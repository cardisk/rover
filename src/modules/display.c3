module rover::display;
import std::collections::list;
import ncurses;

faultdef
    INIT_FAIL,
    NO_COLBIND,
    NO_PREVIEW,
    NO_STATUS;

enum Focus
{
    LIST,
    BOOKMARKS,
    POPUP,
}

enum PopupContentType
{
    STRING,
    PATH,
}

struct Display
{
    // Position selected inside the list.
    usz list_cur;
    // Boundaries of the list window (inclusive).
    usz list_vtop;
    usz list_vbot;
    // Position selected inside the bookmarks.
    usz bookmarks_cur;
    // Boundaries of the bookmarks window (inclusive).
    usz bookmarks_vtop;
    usz bookmarks_vbot;
    // Position selected inside the error popup.
    usz popup_cur;
    // Boundaries of the error popup (inclusive).
    usz popup_vtop;
    usz popup_vbot;

    Focus focus;

    // Subwindows.
    Window *title;
    Window *list;
    Window *preview;
    Window *bookmarks;
    Window *status;
    Window *prompt;

    // Popup, not customizable.
    PopupContentType popup_content_type;
    void *popup_content;
    usz popup_content_len;
    Window *popup;
}

fn void? Display.init(&self)
{
    // Initialization of ncurses is now made inside main.

    if (ncurses::keypad(ncurses::stdscr, true) == ncurses::ERR) return INIT_FAIL?;
    if (ncurses::noecho() == ncurses::ERR) return INIT_FAIL?;
    if (ncurses::raw() == ncurses::ERR) return INIT_FAIL?;
    if (ncurses::curs_set(0) == ncurses::ERR) return INIT_FAIL?;

    self.list_cur = 0;
    self.list_vtop = 0;
    self.list_vbot = 0;

    self.bookmarks_cur = 0;
    self.bookmarks_vtop = 0;
    self.bookmarks_vbot = 0;

    self.popup_cur = 0;
    self.popup_vtop = 0;
    self.popup_vbot = 0;

    self.focus = LIST;

    self.title     = null;
    self.list      = null;
    self.preview   = null;
    self.bookmarks = null;
    self.status    = null;
    self.prompt    = null;

    self.popup = null;
}

fn void Display.free(&self)
{
    if (self.title)     ncurses::delwin(self.title);
    if (self.list)      ncurses::delwin(self.list);
    if (self.preview)   ncurses::delwin(self.preview);
    if (self.bookmarks) ncurses::delwin(self.bookmarks);
    if (self.status)    ncurses::delwin(self.status);
    if (self.prompt)    ncurses::delwin(self.prompt);
}

macro Display.toggle_focus(&self)
{
    switch (self.focus)
    {
        case LIST:
            self.focus = BOOKMARKS;
        case BOOKMARKS:
            self.focus = LIST;
        case POPUP:
            self.focus = LIST;
    }
}

macro Display.toggle_popup(&self, PopupContentType type, void *content, usz len)
{
    self.popup_content_type = type;
    self.popup_content = content;
    self.popup_content_len = len;
    self.focus = POPUP;
}

macro Display.up(&self)
{
    switch (self.focus)
    {
        case LIST:
            if (self.list_cur > 0) self.list_cur--;
        case BOOKMARKS:
            if (self.bookmarks_cur > 0) self.bookmarks_cur--;
        case POPUP:
            if (self.popup_cur > 0) self.popup_cur--;
    }
}

macro Display.down(&self)
{
    switch (self.focus)
    {
        case LIST:
            if (self.list_cur < sys.ls.len() - 1)
            {
                self.list_cur++;
            }
        case BOOKMARKS:
            if (self.bookmarks_cur < sys.bookmarks.len() - 1)
            {
                self.bookmarks_cur++;
            }
        case POPUP:
            if (self.popup_cur < self.popup_content_len - 1)
            {
                self.popup_cur++;
            }
    }
}

macro Display.top(&self)
{
    switch (self.focus)
    {
        case LIST:
            self.list_cur = 0;
        case BOOKMARKS:
            self.bookmarks_cur = 0;
        case POPUP:
            self.popup_cur = 0;
    }
}

macro Display.bottom(&self)
{
    switch (self.focus)
    {
        case LIST:
            self.list_cur = sys.ls.len() - 1;
        case BOOKMARKS:
            self.bookmarks_cur = sys.bookmarks.len() - 1;
        case POPUP:
            self.popup_cur = self.popup_content_len - 1;
    }
}

macro Display.goto(&self, index)
{
    switch (self.focus)
    {
        case LIST:
            self.list_cur = index;
        case BOOKMARKS:
            self.bookmarks_cur = index;
        case POPUP:
            self.popup_cur = index;
    }
}

