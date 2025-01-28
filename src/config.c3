module rover::config;
import std::io::path;
import std::encoding::json;

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
}

module rover::config @private;
import std::collections::object;

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

        // TODO: take care of globals like w and h.
        if (!expr[i].is_digit() && expr[i] != 'h' && expr[i] != 'w') return EvalError.INVALID_OPERAND?;
        
        if ((long)(i + 1) < expr.len - 1 && expr[i + 1].is_digit()) continue; 

        int! x = expr[cur + 1: i - cur].to_int();
        if (catch x) return EvalError.INVALID_OPERAND?;

        switch (op)
        {
            case '+':
                res += x;
            case '-':
                res -= x;
            case '*':
                res *= x;
            case '/':
                res /= x;
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

            switch (name)
            {
                case "title":
                    self.title.x = 0;
                    self.title.y = 0;
                    self.title.w = w;
                    self.title.h = h;
                case "list":
                    self.list.x = 0;
                    self.list.y = 0;
                    self.list.w = w;
                    self.list.h = h;
                case "preview":
                    self.preview.x = 0;
                    self.preview.y = 0;
                    self.preview.w = w;
                    self.preview.h = h;
                case "bookmarks":
                    self.bookmarks.x = 0;
                    self.bookmarks.y = 0;
                    self.bookmarks.w = w;
                    self.bookmarks.h = h;
                case "status":
                    self.status.x = 0;
                    self.status.y = 0;
                    self.status.w = w;
                    self.status.h = h;
                case "logs":
                    self.logs.x = 0;
                    self.logs.y = 0;
                    self.logs.w = w;
                    self.logs.h = h;
                default:
                    return ConfigError.INVALID_NAME?;
            }
        case "hbox":
        case "vbox":
        default:
            unreachable("Something wrong happened during Config parse.");
    }
}
