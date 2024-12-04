module rover;
import libc;

// Everything missing from libc bindings
extern fn ZString getlogin();
extern fn CInt gethostname(ZString, usz);

extern fn CInt isalnum(CInt);

extern fn CInt lstat(ZString, Stat *);
