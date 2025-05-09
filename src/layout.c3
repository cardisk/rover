module rover::layout;
import std::collections::object;
import std::collections::list;
import std::encoding::json;

// IMPORTANT: memory allocations done inside this module are inside
// the allocator::thread_allocator.

enum AxisSizingType
{
    GROW,
    FIT,
    FIXED,
}

struct Axis
{
    AxisSizingType type;
    CInt value;
}

enum BoxType
{
    HBOX,
    VBOX,
}

struct Box
{
    BoxType type;
    List{Component *} children;
}

enum WindowType
{
    TITLE,
    LIST,
    PREVIEW,
    BOOKMARKS,
    STATUS,
    PROMPT,
}

struct Window
{
    WindowType type;
    bool is_visible;
    bool is_boxed;
}

enum ComponentType
{
    WINDOW,
    LAYOUT,
}

struct Component
{
    ComponentType type;
    Component *parent;
    
    struct
    {
        Axis width;
        Axis height;
    }

    struct
    {
        CInt x, y;
        CInt offset;
    }
    
    union
    {
        Box    *box;
        Window *win;
    }
}

fn Component*? parse_tree(String str)
{
    Object *json = json::parse_string(str)!;
    defer json.free();

    // To make the component fill the entire screen, its size must
    // be specified inside the json.
    Component *root = fromJson(json)!;

    // Multiple passes to calculate the necessary information.
    // Thanks to https://github.com/nicbarker/clay for inspiration
    // and explanation.
    component_dfs_calculate_width(root);
    component_bfs_grow_width(root);

    component_dfs_calculate_height(root);
    component_bfs_grow_height(root);

    component_bfs_calculate_positions(root);

    return root;
}

module rover::layout @private;
import std::collections::object;
import std::collections::list;
import ncurses;
import libc;

// //// HELPER FUNCTIONS START      ///////////////////////////////////////////
macro Axis axis_fit()             => { .type = FIT  , .value = 0     };
macro Axis axis_grow()            => { .type = GROW , .value = 0     };
macro Axis axis_fixed(CInt value) => { .type = FIXED, .value = value };

fn Component *new_component(ComponentType type)
{
    Component *new = mem::new(Component);
    libc::memset(new, 0, Component.sizeof);

    *new = { 
        .type   = type,
        .width  = axis_fit(),
        .height = axis_fit(),
    };

    return new;
}

fn Component *new_hbox()
{
    Component *new = new_component(LAYOUT);

    Box *hbox = mem::new(Box);
    libc::memset(hbox, 0, Box.sizeof);

    *hbox = {
        .type  = HBOX,
    };
    hbox.children.init(allocator::mem);

    new.box = hbox;
    return new;
}

fn Component *new_vbox()
{
    Component *new = new_component(LAYOUT);

    Box *vbox = mem::new(Box);
    libc::memset(vbox, 0, Box.sizeof);
    
    *vbox = {
        .type  = VBOX,
    };
    vbox.children.init(allocator::mem);

    new.box = vbox;
    return new;
}

fn Component *new_window(WindowType type)
{
    Component *new = new_component(WINDOW);
    new.width  = axis_grow();
    new.height = axis_grow();

    Window *win = mem::new(Window);
    libc::memset(win, 0, Window.sizeof);

    *win = {
        .type = type,
        .is_visible = true,
    };

    new.win = win;
    return new;
}

faultdef
    INVALID_EVAL_START,
    INVALID_EVAL_END,
    INVALID_EVAL_EXPR,
    INVALID_EVAL_OPERATION,
    INVALID_EVAL_OPERAND;


