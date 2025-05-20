module rover::actions;
import rover::display;
import std::io;
import ncurses;
import libc;

// -- GENERIC
// change_focus

// -- ERRORS
// clear_errors
// open_errors

// -- BROWSING
// browse
// goto
// open_file
// delete_selection

// -- CREATION
// new_file
// new_directory

// -- MATCHING
// filter
// clear_filter
// search

// -- CHANGES
// rename_path
// mark_path
// unmark_path
// move_to_target

// -- POPUPS
// open_history
// open_bookmarks

// -- BOOKMARKS
// save_bookmark
// delete_bookmark

// Category flags to determine whether they are active or not.
bool is_errors_active    = true;
bool is_browsing_active  = true;
bool is_creation_active  = true;
bool is_matching_active  = true;
bool is_changes_active   = true;
bool is_popups_active    = true;
bool is_bookmarks_active = true;

// -- GENERIC

fn void change_focus()
{
    tui.toggle_focus();
}

// -- ERRORS

fn void clear_errors()
{
    if (!is_errors_active) return;

    if (app.logs.is_empty()) return;

    app.clear_logs();
}

fn void open_errors()
{
    if (!is_errors_active) return;

    if (app.logs.is_empty()) return;

    if (tui.focus != Focus.POPUP)
    {
        tui.toggle_popup(STRING, &app.logs, app.logs.len());
    }
    else
    {
        change_focus();
    }

    is_browsing_active = !is_browsing_active;
    is_changes_active  = !is_changes_active;
    is_matching_active = !is_matching_active;
    is_creation_active = !is_creation_active;
    is_popups_active   = !is_popups_active;
}

// -- BROWSING

fn void browse(any path)
{
    switch (path.type)
    {
        case Path.typeid:
            browse_path(*anycast(path, Path)!!);

        case String.typeid:
            browse_string(*anycast(path, String)!!);
    }
}

fn void browse_path(Path path)
{
    if (!is_browsing_active) return;

    if (catch sys.pchdir(path))
    {
        app.log(string::format(mem, "Unable to change directory to %s.",
                    path.str_view()));
        return;
    }

    if (catch sys.clear_filter())
    {
        app.log("Unable to clear the filter.");
        return;
    }

    tui.top();
}

fn void browse_string(String path)
{
    if (!is_browsing_active) return;

    if (catch sys.schdir(path))
    {
        app.log(string::format(mem, "Unable to change directory to %s.", path));
        return;
    }

    if (catch sys.clear_filter())
    {
        app.log("Unable to clear the filter.");
        return;
    }

    tui.top();
}

fn void goto()
{
    if (!is_browsing_active) return;

    @pool()
    {
        ZString in = tui.input("goto >");
        if (!in || in.len() == 0) return;

        actions::browse(&&in.str_view());
    };
}

fn void open_file(Path path)
{
    if (!is_browsing_active) return;

    if (cfg.editor.len == 0)
    {
        app.log("No editor specified through EDITOR environment variable.");
        return;
    }

    ncurses::def_prog_mode();
    ncurses::endwin();

    DString cmd = dstring::new(mem);
    cmd.appendf("%s %s", cfg.editor, path);
    libc::system(cmd.zstr_view());
    cmd.free();

    ncurses::reset_prog_mode();

    // This is necessary but redundant because using CTRL-Z
    // outside of the main application, will cause ncurses
    // to CASUALLY forget about some of the configs set
    // during the initialization.
    ncurses::endwin();
}

fn void delete_selection()
{
    if (!is_browsing_active) return;

    switch (tui.focus)
    {
        case Focus.LIST:
            if (sys.ls.is_empty()) return;

            @pool()
            {
                ZString in = tui.input("confirm deletion [y/N] >");
                if (!in) return;

                bool confirmation = false;

                if (in.len() != 0 && (in[0] == 'y' || in[0] == 'Y')) confirmation = true;
                if (!confirmation) return;

                if (catch path::delete(sys.ls[tui.list_cur]))
                {
                    app.log(string::format(mem, "Unable to delete %s.", sys.ls[tui.list_cur]));
                    return;
                }

                sys.ls[tui.list_cur].free();
                sys.ls.remove_at(tui.list_cur);

                tui.up();
            };

        case Focus.BOOKMARKS:
            if (sys.bookmarks.is_empty()) return;

            sys.bookmarks[tui.bookmarks_cur].free();
            sys.bookmarks.remove_at(tui.bookmarks_cur);

            tui.up();

        default:
            return;
    }
}

