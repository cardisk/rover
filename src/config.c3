module rover::config;
import std::io::path;

enum SubwinType
{
    HEADER,
    CONTENT,
    FOOTER,
}

enum SubwinPos
{
    LEFT,
    CENTER,
    RIGHT,
}

struct Subwin
{
    SubwinType type;
    bool is_visible;
    // These are multipliers (e.g. w = 2/3 => w = 0.6).
    CInt w, h;
    SubwinPos pos;
}

struct Config
{
    Path bookmarks_path;
    Subwin title;
    Subwin list;
    Subwin preview;
    Subwin bookmarks;
    Subwin status;
    Subwin logs;
}

fn void Config.init()
{
}

fn void Config.read_subwin(String name) @private
{
}
