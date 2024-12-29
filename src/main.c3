module rover;
import rover::state, rover::system, rover::display;
import std::io;
import ncurses;
import libc;

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
        tui.update();

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

            case '/':
                ncurses::move(app.h - 1, 0);
                ncurses::curs_set(1);

                ncurses::printw("/");
                ncurses::refresh();
                
                CInt in = 0;
                DString buf;

                while (in != 27 && in != '\n')
                {
                    in = ncurses::getch();

                    if (in == ncurses::KEY_BACKSPACE && buf.len() > 0)
                    {
                        ncurses::printw("\b \b");
                        buf.chop(buf.len() - 1);
                    }
                    else if (rover::isalnum(in))
                    {
                        ncurses::printw("%c", (char) in);
                        buf.append((char) in);
                    }
                }
                if (buf.len() != 0)
                {
                    if (catch sys.set_apply_filter(buf.copy_zstr()))
                    {
                        app.log(string::new_format("Unable to apply filter %s.", buf.str_view()));
                        continue;
                    }
                    buf.free();
                }
                ncurses::curs_set(0);
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
}
