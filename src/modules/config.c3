module rover::config;
import rover::defaults, rover::layout;
import std::io::path, std::io::file;
import std::collections::object;
import std::collections::list;
import std::encoding::json;
import std::os::env;
import ncurses;

const CShort DIRECTORY_COLOR    = 1;
const CShort EXECUTABLE_COLOR   = 2;
const CShort LINK_COLOR         = 3;
const CShort PWD_COLOR          = 4;
const CShort HOST_COLOR         = 5;
const CShort ERROR_COLOR        = 6;
const CShort ERROR_POPUP_BORDER = 7;

CShort color_index = 8;

fault ConfigError
{
    ERROR_HOME_DIR,

    INVALID_COLOR_HEX,
    INVALID_COLOR_FOREGROUND,
    INVALID_COLOR_BACKGROUND,

    MISSING_COLOR_PAIR,
    MISSING_COLOR_FOREGROUND,
    MISSING_COLOR_BACKGROUND,
}

struct Config
{
    String editor;
    String display_config_src;

    DynamicArenaAllocator display_tree_arena;
    Component *display_tree;

    List(<Component *>) windows;
}

fn void! Config.init(&self)
{
    usz tmark = allocator::temp().mark();
    
    self.editor = "";
    String! editor_env = env::get_var("EDITOR");
    if (try editor_env) self.editor = editor_env;

    String! home_env = env::get_home_dir();
    if (catch home_env) return ConfigError.ERROR_HOME_DIR?;

    self.load_display_string(home_env);

    self.windows.init(allocator::mem);

    self.display_tree_arena.init(1024, allocator::mem);

    self.display_tree = null;
    self.reload_windows()!;

    // FIXME: DEBUG ----
    ncurses::endwin();
    foreach (item : self.windows)
    {
        io::printn(*item);
        io::printn(*item.win);
    }
    ncurses::refresh();
    // -----------------

    String theme_config_src = defaults::DEFAULT_THEME;

    String theme_path = home_env.tconcat("/.config/rover/theme.json");

    if THEME_FILE: (file::is_file(theme_path))
    {
        char[]! file_src = file::load_temp(theme_path);
        if (try file_src)
        {
            String fsrc = (String) file_src;
            if (!fsrc.len) break THEME_FILE;
            theme_config_src = fsrc;
        }
    }

    Object *theme_obj = json::temp_parse_string(theme_config_src)!;

    // Here the result can be safely ignored.
    self.parse_theme(theme_obj)!;
    // TODO: maybe this can be also customizable.
    ncurses::init_pair(ERROR_POPUP_BORDER, ncurses::COLOR_RED, ncurses::COLOR_BLACK);

    home_env.free();
    allocator::temp().reset(tmark);
}

fn void Config.free(&self)
{
    self.editor.free();
    self.display_config_src.free();

    self.display_tree_arena.free();
    // No need to free self.display_tree because
    // its content is allocated inside self.display_tree_arena

    self.windows.free();
}

fn void! Config.reload_windows(&self)
{
    self.display_tree_arena.reset();

    mem::@scoped(&self.display_tree_arena)
    {
        self.display_tree = layout::parse_tree(self.display_config_src)!;
    };

    self.extract_subwins(self.display_tree);
}

module rover::config @private;
import std::collections::object;
import std::encoding::hex;
import std::core::array;
import rover::defaults;
import rover::layout;
import std::io;
import ncurses;

fn void Config.load_display_string(&self, String home_env)
{
    self.display_config_src = defaults::DEFAULT_DISPLAY;

    String config_path = home_env.tconcat("/.config/rover/display.json");

    if DISPLAY_FILE: (file::is_file(config_path))
    {
        char[]! file_src = file::load_temp(config_path);
        if (try file_src)
        {
            String fsrc = (String) file_src;
            if (!fsrc.len) break DISPLAY_FILE;
            self.display_config_src = fsrc;
        }
    }
}

fn void Config.extract_subwins(&self, Component *root)
{
    if (root.type == WINDOW)
    {
        self.windows.push(root);
        return;
    }

    foreach (child : root.box.children)
    {
        self.extract_subwins(child);
    }
}

