
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <start_of_kernel-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start_of_kernel
start_of_kernel:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4                   	.byte 0xe4

f010000c <start_of_kernel>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 c0 11 00 	lgdtl  0x11c018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Leave a few words on the stack for the user trap frame
	movl	$(ptr_stack_top-SIZEOF_STRUCT_TRAPFRAME),%esp
f0100033:	bc bc bf 11 f0       	mov    $0xf011bfbc,%esp

	# now to C code
	call	FOS_initialize
f0100038:	e8 02 00 00 00       	call   f010003f <FOS_initialize>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <FOS_initialize>:



//First ever function called in FOS kernel
void FOS_initialize()
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_uninitialized_data_section[], end_of_kernel[];

	// Before doing anything else,
	// clear the uninitialized global data (BSS) section of our program, from start_of_uninitialized_data_section to end_of_kernel 
	// This ensures that all static/global variables start with zero value.
	memset(start_of_uninitialized_data_section, 0, end_of_kernel - start_of_uninitialized_data_section);
f0100045:	ba ec f7 14 f0       	mov    $0xf014f7ec,%edx
f010004a:	b8 f2 ec 14 f0       	mov    $0xf014ecf2,%eax
f010004f:	29 c2                	sub    %eax,%edx
f0100051:	89 d0                	mov    %edx,%eax
f0100053:	83 ec 04             	sub    $0x4,%esp
f0100056:	50                   	push   %eax
f0100057:	6a 00                	push   $0x0
f0100059:	68 f2 ec 14 f0       	push   $0xf014ecf2
f010005e:	e8 28 4c 00 00       	call   f0104c8b <memset>
f0100063:	83 c4 10             	add    $0x10,%esp

	// Initialize the console.
	// Can't call cprintf until after we do this!
	console_initialize();
f0100066:	e8 7b 08 00 00       	call   f01008e6 <console_initialize>

	//print welcome message
	print_welcome_message();
f010006b:	e8 45 00 00 00       	call   f01000b5 <print_welcome_message>

	// Lab 2 memory management initialization functions
	detect_memory();
f0100070:	e8 a6 13 00 00       	call   f010141b <detect_memory>
	initialize_kernel_VM();
f0100075:	e8 2c 22 00 00       	call   f01022a6 <initialize_kernel_VM>
	initialize_paging();
f010007a:	e8 eb 25 00 00       	call   f010266a <initialize_paging>
	page_check();
f010007f:	e8 63 17 00 00       	call   f01017e7 <page_check>

	
	// Lab 3 user environment initialization functions
	env_init();
f0100084:	e8 d8 2d 00 00       	call   f0102e61 <env_init>
	idt_init();
f0100089:	e8 6c 35 00 00       	call   f01035fa <idt_init>

	
	// start the kernel command prompt.
	while (1==1)
	{
		cprintf("\nWelcome to the FOS kernel command prompt!\n");
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	68 80 52 10 f0       	push   $0xf0105280
f0100096:	e8 0e 35 00 00       	call   f01035a9 <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
		cprintf("Type 'help' for a list of commands.\n");	
f010009e:	83 ec 0c             	sub    $0xc,%esp
f01000a1:	68 ac 52 10 f0       	push   $0xf01052ac
f01000a6:	e8 fe 34 00 00       	call   f01035a9 <cprintf>
f01000ab:	83 c4 10             	add    $0x10,%esp
		run_command_prompt();
f01000ae:	e8 9e 08 00 00       	call   f0100951 <run_command_prompt>
	}
f01000b3:	eb d9                	jmp    f010008e <FOS_initialize+0x4f>

f01000b5 <print_welcome_message>:
}


void print_welcome_message()
{
f01000b5:	55                   	push   %ebp
f01000b6:	89 e5                	mov    %esp,%ebp
f01000b8:	83 ec 08             	sub    $0x8,%esp
	cprintf("\n\n\n");
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	68 d1 52 10 f0       	push   $0xf01052d1
f01000c3:	e8 e1 34 00 00       	call   f01035a9 <cprintf>
f01000c8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f01000cb:	83 ec 0c             	sub    $0xc,%esp
f01000ce:	68 d8 52 10 f0       	push   $0xf01052d8
f01000d3:	e8 d1 34 00 00       	call   f01035a9 <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	68 20 53 10 f0       	push   $0xf0105320
f01000e3:	e8 c1 34 00 00       	call   f01035a9 <cprintf>
f01000e8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                   !! FCIS says HELLO !!                     !!\n");
f01000eb:	83 ec 0c             	sub    $0xc,%esp
f01000ee:	68 68 53 10 f0       	push   $0xf0105368
f01000f3:	e8 b1 34 00 00       	call   f01035a9 <cprintf>
f01000f8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000fb:	83 ec 0c             	sub    $0xc,%esp
f01000fe:	68 20 53 10 f0       	push   $0xf0105320
f0100103:	e8 a1 34 00 00       	call   f01035a9 <cprintf>
f0100108:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	68 d8 52 10 f0       	push   $0xf01052d8
f0100113:	e8 91 34 00 00       	call   f01035a9 <cprintf>
f0100118:	83 c4 10             	add    $0x10,%esp
	cprintf("\n\n\n\n");	
f010011b:	83 ec 0c             	sub    $0xc,%esp
f010011e:	68 ad 53 10 f0       	push   $0xf01053ad
f0100123:	e8 81 34 00 00       	call   f01035a9 <cprintf>
f0100128:	83 c4 10             	add    $0x10,%esp
}
f010012b:	90                   	nop
f010012c:	c9                   	leave  
f010012d:	c3                   	ret    

f010012e <_panic>:
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel command prompt.
 */
void _panic(const char *file, int line, const char *fmt,...)
{
f010012e:	55                   	push   %ebp
f010012f:	89 e5                	mov    %esp,%ebp
f0100131:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f0100134:	a1 00 ed 14 f0       	mov    0xf014ed00,%eax
f0100139:	85 c0                	test   %eax,%eax
f010013b:	74 02                	je     f010013f <_panic+0x11>
		goto dead;
f010013d:	eb 49                	jmp    f0100188 <_panic+0x5a>
	panicstr = fmt;
f010013f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100142:	a3 00 ed 14 f0       	mov    %eax,0xf014ed00

	va_start(ap, fmt);
f0100147:	8d 45 10             	lea    0x10(%ebp),%eax
f010014a:	83 c0 04             	add    $0x4,%eax
f010014d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100150:	83 ec 04             	sub    $0x4,%esp
f0100153:	ff 75 0c             	pushl  0xc(%ebp)
f0100156:	ff 75 08             	pushl  0x8(%ebp)
f0100159:	68 b2 53 10 f0       	push   $0xf01053b2
f010015e:	e8 46 34 00 00       	call   f01035a9 <cprintf>
f0100163:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f0100166:	8b 45 10             	mov    0x10(%ebp),%eax
f0100169:	83 ec 08             	sub    $0x8,%esp
f010016c:	ff 75 f4             	pushl  -0xc(%ebp)
f010016f:	50                   	push   %eax
f0100170:	e8 0b 34 00 00       	call   f0103580 <vcprintf>
f0100175:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f0100178:	83 ec 0c             	sub    $0xc,%esp
f010017b:	68 ca 53 10 f0       	push   $0xf01053ca
f0100180:	e8 24 34 00 00       	call   f01035a9 <cprintf>
f0100185:	83 c4 10             	add    $0x10,%esp
	va_end(ap);

dead:
	/* break into the kernel command prompt */
	while (1==1)
		run_command_prompt();
f0100188:	e8 c4 07 00 00       	call   f0100951 <run_command_prompt>
f010018d:	eb f9                	jmp    f0100188 <_panic+0x5a>

f010018f <_warn>:
}

/* like panic, but don't enters the kernel command prompt*/
void _warn(const char *file, int line, const char *fmt,...)
{
f010018f:	55                   	push   %ebp
f0100190:	89 e5                	mov    %esp,%ebp
f0100192:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100195:	8d 45 10             	lea    0x10(%ebp),%eax
f0100198:	83 c0 04             	add    $0x4,%eax
f010019b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	ff 75 0c             	pushl  0xc(%ebp)
f01001a4:	ff 75 08             	pushl  0x8(%ebp)
f01001a7:	68 cc 53 10 f0       	push   $0xf01053cc
f01001ac:	e8 f8 33 00 00       	call   f01035a9 <cprintf>
f01001b1:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01001b7:	83 ec 08             	sub    $0x8,%esp
f01001ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01001bd:	50                   	push   %eax
f01001be:	e8 bd 33 00 00       	call   f0103580 <vcprintf>
f01001c3:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001c6:	83 ec 0c             	sub    $0xc,%esp
f01001c9:	68 ca 53 10 f0       	push   $0xf01053ca
f01001ce:	e8 d6 33 00 00       	call   f01035a9 <cprintf>
f01001d3:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f01001d6:	90                   	nop
f01001d7:	c9                   	leave  
f01001d8:	c3                   	ret    

f01001d9 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001d9:	55                   	push   %ebp
f01001da:	89 e5                	mov    %esp,%ebp
f01001dc:	83 ec 10             	sub    $0x10,%esp
f01001df:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e6:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01001e9:	89 c2                	mov    %eax,%edx
f01001eb:	ec                   	in     (%dx),%al
f01001ec:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01001ef:	8a 45 f7             	mov    -0x9(%ebp),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001f2:	0f b6 c0             	movzbl %al,%eax
f01001f5:	83 e0 01             	and    $0x1,%eax
f01001f8:	85 c0                	test   %eax,%eax
f01001fa:	75 07                	jne    f0100203 <serial_proc_data+0x2a>
		return -1;
f01001fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100201:	eb 16                	jmp    f0100219 <serial_proc_data+0x40>
f0100203:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010020a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010020d:	89 c2                	mov    %eax,%edx
f010020f:	ec                   	in     (%dx),%al
f0100210:	88 45 f6             	mov    %al,-0xa(%ebp)
	return data;
f0100213:	8a 45 f6             	mov    -0xa(%ebp),%al
	return inb(COM1+COM_RX);
f0100216:	0f b6 c0             	movzbl %al,%eax
}
f0100219:	c9                   	leave  
f010021a:	c3                   	ret    

f010021b <serial_intr>:

void
serial_intr(void)
{
f010021b:	55                   	push   %ebp
f010021c:	89 e5                	mov    %esp,%ebp
f010021e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100221:	a1 20 ed 14 f0       	mov    0xf014ed20,%eax
f0100226:	85 c0                	test   %eax,%eax
f0100228:	74 10                	je     f010023a <serial_intr+0x1f>
		cons_intr(serial_proc_data);
f010022a:	83 ec 0c             	sub    $0xc,%esp
f010022d:	68 d9 01 10 f0       	push   $0xf01001d9
f0100232:	e8 e4 05 00 00       	call   f010081b <cons_intr>
f0100237:	83 c4 10             	add    $0x10,%esp
}
f010023a:	90                   	nop
f010023b:	c9                   	leave  
f010023c:	c3                   	ret    

f010023d <serial_init>:

void
serial_init(void)
{
f010023d:	55                   	push   %ebp
f010023e:	89 e5                	mov    %esp,%ebp
f0100240:	83 ec 40             	sub    $0x40,%esp
f0100243:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f010024a:	c6 45 ce 00          	movb   $0x0,-0x32(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010024e:	8a 45 ce             	mov    -0x32(%ebp),%al
f0100251:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100254:	ee                   	out    %al,(%dx)
f0100255:	c7 45 f8 fb 03 00 00 	movl   $0x3fb,-0x8(%ebp)
f010025c:	c6 45 cf 80          	movb   $0x80,-0x31(%ebp)
f0100260:	8a 45 cf             	mov    -0x31(%ebp),%al
f0100263:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100266:	ee                   	out    %al,(%dx)
f0100267:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
f010026e:	c6 45 d0 0c          	movb   $0xc,-0x30(%ebp)
f0100272:	8a 45 d0             	mov    -0x30(%ebp),%al
f0100275:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100278:	ee                   	out    %al,(%dx)
f0100279:	c7 45 f0 f9 03 00 00 	movl   $0x3f9,-0x10(%ebp)
f0100280:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
f0100284:	8a 45 d1             	mov    -0x2f(%ebp),%al
f0100287:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010028a:	ee                   	out    %al,(%dx)
f010028b:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
f0100292:	c6 45 d2 03          	movb   $0x3,-0x2e(%ebp)
f0100296:	8a 45 d2             	mov    -0x2e(%ebp),%al
f0100299:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010029c:	ee                   	out    %al,(%dx)
f010029d:	c7 45 e8 fc 03 00 00 	movl   $0x3fc,-0x18(%ebp)
f01002a4:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f01002a8:	8a 45 d3             	mov    -0x2d(%ebp),%al
f01002ab:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01002ae:	ee                   	out    %al,(%dx)
f01002af:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01002b6:	c6 45 d4 01          	movb   $0x1,-0x2c(%ebp)
f01002ba:	8a 45 d4             	mov    -0x2c(%ebp),%al
f01002bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01002c0:	ee                   	out    %al,(%dx)
f01002c1:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01002cb:	89 c2                	mov    %eax,%edx
f01002cd:	ec                   	in     (%dx),%al
f01002ce:	88 45 d5             	mov    %al,-0x2b(%ebp)
	return data;
f01002d1:	8a 45 d5             	mov    -0x2b(%ebp),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01002d4:	3c ff                	cmp    $0xff,%al
f01002d6:	0f 95 c0             	setne  %al
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	a3 20 ed 14 f0       	mov    %eax,0xf014ed20
f01002e1:	c7 45 dc fa 03 00 00 	movl   $0x3fa,-0x24(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01002eb:	89 c2                	mov    %eax,%edx
f01002ed:	ec                   	in     (%dx),%al
f01002ee:	88 45 d6             	mov    %al,-0x2a(%ebp)
f01002f1:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
f01002f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01002fb:	89 c2                	mov    %eax,%edx
f01002fd:	ec                   	in     (%dx),%al
f01002fe:	88 45 d7             	mov    %al,-0x29(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100301:	90                   	nop
f0100302:	c9                   	leave  
f0100303:	c3                   	ret    

f0100304 <delay>:
// page.

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100304:	55                   	push   %ebp
f0100305:	89 e5                	mov    %esp,%ebp
f0100307:	83 ec 20             	sub    $0x20,%esp
f010030a:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)
f0100311:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100314:	89 c2                	mov    %eax,%edx
f0100316:	ec                   	in     (%dx),%al
f0100317:	88 45 ec             	mov    %al,-0x14(%ebp)
f010031a:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)
f0100321:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100324:	89 c2                	mov    %eax,%edx
f0100326:	ec                   	in     (%dx),%al
f0100327:	88 45 ed             	mov    %al,-0x13(%ebp)
f010032a:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f0100331:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100334:	89 c2                	mov    %eax,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	88 45 ee             	mov    %al,-0x12(%ebp)
f010033a:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
f0100341:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100344:	89 c2                	mov    %eax,%edx
f0100346:	ec                   	in     (%dx),%al
f0100347:	88 45 ef             	mov    %al,-0x11(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010034a:	90                   	nop
f010034b:	c9                   	leave  
f010034c:	c3                   	ret    

f010034d <lpt_putc>:

static void
lpt_putc(int c)
{
f010034d:	55                   	push   %ebp
f010034e:	89 e5                	mov    %esp,%ebp
f0100350:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010035a:	eb 08                	jmp    f0100364 <lpt_putc+0x17>
		delay();
f010035c:	e8 a3 ff ff ff       	call   f0100304 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100361:	ff 45 fc             	incl   -0x4(%ebp)
f0100364:	c7 45 ec 79 03 00 00 	movl   $0x379,-0x14(%ebp)
f010036b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010036e:	89 c2                	mov    %eax,%edx
f0100370:	ec                   	in     (%dx),%al
f0100371:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f0100374:	8a 45 eb             	mov    -0x15(%ebp),%al
f0100377:	84 c0                	test   %al,%al
f0100379:	78 09                	js     f0100384 <lpt_putc+0x37>
f010037b:	81 7d fc ef 0a 00 00 	cmpl   $0xaef,-0x4(%ebp)
f0100382:	7e d8                	jle    f010035c <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f0100384:	8b 45 08             	mov    0x8(%ebp),%eax
f0100387:	0f b6 c0             	movzbl %al,%eax
f010038a:	c7 45 f4 78 03 00 00 	movl   $0x378,-0xc(%ebp)
f0100391:	88 45 e8             	mov    %al,-0x18(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100394:	8a 45 e8             	mov    -0x18(%ebp),%al
f0100397:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010039a:	ee                   	out    %al,(%dx)
f010039b:	c7 45 f0 7a 03 00 00 	movl   $0x37a,-0x10(%ebp)
f01003a2:	c6 45 e9 0d          	movb   $0xd,-0x17(%ebp)
f01003a6:	8a 45 e9             	mov    -0x17(%ebp),%al
f01003a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003ac:	ee                   	out    %al,(%dx)
f01003ad:	c7 45 f8 7a 03 00 00 	movl   $0x37a,-0x8(%ebp)
f01003b4:	c6 45 ea 08          	movb   $0x8,-0x16(%ebp)
f01003b8:	8a 45 ea             	mov    -0x16(%ebp),%al
f01003bb:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01003be:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003bf:	90                   	nop
f01003c0:	c9                   	leave  
f01003c1:	c3                   	ret    

f01003c2 <cga_init>:
static uint16 *crt_buf;
static uint16 crt_pos;

void
cga_init(void)
{
f01003c2:	55                   	push   %ebp
f01003c3:	89 e5                	mov    %esp,%ebp
f01003c5:	83 ec 20             	sub    $0x20,%esp
	volatile uint16 *cp;
	uint16 was;
	unsigned pos;

	cp = (uint16*) (KERNEL_BASE + CGA_BUF);
f01003c8:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f01003cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003d2:	66 8b 00             	mov    (%eax),%ax
f01003d5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16) 0xA55A;
f01003d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003dc:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01003e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003e4:	66 8b 00             	mov    (%eax),%ax
f01003e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01003eb:	74 13                	je     f0100400 <cga_init+0x3e>
		cp = (uint16*) (KERNEL_BASE + MONO_BUF);
f01003ed:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f01003f4:	c7 05 24 ed 14 f0 b4 	movl   $0x3b4,0xf014ed24
f01003fb:	03 00 00 
f01003fe:	eb 14                	jmp    f0100414 <cga_init+0x52>
	} else {
		*cp = was;
f0100400:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100403:	66 8b 45 fa          	mov    -0x6(%ebp),%ax
f0100407:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
f010040a:	c7 05 24 ed 14 f0 d4 	movl   $0x3d4,0xf014ed24
f0100411:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100414:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f0100419:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010041c:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
f0100420:	8a 45 e0             	mov    -0x20(%ebp),%al
f0100423:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100426:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100427:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f010042c:	40                   	inc    %eax
f010042d:	89 45 ec             	mov    %eax,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100430:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100433:	89 c2                	mov    %eax,%edx
f0100435:	ec                   	in     (%dx),%al
f0100436:	88 45 e1             	mov    %al,-0x1f(%ebp)
	return data;
f0100439:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010043c:	0f b6 c0             	movzbl %al,%eax
f010043f:	c1 e0 08             	shl    $0x8,%eax
f0100442:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f0100445:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f010044a:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010044d:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100451:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100454:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100457:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f0100458:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f010045d:	40                   	inc    %eax
f010045e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100461:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100464:	89 c2                	mov    %eax,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010046a:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010046d:	0f b6 c0             	movzbl %al,%eax
f0100470:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16*) cp;
f0100473:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100476:	a3 28 ed 14 f0       	mov    %eax,0xf014ed28
	crt_pos = pos;
f010047b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010047e:	66 a3 2c ed 14 f0    	mov    %ax,0xf014ed2c
}
f0100484:	90                   	nop
f0100485:	c9                   	leave  
f0100486:	c3                   	ret    

f0100487 <cga_putc>:



void
cga_putc(int c)
{
f0100487:	55                   	push   %ebp
f0100488:	89 e5                	mov    %esp,%ebp
f010048a:	53                   	push   %ebx
f010048b:	83 ec 24             	sub    $0x24,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010048e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100491:	b0 00                	mov    $0x0,%al
f0100493:	85 c0                	test   %eax,%eax
f0100495:	75 07                	jne    f010049e <cga_putc+0x17>
		c |= 0x0700;
f0100497:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f010049e:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a1:	0f b6 c0             	movzbl %al,%eax
f01004a4:	83 f8 09             	cmp    $0x9,%eax
f01004a7:	0f 84 94 00 00 00    	je     f0100541 <cga_putc+0xba>
f01004ad:	83 f8 09             	cmp    $0x9,%eax
f01004b0:	7f 0a                	jg     f01004bc <cga_putc+0x35>
f01004b2:	83 f8 08             	cmp    $0x8,%eax
f01004b5:	74 14                	je     f01004cb <cga_putc+0x44>
f01004b7:	e9 c8 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
f01004bc:	83 f8 0a             	cmp    $0xa,%eax
f01004bf:	74 49                	je     f010050a <cga_putc+0x83>
f01004c1:	83 f8 0d             	cmp    $0xd,%eax
f01004c4:	74 53                	je     f0100519 <cga_putc+0x92>
f01004c6:	e9 b9 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
	case '\b':
		if (crt_pos > 0) {
f01004cb:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f01004d1:	66 85 c0             	test   %ax,%ax
f01004d4:	0f 84 d0 00 00 00    	je     f01005aa <cga_putc+0x123>
			crt_pos--;
f01004da:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f01004e0:	48                   	dec    %eax
f01004e1:	66 a3 2c ed 14 f0    	mov    %ax,0xf014ed2c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e7:	8b 15 28 ed 14 f0    	mov    0xf014ed28,%edx
f01004ed:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f01004f3:	0f b7 c0             	movzwl %ax,%eax
f01004f6:	01 c0                	add    %eax,%eax
f01004f8:	01 c2                	add    %eax,%edx
f01004fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01004fd:	b0 00                	mov    $0x0,%al
f01004ff:	83 c8 20             	or     $0x20,%eax
f0100502:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f0100505:	e9 a0 00 00 00       	jmp    f01005aa <cga_putc+0x123>
	case '\n':
		crt_pos += CRT_COLS;
f010050a:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f0100510:	83 c0 50             	add    $0x50,%eax
f0100513:	66 a3 2c ed 14 f0    	mov    %ax,0xf014ed2c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100519:	66 8b 0d 2c ed 14 f0 	mov    0xf014ed2c,%cx
f0100520:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f0100526:	bb 50 00 00 00       	mov    $0x50,%ebx
f010052b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100530:	66 f7 f3             	div    %bx
f0100533:	89 d0                	mov    %edx,%eax
f0100535:	29 c1                	sub    %eax,%ecx
f0100537:	89 c8                	mov    %ecx,%eax
f0100539:	66 a3 2c ed 14 f0    	mov    %ax,0xf014ed2c
		break;
f010053f:	eb 6a                	jmp    f01005ab <cga_putc+0x124>
	case '\t':
		cons_putc(' ');
f0100541:	83 ec 0c             	sub    $0xc,%esp
f0100544:	6a 20                	push   $0x20
f0100546:	e8 79 03 00 00       	call   f01008c4 <cons_putc>
f010054b:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010054e:	83 ec 0c             	sub    $0xc,%esp
f0100551:	6a 20                	push   $0x20
f0100553:	e8 6c 03 00 00       	call   f01008c4 <cons_putc>
f0100558:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010055b:	83 ec 0c             	sub    $0xc,%esp
f010055e:	6a 20                	push   $0x20
f0100560:	e8 5f 03 00 00       	call   f01008c4 <cons_putc>
f0100565:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100568:	83 ec 0c             	sub    $0xc,%esp
f010056b:	6a 20                	push   $0x20
f010056d:	e8 52 03 00 00       	call   f01008c4 <cons_putc>
f0100572:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100575:	83 ec 0c             	sub    $0xc,%esp
f0100578:	6a 20                	push   $0x20
f010057a:	e8 45 03 00 00       	call   f01008c4 <cons_putc>
f010057f:	83 c4 10             	add    $0x10,%esp
		break;
f0100582:	eb 27                	jmp    f01005ab <cga_putc+0x124>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100584:	8b 0d 28 ed 14 f0    	mov    0xf014ed28,%ecx
f010058a:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f0100590:	8d 50 01             	lea    0x1(%eax),%edx
f0100593:	66 89 15 2c ed 14 f0 	mov    %dx,0xf014ed2c
f010059a:	0f b7 c0             	movzwl %ax,%eax
f010059d:	01 c0                	add    %eax,%eax
f010059f:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01005a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01005a5:	66 89 02             	mov    %ax,(%edx)
		break;
f01005a8:	eb 01                	jmp    f01005ab <cga_putc+0x124>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
f01005aa:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ab:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f01005b1:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005b5:	76 58                	jbe    f010060f <cga_putc+0x188>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
f01005b7:	a1 28 ed 14 f0       	mov    0xf014ed28,%eax
f01005bc:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c2:	a1 28 ed 14 f0       	mov    0xf014ed28,%eax
f01005c7:	83 ec 04             	sub    $0x4,%esp
f01005ca:	68 00 0f 00 00       	push   $0xf00
f01005cf:	52                   	push   %edx
f01005d0:	50                   	push   %eax
f01005d1:	e8 e5 46 00 00       	call   f0104cbb <memcpy>
f01005d6:	83 c4 10             	add    $0x10,%esp
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005d9:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f01005e0:	eb 15                	jmp    f01005f7 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
f01005e2:	8b 15 28 ed 14 f0    	mov    0xf014ed28,%edx
f01005e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01005eb:	01 c0                	add    %eax,%eax
f01005ed:	01 d0                	add    %edx,%eax
f01005ef:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f4:	ff 45 f4             	incl   -0xc(%ebp)
f01005f7:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f01005fe:	7e e2                	jle    f01005e2 <cga_putc+0x15b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100600:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f0100606:	83 e8 50             	sub    $0x50,%eax
f0100609:	66 a3 2c ed 14 f0    	mov    %ax,0xf014ed2c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010060f:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f0100614:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100617:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061b:	8a 45 e0             	mov    -0x20(%ebp),%al
f010061e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100621:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100622:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f0100628:	66 c1 e8 08          	shr    $0x8,%ax
f010062c:	0f b6 c0             	movzbl %al,%eax
f010062f:	8b 15 24 ed 14 f0    	mov    0xf014ed24,%edx
f0100635:	42                   	inc    %edx
f0100636:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0100639:	88 45 e1             	mov    %al,-0x1f(%ebp)
f010063c:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010063f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100642:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f0100643:	a1 24 ed 14 f0       	mov    0xf014ed24,%eax
f0100648:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010064b:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
f010064f:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100652:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100655:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100656:	66 a1 2c ed 14 f0    	mov    0xf014ed2c,%ax
f010065c:	0f b6 c0             	movzbl %al,%eax
f010065f:	8b 15 24 ed 14 f0    	mov    0xf014ed24,%edx
f0100665:	42                   	inc    %edx
f0100666:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100669:	88 45 e3             	mov    %al,-0x1d(%ebp)
f010066c:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010066f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100672:	ee                   	out    %al,(%dx)
}
f0100673:	90                   	nop
f0100674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100677:	c9                   	leave  
f0100678:	c3                   	ret    

f0100679 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100679:	55                   	push   %ebp
f010067a:	89 e5                	mov    %esp,%ebp
f010067c:	83 ec 28             	sub    $0x28,%esp
f010067f:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	ec                   	in     (%dx),%al
f010068c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010068f:	8a 45 e3             	mov    -0x1d(%ebp),%al
	int c;
	uint8 data;
	static uint32 shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100692:	0f b6 c0             	movzbl %al,%eax
f0100695:	83 e0 01             	and    $0x1,%eax
f0100698:	85 c0                	test   %eax,%eax
f010069a:	75 0a                	jne    f01006a6 <kbd_proc_data+0x2d>
		return -1;
f010069c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01006a1:	e9 54 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
f01006a6:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01006b0:	89 c2                	mov    %eax,%edx
f01006b2:	ec                   	in     (%dx),%al
f01006b3:	88 45 e2             	mov    %al,-0x1e(%ebp)
	return data;
f01006b6:	8a 45 e2             	mov    -0x1e(%ebp),%al

	data = inb(KBDATAP);
f01006b9:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f01006bc:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f01006c0:	75 17                	jne    f01006d9 <kbd_proc_data+0x60>
		// E0 escape character
		shift |= E0ESC;
f01006c2:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f01006c7:	83 c8 40             	or     $0x40,%eax
f01006ca:	a3 48 ef 14 f0       	mov    %eax,0xf014ef48
		return 0;
f01006cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d4:	e9 21 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (data & 0x80) {
f01006d9:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006dc:	84 c0                	test   %al,%al
f01006de:	79 44                	jns    f0100724 <kbd_proc_data+0xab>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006e0:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f01006e5:	83 e0 40             	and    $0x40,%eax
f01006e8:	85 c0                	test   %eax,%eax
f01006ea:	75 08                	jne    f01006f4 <kbd_proc_data+0x7b>
f01006ec:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006ef:	83 e0 7f             	and    $0x7f,%eax
f01006f2:	eb 03                	jmp    f01006f7 <kbd_proc_data+0x7e>
f01006f4:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006f7:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f01006fa:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01006fe:	8a 80 20 c0 11 f0    	mov    -0xfee3fe0(%eax),%al
f0100704:	83 c8 40             	or     $0x40,%eax
f0100707:	0f b6 c0             	movzbl %al,%eax
f010070a:	f7 d0                	not    %eax
f010070c:	89 c2                	mov    %eax,%edx
f010070e:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100713:	21 d0                	and    %edx,%eax
f0100715:	a3 48 ef 14 f0       	mov    %eax,0xf014ef48
		return 0;
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
f010071f:	e9 d6 00 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (shift & E0ESC) {
f0100724:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100729:	83 e0 40             	and    $0x40,%eax
f010072c:	85 c0                	test   %eax,%eax
f010072e:	74 11                	je     f0100741 <kbd_proc_data+0xc8>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100730:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f0100734:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100739:	83 e0 bf             	and    $0xffffffbf,%eax
f010073c:	a3 48 ef 14 f0       	mov    %eax,0xf014ef48
	}

	shift |= shiftcode[data];
f0100741:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100745:	8a 80 20 c0 11 f0    	mov    -0xfee3fe0(%eax),%al
f010074b:	0f b6 d0             	movzbl %al,%edx
f010074e:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100753:	09 d0                	or     %edx,%eax
f0100755:	a3 48 ef 14 f0       	mov    %eax,0xf014ef48
	shift ^= togglecode[data];
f010075a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010075e:	8a 80 20 c1 11 f0    	mov    -0xfee3ee0(%eax),%al
f0100764:	0f b6 d0             	movzbl %al,%edx
f0100767:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f010076c:	31 d0                	xor    %edx,%eax
f010076e:	a3 48 ef 14 f0       	mov    %eax,0xf014ef48

	c = charcode[shift & (CTL | SHIFT)][data];
f0100773:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100778:	83 e0 03             	and    $0x3,%eax
f010077b:	8b 14 85 20 c5 11 f0 	mov    -0xfee3ae0(,%eax,4),%edx
f0100782:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100786:	01 d0                	add    %edx,%eax
f0100788:	8a 00                	mov    (%eax),%al
f010078a:	0f b6 c0             	movzbl %al,%eax
f010078d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f0100790:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f0100795:	83 e0 08             	and    $0x8,%eax
f0100798:	85 c0                	test   %eax,%eax
f010079a:	74 22                	je     f01007be <kbd_proc_data+0x145>
		if ('a' <= c && c <= 'z')
f010079c:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f01007a0:	7e 0c                	jle    f01007ae <kbd_proc_data+0x135>
f01007a2:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f01007a6:	7f 06                	jg     f01007ae <kbd_proc_data+0x135>
			c += 'A' - 'a';
f01007a8:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f01007ac:	eb 10                	jmp    f01007be <kbd_proc_data+0x145>
		else if ('A' <= c && c <= 'Z')
f01007ae:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f01007b2:	7e 0a                	jle    f01007be <kbd_proc_data+0x145>
f01007b4:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f01007b8:	7f 04                	jg     f01007be <kbd_proc_data+0x145>
			c += 'a' - 'A';
f01007ba:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01007be:	a1 48 ef 14 f0       	mov    0xf014ef48,%eax
f01007c3:	f7 d0                	not    %eax
f01007c5:	83 e0 06             	and    $0x6,%eax
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	75 2b                	jne    f01007f7 <kbd_proc_data+0x17e>
f01007cc:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f01007d3:	75 22                	jne    f01007f7 <kbd_proc_data+0x17e>
		cprintf("Rebooting!\n");
f01007d5:	83 ec 0c             	sub    $0xc,%esp
f01007d8:	68 e6 53 10 f0       	push   $0xf01053e6
f01007dd:	e8 c7 2d 00 00       	call   f01035a9 <cprintf>
f01007e2:	83 c4 10             	add    $0x10,%esp
f01007e5:	c7 45 e8 92 00 00 00 	movl   $0x92,-0x18(%ebp)
f01007ec:	c6 45 e1 03          	movb   $0x3,-0x1f(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01007f0:	8a 45 e1             	mov    -0x1f(%ebp),%al
f01007f3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01007f6:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01007f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01007fa:	c9                   	leave  
f01007fb:	c3                   	ret    

f01007fc <kbd_intr>:

void
kbd_intr(void)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100802:	83 ec 0c             	sub    $0xc,%esp
f0100805:	68 79 06 10 f0       	push   $0xf0100679
f010080a:	e8 0c 00 00 00       	call   f010081b <cons_intr>
f010080f:	83 c4 10             	add    $0x10,%esp
}
f0100812:	90                   	nop
f0100813:	c9                   	leave  
f0100814:	c3                   	ret    

f0100815 <kbd_init>:

void
kbd_init(void)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
}
f0100818:	90                   	nop
f0100819:	5d                   	pop    %ebp
f010081a:	c3                   	ret    

f010081b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f0100821:	eb 35                	jmp    f0100858 <cons_intr+0x3d>
		if (c == 0)
f0100823:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100827:	75 02                	jne    f010082b <cons_intr+0x10>
			continue;
f0100829:	eb 2d                	jmp    f0100858 <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f010082b:	a1 44 ef 14 f0       	mov    0xf014ef44,%eax
f0100830:	8d 50 01             	lea    0x1(%eax),%edx
f0100833:	89 15 44 ef 14 f0    	mov    %edx,0xf014ef44
f0100839:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010083c:	88 90 40 ed 14 f0    	mov    %dl,-0xfeb12c0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100842:	a1 44 ef 14 f0       	mov    0xf014ef44,%eax
f0100847:	3d 00 02 00 00       	cmp    $0x200,%eax
f010084c:	75 0a                	jne    f0100858 <cons_intr+0x3d>
			cons.wpos = 0;
f010084e:	c7 05 44 ef 14 f0 00 	movl   $0x0,0xf014ef44
f0100855:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100858:	8b 45 08             	mov    0x8(%ebp),%eax
f010085b:	ff d0                	call   *%eax
f010085d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100860:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f0100864:	75 bd                	jne    f0100823 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100866:	90                   	nop
f0100867:	c9                   	leave  
f0100868:	c3                   	ret    

f0100869 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100869:	55                   	push   %ebp
f010086a:	89 e5                	mov    %esp,%ebp
f010086c:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010086f:	e8 a7 f9 ff ff       	call   f010021b <serial_intr>
	kbd_intr();
f0100874:	e8 83 ff ff ff       	call   f01007fc <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100879:	8b 15 40 ef 14 f0    	mov    0xf014ef40,%edx
f010087f:	a1 44 ef 14 f0       	mov    0xf014ef44,%eax
f0100884:	39 c2                	cmp    %eax,%edx
f0100886:	74 35                	je     f01008bd <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
f0100888:	a1 40 ef 14 f0       	mov    0xf014ef40,%eax
f010088d:	8d 50 01             	lea    0x1(%eax),%edx
f0100890:	89 15 40 ef 14 f0    	mov    %edx,0xf014ef40
f0100896:	8a 80 40 ed 14 f0    	mov    -0xfeb12c0(%eax),%al
f010089c:	0f b6 c0             	movzbl %al,%eax
f010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008a2:	a1 40 ef 14 f0       	mov    0xf014ef40,%eax
f01008a7:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008ac:	75 0a                	jne    f01008b8 <cons_getc+0x4f>
			cons.rpos = 0;
f01008ae:	c7 05 40 ef 14 f0 00 	movl   $0x0,0xf014ef40
f01008b5:	00 00 00 
		return c;
f01008b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008bb:	eb 05                	jmp    f01008c2 <cons_getc+0x59>
	}
	return 0;
f01008bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01008c2:	c9                   	leave  
f01008c3:	c3                   	ret    

f01008c4 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f01008c4:	55                   	push   %ebp
f01008c5:	89 e5                	mov    %esp,%ebp
f01008c7:	83 ec 08             	sub    $0x8,%esp
	lpt_putc(c);
f01008ca:	ff 75 08             	pushl  0x8(%ebp)
f01008cd:	e8 7b fa ff ff       	call   f010034d <lpt_putc>
f01008d2:	83 c4 04             	add    $0x4,%esp
	cga_putc(c);
f01008d5:	83 ec 0c             	sub    $0xc,%esp
f01008d8:	ff 75 08             	pushl  0x8(%ebp)
f01008db:	e8 a7 fb ff ff       	call   f0100487 <cga_putc>
f01008e0:	83 c4 10             	add    $0x10,%esp
}
f01008e3:	90                   	nop
f01008e4:	c9                   	leave  
f01008e5:	c3                   	ret    

f01008e6 <console_initialize>:

// initialize the console devices
void
console_initialize(void)
{
f01008e6:	55                   	push   %ebp
f01008e7:	89 e5                	mov    %esp,%ebp
f01008e9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01008ec:	e8 d1 fa ff ff       	call   f01003c2 <cga_init>
	kbd_init();
f01008f1:	e8 1f ff ff ff       	call   f0100815 <kbd_init>
	serial_init();
f01008f6:	e8 42 f9 ff ff       	call   f010023d <serial_init>

	if (!serial_exists)
f01008fb:	a1 20 ed 14 f0       	mov    0xf014ed20,%eax
f0100900:	85 c0                	test   %eax,%eax
f0100902:	75 10                	jne    f0100914 <console_initialize+0x2e>
		cprintf("Serial port does not exist!\n");
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	68 f2 53 10 f0       	push   $0xf01053f2
f010090c:	e8 98 2c 00 00       	call   f01035a9 <cprintf>
f0100911:	83 c4 10             	add    $0x10,%esp
}
f0100914:	90                   	nop
f0100915:	c9                   	leave  
f0100916:	c3                   	ret    

f0100917 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010091d:	83 ec 0c             	sub    $0xc,%esp
f0100920:	ff 75 08             	pushl  0x8(%ebp)
f0100923:	e8 9c ff ff ff       	call   f01008c4 <cons_putc>
f0100928:	83 c4 10             	add    $0x10,%esp
}
f010092b:	90                   	nop
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <getchar>:

int
getchar(void)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100934:	e8 30 ff ff ff       	call   f0100869 <cons_getc>
f0100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010093c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100940:	74 f2                	je     f0100934 <getchar+0x6>
		/* do nothing */;
	return c;
f0100942:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100945:	c9                   	leave  
f0100946:	c3                   	ret    

f0100947 <iscons>:

int
iscons(int fdnum)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f010094a:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <run_command_prompt>:
#define NUM_OF_COMMANDS (sizeof(commands)/sizeof(commands[0]))


//invoke the command prompt
void run_command_prompt()
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	81 ec 08 04 00 00    	sub    $0x408,%esp
	char command_line[1024];

	while (1==1)
	{
		//get command line
		readline("FOS> ", command_line);
f010095a:	83 ec 08             	sub    $0x8,%esp
f010095d:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f0100963:	50                   	push   %eax
f0100964:	68 10 59 10 f0       	push   $0xf0105910
f0100969:	e8 31 40 00 00       	call   f010499f <readline>
f010096e:	83 c4 10             	add    $0x10,%esp

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
f0100971:	83 ec 0c             	sub    $0xc,%esp
f0100974:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f010097a:	50                   	push   %eax
f010097b:	e8 0d 00 00 00       	call   f010098d <execute_command>
f0100980:	83 c4 10             	add    $0x10,%esp
f0100983:	85 c0                	test   %eax,%eax
f0100985:	78 02                	js     f0100989 <run_command_prompt+0x38>
				break;
	}
f0100987:	eb d1                	jmp    f010095a <run_command_prompt+0x9>
		readline("FOS> ", command_line);

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
				break;
f0100989:	90                   	nop
	}
}
f010098a:	90                   	nop
f010098b:	c9                   	leave  
f010098c:	c3                   	ret    

f010098d <execute_command>:
#define WHITESPACE "\t\r\n "

//Function to parse any command and execute it
//(simply by calling its corresponding function)
int execute_command(char *command_string)
{
f010098d:	55                   	push   %ebp
f010098e:	89 e5                	mov    %esp,%ebp
f0100990:	83 ec 58             	sub    $0x58,%esp
	int number_of_arguments;
	//allocate array of char * of size MAX_ARGUMENTS = 16 found in string.h
	char *arguments[MAX_ARGUMENTS];


	strsplit(command_string, WHITESPACE, arguments, &number_of_arguments) ;
f0100993:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0100996:	50                   	push   %eax
f0100997:	8d 45 a8             	lea    -0x58(%ebp),%eax
f010099a:	50                   	push   %eax
f010099b:	68 16 59 10 f0       	push   $0xf0105916
f01009a0:	ff 75 08             	pushl  0x8(%ebp)
f01009a3:	e8 9b 45 00 00       	call   f0104f43 <strsplit>
f01009a8:	83 c4 10             	add    $0x10,%esp
	if (number_of_arguments == 0)
f01009ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009ae:	85 c0                	test   %eax,%eax
f01009b0:	75 0a                	jne    f01009bc <execute_command+0x2f>
		return 0;
f01009b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01009b7:	e9 95 00 00 00       	jmp    f0100a51 <execute_command+0xc4>

	// Lookup in the commands array and execute the command
	int command_found = 0;
f01009bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009c3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01009ca:	eb 33                	jmp    f01009ff <execute_command+0x72>
	{
		if (strcmp(arguments[0], commands[i].name) == 0)
f01009cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009cf:	89 d0                	mov    %edx,%eax
f01009d1:	01 c0                	add    %eax,%eax
f01009d3:	01 d0                	add    %edx,%eax
f01009d5:	c1 e0 02             	shl    $0x2,%eax
f01009d8:	05 40 c5 11 f0       	add    $0xf011c540,%eax
f01009dd:	8b 10                	mov    (%eax),%edx
f01009df:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009e2:	83 ec 08             	sub    $0x8,%esp
f01009e5:	52                   	push   %edx
f01009e6:	50                   	push   %eax
f01009e7:	e8 bd 41 00 00       	call   f0104ba9 <strcmp>
f01009ec:	83 c4 10             	add    $0x10,%esp
f01009ef:	85 c0                	test   %eax,%eax
f01009f1:	75 09                	jne    f01009fc <execute_command+0x6f>
		{
			command_found = 1;
f01009f3:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
			break;
f01009fa:	eb 0b                	jmp    f0100a07 <execute_command+0x7a>
		return 0;

	// Lookup in the commands array and execute the command
	int command_found = 0;
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009fc:	ff 45 f0             	incl   -0x10(%ebp)
f01009ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a02:	83 f8 17             	cmp    $0x17,%eax
f0100a05:	76 c5                	jbe    f01009cc <execute_command+0x3f>
			command_found = 1;
			break;
		}
	}

	if(command_found)
f0100a07:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100a0b:	74 2b                	je     f0100a38 <execute_command+0xab>
	{
		int return_value;
		return_value = commands[i].function_to_execute(number_of_arguments, arguments);
f0100a0d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a10:	89 d0                	mov    %edx,%eax
f0100a12:	01 c0                	add    %eax,%eax
f0100a14:	01 d0                	add    %edx,%eax
f0100a16:	c1 e0 02             	shl    $0x2,%eax
f0100a19:	05 48 c5 11 f0       	add    $0xf011c548,%eax
f0100a1e:	8b 00                	mov    (%eax),%eax
f0100a20:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a23:	83 ec 08             	sub    $0x8,%esp
f0100a26:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a29:	51                   	push   %ecx
f0100a2a:	52                   	push   %edx
f0100a2b:	ff d0                	call   *%eax
f0100a2d:	83 c4 10             	add    $0x10,%esp
f0100a30:	89 45 ec             	mov    %eax,-0x14(%ebp)
		return return_value;
f0100a33:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a36:	eb 19                	jmp    f0100a51 <execute_command+0xc4>
	}
	else
	{
		//if not found, then it's unknown command
		cprintf("Unknown command '%s'\n", arguments[0]);
f0100a38:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a3b:	83 ec 08             	sub    $0x8,%esp
f0100a3e:	50                   	push   %eax
f0100a3f:	68 1b 59 10 f0       	push   $0xf010591b
f0100a44:	e8 60 2b 00 00       	call   f01035a9 <cprintf>
f0100a49:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100a4c:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0100a51:	c9                   	leave  
f0100a52:	c3                   	ret    

f0100a53 <command_help>:

/***** Implementations of basic kernel command prompt commands *****/

//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
f0100a53:	55                   	push   %ebp
f0100a54:	89 e5                	mov    %esp,%ebp
f0100a56:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a59:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100a60:	eb 3b                	jmp    f0100a9d <command_help+0x4a>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);
f0100a62:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a65:	89 d0                	mov    %edx,%eax
f0100a67:	01 c0                	add    %eax,%eax
f0100a69:	01 d0                	add    %edx,%eax
f0100a6b:	c1 e0 02             	shl    $0x2,%eax
f0100a6e:	05 44 c5 11 f0       	add    $0xf011c544,%eax
f0100a73:	8b 10                	mov    (%eax),%edx
f0100a75:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100a78:	89 c8                	mov    %ecx,%eax
f0100a7a:	01 c0                	add    %eax,%eax
f0100a7c:	01 c8                	add    %ecx,%eax
f0100a7e:	c1 e0 02             	shl    $0x2,%eax
f0100a81:	05 40 c5 11 f0       	add    $0xf011c540,%eax
f0100a86:	8b 00                	mov    (%eax),%eax
f0100a88:	83 ec 04             	sub    $0x4,%esp
f0100a8b:	52                   	push   %edx
f0100a8c:	50                   	push   %eax
f0100a8d:	68 31 59 10 f0       	push   $0xf0105931
f0100a92:	e8 12 2b 00 00       	call   f01035a9 <cprintf>
f0100a97:	83 c4 10             	add    $0x10,%esp

//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a9a:	ff 45 f4             	incl   -0xc(%ebp)
f0100a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aa0:	83 f8 17             	cmp    $0x17,%eax
f0100aa3:	76 bd                	jbe    f0100a62 <command_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);

	cprintf("-------------------\n");
f0100aa5:	83 ec 0c             	sub    $0xc,%esp
f0100aa8:	68 3a 59 10 f0       	push   $0xf010593a
f0100aad:	e8 f7 2a 00 00       	call   f01035a9 <cprintf>
f0100ab2:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100ab5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100aba:	c9                   	leave  
f0100abb:	c3                   	ret    

f0100abc <command_kernel_info>:

//print information about kernel addresses and kernel size
int command_kernel_info(int number_of_arguments, char **arguments )
{
f0100abc:	55                   	push   %ebp
f0100abd:	89 e5                	mov    %esp,%ebp
f0100abf:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_kernel[], end_of_kernel_code_section[], start_of_uninitialized_data_section[], end_of_kernel[];

	cprintf("Special kernel symbols:\n");
f0100ac2:	83 ec 0c             	sub    $0xc,%esp
f0100ac5:	68 4f 59 10 f0       	push   $0xf010594f
f0100aca:	e8 da 2a 00 00       	call   f01035a9 <cprintf>
f0100acf:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
f0100ad2:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100ad7:	83 ec 04             	sub    $0x4,%esp
f0100ada:	50                   	push   %eax
f0100adb:	68 0c 00 10 f0       	push   $0xf010000c
f0100ae0:	68 68 59 10 f0       	push   $0xf0105968
f0100ae5:	e8 bf 2a 00 00       	call   f01035a9 <cprintf>
f0100aea:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
f0100aed:	b8 79 52 10 00       	mov    $0x105279,%eax
f0100af2:	83 ec 04             	sub    $0x4,%esp
f0100af5:	50                   	push   %eax
f0100af6:	68 79 52 10 f0       	push   $0xf0105279
f0100afb:	68 a4 59 10 f0       	push   $0xf01059a4
f0100b00:	e8 a4 2a 00 00       	call   f01035a9 <cprintf>
f0100b05:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
f0100b08:	b8 f2 ec 14 00       	mov    $0x14ecf2,%eax
f0100b0d:	83 ec 04             	sub    $0x4,%esp
f0100b10:	50                   	push   %eax
f0100b11:	68 f2 ec 14 f0       	push   $0xf014ecf2
f0100b16:	68 e0 59 10 f0       	push   $0xf01059e0
f0100b1b:	e8 89 2a 00 00       	call   f01035a9 <cprintf>
f0100b20:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
f0100b23:	b8 ec f7 14 00       	mov    $0x14f7ec,%eax
f0100b28:	83 ec 04             	sub    $0x4,%esp
f0100b2b:	50                   	push   %eax
f0100b2c:	68 ec f7 14 f0       	push   $0xf014f7ec
f0100b31:	68 28 5a 10 f0       	push   $0xf0105a28
f0100b36:	e8 6e 2a 00 00       	call   f01035a9 <cprintf>
f0100b3b:	83 c4 10             	add    $0x10,%esp
	cprintf("Kernel executable memory footprint: %d KB\n",
			(end_of_kernel-start_of_kernel+1023)/1024);
f0100b3e:	b8 ec f7 14 f0       	mov    $0xf014f7ec,%eax
f0100b43:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100b49:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100b4e:	29 c2                	sub    %eax,%edx
f0100b50:	89 d0                	mov    %edx,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
	cprintf("Kernel executable memory footprint: %d KB\n",
f0100b52:	85 c0                	test   %eax,%eax
f0100b54:	79 05                	jns    f0100b5b <command_kernel_info+0x9f>
f0100b56:	05 ff 03 00 00       	add    $0x3ff,%eax
f0100b5b:	c1 f8 0a             	sar    $0xa,%eax
f0100b5e:	83 ec 08             	sub    $0x8,%esp
f0100b61:	50                   	push   %eax
f0100b62:	68 64 5a 10 f0       	push   $0xf0105a64
f0100b67:	e8 3d 2a 00 00       	call   f01035a9 <cprintf>
f0100b6c:	83 c4 10             	add    $0x10,%esp
			(end_of_kernel-start_of_kernel+1023)/1024);
	return 0;
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b74:	c9                   	leave  
f0100b75:	c3                   	ret    

f0100b76 <command_readmem>:


int command_readmem(int number_of_arguments, char **arguments)
{
f0100b76:	55                   	push   %ebp
f0100b77:	89 e5                	mov    %esp,%ebp
f0100b79:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100b7c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b7f:	83 c0 04             	add    $0x4,%eax
f0100b82:	8b 00                	mov    (%eax),%eax
f0100b84:	83 ec 04             	sub    $0x4,%esp
f0100b87:	6a 10                	push   $0x10
f0100b89:	6a 00                	push   $0x0
f0100b8b:	50                   	push   %eax
f0100b8c:	e8 6c 42 00 00       	call   f0104dfd <strtol>
f0100b91:	83 c4 10             	add    $0x10,%esp
f0100b94:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address ) ;
f0100b97:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b9a:	89 45 f0             	mov    %eax,-0x10(%ebp)

	cprintf("value at address %x = %c\n", ptr, *ptr);
f0100b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ba0:	8a 00                	mov    (%eax),%al
f0100ba2:	0f b6 c0             	movzbl %al,%eax
f0100ba5:	83 ec 04             	sub    $0x4,%esp
f0100ba8:	50                   	push   %eax
f0100ba9:	ff 75 f0             	pushl  -0x10(%ebp)
f0100bac:	68 8f 5a 10 f0       	push   $0xf0105a8f
f0100bb1:	e8 f3 29 00 00       	call   f01035a9 <cprintf>
f0100bb6:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100bb9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bbe:	c9                   	leave  
f0100bbf:	c3                   	ret    

f0100bc0 <command_writemem>:

int command_writemem(int number_of_arguments, char **arguments)
{
f0100bc0:	55                   	push   %ebp
f0100bc1:	89 e5                	mov    %esp,%ebp
f0100bc3:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bc9:	83 c0 04             	add    $0x4,%eax
f0100bcc:	8b 00                	mov    (%eax),%eax
f0100bce:	83 ec 04             	sub    $0x4,%esp
f0100bd1:	6a 10                	push   $0x10
f0100bd3:	6a 00                	push   $0x0
f0100bd5:	50                   	push   %eax
f0100bd6:	e8 22 42 00 00       	call   f0104dfd <strtol>
f0100bdb:	83 c4 10             	add    $0x10,%esp
f0100bde:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address) ;
f0100be1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100be4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	*ptr = arguments[2][0];
f0100be7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bea:	83 c0 08             	add    $0x8,%eax
f0100bed:	8b 00                	mov    (%eax),%eax
f0100bef:	8a 00                	mov    (%eax),%al
f0100bf1:	88 c2                	mov    %al,%dl
f0100bf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bf6:	88 10                	mov    %dl,(%eax)

	return 0;
f0100bf8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bfd:	c9                   	leave  
f0100bfe:	c3                   	ret    

f0100bff <command_meminfo>:

int command_meminfo(int number_of_arguments, char **arguments)
{
f0100bff:	55                   	push   %ebp
f0100c00:	89 e5                	mov    %esp,%ebp
f0100c02:	83 ec 08             	sub    $0x8,%esp
	cprintf("Free frames = %d\n", calculate_free_frames());
f0100c05:	e8 af 20 00 00       	call   f0102cb9 <calculate_free_frames>
f0100c0a:	83 ec 08             	sub    $0x8,%esp
f0100c0d:	50                   	push   %eax
f0100c0e:	68 a9 5a 10 f0       	push   $0xf0105aa9
f0100c13:	e8 91 29 00 00       	call   f01035a9 <cprintf>
f0100c18:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c20:	c9                   	leave  
f0100c21:	c3                   	ret    

f0100c22 <command_abo>:
//===========================================================================
//Lab2.Hands.On
//=============
//TODO: LAB2 Hands-on: write the command function here
int command_abo(int number_of_arguments, char **arguments)
{
f0100c22:	55                   	push   %ebp
f0100c23:	89 e5                	mov    %esp,%ebp
f0100c25:	83 ec 08             	sub    $0x8,%esp
	cprintf("Abo is a low level programmer.\n");
f0100c28:	83 ec 0c             	sub    $0xc,%esp
f0100c2b:	68 bc 5a 10 f0       	push   $0xf0105abc
f0100c30:	e8 74 29 00 00       	call   f01035a9 <cprintf>
f0100c35:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c38:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c3d:	c9                   	leave  
f0100c3e:	c3                   	ret    

f0100c3f <command_add>:

int command_add(int argc, char **argv)
{
f0100c3f:	55                   	push   %ebp
f0100c40:	89 e5                	mov    %esp,%ebp
f0100c42:	83 ec 18             	sub    $0x18,%esp
	if (argc != 3)
f0100c45:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100c49:	74 17                	je     f0100c62 <command_add+0x23>
	{
		cprintf("Usage: add num1 num2\n");
f0100c4b:	83 ec 0c             	sub    $0xc,%esp
f0100c4e:	68 dc 5a 10 f0       	push   $0xf0105adc
f0100c53:	e8 51 29 00 00       	call   f01035a9 <cprintf>
f0100c58:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100c5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c60:	eb 57                	jmp    f0100cb9 <command_add+0x7a>
	}
	int num1 = strtol(argv[1], NULL, 10);
f0100c62:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c65:	83 c0 04             	add    $0x4,%eax
f0100c68:	8b 00                	mov    (%eax),%eax
f0100c6a:	83 ec 04             	sub    $0x4,%esp
f0100c6d:	6a 0a                	push   $0xa
f0100c6f:	6a 00                	push   $0x0
f0100c71:	50                   	push   %eax
f0100c72:	e8 86 41 00 00       	call   f0104dfd <strtol>
f0100c77:	83 c4 10             	add    $0x10,%esp
f0100c7a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int num2 = strtol(argv[2], NULL, 10);
f0100c7d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c80:	83 c0 08             	add    $0x8,%eax
f0100c83:	8b 00                	mov    (%eax),%eax
f0100c85:	83 ec 04             	sub    $0x4,%esp
f0100c88:	6a 0a                	push   $0xa
f0100c8a:	6a 00                	push   $0x0
f0100c8c:	50                   	push   %eax
f0100c8d:	e8 6b 41 00 00       	call   f0104dfd <strtol>
f0100c92:	83 c4 10             	add    $0x10,%esp
f0100c95:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("%d + %d = %d\n", num1, num2, num1 + num2);
f0100c98:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c9e:	01 d0                	add    %edx,%eax
f0100ca0:	50                   	push   %eax
f0100ca1:	ff 75 f0             	pushl  -0x10(%ebp)
f0100ca4:	ff 75 f4             	pushl  -0xc(%ebp)
f0100ca7:	68 f2 5a 10 f0       	push   $0xf0105af2
f0100cac:	e8 f8 28 00 00       	call   f01035a9 <cprintf>
f0100cb1:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100cb4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb9:	c9                   	leave  
f0100cba:	c3                   	ret    

f0100cbb <command_fact>:

int command_fact(int argc, char **argv)
{
f0100cbb:	55                   	push   %ebp
f0100cbc:	89 e5                	mov    %esp,%ebp
f0100cbe:	83 ec 18             	sub    $0x18,%esp
	if (argc != 2)
f0100cc1:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100cc5:	74 1a                	je     f0100ce1 <command_fact+0x26>
	{
		cprintf("Usage: fact N\n");
f0100cc7:	83 ec 0c             	sub    $0xc,%esp
f0100cca:	68 00 5b 10 f0       	push   $0xf0105b00
f0100ccf:	e8 d5 28 00 00       	call   f01035a9 <cprintf>
f0100cd4:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100cd7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cdc:	e9 e6 00 00 00       	jmp    f0100dc7 <command_fact+0x10c>
	}

	// assert it's only numeric values
	for (int i = 0; i < strlen(argv[1]); i++)
f0100ce1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100ce8:	eb 43                	jmp    f0100d2d <command_fact+0x72>
	{
		if (argv[1][i] < '0' || argv[1][i] > '9')
f0100cea:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ced:	83 c0 04             	add    $0x4,%eax
f0100cf0:	8b 10                	mov    (%eax),%edx
f0100cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100cf5:	01 d0                	add    %edx,%eax
f0100cf7:	8a 00                	mov    (%eax),%al
f0100cf9:	3c 2f                	cmp    $0x2f,%al
f0100cfb:	7e 13                	jle    f0100d10 <command_fact+0x55>
f0100cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d00:	83 c0 04             	add    $0x4,%eax
f0100d03:	8b 10                	mov    (%eax),%edx
f0100d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d08:	01 d0                	add    %edx,%eax
f0100d0a:	8a 00                	mov    (%eax),%al
f0100d0c:	3c 39                	cmp    $0x39,%al
f0100d0e:	7e 1a                	jle    f0100d2a <command_fact+0x6f>
		{
			cprintf("N must be a positive integer\n");
f0100d10:	83 ec 0c             	sub    $0xc,%esp
f0100d13:	68 0f 5b 10 f0       	push   $0xf0105b0f
f0100d18:	e8 8c 28 00 00       	call   f01035a9 <cprintf>
f0100d1d:	83 c4 10             	add    $0x10,%esp
			return 0;
f0100d20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d25:	e9 9d 00 00 00       	jmp    f0100dc7 <command_fact+0x10c>
		cprintf("Usage: fact N\n");
		return 0;
	}

	// assert it's only numeric values
	for (int i = 0; i < strlen(argv[1]); i++)
f0100d2a:	ff 45 f4             	incl   -0xc(%ebp)
f0100d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d30:	83 c0 04             	add    $0x4,%eax
f0100d33:	8b 00                	mov    (%eax),%eax
f0100d35:	83 ec 0c             	sub    $0xc,%esp
f0100d38:	50                   	push   %eax
f0100d39:	e8 5f 3d 00 00       	call   f0104a9d <strlen>
f0100d3e:	83 c4 10             	add    $0x10,%esp
f0100d41:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0100d44:	7f a4                	jg     f0100cea <command_fact+0x2f>
			return 0;
		}
	}

	// Corner Case
	long n = strtol(argv[1], NULL, 10);
f0100d46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d49:	83 c0 04             	add    $0x4,%eax
f0100d4c:	8b 00                	mov    (%eax),%eax
f0100d4e:	83 ec 04             	sub    $0x4,%esp
f0100d51:	6a 0a                	push   $0xa
f0100d53:	6a 00                	push   $0x0
f0100d55:	50                   	push   %eax
f0100d56:	e8 a2 40 00 00       	call   f0104dfd <strtol>
f0100d5b:	83 c4 10             	add    $0x10,%esp
f0100d5e:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if (n == 0 || n == 1)
f0100d61:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100d65:	74 06                	je     f0100d6d <command_fact+0xb2>
f0100d67:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
f0100d6b:	75 1a                	jne    f0100d87 <command_fact+0xcc>
	{
		cprintf("%d! = 1\n", n);
f0100d6d:	83 ec 08             	sub    $0x8,%esp
f0100d70:	ff 75 e8             	pushl  -0x18(%ebp)
f0100d73:	68 2d 5b 10 f0       	push   $0xf0105b2d
f0100d78:	e8 2c 28 00 00       	call   f01035a9 <cprintf>
f0100d7d:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100d80:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d85:	eb 40                	jmp    f0100dc7 <command_fact+0x10c>
	}

	// Straightforward
	long result = 1;
f0100d87:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
	for (int i = 1; i <= n; i++)
f0100d8e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d95:	eb 0d                	jmp    f0100da4 <command_fact+0xe9>
		result *= i;
f0100d97:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d9a:	0f af 45 ec          	imul   -0x14(%ebp),%eax
f0100d9e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		return 0;
	}

	// Straightforward
	long result = 1;
	for (int i = 1; i <= n; i++)
f0100da1:	ff 45 ec             	incl   -0x14(%ebp)
f0100da4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100da7:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100daa:	7e eb                	jle    f0100d97 <command_fact+0xdc>
		result *= i;
	cprintf("%d! = %d\n", n, result);
f0100dac:	83 ec 04             	sub    $0x4,%esp
f0100daf:	ff 75 f0             	pushl  -0x10(%ebp)
f0100db2:	ff 75 e8             	pushl  -0x18(%ebp)
f0100db5:	68 36 5b 10 f0       	push   $0xf0105b36
f0100dba:	e8 ea 27 00 00       	call   f01035a9 <cprintf>
f0100dbf:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100dc2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100dc7:	c9                   	leave  
f0100dc8:	c3                   	ret    

f0100dc9 <command_readblock>:

int command_readblock(int argc, char **argv)
{
f0100dc9:	55                   	push   %ebp
f0100dca:	89 e5                	mov    %esp,%ebp
f0100dcc:	83 ec 18             	sub    $0x18,%esp
	if (argc != 3)
f0100dcf:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100dd3:	74 07                	je     f0100ddc <command_readblock+0x13>
		return 1;
f0100dd5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100dda:	eb 74                	jmp    f0100e50 <command_readblock+0x87>
	unsigned int virtualAddress = strtol(argv[1], NULL, 16);
f0100ddc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ddf:	83 c0 04             	add    $0x4,%eax
f0100de2:	8b 00                	mov    (%eax),%eax
f0100de4:	83 ec 04             	sub    $0x4,%esp
f0100de7:	6a 10                	push   $0x10
f0100de9:	6a 00                	push   $0x0
f0100deb:	50                   	push   %eax
f0100dec:	e8 0c 40 00 00       	call   f0104dfd <strtol>
f0100df1:	83 c4 10             	add    $0x10,%esp
f0100df4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	unsigned char *byte = (unsigned char *)(virtualAddress);
f0100df7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100dfa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned int charCount = strtol(argv[2], NULL, 10);
f0100dfd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e00:	83 c0 08             	add    $0x8,%eax
f0100e03:	8b 00                	mov    (%eax),%eax
f0100e05:	83 ec 04             	sub    $0x4,%esp
f0100e08:	6a 0a                	push   $0xa
f0100e0a:	6a 00                	push   $0x0
f0100e0c:	50                   	push   %eax
f0100e0d:	e8 eb 3f 00 00       	call   f0104dfd <strtol>
f0100e12:	83 c4 10             	add    $0x10,%esp
f0100e15:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for(unsigned int i = 0; i < charCount; i++, byte++)
f0100e18:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100e1f:	eb 22                	jmp    f0100e43 <command_readblock+0x7a>
		cprintf("Value @%x = %c\n", byte, *byte);
f0100e21:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e24:	8a 00                	mov    (%eax),%al
f0100e26:	0f b6 c0             	movzbl %al,%eax
f0100e29:	83 ec 04             	sub    $0x4,%esp
f0100e2c:	50                   	push   %eax
f0100e2d:	ff 75 f4             	pushl  -0xc(%ebp)
f0100e30:	68 40 5b 10 f0       	push   $0xf0105b40
f0100e35:	e8 6f 27 00 00       	call   f01035a9 <cprintf>
f0100e3a:	83 c4 10             	add    $0x10,%esp
		return 1;
	unsigned int virtualAddress = strtol(argv[1], NULL, 16);
	unsigned char *byte = (unsigned char *)(virtualAddress);
	unsigned int charCount = strtol(argv[2], NULL, 10);

	for(unsigned int i = 0; i < charCount; i++, byte++)
f0100e3d:	ff 45 f0             	incl   -0x10(%ebp)
f0100e40:	ff 45 f4             	incl   -0xc(%ebp)
f0100e43:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e46:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100e49:	72 d6                	jb     f0100e21 <command_readblock+0x58>
		cprintf("Value @%x = %c\n", byte, *byte);
	return (0);
f0100e4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e50:	c9                   	leave  
f0100e51:	c3                   	ret    

f0100e52 <command_createintarray>:

int command_createintarray(int argc, char **argv)
{
f0100e52:	55                   	push   %ebp
f0100e53:	89 e5                	mov    %esp,%ebp
	}
	cprintf("The start virtual address of the allocated array is: 0x%x", allocatedArr);
	for(int i = 0; i < arrLen; i++, allocatedArr++)
		cprintf("Element %d: %d\n", i, *allocatedArr);
	*/
	return (0);
f0100e55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e5a:	5d                   	pop    %ebp
f0100e5b:	c3                   	ret    

f0100e5c <command_kernel_base_info>:

//===========================================================================
//Lab3.Examples
//=============
int command_kernel_base_info(int number_of_arguments, char **arguments)
{
f0100e5c:	55                   	push   %ebp
f0100e5d:	89 e5                	mov    %esp,%ebp
f0100e5f:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "ikb"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100e62:	83 ec 04             	sub    $0x4,%esp
f0100e65:	68 50 5b 10 f0       	push   $0xf0105b50
f0100e6a:	68 5d 01 00 00       	push   $0x15d
f0100e6f:	68 71 5b 10 f0       	push   $0xf0105b71
f0100e74:	e8 b5 f2 ff ff       	call   f010012e <_panic>

f0100e79 <command_del_kernel_base>:

	return 0;
}

int command_del_kernel_base(int number_of_arguments, char **arguments)
{
f0100e79:	55                   	push   %ebp
f0100e7a:	89 e5                	mov    %esp,%ebp
f0100e7c:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "dkb"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100e7f:	83 ec 04             	sub    $0x4,%esp
f0100e82:	68 50 5b 10 f0       	push   $0xf0105b50
f0100e87:	68 66 01 00 00       	push   $0x166
f0100e8c:	68 71 5b 10 f0       	push   $0xf0105b71
f0100e91:	e8 98 f2 ff ff       	call   f010012e <_panic>

f0100e96 <command_share_page>:

	return 0;
}

int command_share_page(int number_of_arguments, char **arguments)
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "shr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100e9c:	83 ec 04             	sub    $0x4,%esp
f0100e9f:	68 50 5b 10 f0       	push   $0xf0105b50
f0100ea4:	68 6f 01 00 00       	push   $0x16f
f0100ea9:	68 71 5b 10 f0       	push   $0xf0105b71
f0100eae:	e8 7b f2 ff ff       	call   f010012e <_panic>

f0100eb3 <command_show_mapping>:

//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int argc, char **argv)
{
f0100eb3:	55                   	push   %ebp
f0100eb4:	89 e5                	mov    %esp,%ebp
f0100eb6:	83 ec 28             	sub    $0x28,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 2)
f0100eb9:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100ebd:	74 1a                	je     f0100ed9 <command_show_mapping+0x26>
	{
		cprintf("Usage: sm <virtual address>\n");
f0100ebf:	83 ec 0c             	sub    $0xc,%esp
f0100ec2:	68 87 5b 10 f0       	push   $0xf0105b87
f0100ec7:	e8 dd 26 00 00       	call   f01035a9 <cprintf>
f0100ecc:	83 c4 10             	add    $0x10,%esp
		return (0);
f0100ecf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed4:	e9 f9 00 00 00       	jmp    f0100fd2 <command_show_mapping+0x11f>
	}
	unsigned int virtualAddress = strtol(argv[1], NULL, 16);
f0100ed9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100edc:	83 c0 04             	add    $0x4,%eax
f0100edf:	8b 00                	mov    (%eax),%eax
f0100ee1:	83 ec 04             	sub    $0x4,%esp
f0100ee4:	6a 10                	push   $0x10
f0100ee6:	6a 00                	push   $0x0
f0100ee8:	50                   	push   %eax
f0100ee9:	e8 0f 3f 00 00       	call   f0104dfd <strtol>
f0100eee:	83 c4 10             	add    $0x10,%esp
f0100ef1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	cprintf("Directory Index: %d\n", PDX(virtualAddress));
f0100ef4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ef7:	c1 e8 16             	shr    $0x16,%eax
f0100efa:	83 ec 08             	sub    $0x8,%esp
f0100efd:	50                   	push   %eax
f0100efe:	68 a4 5b 10 f0       	push   $0xf0105ba4
f0100f03:	e8 a1 26 00 00       	call   f01035a9 <cprintf>
f0100f08:	83 c4 10             	add    $0x10,%esp
	cprintf("Page Table Index: %d\n", PTX(virtualAddress));
f0100f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f0e:	c1 e8 0c             	shr    $0xc,%eax
f0100f11:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100f16:	83 ec 08             	sub    $0x8,%esp
f0100f19:	50                   	push   %eax
f0100f1a:	68 b9 5b 10 f0       	push   $0xf0105bb9
f0100f1f:	e8 85 26 00 00       	call   f01035a9 <cprintf>
f0100f24:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int PTE_level1 = ptr_page_directory[PDX(virtualAddress)];
f0100f27:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0100f2c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f2f:	c1 ea 16             	shr    $0x16,%edx
f0100f32:	c1 e2 02             	shl    $0x2,%edx
f0100f35:	01 d0                	add    %edx,%eax
f0100f37:	8b 00                	mov    (%eax),%eax
f0100f39:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned int frame_level1 = PTE_level1 >> 12;
f0100f3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f3f:	c1 e8 0c             	shr    $0xc,%eax
f0100f42:	89 45 ec             	mov    %eax,-0x14(%ebp)
	cprintf("Physical address of the Page Table: %x\n", frame_level1 * PAGE_SIZE);
f0100f45:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f48:	c1 e0 0c             	shl    $0xc,%eax
f0100f4b:	83 ec 08             	sub    $0x8,%esp
f0100f4e:	50                   	push   %eax
f0100f4f:	68 d0 5b 10 f0       	push   $0xf0105bd0
f0100f54:	e8 50 26 00 00       	call   f01035a9 <cprintf>
f0100f59:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int *PT_ptr;
	get_page_table(ptr_page_directory, (void *)virtualAddress, 1, &PT_ptr);
f0100f5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f5f:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0100f64:	8d 4d dc             	lea    -0x24(%ebp),%ecx
f0100f67:	51                   	push   %ecx
f0100f68:	6a 01                	push   $0x1
f0100f6a:	52                   	push   %edx
f0100f6b:	50                   	push   %eax
f0100f6c:	e8 4b 1a 00 00       	call   f01029bc <get_page_table>
f0100f71:	83 c4 10             	add    $0x10,%esp
	unsigned int PTE_level2 = PT_ptr[PTX(virtualAddress)];
f0100f74:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f77:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f7a:	c1 ea 0c             	shr    $0xc,%edx
f0100f7d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100f83:	c1 e2 02             	shl    $0x2,%edx
f0100f86:	01 d0                	add    %edx,%eax
f0100f88:	8b 00                	mov    (%eax),%eax
f0100f8a:	89 45 e8             	mov    %eax,-0x18(%ebp)
	unsigned int frame_level2 = PTE_level2 >> 12;
f0100f8d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100f90:	c1 e8 0c             	shr    $0xc,%eax
f0100f93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("Frame number of the page itself: %d\n", frame_level2);
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f9c:	68 f8 5b 10 f0       	push   $0xf0105bf8
f0100fa1:	e8 03 26 00 00       	call   f01035a9 <cprintf>
f0100fa6:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int usedStatus = (PERM_USED & PTE_level2) == PERM_USED;
f0100fa9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fac:	83 e0 20             	and    $0x20,%eax
f0100faf:	85 c0                	test   %eax,%eax
f0100fb1:	0f 95 c0             	setne  %al
f0100fb4:	0f b6 c0             	movzbl %al,%eax
f0100fb7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("Used status: %d\n", usedStatus);
f0100fba:	83 ec 08             	sub    $0x8,%esp
f0100fbd:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fc0:	68 1d 5c 10 f0       	push   $0xf0105c1d
f0100fc5:	e8 df 25 00 00       	call   f01035a9 <cprintf>
f0100fca:	83 c4 10             	add    $0x10,%esp

	return (0) ;
f0100fcd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fd2:	c9                   	leave  
f0100fd3:	c3                   	ret    

f0100fd4 <command_set_permission>:

int command_set_permission(int argc, char **argv)
{
f0100fd4:	55                   	push   %ebp
f0100fd5:	89 e5                	mov    %esp,%ebp
f0100fd7:	83 ec 28             	sub    $0x28,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 3) {
f0100fda:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100fde:	74 1a                	je     f0100ffa <command_set_permission+0x26>
		cprintf("Usage: sp <virtual address> <r/w>\n");
f0100fe0:	83 ec 0c             	sub    $0xc,%esp
f0100fe3:	68 30 5c 10 f0       	push   $0xf0105c30
f0100fe8:	e8 bc 25 00 00       	call   f01035a9 <cprintf>
f0100fed:	83 c4 10             	add    $0x10,%esp
		return (0);
f0100ff0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff5:	e9 f7 00 00 00       	jmp    f01010f1 <command_set_permission+0x11d>
	}
	uint32 virtualAddress = strtol(argv[1], NULL, 16);
f0100ffa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ffd:	83 c0 04             	add    $0x4,%eax
f0101000:	8b 00                	mov    (%eax),%eax
f0101002:	83 ec 04             	sub    $0x4,%esp
f0101005:	6a 10                	push   $0x10
f0101007:	6a 00                	push   $0x0
f0101009:	50                   	push   %eax
f010100a:	e8 ee 3d 00 00       	call   f0104dfd <strtol>
f010100f:	83 c4 10             	add    $0x10,%esp
f0101012:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *mode = argv[2];
f0101015:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101018:	8b 40 08             	mov    0x8(%eax),%eax
f010101b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32 *PT;
	int error = get_page_table(ptr_page_directory, (void *)virtualAddress, 1, &PT);
f010101e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101021:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101026:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f0101029:	51                   	push   %ecx
f010102a:	6a 01                	push   $0x1
f010102c:	52                   	push   %edx
f010102d:	50                   	push   %eax
f010102e:	e8 89 19 00 00       	call   f01029bc <get_page_table>
f0101033:	83 c4 10             	add    $0x10,%esp
f0101036:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (error) {
f0101039:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010103d:	74 1a                	je     f0101059 <command_set_permission+0x85>
		cprintf("Error in get_page_table()\n");
f010103f:	83 ec 0c             	sub    $0xc,%esp
f0101042:	68 53 5c 10 f0       	push   $0xf0105c53
f0101047:	e8 5d 25 00 00       	call   f01035a9 <cprintf>
f010104c:	83 c4 10             	add    $0x10,%esp
		return (1);
f010104f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101054:	e9 98 00 00 00       	jmp    f01010f1 <command_set_permission+0x11d>
	}
	uint32 entry = PT[PTX(virtualAddress)];
f0101059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010105c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010105f:	c1 ea 0c             	shr    $0xc,%edx
f0101062:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101068:	c1 e2 02             	shl    $0x2,%edx
f010106b:	01 d0                	add    %edx,%eax
f010106d:	8b 00                	mov    (%eax),%eax
f010106f:	89 45 e8             	mov    %eax,-0x18(%ebp)

	if (strcmp(mode, "w") == 0)// Writable -> Set
f0101072:	83 ec 08             	sub    $0x8,%esp
f0101075:	68 6e 5c 10 f0       	push   $0xf0105c6e
f010107a:	ff 75 f0             	pushl  -0x10(%ebp)
f010107d:	e8 27 3b 00 00       	call   f0104ba9 <strcmp>
f0101082:	83 c4 10             	add    $0x10,%esp
f0101085:	85 c0                	test   %eax,%eax
f0101087:	75 1e                	jne    f01010a7 <command_set_permission+0xd3>
		PT[PTX(virtualAddress)] = entry | PERM_WRITEABLE;
f0101089:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010108c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010108f:	c1 ea 0c             	shr    $0xc,%edx
f0101092:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101098:	c1 e2 02             	shl    $0x2,%edx
f010109b:	01 d0                	add    %edx,%eax
f010109d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01010a0:	83 ca 02             	or     $0x2,%edx
f01010a3:	89 10                	mov    %edx,(%eax)
f01010a5:	eb 45                	jmp    f01010ec <command_set_permission+0x118>
	else if (strcmp(mode, "r") == 0) // Read Only -> not Writable -> Reset
f01010a7:	83 ec 08             	sub    $0x8,%esp
f01010aa:	68 70 5c 10 f0       	push   $0xf0105c70
f01010af:	ff 75 f0             	pushl  -0x10(%ebp)
f01010b2:	e8 f2 3a 00 00       	call   f0104ba9 <strcmp>
f01010b7:	83 c4 10             	add    $0x10,%esp
f01010ba:	85 c0                	test   %eax,%eax
f01010bc:	75 1e                	jne    f01010dc <command_set_permission+0x108>
		PT[PTX(virtualAddress)] = entry & ~PERM_WRITEABLE;
f01010be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010c4:	c1 ea 0c             	shr    $0xc,%edx
f01010c7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01010cd:	c1 e2 02             	shl    $0x2,%edx
f01010d0:	01 d0                	add    %edx,%eax
f01010d2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01010d5:	83 e2 fd             	and    $0xfffffffd,%edx
f01010d8:	89 10                	mov    %edx,(%eax)
f01010da:	eb 10                	jmp    f01010ec <command_set_permission+0x118>
	else
		cprintf("Usage: sp <virtual address> <r/w>\n");
f01010dc:	83 ec 0c             	sub    $0xc,%esp
f01010df:	68 30 5c 10 f0       	push   $0xf0105c30
f01010e4:	e8 c0 24 00 00       	call   f01035a9 <cprintf>
f01010e9:	83 c4 10             	add    $0x10,%esp
	return (0);
f01010ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010f1:	c9                   	leave  
f01010f2:	c3                   	ret    

f01010f3 <command_share_range>:

int command_share_range(int argc, char **argv)
{
f01010f3:	55                   	push   %ebp
f01010f4:	89 e5                	mov    %esp,%ebp
f01010f6:	83 ec 28             	sub    $0x28,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 4) {
f01010f9:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f01010fd:	74 1a                	je     f0101119 <command_share_range+0x26>
		cprintf("Usage: sr <va1> <va2> <size in KB>\n");
f01010ff:	83 ec 0c             	sub    $0xc,%esp
f0101102:	68 74 5c 10 f0       	push   $0xf0105c74
f0101107:	e8 9d 24 00 00       	call   f01035a9 <cprintf>
f010110c:	83 c4 10             	add    $0x10,%esp
		return (0);
f010110f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101114:	e9 0b 01 00 00       	jmp    f0101224 <command_share_range+0x131>
	}

	// Go to the entries in level 2 and set their frame numbers to one of them

	uint32 va1 = strtol(argv[1], NULL, 16);
f0101119:	8b 45 0c             	mov    0xc(%ebp),%eax
f010111c:	83 c0 04             	add    $0x4,%eax
f010111f:	8b 00                	mov    (%eax),%eax
f0101121:	83 ec 04             	sub    $0x4,%esp
f0101124:	6a 10                	push   $0x10
f0101126:	6a 00                	push   $0x0
f0101128:	50                   	push   %eax
f0101129:	e8 cf 3c 00 00       	call   f0104dfd <strtol>
f010112e:	83 c4 10             	add    $0x10,%esp
f0101131:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32 va2 = strtol(argv[2], NULL, 16);
f0101134:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101137:	83 c0 08             	add    $0x8,%eax
f010113a:	8b 00                	mov    (%eax),%eax
f010113c:	83 ec 04             	sub    $0x4,%esp
f010113f:	6a 10                	push   $0x10
f0101141:	6a 00                	push   $0x0
f0101143:	50                   	push   %eax
f0101144:	e8 b4 3c 00 00       	call   f0104dfd <strtol>
f0101149:	83 c4 10             	add    $0x10,%esp
f010114c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 size = strtol(argv[3], NULL, 16);
f010114f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101152:	83 c0 0c             	add    $0xc,%eax
f0101155:	8b 00                	mov    (%eax),%eax
f0101157:	83 ec 04             	sub    $0x4,%esp
f010115a:	6a 10                	push   $0x10
f010115c:	6a 00                	push   $0x0
f010115e:	50                   	push   %eax
f010115f:	e8 99 3c 00 00       	call   f0104dfd <strtol>
f0101164:	83 c4 10             	add    $0x10,%esp
f0101167:	89 45 e8             	mov    %eax,-0x18(%ebp)

	uint32 *PT1;
	if(get_page_table(ptr_page_directory, (void *)va1, 1, &PT1)) {
f010116a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010116d:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101172:	8d 4d dc             	lea    -0x24(%ebp),%ecx
f0101175:	51                   	push   %ecx
f0101176:	6a 01                	push   $0x1
f0101178:	52                   	push   %edx
f0101179:	50                   	push   %eax
f010117a:	e8 3d 18 00 00       	call   f01029bc <get_page_table>
f010117f:	83 c4 10             	add    $0x10,%esp
f0101182:	85 c0                	test   %eax,%eax
f0101184:	74 1a                	je     f01011a0 <command_share_range+0xad>
		cprintf("Error in ptr_page_directory()\n");
f0101186:	83 ec 0c             	sub    $0xc,%esp
f0101189:	68 98 5c 10 f0       	push   $0xf0105c98
f010118e:	e8 16 24 00 00       	call   f01035a9 <cprintf>
f0101193:	83 c4 10             	add    $0x10,%esp
		return (0);
f0101196:	b8 00 00 00 00       	mov    $0x0,%eax
f010119b:	e9 84 00 00 00       	jmp    f0101224 <command_share_range+0x131>
	}
	uint32 *ptr1 = PT1 + PTX(va1);
f01011a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011a3:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01011a6:	c1 ea 0c             	shr    $0xc,%edx
f01011a9:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011af:	c1 e2 02             	shl    $0x2,%edx
f01011b2:	01 d0                	add    %edx,%eax
f01011b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	uint32 *PT2;
	if(get_page_table(ptr_page_directory, (void *)va2, 1, &PT2)) {
f01011b7:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01011ba:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01011bf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01011c2:	51                   	push   %ecx
f01011c3:	6a 01                	push   $0x1
f01011c5:	52                   	push   %edx
f01011c6:	50                   	push   %eax
f01011c7:	e8 f0 17 00 00       	call   f01029bc <get_page_table>
f01011cc:	83 c4 10             	add    $0x10,%esp
f01011cf:	85 c0                	test   %eax,%eax
f01011d1:	74 17                	je     f01011ea <command_share_range+0xf7>
		cprintf("Error in ptr_page_directory()\n");
f01011d3:	83 ec 0c             	sub    $0xc,%esp
f01011d6:	68 98 5c 10 f0       	push   $0xf0105c98
f01011db:	e8 c9 23 00 00       	call   f01035a9 <cprintf>
f01011e0:	83 c4 10             	add    $0x10,%esp
		return (0);
f01011e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011e8:	eb 3a                	jmp    f0101224 <command_share_range+0x131>
	}
	uint32 *ptr2 = PT2 + PTX(va2);
f01011ea:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011ed:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01011f0:	c1 ea 0c             	shr    $0xc,%edx
f01011f3:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011f9:	c1 e2 02             	shl    $0x2,%edx
f01011fc:	01 d0                	add    %edx,%eax
f01011fe:	89 45 e0             	mov    %eax,-0x20(%ebp)

	for (uint32 frame1, frame2, i = 0; i < size; i++) {
f0101201:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101208:	eb 0d                	jmp    f0101217 <command_share_range+0x124>
//		frame1 = (*ptr1 >> 12) << 12;
//		frame2 = (*ptr2 >> 12) << 12;
//		*ptr2 -= frame2;
//		*ptr2 += frame1;
		*ptr2 = *ptr1;
f010120a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010120d:	8b 10                	mov    (%eax),%edx
f010120f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101212:	89 10                	mov    %edx,(%eax)
		cprintf("Error in ptr_page_directory()\n");
		return (0);
	}
	uint32 *ptr2 = PT2 + PTX(va2);

	for (uint32 frame1, frame2, i = 0; i < size; i++) {
f0101214:	ff 45 f4             	incl   -0xc(%ebp)
f0101217:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010121a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010121d:	72 eb                	jb     f010120a <command_share_range+0x117>
//		*ptr2 -= frame2;
//		*ptr2 += frame1;
		*ptr2 = *ptr1;
	}

	return (0);
f010121f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101224:	c9                   	leave  
f0101225:	c3                   	ret    

f0101226 <command_nr>:
//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");
f010122c:	83 ec 04             	sub    $0x4,%esp
f010122f:	68 50 5b 10 f0       	push   $0xf0105b50
f0101234:	68 e6 01 00 00       	push   $0x1e6
f0101239:	68 71 5b 10 f0       	push   $0xf0105b71
f010123e:	e8 eb ee ff ff       	call   f010012e <_panic>

f0101243 <command_ap>:
	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
f0101243:	55                   	push   %ebp
f0101244:	89 e5                	mov    %esp,%ebp
f0101246:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "ap"
	//Comment the following line
	//panic("Function is not implemented yet!");

	uint32 va = strtol(arguments[1], NULL, 16);
f0101249:	8b 45 0c             	mov    0xc(%ebp),%eax
f010124c:	83 c0 04             	add    $0x4,%eax
f010124f:	8b 00                	mov    (%eax),%eax
f0101251:	83 ec 04             	sub    $0x4,%esp
f0101254:	6a 10                	push   $0x10
f0101256:	6a 00                	push   $0x0
f0101258:	50                   	push   %eax
f0101259:	e8 9f 3b 00 00       	call   f0104dfd <strtol>
f010125e:	83 c4 10             	add    $0x10,%esp
f0101261:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Frame_Info* ptr_frame_info;
	int ret = allocate_frame(&ptr_frame_info) ;
f0101264:	83 ec 0c             	sub    $0xc,%esp
f0101267:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010126a:	50                   	push   %eax
f010126b:	e8 84 16 00 00       	call   f01028f4 <allocate_frame>
f0101270:	83 c4 10             	add    $0x10,%esp
f0101273:	89 45 f0             	mov    %eax,-0x10(%ebp)
	map_frame(ptr_page_directory, ptr_frame_info, (void*)va, PERM_USER | PERM_WRITEABLE);
f0101276:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101279:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010127c:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101281:	6a 06                	push   $0x6
f0101283:	51                   	push   %ecx
f0101284:	52                   	push   %edx
f0101285:	50                   	push   %eax
f0101286:	e8 76 18 00 00       	call   f0102b01 <map_frame>
f010128b:	83 c4 10             	add    $0x10,%esp

	return 0 ;
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101293:	c9                   	leave  
f0101294:	c3                   	ret    

f0101295 <command_fp>:

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
f0101295:	55                   	push   %ebp
f0101296:	89 e5                	mov    %esp,%ebp
f0101298:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	//panic("Function is not implemented yet!");

	uint32 va = strtol(arguments[1], NULL, 16);
f010129b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129e:	83 c0 04             	add    $0x4,%eax
f01012a1:	8b 00                	mov    (%eax),%eax
f01012a3:	83 ec 04             	sub    $0x4,%esp
f01012a6:	6a 10                	push   $0x10
f01012a8:	6a 00                	push   $0x0
f01012aa:	50                   	push   %eax
f01012ab:	e8 4d 3b 00 00       	call   f0104dfd <strtol>
f01012b0:	83 c4 10             	add    $0x10,%esp
f01012b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Un-map the page at this address
	unmap_frame(ptr_page_directory, (void*)va);
f01012b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012b9:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01012be:	83 ec 08             	sub    $0x8,%esp
f01012c1:	52                   	push   %edx
f01012c2:	50                   	push   %eax
f01012c3:	e8 57 19 00 00       	call   f0102c1f <unmap_frame>
f01012c8:	83 c4 10             	add    $0x10,%esp

	return 0;
f01012cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012d0:	c9                   	leave  
f01012d1:	c3                   	ret    

f01012d2 <command_asp>:
//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
f01012d2:	55                   	push   %ebp
f01012d3:	89 e5                	mov    %esp,%ebp
f01012d5:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");
f01012d8:	83 ec 04             	sub    $0x4,%esp
f01012db:	68 50 5b 10 f0       	push   $0xf0105b50
f01012e0:	68 10 02 00 00       	push   $0x210
f01012e5:	68 71 5b 10 f0       	push   $0xf0105b71
f01012ea:	e8 3f ee ff ff       	call   f010012e <_panic>

f01012ef <command_cfp>:
	return 0;
}

//[2] Count Free Pages in Range
int command_cfp(int number_of_arguments, char **arguments)
{
f01012ef:	55                   	push   %ebp
f01012f0:	89 e5                	mov    %esp,%ebp
f01012f2:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "cfp"
	//Comment the following line
	panic("Function is not implemented yet!");
f01012f5:	83 ec 04             	sub    $0x4,%esp
f01012f8:	68 50 5b 10 f0       	push   $0xf0105b50
f01012fd:	68 1a 02 00 00       	push   $0x21a
f0101302:	68 71 5b 10 f0       	push   $0xf0105b71
f0101307:	e8 22 ee ff ff       	call   f010012e <_panic>

f010130c <command_run>:

//===========================================================================
//Lab6.Examples
//=============
int command_run(int number_of_arguments, char **arguments)
{
f010130c:	55                   	push   %ebp
f010130d:	89 e5                	mov    %esp,%ebp
f010130f:	83 ec 18             	sub    $0x18,%esp
	//[1] Create and initialize a new environment for the program to be run
	struct UserProgramInfo* ptr_program_info = env_create(arguments[1]);
f0101312:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101315:	83 c0 04             	add    $0x4,%eax
f0101318:	8b 00                	mov    (%eax),%eax
f010131a:	83 ec 0c             	sub    $0xc,%esp
f010131d:	50                   	push   %eax
f010131e:	e8 6f 1a 00 00       	call   f0102d92 <env_create>
f0101323:	83 c4 10             	add    $0x10,%esp
f0101326:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0101329:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010132d:	75 07                	jne    f0101336 <command_run+0x2a>
f010132f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101334:	eb 0f                	jmp    f0101345 <command_run+0x39>

	//[2] Run the created environment using "env_run" function
	env_run(ptr_program_info->environment);
f0101336:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101339:	8b 40 0c             	mov    0xc(%eax),%eax
f010133c:	83 ec 0c             	sub    $0xc,%esp
f010133f:	50                   	push   %eax
f0101340:	e8 bc 1a 00 00       	call   f0102e01 <env_run>
	return 0;
}
f0101345:	c9                   	leave  
f0101346:	c3                   	ret    

f0101347 <command_kill>:

int command_kill(int number_of_arguments, char **arguments)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	83 ec 18             	sub    $0x18,%esp
	//[1] Get the user program info of the program (by searching in the "userPrograms" array
	struct UserProgramInfo* ptr_program_info = get_user_program_info(arguments[1]) ;
f010134d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101350:	83 c0 04             	add    $0x4,%eax
f0101353:	8b 00                	mov    (%eax),%eax
f0101355:	83 ec 0c             	sub    $0xc,%esp
f0101358:	50                   	push   %eax
f0101359:	e8 74 1f 00 00       	call   f01032d2 <get_user_program_info>
f010135e:	83 c4 10             	add    $0x10,%esp
f0101361:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0101364:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101368:	75 07                	jne    f0101371 <command_kill+0x2a>
f010136a:	b8 00 00 00 00       	mov    $0x0,%eax
f010136f:	eb 21                	jmp    f0101392 <command_kill+0x4b>

	//[2] Kill its environment using "env_free" function
	env_free(ptr_program_info->environment);
f0101371:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101374:	8b 40 0c             	mov    0xc(%eax),%eax
f0101377:	83 ec 0c             	sub    $0xc,%esp
f010137a:	50                   	push   %eax
f010137b:	e8 c4 1a 00 00       	call   f0102e44 <env_free>
f0101380:	83 c4 10             	add    $0x10,%esp
	ptr_program_info->environment = NULL;
f0101383:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101386:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	return 0;
f010138d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101392:	c9                   	leave  
f0101393:	c3                   	ret    

f0101394 <command_ft>:

int command_ft(int number_of_arguments, char **arguments)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
f0101397:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010139c:	5d                   	pop    %ebp
f010139d:	c3                   	ret    

f010139e <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f010139e:	55                   	push   %ebp
f010139f:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f01013a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013a4:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f01013aa:	29 d0                	sub    %edx,%eax
f01013ac:	c1 f8 02             	sar    $0x2,%eax
f01013af:	89 c2                	mov    %eax,%edx
f01013b1:	89 d0                	mov    %edx,%eax
f01013b3:	c1 e0 02             	shl    $0x2,%eax
f01013b6:	01 d0                	add    %edx,%eax
f01013b8:	c1 e0 02             	shl    $0x2,%eax
f01013bb:	01 d0                	add    %edx,%eax
f01013bd:	c1 e0 02             	shl    $0x2,%eax
f01013c0:	01 d0                	add    %edx,%eax
f01013c2:	89 c1                	mov    %eax,%ecx
f01013c4:	c1 e1 08             	shl    $0x8,%ecx
f01013c7:	01 c8                	add    %ecx,%eax
f01013c9:	89 c1                	mov    %eax,%ecx
f01013cb:	c1 e1 10             	shl    $0x10,%ecx
f01013ce:	01 c8                	add    %ecx,%eax
f01013d0:	01 c0                	add    %eax,%eax
f01013d2:	01 d0                	add    %edx,%eax
}
f01013d4:	5d                   	pop    %ebp
f01013d5:	c3                   	ret    

f01013d6 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f01013d6:	55                   	push   %ebp
f01013d7:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f01013d9:	ff 75 08             	pushl  0x8(%ebp)
f01013dc:	e8 bd ff ff ff       	call   f010139e <to_frame_number>
f01013e1:	83 c4 04             	add    $0x4,%esp
f01013e4:	c1 e0 0c             	shl    $0xc,%eax
}
f01013e7:	c9                   	leave  
f01013e8:	c3                   	ret    

f01013e9 <nvram_read>:
{
	sizeof(gdt) - 1, (unsigned long) gdt
};

int nvram_read(int r)
{	
f01013e9:	55                   	push   %ebp
f01013ea:	89 e5                	mov    %esp,%ebp
f01013ec:	53                   	push   %ebx
f01013ed:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f3:	83 ec 0c             	sub    $0xc,%esp
f01013f6:	50                   	push   %eax
f01013f7:	e8 f8 20 00 00       	call   f01034f4 <mc146818_read>
f01013fc:	83 c4 10             	add    $0x10,%esp
f01013ff:	89 c3                	mov    %eax,%ebx
f0101401:	8b 45 08             	mov    0x8(%ebp),%eax
f0101404:	40                   	inc    %eax
f0101405:	83 ec 0c             	sub    $0xc,%esp
f0101408:	50                   	push   %eax
f0101409:	e8 e6 20 00 00       	call   f01034f4 <mc146818_read>
f010140e:	83 c4 10             	add    $0x10,%esp
f0101411:	c1 e0 08             	shl    $0x8,%eax
f0101414:	09 d8                	or     %ebx,%eax
}
f0101416:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101419:	c9                   	leave  
f010141a:	c3                   	ret    

f010141b <detect_memory>:
	
void detect_memory()
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	size_of_base_mem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PAGE_SIZE);
f0101421:	83 ec 0c             	sub    $0xc,%esp
f0101424:	6a 15                	push   $0x15
f0101426:	e8 be ff ff ff       	call   f01013e9 <nvram_read>
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	c1 e0 0a             	shl    $0xa,%eax
f0101431:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101434:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101437:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010143c:	a3 d4 f7 14 f0       	mov    %eax,0xf014f7d4
	size_of_extended_mem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PAGE_SIZE);
f0101441:	83 ec 0c             	sub    $0xc,%esp
f0101444:	6a 17                	push   $0x17
f0101446:	e8 9e ff ff ff       	call   f01013e9 <nvram_read>
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	c1 e0 0a             	shl    $0xa,%eax
f0101451:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101454:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101457:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010145c:	a3 cc f7 14 f0       	mov    %eax,0xf014f7cc

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (size_of_extended_mem)
f0101461:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f0101466:	85 c0                	test   %eax,%eax
f0101468:	74 11                	je     f010147b <detect_memory+0x60>
		maxpa = PHYS_EXTENDED_MEM + size_of_extended_mem;
f010146a:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f010146f:	05 00 00 10 00       	add    $0x100000,%eax
f0101474:	a3 d0 f7 14 f0       	mov    %eax,0xf014f7d0
f0101479:	eb 0a                	jmp    f0101485 <detect_memory+0x6a>
	else
		maxpa = size_of_extended_mem;
f010147b:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f0101480:	a3 d0 f7 14 f0       	mov    %eax,0xf014f7d0

	number_of_frames = maxpa / PAGE_SIZE;
f0101485:	a1 d0 f7 14 f0       	mov    0xf014f7d0,%eax
f010148a:	c1 e8 0c             	shr    $0xc,%eax
f010148d:	a3 c8 f7 14 f0       	mov    %eax,0xf014f7c8

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0101492:	a1 d0 f7 14 f0       	mov    0xf014f7d0,%eax
f0101497:	c1 e8 0a             	shr    $0xa,%eax
f010149a:	83 ec 08             	sub    $0x8,%esp
f010149d:	50                   	push   %eax
f010149e:	68 b8 5c 10 f0       	push   $0xf0105cb8
f01014a3:	e8 01 21 00 00       	call   f01035a9 <cprintf>
f01014a8:	83 c4 10             	add    $0x10,%esp
	cprintf("base = %dK, extended = %dK\n", (int)(size_of_base_mem/1024), (int)(size_of_extended_mem/1024));
f01014ab:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f01014b0:	c1 e8 0a             	shr    $0xa,%eax
f01014b3:	89 c2                	mov    %eax,%edx
f01014b5:	a1 d4 f7 14 f0       	mov    0xf014f7d4,%eax
f01014ba:	c1 e8 0a             	shr    $0xa,%eax
f01014bd:	83 ec 04             	sub    $0x4,%esp
f01014c0:	52                   	push   %edx
f01014c1:	50                   	push   %eax
f01014c2:	68 d9 5c 10 f0       	push   $0xf0105cd9
f01014c7:	e8 dd 20 00 00       	call   f01035a9 <cprintf>
f01014cc:	83 c4 10             	add    $0x10,%esp
}
f01014cf:	90                   	nop
f01014d0:	c9                   	leave  
f01014d1:	c3                   	ret    

f01014d2 <check_boot_pgdir>:
// but it is a pretty good check.
//
uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va);

void check_boot_pgdir()
{
f01014d2:	55                   	push   %ebp
f01014d3:	89 e5                	mov    %esp,%ebp
f01014d5:	83 ec 28             	sub    $0x28,%esp
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
f01014d8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01014df:	8b 15 c8 f7 14 f0    	mov    0xf014f7c8,%edx
f01014e5:	89 d0                	mov    %edx,%eax
f01014e7:	01 c0                	add    %eax,%eax
f01014e9:	01 d0                	add    %edx,%eax
f01014eb:	c1 e0 02             	shl    $0x2,%eax
f01014ee:	89 c2                	mov    %eax,%edx
f01014f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01014f3:	01 d0                	add    %edx,%eax
f01014f5:	48                   	dec    %eax
f01014f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01014f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101501:	f7 75 f0             	divl   -0x10(%ebp)
f0101504:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101507:	29 d0                	sub    %edx,%eax
f0101509:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (i = 0; i < n; i += PAGE_SIZE)
f010150c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101513:	eb 71                	jmp    f0101586 <check_boot_pgdir+0xb4>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);
f0101515:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101518:	8d 90 00 00 00 ef    	lea    -0x11000000(%eax),%edx
f010151e:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101523:	83 ec 08             	sub    $0x8,%esp
f0101526:	52                   	push   %edx
f0101527:	50                   	push   %eax
f0101528:	e8 f4 01 00 00       	call   f0101721 <check_va2pa>
f010152d:	83 c4 10             	add    $0x10,%esp
f0101530:	89 c2                	mov    %eax,%edx
f0101532:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f0101537:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010153a:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0101541:	77 14                	ja     f0101557 <check_boot_pgdir+0x85>
f0101543:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101546:	68 f8 5c 10 f0       	push   $0xf0105cf8
f010154b:	6a 5e                	push   $0x5e
f010154d:	68 29 5d 10 f0       	push   $0xf0105d29
f0101552:	e8 d7 eb ff ff       	call   f010012e <_panic>
f0101557:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010155a:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0101560:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101563:	01 c8                	add    %ecx,%eax
f0101565:	39 c2                	cmp    %eax,%edx
f0101567:	74 16                	je     f010157f <check_boot_pgdir+0xad>
f0101569:	68 38 5d 10 f0       	push   $0xf0105d38
f010156e:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101573:	6a 5e                	push   $0x5e
f0101575:	68 29 5d 10 f0       	push   $0xf0105d29
f010157a:	e8 af eb ff ff       	call   f010012e <_panic>
{
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
f010157f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101586:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101589:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010158c:	72 87                	jb     f0101515 <check_boot_pgdir+0x43>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f010158e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101595:	eb 3d                	jmp    f01015d4 <check_boot_pgdir+0x102>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);
f0101597:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010159a:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f01015a0:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01015a5:	83 ec 08             	sub    $0x8,%esp
f01015a8:	52                   	push   %edx
f01015a9:	50                   	push   %eax
f01015aa:	e8 72 01 00 00       	call   f0101721 <check_va2pa>
f01015af:	83 c4 10             	add    $0x10,%esp
f01015b2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f01015b5:	74 16                	je     f01015cd <check_boot_pgdir+0xfb>
f01015b7:	68 b0 5d 10 f0       	push   $0xf0105db0
f01015bc:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01015c1:	6a 62                	push   $0x62
f01015c3:	68 29 5d 10 f0       	push   $0xf0105d29
f01015c8:	e8 61 eb ff ff       	call   f010012e <_panic>
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f01015cd:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01015d4:	81 7d f4 00 00 00 10 	cmpl   $0x10000000,-0xc(%ebp)
f01015db:	75 ba                	jne    f0101597 <check_boot_pgdir+0xc5>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f01015dd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01015e4:	eb 6e                	jmp    f0101654 <check_boot_pgdir+0x182>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);
f01015e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015e9:	8d 90 00 80 bf ef    	lea    -0x10408000(%eax),%edx
f01015ef:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01015f4:	83 ec 08             	sub    $0x8,%esp
f01015f7:	52                   	push   %edx
f01015f8:	50                   	push   %eax
f01015f9:	e8 23 01 00 00       	call   f0101721 <check_va2pa>
f01015fe:	83 c4 10             	add    $0x10,%esp
f0101601:	c7 45 e0 00 40 11 f0 	movl   $0xf0114000,-0x20(%ebp)
f0101608:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f010160f:	77 14                	ja     f0101625 <check_boot_pgdir+0x153>
f0101611:	ff 75 e0             	pushl  -0x20(%ebp)
f0101614:	68 f8 5c 10 f0       	push   $0xf0105cf8
f0101619:	6a 66                	push   $0x66
f010161b:	68 29 5d 10 f0       	push   $0xf0105d29
f0101620:	e8 09 eb ff ff       	call   f010012e <_panic>
f0101625:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101628:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f010162e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101631:	01 ca                	add    %ecx,%edx
f0101633:	39 d0                	cmp    %edx,%eax
f0101635:	74 16                	je     f010164d <check_boot_pgdir+0x17b>
f0101637:	68 e8 5d 10 f0       	push   $0xf0105de8
f010163c:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101641:	6a 66                	push   $0x66
f0101643:	68 29 5d 10 f0       	push   $0xf0105d29
f0101648:	e8 e1 ea ff ff       	call   f010012e <_panic>
	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f010164d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101654:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f010165b:	76 89                	jbe    f01015e6 <check_boot_pgdir+0x114>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f010165d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101664:	e9 98 00 00 00       	jmp    f0101701 <check_boot_pgdir+0x22f>
		switch (i) {
f0101669:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010166c:	2d bb 03 00 00       	sub    $0x3bb,%eax
f0101671:	83 f8 04             	cmp    $0x4,%eax
f0101674:	77 29                	ja     f010169f <check_boot_pgdir+0x1cd>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
f0101676:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010167b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010167e:	c1 e2 02             	shl    $0x2,%edx
f0101681:	01 d0                	add    %edx,%eax
f0101683:	8b 00                	mov    (%eax),%eax
f0101685:	85 c0                	test   %eax,%eax
f0101687:	75 71                	jne    f01016fa <check_boot_pgdir+0x228>
f0101689:	68 5e 5e 10 f0       	push   $0xf0105e5e
f010168e:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101693:	6a 70                	push   $0x70
f0101695:	68 29 5d 10 f0       	push   $0xf0105d29
f010169a:	e8 8f ea ff ff       	call   f010012e <_panic>
			break;
		default:
			if (i >= PDX(KERNEL_BASE))
f010169f:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f01016a6:	76 29                	jbe    f01016d1 <check_boot_pgdir+0x1ff>
				assert(ptr_page_directory[i]);
f01016a8:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01016ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01016b0:	c1 e2 02             	shl    $0x2,%edx
f01016b3:	01 d0                	add    %edx,%eax
f01016b5:	8b 00                	mov    (%eax),%eax
f01016b7:	85 c0                	test   %eax,%eax
f01016b9:	75 42                	jne    f01016fd <check_boot_pgdir+0x22b>
f01016bb:	68 5e 5e 10 f0       	push   $0xf0105e5e
f01016c0:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01016c5:	6a 74                	push   $0x74
f01016c7:	68 29 5d 10 f0       	push   $0xf0105d29
f01016cc:	e8 5d ea ff ff       	call   f010012e <_panic>
			else				
				assert(ptr_page_directory[i] == 0);
f01016d1:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01016d6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01016d9:	c1 e2 02             	shl    $0x2,%edx
f01016dc:	01 d0                	add    %edx,%eax
f01016de:	8b 00                	mov    (%eax),%eax
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	74 19                	je     f01016fd <check_boot_pgdir+0x22b>
f01016e4:	68 74 5e 10 f0       	push   $0xf0105e74
f01016e9:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01016ee:	6a 76                	push   $0x76
f01016f0:	68 29 5d 10 f0       	push   $0xf0105d29
f01016f5:	e8 34 ea ff ff       	call   f010012e <_panic>
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
			break;
f01016fa:	90                   	nop
f01016fb:	eb 01                	jmp    f01016fe <check_boot_pgdir+0x22c>
		default:
			if (i >= PDX(KERNEL_BASE))
				assert(ptr_page_directory[i]);
			else				
				assert(ptr_page_directory[i] == 0);
			break;
f01016fd:	90                   	nop
	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01016fe:	ff 45 f4             	incl   -0xc(%ebp)
f0101701:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f0101708:	0f 86 5b ff ff ff    	jbe    f0101669 <check_boot_pgdir+0x197>
			else				
				assert(ptr_page_directory[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f010170e:	83 ec 0c             	sub    $0xc,%esp
f0101711:	68 90 5e 10 f0       	push   $0xf0105e90
f0101716:	e8 8e 1e 00 00       	call   f01035a9 <cprintf>
f010171b:	83 c4 10             	add    $0x10,%esp
}
f010171e:	90                   	nop
f010171f:	c9                   	leave  
f0101720:	c3                   	ret    

f0101721 <check_va2pa>:
// defined by the page directory 'ptr_page_directory'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va)
{
f0101721:	55                   	push   %ebp
f0101722:	89 e5                	mov    %esp,%ebp
f0101724:	83 ec 18             	sub    $0x18,%esp
	uint32 *p;

	ptr_page_directory = &ptr_page_directory[PDX(va)];
f0101727:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172a:	c1 e8 16             	shr    $0x16,%eax
f010172d:	c1 e0 02             	shl    $0x2,%eax
f0101730:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*ptr_page_directory & PERM_PRESENT))
f0101733:	8b 45 08             	mov    0x8(%ebp),%eax
f0101736:	8b 00                	mov    (%eax),%eax
f0101738:	83 e0 01             	and    $0x1,%eax
f010173b:	85 c0                	test   %eax,%eax
f010173d:	75 0a                	jne    f0101749 <check_va2pa+0x28>
		return ~0;
f010173f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101744:	e9 87 00 00 00       	jmp    f01017d0 <check_va2pa+0xaf>
	p = (uint32*) K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(*ptr_page_directory));
f0101749:	8b 45 08             	mov    0x8(%ebp),%eax
f010174c:	8b 00                	mov    (%eax),%eax
f010174e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101753:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101756:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101759:	c1 e8 0c             	shr    $0xc,%eax
f010175c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010175f:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0101764:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101767:	72 17                	jb     f0101780 <check_va2pa+0x5f>
f0101769:	ff 75 f4             	pushl  -0xc(%ebp)
f010176c:	68 b0 5e 10 f0       	push   $0xf0105eb0
f0101771:	68 89 00 00 00       	push   $0x89
f0101776:	68 29 5d 10 f0       	push   $0xf0105d29
f010177b:	e8 ae e9 ff ff       	call   f010012e <_panic>
f0101780:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101783:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101788:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PERM_PRESENT))
f010178b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010178e:	c1 e8 0c             	shr    $0xc,%eax
f0101791:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101796:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010179d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017a0:	01 d0                	add    %edx,%eax
f01017a2:	8b 00                	mov    (%eax),%eax
f01017a4:	83 e0 01             	and    $0x1,%eax
f01017a7:	85 c0                	test   %eax,%eax
f01017a9:	75 07                	jne    f01017b2 <check_va2pa+0x91>
		return ~0;
f01017ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01017b0:	eb 1e                	jmp    f01017d0 <check_va2pa+0xaf>
	return EXTRACT_ADDRESS(p[PTX(va)]);
f01017b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017b5:	c1 e8 0c             	shr    $0xc,%eax
f01017b8:	25 ff 03 00 00       	and    $0x3ff,%eax
f01017bd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01017c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017c7:	01 d0                	add    %edx,%eax
f01017c9:	8b 00                	mov    (%eax),%eax
f01017cb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f01017d0:	c9                   	leave  
f01017d1:	c3                   	ret    

f01017d2 <tlb_invalidate>:
		
void tlb_invalidate(uint32 *ptr_page_directory, void *virtual_address)
{
f01017d2:	55                   	push   %ebp
f01017d3:	89 e5                	mov    %esp,%ebp
f01017d5:	83 ec 10             	sub    $0x10,%esp
f01017d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017db:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01017de:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01017e1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(virtual_address);
}
f01017e4:	90                   	nop
f01017e5:	c9                   	leave  
f01017e6:	c3                   	ret    

f01017e7 <page_check>:

void page_check()
{
f01017e7:	55                   	push   %ebp
f01017e8:	89 e5                	mov    %esp,%ebp
f01017ea:	53                   	push   %ebx
f01017eb:	83 ec 24             	sub    $0x24,%esp
	struct Frame_Info *pp, *pp0, *pp1, *pp2;
	struct Linked_List fl;

	// should be able to allocate three frames_info
	pp0 = pp1 = pp2 = 0;
f01017ee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f01017f5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01017f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01017fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(allocate_frame(&pp0) == 0);
f0101801:	83 ec 0c             	sub    $0xc,%esp
f0101804:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0101807:	50                   	push   %eax
f0101808:	e8 e7 10 00 00       	call   f01028f4 <allocate_frame>
f010180d:	83 c4 10             	add    $0x10,%esp
f0101810:	85 c0                	test   %eax,%eax
f0101812:	74 19                	je     f010182d <page_check+0x46>
f0101814:	68 df 5e 10 f0       	push   $0xf0105edf
f0101819:	68 9a 5d 10 f0       	push   $0xf0105d9a
f010181e:	68 9d 00 00 00       	push   $0x9d
f0101823:	68 29 5d 10 f0       	push   $0xf0105d29
f0101828:	e8 01 e9 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp1) == 0);
f010182d:	83 ec 0c             	sub    $0xc,%esp
f0101830:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101833:	50                   	push   %eax
f0101834:	e8 bb 10 00 00       	call   f01028f4 <allocate_frame>
f0101839:	83 c4 10             	add    $0x10,%esp
f010183c:	85 c0                	test   %eax,%eax
f010183e:	74 19                	je     f0101859 <page_check+0x72>
f0101840:	68 f9 5e 10 f0       	push   $0xf0105ef9
f0101845:	68 9a 5d 10 f0       	push   $0xf0105d9a
f010184a:	68 9e 00 00 00       	push   $0x9e
f010184f:	68 29 5d 10 f0       	push   $0xf0105d29
f0101854:	e8 d5 e8 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp2) == 0);
f0101859:	83 ec 0c             	sub    $0xc,%esp
f010185c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f010185f:	50                   	push   %eax
f0101860:	e8 8f 10 00 00       	call   f01028f4 <allocate_frame>
f0101865:	83 c4 10             	add    $0x10,%esp
f0101868:	85 c0                	test   %eax,%eax
f010186a:	74 19                	je     f0101885 <page_check+0x9e>
f010186c:	68 13 5f 10 f0       	push   $0xf0105f13
f0101871:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101876:	68 9f 00 00 00       	push   $0x9f
f010187b:	68 29 5d 10 f0       	push   $0xf0105d29
f0101880:	e8 a9 e8 ff ff       	call   f010012e <_panic>

	assert(pp0);
f0101885:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101888:	85 c0                	test   %eax,%eax
f010188a:	75 19                	jne    f01018a5 <page_check+0xbe>
f010188c:	68 2d 5f 10 f0       	push   $0xf0105f2d
f0101891:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101896:	68 a1 00 00 00       	push   $0xa1
f010189b:	68 29 5d 10 f0       	push   $0xf0105d29
f01018a0:	e8 89 e8 ff ff       	call   f010012e <_panic>
	assert(pp1 && pp1 != pp0);
f01018a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018a8:	85 c0                	test   %eax,%eax
f01018aa:	74 0a                	je     f01018b6 <page_check+0xcf>
f01018ac:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01018af:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018b2:	39 c2                	cmp    %eax,%edx
f01018b4:	75 19                	jne    f01018cf <page_check+0xe8>
f01018b6:	68 31 5f 10 f0       	push   $0xf0105f31
f01018bb:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01018c0:	68 a2 00 00 00       	push   $0xa2
f01018c5:	68 29 5d 10 f0       	push   $0xf0105d29
f01018ca:	e8 5f e8 ff ff       	call   f010012e <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018cf:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01018d2:	85 c0                	test   %eax,%eax
f01018d4:	74 14                	je     f01018ea <page_check+0x103>
f01018d6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01018d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018dc:	39 c2                	cmp    %eax,%edx
f01018de:	74 0a                	je     f01018ea <page_check+0x103>
f01018e0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01018e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018e6:	39 c2                	cmp    %eax,%edx
f01018e8:	75 19                	jne    f0101903 <page_check+0x11c>
f01018ea:	68 44 5f 10 f0       	push   $0xf0105f44
f01018ef:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01018f4:	68 a3 00 00 00       	push   $0xa3
f01018f9:	68 29 5d 10 f0       	push   $0xf0105d29
f01018fe:	e8 2b e8 ff ff       	call   f010012e <_panic>

	// temporarily steal the rest of the free frames_info
	fl = free_frame_list;
f0101903:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0101908:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&free_frame_list);
f010190b:	c7 05 d8 f7 14 f0 00 	movl   $0x0,0xf014f7d8
f0101912:	00 00 00 

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101915:	83 ec 0c             	sub    $0xc,%esp
f0101918:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010191b:	50                   	push   %eax
f010191c:	e8 d3 0f 00 00       	call   f01028f4 <allocate_frame>
f0101921:	83 c4 10             	add    $0x10,%esp
f0101924:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101927:	74 19                	je     f0101942 <page_check+0x15b>
f0101929:	68 64 5f 10 f0       	push   $0xf0105f64
f010192e:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101933:	68 aa 00 00 00       	push   $0xaa
f0101938:	68 29 5d 10 f0       	push   $0xf0105d29
f010193d:	e8 ec e7 ff ff       	call   f010012e <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) < 0);
f0101942:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101945:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010194a:	6a 00                	push   $0x0
f010194c:	6a 00                	push   $0x0
f010194e:	52                   	push   %edx
f010194f:	50                   	push   %eax
f0101950:	e8 ac 11 00 00       	call   f0102b01 <map_frame>
f0101955:	83 c4 10             	add    $0x10,%esp
f0101958:	85 c0                	test   %eax,%eax
f010195a:	78 19                	js     f0101975 <page_check+0x18e>
f010195c:	68 84 5f 10 f0       	push   $0xf0105f84
f0101961:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101966:	68 ad 00 00 00       	push   $0xad
f010196b:	68 29 5d 10 f0       	push   $0xf0105d29
f0101970:	e8 b9 e7 ff ff       	call   f010012e <_panic>

	// free pp0 and try again: pp0 should be used for page table
	free_frame(pp0);
f0101975:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101978:	83 ec 0c             	sub    $0xc,%esp
f010197b:	50                   	push   %eax
f010197c:	e8 da 0f 00 00       	call   f010295b <free_frame>
f0101981:	83 c4 10             	add    $0x10,%esp
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) == 0);
f0101984:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101987:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010198c:	6a 00                	push   $0x0
f010198e:	6a 00                	push   $0x0
f0101990:	52                   	push   %edx
f0101991:	50                   	push   %eax
f0101992:	e8 6a 11 00 00       	call   f0102b01 <map_frame>
f0101997:	83 c4 10             	add    $0x10,%esp
f010199a:	85 c0                	test   %eax,%eax
f010199c:	74 19                	je     f01019b7 <page_check+0x1d0>
f010199e:	68 b4 5f 10 f0       	push   $0xf0105fb4
f01019a3:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01019a8:	68 b1 00 00 00       	push   $0xb1
f01019ad:	68 29 5d 10 f0       	push   $0xf0105d29
f01019b2:	e8 77 e7 ff ff       	call   f010012e <_panic>
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f01019b7:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01019bc:	8b 00                	mov    (%eax),%eax
f01019be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01019c3:	89 c3                	mov    %eax,%ebx
f01019c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01019c8:	83 ec 0c             	sub    $0xc,%esp
f01019cb:	50                   	push   %eax
f01019cc:	e8 05 fa ff ff       	call   f01013d6 <to_physical_address>
f01019d1:	83 c4 10             	add    $0x10,%esp
f01019d4:	39 c3                	cmp    %eax,%ebx
f01019d6:	74 19                	je     f01019f1 <page_check+0x20a>
f01019d8:	68 e4 5f 10 f0       	push   $0xf0105fe4
f01019dd:	68 9a 5d 10 f0       	push   $0xf0105d9a
f01019e2:	68 b2 00 00 00       	push   $0xb2
f01019e7:	68 29 5d 10 f0       	push   $0xf0105d29
f01019ec:	e8 3d e7 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, 0x0) == to_physical_address(pp1));
f01019f1:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01019f6:	83 ec 08             	sub    $0x8,%esp
f01019f9:	6a 00                	push   $0x0
f01019fb:	50                   	push   %eax
f01019fc:	e8 20 fd ff ff       	call   f0101721 <check_va2pa>
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	89 c3                	mov    %eax,%ebx
f0101a06:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101a09:	83 ec 0c             	sub    $0xc,%esp
f0101a0c:	50                   	push   %eax
f0101a0d:	e8 c4 f9 ff ff       	call   f01013d6 <to_physical_address>
f0101a12:	83 c4 10             	add    $0x10,%esp
f0101a15:	39 c3                	cmp    %eax,%ebx
f0101a17:	74 19                	je     f0101a32 <page_check+0x24b>
f0101a19:	68 28 60 10 f0       	push   $0xf0106028
f0101a1e:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101a23:	68 b3 00 00 00       	push   $0xb3
f0101a28:	68 29 5d 10 f0       	push   $0xf0105d29
f0101a2d:	e8 fc e6 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101a32:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101a35:	8b 40 08             	mov    0x8(%eax),%eax
f0101a38:	66 83 f8 01          	cmp    $0x1,%ax
f0101a3c:	74 19                	je     f0101a57 <page_check+0x270>
f0101a3e:	68 69 60 10 f0       	push   $0xf0106069
f0101a43:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101a48:	68 b4 00 00 00       	push   $0xb4
f0101a4d:	68 29 5d 10 f0       	push   $0xf0105d29
f0101a52:	e8 d7 e6 ff ff       	call   f010012e <_panic>
	assert(pp0->references == 1);
f0101a57:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a5a:	8b 40 08             	mov    0x8(%eax),%eax
f0101a5d:	66 83 f8 01          	cmp    $0x1,%ax
f0101a61:	74 19                	je     f0101a7c <page_check+0x295>
f0101a63:	68 7e 60 10 f0       	push   $0xf010607e
f0101a68:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101a6d:	68 b5 00 00 00       	push   $0xb5
f0101a72:	68 29 5d 10 f0       	push   $0xf0105d29
f0101a77:	e8 b2 e6 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because pp0 is already allocated for page table
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101a7c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101a7f:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101a84:	6a 00                	push   $0x0
f0101a86:	68 00 10 00 00       	push   $0x1000
f0101a8b:	52                   	push   %edx
f0101a8c:	50                   	push   %eax
f0101a8d:	e8 6f 10 00 00       	call   f0102b01 <map_frame>
f0101a92:	83 c4 10             	add    $0x10,%esp
f0101a95:	85 c0                	test   %eax,%eax
f0101a97:	74 19                	je     f0101ab2 <page_check+0x2cb>
f0101a99:	68 94 60 10 f0       	push   $0xf0106094
f0101a9e:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101aa3:	68 b8 00 00 00       	push   $0xb8
f0101aa8:	68 29 5d 10 f0       	push   $0xf0105d29
f0101aad:	e8 7c e6 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101ab2:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101ab7:	83 ec 08             	sub    $0x8,%esp
f0101aba:	68 00 10 00 00       	push   $0x1000
f0101abf:	50                   	push   %eax
f0101ac0:	e8 5c fc ff ff       	call   f0101721 <check_va2pa>
f0101ac5:	83 c4 10             	add    $0x10,%esp
f0101ac8:	89 c3                	mov    %eax,%ebx
f0101aca:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101acd:	83 ec 0c             	sub    $0xc,%esp
f0101ad0:	50                   	push   %eax
f0101ad1:	e8 00 f9 ff ff       	call   f01013d6 <to_physical_address>
f0101ad6:	83 c4 10             	add    $0x10,%esp
f0101ad9:	39 c3                	cmp    %eax,%ebx
f0101adb:	74 19                	je     f0101af6 <page_check+0x30f>
f0101add:	68 d4 60 10 f0       	push   $0xf01060d4
f0101ae2:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101ae7:	68 b9 00 00 00       	push   $0xb9
f0101aec:	68 29 5d 10 f0       	push   $0xf0105d29
f0101af1:	e8 38 e6 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101af6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101af9:	8b 40 08             	mov    0x8(%eax),%eax
f0101afc:	66 83 f8 01          	cmp    $0x1,%ax
f0101b00:	74 19                	je     f0101b1b <page_check+0x334>
f0101b02:	68 1b 61 10 f0       	push   $0xf010611b
f0101b07:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101b0c:	68 ba 00 00 00       	push   $0xba
f0101b11:	68 29 5d 10 f0       	push   $0xf0105d29
f0101b16:	e8 13 e6 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101b1b:	83 ec 0c             	sub    $0xc,%esp
f0101b1e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101b21:	50                   	push   %eax
f0101b22:	e8 cd 0d 00 00       	call   f01028f4 <allocate_frame>
f0101b27:	83 c4 10             	add    $0x10,%esp
f0101b2a:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101b2d:	74 19                	je     f0101b48 <page_check+0x361>
f0101b2f:	68 64 5f 10 f0       	push   $0xf0105f64
f0101b34:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101b39:	68 bd 00 00 00       	push   $0xbd
f0101b3e:	68 29 5d 10 f0       	push   $0xf0105d29
f0101b43:	e8 e6 e5 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because it's already there
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101b48:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101b4b:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101b50:	6a 00                	push   $0x0
f0101b52:	68 00 10 00 00       	push   $0x1000
f0101b57:	52                   	push   %edx
f0101b58:	50                   	push   %eax
f0101b59:	e8 a3 0f 00 00       	call   f0102b01 <map_frame>
f0101b5e:	83 c4 10             	add    $0x10,%esp
f0101b61:	85 c0                	test   %eax,%eax
f0101b63:	74 19                	je     f0101b7e <page_check+0x397>
f0101b65:	68 94 60 10 f0       	push   $0xf0106094
f0101b6a:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101b6f:	68 c0 00 00 00       	push   $0xc0
f0101b74:	68 29 5d 10 f0       	push   $0xf0105d29
f0101b79:	e8 b0 e5 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101b7e:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101b83:	83 ec 08             	sub    $0x8,%esp
f0101b86:	68 00 10 00 00       	push   $0x1000
f0101b8b:	50                   	push   %eax
f0101b8c:	e8 90 fb ff ff       	call   f0101721 <check_va2pa>
f0101b91:	83 c4 10             	add    $0x10,%esp
f0101b94:	89 c3                	mov    %eax,%ebx
f0101b96:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101b99:	83 ec 0c             	sub    $0xc,%esp
f0101b9c:	50                   	push   %eax
f0101b9d:	e8 34 f8 ff ff       	call   f01013d6 <to_physical_address>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	39 c3                	cmp    %eax,%ebx
f0101ba7:	74 19                	je     f0101bc2 <page_check+0x3db>
f0101ba9:	68 d4 60 10 f0       	push   $0xf01060d4
f0101bae:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101bb3:	68 c1 00 00 00       	push   $0xc1
f0101bb8:	68 29 5d 10 f0       	push   $0xf0105d29
f0101bbd:	e8 6c e5 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101bc2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101bc5:	8b 40 08             	mov    0x8(%eax),%eax
f0101bc8:	66 83 f8 01          	cmp    $0x1,%ax
f0101bcc:	74 19                	je     f0101be7 <page_check+0x400>
f0101bce:	68 1b 61 10 f0       	push   $0xf010611b
f0101bd3:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101bd8:	68 c2 00 00 00       	push   $0xc2
f0101bdd:	68 29 5d 10 f0       	push   $0xf0105d29
f0101be2:	e8 47 e5 ff ff       	call   f010012e <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in map_frame
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101be7:	83 ec 0c             	sub    $0xc,%esp
f0101bea:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101bed:	50                   	push   %eax
f0101bee:	e8 01 0d 00 00       	call   f01028f4 <allocate_frame>
f0101bf3:	83 c4 10             	add    $0x10,%esp
f0101bf6:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101bf9:	74 19                	je     f0101c14 <page_check+0x42d>
f0101bfb:	68 64 5f 10 f0       	push   $0xf0105f64
f0101c00:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101c05:	68 c6 00 00 00       	push   $0xc6
f0101c0a:	68 29 5d 10 f0       	push   $0xf0105d29
f0101c0f:	e8 1a e5 ff ff       	call   f010012e <_panic>

	// should not be able to map at PTSIZE because need free frame for page table
	assert(map_frame(ptr_page_directory, pp0, (void*) PTSIZE, 0) < 0);
f0101c14:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101c17:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101c1c:	6a 00                	push   $0x0
f0101c1e:	68 00 00 40 00       	push   $0x400000
f0101c23:	52                   	push   %edx
f0101c24:	50                   	push   %eax
f0101c25:	e8 d7 0e 00 00       	call   f0102b01 <map_frame>
f0101c2a:	83 c4 10             	add    $0x10,%esp
f0101c2d:	85 c0                	test   %eax,%eax
f0101c2f:	78 19                	js     f0101c4a <page_check+0x463>
f0101c31:	68 30 61 10 f0       	push   $0xf0106130
f0101c36:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101c3b:	68 c9 00 00 00       	push   $0xc9
f0101c40:	68 29 5d 10 f0       	push   $0xf0105d29
f0101c45:	e8 e4 e4 ff ff       	call   f010012e <_panic>

	// insert pp1 at PAGE_SIZE (replacing pp2)
	assert(map_frame(ptr_page_directory, pp1, (void*) PAGE_SIZE, 0) == 0);
f0101c4a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101c4d:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101c52:	6a 00                	push   $0x0
f0101c54:	68 00 10 00 00       	push   $0x1000
f0101c59:	52                   	push   %edx
f0101c5a:	50                   	push   %eax
f0101c5b:	e8 a1 0e 00 00       	call   f0102b01 <map_frame>
f0101c60:	83 c4 10             	add    $0x10,%esp
f0101c63:	85 c0                	test   %eax,%eax
f0101c65:	74 19                	je     f0101c80 <page_check+0x499>
f0101c67:	68 6c 61 10 f0       	push   $0xf010616c
f0101c6c:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101c71:	68 cc 00 00 00       	push   $0xcc
f0101c76:	68 29 5d 10 f0       	push   $0xf0105d29
f0101c7b:	e8 ae e4 ff ff       	call   f010012e <_panic>

	// should have pp1 at both 0 and PAGE_SIZE, pp2 nowhere, ...
	assert(check_va2pa(ptr_page_directory, 0) == to_physical_address(pp1));
f0101c80:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101c85:	83 ec 08             	sub    $0x8,%esp
f0101c88:	6a 00                	push   $0x0
f0101c8a:	50                   	push   %eax
f0101c8b:	e8 91 fa ff ff       	call   f0101721 <check_va2pa>
f0101c90:	83 c4 10             	add    $0x10,%esp
f0101c93:	89 c3                	mov    %eax,%ebx
f0101c95:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c98:	83 ec 0c             	sub    $0xc,%esp
f0101c9b:	50                   	push   %eax
f0101c9c:	e8 35 f7 ff ff       	call   f01013d6 <to_physical_address>
f0101ca1:	83 c4 10             	add    $0x10,%esp
f0101ca4:	39 c3                	cmp    %eax,%ebx
f0101ca6:	74 19                	je     f0101cc1 <page_check+0x4da>
f0101ca8:	68 ac 61 10 f0       	push   $0xf01061ac
f0101cad:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101cb2:	68 cf 00 00 00       	push   $0xcf
f0101cb7:	68 29 5d 10 f0       	push   $0xf0105d29
f0101cbc:	e8 6d e4 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101cc1:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101cc6:	83 ec 08             	sub    $0x8,%esp
f0101cc9:	68 00 10 00 00       	push   $0x1000
f0101cce:	50                   	push   %eax
f0101ccf:	e8 4d fa ff ff       	call   f0101721 <check_va2pa>
f0101cd4:	83 c4 10             	add    $0x10,%esp
f0101cd7:	89 c3                	mov    %eax,%ebx
f0101cd9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101cdc:	83 ec 0c             	sub    $0xc,%esp
f0101cdf:	50                   	push   %eax
f0101ce0:	e8 f1 f6 ff ff       	call   f01013d6 <to_physical_address>
f0101ce5:	83 c4 10             	add    $0x10,%esp
f0101ce8:	39 c3                	cmp    %eax,%ebx
f0101cea:	74 19                	je     f0101d05 <page_check+0x51e>
f0101cec:	68 ec 61 10 f0       	push   $0xf01061ec
f0101cf1:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101cf6:	68 d0 00 00 00       	push   $0xd0
f0101cfb:	68 29 5d 10 f0       	push   $0xf0105d29
f0101d00:	e8 29 e4 ff ff       	call   f010012e <_panic>
	// ... and ref counts should reflect this
	assert(pp1->references == 2);
f0101d05:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d08:	8b 40 08             	mov    0x8(%eax),%eax
f0101d0b:	66 83 f8 02          	cmp    $0x2,%ax
f0101d0f:	74 19                	je     f0101d2a <page_check+0x543>
f0101d11:	68 33 62 10 f0       	push   $0xf0106233
f0101d16:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101d1b:	68 d2 00 00 00       	push   $0xd2
f0101d20:	68 29 5d 10 f0       	push   $0xf0105d29
f0101d25:	e8 04 e4 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101d2a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101d2d:	8b 40 08             	mov    0x8(%eax),%eax
f0101d30:	66 85 c0             	test   %ax,%ax
f0101d33:	74 19                	je     f0101d4e <page_check+0x567>
f0101d35:	68 48 62 10 f0       	push   $0xf0106248
f0101d3a:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101d3f:	68 d3 00 00 00       	push   $0xd3
f0101d44:	68 29 5d 10 f0       	push   $0xf0105d29
f0101d49:	e8 e0 e3 ff ff       	call   f010012e <_panic>

	// pp2 should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp2);
f0101d4e:	83 ec 0c             	sub    $0xc,%esp
f0101d51:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101d54:	50                   	push   %eax
f0101d55:	e8 9a 0b 00 00       	call   f01028f4 <allocate_frame>
f0101d5a:	83 c4 10             	add    $0x10,%esp
f0101d5d:	85 c0                	test   %eax,%eax
f0101d5f:	75 0a                	jne    f0101d6b <page_check+0x584>
f0101d61:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101d64:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101d67:	39 c2                	cmp    %eax,%edx
f0101d69:	74 19                	je     f0101d84 <page_check+0x59d>
f0101d6b:	68 60 62 10 f0       	push   $0xf0106260
f0101d70:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101d75:	68 d6 00 00 00       	push   $0xd6
f0101d7a:	68 29 5d 10 f0       	push   $0xf0105d29
f0101d7f:	e8 aa e3 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at 0 should keep pp1 at PAGE_SIZE
	unmap_frame(ptr_page_directory, 0x0);
f0101d84:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101d89:	83 ec 08             	sub    $0x8,%esp
f0101d8c:	6a 00                	push   $0x0
f0101d8e:	50                   	push   %eax
f0101d8f:	e8 8b 0e 00 00       	call   f0102c1f <unmap_frame>
f0101d94:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101d97:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101d9c:	83 ec 08             	sub    $0x8,%esp
f0101d9f:	6a 00                	push   $0x0
f0101da1:	50                   	push   %eax
f0101da2:	e8 7a f9 ff ff       	call   f0101721 <check_va2pa>
f0101da7:	83 c4 10             	add    $0x10,%esp
f0101daa:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dad:	74 19                	je     f0101dc8 <page_check+0x5e1>
f0101daf:	68 88 62 10 f0       	push   $0xf0106288
f0101db4:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101db9:	68 da 00 00 00       	push   $0xda
f0101dbe:	68 29 5d 10 f0       	push   $0xf0105d29
f0101dc3:	e8 66 e3 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101dc8:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101dcd:	83 ec 08             	sub    $0x8,%esp
f0101dd0:	68 00 10 00 00       	push   $0x1000
f0101dd5:	50                   	push   %eax
f0101dd6:	e8 46 f9 ff ff       	call   f0101721 <check_va2pa>
f0101ddb:	83 c4 10             	add    $0x10,%esp
f0101dde:	89 c3                	mov    %eax,%ebx
f0101de0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101de3:	83 ec 0c             	sub    $0xc,%esp
f0101de6:	50                   	push   %eax
f0101de7:	e8 ea f5 ff ff       	call   f01013d6 <to_physical_address>
f0101dec:	83 c4 10             	add    $0x10,%esp
f0101def:	39 c3                	cmp    %eax,%ebx
f0101df1:	74 19                	je     f0101e0c <page_check+0x625>
f0101df3:	68 ec 61 10 f0       	push   $0xf01061ec
f0101df8:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101dfd:	68 db 00 00 00       	push   $0xdb
f0101e02:	68 29 5d 10 f0       	push   $0xf0105d29
f0101e07:	e8 22 e3 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101e0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e0f:	8b 40 08             	mov    0x8(%eax),%eax
f0101e12:	66 83 f8 01          	cmp    $0x1,%ax
f0101e16:	74 19                	je     f0101e31 <page_check+0x64a>
f0101e18:	68 69 60 10 f0       	push   $0xf0106069
f0101e1d:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101e22:	68 dc 00 00 00       	push   $0xdc
f0101e27:	68 29 5d 10 f0       	push   $0xf0105d29
f0101e2c:	e8 fd e2 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101e31:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101e34:	8b 40 08             	mov    0x8(%eax),%eax
f0101e37:	66 85 c0             	test   %ax,%ax
f0101e3a:	74 19                	je     f0101e55 <page_check+0x66e>
f0101e3c:	68 48 62 10 f0       	push   $0xf0106248
f0101e41:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101e46:	68 dd 00 00 00       	push   $0xdd
f0101e4b:	68 29 5d 10 f0       	push   $0xf0105d29
f0101e50:	e8 d9 e2 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at PAGE_SIZE should free it
	unmap_frame(ptr_page_directory, (void*) PAGE_SIZE);
f0101e55:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101e5a:	83 ec 08             	sub    $0x8,%esp
f0101e5d:	68 00 10 00 00       	push   $0x1000
f0101e62:	50                   	push   %eax
f0101e63:	e8 b7 0d 00 00       	call   f0102c1f <unmap_frame>
f0101e68:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101e6b:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101e70:	83 ec 08             	sub    $0x8,%esp
f0101e73:	6a 00                	push   $0x0
f0101e75:	50                   	push   %eax
f0101e76:	e8 a6 f8 ff ff       	call   f0101721 <check_va2pa>
f0101e7b:	83 c4 10             	add    $0x10,%esp
f0101e7e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e81:	74 19                	je     f0101e9c <page_check+0x6b5>
f0101e83:	68 88 62 10 f0       	push   $0xf0106288
f0101e88:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101e8d:	68 e1 00 00 00       	push   $0xe1
f0101e92:	68 29 5d 10 f0       	push   $0xf0105d29
f0101e97:	e8 92 e2 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == ~0);
f0101e9c:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101ea1:	83 ec 08             	sub    $0x8,%esp
f0101ea4:	68 00 10 00 00       	push   $0x1000
f0101ea9:	50                   	push   %eax
f0101eaa:	e8 72 f8 ff ff       	call   f0101721 <check_va2pa>
f0101eaf:	83 c4 10             	add    $0x10,%esp
f0101eb2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eb5:	74 19                	je     f0101ed0 <page_check+0x6e9>
f0101eb7:	68 b4 62 10 f0       	push   $0xf01062b4
f0101ebc:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101ec1:	68 e2 00 00 00       	push   $0xe2
f0101ec6:	68 29 5d 10 f0       	push   $0xf0105d29
f0101ecb:	e8 5e e2 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 0);
f0101ed0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ed3:	8b 40 08             	mov    0x8(%eax),%eax
f0101ed6:	66 85 c0             	test   %ax,%ax
f0101ed9:	74 19                	je     f0101ef4 <page_check+0x70d>
f0101edb:	68 e5 62 10 f0       	push   $0xf01062e5
f0101ee0:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101ee5:	68 e3 00 00 00       	push   $0xe3
f0101eea:	68 29 5d 10 f0       	push   $0xf0105d29
f0101eef:	e8 3a e2 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101ef4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101ef7:	8b 40 08             	mov    0x8(%eax),%eax
f0101efa:	66 85 c0             	test   %ax,%ax
f0101efd:	74 19                	je     f0101f18 <page_check+0x731>
f0101eff:	68 48 62 10 f0       	push   $0xf0106248
f0101f04:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101f09:	68 e4 00 00 00       	push   $0xe4
f0101f0e:	68 29 5d 10 f0       	push   $0xf0105d29
f0101f13:	e8 16 e2 ff ff       	call   f010012e <_panic>

	// so it should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp1);
f0101f18:	83 ec 0c             	sub    $0xc,%esp
f0101f1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101f1e:	50                   	push   %eax
f0101f1f:	e8 d0 09 00 00       	call   f01028f4 <allocate_frame>
f0101f24:	83 c4 10             	add    $0x10,%esp
f0101f27:	85 c0                	test   %eax,%eax
f0101f29:	75 0a                	jne    f0101f35 <page_check+0x74e>
f0101f2b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101f2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f31:	39 c2                	cmp    %eax,%edx
f0101f33:	74 19                	je     f0101f4e <page_check+0x767>
f0101f35:	68 fc 62 10 f0       	push   $0xf01062fc
f0101f3a:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101f3f:	68 e7 00 00 00       	push   $0xe7
f0101f44:	68 29 5d 10 f0       	push   $0xf0105d29
f0101f49:	e8 e0 e1 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101f4e:	83 ec 0c             	sub    $0xc,%esp
f0101f51:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101f54:	50                   	push   %eax
f0101f55:	e8 9a 09 00 00       	call   f01028f4 <allocate_frame>
f0101f5a:	83 c4 10             	add    $0x10,%esp
f0101f5d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101f60:	74 19                	je     f0101f7b <page_check+0x794>
f0101f62:	68 64 5f 10 f0       	push   $0xf0105f64
f0101f67:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101f6c:	68 ea 00 00 00       	push   $0xea
f0101f71:	68 29 5d 10 f0       	push   $0xf0105d29
f0101f76:	e8 b3 e1 ff ff       	call   f010012e <_panic>

	// forcibly take pp0 back
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101f7b:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101f80:	8b 00                	mov    (%eax),%eax
f0101f82:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101f87:	89 c3                	mov    %eax,%ebx
f0101f89:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101f8c:	83 ec 0c             	sub    $0xc,%esp
f0101f8f:	50                   	push   %eax
f0101f90:	e8 41 f4 ff ff       	call   f01013d6 <to_physical_address>
f0101f95:	83 c4 10             	add    $0x10,%esp
f0101f98:	39 c3                	cmp    %eax,%ebx
f0101f9a:	74 19                	je     f0101fb5 <page_check+0x7ce>
f0101f9c:	68 e4 5f 10 f0       	push   $0xf0105fe4
f0101fa1:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101fa6:	68 ed 00 00 00       	push   $0xed
f0101fab:	68 29 5d 10 f0       	push   $0xf0105d29
f0101fb0:	e8 79 e1 ff ff       	call   f010012e <_panic>
	ptr_page_directory[0] = 0;
f0101fb5:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101fba:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->references == 1);
f0101fc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101fc3:	8b 40 08             	mov    0x8(%eax),%eax
f0101fc6:	66 83 f8 01          	cmp    $0x1,%ax
f0101fca:	74 19                	je     f0101fe5 <page_check+0x7fe>
f0101fcc:	68 7e 60 10 f0       	push   $0xf010607e
f0101fd1:	68 9a 5d 10 f0       	push   $0xf0105d9a
f0101fd6:	68 ef 00 00 00       	push   $0xef
f0101fdb:	68 29 5d 10 f0       	push   $0xf0105d29
f0101fe0:	e8 49 e1 ff ff       	call   f010012e <_panic>
	pp0->references = 0;
f0101fe5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101fe8:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	free_frame_list = fl;
f0101fee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ff1:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8

	// free the frames_info we took
	free_frame(pp0);
f0101ff6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ff9:	83 ec 0c             	sub    $0xc,%esp
f0101ffc:	50                   	push   %eax
f0101ffd:	e8 59 09 00 00       	call   f010295b <free_frame>
f0102002:	83 c4 10             	add    $0x10,%esp
	free_frame(pp1);
f0102005:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102008:	83 ec 0c             	sub    $0xc,%esp
f010200b:	50                   	push   %eax
f010200c:	e8 4a 09 00 00       	call   f010295b <free_frame>
f0102011:	83 c4 10             	add    $0x10,%esp
	free_frame(pp2);
f0102014:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102017:	83 ec 0c             	sub    $0xc,%esp
f010201a:	50                   	push   %eax
f010201b:	e8 3b 09 00 00       	call   f010295b <free_frame>
f0102020:	83 c4 10             	add    $0x10,%esp

	cprintf("page_check() succeeded!\n");
f0102023:	83 ec 0c             	sub    $0xc,%esp
f0102026:	68 22 63 10 f0       	push   $0xf0106322
f010202b:	e8 79 15 00 00       	call   f01035a9 <cprintf>
f0102030:	83 c4 10             	add    $0x10,%esp
}
f0102033:	90                   	nop
f0102034:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102037:	c9                   	leave  
f0102038:	c3                   	ret    

f0102039 <turn_on_paging>:

void turn_on_paging()
{
f0102039:	55                   	push   %ebp
f010203a:	89 e5                	mov    %esp,%ebp
f010203c:	83 ec 20             	sub    $0x20,%esp
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA (KERNEL_BASE), i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	ptr_page_directory[0] = ptr_page_directory[PDX(KERNEL_BASE)];
f010203f:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102044:	8b 15 e4 f7 14 f0    	mov    0xf014f7e4,%edx
f010204a:	8b 92 00 0f 00 00    	mov    0xf00(%edx),%edx
f0102050:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(phys_page_directory);
f0102052:	a1 e8 f7 14 f0       	mov    0xf014f7e8,%eax
f0102057:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010205a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010205d:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32
rcr0(void)
{
	uint32 val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102060:	0f 20 c0             	mov    %cr0,%eax
f0102063:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
f0102066:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// Turn on paging.
	uint32 cr0;
	cr0 = rcr0();
f0102069:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f010206c:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f0102073:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f0102077:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010207a:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static __inline void
lcr0(uint32 val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010207d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102080:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNEL_BASE+x => x => x.
	// (x < 4MB so uses paging ptr_page_directory[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f0102083:	0f 01 15 90 c6 11 f0 	lgdtl  0xf011c690
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010208a:	b8 23 00 00 00       	mov    $0x23,%eax
f010208f:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102091:	b8 23 00 00 00       	mov    $0x23,%eax
f0102096:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102098:	b8 10 00 00 00       	mov    $0x10,%eax
f010209d:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010209f:	b8 10 00 00 00       	mov    $0x10,%eax
f01020a4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01020a6:	b8 10 00 00 00       	mov    $0x10,%eax
f01020ab:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01020ad:	ea b4 20 10 f0 08 00 	ljmp   $0x8,$0xf01020b4
	asm volatile("lldt %%ax" :: "a" (0));
f01020b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01020b9:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNEL_BASE + x => KERNEL_BASE + x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	ptr_page_directory[0] = 0;
f01020bc:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01020c1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the ptr_page_directory[0] mapping.
	lcr3(phys_page_directory);
f01020c7:	a1 e8 f7 14 f0       	mov    0xf014f7e8,%eax
f01020cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01020cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020d2:	0f 22 d8             	mov    %eax,%cr3
}
f01020d5:	90                   	nop
f01020d6:	c9                   	leave  
f01020d7:	c3                   	ret    

f01020d8 <setup_listing_to_all_page_tables_entries>:

void setup_listing_to_all_page_tables_entries()
{
f01020d8:	55                   	push   %ebp
f01020d9:	89 e5                	mov    %esp,%ebp
f01020db:	83 ec 18             	sub    $0x18,%esp
	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.

	// Permissions: kernel RW, user NONE
	uint32 phys_frame_address = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01020de:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01020e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01020e6:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f01020ed:	77 17                	ja     f0102106 <setup_listing_to_all_page_tables_entries+0x2e>
f01020ef:	ff 75 f4             	pushl  -0xc(%ebp)
f01020f2:	68 f8 5c 10 f0       	push   $0xf0105cf8
f01020f7:	68 39 01 00 00       	push   $0x139
f01020fc:	68 29 5d 10 f0       	push   $0xf0105d29
f0102101:	e8 28 e0 ff ff       	call   f010012e <_panic>
f0102106:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102109:	05 00 00 00 10       	add    $0x10000000,%eax
f010210e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ptr_page_directory[PDX(VPT)] = CONSTRUCT_ENTRY(phys_frame_address , PERM_PRESENT | PERM_WRITEABLE);
f0102111:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102116:	05 fc 0e 00 00       	add    $0xefc,%eax
f010211b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010211e:	83 ca 03             	or     $0x3,%edx
f0102121:	89 10                	mov    %edx,(%eax)

	// same for UVPT
	//Permissions: kernel R, user R
	ptr_page_directory[PDX(UVPT)] = K_PHYSICAL_ADDRESS(ptr_page_directory)|PERM_USER|PERM_PRESENT;
f0102123:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102128:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f010212e:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102133:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102136:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f010213d:	77 17                	ja     f0102156 <setup_listing_to_all_page_tables_entries+0x7e>
f010213f:	ff 75 ec             	pushl  -0x14(%ebp)
f0102142:	68 f8 5c 10 f0       	push   $0xf0105cf8
f0102147:	68 3e 01 00 00       	push   $0x13e
f010214c:	68 29 5d 10 f0       	push   $0xf0105d29
f0102151:	e8 d8 df ff ff       	call   f010012e <_panic>
f0102156:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102159:	05 00 00 00 10       	add    $0x10000000,%eax
f010215e:	83 c8 05             	or     $0x5,%eax
f0102161:	89 02                	mov    %eax,(%edx)

}
f0102163:	90                   	nop
f0102164:	c9                   	leave  
f0102165:	c3                   	ret    

f0102166 <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int envid2env(int32  envid, struct Env **env_store, bool checkperm)
{
f0102166:	55                   	push   %ebp
f0102167:	89 e5                	mov    %esp,%ebp
f0102169:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010216c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102170:	75 15                	jne    f0102187 <envid2env+0x21>
		*env_store = curenv;
f0102172:	8b 15 50 ef 14 f0    	mov    0xf014ef50,%edx
f0102178:	8b 45 0c             	mov    0xc(%ebp),%eax
f010217b:	89 10                	mov    %edx,(%eax)
		return 0;
f010217d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102182:	e9 8c 00 00 00       	jmp    f0102213 <envid2env+0xad>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102187:	8b 15 4c ef 14 f0    	mov    0xf014ef4c,%edx
f010218d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102190:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102195:	89 c1                	mov    %eax,%ecx
f0102197:	89 c8                	mov    %ecx,%eax
f0102199:	c1 e0 02             	shl    $0x2,%eax
f010219c:	01 c8                	add    %ecx,%eax
f010219e:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01021a5:	01 c8                	add    %ecx,%eax
f01021a7:	c1 e0 02             	shl    $0x2,%eax
f01021aa:	01 d0                	add    %edx,%eax
f01021ac:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01021af:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01021b2:	8b 40 54             	mov    0x54(%eax),%eax
f01021b5:	85 c0                	test   %eax,%eax
f01021b7:	74 0b                	je     f01021c4 <envid2env+0x5e>
f01021b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01021bc:	8b 40 4c             	mov    0x4c(%eax),%eax
f01021bf:	3b 45 08             	cmp    0x8(%ebp),%eax
f01021c2:	74 10                	je     f01021d4 <envid2env+0x6e>
		*env_store = 0;
f01021c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01021c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01021cd:	b8 02 00 00 00       	mov    $0x2,%eax
f01021d2:	eb 3f                	jmp    f0102213 <envid2env+0xad>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01021d4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01021d8:	74 2c                	je     f0102206 <envid2env+0xa0>
f01021da:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f01021df:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f01021e2:	74 22                	je     f0102206 <envid2env+0xa0>
f01021e4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01021e7:	8b 50 50             	mov    0x50(%eax),%edx
f01021ea:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f01021ef:	8b 40 4c             	mov    0x4c(%eax),%eax
f01021f2:	39 c2                	cmp    %eax,%edx
f01021f4:	74 10                	je     f0102206 <envid2env+0xa0>
		*env_store = 0;
f01021f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01021f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01021ff:	b8 02 00 00 00       	mov    $0x2,%eax
f0102204:	eb 0d                	jmp    f0102213 <envid2env+0xad>
	}

	*env_store = e;
f0102206:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102209:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010220c:	89 10                	mov    %edx,(%eax)
	return 0;
f010220e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102213:	c9                   	leave  
f0102214:	c3                   	ret    

f0102215 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0102215:	55                   	push   %ebp
f0102216:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0102218:	8b 45 08             	mov    0x8(%ebp),%eax
f010221b:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f0102221:	29 d0                	sub    %edx,%eax
f0102223:	c1 f8 02             	sar    $0x2,%eax
f0102226:	89 c2                	mov    %eax,%edx
f0102228:	89 d0                	mov    %edx,%eax
f010222a:	c1 e0 02             	shl    $0x2,%eax
f010222d:	01 d0                	add    %edx,%eax
f010222f:	c1 e0 02             	shl    $0x2,%eax
f0102232:	01 d0                	add    %edx,%eax
f0102234:	c1 e0 02             	shl    $0x2,%eax
f0102237:	01 d0                	add    %edx,%eax
f0102239:	89 c1                	mov    %eax,%ecx
f010223b:	c1 e1 08             	shl    $0x8,%ecx
f010223e:	01 c8                	add    %ecx,%eax
f0102240:	89 c1                	mov    %eax,%ecx
f0102242:	c1 e1 10             	shl    $0x10,%ecx
f0102245:	01 c8                	add    %ecx,%eax
f0102247:	01 c0                	add    %eax,%eax
f0102249:	01 d0                	add    %edx,%eax
}
f010224b:	5d                   	pop    %ebp
f010224c:	c3                   	ret    

f010224d <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f010224d:	55                   	push   %ebp
f010224e:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0102250:	ff 75 08             	pushl  0x8(%ebp)
f0102253:	e8 bd ff ff ff       	call   f0102215 <to_frame_number>
f0102258:	83 c4 04             	add    $0x4,%esp
f010225b:	c1 e0 0c             	shl    $0xc,%eax
}
f010225e:	c9                   	leave  
f010225f:	c3                   	ret    

f0102260 <to_frame_info>:

static inline struct Frame_Info* to_frame_info(uint32 physical_address)
{
f0102260:	55                   	push   %ebp
f0102261:	89 e5                	mov    %esp,%ebp
f0102263:	83 ec 08             	sub    $0x8,%esp
	if (PPN(physical_address) >= number_of_frames)
f0102266:	8b 45 08             	mov    0x8(%ebp),%eax
f0102269:	c1 e8 0c             	shr    $0xc,%eax
f010226c:	89 c2                	mov    %eax,%edx
f010226e:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0102273:	39 c2                	cmp    %eax,%edx
f0102275:	72 14                	jb     f010228b <to_frame_info+0x2b>
		panic("to_frame_info called with invalid pa");
f0102277:	83 ec 04             	sub    $0x4,%esp
f010227a:	68 3c 63 10 f0       	push   $0xf010633c
f010227f:	6a 39                	push   $0x39
f0102281:	68 61 63 10 f0       	push   $0xf0106361
f0102286:	e8 a3 de ff ff       	call   f010012e <_panic>
	return &frames_info[PPN(physical_address)];
f010228b:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f0102291:	8b 45 08             	mov    0x8(%ebp),%eax
f0102294:	c1 e8 0c             	shr    $0xc,%eax
f0102297:	89 c1                	mov    %eax,%ecx
f0102299:	89 c8                	mov    %ecx,%eax
f010229b:	01 c0                	add    %eax,%eax
f010229d:	01 c8                	add    %ecx,%eax
f010229f:	c1 e0 02             	shl    $0x2,%eax
f01022a2:	01 d0                	add    %edx,%eax
}
f01022a4:	c9                   	leave  
f01022a5:	c3                   	ret    

f01022a6 <initialize_kernel_VM>:
//
// From USER_TOP to USER_LIMIT, the user is allowed to read but not write.
// Above USER_LIMIT the user cannot read (or write).

void initialize_kernel_VM()
{
f01022a6:	55                   	push   %ebp
f01022a7:	89 e5                	mov    %esp,%ebp
f01022a9:	83 ec 28             	sub    $0x28,%esp
	//panic("initialize_kernel_VM: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	ptr_page_directory = boot_allocate_space(PAGE_SIZE, PAGE_SIZE);
f01022ac:	83 ec 08             	sub    $0x8,%esp
f01022af:	68 00 10 00 00       	push   $0x1000
f01022b4:	68 00 10 00 00       	push   $0x1000
f01022b9:	e8 ca 01 00 00       	call   f0102488 <boot_allocate_space>
f01022be:	83 c4 10             	add    $0x10,%esp
f01022c1:	a3 e4 f7 14 f0       	mov    %eax,0xf014f7e4
	memset(ptr_page_directory, 0, PAGE_SIZE);
f01022c6:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01022cb:	83 ec 04             	sub    $0x4,%esp
f01022ce:	68 00 10 00 00       	push   $0x1000
f01022d3:	6a 00                	push   $0x0
f01022d5:	50                   	push   %eax
f01022d6:	e8 b0 29 00 00       	call   f0104c8b <memset>
f01022db:	83 c4 10             	add    $0x10,%esp
	phys_page_directory = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01022de:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01022e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01022e6:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f01022ed:	77 14                	ja     f0102303 <initialize_kernel_VM+0x5d>
f01022ef:	ff 75 f4             	pushl  -0xc(%ebp)
f01022f2:	68 7c 63 10 f0       	push   $0xf010637c
f01022f7:	6a 3c                	push   $0x3c
f01022f9:	68 ad 63 10 f0       	push   $0xf01063ad
f01022fe:	e8 2b de ff ff       	call   f010012e <_panic>
f0102303:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102306:	05 00 00 00 10       	add    $0x10000000,%eax
f010230b:	a3 e8 f7 14 f0       	mov    %eax,0xf014f7e8
	// Map the kernel stack with VA range :
	//  [KERNEL_STACK_TOP-KERNEL_STACK_SIZE, KERNEL_STACK_TOP), 
	// to physical address : "phys_stack_bottom".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_range(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE, KERNEL_STACK_SIZE, K_PHYSICAL_ADDRESS(ptr_stack_bottom), PERM_WRITEABLE) ;
f0102310:	c7 45 f0 00 40 11 f0 	movl   $0xf0114000,-0x10(%ebp)
f0102317:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f010231e:	77 14                	ja     f0102334 <initialize_kernel_VM+0x8e>
f0102320:	ff 75 f0             	pushl  -0x10(%ebp)
f0102323:	68 7c 63 10 f0       	push   $0xf010637c
f0102328:	6a 44                	push   $0x44
f010232a:	68 ad 63 10 f0       	push   $0xf01063ad
f010232f:	e8 fa dd ff ff       	call   f010012e <_panic>
f0102334:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102337:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010233d:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102342:	83 ec 0c             	sub    $0xc,%esp
f0102345:	6a 02                	push   $0x2
f0102347:	52                   	push   %edx
f0102348:	68 00 80 00 00       	push   $0x8000
f010234d:	68 00 80 bf ef       	push   $0xefbf8000
f0102352:	50                   	push   %eax
f0102353:	e8 92 01 00 00       	call   f01024ea <boot_map_range>
f0102358:	83 c4 20             	add    $0x20,%esp
	//      the PA range [0, 2^32 - KERNEL_BASE)
	// We might not have 2^32 - KERNEL_BASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_range(ptr_page_directory, KERNEL_BASE, 0xFFFFFFFF - KERNEL_BASE, 0, PERM_WRITEABLE) ;
f010235b:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102360:	83 ec 0c             	sub    $0xc,%esp
f0102363:	6a 02                	push   $0x2
f0102365:	6a 00                	push   $0x0
f0102367:	68 ff ff ff 0f       	push   $0xfffffff
f010236c:	68 00 00 00 f0       	push   $0xf0000000
f0102371:	50                   	push   %eax
f0102372:	e8 73 01 00 00       	call   f01024ea <boot_map_range>
f0102377:	83 c4 20             	add    $0x20,%esp
	// Permissions:
	//    - frames_info -- kernel RW, user NONE
	//    - the image mapped at READ_ONLY_FRAMES_INFO  -- kernel R, user R
	// Your code goes here:
	uint32 array_size;
	array_size = number_of_frames * sizeof(struct Frame_Info) ;
f010237a:	8b 15 c8 f7 14 f0    	mov    0xf014f7c8,%edx
f0102380:	89 d0                	mov    %edx,%eax
f0102382:	01 c0                	add    %eax,%eax
f0102384:	01 d0                	add    %edx,%eax
f0102386:	c1 e0 02             	shl    $0x2,%eax
f0102389:	89 45 ec             	mov    %eax,-0x14(%ebp)
	frames_info = boot_allocate_space(array_size, PAGE_SIZE);
f010238c:	83 ec 08             	sub    $0x8,%esp
f010238f:	68 00 10 00 00       	push   $0x1000
f0102394:	ff 75 ec             	pushl  -0x14(%ebp)
f0102397:	e8 ec 00 00 00       	call   f0102488 <boot_allocate_space>
f010239c:	83 c4 10             	add    $0x10,%esp
f010239f:	a3 dc f7 14 f0       	mov    %eax,0xf014f7dc
	boot_map_range(ptr_page_directory, READ_ONLY_FRAMES_INFO, array_size, K_PHYSICAL_ADDRESS(frames_info), PERM_USER) ;
f01023a4:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f01023a9:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01023ac:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f01023b3:	77 14                	ja     f01023c9 <initialize_kernel_VM+0x123>
f01023b5:	ff 75 e8             	pushl  -0x18(%ebp)
f01023b8:	68 7c 63 10 f0       	push   $0xf010637c
f01023bd:	6a 5f                	push   $0x5f
f01023bf:	68 ad 63 10 f0       	push   $0xf01063ad
f01023c4:	e8 65 dd ff ff       	call   f010012e <_panic>
f01023c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01023cc:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01023d2:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01023d7:	83 ec 0c             	sub    $0xc,%esp
f01023da:	6a 04                	push   $0x4
f01023dc:	52                   	push   %edx
f01023dd:	ff 75 ec             	pushl  -0x14(%ebp)
f01023e0:	68 00 00 00 ef       	push   $0xef000000
f01023e5:	50                   	push   %eax
f01023e6:	e8 ff 00 00 00       	call   f01024ea <boot_map_range>
f01023eb:	83 c4 20             	add    $0x20,%esp


	// This allows the kernel & user to access any page table entry using a
	// specified VA for each: VPT for kernel and UVPT for User.
	setup_listing_to_all_page_tables_entries();
f01023ee:	e8 e5 fc ff ff       	call   f01020d8 <setup_listing_to_all_page_tables_entries>
	// Permissions:
	//    - envs itself -- kernel RW, user NONE
	//    - the image of envs mapped at UENVS  -- kernel R, user R

	// LAB 3: Your code here.
	int envs_size = NENV * sizeof(struct Env) ;
f01023f3:	c7 45 e4 00 90 01 00 	movl   $0x19000,-0x1c(%ebp)

	//allocate space for "envs" array aligned on 4KB boundary
	envs = boot_allocate_space(envs_size, PAGE_SIZE);
f01023fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01023fd:	83 ec 08             	sub    $0x8,%esp
f0102400:	68 00 10 00 00       	push   $0x1000
f0102405:	50                   	push   %eax
f0102406:	e8 7d 00 00 00       	call   f0102488 <boot_allocate_space>
f010240b:	83 c4 10             	add    $0x10,%esp
f010240e:	a3 4c ef 14 f0       	mov    %eax,0xf014ef4c

	//make the user to access this array by mapping it to UPAGES linear address (UPAGES is in User/Kernel space)
	boot_map_range(ptr_page_directory, UENVS, envs_size, K_PHYSICAL_ADDRESS(envs), PERM_USER) ;
f0102413:	a1 4c ef 14 f0       	mov    0xf014ef4c,%eax
f0102418:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010241b:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0102422:	77 14                	ja     f0102438 <initialize_kernel_VM+0x192>
f0102424:	ff 75 e0             	pushl  -0x20(%ebp)
f0102427:	68 7c 63 10 f0       	push   $0xf010637c
f010242c:	6a 75                	push   $0x75
f010242e:	68 ad 63 10 f0       	push   $0xf01063ad
f0102433:	e8 f6 dc ff ff       	call   f010012e <_panic>
f0102438:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010243b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0102441:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102444:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102449:	83 ec 0c             	sub    $0xc,%esp
f010244c:	6a 04                	push   $0x4
f010244e:	51                   	push   %ecx
f010244f:	52                   	push   %edx
f0102450:	68 00 00 c0 ee       	push   $0xeec00000
f0102455:	50                   	push   %eax
f0102456:	e8 8f 00 00 00       	call   f01024ea <boot_map_range>
f010245b:	83 c4 20             	add    $0x20,%esp

	//update permissions of the corresponding entry in page directory to make it USER with PERMISSION read only
	ptr_page_directory[PDX(UENVS)] = ptr_page_directory[PDX(UENVS)]|(PERM_USER|(PERM_PRESENT & (~PERM_WRITEABLE)));
f010245e:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102463:	05 ec 0e 00 00       	add    $0xeec,%eax
f0102468:	8b 15 e4 f7 14 f0    	mov    0xf014f7e4,%edx
f010246e:	81 c2 ec 0e 00 00    	add    $0xeec,%edx
f0102474:	8b 12                	mov    (%edx),%edx
f0102476:	83 ca 05             	or     $0x5,%edx
f0102479:	89 10                	mov    %edx,(%eax)


	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f010247b:	e8 52 f0 ff ff       	call   f01014d2 <check_boot_pgdir>

	// NOW: Turn off the segmentation by setting the segments' base to 0, and
	// turn on the paging by setting the corresponding flags in control register 0 (cr0)
	turn_on_paging() ;
f0102480:	e8 b4 fb ff ff       	call   f0102039 <turn_on_paging>
}
f0102485:	90                   	nop
f0102486:	c9                   	leave  
f0102487:	c3                   	ret    

f0102488 <boot_allocate_space>:
// It's too early to run out of memory.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
// 
void* boot_allocate_space(uint32 size, uint32 align)
		{
f0102488:	55                   	push   %ebp
f0102489:	89 e5                	mov    %esp,%ebp
f010248b:	83 ec 10             	sub    $0x10,%esp
	// Initialize ptr_free_mem if this is the first time.
	// 'end_of_kernel' is a symbol automatically generated by the linker,
	// which points to the end of the kernel-
	// i.e., the first virtual address that the linker
	// did not assign to any kernel code or global variables.
	if (ptr_free_mem == 0)
f010248e:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f0102493:	85 c0                	test   %eax,%eax
f0102495:	75 0a                	jne    f01024a1 <boot_allocate_space+0x19>
		ptr_free_mem = end_of_kernel;
f0102497:	c7 05 e0 f7 14 f0 ec 	movl   $0xf014f7ec,0xf014f7e0
f010249e:	f7 14 f0 

	// Your code here:
	//	Step 1: round ptr_free_mem up to be aligned properly
	ptr_free_mem = ROUNDUP(ptr_free_mem, PAGE_SIZE) ;
f01024a1:	c7 45 fc 00 10 00 00 	movl   $0x1000,-0x4(%ebp)
f01024a8:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f01024ad:	89 c2                	mov    %eax,%edx
f01024af:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01024b2:	01 d0                	add    %edx,%eax
f01024b4:	48                   	dec    %eax
f01024b5:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01024b8:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01024bb:	ba 00 00 00 00       	mov    $0x0,%edx
f01024c0:	f7 75 fc             	divl   -0x4(%ebp)
f01024c3:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01024c6:	29 d0                	sub    %edx,%eax
f01024c8:	a3 e0 f7 14 f0       	mov    %eax,0xf014f7e0

	//	Step 2: save current value of ptr_free_mem as allocated space
	void *ptr_allocated_mem;
	ptr_allocated_mem = ptr_free_mem ;
f01024cd:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f01024d2:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//	Step 3: increase ptr_free_mem to record allocation
	ptr_free_mem += size ;
f01024d5:	8b 15 e0 f7 14 f0    	mov    0xf014f7e0,%edx
f01024db:	8b 45 08             	mov    0x8(%ebp),%eax
f01024de:	01 d0                	add    %edx,%eax
f01024e0:	a3 e0 f7 14 f0       	mov    %eax,0xf014f7e0

	//	Step 4: return allocated space
	return ptr_allocated_mem ;
f01024e5:	8b 45 f4             	mov    -0xc(%ebp),%eax

		}
f01024e8:	c9                   	leave  
f01024e9:	c3                   	ret    

f01024ea <boot_map_range>:
//
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
f01024ea:	55                   	push   %ebp
f01024eb:	89 e5                	mov    %esp,%ebp
f01024ed:	83 ec 28             	sub    $0x28,%esp
	int i = 0 ;
f01024f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
f01024f7:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01024fe:	8b 55 14             	mov    0x14(%ebp),%edx
f0102501:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102504:	01 d0                	add    %edx,%eax
f0102506:	48                   	dec    %eax
f0102507:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010250a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010250d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102512:	f7 75 f0             	divl   -0x10(%ebp)
f0102515:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102518:	29 d0                	sub    %edx,%eax
f010251a:	89 45 14             	mov    %eax,0x14(%ebp)
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f010251d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0102524:	eb 53                	jmp    f0102579 <boot_map_range+0x8f>
	{
		uint32 *ptr_page_table = boot_get_page_table(ptr_page_directory, virtual_address, 1) ;
f0102526:	83 ec 04             	sub    $0x4,%esp
f0102529:	6a 01                	push   $0x1
f010252b:	ff 75 0c             	pushl  0xc(%ebp)
f010252e:	ff 75 08             	pushl  0x8(%ebp)
f0102531:	e8 4e 00 00 00       	call   f0102584 <boot_get_page_table>
f0102536:	83 c4 10             	add    $0x10,%esp
f0102539:	89 45 e8             	mov    %eax,-0x18(%ebp)
		uint32 index_page_table = PTX(virtual_address);
f010253c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010253f:	c1 e8 0c             	shr    $0xc,%eax
f0102542:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102547:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
f010254a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010254d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102554:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102557:	01 c2                	add    %eax,%edx
f0102559:	8b 45 18             	mov    0x18(%ebp),%eax
f010255c:	0b 45 14             	or     0x14(%ebp),%eax
f010255f:	83 c8 01             	or     $0x1,%eax
f0102562:	89 02                	mov    %eax,(%edx)
		physical_address += PAGE_SIZE ;
f0102564:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
		virtual_address += PAGE_SIZE ;
f010256b:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
	int i = 0 ;
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f0102572:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0102579:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010257c:	3b 45 10             	cmp    0x10(%ebp),%eax
f010257f:	72 a5                	jb     f0102526 <boot_map_range+0x3c>
		uint32 index_page_table = PTX(virtual_address);
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
		physical_address += PAGE_SIZE ;
		virtual_address += PAGE_SIZE ;
	}
}
f0102581:	90                   	nop
f0102582:	c9                   	leave  
f0102583:	c3                   	ret    

f0102584 <boot_get_page_table>:
// boot_get_page_table cannot fail.  It's too early to fail.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
uint32* boot_get_page_table(uint32 *ptr_page_directory, uint32 virtual_address, int create)
		{
f0102584:	55                   	push   %ebp
f0102585:	89 e5                	mov    %esp,%ebp
f0102587:	83 ec 28             	sub    $0x28,%esp
	uint32 index_page_directory = PDX(virtual_address);
f010258a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010258d:	c1 e8 16             	shr    $0x16,%eax
f0102590:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 page_directory_entry = ptr_page_directory[index_page_directory];
f0102593:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102596:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010259d:	8b 45 08             	mov    0x8(%ebp),%eax
f01025a0:	01 d0                	add    %edx,%eax
f01025a2:	8b 00                	mov    (%eax),%eax
f01025a4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	uint32 phys_page_table = EXTRACT_ADDRESS(page_directory_entry);
f01025a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01025aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01025af:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table);
f01025b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01025b5:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01025b8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01025bb:	c1 e8 0c             	shr    $0xc,%eax
f01025be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01025c1:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f01025c6:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01025c9:	72 17                	jb     f01025e2 <boot_get_page_table+0x5e>
f01025cb:	ff 75 e8             	pushl  -0x18(%ebp)
f01025ce:	68 c4 63 10 f0       	push   $0xf01063c4
f01025d3:	68 db 00 00 00       	push   $0xdb
f01025d8:	68 ad 63 10 f0       	push   $0xf01063ad
f01025dd:	e8 4c db ff ff       	call   f010012e <_panic>
f01025e2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01025e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (phys_page_table == 0)
f01025ed:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01025f1:	75 72                	jne    f0102665 <boot_get_page_table+0xe1>
	{
		if (create)
f01025f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01025f7:	74 65                	je     f010265e <boot_get_page_table+0xda>
		{
			ptr_page_table = boot_allocate_space(PAGE_SIZE, PAGE_SIZE) ;
f01025f9:	83 ec 08             	sub    $0x8,%esp
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	68 00 10 00 00       	push   $0x1000
f0102606:	e8 7d fe ff ff       	call   f0102488 <boot_allocate_space>
f010260b:	83 c4 10             	add    $0x10,%esp
f010260e:	89 45 e0             	mov    %eax,-0x20(%ebp)
			phys_page_table = K_PHYSICAL_ADDRESS(ptr_page_table);
f0102611:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102614:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102617:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f010261e:	77 17                	ja     f0102637 <boot_get_page_table+0xb3>
f0102620:	ff 75 dc             	pushl  -0x24(%ebp)
f0102623:	68 7c 63 10 f0       	push   $0xf010637c
f0102628:	68 e1 00 00 00       	push   $0xe1
f010262d:	68 ad 63 10 f0       	push   $0xf01063ad
f0102632:	e8 f7 da ff ff       	call   f010012e <_panic>
f0102637:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010263a:	05 00 00 00 10       	add    $0x10000000,%eax
f010263f:	89 45 ec             	mov    %eax,-0x14(%ebp)
			ptr_page_directory[index_page_directory] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_WRITEABLE);
f0102642:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102645:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010264c:	8b 45 08             	mov    0x8(%ebp),%eax
f010264f:	01 d0                	add    %edx,%eax
f0102651:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0102654:	83 ca 03             	or     $0x3,%edx
f0102657:	89 10                	mov    %edx,(%eax)
			return ptr_page_table ;
f0102659:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010265c:	eb 0a                	jmp    f0102668 <boot_get_page_table+0xe4>
		}
		else
			return 0 ;
f010265e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102663:	eb 03                	jmp    f0102668 <boot_get_page_table+0xe4>
	}
	return ptr_page_table ;
f0102665:	8b 45 e0             	mov    -0x20(%ebp),%eax
		}
f0102668:	c9                   	leave  
f0102669:	c3                   	ret    

f010266a <initialize_paging>:
// After this point, ONLY use the functions below
// to allocate and deallocate physical memory via the free_frame_list,
// and NEVER use boot_allocate_space() or the related boot-time functions above.
//
void initialize_paging()
{
f010266a:	55                   	push   %ebp
f010266b:	89 e5                	mov    %esp,%ebp
f010266d:	53                   	push   %ebx
f010266e:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which frames are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&free_frame_list);
f0102671:	c7 05 d8 f7 14 f0 00 	movl   $0x0,0xf014f7d8
f0102678:	00 00 00 

	frames_info[0].references = 1;
f010267b:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f0102680:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);
f0102686:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f010268d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102690:	05 ff ff 09 00       	add    $0x9ffff,%eax
f0102695:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102698:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010269b:	ba 00 00 00 00       	mov    $0x0,%edx
f01026a0:	f7 75 f0             	divl   -0x10(%ebp)
f01026a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01026a6:	29 d0                	sub    %edx,%eax
f01026a8:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f01026ab:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f01026b2:	e9 90 00 00 00       	jmp    f0102747 <initialize_paging+0xdd>
	{
		frames_info[i].references = 0;
f01026b7:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01026bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01026c0:	89 d0                	mov    %edx,%eax
f01026c2:	01 c0                	add    %eax,%eax
f01026c4:	01 d0                	add    %edx,%eax
f01026c6:	c1 e0 02             	shl    $0x2,%eax
f01026c9:	01 c8                	add    %ecx,%eax
f01026cb:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f01026d1:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01026d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01026da:	89 d0                	mov    %edx,%eax
f01026dc:	01 c0                	add    %eax,%eax
f01026de:	01 d0                	add    %edx,%eax
f01026e0:	c1 e0 02             	shl    $0x2,%eax
f01026e3:	01 c8                	add    %ecx,%eax
f01026e5:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f01026eb:	89 10                	mov    %edx,(%eax)
f01026ed:	8b 00                	mov    (%eax),%eax
f01026ef:	85 c0                	test   %eax,%eax
f01026f1:	74 1d                	je     f0102710 <initialize_paging+0xa6>
f01026f3:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f01026f9:	8b 1d dc f7 14 f0    	mov    0xf014f7dc,%ebx
f01026ff:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0102702:	89 c8                	mov    %ecx,%eax
f0102704:	01 c0                	add    %eax,%eax
f0102706:	01 c8                	add    %ecx,%eax
f0102708:	c1 e0 02             	shl    $0x2,%eax
f010270b:	01 d8                	add    %ebx,%eax
f010270d:	89 42 04             	mov    %eax,0x4(%edx)
f0102710:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102716:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102719:	89 d0                	mov    %edx,%eax
f010271b:	01 c0                	add    %eax,%eax
f010271d:	01 d0                	add    %edx,%eax
f010271f:	c1 e0 02             	shl    $0x2,%eax
f0102722:	01 c8                	add    %ecx,%eax
f0102724:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f0102729:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f010272f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102732:	89 d0                	mov    %edx,%eax
f0102734:	01 c0                	add    %eax,%eax
f0102736:	01 d0                	add    %edx,%eax
f0102738:	c1 e0 02             	shl    $0x2,%eax
f010273b:	01 c8                	add    %ecx,%eax
f010273d:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)

	frames_info[0].references = 1;

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f0102744:	ff 45 f4             	incl   -0xc(%ebp)
f0102747:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010274a:	85 c0                	test   %eax,%eax
f010274c:	79 05                	jns    f0102753 <initialize_paging+0xe9>
f010274e:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102753:	c1 f8 0c             	sar    $0xc,%eax
f0102756:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102759:	0f 8f 58 ff ff ff    	jg     f01026b7 <initialize_paging+0x4d>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f010275f:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
f0102766:	eb 1d                	jmp    f0102785 <initialize_paging+0x11b>
	{
		frames_info[i].references = 1;
f0102768:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f010276e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102771:	89 d0                	mov    %edx,%eax
f0102773:	01 c0                	add    %eax,%eax
f0102775:	01 d0                	add    %edx,%eax
f0102777:	c1 e0 02             	shl    $0x2,%eax
f010277a:	01 c8                	add    %ecx,%eax
f010277c:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f0102782:	ff 45 f4             	incl   -0xc(%ebp)
f0102785:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
f010278c:	7e da                	jle    f0102768 <initialize_paging+0xfe>
	{
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);
f010278e:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f0102795:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f010279a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010279d:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01027a4:	77 17                	ja     f01027bd <initialize_paging+0x153>
f01027a6:	ff 75 e0             	pushl  -0x20(%ebp)
f01027a9:	68 7c 63 10 f0       	push   $0xf010637c
f01027ae:	68 1e 01 00 00       	push   $0x11e
f01027b3:	68 ad 63 10 f0       	push   $0xf01063ad
f01027b8:	e8 71 d9 ff ff       	call   f010012e <_panic>
f01027bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027c0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01027c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027c9:	01 d0                	add    %edx,%eax
f01027cb:	48                   	dec    %eax
f01027cc:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01027cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01027d7:	f7 75 e4             	divl   -0x1c(%ebp)
f01027da:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027dd:	29 d0                	sub    %edx,%eax
f01027df:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f01027e2:	c7 45 f4 00 01 00 00 	movl   $0x100,-0xc(%ebp)
f01027e9:	eb 1d                	jmp    f0102808 <initialize_paging+0x19e>
	{
		frames_info[i].references = 1;
f01027eb:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01027f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01027f4:	89 d0                	mov    %edx,%eax
f01027f6:	01 c0                	add    %eax,%eax
f01027f8:	01 d0                	add    %edx,%eax
f01027fa:	c1 e0 02             	shl    $0x2,%eax
f01027fd:	01 c8                	add    %ecx,%eax
f01027ff:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f0102805:	ff 45 f4             	incl   -0xc(%ebp)
f0102808:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010280b:	85 c0                	test   %eax,%eax
f010280d:	79 05                	jns    f0102814 <initialize_paging+0x1aa>
f010280f:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102814:	c1 f8 0c             	sar    $0xc,%eax
f0102817:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f010281a:	7f cf                	jg     f01027eb <initialize_paging+0x181>
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f010281c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010281f:	85 c0                	test   %eax,%eax
f0102821:	79 05                	jns    f0102828 <initialize_paging+0x1be>
f0102823:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102828:	c1 f8 0c             	sar    $0xc,%eax
f010282b:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010282e:	e9 90 00 00 00       	jmp    f01028c3 <initialize_paging+0x259>
	{
		frames_info[i].references = 0;
f0102833:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102839:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010283c:	89 d0                	mov    %edx,%eax
f010283e:	01 c0                	add    %eax,%eax
f0102840:	01 d0                	add    %edx,%eax
f0102842:	c1 e0 02             	shl    $0x2,%eax
f0102845:	01 c8                	add    %ecx,%eax
f0102847:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f010284d:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102853:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102856:	89 d0                	mov    %edx,%eax
f0102858:	01 c0                	add    %eax,%eax
f010285a:	01 d0                	add    %edx,%eax
f010285c:	c1 e0 02             	shl    $0x2,%eax
f010285f:	01 c8                	add    %ecx,%eax
f0102861:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102867:	89 10                	mov    %edx,(%eax)
f0102869:	8b 00                	mov    (%eax),%eax
f010286b:	85 c0                	test   %eax,%eax
f010286d:	74 1d                	je     f010288c <initialize_paging+0x222>
f010286f:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102875:	8b 1d dc f7 14 f0    	mov    0xf014f7dc,%ebx
f010287b:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f010287e:	89 c8                	mov    %ecx,%eax
f0102880:	01 c0                	add    %eax,%eax
f0102882:	01 c8                	add    %ecx,%eax
f0102884:	c1 e0 02             	shl    $0x2,%eax
f0102887:	01 d8                	add    %ebx,%eax
f0102889:	89 42 04             	mov    %eax,0x4(%edx)
f010288c:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102892:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102895:	89 d0                	mov    %edx,%eax
f0102897:	01 c0                	add    %eax,%eax
f0102899:	01 d0                	add    %edx,%eax
f010289b:	c1 e0 02             	shl    $0x2,%eax
f010289e:	01 c8                	add    %ecx,%eax
f01028a0:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f01028a5:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01028ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01028ae:	89 d0                	mov    %edx,%eax
f01028b0:	01 c0                	add    %eax,%eax
f01028b2:	01 d0                	add    %edx,%eax
f01028b4:	c1 e0 02             	shl    $0x2,%eax
f01028b7:	01 c8                	add    %ecx,%eax
f01028b9:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)
	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f01028c0:	ff 45 f4             	incl   -0xc(%ebp)
f01028c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01028c6:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f01028cb:	39 c2                	cmp    %eax,%edx
f01028cd:	0f 82 60 ff ff ff    	jb     f0102833 <initialize_paging+0x1c9>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}
}
f01028d3:	90                   	nop
f01028d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028d7:	c9                   	leave  
f01028d8:	c3                   	ret    

f01028d9 <initialize_frame_info>:
// Initialize a Frame_Info structure.
// The result has null links and 0 references.
// Note that the corresponding physical frame is NOT initialized!
//
void initialize_frame_info(struct Frame_Info *ptr_frame_info)
{
f01028d9:	55                   	push   %ebp
f01028da:	89 e5                	mov    %esp,%ebp
f01028dc:	83 ec 08             	sub    $0x8,%esp
	memset(ptr_frame_info, 0, sizeof(*ptr_frame_info));
f01028df:	83 ec 04             	sub    $0x4,%esp
f01028e2:	6a 0c                	push   $0xc
f01028e4:	6a 00                	push   $0x0
f01028e6:	ff 75 08             	pushl  0x8(%ebp)
f01028e9:	e8 9d 23 00 00       	call   f0104c8b <memset>
f01028ee:	83 c4 10             	add    $0x10,%esp
}
f01028f1:	90                   	nop
f01028f2:	c9                   	leave  
f01028f3:	c3                   	ret    

f01028f4 <allocate_frame>:
//   E_NO_MEM -- otherwise
//
// Hint: use LIST_FIRST, LIST_REMOVE, and initialize_frame_info
// Hint: references should not be incremented
int allocate_frame(struct Frame_Info **ptr_frame_info)
{
f01028f4:	55                   	push   %ebp
f01028f5:	89 e5                	mov    %esp,%ebp
f01028f7:	83 ec 08             	sub    $0x8,%esp
	// Fill this function in	
	*ptr_frame_info = LIST_FIRST(&free_frame_list);
f01028fa:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102900:	8b 45 08             	mov    0x8(%ebp),%eax
f0102903:	89 10                	mov    %edx,(%eax)
	if(*ptr_frame_info == NULL)
f0102905:	8b 45 08             	mov    0x8(%ebp),%eax
f0102908:	8b 00                	mov    (%eax),%eax
f010290a:	85 c0                	test   %eax,%eax
f010290c:	75 07                	jne    f0102915 <allocate_frame+0x21>
		return E_NO_MEM;
f010290e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102913:	eb 44                	jmp    f0102959 <allocate_frame+0x65>

	LIST_REMOVE(*ptr_frame_info);
f0102915:	8b 45 08             	mov    0x8(%ebp),%eax
f0102918:	8b 00                	mov    (%eax),%eax
f010291a:	8b 00                	mov    (%eax),%eax
f010291c:	85 c0                	test   %eax,%eax
f010291e:	74 12                	je     f0102932 <allocate_frame+0x3e>
f0102920:	8b 45 08             	mov    0x8(%ebp),%eax
f0102923:	8b 00                	mov    (%eax),%eax
f0102925:	8b 00                	mov    (%eax),%eax
f0102927:	8b 55 08             	mov    0x8(%ebp),%edx
f010292a:	8b 12                	mov    (%edx),%edx
f010292c:	8b 52 04             	mov    0x4(%edx),%edx
f010292f:	89 50 04             	mov    %edx,0x4(%eax)
f0102932:	8b 45 08             	mov    0x8(%ebp),%eax
f0102935:	8b 00                	mov    (%eax),%eax
f0102937:	8b 40 04             	mov    0x4(%eax),%eax
f010293a:	8b 55 08             	mov    0x8(%ebp),%edx
f010293d:	8b 12                	mov    (%edx),%edx
f010293f:	8b 12                	mov    (%edx),%edx
f0102941:	89 10                	mov    %edx,(%eax)
	initialize_frame_info(*ptr_frame_info);
f0102943:	8b 45 08             	mov    0x8(%ebp),%eax
f0102946:	8b 00                	mov    (%eax),%eax
f0102948:	83 ec 0c             	sub    $0xc,%esp
f010294b:	50                   	push   %eax
f010294c:	e8 88 ff ff ff       	call   f01028d9 <initialize_frame_info>
f0102951:	83 c4 10             	add    $0x10,%esp
	return 0;
f0102954:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102959:	c9                   	leave  
f010295a:	c3                   	ret    

f010295b <free_frame>:
//
// Return a frame to the free_frame_list.
// (This function should only be called when ptr_frame_info->references reaches 0.)
//
void free_frame(struct Frame_Info *ptr_frame_info)
{
f010295b:	55                   	push   %ebp
f010295c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	LIST_INSERT_HEAD(&free_frame_list, ptr_frame_info);
f010295e:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102964:	8b 45 08             	mov    0x8(%ebp),%eax
f0102967:	89 10                	mov    %edx,(%eax)
f0102969:	8b 45 08             	mov    0x8(%ebp),%eax
f010296c:	8b 00                	mov    (%eax),%eax
f010296e:	85 c0                	test   %eax,%eax
f0102970:	74 0b                	je     f010297d <free_frame+0x22>
f0102972:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0102977:	8b 55 08             	mov    0x8(%ebp),%edx
f010297a:	89 50 04             	mov    %edx,0x4(%eax)
f010297d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102980:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f0102985:	8b 45 08             	mov    0x8(%ebp),%eax
f0102988:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)
}
f010298f:	90                   	nop
f0102990:	5d                   	pop    %ebp
f0102991:	c3                   	ret    

f0102992 <decrement_references>:
//
// Decrement the reference count on a frame
// freeing it if there are no more references.
//
void decrement_references(struct Frame_Info* ptr_frame_info)
{
f0102992:	55                   	push   %ebp
f0102993:	89 e5                	mov    %esp,%ebp
	if (--(ptr_frame_info->references) == 0)
f0102995:	8b 45 08             	mov    0x8(%ebp),%eax
f0102998:	8b 40 08             	mov    0x8(%eax),%eax
f010299b:	48                   	dec    %eax
f010299c:	8b 55 08             	mov    0x8(%ebp),%edx
f010299f:	66 89 42 08          	mov    %ax,0x8(%edx)
f01029a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01029a6:	8b 40 08             	mov    0x8(%eax),%eax
f01029a9:	66 85 c0             	test   %ax,%ax
f01029ac:	75 0b                	jne    f01029b9 <decrement_references+0x27>
		free_frame(ptr_frame_info);
f01029ae:	ff 75 08             	pushl  0x8(%ebp)
f01029b1:	e8 a5 ff ff ff       	call   f010295b <free_frame>
f01029b6:	83 c4 04             	add    $0x4,%esp
}
f01029b9:	90                   	nop
f01029ba:	c9                   	leave  
f01029bb:	c3                   	ret    

f01029bc <get_page_table>:
//
// Hint: you can use "to_physical_address()" to turn a Frame_Info*
// into the physical address of the frame it refers to. 

int get_page_table(uint32 *ptr_page_directory, const void *virtual_address, int create, uint32 **ptr_page_table)
{
f01029bc:	55                   	push   %ebp
f01029bd:	89 e5                	mov    %esp,%ebp
f01029bf:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	uint32 page_directory_entry = ptr_page_directory[PDX(virtual_address)];
f01029c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029c5:	c1 e8 16             	shr    $0x16,%eax
f01029c8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01029cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01029d2:	01 d0                	add    %edx,%eax
f01029d4:	8b 00                	mov    (%eax),%eax
f01029d6:	89 45 f4             	mov    %eax,-0xc(%ebp)

	*ptr_page_table = K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(page_directory_entry)) ;
f01029d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01029dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01029e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01029e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01029e7:	c1 e8 0c             	shr    $0xc,%eax
f01029ea:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01029ed:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f01029f2:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f01029f5:	72 17                	jb     f0102a0e <get_page_table+0x52>
f01029f7:	ff 75 f0             	pushl  -0x10(%ebp)
f01029fa:	68 c4 63 10 f0       	push   $0xf01063c4
f01029ff:	68 79 01 00 00       	push   $0x179
f0102a04:	68 ad 63 10 f0       	push   $0xf01063ad
f0102a09:	e8 20 d7 ff ff       	call   f010012e <_panic>
f0102a0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102a11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a16:	89 c2                	mov    %eax,%edx
f0102a18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a1b:	89 10                	mov    %edx,(%eax)

	if (page_directory_entry == 0)
f0102a1d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102a21:	0f 85 d3 00 00 00    	jne    f0102afa <get_page_table+0x13e>
	{
		if (create)
f0102a27:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102a2b:	0f 84 b9 00 00 00    	je     f0102aea <get_page_table+0x12e>
		{
			struct Frame_Info* ptr_frame_info;
			int err = allocate_frame(&ptr_frame_info) ;
f0102a31:	83 ec 0c             	sub    $0xc,%esp
f0102a34:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102a37:	50                   	push   %eax
f0102a38:	e8 b7 fe ff ff       	call   f01028f4 <allocate_frame>
f0102a3d:	83 c4 10             	add    $0x10,%esp
f0102a40:	89 45 e8             	mov    %eax,-0x18(%ebp)
			if(err == E_NO_MEM)
f0102a43:	83 7d e8 fc          	cmpl   $0xfffffffc,-0x18(%ebp)
f0102a47:	75 13                	jne    f0102a5c <get_page_table+0xa0>
			{
				*ptr_page_table = 0;
f0102a49:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a4c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				return E_NO_MEM;
f0102a52:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102a57:	e9 a3 00 00 00       	jmp    f0102aff <get_page_table+0x143>
			}

			uint32 phys_page_table = to_physical_address(ptr_frame_info);
f0102a5c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102a5f:	83 ec 0c             	sub    $0xc,%esp
f0102a62:	50                   	push   %eax
f0102a63:	e8 e5 f7 ff ff       	call   f010224d <to_physical_address>
f0102a68:	83 c4 10             	add    $0x10,%esp
f0102a6b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			*ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table) ;
f0102a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102a74:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a77:	c1 e8 0c             	shr    $0xc,%eax
f0102a7a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102a7d:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0102a82:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0102a85:	72 17                	jb     f0102a9e <get_page_table+0xe2>
f0102a87:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a8a:	68 c4 63 10 f0       	push   $0xf01063c4
f0102a8f:	68 88 01 00 00       	push   $0x188
f0102a94:	68 ad 63 10 f0       	push   $0xf01063ad
f0102a99:	e8 90 d6 ff ff       	call   f010012e <_panic>
f0102a9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102aa1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aa6:	89 c2                	mov    %eax,%edx
f0102aa8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aab:	89 10                	mov    %edx,(%eax)

			//initialize new page table by 0's
			memset(*ptr_page_table , 0, PAGE_SIZE);
f0102aad:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ab0:	8b 00                	mov    (%eax),%eax
f0102ab2:	83 ec 04             	sub    $0x4,%esp
f0102ab5:	68 00 10 00 00       	push   $0x1000
f0102aba:	6a 00                	push   $0x0
f0102abc:	50                   	push   %eax
f0102abd:	e8 c9 21 00 00       	call   f0104c8b <memset>
f0102ac2:	83 c4 10             	add    $0x10,%esp

			ptr_frame_info->references = 1;
f0102ac5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ac8:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
			ptr_page_directory[PDX(virtual_address)] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_USER | PERM_WRITEABLE);
f0102ace:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ad1:	c1 e8 16             	shr    $0x16,%eax
f0102ad4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102adb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ade:	01 d0                	add    %edx,%eax
f0102ae0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102ae3:	83 ca 07             	or     $0x7,%edx
f0102ae6:	89 10                	mov    %edx,(%eax)
f0102ae8:	eb 10                	jmp    f0102afa <get_page_table+0x13e>
		}
		else
		{
			*ptr_page_table = 0;
f0102aea:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return 0;
f0102af3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102af8:	eb 05                	jmp    f0102aff <get_page_table+0x143>
		}
	}	
	return 0;
f0102afa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102aff:	c9                   	leave  
f0102b00:	c3                   	ret    

f0102b01 <map_frame>:
//   E_NO_MEM, if page table couldn't be allocated
//
// Hint: implement using get_page_table() and unmap_frame().
//
int map_frame(uint32 *ptr_page_directory, struct Frame_Info *ptr_frame_info, void *virtual_address, int perm)
{
f0102b01:	55                   	push   %ebp
f0102b02:	89 e5                	mov    %esp,%ebp
f0102b04:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 physical_address = to_physical_address(ptr_frame_info);
f0102b07:	ff 75 0c             	pushl  0xc(%ebp)
f0102b0a:	e8 3e f7 ff ff       	call   f010224d <to_physical_address>
f0102b0f:	83 c4 04             	add    $0x4,%esp
f0102b12:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *ptr_page_table;
	if( get_page_table(ptr_page_directory, virtual_address, 1, &ptr_page_table) == 0)
f0102b15:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102b18:	50                   	push   %eax
f0102b19:	6a 01                	push   $0x1
f0102b1b:	ff 75 10             	pushl  0x10(%ebp)
f0102b1e:	ff 75 08             	pushl  0x8(%ebp)
f0102b21:	e8 96 fe ff ff       	call   f01029bc <get_page_table>
f0102b26:	83 c4 10             	add    $0x10,%esp
f0102b29:	85 c0                	test   %eax,%eax
f0102b2b:	75 7c                	jne    f0102ba9 <map_frame+0xa8>
	{
		uint32 page_table_entry = ptr_page_table[PTX(virtual_address)];
f0102b2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102b30:	8b 55 10             	mov    0x10(%ebp),%edx
f0102b33:	c1 ea 0c             	shr    $0xc,%edx
f0102b36:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102b3c:	c1 e2 02             	shl    $0x2,%edx
f0102b3f:	01 d0                	add    %edx,%eax
f0102b41:	8b 00                	mov    (%eax),%eax
f0102b43:	89 45 f0             	mov    %eax,-0x10(%ebp)

		//If already mapped
		if ((page_table_entry & PERM_PRESENT) == PERM_PRESENT)
f0102b46:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b49:	83 e0 01             	and    $0x1,%eax
f0102b4c:	85 c0                	test   %eax,%eax
f0102b4e:	74 25                	je     f0102b75 <map_frame+0x74>
		{
			//on this pa, then do nothing
			if (EXTRACT_ADDRESS(page_table_entry) == physical_address)
f0102b50:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102b58:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102b5b:	75 07                	jne    f0102b64 <map_frame+0x63>
				return 0;
f0102b5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b62:	eb 4a                	jmp    f0102bae <map_frame+0xad>
			//on another pa, then unmap it
			else
				unmap_frame(ptr_page_directory , virtual_address);
f0102b64:	83 ec 08             	sub    $0x8,%esp
f0102b67:	ff 75 10             	pushl  0x10(%ebp)
f0102b6a:	ff 75 08             	pushl  0x8(%ebp)
f0102b6d:	e8 ad 00 00 00       	call   f0102c1f <unmap_frame>
f0102b72:	83 c4 10             	add    $0x10,%esp
		}
		ptr_frame_info->references++;
f0102b75:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b78:	8b 40 08             	mov    0x8(%eax),%eax
f0102b7b:	40                   	inc    %eax
f0102b7c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b7f:	66 89 42 08          	mov    %ax,0x8(%edx)
		ptr_page_table[PTX(virtual_address)] = CONSTRUCT_ENTRY(physical_address , perm | PERM_PRESENT);
f0102b83:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102b86:	8b 55 10             	mov    0x10(%ebp),%edx
f0102b89:	c1 ea 0c             	shr    $0xc,%edx
f0102b8c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102b92:	c1 e2 02             	shl    $0x2,%edx
f0102b95:	01 c2                	add    %eax,%edx
f0102b97:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b9a:	0b 45 f4             	or     -0xc(%ebp),%eax
f0102b9d:	83 c8 01             	or     $0x1,%eax
f0102ba0:	89 02                	mov    %eax,(%edx)

		return 0;
f0102ba2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ba7:	eb 05                	jmp    f0102bae <map_frame+0xad>
	}	
	return E_NO_MEM;
f0102ba9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0102bae:	c9                   	leave  
f0102baf:	c3                   	ret    

f0102bb0 <get_frame_info>:
// Return 0 if there is no frame mapped at virtual_address.
//
// Hint: implement using get_page_table() and get_frame_info().
//
struct Frame_Info * get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table)
		{
f0102bb0:	55                   	push   %ebp
f0102bb1:	89 e5                	mov    %esp,%ebp
f0102bb3:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in	
	uint32 ret =  get_page_table(ptr_page_directory, virtual_address, 0, ptr_page_table) ;
f0102bb6:	ff 75 10             	pushl  0x10(%ebp)
f0102bb9:	6a 00                	push   $0x0
f0102bbb:	ff 75 0c             	pushl  0xc(%ebp)
f0102bbe:	ff 75 08             	pushl  0x8(%ebp)
f0102bc1:	e8 f6 fd ff ff       	call   f01029bc <get_page_table>
f0102bc6:	83 c4 10             	add    $0x10,%esp
f0102bc9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*ptr_page_table) != 0)
f0102bcc:	8b 45 10             	mov    0x10(%ebp),%eax
f0102bcf:	8b 00                	mov    (%eax),%eax
f0102bd1:	85 c0                	test   %eax,%eax
f0102bd3:	74 43                	je     f0102c18 <get_frame_info+0x68>
	{	
		uint32 index_page_table = PTX(virtual_address);
f0102bd5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bd8:	c1 e8 0c             	shr    $0xc,%eax
f0102bdb:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102be0:	89 45 f0             	mov    %eax,-0x10(%ebp)
		uint32 page_table_entry = (*ptr_page_table)[index_page_table];
f0102be3:	8b 45 10             	mov    0x10(%ebp),%eax
f0102be6:	8b 00                	mov    (%eax),%eax
f0102be8:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102beb:	c1 e2 02             	shl    $0x2,%edx
f0102bee:	01 d0                	add    %edx,%eax
f0102bf0:	8b 00                	mov    (%eax),%eax
f0102bf2:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( page_table_entry != 0)	
f0102bf5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102bf9:	74 16                	je     f0102c11 <get_frame_info+0x61>
			return to_frame_info( EXTRACT_ADDRESS ( page_table_entry ) );
f0102bfb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102bfe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102c03:	83 ec 0c             	sub    $0xc,%esp
f0102c06:	50                   	push   %eax
f0102c07:	e8 54 f6 ff ff       	call   f0102260 <to_frame_info>
f0102c0c:	83 c4 10             	add    $0x10,%esp
f0102c0f:	eb 0c                	jmp    f0102c1d <get_frame_info+0x6d>
		return 0;
f0102c11:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c16:	eb 05                	jmp    f0102c1d <get_frame_info+0x6d>
	}
	return 0;
f0102c18:	b8 00 00 00 00       	mov    $0x0,%eax
		}
f0102c1d:	c9                   	leave  
f0102c1e:	c3                   	ret    

f0102c1f <unmap_frame>:
//
// Hint: implement using get_frame_info(),
// 	tlb_invalidate(), and decrement_references().
//
void unmap_frame(uint32 *ptr_page_directory, void *virtual_address)
{
f0102c1f:	55                   	push   %ebp
f0102c20:	89 e5                	mov    %esp,%ebp
f0102c22:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 *ptr_page_table;
	struct Frame_Info* ptr_frame_info = get_frame_info(ptr_page_directory, virtual_address, &ptr_page_table);
f0102c25:	83 ec 04             	sub    $0x4,%esp
f0102c28:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0102c2b:	50                   	push   %eax
f0102c2c:	ff 75 0c             	pushl  0xc(%ebp)
f0102c2f:	ff 75 08             	pushl  0x8(%ebp)
f0102c32:	e8 79 ff ff ff       	call   f0102bb0 <get_frame_info>
f0102c37:	83 c4 10             	add    $0x10,%esp
f0102c3a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( ptr_frame_info != 0 )
f0102c3d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102c41:	74 39                	je     f0102c7c <unmap_frame+0x5d>
	{
		decrement_references(ptr_frame_info);
f0102c43:	83 ec 0c             	sub    $0xc,%esp
f0102c46:	ff 75 f4             	pushl  -0xc(%ebp)
f0102c49:	e8 44 fd ff ff       	call   f0102992 <decrement_references>
f0102c4e:	83 c4 10             	add    $0x10,%esp
		ptr_page_table[PTX(virtual_address)] = 0;
f0102c51:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c54:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c57:	c1 ea 0c             	shr    $0xc,%edx
f0102c5a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102c60:	c1 e2 02             	shl    $0x2,%edx
f0102c63:	01 d0                	add    %edx,%eax
f0102c65:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(ptr_page_directory, virtual_address);
f0102c6b:	83 ec 08             	sub    $0x8,%esp
f0102c6e:	ff 75 0c             	pushl  0xc(%ebp)
f0102c71:	ff 75 08             	pushl  0x8(%ebp)
f0102c74:	e8 59 eb ff ff       	call   f01017d2 <tlb_invalidate>
f0102c79:	83 c4 10             	add    $0x10,%esp
	}	
}
f0102c7c:	90                   	nop
f0102c7d:	c9                   	leave  
f0102c7e:	c3                   	ret    

f0102c7f <get_page>:
//		or to allocate any necessary page tables.
// 	HINT: 	remember to free the allocated frame if there is no space 
//		for the necessary page tables

int get_page(uint32* ptr_page_directory, void *virtual_address, int perm)
{
f0102c7f:	55                   	push   %ebp
f0102c80:	89 e5                	mov    %esp,%ebp
f0102c82:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("get_page function is not completed yet") ;
f0102c85:	83 ec 04             	sub    $0x4,%esp
f0102c88:	68 f4 63 10 f0       	push   $0xf01063f4
f0102c8d:	68 14 02 00 00       	push   $0x214
f0102c92:	68 ad 63 10 f0       	push   $0xf01063ad
f0102c97:	e8 92 d4 ff ff       	call   f010012e <_panic>

f0102c9c <calculate_required_frames>:
	return 0 ;
}

//[2] calculate_required_frames: 
uint32 calculate_required_frames(uint32* ptr_page_directory, uint32 start_virtual_address, uint32 size)
{
f0102c9c:	55                   	push   %ebp
f0102c9d:	89 e5                	mov    %esp,%ebp
f0102c9f:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("calculate_required_frames function is not completed yet") ;
f0102ca2:	83 ec 04             	sub    $0x4,%esp
f0102ca5:	68 1c 64 10 f0       	push   $0xf010641c
f0102caa:	68 2b 02 00 00       	push   $0x22b
f0102caf:	68 ad 63 10 f0       	push   $0xf01063ad
f0102cb4:	e8 75 d4 ff ff       	call   f010012e <_panic>

f0102cb9 <calculate_free_frames>:


//[3] calculate_free_frames:

uint32 calculate_free_frames()
{
f0102cb9:	55                   	push   %ebp
f0102cba:	89 e5                	mov    %esp,%ebp
f0102cbc:	83 ec 10             	sub    $0x10,%esp
	// PROJECT 2008: Your code here.
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
f0102cbf:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	LIST_FOREACH(ptr, &free_frame_list)
f0102cc6:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0102ccb:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102cce:	eb 0b                	jmp    f0102cdb <calculate_free_frames+0x22>
	{
		cnt++ ;
f0102cd0:	ff 45 f8             	incl   -0x8(%ebp)
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
	LIST_FOREACH(ptr, &free_frame_list)
f0102cd3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102cd6:	8b 00                	mov    (%eax),%eax
f0102cd8:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102cdb:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0102cdf:	75 ef                	jne    f0102cd0 <calculate_free_frames+0x17>
	{
		cnt++ ;
	}
	return cnt;
f0102ce1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0102ce4:	c9                   	leave  
f0102ce5:	c3                   	ret    

f0102ce6 <freeMem>:
//	Steps:
//		1) Unmap all mapped pages in the range [virtual_address, virtual_address + size ]
//		2) Free all mapped page tables in this range

void freeMem(uint32* ptr_page_directory, void *virtual_address, uint32 size)
{
f0102ce6:	55                   	push   %ebp
f0102ce7:	89 e5                	mov    %esp,%ebp
f0102ce9:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("freeMem function is not completed yet") ;
f0102cec:	83 ec 04             	sub    $0x4,%esp
f0102cef:	68 54 64 10 f0       	push   $0xf0106454
f0102cf4:	68 52 02 00 00       	push   $0x252
f0102cf9:	68 ad 63 10 f0       	push   $0xf01063ad
f0102cfe:	e8 2b d4 ff ff       	call   f010012e <_panic>

f0102d03 <allocate_environment>:
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	E_NO_FREE_ENV if all NENVS environments are allocated
//
int allocate_environment(struct Env** e)
{	
f0102d03:	55                   	push   %ebp
f0102d04:	89 e5                	mov    %esp,%ebp
	if (!(*e = LIST_FIRST(&env_free_list)))
f0102d06:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102d0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d0f:	89 10                	mov    %edx,(%eax)
f0102d11:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d14:	8b 00                	mov    (%eax),%eax
f0102d16:	85 c0                	test   %eax,%eax
f0102d18:	75 07                	jne    f0102d21 <allocate_environment+0x1e>
		return E_NO_FREE_ENV;
f0102d1a:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102d1f:	eb 05                	jmp    f0102d26 <allocate_environment+0x23>
	return 0;
f0102d21:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d26:	5d                   	pop    %ebp
f0102d27:	c3                   	ret    

f0102d28 <free_environment>:

// Free the given environment "e", simply by adding it to the free environment list.
void free_environment(struct Env* e)
{
f0102d28:	55                   	push   %ebp
f0102d29:	89 e5                	mov    %esp,%ebp
	curenv = NULL;	
f0102d2b:	c7 05 50 ef 14 f0 00 	movl   $0x0,0xf014ef50
f0102d32:	00 00 00 
	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d35:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d38:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e);
f0102d3f:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102d45:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d48:	89 50 44             	mov    %edx,0x44(%eax)
f0102d4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d4e:	8b 40 44             	mov    0x44(%eax),%eax
f0102d51:	85 c0                	test   %eax,%eax
f0102d53:	74 0e                	je     f0102d63 <free_environment+0x3b>
f0102d55:	a1 54 ef 14 f0       	mov    0xf014ef54,%eax
f0102d5a:	8b 55 08             	mov    0x8(%ebp),%edx
f0102d5d:	83 c2 44             	add    $0x44,%edx
f0102d60:	89 50 48             	mov    %edx,0x48(%eax)
f0102d63:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d66:	a3 54 ef 14 f0       	mov    %eax,0xf014ef54
f0102d6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d6e:	c7 40 48 54 ef 14 f0 	movl   $0xf014ef54,0x48(%eax)
}
f0102d75:	90                   	nop
f0102d76:	5d                   	pop    %ebp
f0102d77:	c3                   	ret    

f0102d78 <program_segment_alloc_map>:
//
// if the allocation failed, return E_NO_MEM 
// otherwise return 0
//
static int program_segment_alloc_map(struct Env *e, void *va, uint32 length)
{
f0102d78:	55                   	push   %ebp
f0102d79:	89 e5                	mov    %esp,%ebp
f0102d7b:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB6 Hands-on: fill this function. 
	//Comment the following line
	panic("Function is not implemented yet!");
f0102d7e:	83 ec 04             	sub    $0x4,%esp
f0102d81:	68 d8 64 10 f0       	push   $0xf01064d8
f0102d86:	6a 7b                	push   $0x7b
f0102d88:	68 f9 64 10 f0       	push   $0xf01064f9
f0102d8d:	e8 9c d3 ff ff       	call   f010012e <_panic>

f0102d92 <env_create>:
}

//
// Allocates a new env and loads the named user program into it.
struct UserProgramInfo* env_create(char* user_program_name)
{
f0102d92:	55                   	push   %ebp
f0102d93:	89 e5                	mov    %esp,%ebp
f0102d95:	83 ec 38             	sub    $0x38,%esp
	//[1] get pointer to the start of the "user_program_name" program in memory
	// Hint: use "get_user_program_info" function, 
	// you should set the following "ptr_program_start" by the start address of the user program 
	uint8* ptr_program_start = 0; 
f0102d98:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	struct UserProgramInfo* ptr_user_program_info =get_user_program_info(user_program_name);
f0102d9f:	83 ec 0c             	sub    $0xc,%esp
f0102da2:	ff 75 08             	pushl  0x8(%ebp)
f0102da5:	e8 28 05 00 00       	call   f01032d2 <get_user_program_info>
f0102daa:	83 c4 10             	add    $0x10,%esp
f0102dad:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (ptr_user_program_info == 0)
f0102db0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0102db4:	75 07                	jne    f0102dbd <env_create+0x2b>
		return NULL ;
f0102db6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dbb:	eb 42                	jmp    f0102dff <env_create+0x6d>

	ptr_program_start = ptr_user_program_info->ptr_start ;
f0102dbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102dc0:	8b 40 08             	mov    0x8(%eax),%eax
f0102dc3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//[2] allocate new environment, (from the free environment list)
	//if there's no one, return NULL
	// Hint: use "allocate_environment" function
	struct Env* e = NULL;
f0102dc6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	if(allocate_environment(&e) == E_NO_FREE_ENV)
f0102dcd:	83 ec 0c             	sub    $0xc,%esp
f0102dd0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	e8 2a ff ff ff       	call   f0102d03 <allocate_environment>
f0102dd9:	83 c4 10             	add    $0x10,%esp
f0102ddc:	83 f8 fb             	cmp    $0xfffffffb,%eax
f0102ddf:	75 07                	jne    f0102de8 <env_create+0x56>
	{
		return 0;
f0102de1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102de6:	eb 17                	jmp    f0102dff <env_create+0x6d>
	}

	//=========================================================
	//TODO: LAB6 Hands-on: fill this part. 
	//Comment the following line
	panic("env_create: directory creation is not implemented yet!");
f0102de8:	83 ec 04             	sub    $0x4,%esp
f0102deb:	68 14 65 10 f0       	push   $0xf0106514
f0102df0:	68 9f 00 00 00       	push   $0x9f
f0102df5:	68 f9 64 10 f0       	push   $0xf01064f9
f0102dfa:	e8 2f d3 ff ff       	call   f010012e <_panic>

	//[11] switch back to the page directory exists before segment loading
	lcr3(kern_phys_pgdir) ;

	return ptr_user_program_info;
}
f0102dff:	c9                   	leave  
f0102e00:	c3                   	ret    

f0102e01 <env_run>:
// Used to run the given environment "e", simply by 
// context switch from curenv to env e.
//  (This function does not return.)
//
void env_run(struct Env *e)
{
f0102e01:	55                   	push   %ebp
f0102e02:	89 e5                	mov    %esp,%ebp
f0102e04:	83 ec 18             	sub    $0x18,%esp
	if(curenv != e)
f0102e07:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102e0c:	3b 45 08             	cmp    0x8(%ebp),%eax
f0102e0f:	74 25                	je     f0102e36 <env_run+0x35>
	{		
		curenv = e ;
f0102e11:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e14:	a3 50 ef 14 f0       	mov    %eax,0xf014ef50
		curenv->env_runs++ ;
f0102e19:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102e1e:	8b 50 58             	mov    0x58(%eax),%edx
f0102e21:	42                   	inc    %edx
f0102e22:	89 50 58             	mov    %edx,0x58(%eax)
		lcr3(curenv->env_cr3) ;	
f0102e25:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102e2a:	8b 40 60             	mov    0x60(%eax),%eax
f0102e2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e33:	0f 22 d8             	mov    %eax,%cr3
	}	
	env_pop_tf(&(curenv->env_tf));
f0102e36:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102e3b:	83 ec 0c             	sub    $0xc,%esp
f0102e3e:	50                   	push   %eax
f0102e3f:	e8 89 06 00 00       	call   f01034cd <env_pop_tf>

f0102e44 <env_free>:

//
// Frees environment "e" and all memory it uses.
// 
void env_free(struct Env *e)
{
f0102e44:	55                   	push   %ebp
f0102e45:	89 e5                	mov    %esp,%ebp
f0102e47:	83 ec 08             	sub    $0x8,%esp
	panic("env_free function is not completed yet") ;
f0102e4a:	83 ec 04             	sub    $0x4,%esp
f0102e4d:	68 4c 65 10 f0       	push   $0xf010654c
f0102e52:	68 2f 01 00 00       	push   $0x12f
f0102e57:	68 f9 64 10 f0       	push   $0xf01064f9
f0102e5c:	e8 cd d2 ff ff       	call   f010012e <_panic>

f0102e61 <env_init>:
// Insert in reverse order, so that the first call to allocate_environment()
// returns envs[0].
//
void
env_init(void)
{	
f0102e61:	55                   	push   %ebp
f0102e62:	89 e5                	mov    %esp,%ebp
f0102e64:	53                   	push   %ebx
f0102e65:	83 ec 10             	sub    $0x10,%esp
	int iEnv = NENV-1;
f0102e68:	c7 45 f8 ff 03 00 00 	movl   $0x3ff,-0x8(%ebp)
	for(; iEnv >= 0; iEnv--)
f0102e6f:	e9 ed 00 00 00       	jmp    f0102f61 <env_init+0x100>
	{
		envs[iEnv].env_status = ENV_FREE;
f0102e74:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102e7a:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102e7d:	89 d0                	mov    %edx,%eax
f0102e7f:	c1 e0 02             	shl    $0x2,%eax
f0102e82:	01 d0                	add    %edx,%eax
f0102e84:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102e8b:	01 d0                	add    %edx,%eax
f0102e8d:	c1 e0 02             	shl    $0x2,%eax
f0102e90:	01 c8                	add    %ecx,%eax
f0102e92:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[iEnv].env_id = 0;
f0102e99:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102e9f:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102ea2:	89 d0                	mov    %edx,%eax
f0102ea4:	c1 e0 02             	shl    $0x2,%eax
f0102ea7:	01 d0                	add    %edx,%eax
f0102ea9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102eb0:	01 d0                	add    %edx,%eax
f0102eb2:	c1 e0 02             	shl    $0x2,%eax
f0102eb5:	01 c8                	add    %ecx,%eax
f0102eb7:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
f0102ebe:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102ec4:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102ec7:	89 d0                	mov    %edx,%eax
f0102ec9:	c1 e0 02             	shl    $0x2,%eax
f0102ecc:	01 d0                	add    %edx,%eax
f0102ece:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102ed5:	01 d0                	add    %edx,%eax
f0102ed7:	c1 e0 02             	shl    $0x2,%eax
f0102eda:	01 c8                	add    %ecx,%eax
f0102edc:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102ee2:	89 50 44             	mov    %edx,0x44(%eax)
f0102ee5:	8b 40 44             	mov    0x44(%eax),%eax
f0102ee8:	85 c0                	test   %eax,%eax
f0102eea:	74 2a                	je     f0102f16 <env_init+0xb5>
f0102eec:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102ef2:	8b 1d 4c ef 14 f0    	mov    0xf014ef4c,%ebx
f0102ef8:	8b 4d f8             	mov    -0x8(%ebp),%ecx
f0102efb:	89 c8                	mov    %ecx,%eax
f0102efd:	c1 e0 02             	shl    $0x2,%eax
f0102f00:	01 c8                	add    %ecx,%eax
f0102f02:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0102f09:	01 c8                	add    %ecx,%eax
f0102f0b:	c1 e0 02             	shl    $0x2,%eax
f0102f0e:	01 d8                	add    %ebx,%eax
f0102f10:	83 c0 44             	add    $0x44,%eax
f0102f13:	89 42 48             	mov    %eax,0x48(%edx)
f0102f16:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102f1c:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102f1f:	89 d0                	mov    %edx,%eax
f0102f21:	c1 e0 02             	shl    $0x2,%eax
f0102f24:	01 d0                	add    %edx,%eax
f0102f26:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102f2d:	01 d0                	add    %edx,%eax
f0102f2f:	c1 e0 02             	shl    $0x2,%eax
f0102f32:	01 c8                	add    %ecx,%eax
f0102f34:	a3 54 ef 14 f0       	mov    %eax,0xf014ef54
f0102f39:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102f3f:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102f42:	89 d0                	mov    %edx,%eax
f0102f44:	c1 e0 02             	shl    $0x2,%eax
f0102f47:	01 d0                	add    %edx,%eax
f0102f49:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102f50:	01 d0                	add    %edx,%eax
f0102f52:	c1 e0 02             	shl    $0x2,%eax
f0102f55:	01 c8                	add    %ecx,%eax
f0102f57:	c7 40 48 54 ef 14 f0 	movl   $0xf014ef54,0x48(%eax)
//
void
env_init(void)
{	
	int iEnv = NENV-1;
	for(; iEnv >= 0; iEnv--)
f0102f5e:	ff 4d f8             	decl   -0x8(%ebp)
f0102f61:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0102f65:	0f 89 09 ff ff ff    	jns    f0102e74 <env_init+0x13>
	{
		envs[iEnv].env_status = ENV_FREE;
		envs[iEnv].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
	}
}
f0102f6b:	90                   	nop
f0102f6c:	83 c4 10             	add    $0x10,%esp
f0102f6f:	5b                   	pop    %ebx
f0102f70:	5d                   	pop    %ebp
f0102f71:	c3                   	ret    

f0102f72 <complete_environment_initialization>:

void complete_environment_initialization(struct Env* e)
{	
f0102f72:	55                   	push   %ebp
f0102f73:	89 e5                	mov    %esp,%ebp
f0102f75:	83 ec 18             	sub    $0x18,%esp
	//VPT and UVPT map the env's own page table, with
	//different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PERM_PRESENT | PERM_WRITEABLE;
f0102f78:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f7b:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102f7e:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f0102f84:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f87:	8b 40 60             	mov    0x60(%eax),%eax
f0102f8a:	83 c8 03             	or     $0x3,%eax
f0102f8d:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PERM_PRESENT | PERM_USER;
f0102f8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f92:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102f95:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0102f9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f9e:	8b 40 60             	mov    0x60(%eax),%eax
f0102fa1:	83 c8 05             	or     $0x5,%eax
f0102fa4:	89 02                	mov    %eax,(%edx)

	int32 generation;	
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fa6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fa9:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102fac:	05 00 10 00 00       	add    $0x1000,%eax
f0102fb1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0102fb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f0102fb9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102fbd:	7f 07                	jg     f0102fc6 <complete_environment_initialization+0x54>
		generation = 1 << ENVGENSHIFT;
f0102fbf:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f0102fc6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fc9:	8b 15 4c ef 14 f0    	mov    0xf014ef4c,%edx
f0102fcf:	29 d0                	sub    %edx,%eax
f0102fd1:	c1 f8 02             	sar    $0x2,%eax
f0102fd4:	89 c1                	mov    %eax,%ecx
f0102fd6:	89 c8                	mov    %ecx,%eax
f0102fd8:	c1 e0 02             	shl    $0x2,%eax
f0102fdb:	01 c8                	add    %ecx,%eax
f0102fdd:	c1 e0 07             	shl    $0x7,%eax
f0102fe0:	29 c8                	sub    %ecx,%eax
f0102fe2:	c1 e0 03             	shl    $0x3,%eax
f0102fe5:	01 c8                	add    %ecx,%eax
f0102fe7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102fee:	01 d0                	add    %edx,%eax
f0102ff0:	c1 e0 02             	shl    $0x2,%eax
f0102ff3:	01 c8                	add    %ecx,%eax
f0102ff5:	c1 e0 03             	shl    $0x3,%eax
f0102ff8:	01 c8                	add    %ecx,%eax
f0102ffa:	89 c2                	mov    %eax,%edx
f0102ffc:	c1 e2 06             	shl    $0x6,%edx
f0102fff:	29 c2                	sub    %eax,%edx
f0103001:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0103004:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0103007:	8d 04 95 00 00 00 00 	lea    0x0(,%edx,4),%eax
f010300e:	01 c2                	add    %eax,%edx
f0103010:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0103013:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0103016:	89 d0                	mov    %edx,%eax
f0103018:	f7 d8                	neg    %eax
f010301a:	0b 45 f4             	or     -0xc(%ebp),%eax
f010301d:	89 c2                	mov    %eax,%edx
f010301f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103022:	89 50 4c             	mov    %edx,0x4c(%eax)

	// Set the basic status variables.
	e->env_parent_id = 0;//parent_id;
f0103025:	8b 45 08             	mov    0x8(%ebp),%eax
f0103028:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f010302f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103032:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f0103039:	8b 45 08             	mov    0x8(%ebp),%eax
f010303c:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103043:	8b 45 08             	mov    0x8(%ebp),%eax
f0103046:	83 ec 04             	sub    $0x4,%esp
f0103049:	6a 44                	push   $0x44
f010304b:	6a 00                	push   $0x0
f010304d:	50                   	push   %eax
f010304e:	e8 38 1c 00 00       	call   f0104c8b <memset>
f0103053:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	e->env_tf.tf_ds = GD_UD | 3;
f0103056:	8b 45 08             	mov    0x8(%ebp),%eax
f0103059:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f010305f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103062:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f0103068:	8b 45 08             	mov    0x8(%ebp),%eax
f010306b:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = (uint32*)USTACKTOP;
f0103071:	8b 45 08             	mov    0x8(%ebp),%eax
f0103074:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f010307b:	8b 45 08             	mov    0x8(%ebp),%eax
f010307e:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e);	
f0103084:	8b 45 08             	mov    0x8(%ebp),%eax
f0103087:	8b 40 44             	mov    0x44(%eax),%eax
f010308a:	85 c0                	test   %eax,%eax
f010308c:	74 0f                	je     f010309d <complete_environment_initialization+0x12b>
f010308e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103091:	8b 40 44             	mov    0x44(%eax),%eax
f0103094:	8b 55 08             	mov    0x8(%ebp),%edx
f0103097:	8b 52 48             	mov    0x48(%edx),%edx
f010309a:	89 50 48             	mov    %edx,0x48(%eax)
f010309d:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a0:	8b 40 48             	mov    0x48(%eax),%eax
f01030a3:	8b 55 08             	mov    0x8(%ebp),%edx
f01030a6:	8b 52 44             	mov    0x44(%edx),%edx
f01030a9:	89 10                	mov    %edx,(%eax)
	return ;
f01030ab:	90                   	nop
}
f01030ac:	c9                   	leave  
f01030ad:	c3                   	ret    

f01030ae <PROGRAM_SEGMENT_NEXT>:

struct ProgramSegment* PROGRAM_SEGMENT_NEXT(struct ProgramSegment* seg, uint8* ptr_program_start)
				{
f01030ae:	55                   	push   %ebp
f01030af:	89 e5                	mov    %esp,%ebp
f01030b1:	83 ec 18             	sub    $0x18,%esp
	int index = (*seg).segment_id++;
f01030b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01030b7:	8b 40 10             	mov    0x10(%eax),%eax
f01030ba:	8d 48 01             	lea    0x1(%eax),%ecx
f01030bd:	8b 55 08             	mov    0x8(%ebp),%edx
f01030c0:	89 4a 10             	mov    %ecx,0x10(%edx)
f01030c3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01030c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01030cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030cf:	8b 00                	mov    (%eax),%eax
f01030d1:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01030d6:	74 17                	je     f01030ef <PROGRAM_SEGMENT_NEXT+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01030d8:	83 ec 04             	sub    $0x4,%esp
f01030db:	68 73 65 10 f0       	push   $0xf0106573
f01030e0:	68 88 01 00 00       	push   $0x188
f01030e5:	68 f9 64 10 f0       	push   $0xf01064f9
f01030ea:	e8 3f d0 ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01030ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030f2:	8b 50 1c             	mov    0x1c(%eax),%edx
f01030f5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030f8:	01 d0                	add    %edx,%eax
f01030fa:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (ph[(*seg).segment_id].p_type != ELF_PROG_LOAD && ((*seg).segment_id < pELFHDR->e_phnum)) (*seg).segment_id++;	
f01030fd:	eb 0f                	jmp    f010310e <PROGRAM_SEGMENT_NEXT+0x60>
f01030ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103102:	8b 40 10             	mov    0x10(%eax),%eax
f0103105:	8d 50 01             	lea    0x1(%eax),%edx
f0103108:	8b 45 08             	mov    0x8(%ebp),%eax
f010310b:	89 50 10             	mov    %edx,0x10(%eax)
f010310e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103111:	8b 40 10             	mov    0x10(%eax),%eax
f0103114:	c1 e0 05             	shl    $0x5,%eax
f0103117:	89 c2                	mov    %eax,%edx
f0103119:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010311c:	01 d0                	add    %edx,%eax
f010311e:	8b 00                	mov    (%eax),%eax
f0103120:	83 f8 01             	cmp    $0x1,%eax
f0103123:	74 13                	je     f0103138 <PROGRAM_SEGMENT_NEXT+0x8a>
f0103125:	8b 45 08             	mov    0x8(%ebp),%eax
f0103128:	8b 50 10             	mov    0x10(%eax),%edx
f010312b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010312e:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103131:	0f b7 c0             	movzwl %ax,%eax
f0103134:	39 c2                	cmp    %eax,%edx
f0103136:	72 c7                	jb     f01030ff <PROGRAM_SEGMENT_NEXT+0x51>
	index = (*seg).segment_id;
f0103138:	8b 45 08             	mov    0x8(%ebp),%eax
f010313b:	8b 40 10             	mov    0x10(%eax),%eax
f010313e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(index < pELFHDR->e_phnum)
f0103141:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103144:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103147:	0f b7 c0             	movzwl %ax,%eax
f010314a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f010314d:	7e 63                	jle    f01031b2 <PROGRAM_SEGMENT_NEXT+0x104>
	{
		(*seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f010314f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103152:	c1 e0 05             	shl    $0x5,%eax
f0103155:	89 c2                	mov    %eax,%edx
f0103157:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010315a:	01 d0                	add    %edx,%eax
f010315c:	8b 50 04             	mov    0x4(%eax),%edx
f010315f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103162:	01 c2                	add    %eax,%edx
f0103164:	8b 45 08             	mov    0x8(%ebp),%eax
f0103167:	89 10                	mov    %edx,(%eax)
		(*seg).size_in_memory =  ph[index].p_memsz;
f0103169:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010316c:	c1 e0 05             	shl    $0x5,%eax
f010316f:	89 c2                	mov    %eax,%edx
f0103171:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103174:	01 d0                	add    %edx,%eax
f0103176:	8b 50 14             	mov    0x14(%eax),%edx
f0103179:	8b 45 08             	mov    0x8(%ebp),%eax
f010317c:	89 50 08             	mov    %edx,0x8(%eax)
		(*seg).size_in_file = ph[index].p_filesz;
f010317f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103182:	c1 e0 05             	shl    $0x5,%eax
f0103185:	89 c2                	mov    %eax,%edx
f0103187:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010318a:	01 d0                	add    %edx,%eax
f010318c:	8b 50 10             	mov    0x10(%eax),%edx
f010318f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103192:	89 50 04             	mov    %edx,0x4(%eax)
		(*seg).virtual_address = (uint8*)ph[index].p_va;
f0103195:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103198:	c1 e0 05             	shl    $0x5,%eax
f010319b:	89 c2                	mov    %eax,%edx
f010319d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01031a0:	01 d0                	add    %edx,%eax
f01031a2:	8b 40 08             	mov    0x8(%eax),%eax
f01031a5:	89 c2                	mov    %eax,%edx
f01031a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031aa:	89 50 0c             	mov    %edx,0xc(%eax)
		return seg;
f01031ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b0:	eb 05                	jmp    f01031b7 <PROGRAM_SEGMENT_NEXT+0x109>
	}
	return 0;
f01031b2:	b8 00 00 00 00       	mov    $0x0,%eax
				}
f01031b7:	c9                   	leave  
f01031b8:	c3                   	ret    

f01031b9 <PROGRAM_SEGMENT_FIRST>:

struct ProgramSegment PROGRAM_SEGMENT_FIRST( uint8* ptr_program_start)
{
f01031b9:	55                   	push   %ebp
f01031ba:	89 e5                	mov    %esp,%ebp
f01031bc:	57                   	push   %edi
f01031bd:	56                   	push   %esi
f01031be:	53                   	push   %ebx
f01031bf:	83 ec 2c             	sub    $0x2c,%esp
	struct ProgramSegment seg;
	seg.segment_id = 0;
f01031c2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01031c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01031cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031d2:	8b 00                	mov    (%eax),%eax
f01031d4:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01031d9:	74 17                	je     f01031f2 <PROGRAM_SEGMENT_FIRST+0x39>
		panic("Matafa2nash 3ala Keda"); 
f01031db:	83 ec 04             	sub    $0x4,%esp
f01031de:	68 73 65 10 f0       	push   $0xf0106573
f01031e3:	68 a1 01 00 00       	push   $0x1a1
f01031e8:	68 f9 64 10 f0       	push   $0xf01064f9
f01031ed:	e8 3c cf ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01031f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031f5:	8b 50 1c             	mov    0x1c(%eax),%edx
f01031f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031fb:	01 d0                	add    %edx,%eax
f01031fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while (ph[(seg).segment_id].p_type != ELF_PROG_LOAD && ((seg).segment_id < pELFHDR->e_phnum)) (seg).segment_id++;
f0103200:	eb 07                	jmp    f0103209 <PROGRAM_SEGMENT_FIRST+0x50>
f0103202:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103205:	40                   	inc    %eax
f0103206:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103209:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010320c:	c1 e0 05             	shl    $0x5,%eax
f010320f:	89 c2                	mov    %eax,%edx
f0103211:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103214:	01 d0                	add    %edx,%eax
f0103216:	8b 00                	mov    (%eax),%eax
f0103218:	83 f8 01             	cmp    $0x1,%eax
f010321b:	74 10                	je     f010322d <PROGRAM_SEGMENT_FIRST+0x74>
f010321d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103220:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103223:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103226:	0f b7 c0             	movzwl %ax,%eax
f0103229:	39 c2                	cmp    %eax,%edx
f010322b:	72 d5                	jb     f0103202 <PROGRAM_SEGMENT_FIRST+0x49>
	int index = (seg).segment_id;
f010322d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103230:	89 45 dc             	mov    %eax,-0x24(%ebp)

	if(index < pELFHDR->e_phnum)
f0103233:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103236:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103239:	0f b7 c0             	movzwl %ax,%eax
f010323c:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010323f:	7e 68                	jle    f01032a9 <PROGRAM_SEGMENT_FIRST+0xf0>
	{	
		(seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f0103241:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103244:	c1 e0 05             	shl    $0x5,%eax
f0103247:	89 c2                	mov    %eax,%edx
f0103249:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010324c:	01 d0                	add    %edx,%eax
f010324e:	8b 50 04             	mov    0x4(%eax),%edx
f0103251:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103254:	01 d0                	add    %edx,%eax
f0103256:	89 45 c8             	mov    %eax,-0x38(%ebp)
		(seg).size_in_memory =  ph[index].p_memsz;
f0103259:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010325c:	c1 e0 05             	shl    $0x5,%eax
f010325f:	89 c2                	mov    %eax,%edx
f0103261:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103264:	01 d0                	add    %edx,%eax
f0103266:	8b 40 14             	mov    0x14(%eax),%eax
f0103269:	89 45 d0             	mov    %eax,-0x30(%ebp)
		(seg).size_in_file = ph[index].p_filesz;
f010326c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010326f:	c1 e0 05             	shl    $0x5,%eax
f0103272:	89 c2                	mov    %eax,%edx
f0103274:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103277:	01 d0                	add    %edx,%eax
f0103279:	8b 40 10             	mov    0x10(%eax),%eax
f010327c:	89 45 cc             	mov    %eax,-0x34(%ebp)
		(seg).virtual_address = (uint8*)ph[index].p_va;
f010327f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103282:	c1 e0 05             	shl    $0x5,%eax
f0103285:	89 c2                	mov    %eax,%edx
f0103287:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010328a:	01 d0                	add    %edx,%eax
f010328c:	8b 40 08             	mov    0x8(%eax),%eax
f010328f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		return seg;
f0103292:	8b 45 08             	mov    0x8(%ebp),%eax
f0103295:	89 c3                	mov    %eax,%ebx
f0103297:	8d 45 c8             	lea    -0x38(%ebp),%eax
f010329a:	ba 05 00 00 00       	mov    $0x5,%edx
f010329f:	89 df                	mov    %ebx,%edi
f01032a1:	89 c6                	mov    %eax,%esi
f01032a3:	89 d1                	mov    %edx,%ecx
f01032a5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032a7:	eb 1c                	jmp    f01032c5 <PROGRAM_SEGMENT_FIRST+0x10c>
	}
	seg.segment_id = -1;
f01032a9:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
	return seg;
f01032b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b3:	89 c3                	mov    %eax,%ebx
f01032b5:	8d 45 c8             	lea    -0x38(%ebp),%eax
f01032b8:	ba 05 00 00 00       	mov    $0x5,%edx
f01032bd:	89 df                	mov    %ebx,%edi
f01032bf:	89 c6                	mov    %eax,%esi
f01032c1:	89 d1                	mov    %edx,%ecx
f01032c3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
}
f01032c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01032c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032cb:	5b                   	pop    %ebx
f01032cc:	5e                   	pop    %esi
f01032cd:	5f                   	pop    %edi
f01032ce:	5d                   	pop    %ebp
f01032cf:	c2 04 00             	ret    $0x4

f01032d2 <get_user_program_info>:

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
f01032d2:	55                   	push   %ebp
f01032d3:	89 e5                	mov    %esp,%ebp
f01032d5:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f01032d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01032df:	eb 23                	jmp    f0103304 <get_user_program_info+0x32>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
f01032e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01032e4:	c1 e0 04             	shl    $0x4,%eax
f01032e7:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
f01032ec:	8b 00                	mov    (%eax),%eax
f01032ee:	83 ec 08             	sub    $0x8,%esp
f01032f1:	50                   	push   %eax
f01032f2:	ff 75 08             	pushl  0x8(%ebp)
f01032f5:	e8 af 18 00 00       	call   f0104ba9 <strcmp>
f01032fa:	83 c4 10             	add    $0x10,%esp
f01032fd:	85 c0                	test   %eax,%eax
f01032ff:	74 0f                	je     f0103310 <get_user_program_info+0x3e>
}

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0103301:	ff 45 f4             	incl   -0xc(%ebp)
f0103304:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f0103309:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010330c:	7c d3                	jl     f01032e1 <get_user_program_info+0xf>
f010330e:	eb 01                	jmp    f0103311 <get_user_program_info+0x3f>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
			break;
f0103310:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f0103311:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f0103316:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0103319:	75 1a                	jne    f0103335 <get_user_program_info+0x63>
	{
		cprintf("Unknown user program '%s'\n", user_program_name);
f010331b:	83 ec 08             	sub    $0x8,%esp
f010331e:	ff 75 08             	pushl  0x8(%ebp)
f0103321:	68 89 65 10 f0       	push   $0xf0106589
f0103326:	e8 7e 02 00 00       	call   f01035a9 <cprintf>
f010332b:	83 c4 10             	add    $0x10,%esp
		return 0;
f010332e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103333:	eb 0b                	jmp    f0103340 <get_user_program_info+0x6e>
	}

	return &userPrograms[i];
f0103335:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103338:	c1 e0 04             	shl    $0x4,%eax
f010333b:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
				}
f0103340:	c9                   	leave  
f0103341:	c3                   	ret    

f0103342 <get_user_program_info_by_env>:

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
f0103342:	55                   	push   %ebp
f0103343:	89 e5                	mov    %esp,%ebp
f0103345:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0103348:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010334f:	eb 15                	jmp    f0103366 <get_user_program_info_by_env+0x24>
		if (e== userPrograms[i].environment)
f0103351:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103354:	c1 e0 04             	shl    $0x4,%eax
f0103357:	05 ac c6 11 f0       	add    $0xf011c6ac,%eax
f010335c:	8b 00                	mov    (%eax),%eax
f010335e:	3b 45 08             	cmp    0x8(%ebp),%eax
f0103361:	74 0f                	je     f0103372 <get_user_program_info_by_env+0x30>
				}

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0103363:	ff 45 f4             	incl   -0xc(%ebp)
f0103366:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f010336b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010336e:	7c e1                	jl     f0103351 <get_user_program_info_by_env+0xf>
f0103370:	eb 01                	jmp    f0103373 <get_user_program_info_by_env+0x31>
		if (e== userPrograms[i].environment)
			break;
f0103372:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f0103373:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f0103378:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010337b:	75 17                	jne    f0103394 <get_user_program_info_by_env+0x52>
	{
		cprintf("Unknown user program \n");
f010337d:	83 ec 0c             	sub    $0xc,%esp
f0103380:	68 a4 65 10 f0       	push   $0xf01065a4
f0103385:	e8 1f 02 00 00       	call   f01035a9 <cprintf>
f010338a:	83 c4 10             	add    $0x10,%esp
		return 0;
f010338d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103392:	eb 0b                	jmp    f010339f <get_user_program_info_by_env+0x5d>
	}

	return &userPrograms[i];
f0103394:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103397:	c1 e0 04             	shl    $0x4,%eax
f010339a:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
				}
f010339f:	c9                   	leave  
f01033a0:	c3                   	ret    

f01033a1 <set_environment_entry_point>:

void set_environment_entry_point(struct UserProgramInfo* ptr_user_program)
{
f01033a1:	55                   	push   %ebp
f01033a2:	89 e5                	mov    %esp,%ebp
f01033a4:	83 ec 18             	sub    $0x18,%esp
	uint8* ptr_program_start=ptr_user_program->ptr_start;
f01033a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01033aa:	8b 40 08             	mov    0x8(%eax),%eax
f01033ad:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Env* e = ptr_user_program->environment;
f01033b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b3:	8b 40 0c             	mov    0xc(%eax),%eax
f01033b6:	89 45 f0             	mov    %eax,-0x10(%ebp)

	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01033b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01033bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01033bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01033c2:	8b 00                	mov    (%eax),%eax
f01033c4:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01033c9:	74 17                	je     f01033e2 <set_environment_entry_point+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01033cb:	83 ec 04             	sub    $0x4,%esp
f01033ce:	68 73 65 10 f0       	push   $0xf0106573
f01033d3:	68 d9 01 00 00       	push   $0x1d9
f01033d8:	68 f9 64 10 f0       	push   $0xf01064f9
f01033dd:	e8 4c cd ff ff       	call   f010012e <_panic>
	e->env_tf.tf_eip = (uint32*)pELFHDR->e_entry ;
f01033e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01033e5:	8b 40 18             	mov    0x18(%eax),%eax
f01033e8:	89 c2                	mov    %eax,%edx
f01033ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01033ed:	89 50 30             	mov    %edx,0x30(%eax)
}
f01033f0:	90                   	nop
f01033f1:	c9                   	leave  
f01033f2:	c3                   	ret    

f01033f3 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f01033f3:	55                   	push   %ebp
f01033f4:	89 e5                	mov    %esp,%ebp
f01033f6:	83 ec 08             	sub    $0x8,%esp
	env_free(e);
f01033f9:	83 ec 0c             	sub    $0xc,%esp
f01033fc:	ff 75 08             	pushl  0x8(%ebp)
f01033ff:	e8 40 fa ff ff       	call   f0102e44 <env_free>
f0103404:	83 c4 10             	add    $0x10,%esp

	//cprintf("Destroyed the only environment - nothing more to do!\n");
	while (1)
		run_command_prompt();
f0103407:	e8 45 d5 ff ff       	call   f0100951 <run_command_prompt>
f010340c:	eb f9                	jmp    f0103407 <env_destroy+0x14>

f010340e <env_run_cmd_prmpt>:
}

void env_run_cmd_prmpt()
{
f010340e:	55                   	push   %ebp
f010340f:	89 e5                	mov    %esp,%ebp
f0103411:	83 ec 18             	sub    $0x18,%esp
	struct UserProgramInfo* upi= get_user_program_info_by_env(curenv);	
f0103414:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103419:	83 ec 0c             	sub    $0xc,%esp
f010341c:	50                   	push   %eax
f010341d:	e8 20 ff ff ff       	call   f0103342 <get_user_program_info_by_env>
f0103422:	83 c4 10             	add    $0x10,%esp
f0103425:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&curenv->env_tf, 0, sizeof(curenv->env_tf));
f0103428:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f010342d:	83 ec 04             	sub    $0x4,%esp
f0103430:	6a 44                	push   $0x44
f0103432:	6a 00                	push   $0x0
f0103434:	50                   	push   %eax
f0103435:	e8 51 18 00 00       	call   f0104c8b <memset>
f010343a:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	curenv->env_tf.tf_ds = GD_UD | 3;
f010343d:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103442:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	curenv->env_tf.tf_es = GD_UD | 3;
f0103448:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f010344d:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	curenv->env_tf.tf_ss = GD_UD | 3;
f0103453:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103458:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	curenv->env_tf.tf_esp = (uint32*)USTACKTOP;
f010345e:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103463:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	curenv->env_tf.tf_cs = GD_UT | 3;
f010346a:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f010346f:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	set_environment_entry_point(upi);
f0103475:	83 ec 0c             	sub    $0xc,%esp
f0103478:	ff 75 f4             	pushl  -0xc(%ebp)
f010347b:	e8 21 ff ff ff       	call   f01033a1 <set_environment_entry_point>
f0103480:	83 c4 10             	add    $0x10,%esp

	lcr3(K_PHYSICAL_ADDRESS(ptr_page_directory));
f0103483:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0103488:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010348b:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0103492:	77 17                	ja     f01034ab <env_run_cmd_prmpt+0x9d>
f0103494:	ff 75 f0             	pushl  -0x10(%ebp)
f0103497:	68 bc 65 10 f0       	push   $0xf01065bc
f010349c:	68 04 02 00 00       	push   $0x204
f01034a1:	68 f9 64 10 f0       	push   $0xf01064f9
f01034a6:	e8 83 cc ff ff       	call   f010012e <_panic>
f01034ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01034ae:	05 00 00 00 10       	add    $0x10000000,%eax
f01034b3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01034b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01034b9:	0f 22 d8             	mov    %eax,%cr3

	curenv = NULL;
f01034bc:	c7 05 50 ef 14 f0 00 	movl   $0x0,0xf014ef50
f01034c3:	00 00 00 

	while (1)
		run_command_prompt();
f01034c6:	e8 86 d4 ff ff       	call   f0100951 <run_command_prompt>
f01034cb:	eb f9                	jmp    f01034c6 <env_run_cmd_prmpt+0xb8>

f01034cd <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01034cd:	55                   	push   %ebp
f01034ce:	89 e5                	mov    %esp,%ebp
f01034d0:	83 ec 08             	sub    $0x8,%esp
	__asm __volatile("movl %0,%%esp\n"
f01034d3:	8b 65 08             	mov    0x8(%ebp),%esp
f01034d6:	61                   	popa   
f01034d7:	07                   	pop    %es
f01034d8:	1f                   	pop    %ds
f01034d9:	83 c4 08             	add    $0x8,%esp
f01034dc:	cf                   	iret   
			"\tpopl %%es\n"
			"\tpopl %%ds\n"
			"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
			"\tiret"
			: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01034dd:	83 ec 04             	sub    $0x4,%esp
f01034e0:	68 ed 65 10 f0       	push   $0xf01065ed
f01034e5:	68 1b 02 00 00       	push   $0x21b
f01034ea:	68 f9 64 10 f0       	push   $0xf01064f9
f01034ef:	e8 3a cc ff ff       	call   f010012e <_panic>

f01034f4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034f4:	55                   	push   %ebp
f01034f5:	89 e5                	mov    %esp,%ebp
f01034f7:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f01034fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fd:	0f b6 c0             	movzbl %al,%eax
f0103500:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0103507:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010350a:	8a 45 f6             	mov    -0xa(%ebp),%al
f010350d:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103510:	ee                   	out    %al,(%dx)
f0103511:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103518:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010351b:	89 c2                	mov    %eax,%edx
f010351d:	ec                   	in     (%dx),%al
f010351e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f0103521:	8a 45 f7             	mov    -0x9(%ebp),%al
	return inb(IO_RTC+1);
f0103524:	0f b6 c0             	movzbl %al,%eax
}
f0103527:	c9                   	leave  
f0103528:	c3                   	ret    

f0103529 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103529:	55                   	push   %ebp
f010352a:	89 e5                	mov    %esp,%ebp
f010352c:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f010352f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103532:	0f b6 c0             	movzbl %al,%eax
f0103535:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f010353c:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010353f:	8a 45 f6             	mov    -0xa(%ebp),%al
f0103542:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103545:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f0103546:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103549:	0f b6 c0             	movzbl %al,%eax
f010354c:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)
f0103553:	88 45 f7             	mov    %al,-0x9(%ebp)
f0103556:	8a 45 f7             	mov    -0x9(%ebp),%al
f0103559:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010355c:	ee                   	out    %al,(%dx)
}
f010355d:	90                   	nop
f010355e:	c9                   	leave  
f010355f:	c3                   	ret    

f0103560 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103560:	55                   	push   %ebp
f0103561:	89 e5                	mov    %esp,%ebp
f0103563:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0103566:	83 ec 0c             	sub    $0xc,%esp
f0103569:	ff 75 08             	pushl  0x8(%ebp)
f010356c:	e8 a6 d3 ff ff       	call   f0100917 <cputchar>
f0103571:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f0103574:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103577:	83 c0 04             	add    $0x4,%eax
f010357a:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f010357d:	90                   	nop
f010357e:	c9                   	leave  
f010357f:	c3                   	ret    

f0103580 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103580:	55                   	push   %ebp
f0103581:	89 e5                	mov    %esp,%ebp
f0103583:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103586:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010358d:	ff 75 0c             	pushl  0xc(%ebp)
f0103590:	ff 75 08             	pushl  0x8(%ebp)
f0103593:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103596:	50                   	push   %eax
f0103597:	68 60 35 10 f0       	push   $0xf0103560
f010359c:	e8 56 0f 00 00       	call   f01044f7 <vprintfmt>
f01035a1:	83 c4 10             	add    $0x10,%esp
	return cnt;
f01035a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01035a7:	c9                   	leave  
f01035a8:	c3                   	ret    

f01035a9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01035a9:	55                   	push   %ebp
f01035aa:	89 e5                	mov    %esp,%ebp
f01035ac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01035af:	8d 45 0c             	lea    0xc(%ebp),%eax
f01035b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f01035b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035b8:	83 ec 08             	sub    $0x8,%esp
f01035bb:	ff 75 f4             	pushl  -0xc(%ebp)
f01035be:	50                   	push   %eax
f01035bf:	e8 bc ff ff ff       	call   f0103580 <vcprintf>
f01035c4:	83 c4 10             	add    $0x10,%esp
f01035c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f01035ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f01035cd:	c9                   	leave  
f01035ce:	c3                   	ret    

f01035cf <trapname>:
};
extern  void (*PAGE_FAULT)();
extern  void (*SYSCALL_HANDLER)();

static const char *trapname(int trapno)
{
f01035cf:	55                   	push   %ebp
f01035d0:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01035d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01035d5:	83 f8 13             	cmp    $0x13,%eax
f01035d8:	77 0c                	ja     f01035e6 <trapname+0x17>
		return excnames[trapno];
f01035da:	8b 45 08             	mov    0x8(%ebp),%eax
f01035dd:	8b 04 85 20 69 10 f0 	mov    -0xfef96e0(,%eax,4),%eax
f01035e4:	eb 12                	jmp    f01035f8 <trapname+0x29>
	if (trapno == T_SYSCALL)
f01035e6:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
f01035ea:	75 07                	jne    f01035f3 <trapname+0x24>
		return "System call";
f01035ec:	b8 00 66 10 f0       	mov    $0xf0106600,%eax
f01035f1:	eb 05                	jmp    f01035f8 <trapname+0x29>
	return "(unknown trap)";
f01035f3:	b8 0c 66 10 f0       	mov    $0xf010660c,%eax
}
f01035f8:	5d                   	pop    %ebp
f01035f9:	c3                   	ret    

f01035fa <idt_init>:


void
idt_init(void)
{
f01035fa:	55                   	push   %ebp
f01035fb:	89 e5                	mov    %esp,%ebp
f01035fd:	83 ec 10             	sub    $0x10,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	//initialize idt
	SETGATE(idt[T_PGFLT], 0, GD_KT , &PAGE_FAULT, 0) ;
f0103600:	b8 58 3b 10 f0       	mov    $0xf0103b58,%eax
f0103605:	66 a3 d0 ef 14 f0    	mov    %ax,0xf014efd0
f010360b:	66 c7 05 d2 ef 14 f0 	movw   $0x8,0xf014efd2
f0103612:	08 00 
f0103614:	a0 d4 ef 14 f0       	mov    0xf014efd4,%al
f0103619:	83 e0 e0             	and    $0xffffffe0,%eax
f010361c:	a2 d4 ef 14 f0       	mov    %al,0xf014efd4
f0103621:	a0 d4 ef 14 f0       	mov    0xf014efd4,%al
f0103626:	83 e0 1f             	and    $0x1f,%eax
f0103629:	a2 d4 ef 14 f0       	mov    %al,0xf014efd4
f010362e:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103633:	83 e0 f0             	and    $0xfffffff0,%eax
f0103636:	83 c8 0e             	or     $0xe,%eax
f0103639:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f010363e:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103643:	83 e0 ef             	and    $0xffffffef,%eax
f0103646:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f010364b:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103650:	83 e0 9f             	and    $0xffffff9f,%eax
f0103653:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f0103658:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f010365d:	83 c8 80             	or     $0xffffff80,%eax
f0103660:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f0103665:	b8 58 3b 10 f0       	mov    $0xf0103b58,%eax
f010366a:	c1 e8 10             	shr    $0x10,%eax
f010366d:	66 a3 d6 ef 14 f0    	mov    %ax,0xf014efd6
	SETGATE(idt[T_SYSCALL], 0, GD_KT , &SYSCALL_HANDLER, 3) ;
f0103673:	b8 5c 3b 10 f0       	mov    $0xf0103b5c,%eax
f0103678:	66 a3 e0 f0 14 f0    	mov    %ax,0xf014f0e0
f010367e:	66 c7 05 e2 f0 14 f0 	movw   $0x8,0xf014f0e2
f0103685:	08 00 
f0103687:	a0 e4 f0 14 f0       	mov    0xf014f0e4,%al
f010368c:	83 e0 e0             	and    $0xffffffe0,%eax
f010368f:	a2 e4 f0 14 f0       	mov    %al,0xf014f0e4
f0103694:	a0 e4 f0 14 f0       	mov    0xf014f0e4,%al
f0103699:	83 e0 1f             	and    $0x1f,%eax
f010369c:	a2 e4 f0 14 f0       	mov    %al,0xf014f0e4
f01036a1:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01036a6:	83 e0 f0             	and    $0xfffffff0,%eax
f01036a9:	83 c8 0e             	or     $0xe,%eax
f01036ac:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01036b1:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01036b6:	83 e0 ef             	and    $0xffffffef,%eax
f01036b9:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01036be:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01036c3:	83 c8 60             	or     $0x60,%eax
f01036c6:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01036cb:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01036d0:	83 c8 80             	or     $0xffffff80,%eax
f01036d3:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01036d8:	b8 5c 3b 10 f0       	mov    $0xf0103b5c,%eax
f01036dd:	c1 e8 10             	shr    $0x10,%eax
f01036e0:	66 a3 e6 f0 14 f0    	mov    %ax,0xf014f0e6

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KERNEL_STACK_TOP;
f01036e6:	c7 05 64 f7 14 f0 00 	movl   $0xefc00000,0xf014f764
f01036ed:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f01036f0:	66 c7 05 68 f7 14 f0 	movw   $0x10,0xf014f768
f01036f7:	10 00 

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32) (&ts),
f01036f9:	66 c7 05 88 c6 11 f0 	movw   $0x68,0xf011c688
f0103700:	68 00 
f0103702:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f0103707:	66 a3 8a c6 11 f0    	mov    %ax,0xf011c68a
f010370d:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f0103712:	c1 e8 10             	shr    $0x10,%eax
f0103715:	a2 8c c6 11 f0       	mov    %al,0xf011c68c
f010371a:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f010371f:	83 e0 f0             	and    $0xfffffff0,%eax
f0103722:	83 c8 09             	or     $0x9,%eax
f0103725:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f010372a:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f010372f:	83 c8 10             	or     $0x10,%eax
f0103732:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f0103737:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f010373c:	83 e0 9f             	and    $0xffffff9f,%eax
f010373f:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f0103744:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f0103749:	83 c8 80             	or     $0xffffff80,%eax
f010374c:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f0103751:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f0103756:	83 e0 f0             	and    $0xfffffff0,%eax
f0103759:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f010375e:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f0103763:	83 e0 ef             	and    $0xffffffef,%eax
f0103766:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f010376b:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f0103770:	83 e0 df             	and    $0xffffffdf,%eax
f0103773:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f0103778:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f010377d:	83 c8 40             	or     $0x40,%eax
f0103780:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f0103785:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f010378a:	83 e0 7f             	and    $0x7f,%eax
f010378d:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f0103792:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f0103797:	c1 e8 18             	shr    $0x18,%eax
f010379a:	a2 8f c6 11 f0       	mov    %al,0xf011c68f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;
f010379f:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f01037a4:	83 e0 ef             	and    $0xffffffef,%eax
f01037a7:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f01037ac:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
}

static __inline void
ltr(uint16 sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01037b2:	66 8b 45 fe          	mov    -0x2(%ebp),%ax
f01037b6:	0f 00 d8             	ltr    %ax

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
f01037b9:	0f 01 1d f8 c6 11 f0 	lidtl  0xf011c6f8
}
f01037c0:	90                   	nop
f01037c1:	c9                   	leave  
f01037c2:	c3                   	ret    

f01037c3 <print_trapframe>:

void
print_trapframe(struct Trapframe *tf)
{
f01037c3:	55                   	push   %ebp
f01037c4:	89 e5                	mov    %esp,%ebp
f01037c6:	83 ec 08             	sub    $0x8,%esp
	cprintf("TRAP frame at %p\n", tf);
f01037c9:	83 ec 08             	sub    $0x8,%esp
f01037cc:	ff 75 08             	pushl  0x8(%ebp)
f01037cf:	68 1b 66 10 f0       	push   $0xf010661b
f01037d4:	e8 d0 fd ff ff       	call   f01035a9 <cprintf>
f01037d9:	83 c4 10             	add    $0x10,%esp
	print_regs(&tf->tf_regs);
f01037dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01037df:	83 ec 0c             	sub    $0xc,%esp
f01037e2:	50                   	push   %eax
f01037e3:	e8 f6 00 00 00       	call   f01038de <print_regs>
f01037e8:	83 c4 10             	add    $0x10,%esp
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01037eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ee:	8b 40 20             	mov    0x20(%eax),%eax
f01037f1:	0f b7 c0             	movzwl %ax,%eax
f01037f4:	83 ec 08             	sub    $0x8,%esp
f01037f7:	50                   	push   %eax
f01037f8:	68 2d 66 10 f0       	push   $0xf010662d
f01037fd:	e8 a7 fd ff ff       	call   f01035a9 <cprintf>
f0103802:	83 c4 10             	add    $0x10,%esp
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103805:	8b 45 08             	mov    0x8(%ebp),%eax
f0103808:	8b 40 24             	mov    0x24(%eax),%eax
f010380b:	0f b7 c0             	movzwl %ax,%eax
f010380e:	83 ec 08             	sub    $0x8,%esp
f0103811:	50                   	push   %eax
f0103812:	68 40 66 10 f0       	push   $0xf0106640
f0103817:	e8 8d fd ff ff       	call   f01035a9 <cprintf>
f010381c:	83 c4 10             	add    $0x10,%esp
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010381f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103822:	8b 40 28             	mov    0x28(%eax),%eax
f0103825:	83 ec 0c             	sub    $0xc,%esp
f0103828:	50                   	push   %eax
f0103829:	e8 a1 fd ff ff       	call   f01035cf <trapname>
f010382e:	83 c4 10             	add    $0x10,%esp
f0103831:	89 c2                	mov    %eax,%edx
f0103833:	8b 45 08             	mov    0x8(%ebp),%eax
f0103836:	8b 40 28             	mov    0x28(%eax),%eax
f0103839:	83 ec 04             	sub    $0x4,%esp
f010383c:	52                   	push   %edx
f010383d:	50                   	push   %eax
f010383e:	68 53 66 10 f0       	push   $0xf0106653
f0103843:	e8 61 fd ff ff       	call   f01035a9 <cprintf>
f0103848:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x\n", tf->tf_err);
f010384b:	8b 45 08             	mov    0x8(%ebp),%eax
f010384e:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103851:	83 ec 08             	sub    $0x8,%esp
f0103854:	50                   	push   %eax
f0103855:	68 65 66 10 f0       	push   $0xf0106665
f010385a:	e8 4a fd ff ff       	call   f01035a9 <cprintf>
f010385f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103862:	8b 45 08             	mov    0x8(%ebp),%eax
f0103865:	8b 40 30             	mov    0x30(%eax),%eax
f0103868:	83 ec 08             	sub    $0x8,%esp
f010386b:	50                   	push   %eax
f010386c:	68 74 66 10 f0       	push   $0xf0106674
f0103871:	e8 33 fd ff ff       	call   f01035a9 <cprintf>
f0103876:	83 c4 10             	add    $0x10,%esp
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103879:	8b 45 08             	mov    0x8(%ebp),%eax
f010387c:	8b 40 34             	mov    0x34(%eax),%eax
f010387f:	0f b7 c0             	movzwl %ax,%eax
f0103882:	83 ec 08             	sub    $0x8,%esp
f0103885:	50                   	push   %eax
f0103886:	68 83 66 10 f0       	push   $0xf0106683
f010388b:	e8 19 fd ff ff       	call   f01035a9 <cprintf>
f0103890:	83 c4 10             	add    $0x10,%esp
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103893:	8b 45 08             	mov    0x8(%ebp),%eax
f0103896:	8b 40 38             	mov    0x38(%eax),%eax
f0103899:	83 ec 08             	sub    $0x8,%esp
f010389c:	50                   	push   %eax
f010389d:	68 96 66 10 f0       	push   $0xf0106696
f01038a2:	e8 02 fd ff ff       	call   f01035a9 <cprintf>
f01038a7:	83 c4 10             	add    $0x10,%esp
	cprintf("  esp  0x%08x\n", tf->tf_esp);
f01038aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ad:	8b 40 3c             	mov    0x3c(%eax),%eax
f01038b0:	83 ec 08             	sub    $0x8,%esp
f01038b3:	50                   	push   %eax
f01038b4:	68 a5 66 10 f0       	push   $0xf01066a5
f01038b9:	e8 eb fc ff ff       	call   f01035a9 <cprintf>
f01038be:	83 c4 10             	add    $0x10,%esp
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01038c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01038c4:	8b 40 40             	mov    0x40(%eax),%eax
f01038c7:	0f b7 c0             	movzwl %ax,%eax
f01038ca:	83 ec 08             	sub    $0x8,%esp
f01038cd:	50                   	push   %eax
f01038ce:	68 b4 66 10 f0       	push   $0xf01066b4
f01038d3:	e8 d1 fc ff ff       	call   f01035a9 <cprintf>
f01038d8:	83 c4 10             	add    $0x10,%esp
}
f01038db:	90                   	nop
f01038dc:	c9                   	leave  
f01038dd:	c3                   	ret    

f01038de <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f01038de:	55                   	push   %ebp
f01038df:	89 e5                	mov    %esp,%ebp
f01038e1:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01038e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e7:	8b 00                	mov    (%eax),%eax
f01038e9:	83 ec 08             	sub    $0x8,%esp
f01038ec:	50                   	push   %eax
f01038ed:	68 c7 66 10 f0       	push   $0xf01066c7
f01038f2:	e8 b2 fc ff ff       	call   f01035a9 <cprintf>
f01038f7:	83 c4 10             	add    $0x10,%esp
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01038fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01038fd:	8b 40 04             	mov    0x4(%eax),%eax
f0103900:	83 ec 08             	sub    $0x8,%esp
f0103903:	50                   	push   %eax
f0103904:	68 d6 66 10 f0       	push   $0xf01066d6
f0103909:	e8 9b fc ff ff       	call   f01035a9 <cprintf>
f010390e:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103911:	8b 45 08             	mov    0x8(%ebp),%eax
f0103914:	8b 40 08             	mov    0x8(%eax),%eax
f0103917:	83 ec 08             	sub    $0x8,%esp
f010391a:	50                   	push   %eax
f010391b:	68 e5 66 10 f0       	push   $0xf01066e5
f0103920:	e8 84 fc ff ff       	call   f01035a9 <cprintf>
f0103925:	83 c4 10             	add    $0x10,%esp
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103928:	8b 45 08             	mov    0x8(%ebp),%eax
f010392b:	8b 40 0c             	mov    0xc(%eax),%eax
f010392e:	83 ec 08             	sub    $0x8,%esp
f0103931:	50                   	push   %eax
f0103932:	68 f4 66 10 f0       	push   $0xf01066f4
f0103937:	e8 6d fc ff ff       	call   f01035a9 <cprintf>
f010393c:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010393f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103942:	8b 40 10             	mov    0x10(%eax),%eax
f0103945:	83 ec 08             	sub    $0x8,%esp
f0103948:	50                   	push   %eax
f0103949:	68 03 67 10 f0       	push   $0xf0106703
f010394e:	e8 56 fc ff ff       	call   f01035a9 <cprintf>
f0103953:	83 c4 10             	add    $0x10,%esp
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103956:	8b 45 08             	mov    0x8(%ebp),%eax
f0103959:	8b 40 14             	mov    0x14(%eax),%eax
f010395c:	83 ec 08             	sub    $0x8,%esp
f010395f:	50                   	push   %eax
f0103960:	68 12 67 10 f0       	push   $0xf0106712
f0103965:	e8 3f fc ff ff       	call   f01035a9 <cprintf>
f010396a:	83 c4 10             	add    $0x10,%esp
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010396d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103970:	8b 40 18             	mov    0x18(%eax),%eax
f0103973:	83 ec 08             	sub    $0x8,%esp
f0103976:	50                   	push   %eax
f0103977:	68 21 67 10 f0       	push   $0xf0106721
f010397c:	e8 28 fc ff ff       	call   f01035a9 <cprintf>
f0103981:	83 c4 10             	add    $0x10,%esp
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103984:	8b 45 08             	mov    0x8(%ebp),%eax
f0103987:	8b 40 1c             	mov    0x1c(%eax),%eax
f010398a:	83 ec 08             	sub    $0x8,%esp
f010398d:	50                   	push   %eax
f010398e:	68 30 67 10 f0       	push   $0xf0106730
f0103993:	e8 11 fc ff ff       	call   f01035a9 <cprintf>
f0103998:	83 c4 10             	add    $0x10,%esp
}
f010399b:	90                   	nop
f010399c:	c9                   	leave  
f010399d:	c3                   	ret    

f010399e <trap_dispatch>:

static void
trap_dispatch(struct Trapframe *tf)
{
f010399e:	55                   	push   %ebp
f010399f:	89 e5                	mov    %esp,%ebp
f01039a1:	57                   	push   %edi
f01039a2:	56                   	push   %esi
f01039a3:	53                   	push   %ebx
f01039a4:	83 ec 1c             	sub    $0x1c,%esp
	// Handle processor exceptions.
	// LAB 3: Your code here.

	if(tf->tf_trapno == T_PGFLT)
f01039a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01039aa:	8b 40 28             	mov    0x28(%eax),%eax
f01039ad:	83 f8 0e             	cmp    $0xe,%eax
f01039b0:	75 13                	jne    f01039c5 <trap_dispatch+0x27>
	{
		page_fault_handler(tf);
f01039b2:	83 ec 0c             	sub    $0xc,%esp
f01039b5:	ff 75 08             	pushl  0x8(%ebp)
f01039b8:	e8 47 01 00 00       	call   f0103b04 <page_fault_handler>
f01039bd:	83 c4 10             	add    $0x10,%esp
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f01039c0:	e9 90 00 00 00       	jmp    f0103a55 <trap_dispatch+0xb7>

	if(tf->tf_trapno == T_PGFLT)
	{
		page_fault_handler(tf);
	}
	else if (tf->tf_trapno == T_SYSCALL)
f01039c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c8:	8b 40 28             	mov    0x28(%eax),%eax
f01039cb:	83 f8 30             	cmp    $0x30,%eax
f01039ce:	75 42                	jne    f0103a12 <trap_dispatch+0x74>
	{
		uint32 ret = syscall(tf->tf_regs.reg_eax
f01039d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039d3:	8b 78 04             	mov    0x4(%eax),%edi
f01039d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01039d9:	8b 30                	mov    (%eax),%esi
f01039db:	8b 45 08             	mov    0x8(%ebp),%eax
f01039de:	8b 58 10             	mov    0x10(%eax),%ebx
f01039e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01039e4:	8b 48 18             	mov    0x18(%eax),%ecx
f01039e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ea:	8b 50 14             	mov    0x14(%eax),%edx
f01039ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01039f0:	8b 40 1c             	mov    0x1c(%eax),%eax
f01039f3:	83 ec 08             	sub    $0x8,%esp
f01039f6:	57                   	push   %edi
f01039f7:	56                   	push   %esi
f01039f8:	53                   	push   %ebx
f01039f9:	51                   	push   %ecx
f01039fa:	52                   	push   %edx
f01039fb:	50                   	push   %eax
f01039fc:	e8 47 04 00 00       	call   f0103e48 <syscall>
f0103a01:	83 c4 20             	add    $0x20,%esp
f0103a04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			,tf->tf_regs.reg_edx
			,tf->tf_regs.reg_ecx
			,tf->tf_regs.reg_ebx
			,tf->tf_regs.reg_edi
					,tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f0103a07:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a0a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103a0d:	89 50 1c             	mov    %edx,0x1c(%eax)
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0103a10:	eb 43                	jmp    f0103a55 <trap_dispatch+0xb7>
		tf->tf_regs.reg_eax = ret;
	}
	else
	{
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103a12:	83 ec 0c             	sub    $0xc,%esp
f0103a15:	ff 75 08             	pushl  0x8(%ebp)
f0103a18:	e8 a6 fd ff ff       	call   f01037c3 <print_trapframe>
f0103a1d:	83 c4 10             	add    $0x10,%esp
		if (tf->tf_cs == GD_KT)
f0103a20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a23:	8b 40 34             	mov    0x34(%eax),%eax
f0103a26:	66 83 f8 08          	cmp    $0x8,%ax
f0103a2a:	75 17                	jne    f0103a43 <trap_dispatch+0xa5>
			panic("unhandled trap in kernel");
f0103a2c:	83 ec 04             	sub    $0x4,%esp
f0103a2f:	68 3f 67 10 f0       	push   $0xf010673f
f0103a34:	68 8a 00 00 00       	push   $0x8a
f0103a39:	68 58 67 10 f0       	push   $0xf0106758
f0103a3e:	e8 eb c6 ff ff       	call   f010012e <_panic>
		else {
			env_destroy(curenv);
f0103a43:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103a48:	83 ec 0c             	sub    $0xc,%esp
f0103a4b:	50                   	push   %eax
f0103a4c:	e8 a2 f9 ff ff       	call   f01033f3 <env_destroy>
f0103a51:	83 c4 10             	add    $0x10,%esp
			return;
f0103a54:	90                   	nop
		}
	}
	return;
}
f0103a55:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a58:	5b                   	pop    %ebx
f0103a59:	5e                   	pop    %esi
f0103a5a:	5f                   	pop    %edi
f0103a5b:	5d                   	pop    %ebp
f0103a5c:	c3                   	ret    

f0103a5d <trap>:

void
trap(struct Trapframe *tf)
{
f0103a5d:	55                   	push   %ebp
f0103a5e:	89 e5                	mov    %esp,%ebp
f0103a60:	57                   	push   %edi
f0103a61:	56                   	push   %esi
f0103a62:	53                   	push   %ebx
f0103a63:	83 ec 0c             	sub    $0xc,%esp
	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f0103a66:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a69:	8b 40 34             	mov    0x34(%eax),%eax
f0103a6c:	0f b7 c0             	movzwl %ax,%eax
f0103a6f:	83 e0 03             	and    $0x3,%eax
f0103a72:	83 f8 03             	cmp    $0x3,%eax
f0103a75:	75 42                	jne    f0103ab9 <trap+0x5c>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103a77:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103a7c:	85 c0                	test   %eax,%eax
f0103a7e:	75 19                	jne    f0103a99 <trap+0x3c>
f0103a80:	68 64 67 10 f0       	push   $0xf0106764
f0103a85:	68 6b 67 10 f0       	push   $0xf010676b
f0103a8a:	68 9d 00 00 00       	push   $0x9d
f0103a8f:	68 58 67 10 f0       	push   $0xf0106758
f0103a94:	e8 95 c6 ff ff       	call   f010012e <_panic>
		curenv->env_tf = *tf;
f0103a99:	8b 15 50 ef 14 f0    	mov    0xf014ef50,%edx
f0103a9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aa2:	89 c3                	mov    %eax,%ebx
f0103aa4:	b8 11 00 00 00       	mov    $0x11,%eax
f0103aa9:	89 d7                	mov    %edx,%edi
f0103aab:	89 de                	mov    %ebx,%esi
f0103aad:	89 c1                	mov    %eax,%ecx
f0103aaf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103ab1:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103ab6:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103ab9:	83 ec 0c             	sub    $0xc,%esp
f0103abc:	ff 75 08             	pushl  0x8(%ebp)
f0103abf:	e8 da fe ff ff       	call   f010399e <trap_dispatch>
f0103ac4:	83 c4 10             	add    $0x10,%esp

        // Return to the current environment, which should be runnable.
        assert(curenv && curenv->env_status == ENV_RUNNABLE);
f0103ac7:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103acc:	85 c0                	test   %eax,%eax
f0103ace:	74 0d                	je     f0103add <trap+0x80>
f0103ad0:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103ad5:	8b 40 54             	mov    0x54(%eax),%eax
f0103ad8:	83 f8 01             	cmp    $0x1,%eax
f0103adb:	74 19                	je     f0103af6 <trap+0x99>
f0103add:	68 80 67 10 f0       	push   $0xf0106780
f0103ae2:	68 6b 67 10 f0       	push   $0xf010676b
f0103ae7:	68 a7 00 00 00       	push   $0xa7
f0103aec:	68 58 67 10 f0       	push   $0xf0106758
f0103af1:	e8 38 c6 ff ff       	call   f010012e <_panic>
        env_run(curenv);
f0103af6:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103afb:	83 ec 0c             	sub    $0xc,%esp
f0103afe:	50                   	push   %eax
f0103aff:	e8 fd f2 ff ff       	call   f0102e01 <env_run>

f0103b04 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103b04:	55                   	push   %ebp
f0103b05:	89 e5                	mov    %esp,%ebp
f0103b07:	83 ec 18             	sub    $0x18,%esp

static __inline uint32
rcr2(void)
{
	uint32 val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b0a:	0f 20 d0             	mov    %cr2,%eax
f0103b0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
f0103b10:	8b 45 f0             	mov    -0x10(%ebp),%eax
	uint32 fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103b13:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b16:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b19:	8b 50 30             	mov    0x30(%eax),%edx
	curenv->env_id, fault_va, tf->tf_eip);
f0103b1c:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b21:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103b24:	52                   	push   %edx
f0103b25:	ff 75 f4             	pushl  -0xc(%ebp)
f0103b28:	50                   	push   %eax
f0103b29:	68 b0 67 10 f0       	push   $0xf01067b0
f0103b2e:	e8 76 fa ff ff       	call   f01035a9 <cprintf>
f0103b33:	83 c4 10             	add    $0x10,%esp
	curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b36:	83 ec 0c             	sub    $0xc,%esp
f0103b39:	ff 75 08             	pushl  0x8(%ebp)
f0103b3c:	e8 82 fc ff ff       	call   f01037c3 <print_trapframe>
f0103b41:	83 c4 10             	add    $0x10,%esp
	env_destroy(curenv);
f0103b44:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103b49:	83 ec 0c             	sub    $0xc,%esp
f0103b4c:	50                   	push   %eax
f0103b4d:	e8 a1 f8 ff ff       	call   f01033f3 <env_destroy>
f0103b52:	83 c4 10             	add    $0x10,%esp

}
f0103b55:	90                   	nop
f0103b56:	c9                   	leave  
f0103b57:	c3                   	ret    

f0103b58 <PAGE_FAULT>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(PAGE_FAULT, T_PGFLT)		
f0103b58:	6a 0e                	push   $0xe
f0103b5a:	eb 06                	jmp    f0103b62 <_alltraps>

f0103b5c <SYSCALL_HANDLER>:

TRAPHANDLER_NOEC(SYSCALL_HANDLER, T_SYSCALL)
f0103b5c:	6a 00                	push   $0x0
f0103b5e:	6a 30                	push   $0x30
f0103b60:	eb 00                	jmp    f0103b62 <_alltraps>

f0103b62 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:

push %ds 
f0103b62:	1e                   	push   %ds
push %es 
f0103b63:	06                   	push   %es
pushal 	
f0103b64:	60                   	pusha  

mov $(GD_KD), %ax 
f0103b65:	66 b8 10 00          	mov    $0x10,%ax
mov %ax,%ds
f0103b69:	8e d8                	mov    %eax,%ds
mov %ax,%es
f0103b6b:	8e c0                	mov    %eax,%es

push %esp
f0103b6d:	54                   	push   %esp

call trap
f0103b6e:	e8 ea fe ff ff       	call   f0103a5d <trap>

pop %ecx /* poping the pointer to the tf from the stack so that the stack top is at the values of the registers posuhed by pusha*/
f0103b73:	59                   	pop    %ecx
popal 	
f0103b74:	61                   	popa   
pop %es 
f0103b75:	07                   	pop    %es
pop %ds    
f0103b76:	1f                   	pop    %ds

/*skipping the trap_no and the error code so that the stack top is at the old eip value*/
add $(8),%esp
f0103b77:	83 c4 08             	add    $0x8,%esp

iret
f0103b7a:	cf                   	iret   

f0103b7b <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0103b7b:	55                   	push   %ebp
f0103b7c:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0103b7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b81:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f0103b87:	29 d0                	sub    %edx,%eax
f0103b89:	c1 f8 02             	sar    $0x2,%eax
f0103b8c:	89 c2                	mov    %eax,%edx
f0103b8e:	89 d0                	mov    %edx,%eax
f0103b90:	c1 e0 02             	shl    $0x2,%eax
f0103b93:	01 d0                	add    %edx,%eax
f0103b95:	c1 e0 02             	shl    $0x2,%eax
f0103b98:	01 d0                	add    %edx,%eax
f0103b9a:	c1 e0 02             	shl    $0x2,%eax
f0103b9d:	01 d0                	add    %edx,%eax
f0103b9f:	89 c1                	mov    %eax,%ecx
f0103ba1:	c1 e1 08             	shl    $0x8,%ecx
f0103ba4:	01 c8                	add    %ecx,%eax
f0103ba6:	89 c1                	mov    %eax,%ecx
f0103ba8:	c1 e1 10             	shl    $0x10,%ecx
f0103bab:	01 c8                	add    %ecx,%eax
f0103bad:	01 c0                	add    %eax,%eax
f0103baf:	01 d0                	add    %edx,%eax
}
f0103bb1:	5d                   	pop    %ebp
f0103bb2:	c3                   	ret    

f0103bb3 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0103bb3:	55                   	push   %ebp
f0103bb4:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0103bb6:	ff 75 08             	pushl  0x8(%ebp)
f0103bb9:	e8 bd ff ff ff       	call   f0103b7b <to_frame_number>
f0103bbe:	83 c4 04             	add    $0x4,%esp
f0103bc1:	c1 e0 0c             	shl    $0xc,%eax
}
f0103bc4:	c9                   	leave  
f0103bc5:	c3                   	ret    

f0103bc6 <sys_cputs>:

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void sys_cputs(const char *s, uint32 len)
{
f0103bc6:	55                   	push   %ebp
f0103bc7:	89 e5                	mov    %esp,%ebp
f0103bc9:	83 ec 08             	sub    $0x8,%esp
	// Destroy the environment if not.
	
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103bcc:	83 ec 04             	sub    $0x4,%esp
f0103bcf:	ff 75 08             	pushl  0x8(%ebp)
f0103bd2:	ff 75 0c             	pushl  0xc(%ebp)
f0103bd5:	68 70 69 10 f0       	push   $0xf0106970
f0103bda:	e8 ca f9 ff ff       	call   f01035a9 <cprintf>
f0103bdf:	83 c4 10             	add    $0x10,%esp
}
f0103be2:	90                   	nop
f0103be3:	c9                   	leave  
f0103be4:	c3                   	ret    

f0103be5 <sys_cgetc>:

// Read a character from the system console.
// Returns the character.
static int
sys_cgetc(void)
{
f0103be5:	55                   	push   %ebp
f0103be6:	89 e5                	mov    %esp,%ebp
f0103be8:	83 ec 18             	sub    $0x18,%esp
	int c;

	// The cons_getc() primitive doesn't wait for a character,
	// but the sys_cgetc() system call does.
	while ((c = cons_getc()) == 0)
f0103beb:	e8 79 cc ff ff       	call   f0100869 <cons_getc>
f0103bf0:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103bf3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103bf7:	74 f2                	je     f0103beb <sys_cgetc+0x6>
		/* do nothing */;

	return c;
f0103bf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0103bfc:	c9                   	leave  
f0103bfd:	c3                   	ret    

f0103bfe <sys_getenvid>:

// Returns the current environment's envid.
static int32 sys_getenvid(void)
{
f0103bfe:	55                   	push   %ebp
f0103bff:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f0103c01:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c06:	8b 40 4c             	mov    0x4c(%eax),%eax
}
f0103c09:	5d                   	pop    %ebp
f0103c0a:	c3                   	ret    

f0103c0b <sys_env_destroy>:
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int sys_env_destroy(int32  envid)
{
f0103c0b:	55                   	push   %ebp
f0103c0c:	89 e5                	mov    %esp,%ebp
f0103c0e:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103c11:	83 ec 04             	sub    $0x4,%esp
f0103c14:	6a 01                	push   $0x1
f0103c16:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0103c19:	50                   	push   %eax
f0103c1a:	ff 75 08             	pushl  0x8(%ebp)
f0103c1d:	e8 44 e5 ff ff       	call   f0102166 <envid2env>
f0103c22:	83 c4 10             	add    $0x10,%esp
f0103c25:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103c28:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103c2c:	79 05                	jns    f0103c33 <sys_env_destroy+0x28>
		return r;
f0103c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c31:	eb 5b                	jmp    f0103c8e <sys_env_destroy+0x83>
	if (e == curenv)
f0103c33:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103c36:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c3b:	39 c2                	cmp    %eax,%edx
f0103c3d:	75 1b                	jne    f0103c5a <sys_env_destroy+0x4f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103c3f:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c44:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103c47:	83 ec 08             	sub    $0x8,%esp
f0103c4a:	50                   	push   %eax
f0103c4b:	68 75 69 10 f0       	push   $0xf0106975
f0103c50:	e8 54 f9 ff ff       	call   f01035a9 <cprintf>
f0103c55:	83 c4 10             	add    $0x10,%esp
f0103c58:	eb 20                	jmp    f0103c7a <sys_env_destroy+0x6f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103c5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103c5d:	8b 50 4c             	mov    0x4c(%eax),%edx
f0103c60:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c65:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103c68:	83 ec 04             	sub    $0x4,%esp
f0103c6b:	52                   	push   %edx
f0103c6c:	50                   	push   %eax
f0103c6d:	68 90 69 10 f0       	push   $0xf0106990
f0103c72:	e8 32 f9 ff ff       	call   f01035a9 <cprintf>
f0103c77:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103c7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103c7d:	83 ec 0c             	sub    $0xc,%esp
f0103c80:	50                   	push   %eax
f0103c81:	e8 6d f7 ff ff       	call   f01033f3 <env_destroy>
f0103c86:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103c89:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c8e:	c9                   	leave  
f0103c8f:	c3                   	ret    

f0103c90 <sys_env_sleep>:

static void sys_env_sleep()
{
f0103c90:	55                   	push   %ebp
f0103c91:	89 e5                	mov    %esp,%ebp
f0103c93:	83 ec 08             	sub    $0x8,%esp
	env_run_cmd_prmpt();
f0103c96:	e8 73 f7 ff ff       	call   f010340e <env_run_cmd_prmpt>
}
f0103c9b:	90                   	nop
f0103c9c:	c9                   	leave  
f0103c9d:	c3                   	ret    

f0103c9e <sys_allocate_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_allocate_page(void *va, int perm)
{
f0103c9e:	55                   	push   %ebp
f0103c9f:	89 e5                	mov    %esp,%ebp
f0103ca1:	83 ec 28             	sub    $0x28,%esp
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
	
	int r;
	struct Env *e = curenv;
f0103ca4:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103ca9:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//if ((r = envid2env(envid, &e, 1)) < 0)
		//return r;
	
	struct Frame_Info *ptr_frame_info ;
	r = allocate_frame(&ptr_frame_info) ;
f0103cac:	83 ec 0c             	sub    $0xc,%esp
f0103caf:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103cb2:	50                   	push   %eax
f0103cb3:	e8 3c ec ff ff       	call   f01028f4 <allocate_frame>
f0103cb8:	83 c4 10             	add    $0x10,%esp
f0103cbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103cbe:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0103cc2:	75 08                	jne    f0103ccc <sys_allocate_page+0x2e>
		return r ;
f0103cc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103cc7:	e9 cc 00 00 00       	jmp    f0103d98 <sys_allocate_page+0xfa>
	
	//check virtual address to be paged_aligned and < USER_TOP
	if ((uint32)va >= USER_TOP || (uint32)va % PAGE_SIZE != 0)
f0103ccc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ccf:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f0103cd4:	77 0c                	ja     f0103ce2 <sys_allocate_page+0x44>
f0103cd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cd9:	25 ff 0f 00 00       	and    $0xfff,%eax
f0103cde:	85 c0                	test   %eax,%eax
f0103ce0:	74 0a                	je     f0103cec <sys_allocate_page+0x4e>
		return E_INVAL;
f0103ce2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103ce7:	e9 ac 00 00 00       	jmp    f0103d98 <sys_allocate_page+0xfa>
	
	//check permissions to be appropriatess
	if ((perm & (~PERM_AVAILABLE & ~PERM_WRITEABLE)) != (PERM_USER))
f0103cec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cef:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0103cf4:	83 f8 04             	cmp    $0x4,%eax
f0103cf7:	74 0a                	je     f0103d03 <sys_allocate_page+0x65>
		return E_INVAL;
f0103cf9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103cfe:	e9 95 00 00 00       	jmp    f0103d98 <sys_allocate_page+0xfa>
	
			
	uint32 physical_address = to_physical_address(ptr_frame_info) ;
f0103d03:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d06:	83 ec 0c             	sub    $0xc,%esp
f0103d09:	50                   	push   %eax
f0103d0a:	e8 a4 fe ff ff       	call   f0103bb3 <to_physical_address>
f0103d0f:	83 c4 10             	add    $0x10,%esp
f0103d12:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	memset(K_VIRTUAL_ADDRESS(physical_address), 0, PAGE_SIZE);
f0103d15:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103d18:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0103d1b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103d1e:	c1 e8 0c             	shr    $0xc,%eax
f0103d21:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103d24:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0103d29:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0103d2c:	72 14                	jb     f0103d42 <sys_allocate_page+0xa4>
f0103d2e:	ff 75 e8             	pushl  -0x18(%ebp)
f0103d31:	68 a8 69 10 f0       	push   $0xf01069a8
f0103d36:	6a 7a                	push   $0x7a
f0103d38:	68 d7 69 10 f0       	push   $0xf01069d7
f0103d3d:	e8 ec c3 ff ff       	call   f010012e <_panic>
f0103d42:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103d45:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103d4a:	83 ec 04             	sub    $0x4,%esp
f0103d4d:	68 00 10 00 00       	push   $0x1000
f0103d52:	6a 00                	push   $0x0
f0103d54:	50                   	push   %eax
f0103d55:	e8 31 0f 00 00       	call   f0104c8b <memset>
f0103d5a:	83 c4 10             	add    $0x10,%esp
		
	r = map_frame(e->env_pgdir, ptr_frame_info, va, perm) ;
f0103d5d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103d60:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d63:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103d66:	ff 75 0c             	pushl  0xc(%ebp)
f0103d69:	ff 75 08             	pushl  0x8(%ebp)
f0103d6c:	52                   	push   %edx
f0103d6d:	50                   	push   %eax
f0103d6e:	e8 8e ed ff ff       	call   f0102b01 <map_frame>
f0103d73:	83 c4 10             	add    $0x10,%esp
f0103d76:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103d79:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0103d7d:	75 14                	jne    f0103d93 <sys_allocate_page+0xf5>
	{
		decrement_references(ptr_frame_info);
f0103d7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d82:	83 ec 0c             	sub    $0xc,%esp
f0103d85:	50                   	push   %eax
f0103d86:	e8 07 ec ff ff       	call   f0102992 <decrement_references>
f0103d8b:	83 c4 10             	add    $0x10,%esp
		return r;
f0103d8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103d91:	eb 05                	jmp    f0103d98 <sys_allocate_page+0xfa>
	}
	return 0 ;
f0103d93:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d98:	c9                   	leave  
f0103d99:	c3                   	ret    

f0103d9a <sys_get_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_get_page(void *va, int perm)
{
f0103d9a:	55                   	push   %ebp
f0103d9b:	89 e5                	mov    %esp,%ebp
f0103d9d:	83 ec 08             	sub    $0x8,%esp
	return get_page(curenv->env_pgdir, va, perm) ;
f0103da0:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103da5:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103da8:	83 ec 04             	sub    $0x4,%esp
f0103dab:	ff 75 0c             	pushl  0xc(%ebp)
f0103dae:	ff 75 08             	pushl  0x8(%ebp)
f0103db1:	50                   	push   %eax
f0103db2:	e8 c8 ee ff ff       	call   f0102c7f <get_page>
f0103db7:	83 c4 10             	add    $0x10,%esp
}
f0103dba:	c9                   	leave  
f0103dbb:	c3                   	ret    

f0103dbc <sys_map_frame>:
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_map_frame(int32 srcenvid, void *srcva, int32 dstenvid, void *dstva, int perm)
{
f0103dbc:	55                   	push   %ebp
f0103dbd:	89 e5                	mov    %esp,%ebp
f0103dbf:	83 ec 08             	sub    $0x8,%esp
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	panic("sys_map_frame not implemented");
f0103dc2:	83 ec 04             	sub    $0x4,%esp
f0103dc5:	68 e6 69 10 f0       	push   $0xf01069e6
f0103dca:	68 b1 00 00 00       	push   $0xb1
f0103dcf:	68 d7 69 10 f0       	push   $0xf01069d7
f0103dd4:	e8 55 c3 ff ff       	call   f010012e <_panic>

f0103dd9 <sys_unmap_frame>:
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int sys_unmap_frame(int32 envid, void *va)
{
f0103dd9:	55                   	push   %ebp
f0103dda:	89 e5                	mov    %esp,%ebp
f0103ddc:	83 ec 08             	sub    $0x8,%esp
	// Hint: This function is a wrapper around page_remove().
	
	// LAB 4: Your code here.
	panic("sys_page_unmap not implemented");
f0103ddf:	83 ec 04             	sub    $0x4,%esp
f0103de2:	68 04 6a 10 f0       	push   $0xf0106a04
f0103de7:	68 c0 00 00 00       	push   $0xc0
f0103dec:	68 d7 69 10 f0       	push   $0xf01069d7
f0103df1:	e8 38 c3 ff ff       	call   f010012e <_panic>

f0103df6 <sys_calculate_required_frames>:
}

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
f0103df6:	55                   	push   %ebp
f0103df7:	89 e5                	mov    %esp,%ebp
f0103df9:	83 ec 08             	sub    $0x8,%esp
	return calculate_required_frames(curenv->env_pgdir, start_virtual_address, size); 
f0103dfc:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103e01:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103e04:	83 ec 04             	sub    $0x4,%esp
f0103e07:	ff 75 0c             	pushl  0xc(%ebp)
f0103e0a:	ff 75 08             	pushl  0x8(%ebp)
f0103e0d:	50                   	push   %eax
f0103e0e:	e8 89 ee ff ff       	call   f0102c9c <calculate_required_frames>
f0103e13:	83 c4 10             	add    $0x10,%esp
}
f0103e16:	c9                   	leave  
f0103e17:	c3                   	ret    

f0103e18 <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
f0103e18:	55                   	push   %ebp
f0103e19:	89 e5                	mov    %esp,%ebp
f0103e1b:	83 ec 08             	sub    $0x8,%esp
	return calculate_free_frames();
f0103e1e:	e8 96 ee ff ff       	call   f0102cb9 <calculate_free_frames>
}
f0103e23:	c9                   	leave  
f0103e24:	c3                   	ret    

f0103e25 <sys_freeMem>:
void sys_freeMem(void* start_virtual_address, uint32 size)
{
f0103e25:	55                   	push   %ebp
f0103e26:	89 e5                	mov    %esp,%ebp
f0103e28:	83 ec 08             	sub    $0x8,%esp
	freeMem((uint32*)curenv->env_pgdir, (void*)start_virtual_address, size);
f0103e2b:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103e30:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103e33:	83 ec 04             	sub    $0x4,%esp
f0103e36:	ff 75 0c             	pushl  0xc(%ebp)
f0103e39:	ff 75 08             	pushl  0x8(%ebp)
f0103e3c:	50                   	push   %eax
f0103e3d:	e8 a4 ee ff ff       	call   f0102ce6 <freeMem>
f0103e42:	83 c4 10             	add    $0x10,%esp
	return;
f0103e45:	90                   	nop
}
f0103e46:	c9                   	leave  
f0103e47:	c3                   	ret    

f0103e48 <syscall>:
// Dispatches to the correct kernel function, passing the arguments.
uint32
syscall(uint32 syscallno, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
f0103e48:	55                   	push   %ebp
f0103e49:	89 e5                	mov    %esp,%ebp
f0103e4b:	56                   	push   %esi
f0103e4c:	53                   	push   %ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch(syscallno)
f0103e4d:	83 7d 08 0c          	cmpl   $0xc,0x8(%ebp)
f0103e51:	0f 87 19 01 00 00    	ja     f0103f70 <syscall+0x128>
f0103e57:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e5a:	c1 e0 02             	shl    $0x2,%eax
f0103e5d:	05 24 6a 10 f0       	add    $0xf0106a24,%eax
f0103e62:	8b 00                	mov    (%eax),%eax
f0103e64:	ff e0                	jmp    *%eax
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,a2);
f0103e66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e69:	83 ec 08             	sub    $0x8,%esp
f0103e6c:	ff 75 10             	pushl  0x10(%ebp)
f0103e6f:	50                   	push   %eax
f0103e70:	e8 51 fd ff ff       	call   f0103bc6 <sys_cputs>
f0103e75:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103e78:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e7d:	e9 f3 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f0103e82:	e8 5e fd ff ff       	call   f0103be5 <sys_cgetc>
f0103e87:	e9 e9 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0103e8c:	e8 6d fd ff ff       	call   f0103bfe <sys_getenvid>
f0103e91:	e9 df 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_env_destroy:
			return sys_env_destroy(a1);
f0103e96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e99:	83 ec 0c             	sub    $0xc,%esp
f0103e9c:	50                   	push   %eax
f0103e9d:	e8 69 fd ff ff       	call   f0103c0b <sys_env_destroy>
f0103ea2:	83 c4 10             	add    $0x10,%esp
f0103ea5:	e9 cb 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_env_sleep:
			sys_env_sleep();
f0103eaa:	e8 e1 fd ff ff       	call   f0103c90 <sys_env_sleep>
			return 0;
f0103eaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0103eb4:	e9 bc 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_calc_req_frames:
			return sys_calculate_required_frames(a1, a2);			
f0103eb9:	83 ec 08             	sub    $0x8,%esp
f0103ebc:	ff 75 10             	pushl  0x10(%ebp)
f0103ebf:	ff 75 0c             	pushl  0xc(%ebp)
f0103ec2:	e8 2f ff ff ff       	call   f0103df6 <sys_calculate_required_frames>
f0103ec7:	83 c4 10             	add    $0x10,%esp
f0103eca:	e9 a6 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_calc_free_frames:
			return sys_calculate_free_frames();			
f0103ecf:	e8 44 ff ff ff       	call   f0103e18 <sys_calculate_free_frames>
f0103ed4:	e9 9c 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_freeMem:
			sys_freeMem((void*)a1, a2);
f0103ed9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103edc:	83 ec 08             	sub    $0x8,%esp
f0103edf:	ff 75 10             	pushl  0x10(%ebp)
f0103ee2:	50                   	push   %eax
f0103ee3:	e8 3d ff ff ff       	call   f0103e25 <sys_freeMem>
f0103ee8:	83 c4 10             	add    $0x10,%esp
			return 0;			
f0103eeb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ef0:	e9 80 00 00 00       	jmp    f0103f75 <syscall+0x12d>
			break;
		//======================
		
		case SYS_allocate_page:
			sys_allocate_page((void*)a1, a2);
f0103ef5:	8b 55 10             	mov    0x10(%ebp),%edx
f0103ef8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103efb:	83 ec 08             	sub    $0x8,%esp
f0103efe:	52                   	push   %edx
f0103eff:	50                   	push   %eax
f0103f00:	e8 99 fd ff ff       	call   f0103c9e <sys_allocate_page>
f0103f05:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103f08:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f0d:	eb 66                	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_get_page:
			sys_get_page((void*)a1, a2);
f0103f0f:	8b 55 10             	mov    0x10(%ebp),%edx
f0103f12:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f15:	83 ec 08             	sub    $0x8,%esp
f0103f18:	52                   	push   %edx
f0103f19:	50                   	push   %eax
f0103f1a:	e8 7b fe ff ff       	call   f0103d9a <sys_get_page>
f0103f1f:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103f22:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f27:	eb 4c                	jmp    f0103f75 <syscall+0x12d>
		break;case SYS_map_frame:
			sys_map_frame(a1, (void*)a2, a3, (void*)a4, a5);
f0103f29:	8b 75 1c             	mov    0x1c(%ebp),%esi
f0103f2c:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0103f2f:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0103f32:	8b 55 10             	mov    0x10(%ebp),%edx
f0103f35:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f38:	83 ec 0c             	sub    $0xc,%esp
f0103f3b:	56                   	push   %esi
f0103f3c:	53                   	push   %ebx
f0103f3d:	51                   	push   %ecx
f0103f3e:	52                   	push   %edx
f0103f3f:	50                   	push   %eax
f0103f40:	e8 77 fe ff ff       	call   f0103dbc <sys_map_frame>
f0103f45:	83 c4 20             	add    $0x20,%esp
			return 0;
f0103f48:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f4d:	eb 26                	jmp    f0103f75 <syscall+0x12d>
			break;
		case SYS_unmap_frame:
			sys_unmap_frame(a1, (void*)a2);
f0103f4f:	8b 55 10             	mov    0x10(%ebp),%edx
f0103f52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f55:	83 ec 08             	sub    $0x8,%esp
f0103f58:	52                   	push   %edx
f0103f59:	50                   	push   %eax
f0103f5a:	e8 7a fe ff ff       	call   f0103dd9 <sys_unmap_frame>
f0103f5f:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103f62:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f67:	eb 0c                	jmp    f0103f75 <syscall+0x12d>
			break;
		case NSYSCALLS:	
			return 	-E_INVAL;
f0103f69:	b8 03 00 00 00       	mov    $0x3,%eax
f0103f6e:	eb 05                	jmp    f0103f75 <syscall+0x12d>
			break;
	}
	//panic("syscall not implemented");
	return -E_INVAL;
f0103f70:	b8 03 00 00 00       	mov    $0x3,%eax
}
f0103f75:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103f78:	5b                   	pop    %ebx
f0103f79:	5e                   	pop    %esi
f0103f7a:	5d                   	pop    %ebp
f0103f7b:	c3                   	ret    

f0103f7c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
f0103f7c:	55                   	push   %ebp
f0103f7d:	89 e5                	mov    %esp,%ebp
f0103f7f:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0103f82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f85:	8b 00                	mov    (%eax),%eax
f0103f87:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0103f8a:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f8d:	8b 00                	mov    (%eax),%eax
f0103f8f:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103f92:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f0103f99:	e9 ca 00 00 00       	jmp    f0104068 <stab_binsearch+0xec>
		int true_m = (l + r) / 2, m = true_m;
f0103f9e:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103fa1:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0103fa4:	01 d0                	add    %edx,%eax
f0103fa6:	89 c2                	mov    %eax,%edx
f0103fa8:	c1 ea 1f             	shr    $0x1f,%edx
f0103fab:	01 d0                	add    %edx,%eax
f0103fad:	d1 f8                	sar    %eax
f0103faf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103fb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103fb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103fb8:	eb 03                	jmp    f0103fbd <stab_binsearch+0x41>
			m--;
f0103fba:	ff 4d f0             	decl   -0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103fbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103fc0:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103fc3:	7c 1e                	jl     f0103fe3 <stab_binsearch+0x67>
f0103fc5:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103fc8:	89 d0                	mov    %edx,%eax
f0103fca:	01 c0                	add    %eax,%eax
f0103fcc:	01 d0                	add    %edx,%eax
f0103fce:	c1 e0 02             	shl    $0x2,%eax
f0103fd1:	89 c2                	mov    %eax,%edx
f0103fd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fd6:	01 d0                	add    %edx,%eax
f0103fd8:	8a 40 04             	mov    0x4(%eax),%al
f0103fdb:	0f b6 c0             	movzbl %al,%eax
f0103fde:	3b 45 14             	cmp    0x14(%ebp),%eax
f0103fe1:	75 d7                	jne    f0103fba <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0103fe3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103fe6:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0103fe9:	7d 09                	jge    f0103ff4 <stab_binsearch+0x78>
			l = true_m + 1;
f0103feb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103fee:	40                   	inc    %eax
f0103fef:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0103ff2:	eb 74                	jmp    f0104068 <stab_binsearch+0xec>
		}

		// actual binary search
		any_matches = 1;
f0103ff4:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0103ffb:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103ffe:	89 d0                	mov    %edx,%eax
f0104000:	01 c0                	add    %eax,%eax
f0104002:	01 d0                	add    %edx,%eax
f0104004:	c1 e0 02             	shl    $0x2,%eax
f0104007:	89 c2                	mov    %eax,%edx
f0104009:	8b 45 08             	mov    0x8(%ebp),%eax
f010400c:	01 d0                	add    %edx,%eax
f010400e:	8b 40 08             	mov    0x8(%eax),%eax
f0104011:	3b 45 18             	cmp    0x18(%ebp),%eax
f0104014:	73 11                	jae    f0104027 <stab_binsearch+0xab>
			*region_left = m;
f0104016:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104019:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010401c:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f010401e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104021:	40                   	inc    %eax
f0104022:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0104025:	eb 41                	jmp    f0104068 <stab_binsearch+0xec>
		} else if (stabs[m].n_value > addr) {
f0104027:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010402a:	89 d0                	mov    %edx,%eax
f010402c:	01 c0                	add    %eax,%eax
f010402e:	01 d0                	add    %edx,%eax
f0104030:	c1 e0 02             	shl    $0x2,%eax
f0104033:	89 c2                	mov    %eax,%edx
f0104035:	8b 45 08             	mov    0x8(%ebp),%eax
f0104038:	01 d0                	add    %edx,%eax
f010403a:	8b 40 08             	mov    0x8(%eax),%eax
f010403d:	3b 45 18             	cmp    0x18(%ebp),%eax
f0104040:	76 14                	jbe    f0104056 <stab_binsearch+0xda>
			*region_right = m - 1;
f0104042:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104045:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104048:	8b 45 10             	mov    0x10(%ebp),%eax
f010404b:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f010404d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104050:	48                   	dec    %eax
f0104051:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0104054:	eb 12                	jmp    f0104068 <stab_binsearch+0xec>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104056:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104059:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010405c:	89 10                	mov    %edx,(%eax)
			l = m;
f010405e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104061:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0104064:	83 45 18 04          	addl   $0x4,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0104068:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010406b:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f010406e:	0f 8e 2a ff ff ff    	jle    f0103f9e <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104074:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104078:	75 0f                	jne    f0104089 <stab_binsearch+0x10d>
		*region_right = *region_left - 1;
f010407a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010407d:	8b 00                	mov    (%eax),%eax
f010407f:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104082:	8b 45 10             	mov    0x10(%ebp),%eax
f0104085:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0104087:	eb 3d                	jmp    f01040c6 <stab_binsearch+0x14a>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104089:	8b 45 10             	mov    0x10(%ebp),%eax
f010408c:	8b 00                	mov    (%eax),%eax
f010408e:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0104091:	eb 03                	jmp    f0104096 <stab_binsearch+0x11a>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104093:	ff 4d fc             	decl   -0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0104096:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104099:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010409b:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010409e:	7d 1e                	jge    f01040be <stab_binsearch+0x142>
		     l > *region_left && stabs[l].n_type != type;
f01040a0:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01040a3:	89 d0                	mov    %edx,%eax
f01040a5:	01 c0                	add    %eax,%eax
f01040a7:	01 d0                	add    %edx,%eax
f01040a9:	c1 e0 02             	shl    $0x2,%eax
f01040ac:	89 c2                	mov    %eax,%edx
f01040ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01040b1:	01 d0                	add    %edx,%eax
f01040b3:	8a 40 04             	mov    0x4(%eax),%al
f01040b6:	0f b6 c0             	movzbl %al,%eax
f01040b9:	3b 45 14             	cmp    0x14(%ebp),%eax
f01040bc:	75 d5                	jne    f0104093 <stab_binsearch+0x117>
		     l--)
			/* do nothing */;
		*region_left = l;
f01040be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040c1:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01040c4:	89 10                	mov    %edx,(%eax)
	}
}
f01040c6:	90                   	nop
f01040c7:	c9                   	leave  
f01040c8:	c3                   	ret    

f01040c9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uint32*  addr, struct Eipdebuginfo *info)
{
f01040c9:	55                   	push   %ebp
f01040ca:	89 e5                	mov    %esp,%ebp
f01040cc:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01040cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040d2:	c7 00 58 6a 10 f0    	movl   $0xf0106a58,(%eax)
	info->eip_line = 0;
f01040d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040db:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f01040e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040e5:	c7 40 08 58 6a 10 f0 	movl   $0xf0106a58,0x8(%eax)
	info->eip_fn_namelen = 9;
f01040ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040ef:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f01040f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040f9:	8b 55 08             	mov    0x8(%ebp),%edx
f01040fc:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f01040ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104102:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if ((uint32)addr >= USER_LIMIT) {
f0104109:	8b 45 08             	mov    0x8(%ebp),%eax
f010410c:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104111:	76 1e                	jbe    f0104131 <debuginfo_eip+0x68>
		stabs = __STAB_BEGIN__;
f0104113:	c7 45 f4 b0 6c 10 f0 	movl   $0xf0106cb0,-0xc(%ebp)
		stab_end = __STAB_END__;
f010411a:	c7 45 f0 b0 fc 10 f0 	movl   $0xf010fcb0,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104121:	c7 45 ec b1 fc 10 f0 	movl   $0xf010fcb1,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f0104128:	c7 45 e8 3e 37 11 f0 	movl   $0xf011373e,-0x18(%ebp)
f010412f:	eb 2a                	jmp    f010415b <debuginfo_eip+0x92>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f0104131:	c7 45 e0 00 00 20 00 	movl   $0x200000,-0x20(%ebp)

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		
		stabs = usd->stabs;
f0104138:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010413b:	8b 00                	mov    (%eax),%eax
f010413d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		stab_end = usd->stab_end;
f0104140:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104143:	8b 40 04             	mov    0x4(%eax),%eax
f0104146:	89 45 f0             	mov    %eax,-0x10(%ebp)
		stabstr = usd->stabstr;
f0104149:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010414c:	8b 40 08             	mov    0x8(%eax),%eax
f010414f:	89 45 ec             	mov    %eax,-0x14(%ebp)
		stabstr_end = usd->stabstr_end;
f0104152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104155:	8b 40 0c             	mov    0xc(%eax),%eax
f0104158:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010415b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010415e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0104161:	76 0a                	jbe    f010416d <debuginfo_eip+0xa4>
f0104163:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104166:	48                   	dec    %eax
f0104167:	8a 00                	mov    (%eax),%al
f0104169:	84 c0                	test   %al,%al
f010416b:	74 0a                	je     f0104177 <debuginfo_eip+0xae>
		return -1;
f010416d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104172:	e9 01 02 00 00       	jmp    f0104378 <debuginfo_eip+0x2af>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104177:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	rfile = (stab_end - stabs) - 1;
f010417e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104181:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104184:	29 c2                	sub    %eax,%edx
f0104186:	89 d0                	mov    %edx,%eax
f0104188:	c1 f8 02             	sar    $0x2,%eax
f010418b:	89 c2                	mov    %eax,%edx
f010418d:	89 d0                	mov    %edx,%eax
f010418f:	c1 e0 02             	shl    $0x2,%eax
f0104192:	01 d0                	add    %edx,%eax
f0104194:	c1 e0 02             	shl    $0x2,%eax
f0104197:	01 d0                	add    %edx,%eax
f0104199:	c1 e0 02             	shl    $0x2,%eax
f010419c:	01 d0                	add    %edx,%eax
f010419e:	89 c1                	mov    %eax,%ecx
f01041a0:	c1 e1 08             	shl    $0x8,%ecx
f01041a3:	01 c8                	add    %ecx,%eax
f01041a5:	89 c1                	mov    %eax,%ecx
f01041a7:	c1 e1 10             	shl    $0x10,%ecx
f01041aa:	01 c8                	add    %ecx,%eax
f01041ac:	01 c0                	add    %eax,%eax
f01041ae:	01 d0                	add    %edx,%eax
f01041b0:	48                   	dec    %eax
f01041b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01041b4:	ff 75 08             	pushl  0x8(%ebp)
f01041b7:	6a 64                	push   $0x64
f01041b9:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01041bc:	50                   	push   %eax
f01041bd:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01041c0:	50                   	push   %eax
f01041c1:	ff 75 f4             	pushl  -0xc(%ebp)
f01041c4:	e8 b3 fd ff ff       	call   f0103f7c <stab_binsearch>
f01041c9:	83 c4 14             	add    $0x14,%esp
	if (lfile == 0)
f01041cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01041cf:	85 c0                	test   %eax,%eax
f01041d1:	75 0a                	jne    f01041dd <debuginfo_eip+0x114>
		return -1;
f01041d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01041d8:	e9 9b 01 00 00       	jmp    f0104378 <debuginfo_eip+0x2af>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01041dd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01041e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	rfun = rfile;
f01041e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01041e6:	89 45 cc             	mov    %eax,-0x34(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01041e9:	ff 75 08             	pushl  0x8(%ebp)
f01041ec:	6a 24                	push   $0x24
f01041ee:	8d 45 cc             	lea    -0x34(%ebp),%eax
f01041f1:	50                   	push   %eax
f01041f2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01041f5:	50                   	push   %eax
f01041f6:	ff 75 f4             	pushl  -0xc(%ebp)
f01041f9:	e8 7e fd ff ff       	call   f0103f7c <stab_binsearch>
f01041fe:	83 c4 14             	add    $0x14,%esp

	if (lfun <= rfun) {
f0104201:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104204:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104207:	39 c2                	cmp    %eax,%edx
f0104209:	0f 8f 86 00 00 00    	jg     f0104295 <debuginfo_eip+0x1cc>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010420f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104212:	89 c2                	mov    %eax,%edx
f0104214:	89 d0                	mov    %edx,%eax
f0104216:	01 c0                	add    %eax,%eax
f0104218:	01 d0                	add    %edx,%eax
f010421a:	c1 e0 02             	shl    $0x2,%eax
f010421d:	89 c2                	mov    %eax,%edx
f010421f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104222:	01 d0                	add    %edx,%eax
f0104224:	8b 00                	mov    (%eax),%eax
f0104226:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0104229:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010422c:	29 d1                	sub    %edx,%ecx
f010422e:	89 ca                	mov    %ecx,%edx
f0104230:	39 d0                	cmp    %edx,%eax
f0104232:	73 22                	jae    f0104256 <debuginfo_eip+0x18d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104234:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104237:	89 c2                	mov    %eax,%edx
f0104239:	89 d0                	mov    %edx,%eax
f010423b:	01 c0                	add    %eax,%eax
f010423d:	01 d0                	add    %edx,%eax
f010423f:	c1 e0 02             	shl    $0x2,%eax
f0104242:	89 c2                	mov    %eax,%edx
f0104244:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104247:	01 d0                	add    %edx,%eax
f0104249:	8b 10                	mov    (%eax),%edx
f010424b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010424e:	01 c2                	add    %eax,%edx
f0104250:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104253:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = (uint32*) stabs[lfun].n_value;
f0104256:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104259:	89 c2                	mov    %eax,%edx
f010425b:	89 d0                	mov    %edx,%eax
f010425d:	01 c0                	add    %eax,%eax
f010425f:	01 d0                	add    %edx,%eax
f0104261:	c1 e0 02             	shl    $0x2,%eax
f0104264:	89 c2                	mov    %eax,%edx
f0104266:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104269:	01 d0                	add    %edx,%eax
f010426b:	8b 50 08             	mov    0x8(%eax),%edx
f010426e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104271:	89 50 10             	mov    %edx,0x10(%eax)
		addr = (uint32*)(addr - (info->eip_fn_addr));
f0104274:	8b 55 08             	mov    0x8(%ebp),%edx
f0104277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010427a:	8b 40 10             	mov    0x10(%eax),%eax
f010427d:	29 c2                	sub    %eax,%edx
f010427f:	89 d0                	mov    %edx,%eax
f0104281:	c1 f8 02             	sar    $0x2,%eax
f0104284:	89 45 08             	mov    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0104287:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010428a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfun;
f010428d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104290:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104293:	eb 15                	jmp    f01042aa <debuginfo_eip+0x1e1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104295:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104298:	8b 55 08             	mov    0x8(%ebp),%edx
f010429b:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f010429e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01042a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfile;
f01042a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01042a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01042aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042ad:	8b 40 08             	mov    0x8(%eax),%eax
f01042b0:	83 ec 08             	sub    $0x8,%esp
f01042b3:	6a 3a                	push   $0x3a
f01042b5:	50                   	push   %eax
f01042b6:	e8 a4 09 00 00       	call   f0104c5f <strfind>
f01042bb:	83 c4 10             	add    $0x10,%esp
f01042be:	89 c2                	mov    %eax,%edx
f01042c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042c3:	8b 40 08             	mov    0x8(%eax),%eax
f01042c6:	29 c2                	sub    %eax,%edx
f01042c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01042cb:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01042ce:	eb 03                	jmp    f01042d3 <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01042d0:	ff 4d e4             	decl   -0x1c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01042d3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01042d6:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01042d9:	7c 4e                	jl     f0104329 <debuginfo_eip+0x260>
	       && stabs[lline].n_type != N_SOL
f01042db:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01042de:	89 d0                	mov    %edx,%eax
f01042e0:	01 c0                	add    %eax,%eax
f01042e2:	01 d0                	add    %edx,%eax
f01042e4:	c1 e0 02             	shl    $0x2,%eax
f01042e7:	89 c2                	mov    %eax,%edx
f01042e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01042ec:	01 d0                	add    %edx,%eax
f01042ee:	8a 40 04             	mov    0x4(%eax),%al
f01042f1:	3c 84                	cmp    $0x84,%al
f01042f3:	74 34                	je     f0104329 <debuginfo_eip+0x260>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01042f5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01042f8:	89 d0                	mov    %edx,%eax
f01042fa:	01 c0                	add    %eax,%eax
f01042fc:	01 d0                	add    %edx,%eax
f01042fe:	c1 e0 02             	shl    $0x2,%eax
f0104301:	89 c2                	mov    %eax,%edx
f0104303:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104306:	01 d0                	add    %edx,%eax
f0104308:	8a 40 04             	mov    0x4(%eax),%al
f010430b:	3c 64                	cmp    $0x64,%al
f010430d:	75 c1                	jne    f01042d0 <debuginfo_eip+0x207>
f010430f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104312:	89 d0                	mov    %edx,%eax
f0104314:	01 c0                	add    %eax,%eax
f0104316:	01 d0                	add    %edx,%eax
f0104318:	c1 e0 02             	shl    $0x2,%eax
f010431b:	89 c2                	mov    %eax,%edx
f010431d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104320:	01 d0                	add    %edx,%eax
f0104322:	8b 40 08             	mov    0x8(%eax),%eax
f0104325:	85 c0                	test   %eax,%eax
f0104327:	74 a7                	je     f01042d0 <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104329:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010432c:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010432f:	7c 42                	jl     f0104373 <debuginfo_eip+0x2aa>
f0104331:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104334:	89 d0                	mov    %edx,%eax
f0104336:	01 c0                	add    %eax,%eax
f0104338:	01 d0                	add    %edx,%eax
f010433a:	c1 e0 02             	shl    $0x2,%eax
f010433d:	89 c2                	mov    %eax,%edx
f010433f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104342:	01 d0                	add    %edx,%eax
f0104344:	8b 00                	mov    (%eax),%eax
f0104346:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0104349:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010434c:	29 d1                	sub    %edx,%ecx
f010434e:	89 ca                	mov    %ecx,%edx
f0104350:	39 d0                	cmp    %edx,%eax
f0104352:	73 1f                	jae    f0104373 <debuginfo_eip+0x2aa>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104354:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104357:	89 d0                	mov    %edx,%eax
f0104359:	01 c0                	add    %eax,%eax
f010435b:	01 d0                	add    %edx,%eax
f010435d:	c1 e0 02             	shl    $0x2,%eax
f0104360:	89 c2                	mov    %eax,%edx
f0104362:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104365:	01 d0                	add    %edx,%eax
f0104367:	8b 10                	mov    (%eax),%edx
f0104369:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010436c:	01 c2                	add    %eax,%edx
f010436e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104371:	89 10                	mov    %edx,(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0104373:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104378:	c9                   	leave  
f0104379:	c3                   	ret    

f010437a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010437a:	55                   	push   %ebp
f010437b:	89 e5                	mov    %esp,%ebp
f010437d:	53                   	push   %ebx
f010437e:	83 ec 14             	sub    $0x14,%esp
f0104381:	8b 45 10             	mov    0x10(%ebp),%eax
f0104384:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104387:	8b 45 14             	mov    0x14(%ebp),%eax
f010438a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010438d:	8b 45 18             	mov    0x18(%ebp),%eax
f0104390:	ba 00 00 00 00       	mov    $0x0,%edx
f0104395:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0104398:	77 55                	ja     f01043ef <printnum+0x75>
f010439a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f010439d:	72 05                	jb     f01043a4 <printnum+0x2a>
f010439f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f01043a2:	77 4b                	ja     f01043ef <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01043a4:	8b 45 1c             	mov    0x1c(%ebp),%eax
f01043a7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01043aa:	8b 45 18             	mov    0x18(%ebp),%eax
f01043ad:	ba 00 00 00 00       	mov    $0x0,%edx
f01043b2:	52                   	push   %edx
f01043b3:	50                   	push   %eax
f01043b4:	ff 75 f4             	pushl  -0xc(%ebp)
f01043b7:	ff 75 f0             	pushl  -0x10(%ebp)
f01043ba:	e8 59 0c 00 00       	call   f0105018 <__udivdi3>
f01043bf:	83 c4 10             	add    $0x10,%esp
f01043c2:	83 ec 04             	sub    $0x4,%esp
f01043c5:	ff 75 20             	pushl  0x20(%ebp)
f01043c8:	53                   	push   %ebx
f01043c9:	ff 75 18             	pushl  0x18(%ebp)
f01043cc:	52                   	push   %edx
f01043cd:	50                   	push   %eax
f01043ce:	ff 75 0c             	pushl  0xc(%ebp)
f01043d1:	ff 75 08             	pushl  0x8(%ebp)
f01043d4:	e8 a1 ff ff ff       	call   f010437a <printnum>
f01043d9:	83 c4 20             	add    $0x20,%esp
f01043dc:	eb 1a                	jmp    f01043f8 <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01043de:	83 ec 08             	sub    $0x8,%esp
f01043e1:	ff 75 0c             	pushl  0xc(%ebp)
f01043e4:	ff 75 20             	pushl  0x20(%ebp)
f01043e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ea:	ff d0                	call   *%eax
f01043ec:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01043ef:	ff 4d 1c             	decl   0x1c(%ebp)
f01043f2:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f01043f6:	7f e6                	jg     f01043de <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01043f8:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01043fb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104400:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104403:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104406:	53                   	push   %ebx
f0104407:	51                   	push   %ecx
f0104408:	52                   	push   %edx
f0104409:	50                   	push   %eax
f010440a:	e8 19 0d 00 00       	call   f0105128 <__umoddi3>
f010440f:	83 c4 10             	add    $0x10,%esp
f0104412:	05 20 6b 10 f0       	add    $0xf0106b20,%eax
f0104417:	8a 00                	mov    (%eax),%al
f0104419:	0f be c0             	movsbl %al,%eax
f010441c:	83 ec 08             	sub    $0x8,%esp
f010441f:	ff 75 0c             	pushl  0xc(%ebp)
f0104422:	50                   	push   %eax
f0104423:	8b 45 08             	mov    0x8(%ebp),%eax
f0104426:	ff d0                	call   *%eax
f0104428:	83 c4 10             	add    $0x10,%esp
}
f010442b:	90                   	nop
f010442c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010442f:	c9                   	leave  
f0104430:	c3                   	ret    

f0104431 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104431:	55                   	push   %ebp
f0104432:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104434:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0104438:	7e 1c                	jle    f0104456 <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f010443a:	8b 45 08             	mov    0x8(%ebp),%eax
f010443d:	8b 00                	mov    (%eax),%eax
f010443f:	8d 50 08             	lea    0x8(%eax),%edx
f0104442:	8b 45 08             	mov    0x8(%ebp),%eax
f0104445:	89 10                	mov    %edx,(%eax)
f0104447:	8b 45 08             	mov    0x8(%ebp),%eax
f010444a:	8b 00                	mov    (%eax),%eax
f010444c:	83 e8 08             	sub    $0x8,%eax
f010444f:	8b 50 04             	mov    0x4(%eax),%edx
f0104452:	8b 00                	mov    (%eax),%eax
f0104454:	eb 40                	jmp    f0104496 <getuint+0x65>
	else if (lflag)
f0104456:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010445a:	74 1e                	je     f010447a <getuint+0x49>
		return va_arg(*ap, unsigned long);
f010445c:	8b 45 08             	mov    0x8(%ebp),%eax
f010445f:	8b 00                	mov    (%eax),%eax
f0104461:	8d 50 04             	lea    0x4(%eax),%edx
f0104464:	8b 45 08             	mov    0x8(%ebp),%eax
f0104467:	89 10                	mov    %edx,(%eax)
f0104469:	8b 45 08             	mov    0x8(%ebp),%eax
f010446c:	8b 00                	mov    (%eax),%eax
f010446e:	83 e8 04             	sub    $0x4,%eax
f0104471:	8b 00                	mov    (%eax),%eax
f0104473:	ba 00 00 00 00       	mov    $0x0,%edx
f0104478:	eb 1c                	jmp    f0104496 <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f010447a:	8b 45 08             	mov    0x8(%ebp),%eax
f010447d:	8b 00                	mov    (%eax),%eax
f010447f:	8d 50 04             	lea    0x4(%eax),%edx
f0104482:	8b 45 08             	mov    0x8(%ebp),%eax
f0104485:	89 10                	mov    %edx,(%eax)
f0104487:	8b 45 08             	mov    0x8(%ebp),%eax
f010448a:	8b 00                	mov    (%eax),%eax
f010448c:	83 e8 04             	sub    $0x4,%eax
f010448f:	8b 00                	mov    (%eax),%eax
f0104491:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104496:	5d                   	pop    %ebp
f0104497:	c3                   	ret    

f0104498 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0104498:	55                   	push   %ebp
f0104499:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010449b:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f010449f:	7e 1c                	jle    f01044bd <getint+0x25>
		return va_arg(*ap, long long);
f01044a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01044a4:	8b 00                	mov    (%eax),%eax
f01044a6:	8d 50 08             	lea    0x8(%eax),%edx
f01044a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01044ac:	89 10                	mov    %edx,(%eax)
f01044ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01044b1:	8b 00                	mov    (%eax),%eax
f01044b3:	83 e8 08             	sub    $0x8,%eax
f01044b6:	8b 50 04             	mov    0x4(%eax),%edx
f01044b9:	8b 00                	mov    (%eax),%eax
f01044bb:	eb 38                	jmp    f01044f5 <getint+0x5d>
	else if (lflag)
f01044bd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044c1:	74 1a                	je     f01044dd <getint+0x45>
		return va_arg(*ap, long);
f01044c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01044c6:	8b 00                	mov    (%eax),%eax
f01044c8:	8d 50 04             	lea    0x4(%eax),%edx
f01044cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01044ce:	89 10                	mov    %edx,(%eax)
f01044d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01044d3:	8b 00                	mov    (%eax),%eax
f01044d5:	83 e8 04             	sub    $0x4,%eax
f01044d8:	8b 00                	mov    (%eax),%eax
f01044da:	99                   	cltd   
f01044db:	eb 18                	jmp    f01044f5 <getint+0x5d>
	else
		return va_arg(*ap, int);
f01044dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01044e0:	8b 00                	mov    (%eax),%eax
f01044e2:	8d 50 04             	lea    0x4(%eax),%edx
f01044e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01044e8:	89 10                	mov    %edx,(%eax)
f01044ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01044ed:	8b 00                	mov    (%eax),%eax
f01044ef:	83 e8 04             	sub    $0x4,%eax
f01044f2:	8b 00                	mov    (%eax),%eax
f01044f4:	99                   	cltd   
}
f01044f5:	5d                   	pop    %ebp
f01044f6:	c3                   	ret    

f01044f7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01044f7:	55                   	push   %ebp
f01044f8:	89 e5                	mov    %esp,%ebp
f01044fa:	56                   	push   %esi
f01044fb:	53                   	push   %ebx
f01044fc:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01044ff:	eb 17                	jmp    f0104518 <vprintfmt+0x21>
			if (ch == '\0')
f0104501:	85 db                	test   %ebx,%ebx
f0104503:	0f 84 af 03 00 00    	je     f01048b8 <vprintfmt+0x3c1>
				return;
			putch(ch, putdat);
f0104509:	83 ec 08             	sub    $0x8,%esp
f010450c:	ff 75 0c             	pushl  0xc(%ebp)
f010450f:	53                   	push   %ebx
f0104510:	8b 45 08             	mov    0x8(%ebp),%eax
f0104513:	ff d0                	call   *%eax
f0104515:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104518:	8b 45 10             	mov    0x10(%ebp),%eax
f010451b:	8d 50 01             	lea    0x1(%eax),%edx
f010451e:	89 55 10             	mov    %edx,0x10(%ebp)
f0104521:	8a 00                	mov    (%eax),%al
f0104523:	0f b6 d8             	movzbl %al,%ebx
f0104526:	83 fb 25             	cmp    $0x25,%ebx
f0104529:	75 d6                	jne    f0104501 <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f010452b:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f010452f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0104536:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010453d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0104544:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010454b:	8b 45 10             	mov    0x10(%ebp),%eax
f010454e:	8d 50 01             	lea    0x1(%eax),%edx
f0104551:	89 55 10             	mov    %edx,0x10(%ebp)
f0104554:	8a 00                	mov    (%eax),%al
f0104556:	0f b6 d8             	movzbl %al,%ebx
f0104559:	8d 43 dd             	lea    -0x23(%ebx),%eax
f010455c:	83 f8 55             	cmp    $0x55,%eax
f010455f:	0f 87 2b 03 00 00    	ja     f0104890 <vprintfmt+0x399>
f0104565:	8b 04 85 44 6b 10 f0 	mov    -0xfef94bc(,%eax,4),%eax
f010456c:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f010456e:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f0104572:	eb d7                	jmp    f010454b <vprintfmt+0x54>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104574:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0104578:	eb d1                	jmp    f010454b <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010457a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f0104581:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104584:	89 d0                	mov    %edx,%eax
f0104586:	c1 e0 02             	shl    $0x2,%eax
f0104589:	01 d0                	add    %edx,%eax
f010458b:	01 c0                	add    %eax,%eax
f010458d:	01 d8                	add    %ebx,%eax
f010458f:	83 e8 30             	sub    $0x30,%eax
f0104592:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f0104595:	8b 45 10             	mov    0x10(%ebp),%eax
f0104598:	8a 00                	mov    (%eax),%al
f010459a:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f010459d:	83 fb 2f             	cmp    $0x2f,%ebx
f01045a0:	7e 3e                	jle    f01045e0 <vprintfmt+0xe9>
f01045a2:	83 fb 39             	cmp    $0x39,%ebx
f01045a5:	7f 39                	jg     f01045e0 <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01045a7:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01045aa:	eb d5                	jmp    f0104581 <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01045ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01045af:	83 c0 04             	add    $0x4,%eax
f01045b2:	89 45 14             	mov    %eax,0x14(%ebp)
f01045b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01045b8:	83 e8 04             	sub    $0x4,%eax
f01045bb:	8b 00                	mov    (%eax),%eax
f01045bd:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f01045c0:	eb 1f                	jmp    f01045e1 <vprintfmt+0xea>

		case '.':
			if (width < 0)
f01045c2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045c6:	79 83                	jns    f010454b <vprintfmt+0x54>
				width = 0;
f01045c8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f01045cf:	e9 77 ff ff ff       	jmp    f010454b <vprintfmt+0x54>

		case '#':
			altflag = 1;
f01045d4:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01045db:	e9 6b ff ff ff       	jmp    f010454b <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f01045e0:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01045e1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01045e5:	0f 89 60 ff ff ff    	jns    f010454b <vprintfmt+0x54>
				width = precision, precision = -1;
f01045eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01045f1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f01045f8:	e9 4e ff ff ff       	jmp    f010454b <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01045fd:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
f0104600:	e9 46 ff ff ff       	jmp    f010454b <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104605:	8b 45 14             	mov    0x14(%ebp),%eax
f0104608:	83 c0 04             	add    $0x4,%eax
f010460b:	89 45 14             	mov    %eax,0x14(%ebp)
f010460e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104611:	83 e8 04             	sub    $0x4,%eax
f0104614:	8b 00                	mov    (%eax),%eax
f0104616:	83 ec 08             	sub    $0x8,%esp
f0104619:	ff 75 0c             	pushl  0xc(%ebp)
f010461c:	50                   	push   %eax
f010461d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104620:	ff d0                	call   *%eax
f0104622:	83 c4 10             	add    $0x10,%esp
			break;
f0104625:	e9 89 02 00 00       	jmp    f01048b3 <vprintfmt+0x3bc>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010462a:	8b 45 14             	mov    0x14(%ebp),%eax
f010462d:	83 c0 04             	add    $0x4,%eax
f0104630:	89 45 14             	mov    %eax,0x14(%ebp)
f0104633:	8b 45 14             	mov    0x14(%ebp),%eax
f0104636:	83 e8 04             	sub    $0x4,%eax
f0104639:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f010463b:	85 db                	test   %ebx,%ebx
f010463d:	79 02                	jns    f0104641 <vprintfmt+0x14a>
				err = -err;
f010463f:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0104641:	83 fb 07             	cmp    $0x7,%ebx
f0104644:	7f 0b                	jg     f0104651 <vprintfmt+0x15a>
f0104646:	8b 34 9d 00 6b 10 f0 	mov    -0xfef9500(,%ebx,4),%esi
f010464d:	85 f6                	test   %esi,%esi
f010464f:	75 19                	jne    f010466a <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
f0104651:	53                   	push   %ebx
f0104652:	68 31 6b 10 f0       	push   $0xf0106b31
f0104657:	ff 75 0c             	pushl  0xc(%ebp)
f010465a:	ff 75 08             	pushl  0x8(%ebp)
f010465d:	e8 5e 02 00 00       	call   f01048c0 <printfmt>
f0104662:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0104665:	e9 49 02 00 00       	jmp    f01048b3 <vprintfmt+0x3bc>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f010466a:	56                   	push   %esi
f010466b:	68 3a 6b 10 f0       	push   $0xf0106b3a
f0104670:	ff 75 0c             	pushl  0xc(%ebp)
f0104673:	ff 75 08             	pushl  0x8(%ebp)
f0104676:	e8 45 02 00 00       	call   f01048c0 <printfmt>
f010467b:	83 c4 10             	add    $0x10,%esp
			break;
f010467e:	e9 30 02 00 00       	jmp    f01048b3 <vprintfmt+0x3bc>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104683:	8b 45 14             	mov    0x14(%ebp),%eax
f0104686:	83 c0 04             	add    $0x4,%eax
f0104689:	89 45 14             	mov    %eax,0x14(%ebp)
f010468c:	8b 45 14             	mov    0x14(%ebp),%eax
f010468f:	83 e8 04             	sub    $0x4,%eax
f0104692:	8b 30                	mov    (%eax),%esi
f0104694:	85 f6                	test   %esi,%esi
f0104696:	75 05                	jne    f010469d <vprintfmt+0x1a6>
				p = "(null)";
f0104698:	be 3d 6b 10 f0       	mov    $0xf0106b3d,%esi
			if (width > 0 && padc != '-')
f010469d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01046a1:	7e 6d                	jle    f0104710 <vprintfmt+0x219>
f01046a3:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f01046a7:	74 67                	je     f0104710 <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
f01046a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046ac:	83 ec 08             	sub    $0x8,%esp
f01046af:	50                   	push   %eax
f01046b0:	56                   	push   %esi
f01046b1:	e8 0a 04 00 00       	call   f0104ac0 <strnlen>
f01046b6:	83 c4 10             	add    $0x10,%esp
f01046b9:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f01046bc:	eb 16                	jmp    f01046d4 <vprintfmt+0x1dd>
					putch(padc, putdat);
f01046be:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f01046c2:	83 ec 08             	sub    $0x8,%esp
f01046c5:	ff 75 0c             	pushl  0xc(%ebp)
f01046c8:	50                   	push   %eax
f01046c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01046cc:	ff d0                	call   *%eax
f01046ce:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046d1:	ff 4d e4             	decl   -0x1c(%ebp)
f01046d4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01046d8:	7f e4                	jg     f01046be <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01046da:	eb 34                	jmp    f0104710 <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
f01046dc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01046e0:	74 1c                	je     f01046fe <vprintfmt+0x207>
f01046e2:	83 fb 1f             	cmp    $0x1f,%ebx
f01046e5:	7e 05                	jle    f01046ec <vprintfmt+0x1f5>
f01046e7:	83 fb 7e             	cmp    $0x7e,%ebx
f01046ea:	7e 12                	jle    f01046fe <vprintfmt+0x207>
					putch('?', putdat);
f01046ec:	83 ec 08             	sub    $0x8,%esp
f01046ef:	ff 75 0c             	pushl  0xc(%ebp)
f01046f2:	6a 3f                	push   $0x3f
f01046f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01046f7:	ff d0                	call   *%eax
f01046f9:	83 c4 10             	add    $0x10,%esp
f01046fc:	eb 0f                	jmp    f010470d <vprintfmt+0x216>
				else
					putch(ch, putdat);
f01046fe:	83 ec 08             	sub    $0x8,%esp
f0104701:	ff 75 0c             	pushl  0xc(%ebp)
f0104704:	53                   	push   %ebx
f0104705:	8b 45 08             	mov    0x8(%ebp),%eax
f0104708:	ff d0                	call   *%eax
f010470a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010470d:	ff 4d e4             	decl   -0x1c(%ebp)
f0104710:	89 f0                	mov    %esi,%eax
f0104712:	8d 70 01             	lea    0x1(%eax),%esi
f0104715:	8a 00                	mov    (%eax),%al
f0104717:	0f be d8             	movsbl %al,%ebx
f010471a:	85 db                	test   %ebx,%ebx
f010471c:	74 24                	je     f0104742 <vprintfmt+0x24b>
f010471e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104722:	78 b8                	js     f01046dc <vprintfmt+0x1e5>
f0104724:	ff 4d e0             	decl   -0x20(%ebp)
f0104727:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010472b:	79 af                	jns    f01046dc <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010472d:	eb 13                	jmp    f0104742 <vprintfmt+0x24b>
				putch(' ', putdat);
f010472f:	83 ec 08             	sub    $0x8,%esp
f0104732:	ff 75 0c             	pushl  0xc(%ebp)
f0104735:	6a 20                	push   $0x20
f0104737:	8b 45 08             	mov    0x8(%ebp),%eax
f010473a:	ff d0                	call   *%eax
f010473c:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010473f:	ff 4d e4             	decl   -0x1c(%ebp)
f0104742:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104746:	7f e7                	jg     f010472f <vprintfmt+0x238>
				putch(' ', putdat);
			break;
f0104748:	e9 66 01 00 00       	jmp    f01048b3 <vprintfmt+0x3bc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010474d:	83 ec 08             	sub    $0x8,%esp
f0104750:	ff 75 e8             	pushl  -0x18(%ebp)
f0104753:	8d 45 14             	lea    0x14(%ebp),%eax
f0104756:	50                   	push   %eax
f0104757:	e8 3c fd ff ff       	call   f0104498 <getint>
f010475c:	83 c4 10             	add    $0x10,%esp
f010475f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104762:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0104765:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104768:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010476b:	85 d2                	test   %edx,%edx
f010476d:	79 23                	jns    f0104792 <vprintfmt+0x29b>
				putch('-', putdat);
f010476f:	83 ec 08             	sub    $0x8,%esp
f0104772:	ff 75 0c             	pushl  0xc(%ebp)
f0104775:	6a 2d                	push   $0x2d
f0104777:	8b 45 08             	mov    0x8(%ebp),%eax
f010477a:	ff d0                	call   *%eax
f010477c:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f010477f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104782:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104785:	f7 d8                	neg    %eax
f0104787:	83 d2 00             	adc    $0x0,%edx
f010478a:	f7 da                	neg    %edx
f010478c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010478f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f0104792:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0104799:	e9 bc 00 00 00       	jmp    f010485a <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010479e:	83 ec 08             	sub    $0x8,%esp
f01047a1:	ff 75 e8             	pushl  -0x18(%ebp)
f01047a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01047a7:	50                   	push   %eax
f01047a8:	e8 84 fc ff ff       	call   f0104431 <getuint>
f01047ad:	83 c4 10             	add    $0x10,%esp
f01047b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01047b3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f01047b6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01047bd:	e9 98 00 00 00       	jmp    f010485a <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01047c2:	83 ec 08             	sub    $0x8,%esp
f01047c5:	ff 75 0c             	pushl  0xc(%ebp)
f01047c8:	6a 58                	push   $0x58
f01047ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01047cd:	ff d0                	call   *%eax
f01047cf:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f01047d2:	83 ec 08             	sub    $0x8,%esp
f01047d5:	ff 75 0c             	pushl  0xc(%ebp)
f01047d8:	6a 58                	push   $0x58
f01047da:	8b 45 08             	mov    0x8(%ebp),%eax
f01047dd:	ff d0                	call   *%eax
f01047df:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f01047e2:	83 ec 08             	sub    $0x8,%esp
f01047e5:	ff 75 0c             	pushl  0xc(%ebp)
f01047e8:	6a 58                	push   $0x58
f01047ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01047ed:	ff d0                	call   *%eax
f01047ef:	83 c4 10             	add    $0x10,%esp
			break;
f01047f2:	e9 bc 00 00 00       	jmp    f01048b3 <vprintfmt+0x3bc>

		// pointer
		case 'p':
			putch('0', putdat);
f01047f7:	83 ec 08             	sub    $0x8,%esp
f01047fa:	ff 75 0c             	pushl  0xc(%ebp)
f01047fd:	6a 30                	push   $0x30
f01047ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104802:	ff d0                	call   *%eax
f0104804:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f0104807:	83 ec 08             	sub    $0x8,%esp
f010480a:	ff 75 0c             	pushl  0xc(%ebp)
f010480d:	6a 78                	push   $0x78
f010480f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104812:	ff d0                	call   *%eax
f0104814:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
f0104817:	8b 45 14             	mov    0x14(%ebp),%eax
f010481a:	83 c0 04             	add    $0x4,%eax
f010481d:	89 45 14             	mov    %eax,0x14(%ebp)
f0104820:	8b 45 14             	mov    0x14(%ebp),%eax
f0104823:	83 e8 04             	sub    $0x4,%eax
f0104826:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104828:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010482b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
f0104832:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f0104839:	eb 1f                	jmp    f010485a <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010483b:	83 ec 08             	sub    $0x8,%esp
f010483e:	ff 75 e8             	pushl  -0x18(%ebp)
f0104841:	8d 45 14             	lea    0x14(%ebp),%eax
f0104844:	50                   	push   %eax
f0104845:	e8 e7 fb ff ff       	call   f0104431 <getuint>
f010484a:	83 c4 10             	add    $0x10,%esp
f010484d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104850:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0104853:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f010485a:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f010485e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104861:	83 ec 04             	sub    $0x4,%esp
f0104864:	52                   	push   %edx
f0104865:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104868:	50                   	push   %eax
f0104869:	ff 75 f4             	pushl  -0xc(%ebp)
f010486c:	ff 75 f0             	pushl  -0x10(%ebp)
f010486f:	ff 75 0c             	pushl  0xc(%ebp)
f0104872:	ff 75 08             	pushl  0x8(%ebp)
f0104875:	e8 00 fb ff ff       	call   f010437a <printnum>
f010487a:	83 c4 20             	add    $0x20,%esp
			break;
f010487d:	eb 34                	jmp    f01048b3 <vprintfmt+0x3bc>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010487f:	83 ec 08             	sub    $0x8,%esp
f0104882:	ff 75 0c             	pushl  0xc(%ebp)
f0104885:	53                   	push   %ebx
f0104886:	8b 45 08             	mov    0x8(%ebp),%eax
f0104889:	ff d0                	call   *%eax
f010488b:	83 c4 10             	add    $0x10,%esp
			break;
f010488e:	eb 23                	jmp    f01048b3 <vprintfmt+0x3bc>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104890:	83 ec 08             	sub    $0x8,%esp
f0104893:	ff 75 0c             	pushl  0xc(%ebp)
f0104896:	6a 25                	push   $0x25
f0104898:	8b 45 08             	mov    0x8(%ebp),%eax
f010489b:	ff d0                	call   *%eax
f010489d:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f01048a0:	ff 4d 10             	decl   0x10(%ebp)
f01048a3:	eb 03                	jmp    f01048a8 <vprintfmt+0x3b1>
f01048a5:	ff 4d 10             	decl   0x10(%ebp)
f01048a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01048ab:	48                   	dec    %eax
f01048ac:	8a 00                	mov    (%eax),%al
f01048ae:	3c 25                	cmp    $0x25,%al
f01048b0:	75 f3                	jne    f01048a5 <vprintfmt+0x3ae>
				/* do nothing */;
			break;
f01048b2:	90                   	nop
		}
	}
f01048b3:	e9 47 fc ff ff       	jmp    f01044ff <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f01048b8:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01048b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01048bc:	5b                   	pop    %ebx
f01048bd:	5e                   	pop    %esi
f01048be:	5d                   	pop    %ebp
f01048bf:	c3                   	ret    

f01048c0 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01048c0:	55                   	push   %ebp
f01048c1:	89 e5                	mov    %esp,%ebp
f01048c3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01048c6:	8d 45 10             	lea    0x10(%ebp),%eax
f01048c9:	83 c0 04             	add    $0x4,%eax
f01048cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f01048cf:	8b 45 10             	mov    0x10(%ebp),%eax
f01048d2:	ff 75 f4             	pushl  -0xc(%ebp)
f01048d5:	50                   	push   %eax
f01048d6:	ff 75 0c             	pushl  0xc(%ebp)
f01048d9:	ff 75 08             	pushl  0x8(%ebp)
f01048dc:	e8 16 fc ff ff       	call   f01044f7 <vprintfmt>
f01048e1:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f01048e4:	90                   	nop
f01048e5:	c9                   	leave  
f01048e6:	c3                   	ret    

f01048e7 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01048e7:	55                   	push   %ebp
f01048e8:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f01048ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048ed:	8b 40 08             	mov    0x8(%eax),%eax
f01048f0:	8d 50 01             	lea    0x1(%eax),%edx
f01048f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048f6:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f01048f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048fc:	8b 10                	mov    (%eax),%edx
f01048fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104901:	8b 40 04             	mov    0x4(%eax),%eax
f0104904:	39 c2                	cmp    %eax,%edx
f0104906:	73 12                	jae    f010491a <sprintputch+0x33>
		*b->buf++ = ch;
f0104908:	8b 45 0c             	mov    0xc(%ebp),%eax
f010490b:	8b 00                	mov    (%eax),%eax
f010490d:	8d 48 01             	lea    0x1(%eax),%ecx
f0104910:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104913:	89 0a                	mov    %ecx,(%edx)
f0104915:	8b 55 08             	mov    0x8(%ebp),%edx
f0104918:	88 10                	mov    %dl,(%eax)
}
f010491a:	90                   	nop
f010491b:	5d                   	pop    %ebp
f010491c:	c3                   	ret    

f010491d <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010491d:	55                   	push   %ebp
f010491e:	89 e5                	mov    %esp,%ebp
f0104920:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104923:	8b 45 08             	mov    0x8(%ebp),%eax
f0104926:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104929:	8b 45 0c             	mov    0xc(%ebp),%eax
f010492c:	8d 50 ff             	lea    -0x1(%eax),%edx
f010492f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104932:	01 d0                	add    %edx,%eax
f0104934:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104937:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010493e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0104942:	74 06                	je     f010494a <vsnprintf+0x2d>
f0104944:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104948:	7f 07                	jg     f0104951 <vsnprintf+0x34>
		return -E_INVAL;
f010494a:	b8 03 00 00 00       	mov    $0x3,%eax
f010494f:	eb 20                	jmp    f0104971 <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104951:	ff 75 14             	pushl  0x14(%ebp)
f0104954:	ff 75 10             	pushl  0x10(%ebp)
f0104957:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010495a:	50                   	push   %eax
f010495b:	68 e7 48 10 f0       	push   $0xf01048e7
f0104960:	e8 92 fb ff ff       	call   f01044f7 <vprintfmt>
f0104965:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f0104968:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010496b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010496e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0104971:	c9                   	leave  
f0104972:	c3                   	ret    

f0104973 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104973:	55                   	push   %ebp
f0104974:	89 e5                	mov    %esp,%ebp
f0104976:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104979:	8d 45 10             	lea    0x10(%ebp),%eax
f010497c:	83 c0 04             	add    $0x4,%eax
f010497f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0104982:	8b 45 10             	mov    0x10(%ebp),%eax
f0104985:	ff 75 f4             	pushl  -0xc(%ebp)
f0104988:	50                   	push   %eax
f0104989:	ff 75 0c             	pushl  0xc(%ebp)
f010498c:	ff 75 08             	pushl  0x8(%ebp)
f010498f:	e8 89 ff ff ff       	call   f010491d <vsnprintf>
f0104994:	83 c4 10             	add    $0x10,%esp
f0104997:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f010499a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f010499d:	c9                   	leave  
f010499e:	c3                   	ret    

f010499f <readline>:

#define BUFLEN 1024
//static char buf[BUFLEN];

void readline(const char *prompt, char* buf)
{
f010499f:	55                   	push   %ebp
f01049a0:	89 e5                	mov    %esp,%ebp
f01049a2:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;
	
	if (prompt != NULL)
f01049a5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01049a9:	74 13                	je     f01049be <readline+0x1f>
		cprintf("%s", prompt);
f01049ab:	83 ec 08             	sub    $0x8,%esp
f01049ae:	ff 75 08             	pushl  0x8(%ebp)
f01049b1:	68 9c 6c 10 f0       	push   $0xf0106c9c
f01049b6:	e8 ee eb ff ff       	call   f01035a9 <cprintf>
f01049bb:	83 c4 10             	add    $0x10,%esp

	
	i = 0;
f01049be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);	
f01049c5:	83 ec 0c             	sub    $0xc,%esp
f01049c8:	6a 00                	push   $0x0
f01049ca:	e8 78 bf ff ff       	call   f0100947 <iscons>
f01049cf:	83 c4 10             	add    $0x10,%esp
f01049d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f01049d5:	e8 54 bf ff ff       	call   f010092e <getchar>
f01049da:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f01049dd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01049e1:	79 22                	jns    f0104a05 <readline+0x66>
			if (c != -E_EOF)
f01049e3:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
f01049e7:	0f 84 ad 00 00 00    	je     f0104a9a <readline+0xfb>
				cprintf("read error: %e\n", c);			
f01049ed:	83 ec 08             	sub    $0x8,%esp
f01049f0:	ff 75 ec             	pushl  -0x14(%ebp)
f01049f3:	68 9f 6c 10 f0       	push   $0xf0106c9f
f01049f8:	e8 ac eb ff ff       	call   f01035a9 <cprintf>
f01049fd:	83 c4 10             	add    $0x10,%esp
			return;
f0104a00:	e9 95 00 00 00       	jmp    f0104a9a <readline+0xfb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104a05:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0104a09:	7e 34                	jle    f0104a3f <readline+0xa0>
f0104a0b:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f0104a12:	7f 2b                	jg     f0104a3f <readline+0xa0>
			if (echoing)
f0104a14:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104a18:	74 0e                	je     f0104a28 <readline+0x89>
				cputchar(c);
f0104a1a:	83 ec 0c             	sub    $0xc,%esp
f0104a1d:	ff 75 ec             	pushl  -0x14(%ebp)
f0104a20:	e8 f2 be ff ff       	call   f0100917 <cputchar>
f0104a25:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a2b:	8d 50 01             	lea    0x1(%eax),%edx
f0104a2e:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0104a31:	89 c2                	mov    %eax,%edx
f0104a33:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a36:	01 d0                	add    %edx,%eax
f0104a38:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0104a3b:	88 10                	mov    %dl,(%eax)
f0104a3d:	eb 56                	jmp    f0104a95 <readline+0xf6>
		} else if (c == '\b' && i > 0) {
f0104a3f:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0104a43:	75 1f                	jne    f0104a64 <readline+0xc5>
f0104a45:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104a49:	7e 19                	jle    f0104a64 <readline+0xc5>
			if (echoing)
f0104a4b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104a4f:	74 0e                	je     f0104a5f <readline+0xc0>
				cputchar(c);
f0104a51:	83 ec 0c             	sub    $0xc,%esp
f0104a54:	ff 75 ec             	pushl  -0x14(%ebp)
f0104a57:	e8 bb be ff ff       	call   f0100917 <cputchar>
f0104a5c:	83 c4 10             	add    $0x10,%esp
			i--;
f0104a5f:	ff 4d f4             	decl   -0xc(%ebp)
f0104a62:	eb 31                	jmp    f0104a95 <readline+0xf6>
		} else if (c == '\n' || c == '\r') {
f0104a64:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0104a68:	74 0a                	je     f0104a74 <readline+0xd5>
f0104a6a:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f0104a6e:	0f 85 61 ff ff ff    	jne    f01049d5 <readline+0x36>
			if (echoing)
f0104a74:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104a78:	74 0e                	je     f0104a88 <readline+0xe9>
				cputchar(c);
f0104a7a:	83 ec 0c             	sub    $0xc,%esp
f0104a7d:	ff 75 ec             	pushl  -0x14(%ebp)
f0104a80:	e8 92 be ff ff       	call   f0100917 <cputchar>
f0104a85:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;	
f0104a88:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104a8b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a8e:	01 d0                	add    %edx,%eax
f0104a90:	c6 00 00             	movb   $0x0,(%eax)
			return;		
f0104a93:	eb 06                	jmp    f0104a9b <readline+0xfc>
		}
	}
f0104a95:	e9 3b ff ff ff       	jmp    f01049d5 <readline+0x36>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);			
			return;
f0104a9a:	90                   	nop
				cputchar(c);
			buf[i] = 0;	
			return;		
		}
	}
}
f0104a9b:	c9                   	leave  
f0104a9c:	c3                   	ret    

f0104a9d <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0104a9d:	55                   	push   %ebp
f0104a9e:	89 e5                	mov    %esp,%ebp
f0104aa0:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0104aa3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104aaa:	eb 06                	jmp    f0104ab2 <strlen+0x15>
		n++;
f0104aac:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104aaf:	ff 45 08             	incl   0x8(%ebp)
f0104ab2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab5:	8a 00                	mov    (%eax),%al
f0104ab7:	84 c0                	test   %al,%al
f0104ab9:	75 f1                	jne    f0104aac <strlen+0xf>
		n++;
	return n;
f0104abb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104abe:	c9                   	leave  
f0104abf:	c3                   	ret    

f0104ac0 <strnlen>:

int
strnlen(const char *s, uint32 size)
{
f0104ac0:	55                   	push   %ebp
f0104ac1:	89 e5                	mov    %esp,%ebp
f0104ac3:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104ac6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104acd:	eb 09                	jmp    f0104ad8 <strnlen+0x18>
		n++;
f0104acf:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104ad2:	ff 45 08             	incl   0x8(%ebp)
f0104ad5:	ff 4d 0c             	decl   0xc(%ebp)
f0104ad8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104adc:	74 09                	je     f0104ae7 <strnlen+0x27>
f0104ade:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ae1:	8a 00                	mov    (%eax),%al
f0104ae3:	84 c0                	test   %al,%al
f0104ae5:	75 e8                	jne    f0104acf <strnlen+0xf>
		n++;
	return n;
f0104ae7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104aea:	c9                   	leave  
f0104aeb:	c3                   	ret    

f0104aec <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104aec:	55                   	push   %ebp
f0104aed:	89 e5                	mov    %esp,%ebp
f0104aef:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0104af2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104af5:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0104af8:	90                   	nop
f0104af9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104afc:	8d 50 01             	lea    0x1(%eax),%edx
f0104aff:	89 55 08             	mov    %edx,0x8(%ebp)
f0104b02:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b05:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104b08:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0104b0b:	8a 12                	mov    (%edx),%dl
f0104b0d:	88 10                	mov    %dl,(%eax)
f0104b0f:	8a 00                	mov    (%eax),%al
f0104b11:	84 c0                	test   %al,%al
f0104b13:	75 e4                	jne    f0104af9 <strcpy+0xd>
		/* do nothing */;
	return ret;
f0104b15:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104b18:	c9                   	leave  
f0104b19:	c3                   	ret    

f0104b1a <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
f0104b1a:	55                   	push   %ebp
f0104b1b:	89 e5                	mov    %esp,%ebp
f0104b1d:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
f0104b20:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b23:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0104b26:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104b2d:	eb 1f                	jmp    f0104b4e <strncpy+0x34>
		*dst++ = *src;
f0104b2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b32:	8d 50 01             	lea    0x1(%eax),%edx
f0104b35:	89 55 08             	mov    %edx,0x8(%ebp)
f0104b38:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b3b:	8a 12                	mov    (%edx),%dl
f0104b3d:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0104b3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b42:	8a 00                	mov    (%eax),%al
f0104b44:	84 c0                	test   %al,%al
f0104b46:	74 03                	je     f0104b4b <strncpy+0x31>
			src++;
f0104b48:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b4b:	ff 45 fc             	incl   -0x4(%ebp)
f0104b4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104b51:	3b 45 10             	cmp    0x10(%ebp),%eax
f0104b54:	72 d9                	jb     f0104b2f <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0104b56:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104b59:	c9                   	leave  
f0104b5a:	c3                   	ret    

f0104b5b <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
f0104b5b:	55                   	push   %ebp
f0104b5c:	89 e5                	mov    %esp,%ebp
f0104b5e:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f0104b61:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b64:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0104b67:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104b6b:	74 30                	je     f0104b9d <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
f0104b6d:	eb 16                	jmp    f0104b85 <strlcpy+0x2a>
			*dst++ = *src++;
f0104b6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b72:	8d 50 01             	lea    0x1(%eax),%edx
f0104b75:	89 55 08             	mov    %edx,0x8(%ebp)
f0104b78:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b7b:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104b7e:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0104b81:	8a 12                	mov    (%edx),%dl
f0104b83:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b85:	ff 4d 10             	decl   0x10(%ebp)
f0104b88:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104b8c:	74 09                	je     f0104b97 <strlcpy+0x3c>
f0104b8e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b91:	8a 00                	mov    (%eax),%al
f0104b93:	84 c0                	test   %al,%al
f0104b95:	75 d8                	jne    f0104b6f <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0104b97:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b9a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104b9d:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ba0:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104ba3:	29 c2                	sub    %eax,%edx
f0104ba5:	89 d0                	mov    %edx,%eax
}
f0104ba7:	c9                   	leave  
f0104ba8:	c3                   	ret    

f0104ba9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ba9:	55                   	push   %ebp
f0104baa:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0104bac:	eb 06                	jmp    f0104bb4 <strcmp+0xb>
		p++, q++;
f0104bae:	ff 45 08             	incl   0x8(%ebp)
f0104bb1:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104bb4:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bb7:	8a 00                	mov    (%eax),%al
f0104bb9:	84 c0                	test   %al,%al
f0104bbb:	74 0e                	je     f0104bcb <strcmp+0x22>
f0104bbd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bc0:	8a 10                	mov    (%eax),%dl
f0104bc2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bc5:	8a 00                	mov    (%eax),%al
f0104bc7:	38 c2                	cmp    %al,%dl
f0104bc9:	74 e3                	je     f0104bae <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bce:	8a 00                	mov    (%eax),%al
f0104bd0:	0f b6 d0             	movzbl %al,%edx
f0104bd3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bd6:	8a 00                	mov    (%eax),%al
f0104bd8:	0f b6 c0             	movzbl %al,%eax
f0104bdb:	29 c2                	sub    %eax,%edx
f0104bdd:	89 d0                	mov    %edx,%eax
}
f0104bdf:	5d                   	pop    %ebp
f0104be0:	c3                   	ret    

f0104be1 <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
f0104be1:	55                   	push   %ebp
f0104be2:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0104be4:	eb 09                	jmp    f0104bef <strncmp+0xe>
		n--, p++, q++;
f0104be6:	ff 4d 10             	decl   0x10(%ebp)
f0104be9:	ff 45 08             	incl   0x8(%ebp)
f0104bec:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
f0104bef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104bf3:	74 17                	je     f0104c0c <strncmp+0x2b>
f0104bf5:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bf8:	8a 00                	mov    (%eax),%al
f0104bfa:	84 c0                	test   %al,%al
f0104bfc:	74 0e                	je     f0104c0c <strncmp+0x2b>
f0104bfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c01:	8a 10                	mov    (%eax),%dl
f0104c03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c06:	8a 00                	mov    (%eax),%al
f0104c08:	38 c2                	cmp    %al,%dl
f0104c0a:	74 da                	je     f0104be6 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0104c0c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104c10:	75 07                	jne    f0104c19 <strncmp+0x38>
		return 0;
f0104c12:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c17:	eb 14                	jmp    f0104c2d <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c1c:	8a 00                	mov    (%eax),%al
f0104c1e:	0f b6 d0             	movzbl %al,%edx
f0104c21:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c24:	8a 00                	mov    (%eax),%al
f0104c26:	0f b6 c0             	movzbl %al,%eax
f0104c29:	29 c2                	sub    %eax,%edx
f0104c2b:	89 d0                	mov    %edx,%eax
}
f0104c2d:	5d                   	pop    %ebp
f0104c2e:	c3                   	ret    

f0104c2f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c2f:	55                   	push   %ebp
f0104c30:	89 e5                	mov    %esp,%ebp
f0104c32:	83 ec 04             	sub    $0x4,%esp
f0104c35:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c38:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104c3b:	eb 12                	jmp    f0104c4f <strchr+0x20>
		if (*s == c)
f0104c3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c40:	8a 00                	mov    (%eax),%al
f0104c42:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104c45:	75 05                	jne    f0104c4c <strchr+0x1d>
			return (char *) s;
f0104c47:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c4a:	eb 11                	jmp    f0104c5d <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c4c:	ff 45 08             	incl   0x8(%ebp)
f0104c4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c52:	8a 00                	mov    (%eax),%al
f0104c54:	84 c0                	test   %al,%al
f0104c56:	75 e5                	jne    f0104c3d <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c58:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c5d:	c9                   	leave  
f0104c5e:	c3                   	ret    

f0104c5f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c5f:	55                   	push   %ebp
f0104c60:	89 e5                	mov    %esp,%ebp
f0104c62:	83 ec 04             	sub    $0x4,%esp
f0104c65:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c68:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104c6b:	eb 0d                	jmp    f0104c7a <strfind+0x1b>
		if (*s == c)
f0104c6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c70:	8a 00                	mov    (%eax),%al
f0104c72:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104c75:	74 0e                	je     f0104c85 <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104c77:	ff 45 08             	incl   0x8(%ebp)
f0104c7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c7d:	8a 00                	mov    (%eax),%al
f0104c7f:	84 c0                	test   %al,%al
f0104c81:	75 ea                	jne    f0104c6d <strfind+0xe>
f0104c83:	eb 01                	jmp    f0104c86 <strfind+0x27>
		if (*s == c)
			break;
f0104c85:	90                   	nop
	return (char *) s;
f0104c86:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104c89:	c9                   	leave  
f0104c8a:	c3                   	ret    

f0104c8b <memset>:


void *
memset(void *v, int c, uint32 n)
{
f0104c8b:	55                   	push   %ebp
f0104c8c:	89 e5                	mov    %esp,%ebp
f0104c8e:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f0104c91:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c94:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0104c97:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c9a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f0104c9d:	eb 0e                	jmp    f0104cad <memset+0x22>
		*p++ = c;
f0104c9f:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104ca2:	8d 50 01             	lea    0x1(%eax),%edx
f0104ca5:	89 55 fc             	mov    %edx,-0x4(%ebp)
f0104ca8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cab:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0104cad:	ff 4d f8             	decl   -0x8(%ebp)
f0104cb0:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0104cb4:	79 e9                	jns    f0104c9f <memset+0x14>
		*p++ = c;

	return v;
f0104cb6:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104cb9:	c9                   	leave  
f0104cba:	c3                   	ret    

f0104cbb <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
f0104cbb:	55                   	push   %ebp
f0104cbc:	89 e5                	mov    %esp,%ebp
f0104cbe:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0104cc1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cc4:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0104cc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cca:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (n-- > 0)
f0104ccd:	eb 16                	jmp    f0104ce5 <memcpy+0x2a>
		*d++ = *s++;
f0104ccf:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104cd2:	8d 50 01             	lea    0x1(%eax),%edx
f0104cd5:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104cd8:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104cdb:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104cde:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104ce1:	8a 12                	mov    (%edx),%dl
f0104ce3:	88 10                	mov    %dl,(%eax)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0104ce5:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ce8:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104ceb:	89 55 10             	mov    %edx,0x10(%ebp)
f0104cee:	85 c0                	test   %eax,%eax
f0104cf0:	75 dd                	jne    f0104ccf <memcpy+0x14>
		*d++ = *s++;

	return dst;
f0104cf2:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104cf5:	c9                   	leave  
f0104cf6:	c3                   	ret    

f0104cf7 <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
f0104cf7:	55                   	push   %ebp
f0104cf8:	89 e5                	mov    %esp,%ebp
f0104cfa:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f0104cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d00:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0104d03:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d06:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f0104d09:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104d0c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0104d0f:	73 50                	jae    f0104d61 <memmove+0x6a>
f0104d11:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104d14:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d17:	01 d0                	add    %edx,%eax
f0104d19:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0104d1c:	76 43                	jbe    f0104d61 <memmove+0x6a>
		s += n;
f0104d1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d21:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f0104d24:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d27:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f0104d2a:	eb 10                	jmp    f0104d3c <memmove+0x45>
			*--d = *--s;
f0104d2c:	ff 4d f8             	decl   -0x8(%ebp)
f0104d2f:	ff 4d fc             	decl   -0x4(%ebp)
f0104d32:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104d35:	8a 10                	mov    (%eax),%dl
f0104d37:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104d3a:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0104d3c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d3f:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104d42:	89 55 10             	mov    %edx,0x10(%ebp)
f0104d45:	85 c0                	test   %eax,%eax
f0104d47:	75 e3                	jne    f0104d2c <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d49:	eb 23                	jmp    f0104d6e <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0104d4b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104d4e:	8d 50 01             	lea    0x1(%eax),%edx
f0104d51:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104d54:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104d57:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d5a:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104d5d:	8a 12                	mov    (%edx),%dl
f0104d5f:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0104d61:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d64:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104d67:	89 55 10             	mov    %edx,0x10(%ebp)
f0104d6a:	85 c0                	test   %eax,%eax
f0104d6c:	75 dd                	jne    f0104d4b <memmove+0x54>
			*d++ = *s++;

	return dst;
f0104d6e:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104d71:	c9                   	leave  
f0104d72:	c3                   	ret    

f0104d73 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
f0104d73:	55                   	push   %ebp
f0104d74:	89 e5                	mov    %esp,%ebp
f0104d76:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
f0104d79:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d7c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
f0104d7f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d82:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0104d85:	eb 2a                	jmp    f0104db1 <memcmp+0x3e>
		if (*s1 != *s2)
f0104d87:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104d8a:	8a 10                	mov    (%eax),%dl
f0104d8c:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104d8f:	8a 00                	mov    (%eax),%al
f0104d91:	38 c2                	cmp    %al,%dl
f0104d93:	74 16                	je     f0104dab <memcmp+0x38>
			return (int) *s1 - (int) *s2;
f0104d95:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104d98:	8a 00                	mov    (%eax),%al
f0104d9a:	0f b6 d0             	movzbl %al,%edx
f0104d9d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104da0:	8a 00                	mov    (%eax),%al
f0104da2:	0f b6 c0             	movzbl %al,%eax
f0104da5:	29 c2                	sub    %eax,%edx
f0104da7:	89 d0                	mov    %edx,%eax
f0104da9:	eb 18                	jmp    f0104dc3 <memcmp+0x50>
		s1++, s2++;
f0104dab:	ff 45 fc             	incl   -0x4(%ebp)
f0104dae:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
f0104db1:	8b 45 10             	mov    0x10(%ebp),%eax
f0104db4:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104db7:	89 55 10             	mov    %edx,0x10(%ebp)
f0104dba:	85 c0                	test   %eax,%eax
f0104dbc:	75 c9                	jne    f0104d87 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104dbe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104dc3:	c9                   	leave  
f0104dc4:	c3                   	ret    

f0104dc5 <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
f0104dc5:	55                   	push   %ebp
f0104dc6:	89 e5                	mov    %esp,%ebp
f0104dc8:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0104dcb:	8b 55 08             	mov    0x8(%ebp),%edx
f0104dce:	8b 45 10             	mov    0x10(%ebp),%eax
f0104dd1:	01 d0                	add    %edx,%eax
f0104dd3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0104dd6:	eb 15                	jmp    f0104ded <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ddb:	8a 00                	mov    (%eax),%al
f0104ddd:	0f b6 d0             	movzbl %al,%edx
f0104de0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104de3:	0f b6 c0             	movzbl %al,%eax
f0104de6:	39 c2                	cmp    %eax,%edx
f0104de8:	74 0d                	je     f0104df7 <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104dea:	ff 45 08             	incl   0x8(%ebp)
f0104ded:	8b 45 08             	mov    0x8(%ebp),%eax
f0104df0:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0104df3:	72 e3                	jb     f0104dd8 <memfind+0x13>
f0104df5:	eb 01                	jmp    f0104df8 <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f0104df7:	90                   	nop
	return (void *) s;
f0104df8:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104dfb:	c9                   	leave  
f0104dfc:	c3                   	ret    

f0104dfd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104dfd:	55                   	push   %ebp
f0104dfe:	89 e5                	mov    %esp,%ebp
f0104e00:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0104e03:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0104e0a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e11:	eb 03                	jmp    f0104e16 <strtol+0x19>
		s++;
f0104e13:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e16:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e19:	8a 00                	mov    (%eax),%al
f0104e1b:	3c 20                	cmp    $0x20,%al
f0104e1d:	74 f4                	je     f0104e13 <strtol+0x16>
f0104e1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e22:	8a 00                	mov    (%eax),%al
f0104e24:	3c 09                	cmp    $0x9,%al
f0104e26:	74 eb                	je     f0104e13 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e28:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e2b:	8a 00                	mov    (%eax),%al
f0104e2d:	3c 2b                	cmp    $0x2b,%al
f0104e2f:	75 05                	jne    f0104e36 <strtol+0x39>
		s++;
f0104e31:	ff 45 08             	incl   0x8(%ebp)
f0104e34:	eb 13                	jmp    f0104e49 <strtol+0x4c>
	else if (*s == '-')
f0104e36:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e39:	8a 00                	mov    (%eax),%al
f0104e3b:	3c 2d                	cmp    $0x2d,%al
f0104e3d:	75 0a                	jne    f0104e49 <strtol+0x4c>
		s++, neg = 1;
f0104e3f:	ff 45 08             	incl   0x8(%ebp)
f0104e42:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e49:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104e4d:	74 06                	je     f0104e55 <strtol+0x58>
f0104e4f:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0104e53:	75 20                	jne    f0104e75 <strtol+0x78>
f0104e55:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e58:	8a 00                	mov    (%eax),%al
f0104e5a:	3c 30                	cmp    $0x30,%al
f0104e5c:	75 17                	jne    f0104e75 <strtol+0x78>
f0104e5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e61:	40                   	inc    %eax
f0104e62:	8a 00                	mov    (%eax),%al
f0104e64:	3c 78                	cmp    $0x78,%al
f0104e66:	75 0d                	jne    f0104e75 <strtol+0x78>
		s += 2, base = 16;
f0104e68:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0104e6c:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0104e73:	eb 28                	jmp    f0104e9d <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
f0104e75:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104e79:	75 15                	jne    f0104e90 <strtol+0x93>
f0104e7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e7e:	8a 00                	mov    (%eax),%al
f0104e80:	3c 30                	cmp    $0x30,%al
f0104e82:	75 0c                	jne    f0104e90 <strtol+0x93>
		s++, base = 8;
f0104e84:	ff 45 08             	incl   0x8(%ebp)
f0104e87:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0104e8e:	eb 0d                	jmp    f0104e9d <strtol+0xa0>
	else if (base == 0)
f0104e90:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104e94:	75 07                	jne    f0104e9d <strtol+0xa0>
		base = 10;
f0104e96:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ea0:	8a 00                	mov    (%eax),%al
f0104ea2:	3c 2f                	cmp    $0x2f,%al
f0104ea4:	7e 19                	jle    f0104ebf <strtol+0xc2>
f0104ea6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ea9:	8a 00                	mov    (%eax),%al
f0104eab:	3c 39                	cmp    $0x39,%al
f0104ead:	7f 10                	jg     f0104ebf <strtol+0xc2>
			dig = *s - '0';
f0104eaf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eb2:	8a 00                	mov    (%eax),%al
f0104eb4:	0f be c0             	movsbl %al,%eax
f0104eb7:	83 e8 30             	sub    $0x30,%eax
f0104eba:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104ebd:	eb 42                	jmp    f0104f01 <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
f0104ebf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ec2:	8a 00                	mov    (%eax),%al
f0104ec4:	3c 60                	cmp    $0x60,%al
f0104ec6:	7e 19                	jle    f0104ee1 <strtol+0xe4>
f0104ec8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ecb:	8a 00                	mov    (%eax),%al
f0104ecd:	3c 7a                	cmp    $0x7a,%al
f0104ecf:	7f 10                	jg     f0104ee1 <strtol+0xe4>
			dig = *s - 'a' + 10;
f0104ed1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ed4:	8a 00                	mov    (%eax),%al
f0104ed6:	0f be c0             	movsbl %al,%eax
f0104ed9:	83 e8 57             	sub    $0x57,%eax
f0104edc:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104edf:	eb 20                	jmp    f0104f01 <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
f0104ee1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ee4:	8a 00                	mov    (%eax),%al
f0104ee6:	3c 40                	cmp    $0x40,%al
f0104ee8:	7e 39                	jle    f0104f23 <strtol+0x126>
f0104eea:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eed:	8a 00                	mov    (%eax),%al
f0104eef:	3c 5a                	cmp    $0x5a,%al
f0104ef1:	7f 30                	jg     f0104f23 <strtol+0x126>
			dig = *s - 'A' + 10;
f0104ef3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ef6:	8a 00                	mov    (%eax),%al
f0104ef8:	0f be c0             	movsbl %al,%eax
f0104efb:	83 e8 37             	sub    $0x37,%eax
f0104efe:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0104f01:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f04:	3b 45 10             	cmp    0x10(%ebp),%eax
f0104f07:	7d 19                	jge    f0104f22 <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
f0104f09:	ff 45 08             	incl   0x8(%ebp)
f0104f0c:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104f0f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104f13:	89 c2                	mov    %eax,%edx
f0104f15:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f18:	01 d0                	add    %edx,%eax
f0104f1a:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0104f1d:	e9 7b ff ff ff       	jmp    f0104e9d <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f0104f22:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104f23:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104f27:	74 08                	je     f0104f31 <strtol+0x134>
		*endptr = (char *) s;
f0104f29:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f2c:	8b 55 08             	mov    0x8(%ebp),%edx
f0104f2f:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0104f31:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0104f35:	74 07                	je     f0104f3e <strtol+0x141>
f0104f37:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104f3a:	f7 d8                	neg    %eax
f0104f3c:	eb 03                	jmp    f0104f41 <strtol+0x144>
f0104f3e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104f41:	c9                   	leave  
f0104f42:	c3                   	ret    

f0104f43 <strsplit>:

int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
f0104f43:	55                   	push   %ebp
f0104f44:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
f0104f46:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f49:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
f0104f4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f52:	8b 00                	mov    (%eax),%eax
f0104f54:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104f5b:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f5e:	01 d0                	add    %edx,%eax
f0104f60:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0104f66:	eb 0c                	jmp    f0104f74 <strsplit+0x31>
			*string++ = 0;
f0104f68:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f6b:	8d 50 01             	lea    0x1(%eax),%edx
f0104f6e:	89 55 08             	mov    %edx,0x8(%ebp)
f0104f71:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0104f74:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f77:	8a 00                	mov    (%eax),%al
f0104f79:	84 c0                	test   %al,%al
f0104f7b:	74 18                	je     f0104f95 <strsplit+0x52>
f0104f7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f80:	8a 00                	mov    (%eax),%al
f0104f82:	0f be c0             	movsbl %al,%eax
f0104f85:	50                   	push   %eax
f0104f86:	ff 75 0c             	pushl  0xc(%ebp)
f0104f89:	e8 a1 fc ff ff       	call   f0104c2f <strchr>
f0104f8e:	83 c4 08             	add    $0x8,%esp
f0104f91:	85 c0                	test   %eax,%eax
f0104f93:	75 d3                	jne    f0104f68 <strsplit+0x25>
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
f0104f95:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f98:	8a 00                	mov    (%eax),%al
f0104f9a:	84 c0                	test   %al,%al
f0104f9c:	74 5a                	je     f0104ff8 <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1) 
f0104f9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fa1:	8b 00                	mov    (%eax),%eax
f0104fa3:	83 f8 0f             	cmp    $0xf,%eax
f0104fa6:	75 07                	jne    f0104faf <strsplit+0x6c>
		{
			return 0;
f0104fa8:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fad:	eb 66                	jmp    f0105015 <strsplit+0xd2>
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
f0104faf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fb2:	8b 00                	mov    (%eax),%eax
f0104fb4:	8d 48 01             	lea    0x1(%eax),%ecx
f0104fb7:	8b 55 14             	mov    0x14(%ebp),%edx
f0104fba:	89 0a                	mov    %ecx,(%edx)
f0104fbc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104fc3:	8b 45 10             	mov    0x10(%ebp),%eax
f0104fc6:	01 c2                	add    %eax,%edx
f0104fc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fcb:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
f0104fcd:	eb 03                	jmp    f0104fd2 <strsplit+0x8f>
			string++;
f0104fcf:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
f0104fd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fd5:	8a 00                	mov    (%eax),%al
f0104fd7:	84 c0                	test   %al,%al
f0104fd9:	74 8b                	je     f0104f66 <strsplit+0x23>
f0104fdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fde:	8a 00                	mov    (%eax),%al
f0104fe0:	0f be c0             	movsbl %al,%eax
f0104fe3:	50                   	push   %eax
f0104fe4:	ff 75 0c             	pushl  0xc(%ebp)
f0104fe7:	e8 43 fc ff ff       	call   f0104c2f <strchr>
f0104fec:	83 c4 08             	add    $0x8,%esp
f0104fef:	85 c0                	test   %eax,%eax
f0104ff1:	74 dc                	je     f0104fcf <strsplit+0x8c>
			string++;
	}
f0104ff3:	e9 6e ff ff ff       	jmp    f0104f66 <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
f0104ff8:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
f0104ff9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ffc:	8b 00                	mov    (%eax),%eax
f0104ffe:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0105005:	8b 45 10             	mov    0x10(%ebp),%eax
f0105008:	01 d0                	add    %edx,%eax
f010500a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
f0105010:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0105015:	c9                   	leave  
f0105016:	c3                   	ret    
f0105017:	90                   	nop

f0105018 <__udivdi3>:
f0105018:	55                   	push   %ebp
f0105019:	57                   	push   %edi
f010501a:	56                   	push   %esi
f010501b:	53                   	push   %ebx
f010501c:	83 ec 1c             	sub    $0x1c,%esp
f010501f:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105023:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105027:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010502b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010502f:	89 ca                	mov    %ecx,%edx
f0105031:	89 f8                	mov    %edi,%eax
f0105033:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105037:	85 f6                	test   %esi,%esi
f0105039:	75 2d                	jne    f0105068 <__udivdi3+0x50>
f010503b:	39 cf                	cmp    %ecx,%edi
f010503d:	77 65                	ja     f01050a4 <__udivdi3+0x8c>
f010503f:	89 fd                	mov    %edi,%ebp
f0105041:	85 ff                	test   %edi,%edi
f0105043:	75 0b                	jne    f0105050 <__udivdi3+0x38>
f0105045:	b8 01 00 00 00       	mov    $0x1,%eax
f010504a:	31 d2                	xor    %edx,%edx
f010504c:	f7 f7                	div    %edi
f010504e:	89 c5                	mov    %eax,%ebp
f0105050:	31 d2                	xor    %edx,%edx
f0105052:	89 c8                	mov    %ecx,%eax
f0105054:	f7 f5                	div    %ebp
f0105056:	89 c1                	mov    %eax,%ecx
f0105058:	89 d8                	mov    %ebx,%eax
f010505a:	f7 f5                	div    %ebp
f010505c:	89 cf                	mov    %ecx,%edi
f010505e:	89 fa                	mov    %edi,%edx
f0105060:	83 c4 1c             	add    $0x1c,%esp
f0105063:	5b                   	pop    %ebx
f0105064:	5e                   	pop    %esi
f0105065:	5f                   	pop    %edi
f0105066:	5d                   	pop    %ebp
f0105067:	c3                   	ret    
f0105068:	39 ce                	cmp    %ecx,%esi
f010506a:	77 28                	ja     f0105094 <__udivdi3+0x7c>
f010506c:	0f bd fe             	bsr    %esi,%edi
f010506f:	83 f7 1f             	xor    $0x1f,%edi
f0105072:	75 40                	jne    f01050b4 <__udivdi3+0x9c>
f0105074:	39 ce                	cmp    %ecx,%esi
f0105076:	72 0a                	jb     f0105082 <__udivdi3+0x6a>
f0105078:	3b 44 24 08          	cmp    0x8(%esp),%eax
f010507c:	0f 87 9e 00 00 00    	ja     f0105120 <__udivdi3+0x108>
f0105082:	b8 01 00 00 00       	mov    $0x1,%eax
f0105087:	89 fa                	mov    %edi,%edx
f0105089:	83 c4 1c             	add    $0x1c,%esp
f010508c:	5b                   	pop    %ebx
f010508d:	5e                   	pop    %esi
f010508e:	5f                   	pop    %edi
f010508f:	5d                   	pop    %ebp
f0105090:	c3                   	ret    
f0105091:	8d 76 00             	lea    0x0(%esi),%esi
f0105094:	31 ff                	xor    %edi,%edi
f0105096:	31 c0                	xor    %eax,%eax
f0105098:	89 fa                	mov    %edi,%edx
f010509a:	83 c4 1c             	add    $0x1c,%esp
f010509d:	5b                   	pop    %ebx
f010509e:	5e                   	pop    %esi
f010509f:	5f                   	pop    %edi
f01050a0:	5d                   	pop    %ebp
f01050a1:	c3                   	ret    
f01050a2:	66 90                	xchg   %ax,%ax
f01050a4:	89 d8                	mov    %ebx,%eax
f01050a6:	f7 f7                	div    %edi
f01050a8:	31 ff                	xor    %edi,%edi
f01050aa:	89 fa                	mov    %edi,%edx
f01050ac:	83 c4 1c             	add    $0x1c,%esp
f01050af:	5b                   	pop    %ebx
f01050b0:	5e                   	pop    %esi
f01050b1:	5f                   	pop    %edi
f01050b2:	5d                   	pop    %ebp
f01050b3:	c3                   	ret    
f01050b4:	bd 20 00 00 00       	mov    $0x20,%ebp
f01050b9:	89 eb                	mov    %ebp,%ebx
f01050bb:	29 fb                	sub    %edi,%ebx
f01050bd:	89 f9                	mov    %edi,%ecx
f01050bf:	d3 e6                	shl    %cl,%esi
f01050c1:	89 c5                	mov    %eax,%ebp
f01050c3:	88 d9                	mov    %bl,%cl
f01050c5:	d3 ed                	shr    %cl,%ebp
f01050c7:	89 e9                	mov    %ebp,%ecx
f01050c9:	09 f1                	or     %esi,%ecx
f01050cb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01050cf:	89 f9                	mov    %edi,%ecx
f01050d1:	d3 e0                	shl    %cl,%eax
f01050d3:	89 c5                	mov    %eax,%ebp
f01050d5:	89 d6                	mov    %edx,%esi
f01050d7:	88 d9                	mov    %bl,%cl
f01050d9:	d3 ee                	shr    %cl,%esi
f01050db:	89 f9                	mov    %edi,%ecx
f01050dd:	d3 e2                	shl    %cl,%edx
f01050df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01050e3:	88 d9                	mov    %bl,%cl
f01050e5:	d3 e8                	shr    %cl,%eax
f01050e7:	09 c2                	or     %eax,%edx
f01050e9:	89 d0                	mov    %edx,%eax
f01050eb:	89 f2                	mov    %esi,%edx
f01050ed:	f7 74 24 0c          	divl   0xc(%esp)
f01050f1:	89 d6                	mov    %edx,%esi
f01050f3:	89 c3                	mov    %eax,%ebx
f01050f5:	f7 e5                	mul    %ebp
f01050f7:	39 d6                	cmp    %edx,%esi
f01050f9:	72 19                	jb     f0105114 <__udivdi3+0xfc>
f01050fb:	74 0b                	je     f0105108 <__udivdi3+0xf0>
f01050fd:	89 d8                	mov    %ebx,%eax
f01050ff:	31 ff                	xor    %edi,%edi
f0105101:	e9 58 ff ff ff       	jmp    f010505e <__udivdi3+0x46>
f0105106:	66 90                	xchg   %ax,%ax
f0105108:	8b 54 24 08          	mov    0x8(%esp),%edx
f010510c:	89 f9                	mov    %edi,%ecx
f010510e:	d3 e2                	shl    %cl,%edx
f0105110:	39 c2                	cmp    %eax,%edx
f0105112:	73 e9                	jae    f01050fd <__udivdi3+0xe5>
f0105114:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0105117:	31 ff                	xor    %edi,%edi
f0105119:	e9 40 ff ff ff       	jmp    f010505e <__udivdi3+0x46>
f010511e:	66 90                	xchg   %ax,%ax
f0105120:	31 c0                	xor    %eax,%eax
f0105122:	e9 37 ff ff ff       	jmp    f010505e <__udivdi3+0x46>
f0105127:	90                   	nop

f0105128 <__umoddi3>:
f0105128:	55                   	push   %ebp
f0105129:	57                   	push   %edi
f010512a:	56                   	push   %esi
f010512b:	53                   	push   %ebx
f010512c:	83 ec 1c             	sub    $0x1c,%esp
f010512f:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105133:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105137:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010513b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010513f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105143:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105147:	89 f3                	mov    %esi,%ebx
f0105149:	89 fa                	mov    %edi,%edx
f010514b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010514f:	89 34 24             	mov    %esi,(%esp)
f0105152:	85 c0                	test   %eax,%eax
f0105154:	75 1a                	jne    f0105170 <__umoddi3+0x48>
f0105156:	39 f7                	cmp    %esi,%edi
f0105158:	0f 86 a2 00 00 00    	jbe    f0105200 <__umoddi3+0xd8>
f010515e:	89 c8                	mov    %ecx,%eax
f0105160:	89 f2                	mov    %esi,%edx
f0105162:	f7 f7                	div    %edi
f0105164:	89 d0                	mov    %edx,%eax
f0105166:	31 d2                	xor    %edx,%edx
f0105168:	83 c4 1c             	add    $0x1c,%esp
f010516b:	5b                   	pop    %ebx
f010516c:	5e                   	pop    %esi
f010516d:	5f                   	pop    %edi
f010516e:	5d                   	pop    %ebp
f010516f:	c3                   	ret    
f0105170:	39 f0                	cmp    %esi,%eax
f0105172:	0f 87 ac 00 00 00    	ja     f0105224 <__umoddi3+0xfc>
f0105178:	0f bd e8             	bsr    %eax,%ebp
f010517b:	83 f5 1f             	xor    $0x1f,%ebp
f010517e:	0f 84 ac 00 00 00    	je     f0105230 <__umoddi3+0x108>
f0105184:	bf 20 00 00 00       	mov    $0x20,%edi
f0105189:	29 ef                	sub    %ebp,%edi
f010518b:	89 fe                	mov    %edi,%esi
f010518d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105191:	89 e9                	mov    %ebp,%ecx
f0105193:	d3 e0                	shl    %cl,%eax
f0105195:	89 d7                	mov    %edx,%edi
f0105197:	89 f1                	mov    %esi,%ecx
f0105199:	d3 ef                	shr    %cl,%edi
f010519b:	09 c7                	or     %eax,%edi
f010519d:	89 e9                	mov    %ebp,%ecx
f010519f:	d3 e2                	shl    %cl,%edx
f01051a1:	89 14 24             	mov    %edx,(%esp)
f01051a4:	89 d8                	mov    %ebx,%eax
f01051a6:	d3 e0                	shl    %cl,%eax
f01051a8:	89 c2                	mov    %eax,%edx
f01051aa:	8b 44 24 08          	mov    0x8(%esp),%eax
f01051ae:	d3 e0                	shl    %cl,%eax
f01051b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051b4:	8b 44 24 08          	mov    0x8(%esp),%eax
f01051b8:	89 f1                	mov    %esi,%ecx
f01051ba:	d3 e8                	shr    %cl,%eax
f01051bc:	09 d0                	or     %edx,%eax
f01051be:	d3 eb                	shr    %cl,%ebx
f01051c0:	89 da                	mov    %ebx,%edx
f01051c2:	f7 f7                	div    %edi
f01051c4:	89 d3                	mov    %edx,%ebx
f01051c6:	f7 24 24             	mull   (%esp)
f01051c9:	89 c6                	mov    %eax,%esi
f01051cb:	89 d1                	mov    %edx,%ecx
f01051cd:	39 d3                	cmp    %edx,%ebx
f01051cf:	0f 82 87 00 00 00    	jb     f010525c <__umoddi3+0x134>
f01051d5:	0f 84 91 00 00 00    	je     f010526c <__umoddi3+0x144>
f01051db:	8b 54 24 04          	mov    0x4(%esp),%edx
f01051df:	29 f2                	sub    %esi,%edx
f01051e1:	19 cb                	sbb    %ecx,%ebx
f01051e3:	89 d8                	mov    %ebx,%eax
f01051e5:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f01051e9:	d3 e0                	shl    %cl,%eax
f01051eb:	89 e9                	mov    %ebp,%ecx
f01051ed:	d3 ea                	shr    %cl,%edx
f01051ef:	09 d0                	or     %edx,%eax
f01051f1:	89 e9                	mov    %ebp,%ecx
f01051f3:	d3 eb                	shr    %cl,%ebx
f01051f5:	89 da                	mov    %ebx,%edx
f01051f7:	83 c4 1c             	add    $0x1c,%esp
f01051fa:	5b                   	pop    %ebx
f01051fb:	5e                   	pop    %esi
f01051fc:	5f                   	pop    %edi
f01051fd:	5d                   	pop    %ebp
f01051fe:	c3                   	ret    
f01051ff:	90                   	nop
f0105200:	89 fd                	mov    %edi,%ebp
f0105202:	85 ff                	test   %edi,%edi
f0105204:	75 0b                	jne    f0105211 <__umoddi3+0xe9>
f0105206:	b8 01 00 00 00       	mov    $0x1,%eax
f010520b:	31 d2                	xor    %edx,%edx
f010520d:	f7 f7                	div    %edi
f010520f:	89 c5                	mov    %eax,%ebp
f0105211:	89 f0                	mov    %esi,%eax
f0105213:	31 d2                	xor    %edx,%edx
f0105215:	f7 f5                	div    %ebp
f0105217:	89 c8                	mov    %ecx,%eax
f0105219:	f7 f5                	div    %ebp
f010521b:	89 d0                	mov    %edx,%eax
f010521d:	e9 44 ff ff ff       	jmp    f0105166 <__umoddi3+0x3e>
f0105222:	66 90                	xchg   %ax,%ax
f0105224:	89 c8                	mov    %ecx,%eax
f0105226:	89 f2                	mov    %esi,%edx
f0105228:	83 c4 1c             	add    $0x1c,%esp
f010522b:	5b                   	pop    %ebx
f010522c:	5e                   	pop    %esi
f010522d:	5f                   	pop    %edi
f010522e:	5d                   	pop    %ebp
f010522f:	c3                   	ret    
f0105230:	3b 04 24             	cmp    (%esp),%eax
f0105233:	72 06                	jb     f010523b <__umoddi3+0x113>
f0105235:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0105239:	77 0f                	ja     f010524a <__umoddi3+0x122>
f010523b:	89 f2                	mov    %esi,%edx
f010523d:	29 f9                	sub    %edi,%ecx
f010523f:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0105243:	89 14 24             	mov    %edx,(%esp)
f0105246:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010524a:	8b 44 24 04          	mov    0x4(%esp),%eax
f010524e:	8b 14 24             	mov    (%esp),%edx
f0105251:	83 c4 1c             	add    $0x1c,%esp
f0105254:	5b                   	pop    %ebx
f0105255:	5e                   	pop    %esi
f0105256:	5f                   	pop    %edi
f0105257:	5d                   	pop    %ebp
f0105258:	c3                   	ret    
f0105259:	8d 76 00             	lea    0x0(%esi),%esi
f010525c:	2b 04 24             	sub    (%esp),%eax
f010525f:	19 fa                	sbb    %edi,%edx
f0105261:	89 d1                	mov    %edx,%ecx
f0105263:	89 c6                	mov    %eax,%esi
f0105265:	e9 71 ff ff ff       	jmp    f01051db <__umoddi3+0xb3>
f010526a:	66 90                	xchg   %ax,%ax
f010526c:	39 44 24 04          	cmp    %eax,0x4(%esp)
f0105270:	72 ea                	jb     f010525c <__umoddi3+0x134>
f0105272:	89 d9                	mov    %ebx,%ecx
f0105274:	e9 62 ff ff ff       	jmp    f01051db <__umoddi3+0xb3>