fn ZString Display.input(&self, ZString prefix)
{
    if (!self.prompt) return null;

    ncurses::werase(self.prompt);
    
    foreach (item : cfg.windows)
    {
        if (item.win.type != PROMPT) continue;
        if (item.win.is_boxed) ncurses::box(self.prompt, 0, 0);
    }

    CInt maxx, maxy;
    ncurses::@getmaxyx(self.prompt, maxy, maxx);

    CInt x = 2;
    CInt y = maxy / 2;

    ncurses::curs_set(1);
    ncurses::mvwprintw(self.prompt, y, x, "%s ", prefix);
    
    DString buf;
    buf.tinit(128);

    while LOOP: (true)
    {
        CInt in = ncurses::wgetch(self.prompt);
        CInt cur_x = ncurses::getcurx(self.prompt);

        switch (in)
        {
            case 27: // ESC
                ncurses::curs_set(0);
                return null;

            case '\n':
                break LOOP;

            case 127:
            case '\b':
            case ncurses::KEY_BACKSPACE:
                if (!buf.len()) break;
                ncurses::wprintw(self.prompt, "\b \b");
                buf.delete(buf.len() - 1);

            default:
                // clamping the text inside the window.
                if (x > maxx - 3) break;
                if (!((char) in).is_print()) break;
                ncurses::waddch(self.prompt, in);
                buf.append((char) in);
        }
    }

    ncurses::curs_set(0);

    return buf.zstr_view();
}

fn void? Display.update(&self)
{
    self.update_screen();
    self.clear();

    foreach (item : cfg.windows)
    {
        if (!item.win.is_visible) continue;

        bool boxed = item.win.is_boxed;

        switch (item.win.type)
        {
            case TITLE:
                if (boxed) ncurses::box(self.title, 0, 0);
                self.draw_title();
            case LIST:
                if (boxed) ncurses::box(self.list, 0, 0);
                self.draw_list();
            case PREVIEW:
                if (boxed) ncurses::box(self.preview, 0, 0);
                self.draw_preview()!;
            case BOOKMARKS:
                if (boxed) ncurses::box(self.bookmarks, 0, 0);
                self.draw_bookmarks();
            case STATUS:
                if (boxed) ncurses::box(self.status, 0, 0);
                self.draw_status()!;
            case PROMPT:
                if (boxed) ncurses::box(self.prompt, 0, 0);
                self.draw_prompt();
            default:
                unreachable("WindowType not supported by renderer.");
        }
    }

    if (self.focus == POPUP)
    {
        ncurses::werase(self.popup);

        ncurses::wattron(self.popup, ncurses::A_BOLD);
        ncurses::box(self.popup, 0, 0);
        ncurses::wattroff(self.popup, ncurses::A_BOLD);

        self.draw_popup();
    }

    // No need to call refresh cause getch() inside the main will 
    // automatically call it. 
}

module rover::display @private;
import std::io::path, std::io::file;
import rover::config, rover::stat;
import std::collections::list;
import ncurses;
import libc;

fn void Display.dir(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::DIRECTORY_COLOR));
}

fn void Display.exe(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::EXECUTABLE_COLOR));
}

fn void Display.link(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::LINK_COLOR));
}

fn void Display.pwd(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::PWD_COLOR));
}

fn void Display.host(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::HOST_COLOR));
}

fn void Display.err(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::color_pair(config::ERROR_COLOR));
}

macro Display.select(&self, Window *win)
{
    ncurses::wattron(win, ncurses::A_BOLD);
    ncurses::wattron(win, ncurses::A_REVERSE);
}

fn void Display.reset(&self, Window *win)
{
    ncurses::wattroff(win, ncurses::A_BOLD);
    ncurses::wattroff(win, ncurses::A_REVERSE);
    ncurses::wattroff(win, ncurses::color_pair(config::DIRECTORY_COLOR));
    ncurses::wattroff(win, ncurses::color_pair(config::EXECUTABLE_COLOR));
    ncurses::wattroff(win, ncurses::color_pair(config::LINK_COLOR));
    ncurses::wattroff(win, ncurses::color_pair(config::PWD_COLOR));
    ncurses::wattroff(win, ncurses::color_pair(config::HOST_COLOR));
    ncurses::wattroff(win, ncurses::color_pair(config::ERROR_COLOR));
}

fn bool is_printable(String str)
{
    foreach (c : str)
    {
        if (!(rover::isascii(c) || c.is_space())) return false;
    }
    return true;
}

