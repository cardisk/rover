module test;
import std::io;
import rover::layout;
import std::encoding::json;
import std::collections::object;

const Size MAX_SIZE = { .type = FIXED, .w = 100, .h = 100 };

const String STRING_LAYOUT =
`
{
    "type": "LAYOUT",
    "box": {
        "type": "HBOX",
        "align": "CENTER",
        "children": [
            {
                "type": "WINDOW",
                "win": {
                    "type": "TITLE",
                    "is_visible": true,
                    "is_boxed": true,
                    "size": {
                        "w": "10",
                        "h": "10"
                    }
                }
            }
        ]
    }
}
`;

fault LayoutError
{
    MISSING_FIELD,
    INVALID_FIELD,
}

fn Window*! windowFromJson(Object *json)
{
    String! json_window_type = json.get_string("type");
    if (catch json_window_type) return LayoutError.MISSING_FIELD?;

    WindowType! window_type = enum_by_name(WindowType, json_window_type);
    if (catch window_type) return LayoutError.INVALID_FIELD?;
    
    // Other fields are default initialized to 0
    Window *crafted = layout::new_window(window_type);

    bool! window_is_visible = json.get_bool("is_visible");
    if (try window_is_visible)
    {
        crafted.is_visible = window_is_visible;
    }

    bool! window_is_boxed = json.get_bool("is_boxed");
    if (try window_is_boxed)
    {
        crafted.is_boxed = window_is_boxed;
    }

    Object*! json_window_size = json.get("size");
    if (try json_window_size)
    {
        String! json_size_w = json_window_size.get_string("w");
        if (try json_size_w)
        {
            // TODO: assuming only fixed numbers for now
            crafted.size.w = (CInt) json_size_w.to_int()!!;
        }

        String! json_size_h = json_window_size.get_string("h");
        if (try json_size_h)
        {
            // TODO: assuming only fixed numbers for now
            crafted.size.h = (CInt) json_size_h.to_int()!!;
        }
    }

    return crafted;
}

fn Box*! boxFromJson(Object *json, Component *parent)
{
    String! json_box_type = json.get_string("type");
    if (catch json_box_type) return LayoutError.MISSING_FIELD?;

    BoxType! box_type = enum_by_name(BoxType, json_box_type);
    if (catch box_type) return LayoutError.INVALID_FIELD?;
    
    // Other fields are default initialized to 0
    Box *crafted;

    switch (box_type)
    {
        case HBOX:
            crafted = layout::new_hbox();
        case VBOX:
            crafted = layout::new_vbox();
        default:
            unreachable("A new type of box was introduced but not handled");
    }

    String! json_box_align = json.get_string("align");
    if (try json_box_align)
    {
        crafted.align = enum_by_name(BoxAlign, json_box_align)!;
    }

    Object*! json_children = json.get("children");
    if (catch json_children) return LayoutError.MISSING_FIELD?;
    if (!json_children.is_array()) return LayoutError.INVALID_FIELD?;

    foreach (json_child : json_children.array)
    {
        Component *child = fromJson(json_child, parent)!;
        crafted.children.push(child);
    }

    return crafted;
}

fn Component*! fromJson(Object *json, Component *parent = null)
{
    String! json_component_type = json.get_string("type");
    if (catch json_component_type) return LayoutError.MISSING_FIELD?;

    ComponentType! component_type = enum_by_name(ComponentType, json_component_type);
    if (catch component_type) return LayoutError.INVALID_FIELD?;

    Component *crafted = layout::new_component(component_type);
    crafted.parent = parent;
    switch (crafted.type)
    {
        case WINDOW:
            Object*! json_window = json.get("win");
            if (catch json_window) return LayoutError.MISSING_FIELD?;
            Window *window = windowFromJson(json_window)!;
            crafted.win = window;
        case LAYOUT:
            Object*! json_box = json.get("box");
            if (catch json_box) return LayoutError.MISSING_FIELD?;
            Box *box = boxFromJson(json_box, crafted)!;
            crafted.box = box;
        default:
            unreachable("A new type of component was introduced but not handled");
    }

    return crafted;
}

fn void component_dfs(Component *root)
{
    if (root.type != LAYOUT) return;
    foreach (child : root.box.children)
    {
        component_dfs(child);

        Window *win = child.win;
        Box *parent = child.parent.box;

        if (win.size.type == GROW)
        {
            CInt child_w = parent.size.w / (CInt) parent.children.len();
            win.size.w = child_w;

            CInt child_h = parent.size.h / (CInt) parent.children.len();
            win.size.h = child_h;
        }
    }
}

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
        default:
            unreachable("A new type of component was introduced but not handled");
    }
}

fn Component*! parse_layout_tree(String str)
{
    Object *json = json::parse_string(str)!;
    defer json.free();

    Component *root = fromJson(json)!;
    if (root.type == LAYOUT)
    {
        root.box.size = MAX_SIZE;
    }

    return root;
}

fn void main()
{
    Component *component = parse_layout_tree(STRING_LAYOUT)!!;
    print_component(component);
    component_dfs(component);
    print_component(component);
}
