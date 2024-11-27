module rover;
import std::io::path;
import libc;
import ncurses;

// missing functions inside stdlib.
extern fn CInt gethostname(ZString, usz);
extern fn CInt isalnum(CInt);

Rover app;

fn void! save_cwd(Path cwd) @inline
{
    Path p = path::new(cwd.str_view())!;
    app.history.push(p);
}

fn int main()
{
    if (catch err = app.init())
    {
        io::eprintn(((RoverError) err).what());
        return 1;
    }

    // TODO: distinct allocations from heap and temporary arrays.

    while LOOP: (true)
    {
        ncurses::clear();

        ncurses::@getmaxyx(ncurses::stdscr, app.h, app.w);

        Path! cwd = path::new_cwd();
        if (catch cwd) continue;
        defer cwd.free();

        PathList! ls = path::new_ls(cwd);
        if (catch ls) continue;
        defer ls.free();

        if (catch app.draw(cwd, ls)) continue;

        ncurses::move(app.cury, app.curx);

        switch (CInt key = ncurses::getch())
        {
            case ncurses::KEY_UP:
                if (app.cury > 0) app.cury--;

            case ncurses::KEY_DOWN:
                if (app.cury < ls.len() - 1) app.cury++;

            case '\n':
                if (!stat::is_dir(ls[app.cury]))
                {
                    ncurses::def_prog_mode();
                    ncurses::endwin();

                    ZString cmd = string::new_format_zstr(
                        "nvim %s", ls[app.cury]
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
                    if (catch path::chdir(ls[app.cury])) continue;
                    if (catch save_cwd(cwd)) continue;
                    app.cury = 0;
                }

            case '-':
                Path! parent = path::new("..");
                if (catch parent) continue;

                if (catch path::chdir(parent)) continue;
                if (catch save_cwd(cwd)) continue;
                app.cury = 0;

            case '.':
                if (catch path::chdir(app.home)) continue;
                if (catch save_cwd(cwd)) continue;
                app.cury = 0;

            case 'b':
                Path! p = app.history.pop();
                if (catch p) continue;
                if (catch path::chdir(p)) continue;
                app.cury = 0;

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
                    else if (isalnum(in))
                    {
                        ncurses::printw("%c", (char) in);
                        buf.append((char) in);
                    }
                }

                if (app.filter) libc::free(app.filter);
                app.filter = buf.copy_zstr();
                buf.free();

                ncurses::curs_set(0);

            case '\\':
                if (app.filter) libc::free(app.filter);
                app.filter = null;

            case 'q':
                break LOOP;
        }

        ncurses::refresh();
    }

    app.deinit();
    return 0;
}