fn void Display.update_screen(&self)
{
    if (app.resized)
    {
        // This is safe to assume because if something fails, it should
        // crash when the config module is loaded.
        cfg.reload_windows()!!;
        
        if (self.title)     ncurses::delwin(self.title);
        if (self.list)      ncurses::delwin(self.list);
        if (self.preview)   ncurses::delwin(self.preview);
        if (self.bookmarks) ncurses::delwin(self.bookmarks);
        if (self.status)    ncurses::delwin(self.status);
        if (self.prompt)    ncurses::delwin(self.prompt);
        if (self.popup)     ncurses::delwin(self.popup);

        self.title     = null;
        self.list      = null;
        self.preview   = null;
        self.bookmarks = null;
        self.status    = null;
        self.prompt    = null;
        self.popup     = null;

        foreach (item : cfg.windows)
        {
            if (!item.win.is_visible) continue;

            Window **win;

            switch (item.win.type)
            {
                case TITLE:
                    win = &self.title;
                case LIST:
                    win = &self.list;
                case PREVIEW:
                    win = &self.preview;
                case BOOKMARKS:
                    win = &self.bookmarks;
                case STATUS:
                    win = &self.status;
                case PROMPT:
                    win = &self.prompt;
                default:
                    unreachable("WindowType not supported by renderer.");
            }

            *win = ncurses::subwin(ncurses::stdscr, item.height.value, item.width.value, item.y, item.x);
        }

        self.popup = ncurses::subwin(ncurses::stdscr, app.h / 2, app.w / 2, app.h / 4, app.w / 4);   
    }
}

fn void Display.clear(&self)
{
    ncurses::werase(ncurses::stdscr);

    if (self.title)     ncurses::werase(self.title);
    if (self.list)      ncurses::werase(self.list);
    if (self.preview)   ncurses::werase(self.preview);
    if (self.bookmarks) ncurses::werase(self.bookmarks);
    if (self.status)    ncurses::werase(self.status);
    if (self.prompt)    ncurses::werase(self.prompt);
}

fn void Display.draw_title(&self)
{
    CInt x = 2;
    CInt y = ncurses::getmaxy(self.title);

    self.host(self.title);
    ncurses::mvwprintw(self.title, y / 2, x, "%s@%s ", app.user, app.host);
    self.pwd(self.title);
    ncurses::wprintw(self.title, "%s", sys.cwd.as_zstr());
    self.reset(self.title);
}

fn void Display.draw_list(&self)
{
    CInt w, h;
    ncurses::@getmaxyx(self.list, h, w);

    // Cursor coordinates.
    CInt x = 2;
    CInt y = 1;

    CInt w_stop = w - 5;
    CInt h_stop = h - 3;
    
    if (sys.ls.is_empty())
    {
        self.select(self.list);
        // It takes in account the borders and the front space.
        ncurses::mvwprintw(self.list, y, x, " %- *s", w_stop, "<empty>");
        self.reset(self.list);
        return;
    }

    if (app.resized) {
        self.top();
        self.list_vtop = 0;
        self.list_vbot = (usz) h_stop;
    }

    if (sys.ls.len() < (usz) h_stop) 
    {
        self.list_vtop = 0;
        self.list_vbot = sys.ls.len();
        // Here there was a return statement so if something broke maybe it's the cause.
    }
    else 
    {
        self.list_vbot = self.list_vtop + (usz) h_stop;
    }

    if (self.list_cur < self.list_vtop)
    {
        self.list_vtop -= 1;
        self.list_vbot -= 1;
    }
    else if (self.list_cur >= self.list_vbot)
    {
        self.list_vtop += 1;
        self.list_vbot += 1;
    }

    CInt offset = 0;
    for (usz i = self.list_vtop; i < self.list_vbot; i++)
    {
        if (stat::is_link(sys.ls[i]))
        {
            self.link(self.list);
        }
        else if (stat::is_dir(sys.ls[i])) 
        {
            self.dir(self.list);
        }
        else if (stat::is_exe(sys.ls[i]))
        {
            self.exe(self.list);
        }

        if (i == self.list_cur) self.select(self.list);

        DString item;
        item.tinit();
        if (sys.is_marked(i)) item.append("+ ");
        item.append(sys.ls[i].str_view().tcopy());

        // Taking in account elements with non-ascii chars.
        foreach (&c : item)
        {
            if (!c.is_print()) *c = '?';
        }

        if (item.len() > (usz)(w_stop - 1))
        {
            item[(usz)(w_stop - 1)] = '\0';
        }

        // Align text taking in account the first space and one in the middle
        ncurses::mvwprintw(self.list, y + offset, x, " %- *s", w_stop, item.zstr_view());

        self.reset(self.list);
        offset++;
    }
}

