module rover;
import std::core::mem;
import std::io::path;
import std::collections::list;
import std::os::env;
import libc;
import ncurses;

CInt x, y;
CInt w, h;
ZString hostname;
Path home;
List(<Path>) old;

fn void init()
{
    hostname = (ZString) mem::new_array(char, 256);
    assert(gethostname(hostname, 256) == 0, "Can't access host name.");

    ncurses::initscr();

    assert(ncurses::has_colors(), "Your terminal can't display colors.");

    ncurses::start_color();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::raw();
    ncurses::curs_set(0);

    ncurses::init_pair(theme::DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK);
    ncurses::init_pair(theme::EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK);
    ncurses::init_pair(theme::LNK, ncurses::COLOR_CYAN, ncurses::COLOR_BLACK);
    ncurses::init_pair(theme::PWD, ncurses::COLOR_YELLOW, ncurses::COLOR_BLACK);
    ncurses::init_pair(theme::HST, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK);

    String! env_home = env::get_home_dir();
    if (catch env_home)
    {
        deinit();
        io::eprintn("Unable to locate HOME directory from environment.");
        libc::exit(1);
    }
    // FIXME: this assertion can cause some problems in the future.
    home = path::new(env_home)!!;
    old.new_init();
}

fn void deinit()
{
    theme::reset();
    ncurses::endwin();

    // ---- MEMORY ----
    libc::free(hostname);
    old.free();
    home.free();
}
