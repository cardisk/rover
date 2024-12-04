module rover::system;
import std::collections::list;
import std::io::path;
import std::os::env;
import libc;

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
