module rover::state;
import std::collections::list;
import std::io;
import ncurses;

fault StateError
{
    NO_USER,
    NO_HOST,
}

struct State
{
    CInt w, h;
    CInt old_w, old_h;
    ZString user;
    char[255] host;

    List(<String>) logs;
}

fn void! State.init(&self)
{
    // From c-bindings.
    self.user = rover::getlogin();
    if (!self.user) return StateError.NO_USER?;

    if (rover::gethostname((ZString) &self.host, 255) != 0) return StateError.NO_HOST?;

    ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);
    self.old_w = self.w;
    self.old_h = self.h;

    self.logs.new_init();
}

macro State.update(&self)
{
    self.old_w = self.w;
    self.old_h = self.h;
    ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);
}

macro State.shrinkedw(&self) => self.w < self.old_w;
macro State.shrinkedh(&self) => self.h < self.old_h;
macro State.shrinked(&self) => self.shrinkedw() && self.shrinkedh();
macro State.scaledw(&self) => self.w > self.old_w;
macro State.scaledh(&self) => self.h > self.old_h;
macro State.scaled(&self) => self.scaledw() && self.scaledh();
macro State.resized(&self) => self.shrinked() || self.scaled();

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
    self.logs.free();
}
