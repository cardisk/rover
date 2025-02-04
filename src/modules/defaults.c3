module rover::defaults;

const String DEFAULT_DISPLAY = 
`
{
    "type": "vbox",
    "content": [
        {
            "type": "win",
            "name": "title",
            "w": "w",
            "h": "3"
        },
        {
            "type": "hbox",
            "content": [
                {
                    "type": "win",
                    "name": "list",
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
                {
                    "type": "win",
                    "name": "preview",
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
                {
                    "type": "win",
                    "name": "bookmarks",
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
            ],
        },
        {
            "type": "win",
            "name": "status",
            "w": "w",
            "h": "3"
        },
        {
            "type": "win",
            "name": "logs",
            "w": "w",
            "h": "3"
        },
    ],
}
`;


const String DEFAULT_CONFIG =
`
{
    "bookmarks_path" = "~/.config/rover"
}
`;

// TODO: default_keybindings.