fn CInt? evaluate_s_expression(String expr)
{
    if (expr.tsplit(" ").len < 3) return EvalError.INVALID_EVAL_EXPR?;
    if (expr[0] != '(') return EvalError.INVALID_EVAL_START?;
    if (expr[expr.len - 1] != ')') return EvalError.INVALID_EVAL_END?;

    int i = 1;
    while (expr[i] == ' ') i++;

    int cur = i;
    CInt res;
    CInt operand;
    
    char op = expr[cur];
    cur++;

    bool initted = false;

    for (i = cur; i < expr.len - 1; i++)
    {
        if (expr[i] == ' ') 
        {
            cur = i;
            continue;
        }

        if (i == expr.len - 1 && expr[i] != ')') return EvalError.INVALID_EVAL_END?;
        if (i == expr.len - 1 && expr[i] == ')') break;

        CInt val;
        if (!expr[i].is_digit() && expr[i] != 'h' && expr[i] != 'H' && expr[i] != 'w' && expr[i] != 'W') return EvalError.INVALID_EVAL_OPERAND?;
        
        // After h or w there must be a space.
        if (!expr[i].is_digit() && (long)(i + 1) < expr.len - 1 && expr[i + 1] != ' ') return EvalError.INVALID_EVAL_OPERAND?; 

        switch (expr[i])
        {
            case 'w':
            case 'W':
                val = ncurses::getmaxx(ncurses::stdscr);

            case 'h':
            case 'H':
                val = ncurses::getmaxy(ncurses::stdscr);

            default:
                if ((long)(i + 1) < expr.len - 1 && expr[i + 1].is_digit()) continue; 
                CInt? x = (CInt) expr[cur + 1: i - cur].to_int();
                if (catch x) return EvalError.INVALID_EVAL_OPERAND?;
                val = x;
        }

        if (!initted)
        {
            res = val;
            initted = true;
            continue;
        }

        switch (op)
        {
            case '+':
                res += val;
            case '-':
                res -= val;
            case '*':
                res *= val;
            case '/':
                res /= val;
            default:
                return EvalError.INVALID_EVAL_OPERATION?;
        }
    }

    return res;
}
// //// HELPER FUNCTIONS END        ///////////////////////////////////////////

// //// JSON PARSING STUFF START    ///////////////////////////////////////////
faultdef
    LAYOUT_MISSING_FIELD,
    LAYOUT_INVALID_FIELD;

fn Component*? windowFromJson(Object *json)
{
    String? json_window_type = json.get_string("type");
    if (catch json_window_type) return LayoutError.LAYOUT_MISSING_FIELD?;

    WindowType? window_type = enum_by_name(WindowType, json_window_type);
    if (catch window_type) return LayoutError.LAYOUT_INVALID_FIELD?;
    
    // Other fields are default initialized to 0
    Component *crafted = new_window(window_type);

    bool? window_is_visible = json.get_bool("is_visible");
    if (try window_is_visible)
    {
        crafted.win.is_visible = window_is_visible;
    }

    bool? window_is_boxed = json.get_bool("is_boxed");
    if (try window_is_boxed)
    {
        crafted.win.is_boxed = window_is_boxed;
    }

    return crafted;
}

fn Component*? boxFromJson(Object *json, Component *parent)
{
    String? json_box_type = json.get_string("type");
    if (catch json_box_type) return LayoutError.LAYOUT_MISSING_FIELD?;

    BoxType? box_type = enum_by_name(BoxType, json_box_type);
    if (catch box_type) return LayoutError.LAYOUT_INVALID_FIELD?;
    
    Component *crafted;

    switch (box_type)
    {
        case HBOX:
            crafted = new_hbox();
        case VBOX:
            crafted = new_vbox();
        default:
            unreachable("A new type of box was introduced but not handled");
    }

    crafted.parent = parent;

    // Forced to omit the attribute because if the json parser encounters
    // an empty array it never sets the Object type to List.
    Object*? json_children = json.get("children");
    if (try json_children)
    {
        if (!json_children.is_array()) return LayoutError.LAYOUT_INVALID_FIELD?;

        foreach (json_child : json_children.array)
        {
            Component *child = fromJson(json_child, crafted)!;
            crafted.box.children.push(child);
        }
    }

    return crafted;
}

