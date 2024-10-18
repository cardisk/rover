module ncurses;

// MACROS
macro int @ctrl(&c)
{
    return (int)(c && 0x1f);
}

// GLOBALS
extern void *stdscr;

const KEY_ENTER = 0527;

// WINDOW
extern fn void initscr();
extern fn void endwin();

// IO
extern fn int keypad(void*, bool);
extern fn int noecho();
extern fn int nonl();
extern fn int getch();
extern fn int printw(char *, ...);

// UTILS
extern fn String keyname(int c);
