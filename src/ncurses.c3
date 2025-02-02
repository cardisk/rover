module ncurses;
import std::io;

const ERR = -1;
const OK = 0;

def Chtype = CUInt;
def Mmask_t = CUInt;

/*
 * X/Open attributes.  In the ncurses implementation, they are identical to the
 * A_ attributes.
 */
const WA_ATTRIBUTES = A_ATTRIBUTES;
const WA_NORMAL     = A_NORMAL;
const WA_STANDOUT   = A_STANDOUT;
const WA_UNDERLINE  = A_UNDERLINE;
const WA_REVERSE    = A_REVERSE;
const WA_BLINK      = A_BLINK;
const WA_DIM        = A_DIM;
const WA_BOLD       = A_BOLD;
const WA_ALTCHARSET = A_ALTCHARSET;
const WA_INVIS      = A_INVIS;
const WA_PROTECT    = A_PROTECT;
const WA_HORIZONTAL = A_HORIZONTAL;
const WA_LEFT       = A_LEFT;
const WA_LOW        = A_LOW;
const WA_RIGHT      = A_RIGHT;
const WA_TOP        = A_TOP;
const WA_VERTICAL   = A_VERTICAL;

const WA_ITALIC	= A_ITALIC;	/* ncurses extension */

/* colors */
const COLOR_BLACK   = 0;
const COLOR_RED     = 1;
const COLOR_GREEN   = 2;
const COLOR_YELLOW  = 3;
const COLOR_BLUE    = 4;
const COLOR_MAGENTA = 5;
const COLOR_CYAN    = 6;
const COLOR_WHITE   = 7;

/* line graphics */
extern Chtype[] acs_map;

// ---
// NOTE: this part is very different from C because of the strict rules
// of the C3 compiler.
macro acs(c) => acs_map[(CChar)c];

/* VT100 symbols begin here */
macro acs_ulcorner() => acs('l'); /* upper left corner */
macro acs_llcorner() => acs('m'); /* lower left corner */
macro acs_urcorner() => acs('k'); /* upper right corner */
macro acs_lrcorner() => acs('j'); /* lower right corner */
macro acs_ltee()     => acs('t'); /* tee pointing right */
macro acs_rtee()     => acs('u'); /* tee pointing left */
macro acs_btee()     => acs('v'); /* tee pointing up */
macro acs_ttee()     => acs('w'); /* tee pointing down */
macro acs_hline()    => acs('q'); /* horizontal line */
macro acs_vline()    => acs('x'); /* vertical line */
macro acs_plus()     => acs('n'); /* large plus or crossover */
macro acs_s1()       => acs('o'); /* scan line 1 */
macro acs_s9()       => acs('s'); /* scan line 9 */
macro acs_diamond()  => acs('`'); /* diamond */
macro acs_ckboard()  => acs('a'); /* checker board (stipple) */
macro acs_degree()   => acs('f'); /* degree symbol */
macro acs_plminus()  => acs('g'); /* plus/minus */
macro acs_bullet()   => acs('~'); /* bullet */
/* Teletype 5410v1 symbols begin here */
macro acs_larrow()  => acs(','); /* arrow pointing left */
macro acs_rarrow()  => acs('+'); /* arrow pointing right */
macro acs_darrow()  => acs('.'); /* arrow pointing down */
macro acs_uarrow()  => acs('-'); /* arrow pointing up */
macro acs_board()   => acs('h'); /* board of squares */
macro acs_lantern() => acs('i'); /* lantern symbol */
macro acs_block()   => acs('0'); /* solid square block */
/*
 * These aren't documented, but a lot of System Vs have them anyway
 * (you can spot pprryyzz{{||}} in a lot of AT&T terminfo strings)
 * The ACS_names may not match AT&T's, our source didn't know them.
 */
macro acs_s3()       => acs('p'); /* scan line 3 */
macro acs_s7()       => acs('r'); /* scan line 7 */
macro acs_lequal()   => acs('y'); /* less/equal */
macro acs_gequal()   => acs('z'); /* greater/equal */
macro acs_pi()       => acs('{'); /* Pi */
macro acs_nequal()   => acs('|'); /* not equal */
macro acs_sterling() => acs('}'); /* UK pound sign */

/*
 * Line drawing ACS names are of the form ACS_trbl, where t is the top, r
 * is the right, b is the bottom, and l is the left.  t, r, b, and l might
 * be B (blank), S (single), D (double), or T (thick).  The subset defined
 * here only uses B and S.
 */
macro acs_bssb() => acs_ulcorner();
macro acs_ssbb() => acs_llcorner();
macro acs_bbss() => acs_urcorner();
macro acs_sbbs() => acs_lrcorner();
macro acs_sbss() => acs_rtee();
macro acs_sssb() => acs_ltee();
macro acs_ssbs() => acs_btee();
macro acs_bsss() => acs_ttee();
macro acs_bsbs() => acs_hline();
macro acs_sbsb() => acs_vline();
macro acs_ssss() => acs_plus();
// ---


/* values for the _flags member */
const _SUBWIN    = 0x01; /* is this a sub-window? */
const _ENDLINE   = 0x02; /* is the window flush right? */
const _FULLWIN   = 0x04; /* is the window full-screen? */
const _SCROLLWIN = 0x08; /* bottom edge is at screen bottom? */
const _ISPAD     = 0x10; /* is this window a pad? */
const _HASMOVED  = 0x20; /* has cursor moved since last refresh? */
const _WRAPPED   = 0x40; /* cursor was just wrappped */

/*
 * this value is used in the firstchar and lastchar fields to mark
 * unchanged lines
 */
const _NOCHANGE = -1;

/*
 * this value is used in the oldindex field to mark lines created by insertions
 * and scrolls.
 */
const _NEWINDEX = -1;

// NOTE: CInt is used instead of wchar_t.
// This may cause some problems in the future.
// NOTE: CInt is used instead of wint_t.
// This may cause some problems in the future.

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
	struct // Pdat
	{
	    CShort _pad_y,      _pad_x;
	    CShort _pad_top,    _pad_left;
	    CShort _pad_bottom, _pad_right;
	}

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