fn CInt map(CInt x, CInt in_min, CInt in_max, CInt out_min, CInt out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

fn void! Config.parse_color(&self, String name, Object *color)
{
    CShort foreground;
    CShort background;

    String! fg = color.get_string("fg");
    if (catch fg) return ConfigError.MISSING_COLOR_FOREGROUND?;
    String! bg = color.get_string("bg");
    if (catch bg) return ConfigError.MISSING_COLOR_BACKGROUND?;

    switch (fg)
    {
        case "black":
            foreground = ncurses::COLOR_BLACK;
        case "red":
            foreground = ncurses::COLOR_RED;
        case "green":
            foreground = ncurses::COLOR_GREEN;
        case "yellow":
            foreground = ncurses::COLOR_YELLOW;
        case "blue":
            foreground = ncurses::COLOR_BLUE;
        case "magenta":
            foreground = ncurses::COLOR_MAGENTA;
        case "cyan":
            foreground = ncurses::COLOR_CYAN;
        case "white":
            foreground = ncurses::COLOR_WHITE;
        default:
            // Hex foreground.
            if (fg.starts_with("#"))
            {
                char[]! rgb = hex::decode_temp((char[]) fg[1..]);
                if (catch rgb) return ConfigError.INVALID_COLOR_HEX?;
                if (rgb.len < 3) return ConfigError.INVALID_COLOR_HEX?;
                CShort r = (CShort) map(rgb[0], 0, 255, 0, 1000);
                CShort g = (CShort) map(rgb[1], 0, 255, 0, 1000);
                CShort b = (CShort) map(rgb[2], 0, 255, 0, 1000);
                ncurses::init_color(color_index, r, g, b);
                foreground = color_index;
                color_index++;
                break;
            }
            return ConfigError.INVALID_COLOR_FOREGROUND?;
    }

    switch (bg)
    {
        case "black":
            background = ncurses::COLOR_BLACK;
        case "red":
            background = ncurses::COLOR_RED;
        case "green":
            background = ncurses::COLOR_GREEN;
        case "yellow":
            background = ncurses::COLOR_YELLOW;
        case "blue":
            background = ncurses::COLOR_BLUE;
        case "magenta":
            background = ncurses::COLOR_MAGENTA;
        case "cyan":
            background = ncurses::COLOR_CYAN;
        case "white":
            background = ncurses::COLOR_WHITE;
        default:
            // Hex background.
            if (bg.starts_with("#"))
            {
                char[]! rgb = hex::decode_temp((char[]) bg[1..]);
                if (catch rgb) return ConfigError.INVALID_COLOR_HEX?;
                if (rgb.len < 3) return ConfigError.INVALID_COLOR_HEX?;
                CShort r = (CShort) map(rgb[0], 0, 255, 0, 1000);
                CShort g = (CShort) map(rgb[1], 0, 255, 0, 1000);
                CShort b = (CShort) map(rgb[2], 0, 255, 0, 1000);
                ncurses::init_color(color_index, r, g, b);
                background = color_index;
                color_index++;
                break;
            }
            return ConfigError.INVALID_COLOR_BACKGROUND?;
    }

    CShort pair;
    switch (name)
    {
        case "directory": 
            pair = DIRECTORY_COLOR;
        case "executable":
            pair = EXECUTABLE_COLOR;
        case "link":
            pair = LINK_COLOR;
        case "pwd":
            pair = PWD_COLOR;
        case "host":
            pair = HOST_COLOR;
        case "error":
            pair = ERROR_COLOR;
    }

    ncurses::init_pair(pair, foreground, background);
}

fn void! Config.parse_theme(&self, Object *json)
{
    String[*] keycodes = { 
        "directory", 
        "executable",
        "link",
        "pwd",
        "host",
        "error",
    };

    foreach (k : keycodes)
    {
        Object*! color = json.get(k);
        if (catch color) return ConfigError.MISSING_COLOR_PAIR?;
        self.parse_color(k, color)!;
    }
}
