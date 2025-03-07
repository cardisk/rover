module rover::layout;
import std::collections::list;
import std::core::mem;
import libc;

// IMPORTANT: all memory allocations done here are inside the temporary
// allocator because there is no need to make this components persistent.

// TODO: if the window is resized the configuration needs to be reloaded.

enum SizeType
{
    GROW,
    FIT,
    FIXED,
}

struct Size
{
    SizeType type;
    CInt w, h;
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
    Size size;
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
    CInt x, y;
    Size size;
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
    union
    {
        Box    *box;
        Window *win;
    }
}

// helper functions

fn Component *new_component(ComponentType type)
{
    Component *new = mem::temp_new(Component);
    libc::memset(new, 0, Component.sizeof);

    new[0] = { .type = type };

    return new;
}

fn Box *new_hbox()
{
    Box *new = mem::temp_new(Box);
    libc::memset(new, 0, Box.sizeof);

    new[0] = {
        .type  = HBOX,
        .align = LEFT,
        .size  = {
            .type = GROW,
        },
    };
    new.children.tinit();

    return new;
}

fn Box *new_vbox()
{
    Box *new = mem::temp_new(Box);
    libc::memset(new, 0, Box.sizeof);
    
    new[0] = {
        .type  = VBOX,
        .align = TOP,
        .size  = {
            .type = GROW,
        },
    };
    new.children.tinit();

    return new;
}

fn Window *new_window(WindowType type)
{
    Window *new = mem::new(Window);
    libc::memset(new, 0, Window.sizeof);

    new[0] = {
        .type = type,
        .is_visible = true,
        .size  = {
            .type = GROW,
        },
    };

    return new;
}