extern fn CInt addch(Chtype);
extern fn CInt addchnstr(Chtype *, CInt);
extern fn CInt addchstr(Chtype *);
extern fn CInt addnstr(ZString, CInt);
extern fn CInt addstr(ZString);
extern fn CInt attroff(CInt);
extern fn CInt attron(CInt);
extern fn CInt attrset(CInt);
extern fn CInt attr_get(Attr_t *, CShort *, void *);
extern fn CInt attr_off(Attr_t, void *);
extern fn CInt attr_on(Attr_t, void *);
extern fn CInt attr_set(Attr_t, CShort, void *);
extern fn CInt baudrate();
extern fn CInt beep();
extern fn CInt bkgd(Chtype);
extern fn void bkgdset(Chtype);
extern fn CInt border(Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype);
extern fn CInt box(Window *, Chtype, Chtype);
extern fn bool can_change_color();
extern fn CInt cbreak();
extern fn CInt chgat(CInt, Attr_t, CShort, void *);
extern fn CInt clear();
extern fn CInt clearok(Window *, bool);
extern fn CInt clrtobot();
extern fn CInt clrtoeol();
extern fn CInt color_content(CShort, CShort *, CShort *, CShort *);
extern fn CInt color_set(CShort, void *);
extern fn CInt color_pair(CInt) @extern("COLOR_PAIR");
extern fn CInt copywin(Window *, Window *, CInt, CInt, CInt, CInt, CInt, CInt, CInt);
extern fn CInt curs_set(CInt);
extern fn CInt def_prog_mode();
extern fn CInt def_shell_mode();
extern fn CInt delay_output(CInt);
extern fn CInt delch();
extern fn void delscreen(Screen *);
extern fn CInt delwin(Window *);
extern fn CInt deleteln();
extern fn Window *derwin(Window *, CInt, CInt, CInt, CInt);
extern fn CInt doupdate();
extern fn Window *dupwin(Window *);
extern fn CInt echo();
extern fn CInt echochar(Chtype);
extern fn CInt erase();
extern fn CInt endwin();
extern fn char erasechar();
extern fn void filter();
extern fn CInt flash();
extern fn CInt flushinp();
extern fn Chtype getbkgd(Window *);
extern fn CInt getch();
extern fn CInt getnstr(ZString, CInt);
extern fn CInt getstr(ZString);
extern fn Window *getwin(File *);
extern fn CInt halfdelay(CInt);
extern fn bool has_colors();
extern fn bool has_ic();
extern fn bool has_il();
extern fn CInt hline(Chtype, CInt);
extern fn void idcok(Window *, bool);
extern fn CInt idlok(Window *, bool);
extern fn void immedok(Window *, bool);
extern fn Chtype inch();
extern fn CInt inchnstr(Chtype *, CInt);
extern fn CInt inchstr(Chtype *);
extern fn Window *initscr();
extern fn CInt init_color(CShort, CShort, CShort, CShort);
extern fn CInt init_pair(CShort, CShort, CShort);
extern fn CInt innstr(ZString, CInt);
extern fn CInt insch(Chtype);
extern fn CInt insdelln(CInt);
extern fn CInt insertln();
extern fn CInt insnstr(ZString, CInt);
extern fn CInt insstr(ZString);
extern fn CInt instr(ZString);
extern fn CInt intrflush(Window *, bool);
extern fn bool isendwin();
extern fn bool is_linetouched(Window *, CInt);
extern fn bool is_wintouched(Window *);
extern fn ZString keyname(CInt);
extern fn CInt keypad(Window *, bool);
extern fn char killchar();
extern fn CInt leaveok(Window *, bool);
extern fn ZString longname();
extern fn CInt meta(Window *, bool);
extern fn CInt move(CInt, CInt);
extern fn CInt mvaddch(CInt, CInt, Chtype);
extern fn CInt mvaddchnstr(CInt, CInt, Chtype *, CInt);
extern fn CInt mvaddchstr(CInt, CInt, Chtype *);
extern fn CInt mvaddnstr(CInt, CInt, ZString, CInt);
extern fn CInt mvaddstr(CInt, CInt, ZString);
extern fn CInt mvchgat(CInt, CInt, CInt, Attr_t, CShort, void *);
extern fn CInt mvcur(CInt, CInt, CInt, CInt);
extern fn CInt mvdelch(CInt, CInt);
extern fn CInt mvderwin(Window *, CInt, CInt);
extern fn CInt mvgetch(CInt, CInt);
extern fn CInt mvgetnstr(CInt, CInt, ZString, CInt);
extern fn CInt mvgetstr(CInt, CInt, ZString);
extern fn CInt mvhline(CInt, CInt, Chtype, CInt);
extern fn Chtype mvinch(CInt, CInt);
extern fn CInt mvinchnstr(CInt, CInt, Chtype *, CInt);
extern fn CInt mvinchstr(CInt, CInt, Chtype *);
extern fn CInt mvinnstr(CInt, CInt, ZString, CInt);
extern fn CInt mvinsch(CInt, CInt, Chtype);
extern fn CInt mvinsnstr(CInt, CInt, ZString, CInt);
extern fn CInt mvinsstr(CInt, CInt, ZString);
extern fn CInt mvinstr(CInt, CInt, ZString);
extern fn CInt mvprintw(CInt, CInt, ZString, ...);
extern fn CInt mvscanw(CInt, CInt, ZString, ...);
extern fn CInt mvvline(CInt, CInt, Chtype, CInt);
extern fn CInt mvwaddch(Window *, CInt, CInt, Chtype);
extern fn CInt mvwaddchnstr(Window *, CInt, CInt, Chtype *, CInt);
extern fn CInt mvwaddchstr(Window *, CInt, CInt, Chtype *);
extern fn CInt mvwaddnstr(Window *, CInt, CInt, ZString, CInt);
extern fn CInt mvwaddstr(Window *, CInt, CInt, ZString);
extern fn CInt mvwchgat(Window *, CInt, CInt, CInt, Attr_t, CShort, void *);
extern fn CInt mvwdelch(Window *, CInt, CInt);
extern fn CInt mvwgetch(Window *, CInt, CInt);
extern fn CInt mvwgetnstr(Window *, CInt, CInt, ZString, CInt);
extern fn CInt mvwgetstr(Window *, CInt, CInt, ZString);
extern fn CInt mvwhline(Window *, CInt, CInt, Chtype, CInt);
extern fn CInt mvwin(Window *, CInt, CInt);
extern fn Chtype mvwinch(Window *, CInt, CInt);
extern fn CInt mvwinchnstr(Window *, CInt, CInt, Chtype *, CInt);
extern fn CInt mvwinchstr(Window *, CInt, CInt, Chtype *);
extern fn CInt mvwinnstr(Window *, CInt, CInt, ZString, CInt);
extern fn CInt mvwinsch(Window *, CInt, CInt, Chtype);
extern fn CInt mvwinsnstr(Window *, CInt, CInt, ZString, CInt);
extern fn CInt mvwinsstr(Window *, CInt, CInt, ZString);
extern fn CInt mvwinstr(Window *, CInt, CInt, ZString);
extern fn CInt mvwprintw(Window *, CInt, CInt, ZString, ...);
extern fn CInt mvwscanw(Window *, CInt, CInt, ZString, ...);
extern fn CInt mvwvline(Window *, CInt, CInt, Chtype, CInt);
extern fn CInt napms(CInt);
extern fn Window *newpad(CInt, CInt);
extern fn Screen *newterm(ZString, File *, File *);
extern fn Window *newwin(CInt, CInt, CInt, CInt);
extern fn CInt nl();
extern fn CInt nocbreak();
extern fn CInt nodelay(Window *, bool);
extern fn CInt noecho();
extern fn CInt nonl();
extern fn void noqiflush();
extern fn CInt noraw();
extern fn CInt notimeout(Window *, bool);
extern fn CInt overlay(Window *, Window *);
extern fn CInt overwrite(Window *, Window *);
extern fn CInt pair_content(CShort, CShort *, CShort *);
extern fn CInt pair_number(CInt) @extern("PAIR_NUMBER");
extern fn CInt pechochar(Window *, Chtype);
extern fn CInt pnoutrefresh(Window *, CInt, CInt, CInt, CInt, CInt, CInt);
extern fn CInt prefresh(Window *, CInt, CInt, CInt, CInt, CInt, CInt);
extern fn CInt printw(ZString, ...);
extern fn CInt putwin(Window *, File *);
extern fn void qiflush();
extern fn CInt raw();
extern fn CInt redrawwin(Window *);
extern fn CInt refresh();
extern fn CInt resetty();
extern fn CInt reset_prog_mode();
extern fn CInt reset_shell_mode();
// ---
// Callback for this specific function.
def RipOffline_CB = fn CInt(Window *, CInt);
extern fn CInt ripoffline(CInt, RipOffline_CB);
// ---
extern fn CInt savetty();
extern fn CInt scanw(ZString, ...);
extern fn CInt scr_dump(ZString);
extern fn CInt scr_init(ZString);
extern fn CInt scrl(CInt);
extern fn CInt scroll(Window *);
extern fn CInt scrollok(Window *, bool);
extern fn CInt scr_restore(ZString);
extern fn CInt scr_set(ZString);
extern fn CInt setscrreg(CInt, CInt);
extern fn Screen *set_term(Screen *);
extern fn CInt slk_attroff(Chtype);
extern fn CInt slk_attr_off(Attr_t, void *);
extern fn CInt slk_attron(Chtype);
extern fn CInt slk_attr_on(Attr_t, void *);
extern fn CInt slk_attrset(Chtype);
extern fn Attr_t slk_attr();
extern fn CInt slk_attr_set(Attr_t, CShort, void *);
extern fn CInt slk_clear();
extern fn CInt slk_color(CShort);
extern fn CInt slk_init(CInt);
extern fn ZString slk_label(CInt);
extern fn CInt slk_noutrefresh();
extern fn CInt slk_refresh();
extern fn CInt slk_restore();
extern fn CInt slk_set(CInt, ZString, CInt);
extern fn CInt slk_touch();
extern fn CInt standout();
extern fn CInt standend();
extern fn CInt start_color();
extern fn Window *subpad(Window *, CInt, CInt, CInt, CInt);
extern fn Window *subwin(Window *, CInt, CInt, CInt, CInt);
extern fn CInt syncok(Window *, bool);
extern fn Chtype termattrs();
extern fn ZString termname();
extern fn void timeout(CInt);
extern fn CInt touchline(Window *, CInt, CInt);
extern fn CInt touchwin(Window *);
extern fn CInt typeahead(CInt);
extern fn CInt ungetch(CInt);
extern fn CInt untouchwin(Window *);
extern fn void use_env(bool);
extern fn void use_tioctl(bool);
extern fn CInt vidattr(Chtype);
extern fn CInt vidputs(Chtype, OutC);
extern fn CInt vline(Chtype, CInt);
// FIXME: '...' was of type 'va_list', can this be a problem in the future?
extern fn CInt vwprintw(Window *, ZString, ...);
extern fn CInt vw_printw(Window *, ZString, ...);
extern fn CInt vwscanw(Window *, ZString, ...);
extern fn CInt vw_scanw(Window *, ZString, ...);
// -----
extern fn CInt waddch(Window *, Chtype);
extern fn CInt waddchnstr(Window *, Chtype *, CInt);
extern fn CInt waddchstr(Window *, Chtype *);
extern fn CInt waddnstr(Window *, ZString, CInt);
extern fn CInt waddstr(Window *, ZString);
extern fn CInt wattron(Window *, CInt);
extern fn CInt wattroff(Window *, CInt);
extern fn CInt wattrset(Window *, CInt);
extern fn CInt wattr_get(Window *, Attr_t *, CShort *, void *);
extern fn CInt wattr_on(Window *, Attr_t, void *);
extern fn CInt wattr_off(Window *, Attr_t, void *);
extern fn CInt wattr_set(Window *, Attr_t, CShort, void *);
extern fn CInt wbkgd(Window *, Chtype);
extern fn void wbkgdset(Window *, Chtype);
extern fn CInt wborder(Window *, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype, Chtype);
extern fn CInt wchgat(Window *, CInt, Attr_t, CShort, void *);
extern fn CInt wclear(Window *);
extern fn CInt wclrtobot(Window *);
extern fn CInt wclrtoeol(Window *);
extern fn CInt wcolor_set(Window *, CShort, void *);
extern fn void wcursyncup(Window *);
extern fn CInt wdelch(Window *);
extern fn CInt wdeleteln(Window *);
extern fn CInt wechochar(Window *, Chtype);
extern fn CInt werase(Window *);
extern fn CInt wgetch(Window *);
extern fn CInt wgetnstr(Window *, ZString, CInt);
extern fn CInt wgetstr(Window *, ZString);
extern fn CInt whline(Window *, Chtype, CInt);
extern fn Chtype winch(Window *);
extern fn CInt winchnstr(Window *, Chtype *, CInt);
extern fn CInt winchstr(Window *, Chtype *);
extern fn CInt winnstr(Window *, ZString, CInt);
extern fn CInt winsch(Window *, Chtype);
extern fn CInt winsdelln(Window *, CInt);
extern fn CInt winsertln(Window *);
extern fn CInt winsnstr(Window *, ZString, CInt);
extern fn CInt winsstr(Window *, ZString);
extern fn CInt winstr(Window *, ZString);
extern fn CInt wmove(Window *, CInt, CInt);
extern fn CInt wnoutrefresh(Window *);
extern fn CInt wprintw(Window *, ZString, ...);
extern fn CInt wredrawln(Window *, CInt, CInt);
extern fn CInt wrefresh(Window *);
extern fn CInt wscanw(Window *, ZString, ...);
extern fn CInt wscrl(Window *, CInt);
extern fn CInt wsetscrreg(Window *, CInt, CInt);
extern fn CInt wstandout(Window *);
extern fn CInt wstandend(Window *);
extern fn void wsyncdown(Window *);
extern fn void wsyncup(Window *);
extern fn void wtimeout(Window *, CInt);
extern fn CInt wtouchln(Window *, CInt, CInt, CInt);
extern fn CInt wvline(Window *, Chtype, CInt);

