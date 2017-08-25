#include <stdio.h>
#include <signal.h>

#define SECONDS 2

extern int __fsys_geteuid(void);
int stop;

unsigned test1()
{
	unsigned int count = 0;
	while (!stop) {
		geteuid();
		count++;
	}
	return count;
}


unsigned test2()
{
	unsigned int count = 0;
	int i;
	while (!stop) {
		__fsys_geteuid();
		count++;
	}
	return count;
}

void alarm_handler(int sig)
{
	stop = 1;
}

int main()
{
	unsigned int count1, count2;

	signal(SIGALRM, alarm_handler);
	alarm(SECONDS);
	count1 = test1();
	printf("int 0x80 syscall: %d/s\n", count1/SECONDS);
	stop = 0;
	alarm(SECONDS);
	count2 = test2();
	printf("sysenter syscall: %d/s\n", count2/SECONDS);
	return 0;
}

