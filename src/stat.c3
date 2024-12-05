module rover::stat;
import std::io::path;
import libc;

macro bool is_dir(p)
{
    // TODO: native is_dir does not take account of WIN32.
    // maybe implement something here?
    return path::is_dir(p);
}

macro bool @read_stat(p, &s)
{
    $if env::POSIX:
        if (rover::lstat(p.as_zstr(), s) < 0) return false;
        return true;
    $else
        $error("Non-Posix platform not supported");
    $endif
}

macro bool is_stat(stat, type) => ((stat.st_mode & libc::S_IFMT) == type);

fn int is_exe(Path p)
{
    Stat stat;
    if (!@read_stat(p, stat)) return -1;
    if (is_stat(stat, libc::S_IXUSR)) return 1;
    return 0;
}

fn int is_link(Path p)
{
    Stat stat;
    if (!@read_stat(p, stat)) return -1;
    if (is_stat(stat, libc::S_IFLNK)) return 1;
    return 0;
}

fn int is_modified(Path p, Stat last_seen)
{
    Stat stat;
    if (!@read_stat(p, stat)) return -1;

    $if env::DARWIN:
        return (int)(last_seen.st_mtimespec.tv_nsec == stat.st_mtimespec.tv_nsec);
    $endif

    $if env::LINUX:
        return (int)(last_seen.st_mtime == stat.st_mtime);
    $endif
}
