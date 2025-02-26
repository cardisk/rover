module rover;
import rover::state, rover::system, rover::display;
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

fn void crash(anyfault f) @noreturn
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
                if (!enable_action) continue;

                switch (tui.focus)
                {
                    case Focus.LIST:
                        if (sys.ls.is_empty()) continue;
                        if (!path::exists(sys.ls[tui.list_cur]))
                        {
                            app.log(string::new_format("Attempting to access inexistent '%s' path.",
                                                        sys.ls[tui.list_cur].str_view()));
                            continue;
                        }

                        if (!stat::is_dir(sys.ls[tui.list_cur]))
                        {
                            if (cfg.editor.len == 0)
                            {
                                app.log("No editor specified through EDITOR environment variable.");
                                continue;
                            }
                            ncurses::def_prog_mode();
                            ncurses::endwin();

                            ZString cmd = string::new_format_zstr(
                                "%s %s", cfg.editor, sys.ls[tui.list_cur]
                            );
                            libc::system(cmd);
                            libc::free(cmd);

                            ncurses::reset_prog_mode();
                            
                            // this is necessary but redundant because using CTRL-Z
                            // outside of the main application, will cause ncurses
                            // to CASUALLY forget about some of the configs set
                            // during the initialization.
                            ncurses::endwin();
                        }
                        else
                        {
                            if (catch sys.pchdir(sys.ls[tui.list_cur]))
                            {
                                app.log(string::new_format("Unable to change directory to %s.",
                                                            sys.ls[tui.list_cur].str_view()));
                                continue;
                            }
                            if (catch sys.clear_filter())
                            {
                                app.log("Unable to clear the filter.");
                                continue;
                            }
                            tui.top();
                        }
                    case Focus.BOOKMARKS:
                        if (sys.bookmarks.is_empty()) continue;
                        if (!path::exists(sys.bookmarks[tui.bookmarks_cur]))
                        {
                            app.log(string::new_format("Attempting to access inexistent '%s' path.",
                                                        sys.bookmarks[tui.bookmarks_cur].str_view()));
                            continue;
                        }

                        if (!stat::is_dir(sys.bookmarks[tui.bookmarks_cur]))
                        {
                            if (cfg.editor.len == 0)
                            {
                                app.log("No editor specified through EDITOR environment variable.");
                                continue;
                            }
                            ncurses::def_prog_mode();
                            ncurses::endwin();

                            ZString cmd = string::new_format_zstr(
                                "%s %s", cfg.editor, sys.bookmarks[tui.bookmarks_cur]
                            );
                            libc::system(cmd);
                            libc::free(cmd);

                            ncurses::reset_prog_mode();
                            
                            // this is necessary but redundant because using CTRL-Z
                            // outside of the main application, will cause ncurses
                            // to CASUALLY forget about some of the configs set
                            // during the initialization.
                            ncurses::endwin();
                        }
                        else
                        {
                            if (catch sys.pchdir(sys.bookmarks[tui.bookmarks_cur]))
                            {
                                app.log(string::new_format("Unable to change directory to %s.",
                                                            sys.bookmarks[tui.bookmarks_cur].str_view()));
                                continue;
                            }
                            if (catch sys.clear_filter())
                            {
                                app.log("Unable to clear the filter.");
                                continue;
                            }
                            tui.top();
                        }
                    default:
                        app.log(string::new_format("Unhandled focus case %s.", tui.focus));
                        continue;
                }

            case '-':
                if (!enable_action) continue;

                if (catch sys.clear_filter())
                {
                    app.log("Unable to clear the filter.");
                    continue;
                }
                if (catch sys.schdir(".."))
                {
                    app.log("Unable to change directory to the parent one.");
                    continue;
                }
                tui.top();

            case '.':
                if (!enable_action) continue;

                if (catch sys.clear_filter())
                {
                    app.log("Unable to clear the filter.");
                    continue;
                }
                if (catch sys.pchdir(sys.home))
                {
                    app.log("Unable to change directory to the home one.");
                    continue;
                }
                tui.top();

            case 'b':
                if (!enable_action) continue;

                if (sys.history.is_empty()) break;

                Path! p = sys.history.pop();
                if (catch p)
                {
                    app.log("Unable to create a new path from the history.");
                    continue;
                }
                if (catch sys.clear_filter())
                {
                    app.log("Unable to clear the filter.");
                    continue;
                }
                if (catch sys.pchdir(p, false))
                {
                    app.log(string::new_format("Unable to change directory to %s.", p.str_view()));
                    continue;
                }
                tui.top();

            case 's':
                if (!enable_action) continue;

                Path! p = sys.ls[tui.list_cur].new_absolute();
                if (catch p)
                {
                    app.log("Unable to get absolute path for a new bookmark.");
                    continue;
                }
                sys.bookmarks.push(p);

            case 'd':
                if (!enable_action) continue;
                if (tui.focus == Focus.BOOKMARKS)
                {
                    if (sys.bookmarks.is_empty()) continue;
                    sys.bookmarks[tui.bookmarks_cur].free();
                    sys.bookmarks.remove_at(tui.bookmarks_cur);
                    tui.up();
                    continue;
                }
                if (tui.focus == Focus.LIST)
                {
                    if (sys.ls.is_empty()) continue;

                    ZString in = tui.input("confirm deletion [y/N] >");
                    bool confirmation = false;
                    if (in.len() != 0 && (in[0] == 'y' || in[0] == 'Y')) confirmation = true;
                    if (!confirmation) continue;

                    if (catch path::delete(sys.ls[tui.list_cur]))
                    {
                        app.log(string::new_format("Unable to delete %s.", sys.ls[tui.list_cur]));
                        continue;
                    }
                    sys.ls[tui.list_cur].free();
                    sys.ls.remove_at(tui.list_cur);
                    tui.up();
                    continue;
                }

            case 'r':
                if (!enable_action) continue;
                if (tui.focus != Focus.LIST) continue;

                ZString in = tui.input("rename >");
                if (in.len() == 0) continue;

                CInt res = libc::rename(sys.ls[tui.list_cur].as_zstr(), in);
                if (res)
                {
                    app.log(string::new_format("Unable to rename %s into %s", sys.ls[tui.list_cur], in));
                    continue;
                }

            case 'e':
                if (app.logs.is_empty()) continue;
                if (enable_action)
                {
                    // Disable every action that cannot be done with error popup.
                    enable_action = false;
                    tui.toggle_focus(true);
                }
                else
                {
                    enable_action = true;
                    tui.toggle_focus();
                }

            case 'm':
                if (!enable_action) continue;
                if (tui.focus != Focus.LIST) continue;
                if (sys.ls.is_empty()) continue;
                sys.mark(tui.list_cur);

            case 'M':
                if (!enable_action) continue;
                if (tui.focus != Focus.LIST) continue;
                if (sys.ls.is_empty()) continue;
                sys.unmark(tui.list_cur);

            case 'D':
                if (app.logs.is_empty()) continue;
                app.logs.clear();
                if (!enable_action)
                {
                    enable_action = true;
                    tui.toggle_focus();
                }

            case 'n':
                if (!enable_action) continue;

                ZString in = tui.input("filename >");
                if (!in) continue;

                if (in.len() != 0)
                {
                    if (catch sys.new_file(in.str_view()))
                    {
                        app.log(string::new_format("Unable to create new file %s.", in));
                        continue;
                    }
                }

            case '/':
                if (!enable_action) continue;

                ZString in = tui.input("/");
                if (!in) continue;

                if (in.len() != 0)
                {
                    if (catch sys.set_apply_filter(in.str_view().zstr_copy()))
                    {
                        app.log(string::new_format("Unable to apply filter %s.", in));
                        continue;
                    }
                }
                tui.top();

            case '\\':
                if (!enable_action) continue;

                if (catch sys.clear_filter())
                {
                    app.log("Unable to clear the filter.");
                    continue;
                }

            case '\t':
                enable_action = true;
                tui.toggle_focus();

            case ncurses::KEY_UP:
                tui.up();

            case ncurses::KEY_DOWN:
                tui.down();
        }
    }

    ncurses::endwin();

    app.show_logs();

    app.free();
    sys.free();
    tui.free();
}
