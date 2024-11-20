module rover::stat;
import std::io::path;
import libc;

macro bool is_dir(p)
{
    // TODO: native is_dir does not take account of WIN32.
    // maybe implement something here?
    return path::is_dir(p);
}

extern fn CInt lstat(ZString, Stat *);
macro bool is_stat(stat, type) => ((stat.st_mode & libc::S_IFMT) == type);

macro bool is_exe(p)
{

    Stat stat;
    $if env::POSIX:
        if (lstat(p.as_zstr(), &stat) < 0)
        {
            rover::deinit();
            io::eprintfn("Can't read stats of '%s': %s", p, libc::strerror(libc::errno()));
            libc::exit(1);
        }
    $else
        $error("Non-Posix platform not supported");
    $endif

    if (is_stat(stat, libc::S_IXUSR)) return true;
    return false;
}

macro bool is_link(p)
{
    Stat stat;
    $if env::POSIX:
        if (lstat(p.as_zstr(), &stat) < 0)
        {
            rover::deinit();
            io::eprintfn("Can't read stats of '%s': %s", p, libc::strerror(libc::errno()));
            libc::exit(1);
        }
    $else
        $error("Non-Posix platform not supported");
    $endif

    if (is_stat(stat, libc::S_IFLNK)) return true;
    return false;
}
