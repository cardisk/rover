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
}

// TODO: convert State.update() into a function if needed.
macro State.update(&self) => ncurses::@getmaxyx(ncurses::stdscr, self.h, self.w);

// TODO: State.free() may be removed.
// On OSX and Linux everything is allocated statically so this method is useless.
// WIN32 is not supported yet, but if it will, there will be 
// the memory management of the struct members here.
fn void State.free(&self)
{
}
