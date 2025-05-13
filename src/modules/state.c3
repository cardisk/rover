module rover::state;
import std::collections::list;
import std::io;
import ncurses;

faultdef
    NO_USER,
    NO_HOST;

struct State
{
    CInt w, h;
    CInt old_w, old_h;
    bool resized;
    ZString user;
    char[255] host;

    List{String} logs;
}

fn void? State.init(&self)
{
    // From c-bindings.
    self.user = rover::getlogin();
    if (!self.user) return NO_USER?;

    if (rover::gethostname((ZString) &self.host, 255) != 0) return NO_HOST?;

    ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);
    self.old_w = 0;
    self.old_h = 0;

    self.logs.init(mem);
}

macro State.update(&self)
{
    ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);

    self.resized = false;

    if (self.old_w != self.w) self.resized = true;
    if (self.old_h != self.h) self.resized = true;

    self.old_w = self.w;
    self.old_h = self.h;
}

macro State.resized(&self) => self.resized;

macro State.log(&self, String str) => self.logs.push(str);

// TODO: maybe this can be removed.
// Now there is the notion of error popup, so this 
// is not needed anymore. Someone may want to print
// them anyway at the end with some sort of flags.
fn void State.show_logs(&self)
{
    foreach (s : self.logs)
    {
        io::printn(s);
    }
}

fn void State.free(&self)
{
    // No need to free self.user & self.host 'cause they are
    // references to statically allocated memory.
    self.logs.free();
}
