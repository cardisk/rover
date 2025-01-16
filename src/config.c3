module rover::config;
import std::io::path;
import std::encoding::json;

struct Subwin
{
    CInt x ,y;
    CInt w, h;
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

fn void Config.init(&self)
{
}

fn void Config.read_subwin(&self, Object name) @private
{
}
