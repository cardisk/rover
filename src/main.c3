module rover;
import std::io, std::io::path;
import std::os::env;
import std::collections::list;
import libc;
import ncurses;

// ncurses stuff
bool dir, exe, link;
const CInt DIR = 1;
const CInt EXE = 2;
const CInt LNK = 3;
const CInt PWD = 4;

// rover stuff
CInt x, y;
CInt w, h;
Path home;
List(<Path>) old;

macro set_dir()
{
    assert(!dir, "Directory text color can be set only once per time.");
    dir = true;
    ncurses::attron(ncurses::color_pair(DIR));
    ncurses::attron(ncurses::A_BOLD);
}

macro set_exe()
{
    assert(!exe, "Executable text color can be set only once per time.");
    exe = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(EXE));
}

macro set_link()
{
    assert(!link, "Symbolic link text color can be set only once per time.");
    link = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(LNK));
}

macro reset()
{
    assert(!dir || !exe, "Item can't be colored as directory and executable at the same time.");

    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::A_REVERSE);
    if (dir)
    {
        dir = false;
        ncurses::attroff(ncurses::color_pair(DIR));
    }
    
    if (exe)
    {
        exe = false;
        ncurses::attroff(ncurses::color_pair(EXE));
    }

    if (link)
    {
        link = false;
        ncurses::attroff(ncurses::color_pair(LNK));
    }
}

macro bool is_dir(p)
{
    // TODO: native is_dir does not take account of WIN32.
    // maybe implement something here?
    return path::is_dir(p);
}

extern fn CInt lstat(ZString, Stat *);
macro bool is_stat(stat, type) => ((stat.st_mode & libc::S_IFMT) == type);

macro bool is_exe(p)
{

    Stat stat;
    $if env::POSIX:
        if (lstat(p.as_zstr(), &stat) < 0)
        {
            ncurses::endwin();
            io::eprintfn("Can't read stats of '%s': %s", p, libc::strerror(libc::errno()));
            libc::exit(1);
        }
    $else
        $error("Non-Posix platform not supported");
    $endif

    if (is_stat(stat, libc::S_IXUSR)) return true;
    return false;
}

macro bool is_link(p)
{
    Stat stat;
    $if env::POSIX:
        if (lstat(p.as_zstr(), &stat) < 0)
        {
            ncurses::endwin();
            io::eprintfn("Can't read stats of '%s': %s", p, libc::strerror(libc::errno()));
            libc::exit(1);
        }
    $else
        $error("Non-Posix platform not supported");
    $endif

    if (is_stat(stat, libc::S_IFLNK)) return true;
    return false;
}

fn void rover_init()
{
    ncurses::start_color();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::raw();
    ncurses::curs_set(0);

    ncurses::init_pair(DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK);
    ncurses::init_pair(EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK);
    ncurses::init_pair(LNK, ncurses::COLOR_MAGENTA, ncurses::COLOR_BLACK);
    ncurses::init_pair(PWD, ncurses::COLOR_YELLOW, ncurses::COLOR_BLACK);

    String! env_home = env::get_home_dir();
    if (catch env_home)
    {
        ncurses::endwin();
        io::eprintn("Unable to locate HOME directory from environment.");
        libc::exit(1);
    }
    // FIXME: this assertion can cause some problems in the future.
    home = path::new(env_home)!!;
    old.new_init();
}

fn void main()
{
    ncurses::initscr();
    defer ncurses::endwin();
    bool looping = true;
    
    assert(ncurses::has_colors(), "Your terminal can't display colors.");

    rover_init();

    while (looping)
    {
        ncurses::clear();

        ncurses::@getmaxyx(ncurses::stdscr, h, w);

        Path! cwd = path::new_cwd();
        // TODO: better error handling for getting cwd.
        if (catch cwd) continue;
        defer cwd.free();

        ncurses::attron(ncurses::color_pair(PWD));
        ncurses::attron(ncurses::A_BOLD);
        ncurses::printw("%s\n\n", cwd.str_view());
        ncurses::attroff(ncurses::color_pair(PWD));
        ncurses::attroff(ncurses::A_BOLD);

        PathList! ls = path::new_ls(cwd);
        // TODO: better error handling for getting the content of cwd.
        if (catch ls) continue;
        defer ls.free();

        foreach (i, p : ls)
        {
            if (is_link(p))
            {
                set_link();
            }
            else if (is_exe(p))
            {
                set_exe();
            }
            else if (is_dir(p)) 
            {
                set_dir();
            }

            if (i == y)
            {
                ncurses::attron(ncurses::A_REVERSE);
            }

            // align text taking in account the first space and one in the middle
            ncurses::printw(" %- *s\n", (w / 2) - 2, p.str_view());

            reset();
        }

        ncurses::move(y, x);

        switch (CInt key = ncurses::getch())
        {
            case ncurses::KEY_UP:
                if (y > 0) y--;
            case ncurses::KEY_DOWN:
                if (y < ls.len() - 1) y++;
            case '\n':
                if (!is_dir(ls[y])) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(ls[y])) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case '-':
                Path! parent = path::new("..");
                if (catch parent) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(parent)) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case '.':
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(home)) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case 'b':
                Path! p = old.pop();
                if (catch p) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(p)) continue;
                y = 0;
            case 'Q':
            case 'q':
                looping = false;
        }

        ncurses::refresh();
    }

    // TODO: rover_deinit() to deallocate consts and globals.
}

