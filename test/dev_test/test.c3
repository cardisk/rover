module test;
import std::io;
import rover::layout;
import std::encoding::json;
import std::collections::list;
import std::collections::object;

const Axis MAX_WIDTH  = { .type = FIXED, .value = 100 };
const Axis MAX_HEIGHT = { .type = FIXED, .value = 100 };

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

    String! json_box_width  = json.get_string("width");
    if (try json_box_width)
    {
        switch (json_box_width)
        {
            case "GROW":
                crafted.width = layout::axis_grow();
            case "FIT":
                crafted.width = layout::axis_fit();
            default:
                // TODO: handling ncurses width and height.
                CInt value = json_box_width.to_int()!!;
                crafted.width = layout::axis_fixed(value);
        }
    }

    String! json_box_height = json.get_string("height");
    if (try json_box_height)
    {
        switch (json_box_height)
        {
            case "GROW":
                crafted.height = layout::axis_grow();
            case "FIT":
                crafted.height = layout::axis_fit();
            default:
                // TODO: handling ncurses width and height.
                CInt value = json_box_height.to_int()!!;
                crafted.height = layout::axis_fixed(value);
        }
    }

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
            unreachable("ComponentType not handled");
    }

    return crafted;
}

fn CInt boxCalculateLeftWidth(Component *component)
{
    CInt remaining_width = component.width.value;
    
    foreach (child : component.box.children)
    {
        if (child.type == WINDOW)
        {
            remaining_width -= child.width.value;
        }
    }

    return remaining_width;
}

fn CInt boxCalculateLeftHeight(Component *component)
{
    CInt remaining_height = component.height.value;
    
    foreach (child : component.box.children)
    {
        if (child.type == WINDOW)
        {
            remaining_height -= child.height.value;
        }
    }

    return remaining_height;
}

fn List(<Component *>) box_growable_width_children_list(Box *box)
{
    List(<Component *>) growable_children;
    growable_children.tinit();

    foreach (child : box.children)
    {
        if (child.width.type != GROW) continue;
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

fn void component_bfs_grow(Component *root)
{
    List(<Component *>) queue;
    queue.tinit();

    queue.push(root);
    while (!queue.is_empty())
    {
        // The queue should not be empty here
        Component *item = queue.pop_first()!!;
        switch (item.type)
        {
            case LAYOUT:
                Box *box = item.box;

                if (item.parent && item.width.type == GROW)
                {
                    List(<Component *>) growable_children = box_growable_width_children_list(item.parent.box);
                    CInt left_w = boxCalculateLeftWidth(item.parent);

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

                // TODO: missing same calculations for height.
                // TODO: distinguish between along-axis and across-axis growth.

                foreach (child : box.children) queue.push(child);
            case WINDOW:
            default:
                unreachable("ComponentType not handled");
        }
    }
}

fn void component_dfs_calculate_sizes(Component *root)
{
    if (root.type != LAYOUT) return;
    if (root.width.type == FIXED && root.height.type == FIXED) return;

    foreach (child : root.box.children)
    {
        component_dfs_calculate_sizes(child);

        switch (root.box.type)
        {
            case HBOX:
                if (root.width.type != FIXED) root.width.value += child.width.value;
                if (root.height.type != FIXED) root.height.value = max(root.height.value, child.height.value);
            case VBOX:
                if (root.width.type != FIXED) root.width.value = max(root.width.value, child.width.value);
                if (root.height.type != FIXED) root.height.value += child.height.value;
            default:
                unreachable("BoxType not handled");
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
            unreachable("ComponentType not handled");
    }
}

fn Component*! parse_layout_tree(String str)
{
    Object *json = json::parse_string(str)!;
    defer json.free();

    Component *root = fromJson(json)!;
    // TODO: this behaviour is necessary to force the layout to stay
    // inside the terminal bounds.
    // if (root.type == LAYOUT)
    // {
    //     root.box.size = MAX_SIZE;
    // }

    return root;
}

fn void main()
{
    Component *component = parse_layout_tree(STRING_LAYOUT)!!;
    print_component(component);
    component_dfs_calculate_sizes(component);
    print_component(component);
}
