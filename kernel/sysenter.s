#include <machine/asmacros.h>
#include <machine/psl.h>
#include <sys/syscall.h>
#include "assym.s"

ENTRY(sysenter_syscall)
	movl	(%esp),%esp	/* goto our stack */
	pushl	$UDSEL		/* fixed ring 3 %ss */
	pushl	%ecx		/* ring 3 %esp */
	sti			/* sysenter disabled interrupt */
	pushfl

	.globl	sysenter_push_cs
sysenter_push_cs:
	pushl	$UCSEL		/* fixed ring 3 %cs */
	pushl	%edx		/* ring 3 next %eip */
	pushl	$2		/* tf_err, sizeof sysenter (0F 34) */
	subl	$4,%esp		/* tf_trapno */
	pushal
	pushl	%ds
	pushl	%es
	pushl	%fs
	SET_KERNEL_SREGS
	FAKE_MCOUNT(TF_EIP(%esp))

	movl	PCPU(CURPCB),%esi
	call	syscall

	MEXITCOUNT
1:
	movl	PCPU(CURPCB),%esi
	testl	$PCB_FULLCTX,PCB_FLAGS(%esi)
	jnz	3f

	/*
	 * Check for ASTs atomically with returning.  Disabling CPU
	 * interrupts provides sufficient locking evein the SMP case,
	 * since we will be informed of any new ASTs by an IPI.
	 */
	cli
	movl	PCPU(CURTHREAD),%eax
	testl	$TDF_ASTPENDING | TDF_NEEDRESCHED,TD_FLAGS(%eax)
	je	2f
	sti
	pushl	%esp		/* pass a pointer to the trapframe */
	call	ast
	add	$4,%esp
	jmp	1b

2:
	.globl	sysenter_popl_fs
sysenter_popl_fs:
	popl	%fs
	.globl	sysenter_popl_es
sysenter_popl_es:
	popl	%es
	.globl	sysenter_popl_ds
sysenter_popl_ds:
	popl	%ds
	popal
	add	$8,%esp		/* discard tf_trapno, tf_err */
	popl	%edx		/* ring 3 %eip */
	add	$4,%esp		/* discard ring 3 %cs */
	movl	4(%esp),%ecx	/* ring 3 %esp */

	/*
	 * popf reenable interrupts, to guanrantee an atomic
	 * enable & return, it must be the last instruction
	 * before sysexit.
	 * 
	*/
	popfl
#if 0
	addl	$4,%esp		/* discard ring 3 ss */
#endif
	.globl	sysenter_sysexit
sysenter_sysexit:
	sysexit

3:
	andl	$~PCB_FULLCTX,PCB_FLAGS(%esi)
	jmp	doreti
