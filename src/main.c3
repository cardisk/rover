module main;
import std::io, std::io::path;
import ncurses;

fn void! main()
{
    ncurses::initscr();
    defer ncurses::endwin();

    while (true)
    {
        ncurses::clear();

        Path cwd = path::new_cwd()!;
        foreach (p : path::new_ls(cwd)!)
        {
            ncurses::printw("%s\n", p.path_string);
        }

        ncurses::refresh();

        if (ncurses::getch() == 'q') break;
    }
}
