module rover;
import std::io, std::io::path;
import libc;
import ncurses;

bool dir, exe;
const CInt DIR = 1;
const CInt EXE = 2;

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
}

macro bool is_dir(p)
{
    // TODO: native is_dir does not take account of WIN32.
    // maybe implement something here?
    return path::is_dir(p);
}

macro bool is_exe(p)
{

    Stat stat;
    if (catch os::native_stat(&stat, p.str_view()))
    {
        libc::exit(1);
    }

    if (stat.st_mode & libc::S_IXUSR) return true;
    return false;
}

CInt x, y;
CInt w, h;

fn void rover_init()
{
    ncurses::start_color();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::raw();
    ncurses::curs_set(0);

    ncurses::init_pair(DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK);
    ncurses::init_pair(EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK);
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

        PathList! ls = path::new_ls(cwd);
        // TODO: better error handling for getting the content of cwd.
        if (catch ls) continue;
        defer ls.free();

        foreach (i, p : ls)
        {
            if (is_dir(p)) 
            {
                set_dir();
            }
            else if (is_exe(p))
            {
                set_exe();
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
                // if (y < ncurses::getmaxy(ncurses::stdscr) - 1) y++;
                if (y < ls.len() - 1) y++;
            case '\n':
                if (!is_dir(ls[y])) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(ls[y])) continue;
                y = 0;
            case '-':
                // FIXME: when reaching the /Users directory on env::DARWIN
                // the application crash. It seems a problem with ncurses
                // because trying to access the root folder by C3 works fine.
                Path! parent = path::new("..");
                if (catch parent) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(parent)) continue;
                y = 0;
            case 'Q':
            case 'q':
                looping = false;
            default:
                ncurses::printw("%d ", key);
        }

        ncurses::refresh();
    }
}

