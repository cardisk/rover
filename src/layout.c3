module rover::layout;
import std::collections::list;

// IMPORTANT: all memory allocations done here that are not on stack,
// are done inside the temporary allocator because there is no need to
// make this component persistent every time.

// TODO: if the window is resized the configuration needs to be reloaded.

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
    List(<Component>) children;
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

struct Size
{
    CInt w, h;
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
    union
    {
        Box box;
        Window win;
    }
}

// helper functions

fn Component new_component(ComponentType type)
{
    return {
        .type = type,
    };
}

fn Box new_hbox()
{
    Box hbox = {
        .type  = HBOX,
        .align = LEFT,
    };
    hbox.children.tinit();

    return hbox;
}

fn Box new_vbox()
{
    Box vbox = {
        .type  = VBOX,
        .align = TOP,
    };
    vbox.children.tinit();

    return vbox;
}
