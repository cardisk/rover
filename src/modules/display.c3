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
    // Where the cursor needs to be placed.
    usz cur;
    // Boundaries of the window (inclusive).
    usz vtop;
    usz vbot;
    // Marker for the temporary allocator.
    usz tmark;

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
}

// Display doesn't need a free method.

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

fn void Display.dir(&self)
{
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(DIR));
}

fn void Display.exe(&self)
{
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(EXE));
}

fn void Display.link(&self)
{
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(LNK));
}

fn void Display.pwd(&self)
{
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(PWD));
}

fn void Display.host(&self)
{
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(HST));
}

macro Display.select(&self) => ncurses::attron(ncurses::A_REVERSE);

fn void Display.reset(&self)
{
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::A_REVERSE);
    ncurses::attroff(ncurses::color_pair(DIR));
    ncurses::attroff(ncurses::color_pair(EXE));
    ncurses::attroff(ncurses::color_pair(LNK));
    ncurses::attroff(ncurses::color_pair(PWD));
    ncurses::attroff(ncurses::color_pair(HST));
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

fn void! Display.draw(&self)
{
    allocator::temp().reset(self.tmark);
    ncurses::clear();

    self.host();
    ncurses::printw("%s@%s ", self.app.user, self.app.host);
    self.pwd();
    ncurses::printw("%s\n\n", self.sys.cwd.str_view());
    self.reset();

    self.update_viewport();

    if (self.sys.ls.is_empty())
    {
        self.select();
        ncurses::printw(" %- *s\n", (self.app.w / 2) - 2, 
                                    "<empty>");
        self.reset();
        ncurses::refresh();
        return;
    }

    for (usz i = self.vtop; i < self.vbot; i++)
    {
        if (stat::is_link(self.sys.ls[i]))
        {
            self.link();
        }
        else if (stat::is_exe(self.sys.ls[i]))
        {
            self.exe();
        }
        else if (stat::is_dir(self.sys.ls[i])) 
        {
            self.dir();
        }

        if (i == self.cur) self.select();

        // align text taking in account the first space and one in the middle
        ncurses::printw(" %- *s\n", (self.app.w / 2) - 2, 
                                    self.sys.ls[i].str_view());

        self.reset();
    }

    CInt x = (self.app.w / 2) + 1;
    CInt y = 2;

    if (path::is_file(self.sys.ls[self.cur]))
    {
        switch (stat::is_exe(self.sys.ls[self.cur]))
        {
            case 1:
                ncurses::mvprintw(y, x, "<binary>");

            case 0:
                char[]! chars = file::load_temp(self.sys.ls[self.cur].str_view());
                if (catch chars) break;

                String content = (String) chars;
                if (content.len == 0)
                {
                    ncurses::mvprintw(y, x, "<empty>");
                    break;
                }
                if (!is_printable(content))
                {
                    ncurses::mvprintw(y, x, "<binary>");
                    break;
                }
                String[] lines = content.tsplit("\n");

                usz stop = (usz)(self.app.h - 3);
                if (lines.len < stop) stop = lines.len;
                
                for (int i = 0; i < stop; i++)
                {
                    CInt len = lines[i].len;
                    if (len > (self.app.w / 2 - 2)) len = (CInt)(self.app.w / 2 - 2);
                    ncurses::mvprintw(y + i, x, "%.*s", len, lines[i]);
                }

            case -1:
                return DisplayError.NO_PREVIEW?;
        }
    }

    if (stat::is_dir(self.sys.ls[self.cur]))
    {
        PathList! ls = path::temp_ls(self.sys.ls[self.cur]);
        if (catch ls) return DisplayError.NO_PREVIEW?;

        usz stop = (usz)(self.app.h - 3);
        if (ls.len() < stop) stop = ls.len();
        
        if (ls.is_empty())
        {
            ncurses::mvprintw(y, x, "<empty>");
        }
        else
        {
            for (int i = 0; i < stop; i++)
            {
                CInt len = ls[i].str_view().len;
                if (len > (self.app.w / 2 - 2)) len = (CInt)(self.app.w / 2 - 2);
                ncurses::mvprintw(y + i, x, "%.*s", len, ls[i].str_view());
            }
        }
    }

    ncurses::refresh();
}
