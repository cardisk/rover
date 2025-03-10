module test;
import std::io;
import rover::layout;
import std::encoding::json;
import std::collections::list;
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
                        "type": "FIXED",
                        "w": "20",
                        "h": "30",
                    }
                }
            },
            {
                "type": "WINDOW",
                "win": {
                    "type": "TITLE",
                    "is_visible": true,
                    "is_boxed": true,
                    "size": {
                        "type": "FIXED",
                        "w": "10",
                        "h": "40",
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
        String! json_size_type = json_window_size.get_string("type");
        if (try json_size_type)
        {
            crafted.size.type = enum_by_name(SizeType, json_size_type)!;
        }

        String! json_size_w = json_window_size.get_string("w");
        if (try json_size_w)
        {
            // TODO: assuming only fixed numbers for now.
            crafted.size.w = (CInt) json_size_w.to_int()!!;
        }

        String! json_size_h = json_window_size.get_string("h");
        if (try json_size_h)
        {
            // TODO: assuming only fixed numbers for now.
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

    Object*! json_box_size = json.get("size");
    if (try json_box_size)
    {
        String! json_size_type = json_box_size.get_string("type");
        if (try json_size_type)
        {
            crafted.size.type = enum_by_name(SizeType, json_size_type)!;
        }

        String! json_size_w = json_box_size.get_string("w");
        if (try json_size_w)
        {
            // TODO: assuming only fixed numbers for now.
            crafted.size.w = (CInt) json_size_w.to_int()!!;
        }

        String! json_size_h = json_box_size.get_string("h");
        if (try json_size_h)
        {
            // TODO: assuming only fixed numbers for now.
            crafted.size.h = (CInt) json_size_h.to_int()!!;
        }
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
            unreachable("ComponentType not handled");
    }

    return crafted;
}

fn CInt boxCalculateLeftWidth(Box *box)
{
    CInt remaining_width = box.size.w;
    
    foreach (child : box.children)
    {
        if (child.type == WINDOW)
        {
            // If child.size.type == GROW its w will be 0
            remaining_width -= child.win.size.w;
        }
    }

    return remaining_width;
}

fn CInt boxCalculateLeftHeight(Box *box)
{
    CInt remaining_height = box.size.w;
    
    foreach (child : box.children)
    {
        if (child.type == WINDOW)
        {
            // If child.size.type == GROW its h will be 0
            remaining_height -= child.win.size.h;
        }
    }

    return remaining_height;
}

fn List(<Component *>) box_growable_children_list(Box *box)
{
    List(<Component *>) growable_children;
    growable_children.tinit();

    foreach (child : box.children)
    {
        switch (child.type)
        {
            case WINDOW:
                if (child.win.size.type != GROW) continue;
            case LAYOUT:
                if (child.box.size.type != GROW) continue;
            default:
                unreachable("ComponentType not handled");
        }

        growable_children.push(child);
    }

    return growable_children;
}

fn CInt component_take_width(Component *component)
{
    switch (component.type)
    {
        case LAYOUT:
            return component.box.size.w;
        case WINDOW:
            return component.win.size.w;
        default:
            unreachable("ComponentType not handled");
    }
}

fn CInt component_take_height(Component *component)
{
    switch (component.type)
    {
        case LAYOUT:
            return component.box.size.h;
        case WINDOW:
            return component.win.size.h;
        default:
            unreachable("ComponentType not handled");
    }
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

                if (item.parent && box.size.type == GROW)
                {
                    Box *parent = item.parent.box;
                    List(<Component *>) growable_children = box_growable_children_list(parent);
                    CInt left_w = boxCalculateLeftWidth(parent);
                    CInt left_h = boxCalculateLeftHeight(parent);

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
                                switch (child.type)
                                {
                                    case LAYOUT:
                                        child.box.size.w += width_to_add;
                                    case WINDOW:
                                        child.win.size.w += width_to_add;
                                    default:
                                        unreachable("ComponentType not handled");
                                }

                                left_w -= width_to_add;
                            }
                        }
                    }

                    // TODO: missing same calculations for height.
                    // TODO: distinguish between along-axis and across-axis growth.
                }


                foreach (child : box.children) queue.push(child);
            case WINDOW:
            default:
                unreachable("ComponentType not handled");
        }
    }
}

// fn void component_dfs_grow(Component *root)
// {
//     if (root.type != LAYOUT) return;
//     if (root.box.size.type != FIXED) return;

//     CInt growing_children_number = boxCalculateGrowingChildrenNumber(root.box);
//     CInt left_w = boxCalculateLeftWidth(root.box);
//     CInt left_h = boxCalculateLeftHeight(root.box);
//     CInt grow_w = left_w / growing_children_number;
//     CInt grow_h = left_h / growing_children_number;
    
//     foreach (child : root.box.children)
//     {
//         component_dfs_grow(child);

//         Window *win = child.win;

//         if (win.size.type == GROW)
//         {
//             win.size.w += grow_w;
//             win.size.h += grow_h;
//         }
//     }
// }

fn void component_dfs_calculate_sizes(Component *root)
{
    if (root.type != LAYOUT) return;
    if (root.box.size.type == FIXED) return;

    foreach (child : root.box.children)
    {
        component_dfs_calculate_sizes(child);

        Box *parent = child.parent.box;
        Window *win = child.win;

        switch (parent.type)
        {
            case HBOX:
                parent.size.w += win.size.w;
                parent.size.h = max(parent.size.h, win.size.h);
            case VBOX:
                parent.size.w = max(parent.size.w, win.size.w);
                parent.size.h += win.size.h;
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
