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

fn bool Color.equals(self, Color other)
{
    return
        self.r == other.r &&
        self.g == other.g &&
        self.b == other.b;
}

fn void init()
{
    registered_colors.init(mem);
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

fn void register(Color c)
{
    ncurses::init_color((CShort) color_index, c.r, c.g, c.b);
    registered_colors[c] = (CShort) color_index;
    color_index++;
}

fn void register_pair(Color c1, Color c2)
{
}

module rover::colors @private;
import std::collections::map;

HashMap{Color, CShort} registered_colors;
HashMap{Color, int} registered_pairs;

// Ncurses has 0-7 registered, starting from the first free.
int color_index = 8;

fn CInt map(CInt x, CInt in_min, CInt in_max, CInt out_min, CInt out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
