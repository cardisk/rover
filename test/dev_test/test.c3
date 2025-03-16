module test;
import ncurses;
import std::io;
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

const String STRING_LAYOUT_LAYOUT_GROW =
`
{
    "type": "LAYOUT",
    "width": "100",
    "box": {
        "type": "HBOX",
        "children": [
            {
                "type": "LAYOUT",
                "width": "GROW",
                "box": {
                    "type": "HBOX",
                }
            },
            {
                "type": "LAYOUT",
                "width": "GROW",
                "box": {
                    "type": "HBOX",
                }
            },
            {
                "type": "LAYOUT",
                "width": "GROW",
                "box": {
                    "type": "HBOX",
                }
            }
        ]
    }
}
`;

const String STRING_LAYOUT_MIXED_GROW =
`
{
    "type": "LAYOUT",
    "width": "100",
    "height": "100",
    "box": {
        "type": "HBOX",
        "children": [
            {
                "type": "LAYOUT",
                "width": "GROW",
                "height": "GROW",
                "box": {
                    "type": "HBOX",
                }
            },
            {
                "type": "WINDOW",
                "win": {
                    "type": "TITLE",
                }
            },
            {
                "type": "WINDOW",
                "win": {
                    "type": "TITLE",
                }
            }
        ]
    }
}
`;

const String STRING_REAL_LAYOUT =
`
{
    "type": "LAYOUT",
    "width": "W",
    "height": "H",
    "box": {
        "type": "VBOX",
        "children": [
            {
                "type": "WINDOW",
                "height": "3",
                "win": {
                    "type": "TITLE",
                }
            },
            {
                "type": "LAYOUT",
                "width": "GROW",
                "height": "60",
                "box": {
                    "type": "HBOX",
                    "children": [
                        {
                            "type": "WINDOW",
                            "width": "(/ w 2)",
                            "win": {
                                "type": "LIST",
                            }
                        },
                        {
                            "type": "WINDOW",
                            "win": {
                                "type": "PREVIEW",
                            }
                        },
                        {
                            "type": "WINDOW",
                            "win": {
                                "type": "BOOKMARKS",
                            }
                        }
                    ]
                }
            },
            {
                "type": "WINDOW",
                "height": "3",
                "win": {
                    "type": "STATUS",
                }
            },
            {
                "type": "WINDOW",
                "height": "3",
                "win": {
                    "type": "PROMPT",
                }
            }
        ]
    }
}
`;

fn void print_component(Component *component, int level = 0)
{
    for (int i = 0; i < level; i++)
    {
        io::print("-");
    }
    io::printn(*component);
    switch (component.type)
    {
        case LAYOUT:
            for (int i = 0; i < level; i++)
            {
                io::print("-");
            }
            io::printn(*component.box);
            io::printn("#########");
            foreach (child : component.box.children)
            {
                print_component(child, level + 1);
            }
        case WINDOW:
            for (int i = 0; i < level; i++)
            {
                io::print("-");
            }
            io::printn(*component.win);
            io::printn("#########");
        default:
            unreachable("ComponentType not handled");
    }
}

fn void main()
{
    ncurses::initscr();
    Component *component = layout::parse_tree(STRING_REAL_LAYOUT)!!;
    ncurses::endwin();
    print_component(component);
}
