module rover::defaults;

const String DEFAULT_DISPLAY = 
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
                "height": "(- H 9)",
                "box": {
                    "type": "HBOX",
                    "children": [
                        {
                            "type": "WINDOW",
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

const String DEFAULT_THEME =
`
{
    "directory": {
        "bg": "black",
        "fg": "blue",
    },
    "executable": {
        "bg": "black",
        "fg": "green",
    },
    "link": {
        "bg": "black",
        "fg": "cyan",
    },
    "pwd": {
        "bg": "black",
        "fg": "yellow",
    },
    "host": {
        "bg": "black",
        "fg": "green",
    },
    "error": {
        "bg": "red",
        "fg": "white",
    },
}
`;

// TODO: default_keybindings.
