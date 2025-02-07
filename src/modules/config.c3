module rover::config;
import rover::defaults;
import std::io::path, std::io::file;
import std::encoding::json;
import std::collections::object;
import std::os::env;
import ncurses;

// container -> hbox, vbox
// entity -> hbox, vbox, win
fault ConfigError
{
    INVALID_CONTAINER_TYPE,
    INVALID_CONFIG_TYPE,
    INVALID_CONTAINER_CONTENT,
    INVALID_W_CONTENT,
    INVALID_H_CONTENT,
    INVALID_WINDOW_NAME,

    MISSING_CONFIG_TYPE,
    MISSING_CONTAINER_CONTENT,
    MISSING_WINDOW_NAME,
    MISSING_OR_INVALID_WINDOW_BOXED,
    MISSING_WINDOW_W,
    MISSING_WINDOW_H,
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
    Path bookmarks_path;
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
    
    String display_config_src = defaults::DEFAULT_DISPLAY;

    String! home_env = env::get_home_dir();
    if ENV: (try home_env)
    {
        String config_path = home_env.tconcat("/.config/rover/display.json");
        home_env.free();

        if (!file::is_file(config_path)) break ENV;

        char[]! file_src = file::load_temp(config_path);
        if (try file_src) display_config_src = (String) file_src;
    }

    Object *default_display_obj = json::temp_parse_string(display_config_src)!;

    // Here the result can be safely ignored.
    self.parse(default_display_obj, Coord {})!;

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

    allocator::temp().reset(tmark);
}

module rover::config @private;
import std::collections::object;
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

fn Coord! Config.parse(&self, Object *json, Coord coord)
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
                Coord rec = self.parse(entity, coord)!;
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
