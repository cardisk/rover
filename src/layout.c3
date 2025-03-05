module rover::layout;
import std::collections::list;

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

struct Window
{
    CInt x, y;
    CInt w, h;
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
