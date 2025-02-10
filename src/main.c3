module rover;
import rover::state, rover::system, rover::display;
import std::collections::list;
import std::io;
import ncurses;
import libc;

Config  cfg;
State   app;
System  sys;
Display tui;

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

    if (catch e = cfg.init())                 crash(e);
    if (catch e = app.init())                 crash(e);
    if (catch e = sys.init())                 crash(e);
    if (catch e = tui.init(&app, &sys, &cfg)) crash(e);

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

                List(<Path>) *list;
                usz cursor;
                switch (tui.focus)
                {
                    case Focus.LIST:
                        list = &sys.ls;
                        cursor = tui.list_cur;
                    case Focus.BOOKMARKS:
                        list = &sys.bookmarks;
                        cursor = tui.bookmarks_cur;
                    default:
                        app.log(string::new_format("Unhandled focus case %s.", tui.focus));
                        continue;
                }

                if (list.is_empty()) continue;
                if (!path::exists((*list)[cursor]))
                {
                    app.log(string::new_format("Attempting to access inexistent '%s' path.",
                                                (*list)[cursor].str_view()));
                    continue;
                }

                if (!stat::is_dir((*list)[cursor]))
                {
                    if (cfg.editor.len == 0)
                    {
                        app.log("No editor specified through EDITOR environment variable.");
                        continue;
                    }
                    ncurses::def_prog_mode();
                    ncurses::endwin();

                    ZString cmd = string::new_format_zstr(
                        "%s %s", cfg.editor, (*list)[cursor]
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
                    if (catch sys.pchdir((*list)[cursor]))
                    {
                        app.log(string::new_format("Unable to change directory to %s.",
                                                    (*list)[cursor].str_view()));
                        continue;
                    }
                    if (catch sys.clear_filter())
                    {
                        app.log("Unable to clear the filter.");
                        continue;
                    }
                    tui.top();
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
                if (tui.focus != Focus.BOOKMARKS) continue;
                if (sys.bookmarks.is_empty()) continue;
                sys.bookmarks[tui.bookmarks_cur].free();
                sys.bookmarks.remove_at(tui.bookmarks_cur);
                tui.up();

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

            case 'D':
                if (app.logs.is_empty()) continue;
                app.logs.clear();
                if (!enable_action)
                {
                    enable_action = true;
                    tui.toggle_focus();
                }

            case '/':
                if (!enable_action) continue;

                ZString in = tui.input('/');
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
