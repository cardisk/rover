module main;
import std::io, std::io::path;
import ncurses;

const KEY_DOWN  @if(env::DARWIN) = 258 ;
const KEY_UP    @if(env::DARWIN) = 259 ;
const KEY_LEFT  @if(env::DARWIN) = 260 ;
const KEY_RIGHT @if(env::DARWIN) = 261 ;

const KEY_DOWN  @if(!env::DARWIN) = ncurses::KEY_DOWN;
const KEY_UP    @if(!env::DARWIN) = ncurses::KEY_UP;
const KEY_LEFT  @if(!env::DARWIN) = ncurses::KEY_LEFT;
const KEY_RIGHT @if(!env::DARWIN) = ncurses::KEY_RIGHT;

const BLACK   = 0;
const RED     = 1;
const GREEN   = 2;
const YELLOW  = 3;
const BLUE    = 4;
const MAGENTA = 5;
const CYAN    = 6;
const WHITE   = 7;

const CInt NORMAL   = 1;
const CInt SELECTED = 2;
const CInt DIR      = 3;
const CInt EXE      = 4;

macro set_mode(m) => ncurses::attron(m);
macro unset_mode(m) => ncurses::attroff(m);
macro set_color_mode(m) => set_mode(ncurses::color_pair(m));

bool bold = false;
bool underline = false;
bool italic = false;

macro toggle(s)
{
    switch (s)
    {
        case ncurses::A_UNDERLINE:
            if (bold)
            {
                underline = false;
                unset_mode(ncurses::A_UNDERLINE);
            }
            else
            {
                underline = true;
                set_mode(ncurses::A_UNDERLINE);
            }
        case ncurses::A_BOLD:
            if (bold)
            {
                bold = false;
                unset_mode(ncurses::A_BOLD);
            }
            else
            {
                bold = true;
                set_mode(ncurses::A_BOLD);
            }
        case ncurses::A_ITALIC:
            if (bold)
            {
                italic = false;
                unset_mode(ncurses::A_ITALIC);
            }
            else
            {
                italic = true;
                set_mode(ncurses::A_ITALIC);
            }
        case ncurses::A_NORMAL:
        case ncurses::A_ATTRIBUTES:
        case ncurses::A_CHARTEXT:
        case ncurses::A_COLOR:
        case ncurses::A_STANDOUT:
        case ncurses::A_REVERSE:
        case ncurses::A_BLINK:
        case ncurses::A_DIM:
        case ncurses::A_ALTCHARSET:
        case ncurses::A_INVIS:
        case ncurses::A_PROTECT:
        case ncurses::A_HORIZONTAL:
        case ncurses::A_LEFT:
        case ncurses::A_LOW:
        case ncurses::A_RIGHT:
        case ncurses::A_TOP:
        case ncurses::A_VERTICAL:
        default:
            unreachable("Only text styles can be toggled.");
    }
}

CShort dbkgd;
CShort dfrgd;
CInt x, y;

fn void rover_init()
{
    ncurses::start_color();
    ncurses::keypad(ncurses::stdscr, true);
    ncurses::noecho();
    ncurses::raw();
    ncurses::curs_set(1);

    Chtype def_pair = ncurses::getbkgd(ncurses::stdscr);
    ncurses::pair_content((CShort)def_pair, &dfrgd, &dbkgd);

    ncurses::init_pair(NORMAL, dfrgd, dbkgd);
    ncurses::init_pair(SELECTED, BLACK, BLUE);
    ncurses::init_pair(DIR, BLUE, dbkgd);
    ncurses::init_pair(EXE, GREEN, dbkgd);
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
    
        ncurses::printw("%d %d\n", x, y);
    
        Path cwd = path::new_cwd()!;
        foreach (i, p : path::new_ls(cwd)!)
        {
            ncurses::printw("%s\n", p.path_string);
        }

        ncurses::move(y, x);

        switch (CInt key = ncurses::getch())
        {
            case KEY_UP:
                if (y > 0) y--;
            case KEY_DOWN:
                if (y < ncurses::getmaxy(ncurses::stdscr) - 1) y++;
            case 'Q':
            case 'q':
                looping = false;
            default:
                ncurses::printw("%d\n", key);
        }

        ncurses::refresh();
    }
}

