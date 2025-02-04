module rover;
import rover::state, rover::system, rover::display;
import std::io;
import ncurses;
import libc;

Config  cfg;
State   app;
System  sys;
Display tui;

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

    if (catch e = cfg.init())           crash(e);
    if (catch e = app.init())           crash(e);
    if (catch e = sys.init())           crash(e);
    if (catch e = tui.init(&app, &sys)) crash(e);

    while LOOP: (true)
    {
        if (app.logs.len() > 10) break;

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
                if (sys.ls.is_empty()) continue;
                if (!stat::is_dir(sys.ls[tui.cur]))
                {
                    ncurses::def_prog_mode();
                    ncurses::endwin();

                    ZString cmd = string::new_format_zstr(
                        "nvim %s", sys.ls[tui.cur]
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
                    if (catch sys.pchdir(sys.ls[tui.cur]))
                    {
                        app.log(string::new_format("Unable to change directory to %s.",
                                                    sys.ls[tui.cur].str_view()));
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
                Path! p = sys.ls[tui.cur].new_absolute();
                if (catch p)
                {
                    app.log("Unable to get absolute path for a new bookmark.");
                    continue;
                }
                sys.bookmarks.push(p);

            case '/':
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
                if (catch sys.clear_filter())
                {
                    app.log("Unable to clear the filter.");
                    continue;
                }

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
