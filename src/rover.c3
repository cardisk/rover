module rover;
import std::core::mem;
import std::io::path;
import std::collections::list;
import std::os::env;
import libc;
import ncurses;

// missing function in stdlib.
extern fn ZString getlogin();

fault RoverError
{
    INIT_FAIL,
    NO_COLORS,
    NO_USER,
    NO_HOST,
    NO_HOME,
}

fn String RoverError.what(self)
{
    switch (self)
    {
        case INIT_FAIL: return "Can't initialize the application correctly.";
        case NO_COLORS: return "Your terminal can't display colors.";
        case NO_USER: return "Failed to retrieve logged user info.";
        case NO_HOST: return "Failed to retrieve host name info.";
    }
    return "No known info on what happend.";
}

struct Rover
{
    CInt curx, cury;
    CInt w, h;

    ZString user;
    char[255] host;

    Path home;
    // TODO: make history as a fixed size array.
    List(<Path>) history;
}

fn void! Rover.init(&self)
{
    if (!ncurses::initscr()) return RoverError.INIT_FAIL?;
    if (!ncurses::has_colors()) return RoverError.NO_COLORS?;

    // TODO: refactor Rover.user in a similar way of Rover.host.
    self.user = getlogin();
    if (!self.user) return RoverError.NO_USER?;

    if (gethostname((ZString) &self.host, 255) != 0) return RoverError.NO_HOST?;

    // this code smell.
    String! home = env::get_home_dir();
    if (catch home) return RoverError.NO_HOME?;
    Path! home_path = path::new(home);
    if (catch home_path) return RoverError.NO_HOME?;
    self.home = home_path;

    self.history.new_init();

    if (ncurses::start_color() == ncurses::ERR) return RoverError.INIT_FAIL?;
    if (ncurses::keypad(ncurses::stdscr, true) == ncurses::ERR) return RoverError.INIT_FAIL?;
    if (ncurses::noecho() == ncurses::ERR) return RoverError.INIT_FAIL?;
    if (ncurses::raw() == ncurses::ERR) return RoverError.INIT_FAIL?;
    if (ncurses::curs_set(0) == ncurses::ERR) return RoverError.INIT_FAIL?;

    // TODO: make the colors customizable.
    if (ncurses::init_pair(theme::DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK)) return RoverError.INIT_FAIL?;
    if (ncurses::init_pair(theme::EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return RoverError.INIT_FAIL?;
    if (ncurses::init_pair(theme::LNK, ncurses::COLOR_CYAN, ncurses::COLOR_BLACK)) return RoverError.INIT_FAIL?;
    if (ncurses::init_pair(theme::PWD, ncurses::COLOR_YELLOW, ncurses::COLOR_BLACK)) return RoverError.INIT_FAIL?;
    if (ncurses::init_pair(theme::HST, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return RoverError.INIT_FAIL?;
}

fn void Rover.deinit(&self)
{
    theme::reset();
    ncurses::endwin();

    // ---- MEMORY ----
    // FIXME: on ubuntu manpages this is statically allocated so, no needs to free?
    // libc::free(self.user);
    self.history.free();
    self.home.free();
}
