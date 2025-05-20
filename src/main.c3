module rover;
import rover::state, rover::system, rover::display, rover::actions;
import std::collections::list;
import std::io;
import ncurses;
import libc;

Config  cfg @builtin;
State   app @builtin;
System  sys @builtin;
Display tui @builtin;

// This serves to activate or deactivate actions
// when displaying the error popup.
bool enable_action = true;

fn void crash(fault f) @noreturn
{
    ncurses::endwin();
    io::eprintfn("Unattended error happened: %s", f);
    libc::exit(1);
}

fn void main()
{
    // Doing the initalization here so the modules will load up correctly.
    ncurses::initscr();
    if (!ncurses::has_colors())
    {
        ncurses::endwin();
        io::eprintn("Your terminal emulator does not support colors.");
        libc::exit(1);
    }
    ncurses::start_color();

    if (catch e = cfg.init()) crash(e);
    if (catch e = app.init()) crash(e);
    if (catch e = sys.init()) crash(e);
    if (catch e = tui.init()) crash(e);

    while LOOP: (true)
    {
        app.update();
        if (catch sys.update())
        {
            app.log("Unable to update System info.");
            continue;
        }
        if (catch tui.update())
        {
            app.log("Unable to update Display module.");
            continue;
        }

        switch (CInt key = ncurses::getch())
        {
            case 'q':
                break LOOP;

            case '\n':
                switch (tui.focus)
                {
                    case Focus.LIST:
                        if (sys.ls.is_empty()) continue;

                        if (!path::exists(sys.ls[tui.list_cur]))
                        {
                            app.log(string::format(mem, "Attempting to access inexistent '%s' path.",
                                        sys.ls[tui.list_cur].str_view()));
                            continue;
                        }

                        if (stat::is_dir(sys.ls[tui.list_cur]))
                        {
                            actions::browse(&sys.ls[tui.list_cur]);
                        }
                        else
                        {
                            actions::open_file(sys.ls[tui.list_cur]);
                        }

                    case Focus.BOOKMARKS:
                        if (sys.bookmarks.is_empty()) continue;

                        if (!path::exists(sys.bookmarks[tui.bookmarks_cur]))
                        {
                            app.log(string::format(mem, "Attempting to access inexistent '%s' path.",
                                        sys.bookmarks[tui.bookmarks_cur].str_view()));
                            continue;
                        }

                        if (stat::is_dir(sys.bookmarks[tui.bookmarks_cur]))
                        {
                            actions::browse(&sys.bookmarks[tui.bookmarks_cur]);
                        }
                        else
                        {
                            actions::open_file(sys.bookmarks[tui.bookmarks_cur]);
                        }

                    default:
                        app.log(string::format(mem, "Unhandled focus case %s.", tui.focus));
                        continue;
                }

            case '-':
                // NOTE: Taking the address of a temporary string may create errors.
                // Inside the standard library there is a notion of 'any_make' that
                // creates an any object from a given pointer. I think that this solution
                // is more readable, but may cause some problems in the future.
                actions::browse(&&"..");

            case '.':
                actions::browse(&sys.home);

            case 'b':
                if (sys.history.is_empty()) break;

                // Safe to unwrap due to previous check.
                Path p = sys.history.pop()!!;
                actions::browse(&p);

            case 's':
                actions::save_bookmark();

            case 'd':
                actions::delete_selection();

            case 'r':
                if (tui.focus != Focus.LIST) continue;
                actions::rename_path(sys.ls[tui.list_cur]);

            case 'h':
                actions::open_history();

            case 'B':
                actions::open_bookmarks();

            case 'e':
                actions::open_errors();

            case 'm':
                if (tui.focus != Focus.LIST) continue;
                actions::mark_path(tui.list_cur);

            case 'M':
                if (tui.focus != Focus.LIST) continue;
                actions::unmark_path(tui.list_cur);

            case 't':
                if (tui.focus != Focus.LIST) continue;
                actions::move_to_target(tui.list_cur);

            case 'g':
                actions::goto();

            case 'D':
                actions::clear_errors();

            case 'n':
                actions::new_file();

            case '/':
                actions::search();

            case 'f':
                actions::filter(false);


            case 'F':
                actions::filter(true);

            case '\\':
                actions::clear_filter();

            case '\t':
                actions::change_focus();

            case ncurses::KEY_UP:
                tui.up();

            case ncurses::KEY_DOWN:
                tui.down();
        }
    }

    ncurses::endwin();

    cfg.free();
    app.free();
    sys.free();
    tui.free();
}
