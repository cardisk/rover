module rover;
import std::collections::list;
import std::io::path;
import std::os::env;
import libc;

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

fn void System.free(&self)
{
    self.home.free();
    self.cwd.free();
    self.history.free();
    self.ls.free();
    if (self.filter) libc::free(self.filter);
}

// Everything needed about ncurses and application.
struct State
{
    CInt w, h;
    ZString user;
    char[255] host;
}

fault StateError
{
    NO_USER,
    NO_HOST,
}

// Everything needed about how to display the application.
struct Display
{
    CInt vw, vh;
    PathList* ls;
}

fault DisplayError
{
    NO_COLORS,
}