// -- CREATION

fn void new_file()
{
    if (!is_creation_active) return;

    @pool()
    {
        ZString in = tui.input("filename >");
        if (!in || in.len() == 0) return;

        if (catch sys.new_file(in.str_view()))
        {
            app.log(string::format(mem, "Unable to create new file %s.", in));
            return;
        }
    };
}

fn void new_directory()
{
    if (!is_creation_active) return;

    @pool()
    {
        ZString in = tui.input("directory name >");
        if (!in || in.len() == 0) return;

        bool? created = path::mkdir(path::temp(in.str_view()), true);
        if (catch e = created)
        {
            app.log(string::format(mem, "Unable to create new directory %s: %s.", in, e));
            return;
        }

        if (!created)
        {
            app.log(string::format(mem, "Unable to create new directory %s.", in));
            return;
        }
    };
}

// MATCHING

fn void filter(bool case_sensitive)
{
    if (!is_matching_active) return;

    @pool()
    {
        ZString in = tui.input("/");
        if (!in || in.len() == 0) return;

        if (catch sys.set_apply_filter(in.str_view().zstr_copy(mem), case_sensitive))
        {
            app.log(string::format(mem, "Unable to apply filter %s.", in));
            return;
        }

        tui.top();
    };
}

fn void clear_filter()
{
    if (!is_matching_active) return;

    if (catch sys.clear_filter())
    {
        app.log("Unable to clear the filter.");
        return;
    }
}

fn void search()
{
    if (!is_matching_active) return;

    @pool()
    {
        ZString in = tui.input("/");
        if (!in || in.len() == 0) return;

        isz match_index = sys.search_item(in);

        if (match_index < 0) 
        {
            app.log("No match...");
            return;
        }

        tui.goto(match_index);
    };
}

// -- CHANGES

fn void rename_path(Path path)
{
    if (!is_changes_active) return;

    @pool()
    {
        ZString in = tui.input("rename >");
        if (!in || in.len() == 0) return;

        CInt res = libc::rename(path.as_zstr(), in);
        if (res)
        {
            app.log(string::format(mem, "Unable to rename %s into %s", path, in));
            return;
        }
    };
}

fn void mark_path(usz index)
{
    if (!is_changes_active) return;

    sys.mark(index);

    tui.down();
}

fn void unmark_path(usz index)
{
    if (!is_changes_active) return;

    if (sys.ls.is_empty()) return;
    sys.unmark(index);

    tui.up();
}

fn void move_to_target(usz index)
{
    if (!is_changes_active) return;

    if (!path::is_dir(sys.ls[index]))
    {
        app.log("Target is not a directory");
        return;
    }

    if (sys.is_marked(index))
    {
        app.log("Target cannot be marked");
        return;
    }

    sys.move_marks(index);

    tui.top();
}

// -- POPUPS

fn void open_history()
{
    if (!is_popups_active) return;

    if (sys.history.is_empty()) return;

    if (tui.focus != Focus.POPUP)
    {
        tui.toggle_popup(PATH, &sys.history, sys.history.len());
    }
    else
    {
        change_focus();
    }

    is_changes_active  = !is_changes_active;
    is_matching_active = !is_matching_active;
    is_creation_active = !is_creation_active;
    is_errors_active   = !is_errors_active;
}

fn void open_bookmarks()
{
    if (!is_popups_active) return;

    if (sys.bookmarks.is_empty()) return;

    if (tui.focus != Focus.POPUP)
    {
        tui.toggle_popup(PATH, &sys.bookmarks, sys.bookmarks.len());
    }
    else
    {
        change_focus();
    }

    is_changes_active  = !is_changes_active;
    is_matching_active = !is_matching_active;
    is_creation_active = !is_creation_active;
    is_errors_active   = !is_errors_active;
}

// -- BOOKMARKS

fn void save_bookmark()
{
    if (!is_bookmarks_active) return;

    Path? p = sys.ls[tui.list_cur].absolute(mem);
    if (catch p)
    {
        app.log("Unable to get absolute path for a new bookmark.");
        return;
    }

    sys.bookmarks.push(p);
}

// TODO: Maybe remove this because delete_selection is doing the same thing.
fn void delete_bookmark()
{
}

