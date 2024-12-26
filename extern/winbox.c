#include <ncurses.h>

int winbox(WINDOW *win)
{
    return box(win, ACS_VLINE, ACS_HLINE);
}
