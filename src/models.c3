module rover;
import std::collections::list;
import std::io::path, std::os::env;
import libc;
import ncurses;

// TODO: move this bindings into their own file.
// Everything missing from libc bindings
extern fn ZString getlogin();
extern fn CInt gethostname(ZString, usz);
extern fn CInt isalnum(CInt);

// Everything needed about the filesystem.
fault SystemError
{
    NO_HOME,
    NO_CWD,
    NO_LS,
}

struct System
{
    Path home;
    Path cwd;
    List(<Path>) history;
    // When filtering this List will change, clear-filter will reload the cwd.
    PathList ls;
    ZString filter;
}

fn void! System.init(&self)
{
    // --- THIS CODE SMELLS ---
    String! home_env = env::get_home_dir();
    if (catch home_env) return SystemError.NO_HOME?;

    Path! home = path::new(home_env);
    if (catch home) return SystemError.NO_HOME?;
    home.free();

    self.home = home;
    // ------------------------

    Path! cwd = path::new_cwd();
    if (catch cwd) return SystemError.NO_CWD?;
    self.cwd = cwd;

    self.history.new_init();
    
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.filter = null;
}

fn void System.set_filter(&self, ZString filter)
{
    assert(self.filter);

    self.filter = filter;
    self.ls.remove_using_test(
        fn bool(PathImp *p, any ctx)
        {
            return p.str_view().contains(((ZString) ctx).str_view());
        },

        self.filter
    );
}

fn void System.clear_filter(&self)
{
    if (!self.filter) return;
    libc::free(self.filter);
    self.filter = null;

    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return;
    self.ls = ls;
}

fn void System.free(&self)
{
    self.home.free();
    self.cwd.free();
    self.history.free();
    self.ls.free();
    if (self.filter) libc::free(self.filter);
}

// Everything needed about ncurses and application.
fault StateError
{
    NO_USER,
    NO_HOST,
}

struct State
{
    CInt w, h;
    ZString user;
    char[255] host;
}

fn void! State.init(&self)
{
    // From c-bindings.
    self.user = getlogin();
    if (!self.user) return StateError.NO_USER?;

    if (gethostname((ZString) &self.host, 255) != 0) return StateError.NO_HOST?;

    ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);
}

// TODO: convert State.update() into a function if needed.
macro State.update(&self) => ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);

// TODO: State.free() may be removed.
// On OSX and Linux everything is allocated statically so this method is useless.
// WIN32 is not supported yet, but if it will, there will be 
// the memory management of the struct members here.
fn void State.free(&self)
{
}

// Everything needed about how to display the application.
fault DisplayError
{
    INIT_FAIL,
    NO_COLORS,
    NO_COLBIND,
}

struct Display
{
    // TODO: maybe vw and vh are not needed inside Display.
    CInt vw, vh;
    State *app;
    System *sys;
}

const CInt DIR = 1;
const CInt EXE = 2;
const CInt LNK = 3;
const CInt PWD = 4;
const CInt HST = 5;

fn void! Display.init(&self, State *app, System *sys)
{
    assert(app && sys);
    self.app = app;
    self.sys = sys;

    // Half of the screen, the rest will be selected entry content.
    self.vw = self.app.w / 2;
    // Taking in account the status and command lines.
    self.vh = self.app.h - 3;

    if (!ncurses::initscr()) return DisplayError.INIT_FAIL?;
    if (!ncurses::has_colors()) return DisplayError.NO_COLORS?;

    if (ncurses::start_color() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::keypad(ncurses::stdscr, true) == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::noecho() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::raw() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::curs_set(0) == ncurses::ERR) return DisplayError.INIT_FAIL?;

    // TODO: make the Display theme customizable.
    if (ncurses::init_pair(DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(LNK, ncurses::COLOR_CYAN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(PWD, ncurses::COLOR_YELLOW, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(HST, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
}

// Display doesn't need a free method.

fn void Display.dir(&self)
{
}

fn void Display.exe(&self)
{
}

fn void Display.link(&self)
{
}

fn void Display.pwd(&self)
{
}

fn void Display.host(&self)
{
}

macro Display.select(&self) => ncurses::attron(ncurses::A_REVERSE);

fn void Display.reset(&self)
{
    // TODO: making a bold assumption that if this is set twice it will not crash.
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::A_REVERSE);
    ncurses::attroff(ncurses::color_pair(DIR));
    ncurses::attroff(ncurses::color_pair(EXE));
    ncurses::attroff(ncurses::color_pair(LNK));
    ncurses::attroff(ncurses::color_pair(PWD));
    ncurses::attroff(ncurses::color_pair(HST));
}

fn void Display.draw(&self)
{
}
