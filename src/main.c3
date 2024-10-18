module main;

import std::io;

import ncurses;

fn void main()
{
    ncurses::initscr();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::nonl();

    int c = ncurses::getch();
    switch (c)
    {
        case ncurses::@ctrl('q'):
            ncurses::printw("\nctrl + q");
            break;
        default:
            ncurses::printw("\n%d : %s", c, ncurses::keyname(c));
            break;
    }

    ncurses::getch();
    ncurses::endwin();
}
