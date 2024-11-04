module ncurses;
import std::io;

def Chtype = CUInt;
def Mmask_t = CUInt;

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
// FIXME: '...' was of type 'va_list', this can be a problem in the future
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

// continue from line 1159.
