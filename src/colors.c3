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
    // Also the unwrap is safe because they are the first ones to be registered.
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
    if (try registered_colors[c]) return registered_colors[c]!!;

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

    if (try registered_pairs[pair]) return registered_pairs[pair]!!;

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
CShort directory;
CShort executable;
CShort link;
CShort pwd;
CShort host;
CShort error;
CShort error_popup_border;

// Placeholder for the default color.
// Its index should always result into -1.
const Color DEFAULT = { .r = -1, .g = -1, .b = -1};

// These colors are placeholders for ncurses ones.
// Getting the indexes of these should result into obtaining
// the indexes of the ncurses ones.
const Color BLACK   = { .r = 0, .g = 0, .b = 0};
const Color RED     = { .r = 1, .g = 1, .b = 1};
const Color GREEN   = { .r = 2, .g = 2, .b = 2};
const Color YELLOW  = { .r = 3, .g = 3, .b = 3};
const Color BLUE    = { .r = 4, .g = 4, .b = 4};
const Color MAGENTA = { .r = 5, .g = 5, .b = 5};
const Color CYAN    = { .r = 6, .g = 6, .b = 6};
const Color WHITE   = { .r = 7, .g = 7, .b = 7};

module rover::colors @private;
import std::collections::map;

HashMap{Color, CShort}     registered_colors;
HashMap{ColorPair, CShort} registered_pairs;

// Ncurses has 0-7 registered, starting from the first free.
// -1 is the default one, active only when use_default_colors has
// been called.
CShort color_index = -1;

// NOTE: Config module has to register the theme before
// anything else can be registered.
// IMPORTANT: pair index must start from index 1
CShort pair_index = 1;

fn CInt map(CInt x, CInt in_min, CInt in_max, CInt out_min, CInt out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
