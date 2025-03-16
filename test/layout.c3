module test::layout @test;
import rover::layout;

const String STRING_LAYOUT_FIT =
`
{
    "type": "LAYOUT",
    "box": {
        "type": "HBOX",
        "children": [
            {
                "type": "WINDOW",
                "width": "10",
                "height": "40",
                "win": {
                    "type": "TITLE",
                    "is_visible": true,
                    "is_boxed": true,
                }
            },
            {
                "type": "WINDOW",
                "width": "20",
                "height": "30",
                "win": {
                    "type": "TITLE",
                    "is_visible": true,
                    "is_boxed": true,
                }
            }
        ]
    }
}
`;

fn void memory_leak()
{
    @assert_leak()
    {
        Component *component = layout::parse_tree(STRING_LAYOUT_FIT)!!;
    };
}
