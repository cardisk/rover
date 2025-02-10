module rover::config;
import rover::defaults;
import std::io::path, std::io::file;
import std::encoding::json;
import std::collections::object;
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

// container -> hbox, vbox
// entity -> hbox, vbox, win
fault ConfigError
{
    ERROR_HOME_DIR,

    INVALID_CONTAINER_TYPE,
    INVALID_CONFIG_TYPE,
    INVALID_CONTAINER_CONTENT,
    INVALID_W_CONTENT,
    INVALID_H_CONTENT,
    INVALID_WINDOW_NAME,

    INVALID_COLOR_HEX,
    INVALID_COLOR_FOREGROUND,
    INVALID_COLOR_BACKGROUND,

    MISSING_CONFIG_TYPE,
    MISSING_CONTAINER_CONTENT,
    MISSING_WINDOW_NAME,
    MISSING_OR_INVALID_WINDOW_BOXED,
    MISSING_WINDOW_W,
    MISSING_WINDOW_H,

    MISSING_COLOR_PAIR,
    MISSING_COLOR_FOREGROUND,
    MISSING_COLOR_BACKGROUND,
}

struct Subwin
{
    CInt x ,y;
    CInt w, h;
    bool is_visible;
    bool is_boxed;
}

struct Config
{
    String editor;

    Subwin title;
    Subwin list;
    Subwin preview;
    Subwin bookmarks;
    Subwin status;
    Subwin prompt;
}

