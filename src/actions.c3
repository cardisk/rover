module rover::actions;

// -- ERRORS
// clear_errors
// open_errors

// -- BROWSING
// browse
// open_file
// delete_selection
// change_focus

// -- CREATION
// new_file
// new_directory

// -- MATCHING
// filter
// clear_filter
// search

// -- CHANGES
// rename_path
// mark_path
// unmark_path
// move_to_target

// -- POPUPS
// open_history
// open_bookmarks

// -- BOOKMARKS
// save_bookmark
// delete_bookmark

// Category flags to determine whether they are active or not.
bool is_errors_active = true;
bool is_browsing_active = true;
bool is_creation_active = true;
bool is_matching_active = true;
bool is_changes_active = true;
bool is_popups_active = true;
bool is_bookmarks_active = true;

// -- ERRORS

fn void clear_errors()
{
}

fn void open_errors()
{
}

// -- BROWSING

fn void browse()
{
}

fn void open_file()
{
}

fn void delete_selection()
{
}

fn void change_focus()
{
}

// -- CREATION

fn void new_file()
{
}

fn void new_directory()
{
}

// MATCHING

fn void filter()
{
}

fn void clear_filter()
{
}

fn void search()
{
}

// -- CHANGES

fn void rename_path()
{
}

fn void mark_path()
{
}

fn void unmark_path()
{
}

fn void move_to_target()
{
}

// -- POPUPS

fn void open_history()
{
}

fn void open_bookmarks()
{
}

// -- BOOKMARKS

fn void save_bookmark()
{
}

fn void delete_bookmark()
{
}