/*
 * These are also declared in <ncursesw/term.h>:
 */
extern fn CInt tigetflag(ZString);
extern fn CInt tigetnum(ZString);
extern fn ZString tigetstr(ZString);
extern fn CInt putp(ZString);

extern fn ZString tparm(ZString, ...);

extern fn ZString tiparm(ZString, ...);
extern fn ZString tiparm_s(CInt, CInt, ZString, ...);
extern fn CInt tiscan_s(CInt *, CInt *, ZString);

/*
 * These functions are not in X/Open, but we use them in macro definitions:
 */
extern fn CInt getattrs(Window *);
extern fn CInt getcurx(Window *);
extern fn CInt getcury(Window *);
extern fn CInt getbegx(Window *);
extern fn CInt getbegy(Window *);
extern fn CInt getmaxx(Window *);
extern fn CInt getmaxy(Window *);
extern fn CInt getparx(Window *);
extern fn CInt getpary(Window *);

/*
 * These functions are extensions - not in X/Open Curses.
 */
const EXT_FUNCS = 20240427;

def Window_CB = fn int(Window *, void *);
def Screen_CB = fn int(Screen *, void *);

extern fn CInt alloc_pair(CInt, CInt);
extern fn CInt assume_default_colors(CInt, CInt);
extern fn ZString curses_version();
extern fn CInt define_key(ZString, CInt);
extern fn CInt extended_color_content(CInt, CInt *, CInt *, CInt *);
extern fn CInt extended_pair_content(CInt, CInt *, CInt *);
extern fn CInt extended_slk_color(CInt);
extern fn CInt find_pair(CInt, CInt);
extern fn CInt free_pair(CInt);
extern fn CInt get_escdelay();
extern fn CInt init_extended_color(CInt, CInt, CInt, CInt);
extern fn CInt init_extended_pair(CInt, CInt, CInt);
extern fn CInt is_cbreak();
extern fn CInt is_echo();
extern fn CInt is_nl();
extern fn CInt is_raw();
extern fn bool is_term_resized(CInt, CInt);
extern fn CInt key_defined(ZString);
extern fn ZString keybound(CInt, CInt);
extern fn CInt keyok(CInt, bool);
extern fn void nofilter();
extern fn void reset_color_pairs();
extern fn CInt resize_term(CInt, CInt);
extern fn CInt resizeterm(CInt, CInt);
extern fn CInt set_escdelay(CInt);
extern fn CInt set_tabsize(CInt);
extern fn CInt use_default_colors();
extern fn CInt use_legacy_coding(CInt);
extern fn CInt use_screen(Screen *, Screen_CB, void *);
extern fn CInt use_window(Window *, Window_CB, void *);
extern fn CInt wresize(Window *, CInt, CInt);

const XNAMES = 1;
extern fn int use_extended_names(bool);

/*
 * These extensions provide access to information stored in the WINDOW even
 * when NCURSES_OPAQUE is set:
 */
extern fn Window *wgetparent(Window *);
extern fn bool is_cleared(Window *);
extern fn bool is_idcok(Window *);
extern fn bool is_idlok(Window *);
extern fn bool is_immedok(Window *);
extern fn bool is_keypad(Window *);
extern fn bool is_leaveok(Window *);
extern fn bool is_nodelay(Window *);
extern fn bool is_notimeout(Window *);
extern fn bool is_pad(Window *);
extern fn bool is_scrollok(Window *);
extern fn bool is_subwin(Window *);
extern fn bool is_syncok(Window *);
extern fn CInt wgetdelay(Window *);
extern fn CInt wgetscrreg(Window *, CInt *, CInt *);

/*
 * Extra extension-functions, which pass a SCREEN pointer rather than using
 * a global variable SP.
 */
const SP_FUNCS = 20240427;

/* Define the sp-funcs helper function */
def OutC_Sp = fn CInt(Screen *, CInt);

extern fn Screen *new_prescr();

extern fn CInt baudrate_sp(Screen *);
extern fn CInt beep_sp(Screen *);
extern fn bool can_change_color_sp(Screen *);
extern fn CInt cbreak_sp(Screen *);
extern fn CInt curs_set_sp(Screen *, CInt);
extern fn CInt color_content_sp(Screen *, CShort, CShort *, CShort *, CShort *);
extern fn CInt def_prog_mode_sp(Screen *);
extern fn CInt def_shell_mode_sp(Screen *);
extern fn CInt delay_output_sp(Screen *, CInt);
extern fn CInt doupdate_sp(Screen *);
extern fn CInt echo_sp(Screen *);
extern fn CInt endwin_sp(Screen *);
extern fn char erasechar_sp(Screen *);
extern fn void filter_sp(Screen *);
extern fn CInt flash_sp(Screen *);
extern fn CInt flushinp_sp(Screen *);
extern fn Window *getwin_sp(Screen *, File *);
extern fn CInt halfdelay_sp(Screen *, CInt);
extern fn bool has_colors_sp(Screen *);
extern fn bool has_ic_sp(Screen *);
extern fn bool has_il_sp(Screen *);
extern fn CInt init_color_sp(Screen *, CShort, CShort, CShort, CShort);
extern fn CInt init_pair_sp(Screen *, CShort, CShort, CShort);
extern fn CInt intrflush_sp(Screen *, Window *, bool);
extern fn bool isendwin_sp(Screen *);
extern fn ZString keyname_sp(Screen *, CInt);
extern fn char killchar_sp(Screen *);
extern fn ZString longname_sp(Screen *);
extern fn CInt mvcur_sp(Screen *, CInt, CInt, CInt, CInt);
extern fn CInt napms_sp(Screen *, CInt);
extern fn Window *newpad_sp(Screen *, CInt, CInt);
extern fn Screen * newterm_sp(Screen *, ZString, File *, File *);
extern fn Window *newwin_sp(Screen *, CInt, CInt, CInt, CInt);
extern fn CInt nl_sp(Screen *);
extern fn CInt nocbreak_sp(Screen *);
extern fn CInt noecho_sp(Screen *);
extern fn CInt nonl_sp(Screen *);
extern fn void noqiflush_sp(Screen *);
extern fn CInt noraw_sp(Screen *);
extern fn CInt pair_content_sp(Screen *, CShort, CShort *, CShort *);
extern fn void qiflush_sp(Screen *);
extern fn CInt raw_sp(Screen *);
extern fn CInt reset_prog_mode_sp(Screen *);
extern fn CInt reset_shell_mode_sp(Screen *);
extern fn CInt resetty_sp(Screen *);
// ---
// Callback for this specific function already defined.
extern fn CInt ripoffline_sp(Screen *, CInt, RipOffline_CB);
// ---
extern fn CInt savetty_sp(Screen *);
extern fn CInt scr_init_sp(Screen *, ZString);
extern fn CInt scr_restore_sp(Screen *, ZString);
extern fn CInt scr_set_sp(Screen *, ZString);
extern fn CInt slk_attroff_sp(Screen *, Chtype);
extern fn CInt slk_attron_sp(Screen *, Chtype);
extern fn CInt slk_attrset_sp(Screen *, Chtype);
extern fn Attr_t slk_attr_sp(Screen *);
extern fn CInt slk_attr_set_sp(Screen *, Attr_t, CShort, void *);
extern fn CInt slk_clear_sp(Screen *);
extern fn CInt slk_color_sp(Screen *, CShort);
extern fn CInt slk_init_sp(Screen *, CInt);
extern fn ZString slk_label_sp(Screen *, CInt);
extern fn CInt slk_noutrefresh_sp(Screen *);
extern fn CInt slk_refresh_sp(Screen *);
extern fn CInt slk_restore_sp(Screen *);
extern fn CInt slk_set_sp(Screen *, CInt, ZString, CInt);
extern fn CInt slk_touch_sp(Screen *);
extern fn CInt start_color_sp(Screen *);
extern fn Chtype termattrs_sp(Screen *);
extern fn ZString termname_sp(Screen *);
extern fn CInt typeahead_sp(Screen *, CInt);
extern fn CInt ungetch_sp(Screen *, CInt);
extern fn void use_env_sp(Screen *, bool);
extern fn void use_tioctl_sp(Screen *, bool);
extern fn CInt vidattr_sp(Screen *, Chtype);
extern fn CInt vidputs_sp(Screen *, Chtype, OutC_Sp);
extern fn CInt alloc_pair_sp(Screen *, CInt, CInt);
extern fn CInt assume_default_colors_sp(Screen *, CInt, CInt);
extern fn CInt define_key_sp(Screen *, ZString, CInt);
extern fn CInt extended_color_content_sp(Screen *, CInt, CInt *, CInt *, CInt *);
extern fn CInt extended_pair_content_sp(Screen *, CInt, CInt *, CInt *);
extern fn CInt extended_slk_color_sp(Screen *, CInt);
extern fn CInt find_pair_sp(Screen *, CInt, CInt);
extern fn CInt free_pair_sp(Screen *, CInt);
extern fn CInt get_escdelay_sp(Screen *);
extern fn CInt init_extended_color_sp(Screen *, CInt, CInt, CInt, CInt);
extern fn CInt init_extended_pair_sp(Screen *, CInt, CInt, CInt);
extern fn CInt is_cbreak_sp(Screen *);
extern fn CInt is_echo_sp(Screen *);
extern fn CInt is_nl_sp(Screen *);
extern fn CInt is_raw_sp(Screen *);
extern fn bool is_term_resized_sp(Screen *, CInt, CInt);
extern fn CInt key_defined_sp(Screen *, ZString);
extern fn ZString keybound_sp(Screen *, CInt, CInt);
extern fn CInt keyok_sp(Screen *, CInt, bool);
extern fn void nofilter_sp(Screen *);
extern fn void reset_color_pairs_sp(Screen *);
extern fn CInt resize_term_sp(Screen *, CInt, CInt);
extern fn CInt resizeterm_sp(Screen *, CInt, CInt);
extern fn CInt set_escdelay_sp(Screen *, CInt);
extern fn CInt set_tabsize_sp(Screen *, CInt);
extern fn CInt use_default_colors_sp(Screen *);
extern fn CInt use_legacy_coding_sp(Screen *, CInt);


