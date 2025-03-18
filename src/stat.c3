module rover::stat;
import std::io::path;
import libc;

macro bool is_dir(p)
{
    // TODO: native is_dir does not take account of WIN32.
    // maybe implement something here?
    return path::is_dir(p);
}

fn bool read_stat(Path p, Stat *s)
{
    $if env::POSIX:
        if (rover::lstat(p.as_zstr(), s) < 0) return false;
        return true;
    $else
        $error("Non-Posix platform not supported");
    $endif
}

fn int is_exe(Path p)
{
    Stat stat;
    if (!read_stat(p, &stat)) return -1;
    if (stat.st_mode & libc::S_IXUSR) return 1;
    return 0;
}

fn int is_link(Path p)
{
    Stat stat;
    if (!read_stat(p, &stat)) return -1;
    if ((stat.st_mode & libc::S_IFMT) == libc::S_IFLNK) return 1;
    return 0;
}

fn int is_modified(Path p, Stat last_seen)
{
    Stat stat;
    if (!read_stat(p, &stat)) return -1;

    $if env::DARWIN:
        return (int)(last_seen.st_mtimespec.ns != stat.st_mtimespec.ns);
    $endif

    $if env::LINUX:
        return (int)(last_seen.st_mtime != stat.st_mtime);
    $endif
}

fn DString tposix_perm(Stat s)
{
    DString perm;
    // Only 10 slots are needed, round to the next power of 2 (default 16).
    perm.tinit();

    $if env::POSIX:
        perm.append(libc_S_ISTYPE(s.st_mode, libc::S_IFDIR) ? "d" : "-");
        perm.append((s.st_mode &  libc::S_IRUSR) ? "r" : "-");
        perm.append((s.st_mode &  libc::S_IWUSR) ? "w" : "-");
        perm.append((s.st_mode &  libc::S_IXUSR) ? "x" : "-");
        perm.append((s.st_mode & rover::S_IRGRP) ? "r" : "-");
        perm.append((s.st_mode & rover::S_IWGRP) ? "w" : "-");
        perm.append((s.st_mode & rover::S_IXGRP) ? "x" : "-");
        perm.append((s.st_mode & rover::S_IROTH) ? "r" : "-");
        perm.append((s.st_mode & rover::S_IWOTH) ? "w" : "-");
        perm.append((s.st_mode & rover::S_IXOTH) ? "x" : "-");
    $else
        $error("Non-Posix platform not supported");
    $endif

    return perm;
}
