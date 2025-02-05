module rover;
import libc;

// TODO: maybe create a pull request for this bindings.

// Everything missing from libc bindings
const S_IRGRP = 0o0000040;
const S_IWGRP = 0o0000020;
const S_IXGRP = 0o0000010;
const S_IROTH = 0o0000004;
const S_IWOTH = 0o0000002;
const S_IXOTH = 0o0000001;

struct Group
{
    ZString  gr_name;     // group name
    ZString  gr_passwd;   // group password
    Gid_t    gr_gid;      // group id
    ZString *gr_mem;      // group members
}

struct Passwd
{
    ZString pw_name;      // user name
    ZString pw_passwd;    // encrypted password
    Uid_t   pw_uid;       // user uid
    Gid_t   pw_gid;       // user gid
    Time_t  pw_change;    // password change time
    ZString pw_class;     // user access class
    ZString pw_gecos;     // Honeywell login info
    ZString pw_dir;       // home directory
    ZString pw_shell;     // default shell
    Time_t  pw_expire;    // account expiration
    CInt    pw_fields;    // internal: fields filled in
}

extern fn ZString getlogin();
extern fn CInt gethostname(ZString, usz);

extern fn CInt isascii(CInt);

extern fn CInt lstat(ZString, Stat *);

extern fn Group  *getgrgid(CUInt gid);
extern fn Passwd *getpwuid(CUInt uid);