fn void! Config.init(&self)
{
    usz tmark = allocator::temp().mark();
    
    self.editor = "";
    String! editor_env = env::get_var("EDITOR");
    if (try editor_env) self.editor = editor_env;

    String! home_env = env::get_home_dir();
    if (catch home_env) return ConfigError.ERROR_HOME_DIR?;

    String display_config_src = defaults::DEFAULT_DISPLAY;

    String config_path = home_env.tconcat("/.config/rover/display.json");

    if DISPLAY_FILE: (file::is_file(config_path))
    {
        char[]! file_src = file::load_temp(config_path);
        if (try file_src)
        {
            String fsrc = (String) file_src;
            if (!fsrc.len) break DISPLAY_FILE;
            display_config_src = fsrc;
        }
    }

    Object *display_obj = json::temp_parse_string(display_config_src)!;

    // Here the result can be safely ignored.
    self.parse_display(display_obj, Coord {})!;

    // FIXME: DEBUG ----
    ncurses::endwin();
    io::print("\ntitle: ");
    io::printn(self.title);
    io::print("list: ");
    io::printn(self.list);
    io::print("preview: ");
    io::printn(self.preview);
    io::print("bookmarks: ");
    io::printn(self.bookmarks);
    io::print("status: ");
    io::printn(self.status);
    io::print("prompt: ");
    io::printn(self.prompt);
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
            display_config_src = fsrc;
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

module rover::config @private;
import std::collections::object;
import std::encoding::hex;
import std::core::array;
import std::io;
import ncurses;

struct Coord
{
    CInt x, y;
    CInt maxx, maxy;
}

fault EvalError
{
    INVALID_EVAL_START,
    INVALID_EVAL_END,
    INVALID_EVAL_EXPR,
    INVALID_EVAL_OPERATION,
    INVALID_EVAL_OPERAND,
}

// Helper to handle s-expressions.
fn CInt! eval(String expr)
{
    if (expr.tsplit(" ").len < 3) return EvalError.INVALID_EVAL_EXPR?;
    if (expr[0] != '(') return EvalError.INVALID_EVAL_START?;
    if (expr[expr.len - 1] != ')') return EvalError.INVALID_EVAL_END?;

    int i = 1;
    while (expr[i] == ' ') i++;

    int cur = i;
    CInt res;
    CInt operand;
    
    char op = expr[cur];
    cur++;

    bool initted = false;

    for (i = cur; i < expr.len - 1; i++)
    {
        if (expr[i] == ' ') 
        {
            cur = i;
            continue;
        }

        if (i == expr.len - 1 && expr[i] != ')') return EvalError.INVALID_EVAL_END?;
        if (i == expr.len - 1 && expr[i] == ')') break;

        CInt val;
        if (!expr[i].is_digit() && expr[i] != 'h' && expr[i] != 'w') return EvalError.INVALID_EVAL_OPERAND?;
        
        // After h or w there must be a space.
        if (!expr[i].is_digit() && (long)(i + 1) < expr.len - 1 && expr[i + 1] != ' ') return EvalError.INVALID_EVAL_OPERAND?; 

        switch (expr[i])
        {
            case 'w':
                val = ncurses::getmaxx(ncurses::stdscr);

            case 'h':
                val = ncurses::getmaxy(ncurses::stdscr);

            default:
                if ((long)(i + 1) < expr.len - 1 && expr[i + 1].is_digit()) continue; 
                CInt! x = (CInt) expr[cur + 1: i - cur].to_int();
                if (catch x) return EvalError.INVALID_EVAL_OPERAND?;
                val = x;
        }

        if (!initted)
        {
            res = val;
            initted = true;
            continue;
        }

        switch (op)
        {
            case '+':
                res += val;
            case '-':
                res -= val;
            case '*':
                res *= val;
            case '/':
                res /= val;
            default:
                return EvalError.INVALID_EVAL_OPERATION?;
        }
    }

    return res;
}

fn Subwin*! Config.parse_win(&self, Object *obj, CInt x, CInt y)
{
    String! name = obj.get_string("name");
    if (catch name) return ConfigError.MISSING_WINDOW_NAME?;

    bool! boxed = obj.get_bool("boxed");
    if (catch boxed) return ConfigError.MISSING_OR_INVALID_WINDOW_BOXED?;

    String! w = obj.get_string("w");
    if (catch w) return ConfigError.MISSING_WINDOW_W?;
    String! h = obj.get_string("h");
    if (catch h) return ConfigError.MISSING_WINDOW_H?;

    Subwin *s;
    switch (name)
    {
        case "title":
            s = &self.title;
        case "list":
            s = &self.list;
        case "preview":
            s = &self.preview;
        case "bookmarks":
            s = &self.bookmarks;
        case "status":
            s = &self.status;
        case "prompt":
            s = &self.prompt;
        default:
            return ConfigError.INVALID_WINDOW_NAME?;
    }
    
    // If the window is specified inside the configuration then it's
    // automatically visible.
    s.is_visible = true;

    // s.is_boxed = boxed;
    s.is_boxed = true;

    s.x = x;
    s.y = y;

    if (w == "w")
    {
        // Just take the entire width.
        s.w = ncurses::getmaxx(ncurses::stdscr);
    }
    else if (w.starts_with("("))
    {
        // Parse the s-expression.
        s.w = eval(w)!;
    }
    else
    {
        // Maybe it's only a number.
        CInt! w_val = (CInt) w.to_int();
        if (catch w_val) return ConfigError.INVALID_W_CONTENT?;
        s.w = w_val;
    }

    if (h == "h")
    {
        // Just take the entire height.
        s.h = ncurses::getmaxy(ncurses::stdscr);
    }
    else if (h.starts_with("("))
    {
        // Parse the s-expression.
        s.h = eval(h)!;
    }
    else
    {
        // Maybe it's only a number.
        CInt! h_val = (CInt) h.to_int();
        if (catch h_val) return ConfigError.INVALID_H_CONTENT?;
        s.h = h_val;
    }

    return s;
}

fn Coord! Config.parse_display(&self, Object *json, Coord coord)
{
    String! type = json.get_string("type");
    if (catch type) return ConfigError.MISSING_CONFIG_TYPE?;

    // Only structural containers are allowed at the top-level.
    if (type != "vbox" && type != "hbox") return ConfigError.INVALID_CONTAINER_TYPE?;

    Object*! content = json.get("content");
    if (catch content) return ConfigError.MISSING_CONTAINER_CONTENT?;
    if (!content.is_array()) return ConfigError.INVALID_CONTAINER_CONTENT?;

    foreach (entity : content.array)
    {
        String! entity_type = entity.get_string("type");
        if (catch entity_type) return ConfigError.MISSING_CONFIG_TYPE?;

        switch (entity_type)
        {
            case "win":
                Subwin *s = self.parse_win(entity, coord.x, coord.y)!;
                if (coord.maxx < s.w) coord.maxx = s.w;
                if (coord.maxy < s.h) coord.maxy = s.h;
                switch (type)
                {
                    case "hbox":
                        coord.x += s.w;
                    case "vbox":
                        coord.y += s.h;
                    default:
                        unreachable("This should have been caught up in this method.");
                }

            case "hbox":
            case "vbox":
                Coord rec = self.parse_display(entity, coord)!;
                switch (type)
                {
                    case "hbox":
                        coord.x += rec.maxx;
                    case "vbox":
                        coord.y += rec.maxy;
                    default:
                        unreachable("This should have been caught up in this method.");
                }

            default:
                return ConfigError.INVALID_CONFIG_TYPE?;
        }
    }

    return coord;
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
