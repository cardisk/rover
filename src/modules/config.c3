module rover::config;
import rover::defaults, rover::layout;
import std::io::path, std::io::file;
import std::collections::object;
import std::collections::list;
import std::encoding::json;
import std::os::env;
import ncurses;

faultdef
    ERROR_HOME_DIR,
    INVALID_COLOR_FOREGROUND,
    INVALID_COLOR_BACKGROUND,
    MISSING_COLOR_PAIR,
    MISSING_COLOR_FOREGROUND,
    MISSING_COLOR_BACKGROUND;

struct Config
{
    String editor;
    String display_config_src;
    String theme_config_src;

    DynamicArenaAllocator display_tree_arena;
    Component *display_tree;

    List{Component *} windows;
}

fn void? Config.init(&self)
{
    @pool()
    {
        self.editor = "";
        String? editor_env = env::get_var(mem, "EDITOR");
        if (try editor_env) self.editor = editor_env;

        String? home_env = env::get_home_dir(tmem);
        if (catch home_env) return ERROR_HOME_DIR?;

        self.display_config_src = "";
        self.load_display_string(home_env);

        self.windows.init(mem);

        self.display_tree_arena.init(mem, 1024);

        self.display_tree = null;
        self.reload_windows()!;

        self.theme_config_src = "";
        self.load_theme_string(home_env);

        Object *theme_obj = json::tparse_string(self.theme_config_src)!;

        // Here the resulting error can be ignored.
        self.parse_theme(theme_obj)!;

        // TODO: maybe this can be also customizable.
        ncurses::init_pair(ERROR_POPUP_BORDER, ncurses::COLOR_RED, ncurses::COLOR_BLACK);
    };
}

fn void Config.free(&self)
{
    self.editor.free(mem);
    self.display_config_src.free(mem);
    self.theme_config_src.free(mem);

    self.display_tree_arena.free();
    // No need to free self.display_tree because
    // its content is allocated inside self.display_tree_arena

    self.windows.free();
}

fn void? Config.reload_windows(&self)
{
    self.display_tree_arena.reset();

    mem::@scoped(&self.display_tree_arena)
    {
        self.display_tree = layout::parse_tree(self.display_config_src)!;
    };

    self.extract_subwins(self.display_tree);
}

module rover::config @private;
import rover::colors;
import std::collections::object;
import std::encoding::hex;
import std::core::array;
import rover::defaults;
import rover::layout;
import std::io;
import ncurses;

fn void Config.load_display_string(&self, String home_env)
{
    String config_path = home_env.tconcat("/.config/rover/display.json");

    if (file::is_file(config_path))
    {
        char[]? file_src = file::load_temp(config_path);
        if (try file_src)
        {
            String fsrc = (String) file_src;
            self.display_config_src = fsrc.copy(mem);
        }
    }
    else
    {
        self.display_config_src = defaults::DEFAULT_DISPLAY.copy(mem);
    }
}

fn void Config.load_theme_string(&self, String home_env)
{
    String config_path = home_env.tconcat("/.config/rover/theme.json");

    if (file::is_file(config_path))
    {
        char[]? file_src = file::load_temp(config_path);
        if (try file_src)
        {
            String fsrc = (String) file_src;
            self.theme_config_src = fsrc.copy(mem);
        }
    }
    else
    {
        self.theme_config_src = defaults::DEFAULT_THEME.copy(mem);
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

fn void? Config.parse_color(&self, String name, Object *color)
{
    Color foreground;
    Color background;

    String? fg = color.get_string("fg");
    if (catch fg) foreground = colors::DEFAULT;
    String? bg = color.get_string("bg");
    if (catch bg) background = colors::DEFAULT;

    switch (fg)
    {
        case "black":
            foreground = colors::BLACK;
        case "red":
            foreground = colors::RED;
        case "green":
            foreground = colors::GREEN;
        case "yellow":
            foreground = colors::YELLOW;
        case "blue":
            foreground = colors::BLUE;
        case "magenta":
            foreground = colors::MAGENTA;
        case "cyan":
            foreground = colors::CYAN;
        case "white":
            foreground = colors::WHITE;
        default:
            // Hex foreground.
            if (!fg.starts_with("#")) return INVALID_COLOR_FOREGROUND?;
            foreground = colors::from_hex((char[]) fg[1..])!;
            // colors::register is redundant because register_pair does the same.
    }

    switch (bg)
    {
        case "black":
            background = colors::BLACK;
        case "red":
            background = colors::RED;
        case "green":
            background = colors::GREEN;
        case "yellow":
            background = colors::YELLOW;
        case "blue":
            background = colors::BLUE;
        case "magenta":
            background = colors::MAGENTA;
        case "cyan":
            background = colors::CYAN;
        case "white":
            background = colors::WHITE;
        default:
            // Hex background.
            if (!fg.starts_with("#")) return INVALID_COLOR_BACKGROUND?;
            background = colors::from_hex((char[]) fg[1..])!;
            // colors::register is redundant because register_pair does the same.
    }

    CShort pair = colors::register_pair(foreground, background);

    switch (name)
    {
        case "directory": 
            colors::directory = pair;
        case "executable":
            colors::executable = pair;
        case "link":
            colors::link = pair;
        case "pwd":
            colors::pwd = pair;
        case "host":
            colors::host = pair;
        case "error":
            colors::error = pair;
    }
}

fn void? Config.parse_theme(&self, Object *json)
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
        Object*? color = json.get(k);
        if (catch color) return MISSING_COLOR_PAIR?;
        self.parse_color(k, color)!;
    }
}
