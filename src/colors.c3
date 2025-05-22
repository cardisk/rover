module rover::colors;
import std::encoding::hex;
import ncurses;

faultdef
    INVALID_HEX_STRING,
    INVALID_ESCAPE_SEQUENCE;

struct Color
{
    CShort r, g, b;
}

fn uint Color.hash(self)
{
    return
        self.r.hash() +
        self.g.hash() +
        self.b.hash();
}

fn bool Color.equals(self, Color other) @operator(==)
{
    return
        self.r == other.r &&
        self.g == other.g &&
        self.b == other.b;
}

struct ColorPair
{
    Color fg;
    Color bg;
}

fn uint ColorPair.hash(self)
{
    return
        self.fg.hash() +
        self.bg.hash();
}

fn bool ColorPair.equals(self, ColorPair other) @operator(==)
{
    return
        self.fg == other.fg &&
        self.bg == other.bg;
}

fn void init()
{
    registered_colors.init(mem);
    registered_pairs.init(mem);

    // NOTE: do not change the order of these, they are placeholder
    // for ncurses ones.
    register(DEFAULT, false);
    register(BLACK  , false);
    register(RED    , false);
    register(GREEN  , false);
    register(YELLOW , false);
    register(BLUE   , false);
    register(MAGENTA, false);
    register(CYAN   , false);
    register(WHITE  , false);
    // ---
}

fn Color? from_escape_sequence(String seq)
{
    if (seq[0] != '\e') return INVALID_ESCAPE_SEQUENCE?;
    if (seq[1] != '[') return INVALID_ESCAPE_SEQUENCE?;

    // TODO: ^[[38;2;156;101;0m
    //       ^[[38;2;{r};{g};{b}m

    return {};
}

fn Color? from_hex(char[] hex)
{
    @pool()
    {
        char[]? rgb = hex::tdecode(hex);
        if (catch rgb) return INVALID_HEX_STRING?;

        return {
            .r = (CShort) map(rgb[0], 0, 255, 0, 1000),
            .g = (CShort) map(rgb[1], 0, 255, 0, 1000),
            .b = (CShort) map(rgb[2], 0, 255, 0, 1000),
        };
    };
}

fn CShort register(Color c, bool register_into_ncurses = true)
{
    if (try registered_colors[c]) return;

    if (register_into_ncurses)
    {
        ncurses::init_color(color_index, c.r, c.g, c.b);
    }

    registered_colors[c] = color_index;
    defer color_index++;

    return color_index;
}

fn CShort register_pair(Color c1, Color c2, bool register_into_ncurses = true)
{
    ColorPair pair = {
        .fg = c1,
        .bg = c2,
    };

    if (try registered_pairs[pair]) return;

    // NOTE: this is redundant because before calling this function
    // maybe is better to call register separately.
    register(pair.fg);
    register(pair.bg);

    if (register_into_ncurses)
    {
        CShort fg_index = registered_colors[pair.fg]!!;
        CShort bg_index = registered_colors[pair.bg]!!;

        ncurses::init_pair(pair_index, fg_index, bg_index);
    }

    registered_pairs[pair] = pair_index;
    defer pair_index++;

    return pair_index;
}

fn CShort? get(Color c)
{
    return registered_colors[c]!;
}

fn CShort? get_pair(ColorPair p)
{
    return registered_pairs[p]!;
}

// Rover color pairs
const CShort DIRECTORY          = 0;
const CShort EXECUTABLE         = 1;
const CShort LINK               = 2;
const CShort PWD                = 3;
const CShort HOST               = 4;
const CShort ERROR              = 5;
const CShort ERROR_POPUP_BORDER = 6;

// Placeholder for the default color.
// Its index should always result into -1.
const Color DEFAULT = {};

// These colors are placeholders for ncurses ones.
// Getting the indexes of these should result into obtaining
// the indexes of the ncurses ones.
const Color BLACK   = {};
const Color RED     = {};
const Color GREEN   = {};
const Color YELLOW  = {};
const Color BLUE    = {};
const Color MAGENTA = {};
const Color CYAN    = {};
const Color WHITE   = {};

module rover::colors @private;
import std::collections::map;

HashMap{Color, CShort}     registered_colors;
HashMap{ColorPair, CShort} registered_pairs;

// Ncurses has 0-7 registered, starting from the first free.
CShort color_index = -1;

// NOTE: Config module has to register the theme before
// anything else can be registered.
CShort pair_index = 0;

fn CInt map(CInt x, CInt in_min, CInt in_max, CInt out_min, CInt out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
