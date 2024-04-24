#ifndef FOS_KERN_MONITOR_H
#define FOS_KERN_MONITOR_H
#ifndef FOS_KERNEL
# error "This is a FOS kernel header; user programs should not #include it"
#endif

#include <inc/types.h>

// Function to activate the kernel command prompt
void run_command_prompt();
int execute_command(char *command_string);

// Declaration of functions that implement command prompt commands.
int command_help(int , char **);
int command_kernel_info(int , char **);
int command_ver(int number_of_arguments, char **arguments);
int command_add(int number_of_arguments, char **arguments);
int command_cnia(int number_of_arguments, char **arguments);
int*CreateIntArray(int number_of_arguments, char **arguments);

/*ASSIGNMENT#1*/
int command_cav(int number_of_arguments, char **arguments );
int CalcArrVar(char** arguments);
uint32 ConnectVirtualToPhysicalFrame(char** arguments);
int command_cvp(int number_of_arguments, char **arguments );
int CountModifiedPagesInRange(char** arguments);
int command_cmps(int , char **);
void TransferUserPage(char** arguments);
int command_tup(int, char **);
#endif	// !FOS_KERN_MONITOR_H
