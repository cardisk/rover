module rover;
import std::io::path;
import libc;
import ncurses;

// missing function inside stdlib.
extern fn CInt gethostname(ZString, usz);

fn void! save_cwd(Path cwd) @inline
{
    Path p = path::new(cwd.str_view())!;
    old.push(p);
}

fn void main()
{
    init();

    // TODO: distinct allocations from heap and temporary arrays.

    while LOOP: (true)
    {
        ncurses::clear();

        ncurses::@getmaxyx(ncurses::stdscr, h, w);

        Path! cwd = path::new_cwd();
        if (catch cwd) continue;
        defer cwd.free();

        theme::set_host();
        ncurses::printw("%s@%s ", user, hostname);
        theme::set_pwd();
        ncurses::printw("%s\n\n", cwd.str_view());
        theme::reset();

        PathList! ls = path::new_ls(cwd);
        if (catch ls) continue;
        defer ls.free();

        foreach (i, p : ls)
        {
            if (stat::is_link(p))
            {
                theme::set_link();
            }
            else if (stat::is_exe(p))
            {
                theme::set_exe();
            }
            else if (stat::is_dir(p)) 
            {
                theme::set_dir();
            }

            if (i == y) theme::highlight();

            // align text taking in account the first space and one in the middle
            ncurses::printw(" %- *s\n", (w / 2) - 2, p.str_view());

            theme::reset();
        }

        ncurses::move(y, x);

        switch (CInt key = ncurses::getch())
        {
            case ncurses::KEY_UP:
                if (y > 0) y--;

            case ncurses::KEY_DOWN:
                if (y < ls.len() - 1) y++;

            case '\n':
                if (!stat::is_dir(ls[y]))
                {
                    ncurses::def_prog_mode();
                    ncurses::endwin();

                    ZString cmd = string::new_format_zstr(
                        "nvim %s", ls[y]
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
                    if (catch path::chdir(ls[y])) continue;
                    if (catch save_cwd(cwd)) continue;
                    y = 0;
                }

            case '-':
                Path! parent = path::new("..");
                if (catch parent) continue;

                if (catch path::chdir(parent)) continue;
                if (catch save_cwd(cwd)) continue;
                y = 0;

            case '.':
                if (catch path::chdir(home)) continue;
                if (catch save_cwd(cwd)) continue;
                y = 0;

            case 'b':
                Path! p = old.pop();
                if (catch p) continue;
                if (catch path::chdir(p)) continue;
                y = 0;

            case 'q':
                break LOOP;
        }

        ncurses::refresh();
    }

    deinit();
}

