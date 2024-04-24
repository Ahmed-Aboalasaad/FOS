#include <kern/tests.h>
#include <kern/memory_manager.h>

//define the white-space symbols
#define WHITESPACE "\t\r\n "

void TestAss1()
{
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q1:\n");
	cprintf("========================\n");
	TestAss1Q1();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q2:\n");
	cprintf("========================\n");
	TestAss1Q2();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q3:\n");
	cprintf("========================\n");
	TestAss1Q3();
	cprintf("\n========================\n");
	cprintf("Automatic Testing of Q4:\n");
	cprintf("========================\n");
	TestAss1Q4();
}

int TestAss1Q1()
{
	int retValue = 1;
	int i = 0;
	//Create first array
	char cr1[100] = "cnia _x4 3 10 20 30";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
	assert(ptr1 >= (int*)0xF1000000);


	//Create second array
	char cr2[100] = "cnia _y4 4 400 400";
	numOfArgs = 0;
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	int* ptr2 = CreateIntArray(numOfArgs,args);
	assert(ptr2 >= (int*)0xF1000000);

	int ret =0 ;

	//Calculate var of 1st array
	char v1[100] = "cav _x4";
	strsplit(v1, WHITESPACE, args, &numOfArgs) ;
	ret = CalcArrVar(args) ;

	if (ret != 66)
	{
		cprintf("[EVAL] #1 CalcArrVar: Failed\n");
		return 1;
	}

	//Calculate var of 2nd array
	char v2[100] = "cav _y4";
	strsplit(v2, WHITESPACE, args, &numOfArgs) ;
	ret = CalcArrVar(args) ;

	if (ret != 40000)
	{
		cprintf("[EVAL] #2 CalcArrVar: Failed\n");
		return 1;
	}

	cprintf("[EVAL] CalcArrVar: Succeeded. Evaluation = 1\n");

	return 1;
}

int TestAss1Q2()
{
	//Connect with write permission
	char cr1[100] = "cvp 0x0 768 w";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int ref1 = frames_info[0x00300000 / PAGE_SIZE].references;
	uint32 entry = ConnectVirtualToPhysicalFrame(args) ;
	char *ptr1, *ptr2, *ptr3;
	ptr1 = (char*)0x0; *ptr1 = 'A' ;
	int ref2 = frames_info[0x00300000 / PAGE_SIZE].references;

	if ((ref2 - ref1) != 0)
	{
		cprintf("Test1: Failed. You should manually implement the connection logic using paging data structures ONLY. [DON'T update the references]. Evaluation = 0\n");
		return 0;
	}

	uint32 f = entry & 0xFFFFF000 ;
	if (*ptr1 != 'A' || (f != 0x00300000) || ((entry & PERM_WRITEABLE) == 0))
	{
		cprintf("Test2: Failed. Evaluation = 0\n");
		return 0;
	}

	//Connect with read permission on same pa
	char cr2[100] = "cvp 0x00004000 768 r";
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	entry = ConnectVirtualToPhysicalFrame(args) ;
	ptr2 = (char*)0x00004000;

	int ref3 = frames_info[0x00300000 / PAGE_SIZE].references;

	if ((ref3 - ref2) != 0)
	{
		cprintf("Test3: Failed. You should manually implement the connection logic using paging data structures ONLY. [DON'T update the references]. Evaluation = 0.25\n");
		return 0;
	}

	f = entry & 0xFFFFF000 ;
	if (*ptr1 != 'A' || *ptr2 != 'A' || (f != 0x00300000) || ((entry & PERM_WRITEABLE) != 0))
	{
		cprintf("Test4: Failed. Evaluation = 0.5\n");
		return 0;
	}

	//Connect with write permission on already connected page
	char cr3[100] = "cvp 0x00004000 1024 w";
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
	int r1 = frames_info[0x00400000 / PAGE_SIZE].references;

	entry = ConnectVirtualToPhysicalFrame(args) ;

	ptr2 = (char*)0x00004000; *ptr2 = 'B';

	int ref4 = frames_info[0x00300000 / PAGE_SIZE].references;
	int r2 = frames_info[0x00400000 / PAGE_SIZE].references;

	if (*ptr1 != 'A' || *ptr2 != 'B' || (ref4 - ref1) != 0 || (r2 - r1) != 0)
	{
		cprintf("Test5: Failed [DON'T USE MAP_FRAME()! Implement the connection by yourself]. Evaluation = 0.5\n");
		return 0;
	}

	cprintf("[EVAL] ConnectVirtualToPhysicalFrame: Succeeded. Evaluation = 1\n");

	return 0;
}

