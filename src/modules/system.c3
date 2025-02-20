module rover::system;
import rover::stat;
import std::collections::list;
import std::io::path, std::io::file;
import std::os::env;
import libc;

fn bool is_root(Path p) @private
{
    $if env::POSIX:
        return p.str_view() == "/";
    $endif

    $if env::WIN32:
        return p.str_view().ends_with(":\\");
    $endif
}

fault SystemError
{
    NO_HOME,
    NO_CWD,
    NO_LS,
    NO_STAT,
    NO_PATH,
    NO_CHDIR,
}

struct System
{
    Path home;
    Stat cwd_stat;
    Path cwd;
    List(<Path>) history;
    List(<Path>) bookmarks;
    // When filtering this List will change, clear-filter will reload the cwd.
    PathList ls;
    ZString filter;
}

fn void! System.init(&self)
{
    usz tmark = allocator::temp().mark();

    String! home_env = env::get_home_dir();
    if (catch home_env) return SystemError.NO_HOME?;

    Path! home = path::new(home_env);
    if (catch home) return SystemError.NO_HOME?;

    self.home = home;

    Path! cwd = path::new_cwd();
    if (catch cwd) return SystemError.NO_CWD?;
    self.cwd = cwd;

    if (!stat::read_stat(self.cwd, &self.cwd_stat)) return SystemError.NO_STAT?;

    self.history.new_init();
    self.bookmarks.new_init();

    String bookmarks_path = self.home.str_view().tconcat("/.config/rover/bookmarks");

    char[]! bookmarks_content = file::load_temp(bookmarks_path);
    if BOOKMARKS: (try bookmarks_content)
    {
        if (bookmarks_content.len == 0) break BOOKMARKS;

        String[] lines = ((String) bookmarks_content).tsplit("\n", skip_empty: true);
        foreach (line : lines)
        {
            Path! p = path::new(line);
            if (catch p) continue;
            if (!path::exists(p)) continue;
            self.bookmarks.push(p);
        }
    }

    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.filter = null;

    allocator::temp().reset(tmark);
}

fn void System.apply_filter(&self)
{
    usz tmark = allocator::temp().mark();
    if (!self.filter) return;
    for (int i = 0; i < self.ls.len();)
    {
        String lower_current = self.ls[i].str_view().temp_ascii_to_lower();
        String lower_filter = self.filter.str_view().temp_ascii_to_lower();

        if (!lower_current.contains(lower_filter))
        {
            self.ls.remove_at(i);
            continue;
        }

        i++;
    }

    allocator::temp().reset(tmark);
    // With this implementation the compiler segfaults (c3c version 0.6.6).
    // self.ls.remove_using_test(
    //     fn bool(PathImp *p, any ctx)
    //     {
    //         return !p.str_view().contains(((ZString) ctx).str_view());
    //     },

    //     self.filter
    // );
}

fn void! System.set_apply_filter(&self, ZString filter)
{
    self.clear_filter()!;
    self.filter = filter;
    self.apply_filter();
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

fn void! System.reload_cwd(&self) @private
{
    self.cwd.free();
    Path! cwd = path::new_cwd();
    if (catch cwd) return SystemError.NO_CWD?;
    self.cwd = cwd;

    if (!stat::read_stat(self.cwd, &self.cwd_stat)) return SystemError.NO_STAT?;

    self.ls.free();
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.apply_filter();
}

fn void! System.pchdir(&self, Path p, bool save_cwd = true)
{
    if (is_root(self.cwd) && p.str_view() == "..") return;
    if (catch path::chdir(p)) return SystemError.NO_CHDIR?;
    if (save_cwd) self.save_cwd();

    self.reload_cwd()!;
}

fn void! System.schdir(&self, String p, bool save_cwd = true)
{
    if (is_root(self.cwd) && p == "..") return;
    Path! path = path::new(p);
    if (catch path) return SystemError.NO_PATH?;

    if (catch path::chdir(path)) return SystemError.NO_CHDIR?;
    if (save_cwd) self.save_cwd();

    self.reload_cwd()!;
}

fn void! System.update(&self)
{
    if (stat::is_modified(self.cwd, self.cwd_stat) < 0) return SystemError.NO_STAT?;
    if (!stat::is_modified(self.cwd, self.cwd_stat)) return;

    self.reload_cwd()!;
}

fn void System.save_cwd(&self)
{
    // Assuming that creating a new path from an existing one will never fail.
    Path p = path::new(self.cwd.as_zstr().copy())!!;
    self.history.push(p);
}

fn void System.free(&self)
{
    {|
        usz tmark = allocator::temp().mark();

        String config_path = self.home.str_view().tconcat("/.config/rover");

        Path! dir = path::temp_new(config_path);
        if (catch dir) return;

        if (!path::is_dir(dir))
        {
            bool! success = path::mkdir(dir, true);
            if (catch success) return;
            if (!success) return;
        }

        if (catch path::chdir(dir)) return;

        File! f = file::open("bookmarks", "wb");
        if (catch f) return;

        DString bookmarks;
        bookmarks.temp_init();

        foreach (b : self.bookmarks)
        {
            bookmarks.append(b.str_view());
            bookmarks.append("\n");
        }

        if (catch f.write((char[]) bookmarks.str_view())) return;
        
        allocator::temp().reset(tmark);
    |};

    self.home.free();
    self.cwd.free();
    self.history.free();
    self.bookmarks.free();
    self.ls.free();
    if (self.filter) libc::free(self.filter);
}