fn Component*? fromJson(Object *json, Component *parent = null)
{
    String? json_component_type = json.get_string("type");
    if (catch json_component_type) return LayoutError.LAYOUT_MISSING_FIELD?;

    ComponentType? component_type = enum_by_name(ComponentType, json_component_type);
    if (catch component_type) return LayoutError.LAYOUT_INVALID_FIELD?;

    Component *crafted;

    switch (component_type)
    {
        case WINDOW:
            Object*? json_window = json.get("win");
            if (catch json_window) return LayoutError.LAYOUT_MISSING_FIELD?;
            crafted = windowFromJson(json_window)!;
        case LAYOUT:
            Object*? json_box = json.get("box");
            if (catch json_box) return LayoutError.LAYOUT_MISSING_FIELD?;
            crafted = boxFromJson(json_box, crafted)!;
        default:
            unreachable("ComponentType not handled");
    }

    crafted.parent = parent;

    String? json_box_width = json.get_string("width");
    if (try json_box_width)
    {
        switch (json_box_width)
        {
            case "GROW":
                crafted.width = axis_grow();
            case "FIT":
                crafted.width = axis_fit();
            case "W":
                CInt value = ncurses::getmaxx(ncurses::stdscr);
                crafted.width = axis_fixed(value);
            case "H":
                CInt value = ncurses::getmaxy(ncurses::stdscr);
                crafted.width = axis_fixed(value);
            default:
                if (json_box_width.len == 0) break;

                if (json_box_width.starts_with("("))
                {
                    CInt value = evaluate_s_expression(json_box_width)!;
                    crafted.width = axis_fixed(value);
                }
                else
                {
                    CInt value = json_box_width.to_int()!;
                    crafted.width = axis_fixed(value);
                }
        }
    }

    String? json_box_height = json.get_string("height");
    if (try json_box_height)
    {
        switch (json_box_height)
        {
            case "GROW":
                crafted.height = axis_grow();
            case "FIT":
                crafted.height = axis_fit();
            case "w":
            case "W":
                CInt value = ncurses::getmaxx(ncurses::stdscr);
                crafted.height = axis_fixed(value);
            case "h":
            case "H":
                CInt value = ncurses::getmaxy(ncurses::stdscr);
                crafted.height = axis_fixed(value);
            default:
                if (json_box_height.len == 0) break;

                if (json_box_height.starts_with("("))
                {
                    CInt value = evaluate_s_expression(json_box_height)!;
                    crafted.height = axis_fixed(value);
                }
                else
                {
                    CInt value = json_box_height.to_int()!;
                    crafted.height = axis_fixed(value);
                }
        }
    }

    return crafted;
}
// //// JSON PARSING STUFF END      ///////////////////////////////////////////

// //// GROWING CALCULATION START   ///////////////////////////////////////////
fn CInt boxCalculateLeftWidth(Component *component)
{
    CInt remaining_width = component.width.value;
    
    foreach (child : component.box.children)
    {
        remaining_width -= child.width.value;
    }

    return remaining_width;
}

fn CInt boxCalculateLeftHeight(Component *component)
{
    CInt remaining_height = component.height.value;
    
    foreach (child : component.box.children)
    {
        remaining_height -= child.height.value;
    }

    return remaining_height;
}

fn List{Component *} box_growable_width_children_list(Box *box)
{
    List{Component *} growable_children;
    growable_children.tinit();

    foreach (child : box.children)
    {
        if (child.width.type != GROW) continue;
        growable_children.push(child);
    }

    return growable_children;
}

fn List{Component *} box_growable_height_children_list(Box *box)
{
    List{Component *} growable_children;
    growable_children.tinit();

    foreach (child : box.children)
    {
        if (child.height.type != GROW) continue;
        growable_children.push(child);
    }

    return growable_children;
}

fn CInt component_take_width(Component *component)
{
    return component.width.value;
}

fn CInt component_take_height(Component *component)
{
    return component.height.value;
}

fn void component_bfs_grow_width(Component *root)
{
    List{Component *} queue;
    queue.tinit();

    queue.push(root);
    while (!queue.is_empty())
    {
        // The queue should not be empty here
        Component *item = queue.pop_first()!!;

        if GROW: (item.parent && item.width.type == GROW)
        {
            List{Component *} growable_children = box_growable_width_children_list(item.parent.box);
            CInt left_w;

            // Across-axis growth: expand to fill the width of the parent.
            if (item.parent.box.type == VBOX)
            {
                left_w = item.parent.width.value;

                foreach (child : growable_children)
                {
                    child.width.value = left_w;
                }

                break GROW;
            }

            // Along-axis growth: grow the children to fill the parent width equally.
            left_w = boxCalculateLeftWidth(item.parent);

            while (left_w > 0)
            {
                CInt smallest = component_take_width(growable_children[0]); 
                CInt second_smallest = -1;
                CInt width_to_add = left_w;

                foreach (child : growable_children)
                {
                    CInt child_width = component_take_width(child);
                    if (child_width < smallest)
                    {
                        second_smallest = smallest;
                        smallest = child_width;
                    }
                    if (child_width > smallest)
                    {
                        second_smallest = min(second_smallest, child_width);
                        width_to_add = second_smallest - smallest;
                    }
                }

                width_to_add = min(width_to_add, left_w / (CInt) growable_children.len());

                // It means that the left_w is not divisible by the number of 
                // growable_children so add it to the first one and go.
                if (width_to_add == 0)
                {
                    item.width.value += left_w;
                    break;
                }

                foreach (child : growable_children)
                {
                    CInt child_width = component_take_width(child);
                    if (child_width == smallest)
                    {
                        child.width.value += width_to_add;
                        left_w -= width_to_add;
                    }
                }
            }
        }

        if (item.type == LAYOUT)
        {
            foreach (child : item.box.children) queue.push(child);
        }
    }
}

