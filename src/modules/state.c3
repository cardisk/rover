module rover::state;
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

// TODO: State.free() may be removed.
// On OSX and Linux everything is allocated statically so this method is useless.
// WIN32 is not supported yet, but if it will, there will be 
// the memory management of the struct members here.
fn void State.free(&self)
{
}