int TestAss1Q3()
{
	int i = 0;
	//Not modified range
	char cr1[100] = "cmps 0xF0000000 0xF0005000";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;

	int cnt = CountModifiedPagesInRange(args) ;
	if (cnt != 0)
	{
		cprintf("[EVAL] #1 CntModPages: Failed. Evaluation = 0\n");
		return 0;
	}

	//Modify 3 pages in the range
	char *ptr ;
	ptr = (char*)0xF0000000 ; *ptr = 'A';
	ptr = (char*)0xF0000005 ; *ptr = 'B';
	ptr = (char*)0xF0003000 ; *ptr = 'C';
	ptr = (char*)0xF0004FFF ; *ptr = 'D';

	char cr2[100] = "cmps 0xF0000000 0xF0005000";
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;

	cnt = CountModifiedPagesInRange(args) ;
	if (cnt != 3)
	{
		cprintf("[EVAL] #2 CntModPages: Failed. Evaluation = 0.15\n");
		return 0;
	}


	//Modify 1 page outside the range
	ptr = (char*)0xF0005000 ; *ptr = 'X';

	char cr3[100] = "cmps 0xF0000000 0xF0005000";
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;

	cnt = CountModifiedPagesInRange(args) ;
	if (cnt != 3)
	{
		cprintf("[EVAL] #3 CntModPages: Failed. Evaluation = 0.30\n");
		return 0;
	}

	//range across multiple tables
	ptr = (char*)0xF03FF000 ; *ptr = 'A';
	ptr = (char*)0xF0405000 ; *ptr = 'B';
	ptr = (char*)0xF0900000 ; *ptr = 'C';
	ptr = (char*)0xF0903000 ; *ptr = 'D';
	ptr = (char*)0xF0904000 ; *ptr = 'E';
	ptr = (char*)0xF0905000 ; *ptr = 'X';

	char cr4[100] = "cmps 0xF03FF000 0xF0905000";
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;

	cnt = CountModifiedPagesInRange(args) ;
	if (cnt != 5)
	{
		cprintf("[EVAL] #4 CntModPages: Failed. Evaluation = 0.45\n");
		return 0;
	}

	//range across multiple tables & not on page boundary
	ptr = (char*)0xF0403333 ; *ptr = 'X';

	char cr5[100] = "cmps 0xF03FFFF0 0xF040500F";
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;

	cnt = CountModifiedPagesInRange(args) ;
	if (cnt != 3)
	{
		cprintf("[EVAL] #5 CntModPages: Failed. Evaluation = 0.70\n");
		return 0;
	}

	cprintf("[EVAL] CountModifiedPagesInRange: Succeeded. Evaluation = 1\n");

	return 0;
}

