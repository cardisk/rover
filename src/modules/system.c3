module rover::system;
import rover::stat;
import std::collections::list;
import std::io::path;
import std::os::env;
import libc;

fault SystemError
{
    NO_HOME,
    NO_CWD,
    NO_LS,
    NO_STAT,
}

struct System
{
    Path home;
    Stat cwd_stat;
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

    if (!stat::@read_stat(self.cwd, self.cwd_stat)) return SystemError.NO_STAT?;

    self.history.new_init();
    
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.filter = null;
}

fn void System.apply_filter(&self)
{
    if (!self.filter) return;
    self.ls.remove_using_test(
        fn bool(PathImp *p, any ctx)
        {
            return p.str_view().contains(((ZString) ctx).str_view());
        },

        self.filter
    );
}

fn void System.set_filter(&self, ZString filter)
{
    // TODO: System.set_filter() doesn't handle errors.
    if (catch self.clear_filter()) return;
    self.filter = filter;
}

fn void! System.clear_filter(&self)
{
    if (!self.filter) return;
    libc::free(self.filter);
    self.filter = null;

    self.ls.free();
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;
}

fn void! System.update(&self)
{
    if (stat::is_modified(self.cwd, self.cwd_stat) < 0) return SystemError.NO_STAT?;
    if (!stat::is_modified(self.cwd, self.cwd_stat)) return;

    self.cwd.free();
    Path! cwd = path::new_cwd();
    if (catch cwd) return SystemError.NO_CWD?;
    self.cwd = cwd;

    if (!stat::@read_stat(self.cwd, self.cwd_stat)) return SystemError.NO_STAT?;

    self.ls.free();
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.apply_filter();
}

fn void System.save_cwd(&self)
{
    // TODO: assuming that creating a new path from an existing one will never fail.
    Path p = path::new(self.cwd.str_view())!!;
    self.history.push(p);
}

fn void System.free(&self)
{
    self.home.free();
    self.cwd.free();
    self.history.free();
    self.ls.free();
    if (self.filter) libc::free(self.filter);
}
