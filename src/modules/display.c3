module rover::display;
import rover::state, rover::system, rover::stat;
import std::io::path, std::io::file;
import std::core::mem::allocator;
import ncurses;

const CInt DIR = 1;
const CInt EXE = 2;
const CInt LNK = 3;
const CInt PWD = 4;
const CInt HST = 5;

fault DisplayError
{
    INIT_FAIL,
    NO_COLORS,
    NO_COLBIND,
    NO_PREVIEW,
}

struct Display
{
    // Position selected inside the list.
    usz cur;
    // Boundaries of the window (inclusive).
    usz vtop;
    usz vbot;
    // Marker for the temporary allocator.
    usz tmark;
    // Subwindows.
    Window *list;
    Window *prev;
    Window *text;

    State *app;
    System *sys;
}

fn void! Display.init(&self, State *app, System *sys)
{
    assert(app && sys);
    self.app = app;
    self.sys = sys;

    self.cur = 0;
    self.vtop = 0;
    self.vbot = (usz)(app.h - 3);

    self.tmark = allocator::temp().mark();

    self.update_viewport();

    if (!ncurses::initscr()) return DisplayError.INIT_FAIL?;
    if (!ncurses::has_colors()) return DisplayError.NO_COLORS?;

    if (ncurses::start_color() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::keypad(ncurses::stdscr, true) == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::noecho() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::raw() == ncurses::ERR) return DisplayError.INIT_FAIL?;
    if (ncurses::curs_set(0) == ncurses::ERR) return DisplayError.INIT_FAIL?;

    // TODO: make the Display theme customizable.
    if (ncurses::init_pair(DIR, ncurses::COLOR_BLUE, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(EXE, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(LNK, ncurses::COLOR_CYAN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(PWD, ncurses::COLOR_YELLOW, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;
    if (ncurses::init_pair(HST, ncurses::COLOR_GREEN, ncurses::COLOR_BLACK)) return DisplayError.INIT_FAIL?;

    self.list = null;
    self.prev = null;
    self.text = null;
}

// TODO: Display does need a free method for subwindows.

// This is only called by Display.init() and Display.draw().
fn void Display.update_viewport(&self) @private
{
    // TODO: maybe the behaviour of the resize should be handled differently.
    if (self.app.resized()) {
        self.top();
        self.vtop = 0;
        self.vbot = (usz)(self.app.h - 3);
    }

    if (self.sys.ls.len() < (usz)(self.app.h - 3)) 
    {
        self.vtop = 0;
        self.vbot = self.sys.ls.len();
        return;
    }
    else 
    {
        self.vbot = self.vtop + (usz)(self.app.h - 3);
    }

    if (self.cur < self.vtop)
    {
        self.vtop -= 1;
        self.vbot -= 1;
    }

    if (self.cur >= self.vbot)
    {
        self.vtop += 1;
        self.vbot += 1;
    }
}

fn void Display.dir(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(DIR));
}

fn void Display.exe(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(EXE));
}

fn void Display.link(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(LNK));
}

fn void Display.pwd(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(PWD));
}

fn void Display.host(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(HST));
}

macro Display.select(&self, Window *win) => ncurses::wattron(win, ncurses::A_REVERSE);

fn void Display.reset(&self, Window *win)
{
    ncurses::wattroff(win, ncurses::A_BOLD);
    ncurses::wattroff(win, ncurses::A_REVERSE);
    ncurses::wattroff(win, ncurses::color_pair(DIR));
    ncurses::wattroff(win, ncurses::color_pair(EXE));
    ncurses::wattroff(win, ncurses::color_pair(LNK));
    ncurses::wattroff(win, ncurses::color_pair(PWD));
    ncurses::wattroff(win, ncurses::color_pair(HST));
}

macro Display.up(&self)   => (self.cur > 0) ? self.cur-- : 0;
macro Display.down(&self) => (self.cur < self.sys.ls.len() - 1) ? self.cur++ : 0;
macro Display.top(&self) => self.cur = 0;
macro Display.bottom(&self) => self.cur = self.sys.ls.len() - 1;

fn bool is_printable(String str) @private
{
    foreach (c : str)
    {
        if (!(rover::isascii(c) || c.is_space())) return false;
    }
    return true;
}

// This is an hack because ncurses will segfault when accessing ACS characters.
extern fn void winbox(Window *);

fn void Display.update_screen(&self) @private
{
    if (self.list) ncurses::delwin(self.list);
    if (self.prev) ncurses::delwin(self.prev);
    if (self.text) ncurses::delwin(self.text);

    self.list = ncurses::subwin(ncurses::stdscr, self.app.h - 3, self.app.w / 2, 0, 0);
    self.prev = ncurses::subwin(ncurses::stdscr, self.app.h, self.app.w / 2, 0, self.app.w / 2);
    self.text = ncurses::subwin(ncurses::stdscr, 3, self.app.w / 2, self.app.h - 3, 0);
}

fn void Display.clear(&self)
{
    assert(self.list && self.prev && self.text);

    ncurses::wclear(ncurses::stdscr);
    ncurses::wclear(self.list);
    ncurses::wclear(self.prev);
    ncurses::wclear(self.text);
}

