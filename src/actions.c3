module rover::actions;

bool allow_generic             = true;
bool allow_bookmarks           = true;
bool allow_marking             = true;
bool allow_cursor_navigation   = true;
bool allow_relative_navigation = true;
bool allow_focus_changes       = true;
bool allow_focus_changes       = true;
bool allow_errors              = true;
bool allow_filtering           = true;
bool allow_cursor_movements    = true;

// Generic
fn void new_file()
{
}

fn void rename_selected_item()
{
}

fn void delete_selected_item()
{
}

// Bookmarks
fn void add_entry_as_bookmark()
{
}

fn void remove_entry_as_bookmark()
{
}

// Marking
fn void mark_selected_item()
{
}

fn void unmark_selected_item()
{
}

fn void target_item()
{
}

// Cursor Navigation
fn void open_selected_dir()
{
}

fn void open_selected_file()
{
}

// Relative Navigation
fn void goto_parent_dir()
{
}

fn void goto_home_dir()
{
}

fn void goto_previous_dir()
{
}

fn void goto_input_dir()
{
}

// Focus changes
fn void change_focus()
{
}

fn void show_history()
{
}

fn void show_bookmarks()
{
}

fn void show_errors()
{
}

// Errors
fn void clear_errors()
{
}

// Filtering
fn void filter_case_insensitive()
{
}

fn void filter_case_sensitive()
{
}

fn void clear_filter()
{
}

// Cursor Movements
fn void cursor_up()
{
}

fn void cursor_down()
{
}

fn void cursor_top()
{
}

fn void cursor_down()
{
}