int TestAss1Q4()
{
	int eval = 0;
	char *ptr1, *ptr2, *ptr3, *ptr4, *ptr5, *ptr6, *ptr7;
	int kilo = 1024;
	int mega = 1024 * 1024;

	ClearUserSpace();
	cprintf("\nPART I: [COPY] Destination page exists [25% MARK]\n");
	//=================================================
	//PART I: [COPY] Destination page exists [25% MARK]
	//=================================================
	char ap1[100] = "ap 0x500000";
	execute_command(ap1);

	ptr1 = (char*) 0x500000;
	*ptr1 = 'a';
	ptr1 = (char*) 0x500100;
	*ptr1 = 'b';
	ptr1 = (char*) 0x500FFF;
	*ptr1 = 'c';
	char ap2[100] = "ap 0x502000";
	execute_command(ap2);
	uint32 *ptr_table;
	struct Frame_Info *srcFI1 = get_frame_info(ptr_page_directory, (void*)0x500000, &ptr_table);
	struct Frame_Info *dstFI1 = get_frame_info(ptr_page_directory, (void*)0x502000, &ptr_table);

	int ff1 = calculate_free_frames();

	char cmd1[100] = "tup 0x500000 0x502000 c";
	int numOfArgs = 0;
	char *args[MAX_ARGUMENTS];
	strsplit(cmd1, WHITESPACE, args, &numOfArgs);
	TransferUserPage(args);
	int ff2 = calculate_free_frames();
	struct Frame_Info *srcFI2 = get_frame_info(ptr_page_directory, (void*)0x500000, &ptr_table);
	struct Frame_Info *dstFI2 = get_frame_info(ptr_page_directory, (void*)0x502000, &ptr_table);

	int failed = 0;
	if (ff1 != ff2 || srcFI1 != srcFI2 || dstFI1 != dstFI2) {
		cprintf("[EVAL] #0 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}

	if (CB(0x500000, 0) != 1 || CB(0x502000, 0) != 1) {
		cprintf("[EVAL] #1 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	ptr1 = (char*) 0x500000;
	*ptr1 = 'z';
	ptr2 = (char*) 0x502000;
	ptr3 = (char*) 0x502100;
	ptr4 = (char*) 0x502FFF;
	if ((*ptr1) != 'z' || (*ptr2) != 'a' || (*ptr3) != 'b' || (*ptr4) != 'c') {
		failed = 1;
		cprintf("[EVAL] #2 TransferUserPage: Failed.\n");
		//return 0;
	}

	if (failed == 0)
		eval += 25;
	//ff1 = ff2 ;

	cprintf("\nPART II: [COPY] Destination page NOT exists [25% MARK]\n");
	//======================================================
	//PART II: [COPY] Destination page NOT exists [25% MARK]
	//======================================================
	char ap3[100] = "ap 0x600000";
	execute_command(ap3);

	ptr1 = (char*) 0x600000;
	*ptr1 = 'a';
	ptr1 = (char*) 0x600100;
	*ptr1 = 'b';
	ptr1 = (char*) 0x600FFF;
	*ptr1 = 'c';

	ff1 = calculate_free_frames();

	char cmd2[100] = "tup 0x600000 0x800000 c";
	strsplit(cmd2, WHITESPACE, args, &numOfArgs);

	TransferUserPage(args);

	ff2 = calculate_free_frames();

	failed = 0;
	if (ff1 - ff2 != 2) {
		cprintf("[EVAL] #3 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	if (CB(0x600000, 0) != 1 || CB(0x800000, 0) != 1) {
		cprintf("[EVAL] #4 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	ff1 = calculate_free_frames();

	char cmd3[100] = "tup 0x600000 0x900000 c";
	strsplit(cmd3, WHITESPACE, args, &numOfArgs);

	TransferUserPage(args);

	ff2 = calculate_free_frames();
	if (ff1 - ff2 != 1) {
		cprintf("[EVAL] #5 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	if (CB(0x600000, 0) != 1 || CB(0x900000, 0) != 1) {
		cprintf("[EVAL] #6 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	ptr1 = (char*) 0x600000;
	*ptr1 = 'z';
	ptr2 = (char*) 0x600100;
	ptr3 = (char*) 0x800000;
	ptr4 = (char*) 0x800100;
	ptr5 = (char*) 0x800FFF;
	ptr6 = (char*) 0x900000;
	ptr7 = (char*) 0x900FFF;
	if ((*ptr1) != 'z' || (*ptr2) != 'b' || (*ptr3) != 'a' || (*ptr4) != 'b' || (*ptr5) != 'c'
			|| (*ptr6) != 'a'|| (*ptr7) != 'c') {
		cprintf("[EVAL] #7 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	if (failed == 0)
		eval += 25 ;

	cprintf("\nPART III: [MOVE] Destination page exists [25% MARK]\n");
	//===================================================
	//PART III: [MOVE] Destination page exists [25% MARK]
	//===================================================
	char ap4[100] = "ap 0xC00000";
	execute_command(ap4);

	ptr1 = (char*) 0xC00000;
	*ptr1 = 'x';
	ptr1 = (char*) 0xC00100;
	*ptr1 = 'y';
	ptr1 = (char*) 0xC00FFF;
	*ptr1 = 'z';
	char ap5[100] = "ap 0xC02000";
	execute_command(ap5);

	srcFI1 = get_frame_info(ptr_page_directory, (void*)0xC00000, &ptr_table);
	dstFI1 = get_frame_info(ptr_page_directory, (void*)0xC02000, &ptr_table);

	ff1 = calculate_free_frames();

	char cmd4[100] = "tup 0xC00000 0xC02000 m";

	strsplit(cmd4, WHITESPACE, args, &numOfArgs);

	TransferUserPage(args);

	ff2 = calculate_free_frames();
	srcFI2 = get_frame_info(ptr_page_directory, (void*)0xC00000, &ptr_table);
	dstFI2 = get_frame_info(ptr_page_directory, (void*)0xC02000, &ptr_table);

	failed = 0;
	if (ff2 - ff1 != 1 || srcFI1->references > 1 || srcFI2 != NULL) {
		cprintf("[EVAL] #8 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}

	if (CB(0xC00000, 0) != 0 || CB(0xC02000, 0) != 1) {
		cprintf("[EVAL] #9 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}

	ptr1 = (char*) 0xC02000;
	ptr2 = (char*) 0xC02100;
	ptr3 = (char*) 0xC02FFF;
	if ((*ptr1) != 'x' || (*ptr2) != 'y' || (*ptr3) != 'z') {
		cprintf("[EVAL] #10 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}

	if (failed == 0)
		eval += 25 ;
	//ff1 = ff2 ;

	cprintf("\nPART IV: [MOVE] Destination page NOT exists [25% MARK]\n");

	//======================================================
	//PART IV: [MOVE] Destination page NOT exists [25% MARK]
	//======================================================
	char ap6[100] = "ap 0xD00000";
	execute_command(ap6);

	ptr1 = (char*) 0xD00000;
	*ptr1 = 'x';
	ptr1 = (char*) 0xD00100;
	*ptr1 = 'y';
	ptr1 = (char*) 0xD00FFF;
	*ptr1 = 'z';

	srcFI1 = get_frame_info(ptr_page_directory, (void*)0xD00000, &ptr_table);
	ff1 = calculate_free_frames();

	char cmd5[100] = "tup 0xD00000 0x1000000 m";
	strsplit(cmd5, WHITESPACE, args, &numOfArgs);

	TransferUserPage(args);

	ff2 = calculate_free_frames();
	srcFI2 = get_frame_info(ptr_page_directory, (void*)0xD00000, &ptr_table);

	failed = 0;
	if (ff1 - ff2 != 1 || srcFI1->references > 1 || srcFI2 != NULL) {
		cprintf("[EVAL] #11 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	if (CB(0xD00000, 0) != 0 || CB(0x1000000, 0) != 1) {
		cprintf("[EVAL] #12 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}

	ptr1 = (char*) 0x1000000;
	ptr2 = (char*) 0x1000100;
	ptr3 = (char*) 0x1000FFF;

	if ((*ptr1) != 'x' || (*ptr2) != 'y' || (*ptr3) != 'z') {
		cprintf("[EVAL] #13 TransferUserPage: Failed.\n");
		failed = 1;
		//return 0;
	}
	if (failed == 0)
		eval += 25;

	cprintf("\n[EVAL] TransferUserPage. Final Evaluation = %d\n", eval);

	return 0;

}

int CB(uint32 va, int bn)
{
	uint32 *ptr_table = NULL;
	uint32 mask = 1<<bn;
	get_page_table(ptr_page_directory, (void*)va, 0, &ptr_table);
	if (ptr_table == NULL) return -1;
	return (ptr_table[PTX(va)] & mask) == mask ? 1 : 0 ;
}

void ClearUserSpace()
{
	for (int i = 0; i < PDX(USER_TOP); ++i) {
		ptr_page_directory[i] = 0;
	}
}
