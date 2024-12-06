module rover::display;
import rover::state, rover::system, rover::stat;
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
}

struct Display
{
    // Where the cursor needs to be placed.
    usz cur;
    // Boundaries of the window (inclusive).
    usz vtop;
    usz vbot;

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
    // TODO: this if-else code will break the viewport.
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
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::color_pair(DIR));
}

fn void Display.exe(&self)
{
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::color_pair(EXE));
}

fn void Display.link(&self)
{
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::color_pair(LNK));
}

fn void Display.pwd(&self)
{
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::color_pair(PWD));
}

fn void Display.host(&self)
{
    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::color_pair(HST));
}

macro Display.select(&self) => ncurses::attron(ncurses::A_REVERSE);

fn void Display.reset(&self)
{
    // TODO: making a bold assumption that if this is set twice it will not crash.
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

fn void Display.draw(&self)
{
    ncurses::clear();

    // self.host();
    // ncurses::printw("%s@%s ", self.app.user, self.app.host);
    // self.pwd();
    // ncurses::printw("%s\n\n", self.sys.cwd.str_view());
    // self.reset();

    self.update_viewport();

    // TODO: this line is here to eventaully check over viewport errors.
    ncurses::printw("w: %d h: %d c: %d t: %d b: %d l: %d\n\n", self.app.w, self.app.h, self.cur, self.vtop, self.vbot, self.sys.ls.len());

    for (usz i = self.vtop; i < self.vbot; i++)
    {
        // TODO: this line is here to eventaully check over viewport errors.
        // if (i >= self.sys.ls.len()) break;

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
}
