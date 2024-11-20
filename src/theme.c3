module rover::theme;
import ncurses;

bool dir, exe, link, pwd, host;
const CInt DIR = 1;
const CInt EXE = 2;
const CInt LNK = 3;
const CInt PWD = 4;
const CInt HST = 5;

macro set_dir()
{
    assert(!dir, "Directory text color can be set only once per time.");
    dir = true;
    ncurses::attron(ncurses::color_pair(DIR));
    ncurses::attron(ncurses::A_BOLD);
}

macro set_exe()
{
    assert(!exe, "Executable text color can be set only once per time.");
    exe = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(EXE));
}

macro set_link()
{
    assert(!link, "Symbolic link text color can be set only once per time.");
    link = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(LNK));
}

macro set_pwd()
{
    assert(!pwd, "PWD text color can be set only once per time.");
    pwd = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(PWD));
}

macro set_host()
{
    assert(!host, "Host name text color can be set only once per time.");
    host = true;
    ncurses::attron(ncurses::A_BOLD);
    ncurses::attron(ncurses::color_pair(HST));
}

macro highlight() => ncurses::attron(ncurses::A_REVERSE);

macro reset()
{
    assert(!dir || !exe, "Item can't be colored as directory and executable at the same time.");

    ncurses::attroff(ncurses::A_BOLD);
    ncurses::attroff(ncurses::A_REVERSE);
    if (dir)
    {
        dir = false;
        ncurses::attroff(ncurses::color_pair(DIR));
    }
    
    if (exe)
    {
        exe = false;
        ncurses::attroff(ncurses::color_pair(EXE));
    }

    if (link)
    {
        link = false;
        ncurses::attroff(ncurses::color_pair(LNK));
    }

    if (pwd)
    {
        pwd = false;
        ncurses::attroff(ncurses::color_pair(PWD));
    }

    if (host)
    {
        host = false;
        ncurses::attroff(ncurses::color_pair(HST));
    }
}
