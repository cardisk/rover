module main;
import std::io, std::io::path;
import libc;
import ncurses;

CInt x, y;

fn void rover_init()
{
    ncurses::start_color();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::raw();
    ncurses::curs_set(1);
}

fn void! main()
{
    ncurses::initscr();
    defer ncurses::endwin();
    bool looping = true;
    
    assert(ncurses::has_colors(), "Your terminal can't display colors.");

    rover_init();

    while (looping)
    {
        ncurses::clear();
    
        Path cwd = path::new_cwd()!;
        foreach (p : path::new_ls(cwd)!)
        {
            // if (path::is_dir(p)) 
            // {
            //     set_color_mode(DIR);
            // }
            // else
            // {
            //     Stat stat;
            //     if (catch os::native_stat(&stat, p.str_view()))
            //     {
            //         libc::exit(1);
            //     }

            //     if (stat.st_mode & libc::S_IXUSR) set_color_mode(EXE);

            // }
  
            ncurses::printw("%s\n", p.str_view());
        }

        ncurses::move(y, x);

        switch (CInt key = ncurses::wgetch(ncurses::stdscr))
        {
            case ncurses::KEY_UP:
                if (y > 0) y--;
            case ncurses::KEY_DOWN:
                if (y < ncurses::getmaxy(ncurses::stdscr) - 1) y++;
            case 'Q':
            case 'q':
                looping = false;
        }

        ncurses::refresh();
    }
}

