module rover::system;
import rover::stat;
import std::collections::list;
import std::io::path, std::io::file;
import std::os::env;
import libc;

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
    List(<Path>) ls;
    List(<usz>) marked_indexes;

    bool filter_case_sensitive;
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

    self.history.init(allocator::mem);
    self.bookmarks.init(allocator::mem);

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
    // No undefined behaviour because self.ls points to
    // the content of ls.
    self.ls = ls;

    self.filter = null;

    allocator::temp().reset(tmark);
}

fn void! System.set_apply_filter(&self, ZString filter, bool case_sensitive = false)
{
    if (catch err = self.clear_filter())
    {
        libc::free(filter);
        return err?;
    }
    self.filter = filter;
    self.filter_case_sensitive = case_sensitive;
    self.apply_filter();
}

fn void! System.clear_filter(&self)
{
    if (!self.filter) return;
    libc::free(self.filter);
    self.filter = null;

    // No need to free its content, everything is done
    // by std::collections::list::free() method.
    self.ls.free();
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    // No undefined behaviour because self.ls points to
    // the content of ls.
    self.ls = ls;
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

fn void! System.new_file(&self, String name)
{
    file::save(name, {})!;
}

fn bool System.is_marked(&self, usz index)
{
    foreach (it : self.marked_indexes)
    {
        if (index == it) return true;
    }
    return false;
}

fn void System.mark(&self, usz index)
{
    if (self.is_marked(index)) return;
    self.marked_indexes.push(index);
}

fn void System.unmark(&self, usz index)
{
    if (!self.is_marked(index)) return;
    foreach (i, it : self.marked_indexes)
    {
        if (index == it)
        {
            self.marked_indexes.remove_at(i);
            break;
        }
    }
}

fn void System.move_marks(&self, usz index)
{
    usz tmark = allocator::temp().mark();
    Path target = self.ls[index];
    for (usz i = 0; i < self.marked_indexes.len();)
    {
        Path old = self.ls[self.marked_indexes[i]];
        
        DString new;
        new.tinit();
        new.append(target.str_view());
        new.append('/');
        new.append(old.str_view());

        CInt res = libc::rename(old.as_zstr(), new.zstr_view());
        if (!res) 
        {
            self.marked_indexes.remove_at(i);
            continue;
        }

        i++;
    }

    allocator::temp().reset(tmark);
}

fn void System.free(&self)
{
    // Allocations inside this block are made inside the temporary
    // allocator that at the end of the scope is automatically freed.
    @pool()
    {
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
        bookmarks.tinit();

        foreach (b : self.bookmarks)
        {
            bookmarks.append(b.str_view());
            bookmarks.append("\n");
        }

        if (catch f.write((char[]) bookmarks.str_view())) return;
    };

    self.home.free();
    self.cwd.free();

    // No undefined behaviour because the content gets
    // invalidated with the container free.
    self.history.free();
    self.bookmarks.free();
    self.ls.free();

    if (self.filter) libc::free(self.filter);
}

module rover::system @private;
import rover::stat;
import std::io::path;

fn bool is_root(Path p)
{
    $if env::POSIX:
        return p.str_view() == "/";
    $endif

    $if env::WIN32:
        return p.str_view().ends_with(":\\");
    $endif
}

fn void! System.reload_cwd(&self)
{
    self.cwd.free();
    Path! cwd = path::new_cwd();
    if (catch cwd) return SystemError.NO_CWD?;
    // No undefined behaviour because the cwd.path_string.ptr
    // is assigned to self.cwd
    self.cwd = cwd;

    if (!stat::read_stat(self.cwd, &self.cwd_stat)) return SystemError.NO_STAT?;

    self.ls.free();
    PathList! ls = path::new_ls(self.cwd);
    if (catch ls) return SystemError.NO_LS?;
    self.ls = ls;

    self.apply_filter();
}

fn void System.apply_filter(&self)
{
    @pool()
    {
        if (!self.filter) return;
        for (int i = 0; i < self.ls.len();)
        {
            String lower_current = self.ls[i].str_view().temp_ascii_to_lower();
            String lower_filter = self.filter.str_view().temp_ascii_to_lower();

            String current = lower_current;
            String filter  = lower_filter;

            // No need to make copies here because String is a pointer with a length,
            // str_view() just crafts the String type filling its fields.
            if (self.filter_case_sensitive)
            {
                current = self.ls[i].str_view();
                filter  = self.filter.str_view();
            }

            if (!current.contains(filter))
            {
                self.ls.remove_at(i);
                continue;
            }

            i++;
        }
    };
    // With this implementation the compiler segfaults (c3c version 0.6.6).
    // self.ls.remove_using_test(
    //     fn bool(PathImp *p, any ctx)
    //     {
    //         return !p.str_view().contains(((ZString) ctx).str_view());
    //     },

    //     self.filter
    // );
}
