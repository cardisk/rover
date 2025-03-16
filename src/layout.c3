module rover::layout;
import std::collections::list;
import std::core::mem;
import libc;

// IMPORTANT: all memory allocations done here are inside the temporary
// allocator because there is no need to make this components persistent.

// TODO: if the window is resized the configuration needs to be reloaded.

enum AxisSizingType
{
    GROW,
    FIT,
    FIXED,
}

struct Axis
{
    AxisSizingType type;
    CInt value;
}

enum BoxType
{
    HBOX,
    VBOX,
}

enum BoxAlign
{
    // -- hbox specific
    LEFT,
    RIGHT,

    // -- vbox specific
    TOP,
    BOTTOM,

    // -- common
    CENTER,
    STRETCH,
}

struct Box
{
    BoxType type;
    BoxAlign align;
    List(<Component *>) children;
}

enum WindowType
{
    TITLE,
    LIST,
    PREVIEW,
    BOOKMARKS,
    STATUS,
    PROMPT,
}

struct Window
{
    WindowType type;
    bool is_visible;
    bool is_boxed;
}

enum ComponentType
{
    WINDOW,
    LAYOUT,
}

struct Component
{
    ComponentType type;
    Component *parent;
    
    struct
    {
        Axis width;
        Axis height;
    }

    struct
    {
        CInt x, y;
        CInt offset;
    }
    
    union
    {
        Box    *box;
        Window *win;
    }
}

// helper functions

macro Axis axis_fit()             => { .type = FIT  , .value = 0     };
macro Axis axis_grow()            => { .type = GROW , .value = 0     };
macro Axis axis_fixed(CInt value) => { .type = FIXED, .value = value };

fn Component *new_component(ComponentType type)
{
    Component *new = mem::temp_new(Component);
    libc::memset(new, 0, Component.sizeof);

    *new = { 
        .type   = type,
        .width  = axis_fit(),
        .height = axis_fit(),
    };

    return new;
}

fn Component *new_hbox()
{
    Component *new = new_component(LAYOUT);

    Box *hbox = mem::temp_new(Box);
    libc::memset(hbox, 0, Box.sizeof);

    *hbox = {
        .type  = HBOX,
        .align = LEFT,
    };
    hbox.children.tinit();

    new.box = hbox;
    return new;
}

fn Component *new_vbox()
{
    Component *new = new_component(LAYOUT);

    Box *vbox = mem::temp_new(Box);
    libc::memset(vbox, 0, Box.sizeof);
    
    *vbox = {
        .type  = VBOX,
        .align = TOP,
    };
    vbox.children.tinit();

    new.box = vbox;
    return new;
}

fn Component *new_window(WindowType type)
{
    Component *new = new_component(WINDOW);
    new.width  = axis_grow();
    new.height = axis_grow();

    Window *win = mem::new(Window);
    libc::memset(win, 0, Window.sizeof);

    *win = {
        .type = type,
        .is_visible = true,
    };

    new.win = win;
    return new;
}