/* attributes */

const ATTR_SHIFT = 8;
// NOTE: this function-like macro differs from C because of the macro-rules of C3.
macro @bits($mask, $shift) => ((Chtype)$mask << ($shift + ATTR_SHIFT));

const A_NORMAL     = (1U - 1U);
const A_ATTRIBUTES = @bits(~(1U - 1U), 0);
const A_CHARTEXT   = (@bits(1U,0) - 1U);
const A_COLOR      = @bits(((1U) << 8) - 1U, 0);
const A_STANDOUT   = @bits(1U, 8);
const A_UNDERLINE  = @bits(1U, 9);
const A_REVERSE    = @bits(1U, 10);
const A_BLINK      = @bits(1U, 11);
const A_DIM        = @bits(1U, 12);
const A_BOLD       = @bits(1U, 13);
const A_ALTCHARSET = @bits(1U, 14);
const A_INVIS      = @bits(1U, 15);
const A_PROTECT    = @bits(1U, 16);
const A_HORIZONTAL = @bits(1U, 17);
const A_LEFT       = @bits(1U, 18);
const A_LOW        = @bits(1U, 19);
const A_RIGHT      = @bits(1U, 20);
const A_TOP        = @bits(1U, 21);
const A_VERTICAL   = @bits(1U, 22);
const A_ITALIC     = @bits(1U, 23);

/*
 * Most of the pseudo functions are macros that either provide compatibility
 * with older versions of curses, or provide inline functionality to improve
 * performance.
 */

/*
 * These pseudo functions are always implemented as macros:
 */

// NOTE: this function-like macros differ from C because of the macro-rules of C3.