fn void Display.draw_list(&self)
{
    CInt w, h;
    ncurses::@getmaxyx(self.list, h, w);

    // Cursor coordinates.
    CInt x = 2;
    CInt y = 2;
    
    // Window specifiers.
    self.host(self.list);
    ncurses::mvwprintw(self.list, 0, 2, "%s@%s ", self.app.user, self.app.host);
    self.pwd(self.list);
    ncurses::wprintw(self.list, "%s", self.sys.cwd.as_zstr());
    self.reset(self.list);

    if (self.sys.ls.is_empty())
    {
        self.select(self.list);
        // w - 3 because it takes in account the borders and the front space.
        ncurses::mvwprintw(self.list, y, x, "%- *s", w - 3, "<empty>");
        self.reset(self.list);
        return;
    }

    if (self.app.resized()) {
        self.top();
        self.vtop = 0;
        self.vbot = (usz)(h - 4);
    }

    if (self.sys.ls.len() < (usz)(h - 4)) 
    {
        self.vtop = 0;
        self.vbot = self.sys.ls.len();
        // Here there was a return statement so if something broke maybe it's the cause.
    }
    else 
    {
        self.vbot = self.vtop + (usz)(h - 4);
    }

    if (self.cur < self.vtop)
    {
        self.vtop -= 1;
        self.vbot -= 1;
    }
    else if (self.cur >= self.vbot)
    {
        self.vtop += 1;
        self.vbot += 1;
    }

    for (usz i = self.vtop; i < self.vbot; i++)
    {
        if (stat::is_link(self.sys.ls[i]))
        {
            self.link(self.list);
        }
        else if (stat::is_exe(self.sys.ls[i]))
        {
            self.exe(self.list);
        }
        else if (stat::is_dir(self.sys.ls[i])) 
        {
            self.dir(self.list);
        }

        if (i == self.cur) self.select(self.list);

        // Align text taking in account the first space and one in the middle
        ncurses::mvwprintw(self.list, y + (CInt)i, x, "%- *s", w - 3, 
                                                self.sys.ls[i].str_view());

        self.reset(self.list);
    }
}

fn void Display.draw_prev(&self)
{
}

fn void Display.draw_text(&self)
{
}

fn void Display.update(&self)
{
    allocator::temp().reset(self.tmark);

    self.update_screen();
    self.clear();

    winbox(self.list);
    winbox(self.prev);
    winbox(self.text);

    self.draw_list();
    self.draw_prev();
    self.draw_text();

    // No need to call refresh cause getch() inside the main will 
    // automatically call it. 
}

// fn void! Display.draw(&self)
// {
//     // Coordinates relative to the window.
//     CInt x = 1;
//     CInt y = 2;

//     CInt wl, hl, wp, hp;
//     ncurses::@getmaxyx(self.list, hl, wl);
//     ncurses::@getmaxyx(self.prev, hp, wp);

//     for (usz i = self.vtop; i < self.vbot; i++)
//     {
//         if (stat::is_link(self.sys.ls[i]))
//         {
//             self.link(self.list);
//         }
//         else if (stat::is_exe(self.sys.ls[i]))
//         {
//             self.exe(self.list);
//         }
//         else if (stat::is_dir(self.sys.ls[i])) 
//         {
//             self.dir(self.list);
//         }

//         if (i == self.cur) self.select(self.list);

//         // Align text taking in account the first space and one in the middle
//         ncurses::mvwprintw(self.list, y + (CInt)i, x, " %- *s", wl - 3, 
//                                                 self.sys.ls[i].str_view());

//         self.reset(self.list);
//     }


//     if (path::is_file(self.sys.ls[self.cur]))
//     {
//         switch (stat::is_exe(self.sys.ls[self.cur]))
//         {
//             case 1:
//                 ncurses::mvwprintw(self.prev, y, x, "<binary>");

//             case 0:
//                 char[]! chars = file::load_temp(self.sys.ls[self.cur].str_view());
//                 if (catch chars) break;

//                 String content = (String) chars;
//                 if (content.len == 0)
//                 {
//                     ncurses::mvwprintw(self.prev, y, x, "<empty>");
//                     break;
//                 }
//                 if (!is_printable(content))
//                 {
//                     ncurses::mvwprintw(self.prev, y, x, "<binary>");
//                     break;
//                 }
//                 String[] lines = content.tsplit("\n");

//                 usz stop = (usz)(hp - 3);
//                 if (lines.len < stop) stop = lines.len;
                
//                 for (int i = 0; i < stop; i++)
//                 {
//                     CInt len = lines[i].len;
//                     if (len > (wp - 2)) len = wp - 2;
//                     ncurses::mvwprintw(self.prev, y + i, x, "%.*s", len, lines[i]);
//                 }

//             case -1:
//                 return DisplayError.NO_PREVIEW?;
//         }
//     }

//     if (stat::is_dir(self.sys.ls[self.cur]))
//     {
//         PathList! ls = path::temp_ls(self.sys.ls[self.cur]);
//         if (catch ls)
//         {
//             ncurses::mvwprintw(self.prev, y, x, "<error while loading>");
//             return;
//         }

//         usz stop = (usz)(hp - 3);
//         if (ls.len() < stop) stop = ls.len();
        
//         if (ls.is_empty())
//         {
//             ncurses::mvwprintw(self.prev, y, x, "<empty>");
//         }
//         else
//         {
//             for (int i = 0; i < stop; i++)
//             {
//                 CInt len = ls[i].str_view().len;
//                 if (len > (wp - 2)) len = (CInt)(wp - 2);
//                 ncurses::mvwprintw(self.prev, y + i, x, "%.*s", len, ls[i].str_view());
//             }
//         }
//     }

//     ncurses::wrefresh(self.list);
//     ncurses::wrefresh(self.prev);
//     ncurses::wrefresh(self.text);
// }
