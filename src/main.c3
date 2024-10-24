module main;
import std::io, ncurses;

fn void main()
{
    ncurses::initscr();
    ncurses::getch();
    ncurses::endwin();
}
