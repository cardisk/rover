module ncurses;

def Chtype = CUint;
def Mmask_t = CUint;

// FIXME: this is an hack, may cause some problems in the future.
// ORIGINAL: typedef struct screen SCREEN;
// struct screen has no reference over ncurses.h
def Screen = void;

def Attr_t = Chtype;

/*
 * cchar_t stores an array of CCHARW_MAX wide characters.  The first is
 * normally a spacing character.  The others are non-spacing.  If those
 * (spacing and nonspacing) do not fill the array, a null L'\0' follows.
 * Otherwise, a null is assumed to follow when extracting via getcchar().
 */
const CCHARW_MAX = 5;

struct CChar_t
{
    Attr_t attr;
    CInt[CCHARW_MAX] chars;
    CInt ext_color;  /* color pair, must be more than 16-bits */
}


struct _Win_st
{
	CShort _cury, _curx; /* current cursor position */

	/* window location and size */
	CShort _maxy, _maxx; /* maximums of x and y, NOT window size */
	CShort _begy, _begx; /* screen coords of upper-left-hand corner */

	CShort   _flags;		/* window state flags */

	/* attribute tracking */
	Attr_t  _attrs;		/* current attribute for non-space character */
	Chtype  _bkgd;		/* current background char/attribute pair */

	/* option values set by user */
	bool	_notimeout;	/* no time out on function-key entry? */
	bool	_clear;		/* consider all data in the window invalid? */
	bool	_leaveok;	/* OK to not reset cursor on exit? */
	bool	_scroll;	/* OK to scroll this window? */
	bool	_idlok;		/* OK to use insert/delete line? */
	bool	_idcok;		/* OK to use insert/delete char? */
	bool	_immed;		/* window in immed mode? (not yet used) */
	bool	_sync;		/* window in sync mode? */
	bool	_use_keypad;	/* process function keys into KEY_ symbols? */
	CInt	_delay;		/* 0 = nodelay, <0 = blocking, >0 = delay */

	void *_line;	/* the actual line data */

	/* global screen state */
	CShort _regtop;	/* top line of scrolling region */
	CShort _regbottom; /* bottom line of scrolling region */

	/* these are used only if this is a sub-window */
	CInt	_parx;		/* x coordinate of this window in parent */
	CInt	_pary;		/* y coordinate of this window in parent */
	Window *_parent;	/* pointer to parent if a sub-window */

	/* these are used only if this is a pad */
	struct Pdat
	{
	    CShort _pad_y,      _pad_x;
	    CShort _pad_top,    _pad_left;
	    CShort _pad_bottom, _pad_right;
	};

	CShort _yoffset; /* real begy is _begy + _yoffset */

	CChar_t _bkgrnd;	/* current background char/attribute pair */
	CInt	_color;		/* current color-pair for non-space character */
}

def Window = _Win_st;

/*
 * Curses uses a helper function.  Define our type for this to simplify
 * extending it for the sp-funcs feature.
 */
def OutC = fn CInt(CInt);

/*
 * Function prototypes.  This is the complete X/Open Curses list of required
 * functions.  Those marked `generated' will have sources generated from the
 * macro definitions later in this file, in order to satisfy XPG4.2
 * requirements.
 */

