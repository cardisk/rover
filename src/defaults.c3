module rover::defaults;

const String default_display = 
`
{
    "title" = {
        "is_visible" = true,
    },
    "list" = {
        "is_visible" = true,
    },
    "preview" = {
        "is_visible" = true,
    },
    "bookmarks" = {
        "is_visible" = true,
    },
    "status" = {
        "is_visible" = true,
    },
    "logs" = {
        "is_visible" = true,
    },
}
`;

const String default_config =
`
{
    "bookmarks_path" = "~/.config/rover"
}
`;

// TODO: default_keybindings.
