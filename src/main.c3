module rover;
import std::io::path;
import ncurses;

// missing function inside stdlib.
extern fn CInt gethostname(ZString, usz);

fn void main()
{
    init();

    bool looping = true;

    // FIXME: distinct allocations from heap and temporary arrays.

    while (looping)
    {
        ncurses::clear();

        ncurses::@getmaxyx(ncurses::stdscr, h, w);

        Path! cwd = path::new_cwd();
        // TODO: better error handling for getting cwd.
        if (catch cwd) continue;
        defer cwd.free();

        theme::set_host();
        ncurses::printw("%s ", hostname);
        theme::set_pwd();
        ncurses::printw("%s\n\n", cwd.str_view());
        theme::reset();

        PathList! ls = path::new_ls(cwd);
        // TODO: better error handling for getting the content of cwd.
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
                if (!stat::is_dir(ls[y])) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(ls[y])) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case '-':
                Path! parent = path::new("..");
                if (catch parent) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(parent)) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case '.':
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(home)) continue;
                Path! p = path::new(cwd.to_new_string());
                if (catch p) continue;
                old.push(p);
                y = 0;
            case 'b':
                Path! p = old.pop();
                if (catch p) continue;
                // TODO: changing directory should have a better error handling.
                if (catch path::chdir(p)) continue;
                y = 0;
            case 'Q':
            case 'q':
                looping = false;
        }

        ncurses::refresh();
    }

    deinit();
}