extern CInt addch(Chtype);
extern CInt addchnstr(Chtype *, CInt);
extern CInt addchstr(Chtype *);
extern CInt addnstr(ZString, CInt);
extern CInt addstr(ZString);
extern CInt attroff(CInt);
extern CInt attron(CInt);
extern CInt attrset(CInt);
extern CInt attr_get(Attr_t *, CShort *, void *);
extern CInt attr_off(Attr_t, void *);
extern CInt attr_on(Attr_t, void *);
extern CInt attr_set(Attr_t, CShort, void *);
extern CInt baudrate();
extern CInt beep();
extern CInt bkgd(Chtype);
extern void bkgdset(Chtype);
extern CInt border(Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype);
extern CInt box(Window *, Chtype, Chtype);
extern bool can_change_color();
extern CInt cbreak();
extern CInt chgat(CInt, Attr_t, CShort, void *);
extern CInt clear();
extern CInt clearok(Window *, bool);
extern CInt clrtobot();
extern CInt clrtoeol();
extern CInt color_content(CShort, CShort *, CShort *, CShort *);
extern CInt color_set(CShort, void *);
extern CInt color_pair(CInt) @extern("COLOR_PAIR");
extern CInt copywin(Window *, Window *, CInt, CInt, CInt, CInt, CInt, CInt, CInt);
extern CInt curs_set(CInt);
extern CInt def_prog_mode();
extern CInt def_shell_mode();
extern CInt delay_output(CInt);
extern CInt delch();
extern void delscreen(Screen *);
extern CInt delwin(Window *);
extern CInt deleteln();
extern Window *derwin(Window *, CInt, CInt, CInt, CInt);
extern CInt doupdate();
extern Window *dupwin(Window *);
extern CInt echo();
extern CInt echochar(Chtype);
extern CInt erase();
extern CInt endwin();
extern char erasechar();
extern void filter();
extern CInt flash();
extern CInt flushinp();
extern Chtype getbkgd(Window *);
extern CInt getch();
extern CInt getnstr(ZString, CInt);
extern CInt getstr(ZString);
extern Window *getwin(File *);
extern CInt halfdelay(CInt);
extern bool has_colors();
extern bool has_ic();
extern bool has_il();
extern CInt hline(Chtype, CInt);
extern void idcok(Window *, bool);
extern CInt idlok(Window *, bool);
extern void immedok(Window *, bool);
extern Chtype inch();
extern CInt inchnstr(Chtype *, CInt);
extern CInt inchstr(Chtype *);
extern Window *initscr();
extern CInt init_color(CShort, CShort, CShort, CShort);
extern CInt init_pair(CShort, CShort, CShort);
extern CInt innstr(ZString, CInt);
extern CInt insch(Chtype);
extern CInt insdelln(CInt);
extern CInt insertln();
extern CInt insnstr(ZString, CInt);
extern CInt insstr(ZString);
extern CInt instr(ZString);
extern CInt intrflush(Window *, bool);
extern bool isendwin();
extern bool is_linetouched(Window *, CInt);
extern bool is_wintouched(Window *);
extern ZString keyname(CInt);
extern CInt keypad(Window *, bool);
extern char killchar();
extern CInt leaveok(Window *, bool);
extern ZString longname();
extern CInt meta(Window *, bool);
extern CInt move(CInt, CInt);
extern CInt mvaddch(CInt, CInt, Chtype);
extern CInt mvaddchnstr(CInt, CInt, Chtype *, CInt);
extern CInt mvaddchstr(CInt, CInt, Chtype *);
extern CInt mvaddnstr(CInt, CInt, ZString, CInt);
extern CInt mvaddstr(CInt, CInt, ZString);
extern CInt mvchgat(CInt, CInt, CInt, Attr_t, CShort, void *);
extern CInt mvcur(CInt, CInt, CInt, CInt);
extern CInt mvdelch(CInt, CInt);
extern CInt mvderwin(Window *, CInt, CInt);
extern CInt mvgetch(CInt, CInt);
extern CInt mvgetnstr(CInt, CInt, ZString, CInt);
extern CInt mvgetstr(CInt, CInt, ZString);
extern CInt mvhline(CInt, CInt, Chtype, CInt);
extern Chtype mvinch(CInt, CInt);
extern CInt mvinchnstr(CInt, CInt, Chtype *, CInt);
extern CInt mvinchstr(CInt, CInt, Chtype *);
extern CInt mvinnstr(CInt, CInt, ZString, CInt);
extern CInt mvinsch(CInt, CInt, Chtype);
extern CInt mvinsnstr(CInt, CInt, ZString, CInt);
extern CInt mvinsstr(CInt, CInt, ZString);
extern CInt mvinstr(CInt, CInt, ZString);
extern CInt mvprintw(CInt, CInt, ZString, ...);
extern CInt mvscanw(CInt, CInt, ZString, ...);
extern CInt mvvline(CInt, CInt, Chtype, CInt);
extern CInt mvwaddch(Window *, CInt, CInt, Chtype);
extern CInt mvwaddchnstr(Window *, CInt, CInt, Chtype *, CInt);
extern CInt mvwaddchstr(Window *, CInt, CInt, Chtype *);
extern CInt mvwaddnstr(Window *, CInt, CInt, ZString, CInt);
extern CInt mvwaddstr(Window *, CInt, CInt, ZString);
extern CInt mvwchgat(Window *, CInt, CInt, CInt, Attr_t, CShort, void *);
extern CInt mvwdelch(Window *, CInt, CInt);
extern CInt mvwgetch(Window *, CInt, CInt);
extern CInt mvwgetnstr(Window *, CInt, CInt, ZString, CInt);
extern CInt mvwgetstr(Window *, CInt, CInt, ZString);
extern CInt mvwhline(Window *, CInt, CInt, Chtype, CInt);
extern CInt mvwin(Window *, CInt, CInt);
extern Chtype mvwinch(Window *, CInt, CInt);
extern CInt mvwinchnstr(Window *, CInt, CInt, Chtype *, CInt);
extern CInt mvwinchstr(Window *, CInt, CInt, Chtype *);
extern CInt mvwinnstr(Window *, CInt, CInt, ZString, CInt);
extern CInt mvwinsch(Window *, CInt, CInt, Chtype);
extern CInt mvwinsnstr(Window *, CInt, CInt, ZString, CInt);
extern CInt mvwinsstr(Window *, CInt, CInt, ZString);
extern CInt mvwinstr(Window *, CInt, CInt, ZString);
extern CInt mvwprintw(Window *, CInt, CInt, ZString, ...);
extern CInt mvwscanw(Window *, CInt, CInt, ZString, ...);
extern CInt mvwvline(Window *, CInt, CInt, Chtype, CInt);
extern CInt napms(CInt);
extern Window *newpad(CInt, CInt);
extern Screen *newterm(ZString, File *, File *);
extern Window *newwin(CInt, CInt, CInt, CInt);
extern CInt nl();
extern CInt nocbreak();
extern CInt nodelay(Window *, bool);
extern CInt noecho();
extern CInt nonl();
extern void noqiflush();
extern CInt noraw();
extern CInt notimeout(Window *, bool);
extern CInt overlay(Window *, Window *);
extern CInt overwrite(Window *, Window *);
extern CInt pair_content(CShort, CShort *, CShort *);
extern CInt pair_number(CInt) @extern("PAIR_NUMBER");
extern CInt pechochar(Window *, Chtype);
extern CInt pnoutrefresh(Window *, CInt, CInt, CInt, CInt, CInt, CInt);
extern CInt prefresh(Window *, CInt, CInt, CInt, CInt, CInt, CInt);
extern CInt printw(ZString, ...);
extern CInt putwin(Window *, File *);
extern void qiflush();
extern CInt raw();
extern CInt redrawwin(Window *);
extern CInt refresh();
extern CInt resetty();
extern CInt reset_prog_mode();
extern CInt reset_shell_mode();
extern CInt ripoffline(CInt, CInt(*)(Window *, CInt));
extern CInt savetty();
extern CInt scanw(ZString, ...);
extern CInt scr_dump(ZString);
extern CInt scr_init(ZString);
extern CInt scrl(CInt);
extern CInt scroll(Window *);
extern CInt scrollok(Window *, bool);
extern CInt scr_restore(ZString);
extern CInt scr_set(ZString);
extern CInt setscrreg(CInt, CInt);
extern Screen *set_term(Screen *);
extern CInt slk_attroff(Chtype);
extern CInt slk_attr_off(Attr_t, void *);
extern CInt slk_attron(Chtype);
extern CInt slk_attr_on(Attr_t, void *);
extern CInt slk_attrset(Chtype);
extern Attr_t slk_attr();
extern CInt slk_attr_set(Attr_t, CShort, void *);
extern CInt slk_clear();
extern CInt slk_color(CShort);
extern CInt slk_init(CInt);
extern ZString slk_label(CInt);
extern CInt slk_noutrefresh();
extern CInt slk_refresh();
extern CInt slk_restore();
extern CInt slk_set(CInt, ZString, CInt);
extern CInt slk_touch();
extern CInt standout();
extern CInt standend();
extern CInt start_color();
extern Window *subpad(Window *, CInt, CInt, CInt, CInt);
extern Window *subwin(Window *, CInt, CInt, CInt, CInt);
extern CInt syncok(Window *, bool);
extern Chtype termattrs();
extern ZString termname();
extern void timeout(CInt);
extern CInt touchline(Window *, CInt, CInt);
extern CInt touchwin(Window *);
extern CInt typeahead(CInt);
extern CInt ungetch(CInt);
extern CInt untouchwin(Window *);
extern void use_env(bool);
extern void use_tioctl(bool);
extern CInt vidattr(Chtype);
extern CInt vidputs(Chtype, OutC);
extern CInt vline(Chtype, CInt);
// FIXME: '...' was of type 'va_list', this can be a problem in the future
extern CInt vwprintw(Window *, ZString, ...);
extern CInt vw_printw(Window *, ZString, ...);
extern CInt vwscanw(Window *, ZString, ...);
extern CInt vw_scanw(Window *, ZString, ...);
// -----
extern CInt waddch(Window *, Chtype);
extern CInt waddchnstr(Window *, Chtype *, CInt);
extern CInt waddchstr(Window *, Chtype *);
extern CInt waddnstr(Window *, ZString, CInt);
extern CInt waddstr(Window *, ZString);
extern CInt wattron(Window *, CInt);
extern CInt wattroff(Window *, CInt);
extern CInt wattrset(Window *, CInt);
extern CInt wattr_get(Window *, Attr_t *, CShort *, void *);
extern CInt wattr_on(Window *, Attr_t, void *);
extern CInt wattr_off(Window *, Attr_t, void *);
extern CInt wattr_set(Window *, Attr_t, CShort, void *);
extern CInt wbkgd(Window *, Chtype);
extern void wbkgdset(Window *, Chtype);
extern CInt wborder(Window *, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype);
extern CInt wchgat(Window *, CInt, Attr_t, CShort, void *);
extern CInt wclear(Window *);
extern CInt wclrtobot(Window *);
extern CInt wclrtoeol(Window *);
extern CInt wcolor_set(Window *, CShort, void *);
extern void wcursyncup(Window *);
extern CInt wdelch(Window *);
extern CInt wdeleteln(Window *);
extern CInt wechochar(Window *, Chtype);
extern CInt werase(Window *);
extern CInt wgetch(Window *);
extern CInt wgetnstr(Window *, ZString, CInt);
extern CInt wgetstr(Window *, ZString);
extern CInt whline(Window *, Chtype, CInt);
extern Chtype winch(Window *);
extern CInt winchnstr(Window *, Chtype *, CInt);
extern CInt winchstr(Window *, Chtype *);
extern CInt winnstr(Window *, ZString, CInt);
extern CInt winsch(Window *, Chtype);
extern CInt winsdelln(Window *, CInt);
extern CInt winsertln(Window *);
extern CInt winsnstr(Window *, ZString, CInt);
extern CInt winsstr(Window *, ZString);
extern CInt winstr(Window *, ZString);
extern CInt wmove(Window *, CInt, CInt);
extern CInt wnoutrefresh(Window *);
extern CInt wprintw(Window *, ZString, ...);
extern CInt wredrawln(Window *, CInt, CInt);
extern CInt wrefresh(Window *);
extern CInt wscanw(Window *, ZString, ...);
extern CInt wscrl(Window *, CInt);
extern CInt wsetscrreg(Window *, CInt, CInt);
extern CInt wstandout(Window *);
extern CInt wstandend(Window *);
extern void wsyncdown(Window *);
extern void wsyncup(Window *);
extern void wtimeout(Window *, CInt);
extern CInt wtouchln(Window *, CInt, CInt, CInt);
extern CInt wvline(Window *, Chtype, CInt);

/*
 * These are also declared in <ncursesw/term.h>:
 */
extern CInt tigetflag(ZString);
extern CInt tigetnum(ZString);
extern ZString tigetstr(ZString);
extern CInt putp(ZString);

extern ZString tparm(ZString, ...);

extern ZString tiparm(ZString, ...);
extern ZString tiparm_s(CInt, CInt, ZString, ...);
extern CInt tiscan_s(CInt *, CInt *, ZString);

/*
 * These functions are not in X/Open, but we use them in macro definitions:
 */
extern CInt getattrs(Window *);
extern CInt getcurx(Window *);
extern CInt getcury(Window *);
extern CInt getbegx(Window *);
extern CInt getbegy(Window *);
extern CInt getmaxx(Window *);
extern CInt getmaxy(Window *);
extern CInt getparx(Window *);
extern CInt getpary(Window *);

// continue from line 929.
