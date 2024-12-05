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
        app.update();
        if (catch sys.update()) continue;
        tui.draw();

        switch (CInt key = ncurses::getch())
        {
            case 'q':
                break LOOP;

            case '\n':
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
                    if (catch path::chdir(sys.ls[tui.cur])) continue;
                    sys.save_cwd();
                    tui.top();
                }

            case '-':
                Path! parent = path::new("..");
                if (catch parent) continue;

                if (catch path::chdir(parent)) continue;
                sys.save_cwd();
                tui.top();

            case '.':
                if (catch path::chdir(sys.home)) continue;
                sys.save_cwd();
                tui.top();

            case 'b':
                Path! p = sys.history.pop();
                if (catch p) continue;
                if (catch path::chdir(p)) continue;
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

                sys.set_filter(buf.copy_zstr());
                buf.free();

                ncurses::curs_set(0);

            case '\\':
                if (catch sys.clear_filter()) continue;

            case ncurses::KEY_UP:
                tui.up();

            case ncurses::KEY_DOWN:
                tui.down();
        }
    }

    app.free();
    sys.free();

    ncurses::endwin();
}

// TODO: the application ignores the errors, but maybe it should crash or
// store somewhere the logs that will be printed to the user at the end of
// the execution.
