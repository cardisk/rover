module rover::colors;

faultdef
    INVALID_ESCAPE_SEQUENCE;


struct Color
{
    char r, g, b;
}

fn Color? escape_sequence_to_ncurses(String seq)
{
    if (seq[0] != '\e') return INVALID_ESCAPE_SEQUENCE?;
    if (seq[1] != '[') return INVALID_ESCAPE_SEQUENCE?;

    // TODO: ^[[38;2;156;101;0m
    //       ^[[38;2;{r};{g};{b}m

    return {};
}

module rover::colors @private;

macro CInt map(CInt x, CInt in_min, CInt in_max, CInt out_min, CInt out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
