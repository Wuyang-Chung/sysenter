#include <sys/syscall.h>
#include <machine/asm.h>

#define	SYSCALL(x)	ENTRY(__CONCAT(__fsys_,x));			\
			pushl %ecx;			\
			pushl %edx;			\
			mov __CONCAT($SYS_,x),%eax;	\
			mov %esp,%ecx;			\
			leal __CONCAT(__CONCAT(sys_,x),SYSExitThere), %edx;	\
			sysenter;			\
		__CONCAT(__CONCAT(sys_,x),SYSExitThere):;\
			popl %edx;			\
			popl %ecx

#define	RSYSCALL(x)	SYSCALL(x); ret