fn void component_bfs_grow_height(Component *root)
{
    List{Component *} queue;
    queue.tinit();

    queue.push(root);
    while (!queue.is_empty())
    {
        // The queue should not be empty here
        Component *item = queue.pop_first()!!;

        if GROW: (item.parent && item.height.type == GROW)
        {
            List{Component *} growable_children = box_growable_height_children_list(item.parent.box);
            CInt left_h;

            // Across-axis growth: expand to fill the height of the parent.
            if (item.parent.box.type == HBOX)
            {
                left_h = item.parent.height.value;

                foreach (child : growable_children)
                {
                    child.height.value = left_h;
                }

                break GROW;
            }

            // Along-axis growth: grow the children to fill the parent height equally.
            left_h = boxCalculateLeftHeight(item.parent);

            while (left_h > 0)
            {
                CInt smallest = component_take_height(growable_children[0]); 
                CInt second_smallest = -1;
                CInt height_to_add = left_h;

                foreach (child : growable_children)
                {
                    CInt child_height = component_take_height(child);
                    if (child_height < smallest)
                    {
                        second_smallest = smallest;
                        smallest = child_height;
                    }
                    if (child_height > smallest)
                    {
                        second_smallest = min(second_smallest, child_height);
                        height_to_add = second_smallest - smallest;
                    }
                }

                height_to_add = min(height_to_add, left_h / (CInt) growable_children.len());

                // It means that the left_h is not divisible by the number of 
                // growable_children so add it to the first one and go.
                if (height_to_add == 0)
                {
                    item.height.value += left_h;
                    break;
                }

                foreach (child : growable_children)
                {
                    CInt child_height = component_take_height(child);
                    if (child_height == smallest)
                    {
                        child.height.value += height_to_add;
                        left_h -= height_to_add;
                    }
                }
            }
        }

        if (item.type == LAYOUT)
        {
            foreach (child : item.box.children) queue.push(child);
        }
    }
}
// //// GROWING CALCULATION END     ///////////////////////////////////////////

// //// SIZE CALCULATION START      ///////////////////////////////////////////
fn void component_dfs_calculate_width(Component *root)
{
    if (root.type != LAYOUT) return;
    if (root.width.type == FIXED) return;

    foreach (child : root.box.children)
    {
        component_dfs_calculate_width(child);

        switch (root.box.type)
        {
            case HBOX:
                if (root.width.type != FIXED) root.width.value += child.width.value;
            case VBOX:
                if (root.width.type != FIXED) root.width.value = max(root.width.value, child.width.value);
            default:
                unreachable("BoxType not handled");
        }
    }
}

fn void component_dfs_calculate_height(Component *root)
{
    if (root.type != LAYOUT) return;
    if (root.height.type == FIXED) return;

    foreach (child : root.box.children)
    {
        component_dfs_calculate_height(child);

        switch (root.box.type)
        {
            case HBOX:
                if (root.height.type != FIXED) root.height.value = max(root.height.value, child.height.value);
            case VBOX:
                if (root.height.type != FIXED) root.height.value += child.height.value;
            default:
                unreachable("BoxType not handled");
        }
    }
}
// //// SIZE CALCULATION END        ///////////////////////////////////////////

// //// POSITION CALCULATION START  ///////////////////////////////////////////
fn void component_bfs_calculate_positions(Component *root)
{
    List{Component *} queue;
    queue.tinit();

    queue.push(root);
    while (!queue.is_empty())
    {
        // The queue should not be empty here
        Component *item = queue.pop_first()!!;

        if (item.parent)
        {
            switch (item.parent.box.type)
            {
                case HBOX:
                    item.x = item.parent.x + item.parent.offset;
                    item.y = item.parent.y;
                    item.parent.offset += item.width.value;
                case VBOX:
                    item.x = item.parent.x;
                    item.y = item.parent.y + item.parent.offset;
                    item.parent.offset += item.height.value;
                default:
                    unreachable("BoxType not handled");
            }
        }

        if (item.type == LAYOUT)
        {
            foreach (child : item.box.children) queue.push(child);
        }
    }
}
// //// POSITION CALCULATION END    ///////////////////////////////////////////
