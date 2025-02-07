module rover::defaults;

const String DEFAULT_DISPLAY = 
`
{
    "type": "vbox",
    "content": [
        {
            "type": "win",
            "name": "title",
            "boxed": false,
            "w": "w",
            "h": "3"
        },
        {
            "type": "hbox",
            "content": [
                {
                    "type": "win",
                    "name": "list",
                    "boxed": false,
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
                {
                    "type": "win",
                    "name": "preview",
                    "boxed": false,
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
                {
                    "type": "win",
                    "name": "bookmarks",
                    "boxed": false,
                    "w": "(/ w 3)",
                    "h": "(- h 9)"
                },
            ],
        },
        {
            "type": "win",
            "name": "status",
            "boxed": false,
            "w": "w",
            "h": "3"
        },
        {
            "type": "win",
            "name": "prompt",
            "boxed": false,
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
