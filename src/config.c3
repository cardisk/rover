module rover::config;
import rover::defaults;
import std::io::path;
import std::encoding::json;
import std::collections::object;

fault ConfigError
{
    INVALID_TYPE,
    MISSING_TYPE,
    INVALID_NAME,
    MISSING_NAME,
    MISSING_W,
    MISSING_H,
}

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
    // TODO: read configs from file if present.
    usz tmark = allocator::temp().mark();

    // Defaults cannot present issues with formatting.
    Object *default_display_obj = json::temp_parse_string(defaults::DEFAULT_DISPLAY)!!;
    // TODO: handle errors.
    self.parse(default_display_obj)!!;

    allocator::temp().reset(tmark);
}

module rover::config @private;
import std::collections::object;
import ncurses;

fault EvalError
{
    INVALID_START,
    INVALID_END,
    INVALID_EXPR,
    INVALID_OPERATION,
    INVALID_OPERAND,
}

// Helper to handle s-expressions.
fn CInt! eval(String expr)
{
    // TODO: this split will leak memory if alloc::temp will not be resetted.
    if (expr.tsplit(" ").len < 3) return EvalError.INVALID_EXPR?;
    if (expr[0] != '(') return EvalError.INVALID_START?;
    if (expr[expr.len - 1] != ')') return EvalError.INVALID_END?;

    int i = 1;
    while (expr[i] == ' ') i++;

    int cur = i;
    CInt res = 0;
    CInt operand;
    
    char op = expr[cur];
    cur++;

    if (op == '*' || op == '/') res = 1;

    for (i = cur; i < expr.len - 1; i++)
    {
        if (expr[i] == ' ') 
        {
            cur = i;
            continue;
        }

        if (i == expr.len - 1 && expr[i] != ')') return EvalError.INVALID_END?;
        if (i == expr.len - 1 && expr[i] == ')') break;

        CInt val;
        if (!expr[i].is_digit() && expr[i] != 'h' && expr[i] != 'w') return EvalError.INVALID_OPERAND?;
        
        // After h or w there must be a space.
        if (!expr[i].is_digit() && (long)(i + 1) < expr.len - 1 && expr[i + 1] != ' ') return EvalError.INVALID_OPERAND?; 

        switch (expr[i])
        {
            case 'w':
                val = ncurses::getmaxy(ncurses::stdscr);

            case 'h':
                val = ncurses::getmaxx(ncurses::stdscr);

            default:
                if ((long)(i + 1) < expr.len - 1 && expr[i + 1].is_digit()) continue; 
                int! x = expr[cur + 1: i - cur].to_int();
                if (catch x) return EvalError.INVALID_OPERAND?;
                val = x;
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
                return EvalError.INVALID_OPERATION?;
        }
    }

    return res;
}

fn void! Config.parse(&self, Object *json)
{
    String! type = json.get_string("type");
    if (catch type) return ConfigError.MISSING_TYPE?;

    if (type != "vbox" && type != "hbox" && type != "win") return ConfigError.INVALID_TYPE?;

    CInt x = 0;
    CInt y = 0;

    switch (type)
    {
        case "win":
            String! name = json.get_string("name");
            if (catch name) return ConfigError.MISSING_NAME?;

            String! w = json.get_string("w");
            if (catch w) return ConfigError.MISSING_W?;
            String! h = json.get_string("h");
            if (catch h) return ConfigError.MISSING_H?;

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
                case "logs":
                    s = &self.logs;
                default:
                    return ConfigError.INVALID_NAME?;
            }
            
            usz tmark = allocator::temp().mark();
            s.x = x;
            s.y = y;
            s.w = eval(w)!;
            s.h = eval(h)!;
            allocator::temp().reset(tmark);

        case "hbox":
        case "vbox":
        default:
            unreachable("Something wrong happened during Config parse.");
    }
}