fn void? Display.draw_preview(&self)
{
    CInt w, h;
    ncurses::@getmaxyx(self.preview, h, w);

    // Cursor coordinates.
    CInt x = 2;
    CInt y = 1;

    CInt w_stop = w - 4;
    CInt h_stop = h - 3;

    if (sys.ls.is_empty()) return;

    if (path::is_file(sys.ls[self.list_cur]))
    {
        switch (stat::is_exe(sys.ls[self.list_cur]))
        {
            case 1:
                ncurses::mvwprintw(self.preview, y, x, "<binary>");

            case 0:
                char[]? chars = file::load_temp(sys.ls[self.list_cur].str_view());
                if (catch chars) break;

                String content = (String) chars;
                if (content.len == 0)
                {
                    ncurses::mvwprintw(self.preview, y, x, "<empty>");
                    break;
                }
                if (!is_printable(content))
                {
                    ncurses::mvwprintw(self.preview, y, x, "<binary>");
                    break;
                }
                String[] lines = content.tsplit("\n");

                usz stop = (usz) h_stop;
                if (lines.len < stop) stop = lines.len;
                
                for (int i = 0; i < stop; i++)
                {
                    DString item;
                    item.tinit(1024);
                    item.append(lines[i]);
                    item.replace("\t", "    ");

                    CInt len = (CInt) item.len();
                    if (len > w_stop) len = w_stop; 

                    ncurses::mvwprintw(self.preview, y + i, x, "%.*s", len, item.zstr_view());
                }

            case -1:
                return NO_PREVIEW?;
        }
    }

    if (stat::is_dir(sys.ls[self.list_cur]))
    {
        PathList? ls = path::ls(tmem, sys.ls[self.list_cur]);
        if (catch ls)
        {
            ncurses::mvwprintw(self.preview, y, x, "<error while loading>");
            return;
        }

        usz stop = (usz) h_stop;
        if (ls.len() < stop) stop = ls.len();
        
        if (ls.is_empty())
        {
            ncurses::mvwprintw(self.preview, y, x, "<empty>");
        }
        else
        {
            for (int i = 0; i < stop; i++)
            {
                ZString item = ls[i].str_view().zstr_tcopy();
                CInt len = (CInt) item.len();
                if (len > w_stop) len = w_stop;
                ncurses::mvwprintw(self.preview, y + i, x, "%.*s", len, item);
            }
        }
    }
}

fn void Display.draw_bookmarks(&self)
{
    CInt w, h;
    ncurses::@getmaxyx(self.bookmarks, h, w);

    // Cursor coordinates.
    CInt x = 2;
    CInt y = 1;

    CInt w_stop = w - 5;
    CInt h_stop = h - 3;
    
    if (sys.bookmarks.is_empty())
    {
        self.select(self.bookmarks);
        // It takes in account the borders and the front space.
        ncurses::mvwprintw(self.bookmarks, y, x, " %- *s", w_stop, "<empty>");
        self.reset(self.bookmarks);
        return;
    }

    if (app.resized) {
        self.top();
        self.bookmarks_vtop = 0;
        self.bookmarks_vbot = (usz) h_stop;
    }

    if (sys.bookmarks.len() < (usz) h_stop) 
    {
        self.bookmarks_vtop = 0;
        self.bookmarks_vbot = sys.bookmarks.len();
        // Here there was a return statement so if something broke maybe it's the cause.
    }
    else 
    {
        self.bookmarks_vbot = self.bookmarks_vtop + (usz) h_stop;
    }

    if (self.bookmarks_cur < self.bookmarks_vtop)
    {
        self.bookmarks_vtop -= 1;
        self.bookmarks_vbot -= 1;
    }
    else if (self.bookmarks_cur >= self.bookmarks_vbot)
    {
        self.bookmarks_vtop += 1;
        self.bookmarks_vbot += 1;
    }

    CInt offset = 0;
    for (usz i = self.bookmarks_vtop; i < self.bookmarks_vbot; i++)
    {
        if (stat::is_link(sys.bookmarks[i]))
        {
            self.link(self.bookmarks);
        }
        else if (stat::is_dir(sys.bookmarks[i])) 
        {
            self.dir(self.bookmarks);
        }
        else if (stat::is_exe(sys.bookmarks[i]))
        {
            self.exe(self.bookmarks);
        }

        if (i == self.bookmarks_cur) self.select(self.bookmarks);

        String item = sys.bookmarks[i].str_view().tcopy();

        // Taking in account elements with non-ascii chars.
        foreach (&c : item)
        {
            if (!c.is_print()) *c = '?';
        }

        if (item.len > (usz)(w_stop - 1))
        {
            item[(usz)(w_stop - 1)] = '\0';
        }

        // Align text taking in account the first space and one in the middle
        ncurses::mvwprintw(self.bookmarks, y + offset, x, " %- *s", w_stop, item);

        self.reset(self.bookmarks);
        offset++;
    }
}