macro @getyx(win, #y, #x)
{
    #y = getcury(win);
    #x = getcurx(win);
}

macro @getbegyx(win, #y, #x)
{
    #y = getbegy(win);
    #x = getbegx(win);
}

macro @getmaxyx(win, #y, #x)
{
    #y = getmaxy(win);
    #x = getmaxx(win);
}

macro @getparyx(win, #y, #x)
{
    #y = getpary(win);
    #x = getparx(win);
}

macro @getsyx(#y, #x)
{
    if (is_leaveok(newscr))
    {
        #x = #y = -1;
    }
    else
    {
        getyx(newscr, #y, #x);
    }
}

macro @setsyx(#y, #x)
{
    if (*y == -1 && *x == -1)
    {
        leaveok(newscr, true);
    }
    else
    {
        leaveok(newscr, false);
        wmove(newscr, *y, *x);
    }
}

/*
 * These miscellaneous pseudo functions are provided for compatibility:
 */

// NOTE: compatibility macros commented out are conflicting with external
// functions declared above.

// macro wgetstr(w, s) => wgetnstr(w, s, -1);
// macro getnstr(s, n) => wgetnstr(stdscr, s, n);

macro setterm(term) => setupterm(term, 1, (int *)0);

macro fixterm()     => reset_prog_mode();
macro resetterm()   => reset_shell_mode();
macro saveterm()    => def_prog_mode();
macro crmode()      => cbreak();
macro nocrmode()    => nocbreak();
macro gettmode()
{
}

// macro wstandout(win)    => (wattrset(win, A_STANDOUT));
// macro wstandend(win)    => (wattrset(win, A_NORMAL));

// macro wattron(win, at)  => wattr_on(win, (Attr_t)at, null);
// macro wattroff(win, at) => wattr_off(win, (Attr_t)at, null);

// macro scroll(win) => wscrl(win, 1);

// macro touchwin(win)        => wtouchln(win, 0, getmaxy(win), 1);
// macro touchline(win, s, c) => wtouchln(win, s, c, 1);
// macro untouchwin(win)      => wtouchln(win, 0, getmaxy(win), 0);

// macro box(win, v, h)                         => wborder(win, v, v, h, h, 0, 0, 0, 0);
// macro border(ls, rs, ts, bs, tl, tr, bl, br) => wborder(stdscr, ls, rs, ts, bs, tl, tr, bl, br);
// macro hline(ch, n)                           => whline(stdscr, ch, n);
// macro vline(ch, n)                           => wvline(stdscr, ch, n);

// macro winstr(w, s)   => winnstr(w, s, -1);
// macro winchstr(w, s) => winchnstr(w, s, -1);
// macro winsstr(w, s)  => winsnstr(w, s, -1);

// macro waddstr(win, str)   => waddnstr(win, str, -1);
// macro waddchstr(win, str) => waddchnstr(win, str, -1);

/*
 * These apply to the first 256 color pairs.
 */
// macro color_pair(n)  => @bits(n, 0) & A_COLOR;
// macro pair_number(a) => ((CInt)((CLong)a) & A_COLOR) >> ATTR_SHIFT;

/*
 * pseudo functions for standard screen
 */

// macro addch(ch)           => waddch(stdscr, ch);
// macro addchnstr(str, n)   => waddchnstr(stdscr, str, n);
// macro addchstr(str)       => waddchstr(stdscr, str);
// macro addnstr(str, n)     => waddnstr(stdscr, str, n);
// macro addstr(str)         => waddnstr(stdscr, str, -1);
// macro attr_get(ap, cp, o) => wattr_get(stdscr, ap, cp, o);
// macro attr_off(a, o)      => wattr_off(stdscr, a, o);
// macro attr_on(a, o)       => wattr_on(stdscr, a, o);
// macro attr_set(a, c, o)   => wattr_set(stdscr, a, c, o);
// macro attroff(at)         => wattroff(stdscr, at);
// macro attron(at)          => wattron(stdscr, at);
// macro attrset(at)         => wattrset(stdscr, at);
// macro bkgd(ch)            => wbkgd(stdscr, ch);
// macro bkgdset(ch)         => wbkgdset(stdscr, ch);
// macro chgat(n, a, c, o)   => wchgat(stdscr, n, a, c, o);
// macro clear()             => wclear(stdscr);
// macro clrtobot()          => wclrtobot(stdscr);
// macro clrtoeol()          => wclrtoeol(stdscr);
// macro color_set(c, o)     => wcolor_set(stdscr, c, o);
// macro delch()             => wdelch(stdscr);
// macro deleteln()          => winsdelln(stdscr, -1);
// macro echochar(c)         => wechochar(stdscr, c);
// macro erase()             => werase(stdscr);
// macro getch()             => wgetch(stdscr);
// macro getstr(str)         => wgetstr(stdscr, str);
// macro inch()              => winch(stdscr);
// macro inchnstr(s, n)      => winchnstr(stdscr, s, n);
// macro inchstr(s)          => winchstr(stdscr, s);
// macro innstr(s, n)        => winnstr(stdscr, s, n);
// macro insch(c)            => winsch(stdscr, c);
// macro insdelln(n)         => winsdelln(stdscr, n);
// macro insertln()          => winsdelln(stdscr, 1);
// macro insnstr(s, n)       => winsnstr(stdscr, s, n);
// macro insstr(s)           => winsstr(stdscr, s);
// macro instr(s)            => winstr(stdscr, s);
// macro move(y, x)          => wmove(stdscr, y, x);
// macro refresh()           => wrefresh(stdscr);
// macro scrl(n)             => wscrl(stdscr, n);
// macro setscrreg(t, b)     => wsetscrreg(stdscr, t, b);
// macro standend()          => wstandend(stdscr);
// macro standout()          => wstandout(stdscr);
// macro timeout(delay)      => wtimeout(stdscr, delay);
// macro wdeleteln(win)      => winsdelln(win, -1);
// macro winsertln(win)      => winsdelln(win, 1);

/*
 * mv functions
 */

// macro mvwaddch(win, y, x, ch)         => (wmove(win, y, x) == ERR ? ERR : waddch(win, ch));
// macro mvwaddchnstr(win, y, x, str, n) => (wmove(win, y, x) == ERR ? ERR : waddchnstr(win, str, n));
// macro mvwaddchstr(win, y, x, str)     => (wmove(win, y, x) == ERR ? ERR : waddchnstr(win, str, -1));
// macro mvwaddnstr(win, y, x, str, n)   => (wmove(win, y, x) == ERR ? ERR : waddnstr(win, str, n));
// macro mvwaddstr(win, y, x, str)       => (wmove(win, y, x) == ERR ? ERR : waddnstr(win, str, -1));
// macro mvwchgat(win, y, x, n, a, c, o) => (wmove(win, y, x) == ERR ? ERR : wchgat(win, n, a, c, o));
// macro mvwdelch(win, y, x)             => (wmove(win, y, x) == ERR ? ERR : wdelch(win));
// macro mvwgetch(win, y, x)             => (wmove(win, y, x) == ERR ? ERR : wgetch(win));
// macro mvwgetnstr(win, y, x, str, n)   => (wmove(win, y, x) == ERR ? ERR : wgetnstr(win, str, n));
// macro mvwgetstr(win, y, x, str)       => (wmove(win, y, x) == ERR ? ERR : wgetstr(win, str));
// macro mvwhline(win, y, x, c, n)       => (wmove(win, y, x) == ERR ? ERR : whline(win, c, n));
// macro mvwinch(win, y, x)              => (wmove(win, y, x) == ERR ? (Chtype)ERR : winch(win));
// macro mvwinchnstr(win, y, x, s, n)    => (wmove(win, y, x) == ERR ? ERR : winchnstr(win, s, n));
// macro mvwinchstr(win, y, x, s)        => (wmove(win, y, x) == ERR ? ERR : winchstr(win, s));
// macro mvwinnstr(win, y, x, s, n)      => (wmove(win, y, x) == ERR ? ERR : winnstr(win, s, n));
// macro mvwinsch(win, y, x, c)          => (wmove(win, y, x) == ERR ? ERR : winsch(win, c));
// macro mvwinsnstr(win, y, x, s, n)     => (wmove(win, y, x) == ERR ? ERR : winsnstr(win, s, n));
// macro mvwinsstr(win, y, x, s)         => (wmove(win, y, x) == ERR ? ERR : winsstr(win, s));
// macro mvwinstr(win, y, x, s)          => (wmove(win, y, x) == ERR ? ERR : winstr(win, s));
// macro mvwvline(win, y, x, c, n)       => (wmove(win, y, x) == ERR ? ERR : wvline(win, c, n));

// macro mvaddch(y, x, ch)         => mvwaddch(stdscr, y, x, ch);
// macro mvaddchnstr(y, x, str, n) => mvwaddchnstr(stdscr, y, x, str, n);
// macro mvaddchstr(y, x, str)     => mvwaddchstr(stdscr, y, x, str);
// macro mvaddnstr(y, x, str, n)   => mvwaddnstr(stdscr, y, x, str, n);
// macro mvaddstr(y, x, str)       => mvwaddstr(stdscr, y, x, str);
// macro mvchgat(y, x, n, a, c, o) => mvwchgat(stdscr, y, x, n, a, c, o);
// macro mvdelch(y, x)             => mvwdelch(stdscr, y, x);
// macro mvgetch(y, x)             => mvwgetch(stdscr, y, x);
// macro mvgetnstr(y, x, str, n)   => mvwgetnstr(stdscr, y, x, str, n);
// macro mvgetstr(y, x, str)       => mvwgetstr(stdscr, y, x, str);
// macro mvhline(y, x, c, n)       => mvwhline(stdscr, y, x, c, n);
// macro mvinch(y, x)              => mvwinch(stdscr, y, x);
// macro mvinchnstr(y, x, s, n)    => mvwinchnstr(stdscr, y, x, s, n);
// macro mvinchstr(y, x, s)        => mvwinchstr(stdscr, y, x, s);
// macro mvinnstr(y, x, s, n)      => mvwinnstr(stdscr, y, x, s, n);
// macro mvinsch(y, x, c)          => mvwinsch(stdscr, y, x, c);
// macro mvinsnstr(y, x, s, n)     => mvwinsnstr(stdscr, y, x, s, n);
// macro mvinsstr(y, x, s)         => mvwinsstr(stdscr, y, x, s);
// macro mvinstr(y, x, s)          => mvwinstr(stdscr, y, x, s);
// macro mvvline(y, x, c, n)       => mvwvline(stdscr, y, x, c, n);

// macro slk_attr_off(a, v) => (v ? ERR : slk_attroff(a));
// macro slk_attr_on(a, v)  => (v ? ERR : slk_attron(a));

/*
 * X/Open says this returns a bool; SVr4 also checked for out-of-range line.
 * The macro provides compatibility:
 */
// macro is_linetouched(w, l) ((!w || (l > getmaxy(w)) || (l < 0)) ? ERR : is_linetouched(w,l));

/*
 * Public variables.
 *
 * Notes:
 *	a. ESCDELAY was an undocumented feature under AIX curses.
 *	   It gives the ESC expire time in milliseconds.
 *	b. ttytype is needed for backward compatibility
 */
extern Window *curscr;
extern Window *newscr;
extern Window *stdscr;
extern char[] ttytype;

// NOTE: this externs differ from C because of the C3 naming rules.
extern CInt colors @extern("COLORS");
extern CInt color_pairs @extern("COLOR_PAIRS");
extern CInt cols @extern("COLS");
extern CInt escdelay @extern("ESCDELAY");
extern CInt lines @extern("LINES");
extern CInt tabsize @extern("TABSIZE");

/*
 * Pseudo-character tokens outside ASCII range.  The curses wgetch() function
 * will return any given one of these only if the corresponding k- capability
 * is defined in your terminal's terminfo entry.
 *
 * Some keys (KEY_A1, etc) are arranged like this:
 *	a1     up    a3
 *	left   b2    right
 *	c1     down  c3
 *
 * A few key codes do not depend upon the terminfo entry.
 */

const KEY_CODE_YES = 0o400;  /* A wchar_t contains a key code */
const KEY_MIN      = 0o401;  /* Minimum curses key */
const KEY_BREAK    = 0o401;  /* Break key (unreliable) */
const KEY_SRESET   = 0o530;  /* Soft (partial) reset (unreliable) */
const KEY_RESET    = 0o531;  /* Reset or hard reset (unreliable) */
/*
 * These definitions were generated by ./MKkey_defs.sh ./Caps ./Caps-ncurses
 */
const KEY_DOWN      = 0o402; /* down-arrow key */
const KEY_UP        = 0o403; /* up-arrow key */
const KEY_LEFT      = 0o404; /* left-arrow key */
const KEY_RIGHT     = 0o405; /* right-arrow key */
const KEY_HOME      = 0o406; /* home key */
const KEY_BACKSPACE = 0o407; /* backspace key */
const KEY_F0        = 0o410; /* Function keys.  Space for 64 */
// ---
// NOTE: this differ from C because of the C3 naming rules.
macro key_f(n) => (KEY_F0 + n);	/* Value of function key n */
// ---
const KEY_DL        = 0o510; /* delete-line key */
const KEY_IL        = 0o511; /* insert-line key */
const KEY_DC        = 0o512; /* delete-character key */
const KEY_IC        = 0o513; /* insert-character key */
const KEY_EIC       = 0o514; /* sent by rmir or smir in insert mode */
const KEY_CLEAR     = 0o515; /* clear-screen or erase key */
const KEY_EOS       = 0o516; /* clear-to-end-of-screen key */
const KEY_EOL       = 0o517; /* clear-to-end-of-line key */
const KEY_SF        = 0o520; /* scroll-forward key */
const KEY_SR        = 0o521; /* scroll-backward key */
const KEY_NPAGE     = 0o522; /* next-page key */
const KEY_PPAGE     = 0o523; /* previous-page key */
const KEY_STAB      = 0o524; /* set-tab key */
const KEY_CTAB      = 0o525; /* clear-tab key */
const KEY_CATAB     = 0o526; /* clear-all-tabs key */
const KEY_ENTER     = 0o527; /* enter/send key */
const KEY_PRINT     = 0o532; /* print key */
const KEY_LL        = 0o533; /* lower-left key (home down) */
const KEY_A1        = 0o534; /* upper left of keypad */
const KEY_A3        = 0o535; /* upper right of keypad */
const KEY_B2        = 0o536; /* center of keypad */
const KEY_C1        = 0o537; /* lower left of keypad */
const KEY_C3        = 0o540; /* lower right of keypad */
const KEY_BTAB      = 0o541; /* back-tab key */
const KEY_BEG       = 0o542; /* begin key */
const KEY_CANCEL    = 0o543; /* cancel key */
const KEY_CLOSE     = 0o544; /* close key */
const KEY_COMMAND   = 0o545; /* command key */
const KEY_COPY      = 0o546; /* copy key */
const KEY_CREATE    = 0o547; /* create key */
const KEY_END       = 0o550; /* end key */
const KEY_EXIT      = 0o551; /* exit key */
const KEY_FIND      = 0o552; /* find key */
const KEY_HELP      = 0o553; /* help key */
const KEY_MARK      = 0o554; /* mark key */
const KEY_MESSAGE   = 0o555; /* message key */
const KEY_MOVE      = 0o556; /* move key */
const KEY_NEXT      = 0o557; /* next key */
const KEY_OPEN      = 0o560; /* open key */
const KEY_OPTIONS   = 0o561; /* options key */
const KEY_PREVIOUS  = 0o562; /* previous key */
const KEY_REDO      = 0o563; /* redo key */
const KEY_REFERENCE = 0o564; /* reference key */
const KEY_REFRESH   = 0o565; /* refresh key */
const KEY_REPLACE   = 0o566; /* replace key */
const KEY_RESTART   = 0o567; /* restart key */
const KEY_RESUME    = 0o570; /* resume key */
const KEY_SAVE      = 0o571; /* save key */
const KEY_SBEG      = 0o572; /* shifted begin key */
const KEY_SCANCEL   = 0o573; /* shifted cancel key */
const KEY_SCOMMAND  = 0o574; /* shifted command key */
const KEY_SCOPY     = 0o575; /* shifted copy key */
const KEY_SCREATE   = 0o576; /* shifted create key */
const KEY_SDC       = 0o577; /* shifted delete-character key */
const KEY_SDL       = 0o600; /* shifted delete-line key */
const KEY_SELECT    = 0o601; /* select key */
const KEY_SEND      = 0o602; /* shifted end key */
const KEY_SEOL      = 0o603; /* shifted clear-to-end-of-line key */
const KEY_SEXIT     = 0o604; /* shifted exit key */
const KEY_SFIND     = 0o605; /* shifted find key */
const KEY_SHELP     = 0o606; /* shifted help key */
const KEY_SHOME     = 0o607; /* shifted home key */
const KEY_SIC       = 0o610; /* shifted insert-character key */
const KEY_SLEFT     = 0o611; /* shifted left-arrow key */
const KEY_SMESSAGE  = 0o612; /* shifted message key */
const KEY_SMOVE     = 0o613; /* shifted move key */
const KEY_SNEXT     = 0o614; /* shifted next key */
const KEY_SOPTIONS  = 0o615; /* shifted options key */
const KEY_SPREVIOUS = 0o616; /* shifted previous key */
const KEY_SPRINT    = 0o617; /* shifted print key */
const KEY_SREDO     = 0o620; /* shifted redo key */
const KEY_SREPLACE  = 0o621; /* shifted replace key */
const KEY_SRIGHT    = 0o622; /* shifted right-arrow key */
const KEY_SRSUME    = 0o623; /* shifted resume key */
const KEY_SSAVE     = 0o624; /* shifted save key */
const KEY_SSUSPEND  = 0o625; /* shifted suspend key */
const KEY_SUNDO     = 0o626; /* shifted undo key */
const KEY_SUSPEND   = 0o627; /* suspend key */
const KEY_UNDO      = 0o630; /* undo key */
const KEY_MOUSE     = 0o631; /* Mouse event has occurred */

const KEY_RESIZE    = 0o632; /* Terminal resize event */

const KEY_MAX       = 0o777; /* Maximum key value is 0632 */

/* $Id: curses.wide,v 1.51 2021/05/22 20:28:29 tom Exp $ */
/*
 * vile:cmode:
 * This file is part of ncurses, designed to be appended after curses.h.in
 * (see that file for the relevant copyright).
 */
extern CChar_t *_nc_wacs;

macro wacs(c) => &_nc_wacs[(CChar)c];

// ---
// NOTE: this part is very different from C because of the strict rules of
// the C3 compiler. Using consts instead of macros will crash the compiler because
// the assignment cannot be evaluated at compile time.
macro wacs_bssb() => wacs('l');
macro wacs_ssbb() => wacs('m');
macro wacs_bbss() => wacs('k');
macro wacs_sbbs() => wacs('j');
macro wacs_sbss() => wacs('u');
macro wacs_sssb() => wacs('t');
macro wacs_ssbs() => wacs('v');
macro wacs_bsss() => wacs('w');
macro wacs_bsbs() => wacs('q');
macro wacs_sbsb() => wacs('x');
macro wacs_ssss() => wacs('n');

macro wacs_ulcorner() => wacs_bssb();
macro wacs_llcorner() => wacs_ssbb();
macro wacs_urcorner() => wacs_bbss();
macro wacs_lrcorner() => wacs_sbbs();
macro wacs_rtee()     => wacs_sbss();
macro wacs_ltee()     => wacs_sssb();
macro wacs_btee()     => wacs_ssbs();
macro wacs_ttee()     => wacs_bsss();
macro wacs_hline()    => wacs_bsbs();
macro wacs_vline()    => wacs_sbsb();
macro wacs_plus()     => wacs_ssss();

macro wacs_s1()      => wacs('o'); /* scan line 1 */
macro wacs_s9()      => wacs('s'); /* scan line 9 */
macro wacs_diamond() => wacs('`'); /* diamond */
macro wacs_ckboard() => wacs('a'); /* checker board */
macro wacs_degree()  => wacs('f'); /* degree symbol */
macro wacs_plminus() => wacs('g'); /* plus/minus */
macro wacs_bullet()  => wacs('~'); /* bullet */

/* Teletype 5410v1 symbols */
macro wacs_larrow()  => wacs(','); /* arrow left */
macro wacs_rarrow()  => wacs('+'); /* arrow right */
macro wacs_darrow()  => wacs('.'); /* arrow down */
macro wacs_uarrow()  => wacs('-'); /* arrow up */
macro wacs_board()   => wacs('h'); /* board of squares */
macro wacs_lantern() => wacs('i'); /* lantern symbol */
macro wacs_block()   => wacs('0'); /* solid square block */

/* ncurses extensions */
macro wacs_s3()       => wacs('p'); /* scan line 3 */
macro wacs_s7()       => wacs('r'); /* scan line 7 */
macro wacs_lequal()   => wacs('y'); /* less/equal */
macro wacs_gequal()   => wacs('z'); /* greater/equal */
macro wacs_pi()       => wacs('{'); /* Pi */
macro wacs_nequal()   => wacs('|'); /* not equal */
macro wacs_sterling() => wacs('}'); /* UK pound sign */

/* double lines */
macro wacs_bddb() => wacs('c');
macro wacs_ddbb() => wacs('d');
macro wacs_bbdd() => wacs('b');
macro wacs_dbbd() => wacs('a');
macro wacs_dbdd() => wacs('g');
macro wacs_dddb() => wacs('f');
macro wacs_ddbd() => wacs('h');
macro wacs_bddd() => wacs('i');
macro wacs_bdbd() => wacs('r');
macro wacs_dbdb() => wacs('y');
macro wacs_dddd() => wacs('e');

macro wacs_d_ulcorner() => wacs_bddb();
macro wacs_d_llcorner() => wacs_ddbb();
macro wacs_d_urcorner() => wacs_bbdd();
macro wacs_d_lrcorner() => wacs_dbbd();
macro wacs_d_rtee()     => wacs_dbdd();
macro wacs_d_ltee()     => wacs_dddb();
macro wacs_d_btee()     => wacs_ddbd();
macro wacs_d_ttee()     => wacs_bddd();
macro wacs_d_hline()    => wacs_bdbd();
macro wacs_d_vline()    => wacs_dbdb();
macro wacs_d_plus()     => wacs_dddd();

/* thick lines */
macro wacs_bttb() => wacs('L');
macro wacs_ttbb() => wacs('M');
macro wacs_bbtt() => wacs('K');
macro wacs_tbbt() => wacs('J');
macro wacs_tbtt() => wacs('U');
macro wacs_tttb() => wacs('T');
macro wacs_ttbt() => wacs('V');
macro wacs_bttt() => wacs('W');
macro wacs_btbt() => wacs('Q');
macro wacs_tbtb() => wacs('X');
macro wacs_tttt() => wacs('N');

macro wacs_t_ulcorner() => wacs_bttb();
macro wacs_t_llcorner() => wacs_ttbb();
macro wacs_t_urcorner() => wacs_bbtt();
macro wacs_t_lrcorner() => wacs_tbbt();
macro wacs_t_rtee()     => wacs_tbtt();
macro wacs_t_ltee()     => wacs_tttb();
macro wacs_t_btee()     => wacs_ttbt();
macro wacs_t_ttee()     => wacs_bttt();
macro wacs_t_hline()    => wacs_btbt();
macro wacs_t_vline()    => wacs_tbtb();
macro wacs_t_plus()     => wacs_tttt();
// ---

/*
 * Function prototypes for wide-character operations.
 *
 * "generated" comments should include ":WIDEC" to make the corresponding
 * functions ifdef'd in lib_gen.c
 *
 * "implemented" comments do not need this marker.
 */

extern fn CInt add_wch(CChar_t *);
extern fn CInt add_wchnstr(CChar_t *, CInt);
extern fn CInt add_wchstr(CChar_t *);
extern fn CInt addnwstr(CInt *, CInt);
extern fn CInt addwstr(CInt *);
extern fn CInt bkgrnd(CChar_t *);
extern fn void bkgrndset(CChar_t *);
extern fn CInt border_set(CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *);
extern fn CInt box_set(Window *, CChar_t *, CChar_t *);
extern fn CInt echo_wchar(CChar_t *);
extern fn CInt erasewchar(CInt *);
extern fn CInt get_wch(CInt *);
extern fn CInt get_wstr(CInt *);
extern fn CInt getbkgrnd(CChar_t *);
extern fn CInt getcchar(CChar_t *, CInt *, Attr_t *, CShort *, void *);
extern fn CInt getn_wstr(CInt *, CInt);
extern fn CInt hline_set(CChar_t *, CInt);
extern fn CInt in_wch(CChar_t *);
extern fn CInt in_wchnstr(CChar_t *, CInt);
extern fn CInt in_wchstr(CChar_t *);
extern fn CInt innwstr(CInt *, CInt);
extern fn CInt ins_nwstr(CInt *, CInt);
extern fn CInt ins_wch(CChar_t *);
extern fn CInt ins_wstr(CInt *);
extern fn CInt inwstr(CInt *);
extern fn ZString key_name(CInt);
extern fn CInt killwchar(CInt *);
extern fn CInt mvadd_wch(CInt, CInt, CChar_t *);
extern fn CInt mvadd_wchnstr(CInt, CInt, CChar_t *, CInt);
extern fn CInt mvadd_wchstr(CInt, CInt, CChar_t *);
extern fn CInt mvaddnwstr(CInt, CInt, CInt *, CInt);
extern fn CInt mvaddwstr(CInt, CInt, CInt *);
extern fn CInt mvget_wch(CInt, CInt, CInt *);
extern fn CInt mvget_wstr(CInt, CInt, CInt *);
extern fn CInt mvgetn_wstr(CInt, CInt, CInt *, CInt);
extern fn CInt mvhline_set(CInt, CInt, CChar_t *, CInt);
extern fn CInt mvin_wch(CInt, CInt, CChar_t *);
extern fn CInt mvin_wchnstr(CInt, CInt, CChar_t *, CInt);
extern fn CInt mvin_wchstr(CInt, CInt, CChar_t *);
extern fn CInt mvinnwstr(CInt, CInt, CInt *, CInt);
extern fn CInt mvins_nwstr(CInt, CInt, CInt *, CInt);
extern fn CInt mvins_wch(CInt, CInt, CChar_t *);
extern fn CInt mvins_wstr(CInt, CInt, CInt *);
extern fn CInt mvinwstr(CInt, CInt, CInt *);
extern fn CInt mvvline_set(CInt, CInt, CChar_t *, CInt);
extern fn CInt mvwadd_wch(Window *, CInt, CInt, CChar_t *);
extern fn CInt mvwadd_wchnstr(Window *, CInt, CInt, CChar_t *, CInt);
extern fn CInt mvwadd_wchstr(Window *, CInt, CInt, CChar_t *);
extern fn CInt mvwaddnwstr(Window *, CInt, CInt, CInt *, CInt);
extern fn CInt mvwaddwstr(Window *, CInt, CInt, CInt *);
extern fn CInt mvwget_wch(Window *, CInt, CInt, CInt *);
extern fn CInt mvwget_wstr(Window *, CInt, CInt, CInt *);
extern fn CInt mvwgetn_wstr(Window *, CInt, CInt, CInt *, CInt);
extern fn CInt mvwhline_set(Window *, CInt, CInt, CChar_t *, CInt);
extern fn CInt mvwin_wch(Window *, CInt, CInt, CChar_t *);
extern fn CInt mvwin_wchnstr(Window *, CInt,CInt, CChar_t *,CInt);
extern fn CInt mvwin_wchstr(Window *, CInt, CInt, CChar_t *);
extern fn CInt mvwinnwstr(Window *, CInt, CInt, CInt *, CInt);
extern fn CInt mvwins_nwstr(Window *, CInt,CInt, CInt *, CInt);
extern fn CInt mvwins_wch(Window *, CInt, CInt, CChar_t *);
extern fn CInt mvwins_wstr(Window *, CInt, CInt, CInt *);
extern fn CInt mvwinwstr(Window *, CInt, CInt, CInt *);
extern fn CInt mvwvline_set(Window *, CInt, CInt, CChar_t *, CInt);
extern fn CInt pecho_wchar(Window *, CChar_t *);
extern fn CInt setcchar(CChar_t *, CInt *, Attr_t, CShort, void *);
extern fn CInt slk_wset(CInt, CInt *, CInt);
extern fn Attr_t term_attrs();
extern fn CInt unget_wch(CInt);
extern fn CInt vid_attr(Attr_t, CShort, void *);
extern fn CInt vid_puts(Attr_t, CShort, void *, OutC);
extern fn CInt vline_set(CChar_t *, CInt);
extern fn CInt wadd_wch(Window *, CChar_t *);
extern fn CInt wadd_wchnstr(Window *, CChar_t *, CInt);
extern fn CInt wadd_wchstr(Window *, CChar_t *);
extern fn CInt waddnwstr(Window *, CInt *, CInt);
extern fn CInt waddwstr(Window *, CInt *);
extern fn CInt wbkgrnd(Window *,CChar_t *);
extern fn void wbkgrndset(Window *, CChar_t *);
extern fn CInt wborder_set(Window *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *, CChar_t *);
extern fn CInt wecho_wchar(Window *, CChar_t *);
extern fn CInt wget_wch(Window *, CInt *);
extern fn CInt wget_wstr(Window *, CInt *);
extern fn CInt wgetbkgrnd(Window *, CChar_t *);
extern fn CInt wgetn_wstr(Window *, CInt *, CInt);
extern fn CInt whline_set(Window *, CChar_t *, CInt);
extern fn CInt win_wch(Window *, CChar_t *);
extern fn CInt win_wchnstr(Window *, CChar_t *, CInt);
extern fn CInt win_wchstr(Window *, CChar_t *);
extern fn CInt winnwstr(Window *, CInt *, CInt);
extern fn CInt wins_nwstr(Window *, CInt *, CInt);
extern fn CInt wins_wch(Window *, CChar_t *);
extern fn CInt wins_wstr(Window *, CInt *);
extern fn CInt winwstr(Window *, CInt *);
extern fn CInt *wunctrl(CChar_t *);
extern fn CInt wvline_set(Window *, CChar_t *, CInt);

extern fn Attr_t term_attrs_sp (Screen *);
extern fn CInt erasewchar_sp (Screen *, CInt *);
extern fn CInt killwchar_sp (Screen *, CInt *);
extern fn CInt unget_wch_sp (Screen *, CInt);
extern fn CInt vid_attr_sp (Screen *, Attr_t, CShort, void *);
extern fn CInt vid_puts_sp (Screen *, Attr_t, CShort, void *, OutC);
extern fn CInt *wunctrl_sp (Screen *, CChar_t *);

/*
 * XSI curses macros for XPG4 conformance.
 */

// NOTE: macros commented out are conflicting with external
// functions declared above.

// macro add_wch(c)                             => wadd_wch(stdscr, c);
// macro add_wchnstr(str, n)                    => wadd_wchnstr(stdscr, str, n);
// macro add_wchstr(str)                        => wadd_wchstr(stdscr, str);
// macro addnwstr(wstr, n)                      => waddnwstr(stdscr, wstr, n);
// macro addwstr(wstr)                          => waddwstr(stdscr, wstr);
// macro bkgrnd(c)                              => wbkgrnd(stdscr, c);
// macro bkgrndset(c)                           => wbkgrndset(stdscr, c);
// macro border_set(l, r, t, b, tl, tr, bl, br) => wborder_set(stdscr, l, r, t, b, tl, tr, bl, br);
// macro box_set(w, v, h)                       => wborder_set(w, v, v, h, h, 0, 0, 0, 0);
// macro echo_wchar(c)                          => wecho_wchar(stdscr, c);
// macro get_wch(c)                             => wget_wch(stdscr, c);
// macro get_wstr(t)                            => wget_wstr(stdscr, t);
// macro getbkgrnd(wch)                         => wgetbkgrnd(stdscr, wch);
// macro getn_wstr(t, n)                        => wgetn_wstr(stdscr, t, n);
// macro hline_set(c, n)                        => whline_set(stdscr, c, n);
// macro in_wch(c)                              => win_wch(stdscr, c);
// macro in_wchnstr(c, n)                       => win_wchnstr(stdscr, c, n);
// macro in_wchstr(c)                           => win_wchstr(stdscr, c);
// macro innwstr(c, n)                          => winnwstr(stdscr, c, n);
// macro ins_nwstr(t, n)                        => wins_nwstr(stdscr, t, n);
// macro ins_wch(c)                             => wins_wch(stdscr, c);
// macro ins_wstr(t)                            => wins_wstr(stdscr, t);
// macro inwstr(c)                              => winwstr(stdscr, c);
// macro vline_set(c, n)                        => wvline_set(stdscr, c, n);
// macro wadd_wchstr(win, str)                  => wadd_wchnstr(win, str, -1);
// macro waddwstr(win, wstr)                    => waddnwstr(win, wstr, -1);
// macro wget_wstr(w, t)                        => wgetn_wstr(w, t, -1);
// macro win_wchstr(w, c)                       => win_wchnstr(w, c, -1);
// macro wins_wstr(w, t)                        => wins_nwstr(w, t, -1);

// macro mvadd_wch(y, x, c)              => mvwadd_wch(stdscr, y, x, c);
// macro mvadd_wchnstr(y, x, s, n)       => mvwadd_wchnstr(stdscr, y, x, s, n);
// macro mvadd_wchstr(y, x, s)           => mvwadd_wchstr(stdscr, y, x, s);
// macro mvaddnwstr(y, x, wstr, n)       => mvwaddnwstr(stdscr, y, x, wstr, n);
// macro mvaddwstr(y, x, wstr)           => mvwaddwstr(stdscr, y, x, wstr);
// macro mvget_wch(y, x, c)              => mvwget_wch(stdscr, y, x, c);
// macro mvget_wstr(y, x, t)             => mvwget_wstr(stdscr, y, x, t);
// macro mvgetn_wstr(y, x, t, n)         => mvwgetn_wstr(stdscr, y, x, t, n);
// macro mvhline_set(y, x, c, n)         => mvwhline_set(stdscr, y, x, c, n);
// macro mvin_wch(y, x, c)               => mvwin_wch(stdscr, y, x, c);
// macro mvin_wchnstr(y, x, c, n)        => mvwin_wchnstr(stdscr, y, x, c, n);
// macro mvin_wchstr(y, x, c)            => mvwin_wchstr(stdscr, y, x, c);
// macro mvinnwstr(y, x, c, n)           => mvwinnwstr(stdscr, y, x, c, n);
// macro mvins_nwstr(y, x, t, n)         => mvwins_nwstr(stdscr, y, x, t, n);
// macro mvins_wch(y, x, c)              => mvwins_wch(stdscr, y, x, c);
// macro mvins_wstr(y, x, t)             => mvwins_wstr(stdscr, y, x, t);
// macro mvinwstr(y, x, c)               => mvwinwstr(stdscr, y, x, c);
// macro mvvline_set(y, x, c, n)         => mvwvline_set(stdscr, y, x, c, n);

// macro mvwadd_wch(win, y, x, c)        => (wmove(win, y, x) == ERR ? ERR : wadd_wch(win, c));
// macro mvwadd_wchnstr(win, y, x, s, n) => (wmove(win, y, x) == ERR ? ERR : wadd_wchnstr(win, s, n));
// macro mvwadd_wchstr(win, y, x, s)     => (wmove(win, y, x) == ERR ? ERR : wadd_wchstr(win, s));
// macro mvwaddnwstr(win, y, x, wstr, n) => (wmove(win, y, x) == ERR ? ERR : waddnwstr(win, wstr, n));
// macro mvwaddwstr(win, y, x, wstr)     => (wmove(win, y, x) == ERR ? ERR : waddwstr(win, wstr));
// macro mvwget_wch(win, y, x, c)        => (wmove(win, y, x) == ERR ? ERR : wget_wch(win, c));
// macro mvwget_wstr(win, y, x, t)       => (wmove(win, y, x) == ERR ? ERR : wget_wstr(win, t));
// macro mvwgetn_wstr(win, y, x, t, n)   => (wmove(win, y, x) == ERR ? ERR : wgetn_wstr(win, t, n));
// macro mvwhline_set(win, y, x, c, n)   => (wmove(win, y, x) == ERR ? ERR : whline_set(win, c, n));
// macro mvwin_wch(win, y, x, c)         => (wmove(win, y, x) == ERR ? ERR : win_wch(win, c));
// macro mvwin_wchnstr(win, y, x, c, n)  => (wmove(win, y, x) == ERR ? ERR : win_wchnstr(win, c, n));
// macro mvwin_wchstr(win, y, x, c)      => (wmove(win, y, x) == ERR ? ERR : win_wchstr(win, c));
// macro mvwinnwstr(win, y, x, c, n)     => (wmove(win, y, x) == ERR ? ERR : winnwstr(win, c, n));
// macro mvwins_nwstr(win, y, x, t, n)   => (wmove(win, y, x) == ERR ? ERR : wins_nwstr(win, t, n));
// macro mvwins_wch(win, y, x, c)        => (wmove(win, y, x) == ERR ? ERR : wins_wch(win, c));
// macro mvwins_wstr(win, y, x, t)       => (wmove(win, y, x) == ERR ? ERR : wins_wstr(win, t));
// macro mvwinwstr(win, y, x, c)         => (wmove(win, y, x) == ERR ? ERR : winwstr(win, c));
// macro mvwvline_set(win, y, x, c, n)   => (wmove(win, y, x) == ERR ? ERR : wvline_set(win, c, n));

extern fn ZString _nc_viswbuf(CInt *);
extern fn ZString _nc_viswibuf(CInt *);

/* $Id: curses.tail,v 1.27 2023/08/05 19:43:46 tom Exp $ */
/*
 * vile:cmode:
 * This file is part of ncurses, designed to be appended after curses.h.in
 * (see that file for the relevant copyright).
 */

/* mouse interface */

const MOUSE_VERSION = 2;

macro @check_mouse_version($v) @private
{
    return MOUSE_VERSION > $v;
}

// NOTE: this macros differ from C because of the C3 naming rules.

macro mouse_mask(b, m) @if(@check_mouse_version(1))
{
    return (m << (b - 1) * 5);
}

macro mouse_mask(b, m) @if(!@check_mouse_version(1))
{
    return (m << (b - 1) * 6);
}

const BUTTON_RELEASED = 001UL;
const BUTTON_PRESSED = 002UL;
const BUTTON_CLICKED = 004UL;
const DOUBLE_CLICKED = 010UL;
const TRIPLE_CLICKED = 020UL;
const RESERVED_EVENT = 040UL;

/* event masks */

// ---
// NOTE: this part is very different from C because of the strict rules of
// the C3 compiler. Using consts instead of macros will crash the compiler because
// the assignment cannot be evaluated at compile time.
macro button1_released()       => mouse_mask(1, BUTTON_RELEASED);
macro button1_pressed()        => mouse_mask(1, BUTTON_PRESSED);
macro button1_clicked()        => mouse_mask(1, BUTTON_CLICKED);
macro button1_double_clicked() => mouse_mask(1, DOUBLE_CLICKED);
macro button1_triple_clicked() => mouse_mask(1, TRIPLE_CLICKED);

macro button2_released()       => mouse_mask(2, BUTTON_RELEASED);
macro button2_pressed()        => mouse_mask(2, BUTTON_PRESSED);
macro button2_clicked()        => mouse_mask(2, BUTTON_CLICKED);
macro button2_double_clicked() => mouse_mask(2, DOUBLE_CLICKED);
macro button2_triple_clicked() => mouse_mask(2, TRIPLE_CLICKED);

macro button3_released()       => mouse_mask(3, BUTTON_RELEASED);
macro button3_pressed()        => mouse_mask(3, BUTTON_PRESSED);
macro button3_clicked()        => mouse_mask(3, BUTTON_CLICKED);
macro button3_double_clicked() => mouse_mask(3, DOUBLE_CLICKED);
macro button3_triple_clicked() => mouse_mask(3, TRIPLE_CLICKED);

macro button4_released()       => mouse_mask(4, BUTTON_RELEASED);
macro button4_pressed()        => mouse_mask(4, BUTTON_PRESSED);
macro button4_clicked()        => mouse_mask(4, BUTTON_CLICKED);
macro button4_double_clicked() => mouse_mask(4, DOUBLE_CLICKED);
macro button4_triple_clicked() => mouse_mask(4, TRIPLE_CLICKED);

/*
 * In 32 bits the version-1 scheme does not provide enough space for a 5th
 * button, unless we choose to change the ABI by omitting the reserved-events.
 */
macro button5_released() @if(@check_mouse_version(1))
{
    return mouse_mask(5, BUTTON_RELEASED);
}

macro button5_pressed() @if(@check_mouse_version(1))
{
    return mouse_mask(5, BUTTON_PRESSED);
}

macro button5_clicked() @if(@check_mouse_version(1))
{
    return mouse_mask(5, BUTTON_CLICKED);
}

macro button5_double_clicked() @if(@check_mouse_version(1))
{
    return mouse_mask(5, DOUBLE_CLICKED);
}

macro button5_triple_clicked() @if(@check_mouse_version(1))
{
    return mouse_mask(5, TRIPLE_CLICKED);
}

macro button_ctrl() @if(@check_mouse_version(1))
{
    return mouse_mask(6, 0001L);
}

macro button_shift() @if(@check_mouse_version(1))
{
    return mouse_mask(6, 0002L);
}

macro button_alt() @if(@check_mouse_version(1))
{
    return mouse_mask(6, 0004L);
}

macro report_mouse_position() @if(@check_mouse_version(1))
{
    return mouse_mask(6, 0010L);
}

macro button1_reserved_event() @if(!@check_mouse_version(1))
{
    return mouse_mask(1, RESERVED_EVENT);
}

macro button2_reserved_event() @if(!@check_mouse_version(1))
{
    return mouse_mask(2, RESERVED_EVENT);
}

macro button3_reserved_event() @if(!@check_mouse_version(1))
{
    return mouse_mask(3, RESERVED_EVENT);
}

macro button4_reserved_event() @if(!@check_mouse_version(1))
{
    return mouse_mask(4, RESERVED_EVENT);
}

macro button_ctrl() @if(!@check_mouse_version(1))
{
    return mouse_mask(5, 0001L);
}

macro button_shift() @if(!@check_mouse_version(1))
{
    return mouse_mask(5, 0002L);
}

macro button_alt() @if(!@check_mouse_version(1))
{
    return mouse_mask(5, 0004L);
}

macro report_mouse_position() @if(!@check_mouse_version(1))
{
    return mouse_mask(5, 0010L);
}

macro all_mouse_events() => (report_mouse_position() - 1);

/* macros to extract single event-bits from masks */
macro button_release(e, x)        => (e & mouse_mask(x, 001));
macro button_press(e, x)          => (e & mouse_mask(x, 002));
macro button_click(e, x)          => (e & mouse_mask(x, 004));
macro button_double_click(e, x)   => (e & mouse_mask(x, 010));
macro button_triple_click(e, x)   => (e & mouse_mask(x, 020));
macro button_reserved_event(e, x) => (e & mouse_mask(x, 040));
// ---

struct MEvent
{
    CShort id;      /* ID to distinguish multiple devices */
    CInt x, y, z;   /* event coordinates (character-cell) */
    Mmask_t bstate;	/* button state bits */
}

extern fn bool has_mouse();
extern fn CInt getmouse(MEvent *);
extern fn CInt ungetmouse(MEvent *);
extern fn Mmask_t mousemask(Mmask_t, Mmask_t *);
extern fn bool wenclose(Window *, CInt, CInt);
extern fn CInt mouseinterval(CInt);
extern fn bool wmouse_trafo(Window *, CInt *, CInt *, bool);
extern fn bool mouse_trafo(CInt *, CInt *, bool);

extern fn bool has_mouse_sp(Screen *);
extern fn CInt getmouse_sp(Screen *, MEvent *);
extern fn CInt ungetmouse_sp(Screen *, MEvent *);
extern fn Mmask_t mousemask_sp(Screen *, Mmask_t, Mmask_t *);
extern fn CInt mouseinterval_sp(Screen *, CInt);

// NOTE: this is conflicting with an external function declared above.
// macro mouse_trafo(y, x, to_screen) => wmouse_trafo(stdscr, y, x, to_screen);

/* other non-XSI functions */

extern fn CInt mcprint(ZString, CInt);              /* direct data to printer */
extern fn CInt has_key(CInt);                       /* do we have given key? */

extern fn CInt has_key_sp(Screen *, CInt);          /* do we have given key? */
extern fn CInt mcprint_sp(Screen *, ZString, CInt);	/* direct data to printer */

/* Debugging : use with libncurses_g.a */

extern fn void _tracef(ZString, ...);
extern fn ZString _traceattr(Attr_t);
extern fn ZString _traceattr2(CInt, Chtype);
extern fn ZString _tracechar(CInt);
extern fn ZString _tracechtype(Chtype);
extern fn ZString _tracechtype2(CInt, Chtype);

// NOTE: this is not possible with C3 macro system.
// #define _tracech_t _tracecchar_t
extern fn ZString _tracecchar_t(CChar_t *);

// NOTE: this is not possible with C3 macro system.
// #define _tracech_t2 _tracecchar_t2
extern fn ZString _tracecchar_t2(CInt, CChar_t *);

extern fn void trace(CUInt) @deprecated("use curses_trace");
extern fn CUInt curses_trace(CUInt);

/* trace masks */
const TRACE_DISABLE  = 0x0000; /* turn off tracing */
const TRACE_TIMES    = 0x0001; /* trace user and system times of updates */
const TRACE_TPUTS    = 0x0002; /* trace tputs calls */
const TRACE_UPDATE   = 0x0004; /* trace update actions, old & new screens */
const TRACE_MOVE     = 0x0008; /* trace cursor moves and scrolls */
const TRACE_CHARPUT  = 0x0010; /* trace all character outputs */
const TRACE_ORDINARY = 0x001F; /* trace all update actions */
const TRACE_CALLS    = 0x0020; /* trace all curses calls */
const TRACE_VIRTPUT  = 0x0040; /* trace virtual character puts */
const TRACE_IEVENT   = 0x0080; /* trace low-level input processing */
const TRACE_BITS     = 0x0100; /* trace state of TTY control bits */
const TRACE_ICALLS   = 0x0200; /* trace internal/nested calls */
const TRACE_CCALLS   = 0x0400; /* trace per-character calls */
const TRACE_DATABASE = 0x0800; /* trace read/write of terminfo/termcap data */
const TRACE_ATTRS    = 0x1000; /* trace attribute updates */

const TRACE_SHIFT    = 13; /* number of bits in the trace masks */
const TRACE_MAXIMUM  = ((1 << TRACE_SHIFT) - 1); /* maximum trace level */

extern CInt _nc_optimize_enable;        /* enable optimizations */
extern fn ZString _nc_visbuf(ZString);
const OPTIMIZE_MVCUR   = 0x01;          /* cursor movement optimization */
const OPTIMIZE_HASHMAP = 0x02;          /* diff hashing to detect scrolls */
const OPTIMIZE_SCROLL  = 0x04;          /* scroll optimization */
const OPTIMIZE_ALL     = 0xff;          /* enable all optimizations (dflt) */
