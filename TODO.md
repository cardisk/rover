# Big features

- [ ] Custom keybindings.
- [X] Mark file to peform actions.
- [X] Polish modules moving stuff like the config one.
- [X] Refactor the error popup to be able to contain also other stuff.
- [ ] Group actions in categories, so it's easier to allow or not some of them.
- [ ] Session tabs that store indipendent application state (cwd, bookmarks ...).
- [ ] Vim-like find file with cursor movement

Command-line args:
- [ ] '--temp' to make the session temporary (no changes made to bookmarks and other stuff).
- [ ] '--emit-defaults' to emit the default configuration somewhere.
- [ ] '--version' to emit the actual version.
- [ ] '--help'

# Small features

All of this needs to work also on groups (marked files):
- [X] Create file.
- [X] Delete file with confirmation.
- [X] Move file.
- [X] Rename file.

- [X] Display the list of previously visited directories.

- [X] Go-to prompt to access another directory.

Filtering:
- [X] Display somewhere the active filter.
- [ ] Filtering can be case sensitive or not based on the action required.
- [ ] Grep inside files (feature flagged)

# Things to be fixed

- [ ] Every time a String is reassigned, it needs to be freed or copied.
- [X] Window configuration needs to be rethinked because now it's very messy.
- [X] Global modules need to be marked like @builtin so no prefixing is needed.
- [X] Filtering should be case-insensitive.

# Things to think of

- [ ] Drop the bookmarks window in favor of a popup version.
- [ ] libSSH integration to work with a remote host.