fn void? Display.draw_status(&self)
{
    CInt x = 2;
    CInt maxx = ncurses::getmaxx(self.status);
    CInt y = ncurses::getmaxy(self.status);

    ZString leading, trailing;

    if (sys.ls.is_empty())
    {
        leading  = string::tformat_zstr("%s @ %s %s", "----------", "---", "---");
        trailing = string::tformat_zstr("%dB %d/%d", 0, 0, sys.ls.len());
    }
    else
    {
        Stat s;
        if (!stat::read_stat(sys.ls[self.list_cur], &s)) return NO_STATUS?;

        // Needed for group name.
        Group  *group  = rover::getgrgid(s.st_gid);
        // Needed for user name.
        Passwd *passwd = rover::getpwuid(s.st_uid);

        ZString perm = stat::tposix_perm(s).zstr_view();

        if (sys.filter)
        {
            leading  = string::tformat_zstr("%s @ %s %s @ %s", perm, passwd.pw_name, group.gr_name, sys.filter);
        }
        else
        {
            leading  = string::tformat_zstr("%s @ %s %s", perm, passwd.pw_name, group.gr_name);
        }

        trailing = string::tformat_zstr("%dB %d/%d", s.st_size, self.list_cur + 1, sys.ls.len());
    }

    // Avoid printing anything if the terminal width is too short.
    if ((CInt)(leading.len() + trailing.len()) + 3 > maxx) return;

    ncurses::wattron(self.status, ncurses::A_BOLD);
    ncurses::mvwprintw(self.status, y / 2, x, "%s", leading);
    ncurses::mvwprintw(self.status, y / 2, maxx - (CInt) trailing.len() - 2, "%s", trailing);
    ncurses::wattroff(self.status, ncurses::A_BOLD);
}

fn void Display.draw_prompt(&self)
{
    if (app.logs.is_empty()) return;

    CInt x = 2;
    CInt maxx = ncurses::getmaxx(self.status);
    CInt y = ncurses::getmaxy(self.status);

    // It's safe to assume that at least one element is present 'cause of
    // the first condition of this function.
    ZString msg = app.logs.first()!!.zstr_tcopy();

    self.err(self.prompt);
    ncurses::mvwprintw(self.prompt, y / 2, x, "%s", msg);
    self.reset(self.prompt);
}

fn void Display.draw_popup(&self)
{
    assert(self.popup_content, "Programmer forgot to init the content pointer");
    
    CInt w, h;
    ncurses::@getmaxyx(self.popup, h, w);

    // Cursor coordinates.
    CInt x = 2;
    CInt y = 1;

    CInt w_stop = w - 5;
    CInt h_stop = h - 2;
    
    if (app.resized) {
        self.top();
        self.popup_vtop = 0;
        self.popup_vbot = (usz) h_stop;
    }

    if (self.popup_content_len < (usz) h_stop) 
    {
        self.popup_vtop = 0;
        self.popup_vbot = self.popup_content_len;
        // Here there was a return statement so if something broke maybe it's the cause.
    }
    else 
    {
        self.popup_vbot = self.popup_vtop + (usz) h_stop;
    }

    if (self.popup_cur < self.popup_vtop)
    {
        self.popup_vtop -= 1;
        self.popup_vbot -= 1;
    }
    else if (self.popup_cur >= self.popup_vbot)
    {
        self.popup_vtop += 1;
        self.popup_vbot += 1;
    }

    CInt offset = 0;
    for (usz i = self.popup_vtop; i < self.popup_vbot; i++)
    {
        if (i == self.popup_cur) self.select(self.popup);

        String item;
        switch (self.popup_content_type)
        {
            case STRING:
                List{String} *temp = self.popup_content;
                item = (*temp)[i].tcopy();
            case PATH:
                List{Path} *temp = self.popup_content;
                item = (*temp)[i].str_view().tcopy();
            default:
                unreachable("Programmer's fault...sorry :(");
        }

        if (item.len > (usz)(w_stop - 1))
        {
            item[(usz)(w_stop - 1)] = '\0';
        }

        // Align text taking in account the first space and one in the middle
        ncurses::mvwprintw(self.popup, y + offset, x, " %- *s", w_stop, item);

        self.reset(self.popup);
        offset++;
    }
}
