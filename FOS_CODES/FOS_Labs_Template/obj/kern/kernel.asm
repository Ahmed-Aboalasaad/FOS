
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
f010005e:	e8 5c 4d 00 00       	call   f0104dbf <memset>
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
f0100070:	e8 dd 14 00 00       	call   f0101552 <detect_memory>
	initialize_kernel_VM();
f0100075:	e8 63 23 00 00       	call   f01023dd <initialize_kernel_VM>
	initialize_paging();
f010007a:	e8 22 27 00 00       	call   f01027a1 <initialize_paging>
	page_check();
f010007f:	e8 9a 18 00 00       	call   f010191e <page_check>

	
	// Lab 3 user environment initialization functions
	env_init();
f0100084:	e8 0b 2f 00 00       	call   f0102f94 <env_init>
	idt_init();
f0100089:	e8 9f 36 00 00       	call   f010372d <idt_init>

	
	// start the kernel command prompt.
	while (1==1)
	{
		cprintf("\nWelcome to the FOS kernel command prompt!\n");
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	68 c0 53 10 f0       	push   $0xf01053c0
f0100096:	e8 41 36 00 00       	call   f01036dc <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
		cprintf("Type 'help' for a list of commands.\n");	
f010009e:	83 ec 0c             	sub    $0xc,%esp
f01000a1:	68 ec 53 10 f0       	push   $0xf01053ec
f01000a6:	e8 31 36 00 00       	call   f01036dc <cprintf>
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
f01000be:	68 11 54 10 f0       	push   $0xf0105411
f01000c3:	e8 14 36 00 00       	call   f01036dc <cprintf>
f01000c8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f01000cb:	83 ec 0c             	sub    $0xc,%esp
f01000ce:	68 18 54 10 f0       	push   $0xf0105418
f01000d3:	e8 04 36 00 00       	call   f01036dc <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	68 60 54 10 f0       	push   $0xf0105460
f01000e3:	e8 f4 35 00 00       	call   f01036dc <cprintf>
f01000e8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                   !! FCIS says HELLO !!                     !!\n");
f01000eb:	83 ec 0c             	sub    $0xc,%esp
f01000ee:	68 a8 54 10 f0       	push   $0xf01054a8
f01000f3:	e8 e4 35 00 00       	call   f01036dc <cprintf>
f01000f8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000fb:	83 ec 0c             	sub    $0xc,%esp
f01000fe:	68 60 54 10 f0       	push   $0xf0105460
f0100103:	e8 d4 35 00 00       	call   f01036dc <cprintf>
f0100108:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	68 18 54 10 f0       	push   $0xf0105418
f0100113:	e8 c4 35 00 00       	call   f01036dc <cprintf>
f0100118:	83 c4 10             	add    $0x10,%esp
	cprintf("\n\n\n\n");	
f010011b:	83 ec 0c             	sub    $0xc,%esp
f010011e:	68 ed 54 10 f0       	push   $0xf01054ed
f0100123:	e8 b4 35 00 00       	call   f01036dc <cprintf>
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
f0100159:	68 f2 54 10 f0       	push   $0xf01054f2
f010015e:	e8 79 35 00 00       	call   f01036dc <cprintf>
f0100163:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f0100166:	8b 45 10             	mov    0x10(%ebp),%eax
f0100169:	83 ec 08             	sub    $0x8,%esp
f010016c:	ff 75 f4             	pushl  -0xc(%ebp)
f010016f:	50                   	push   %eax
f0100170:	e8 3e 35 00 00       	call   f01036b3 <vcprintf>
f0100175:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f0100178:	83 ec 0c             	sub    $0xc,%esp
f010017b:	68 0a 55 10 f0       	push   $0xf010550a
f0100180:	e8 57 35 00 00       	call   f01036dc <cprintf>
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
f01001a7:	68 0c 55 10 f0       	push   $0xf010550c
f01001ac:	e8 2b 35 00 00       	call   f01036dc <cprintf>
f01001b1:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01001b7:	83 ec 08             	sub    $0x8,%esp
f01001ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01001bd:	50                   	push   %eax
f01001be:	e8 f0 34 00 00       	call   f01036b3 <vcprintf>
f01001c3:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001c6:	83 ec 0c             	sub    $0xc,%esp
f01001c9:	68 0a 55 10 f0       	push   $0xf010550a
f01001ce:	e8 09 35 00 00       	call   f01036dc <cprintf>
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
f01005d1:	e8 19 48 00 00       	call   f0104def <memcpy>
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
f01007d8:	68 26 55 10 f0       	push   $0xf0105526
f01007dd:	e8 fa 2e 00 00       	call   f01036dc <cprintf>
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
f0100907:	68 32 55 10 f0       	push   $0xf0105532
f010090c:	e8 cb 2d 00 00       	call   f01036dc <cprintf>
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
f0100964:	68 50 5a 10 f0       	push   $0xf0105a50
f0100969:	e8 65 41 00 00       	call   f0104ad3 <readline>
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
f010099b:	68 56 5a 10 f0       	push   $0xf0105a56
f01009a0:	ff 75 08             	pushl  0x8(%ebp)
f01009a3:	e8 cf 46 00 00       	call   f0105077 <strsplit>
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
f01009e7:	e8 f1 42 00 00       	call   f0104cdd <strcmp>
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
f0100a3f:	68 5b 5a 10 f0       	push   $0xf0105a5b
f0100a44:	e8 93 2c 00 00       	call   f01036dc <cprintf>
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
f0100a8d:	68 71 5a 10 f0       	push   $0xf0105a71
f0100a92:	e8 45 2c 00 00       	call   f01036dc <cprintf>
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
f0100aa8:	68 7a 5a 10 f0       	push   $0xf0105a7a
f0100aad:	e8 2a 2c 00 00       	call   f01036dc <cprintf>
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
f0100ac5:	68 8f 5a 10 f0       	push   $0xf0105a8f
f0100aca:	e8 0d 2c 00 00       	call   f01036dc <cprintf>
f0100acf:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
f0100ad2:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100ad7:	83 ec 04             	sub    $0x4,%esp
f0100ada:	50                   	push   %eax
f0100adb:	68 0c 00 10 f0       	push   $0xf010000c
f0100ae0:	68 a8 5a 10 f0       	push   $0xf0105aa8
f0100ae5:	e8 f2 2b 00 00       	call   f01036dc <cprintf>
f0100aea:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
f0100aed:	b8 ad 53 10 00       	mov    $0x1053ad,%eax
f0100af2:	83 ec 04             	sub    $0x4,%esp
f0100af5:	50                   	push   %eax
f0100af6:	68 ad 53 10 f0       	push   $0xf01053ad
f0100afb:	68 e4 5a 10 f0       	push   $0xf0105ae4
f0100b00:	e8 d7 2b 00 00       	call   f01036dc <cprintf>
f0100b05:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
f0100b08:	b8 f2 ec 14 00       	mov    $0x14ecf2,%eax
f0100b0d:	83 ec 04             	sub    $0x4,%esp
f0100b10:	50                   	push   %eax
f0100b11:	68 f2 ec 14 f0       	push   $0xf014ecf2
f0100b16:	68 20 5b 10 f0       	push   $0xf0105b20
f0100b1b:	e8 bc 2b 00 00       	call   f01036dc <cprintf>
f0100b20:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
f0100b23:	b8 ec f7 14 00       	mov    $0x14f7ec,%eax
f0100b28:	83 ec 04             	sub    $0x4,%esp
f0100b2b:	50                   	push   %eax
f0100b2c:	68 ec f7 14 f0       	push   $0xf014f7ec
f0100b31:	68 68 5b 10 f0       	push   $0xf0105b68
f0100b36:	e8 a1 2b 00 00       	call   f01036dc <cprintf>
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
f0100b62:	68 a4 5b 10 f0       	push   $0xf0105ba4
f0100b67:	e8 70 2b 00 00       	call   f01036dc <cprintf>
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
f0100b8c:	e8 a0 43 00 00       	call   f0104f31 <strtol>
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
f0100bac:	68 cf 5b 10 f0       	push   $0xf0105bcf
f0100bb1:	e8 26 2b 00 00       	call   f01036dc <cprintf>
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
f0100bd6:	e8 56 43 00 00       	call   f0104f31 <strtol>
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
f0100c05:	e8 e6 21 00 00       	call   f0102df0 <calculate_free_frames>
f0100c0a:	83 ec 08             	sub    $0x8,%esp
f0100c0d:	50                   	push   %eax
f0100c0e:	68 e9 5b 10 f0       	push   $0xf0105be9
f0100c13:	e8 c4 2a 00 00       	call   f01036dc <cprintf>
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
f0100c2b:	68 fc 5b 10 f0       	push   $0xf0105bfc
f0100c30:	e8 a7 2a 00 00       	call   f01036dc <cprintf>
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
f0100c4e:	68 1c 5c 10 f0       	push   $0xf0105c1c
f0100c53:	e8 84 2a 00 00       	call   f01036dc <cprintf>
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
f0100c72:	e8 ba 42 00 00       	call   f0104f31 <strtol>
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
f0100c8d:	e8 9f 42 00 00       	call   f0104f31 <strtol>
f0100c92:	83 c4 10             	add    $0x10,%esp
f0100c95:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("%d + %d = %d\n", num1, num2, num1 + num2);
f0100c98:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c9e:	01 d0                	add    %edx,%eax
f0100ca0:	50                   	push   %eax
f0100ca1:	ff 75 f0             	pushl  -0x10(%ebp)
f0100ca4:	ff 75 f4             	pushl  -0xc(%ebp)
f0100ca7:	68 32 5c 10 f0       	push   $0xf0105c32
f0100cac:	e8 2b 2a 00 00       	call   f01036dc <cprintf>
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
f0100cca:	68 40 5c 10 f0       	push   $0xf0105c40
f0100ccf:	e8 08 2a 00 00       	call   f01036dc <cprintf>
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
f0100d13:	68 4f 5c 10 f0       	push   $0xf0105c4f
f0100d18:	e8 bf 29 00 00       	call   f01036dc <cprintf>
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
f0100d39:	e8 93 3e 00 00       	call   f0104bd1 <strlen>
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
f0100d56:	e8 d6 41 00 00       	call   f0104f31 <strtol>
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
f0100d73:	68 6d 5c 10 f0       	push   $0xf0105c6d
f0100d78:	e8 5f 29 00 00       	call   f01036dc <cprintf>
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
f0100db5:	68 76 5c 10 f0       	push   $0xf0105c76
f0100dba:	e8 1d 29 00 00       	call   f01036dc <cprintf>
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
f0100dec:	e8 40 41 00 00       	call   f0104f31 <strtol>
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
f0100e0d:	e8 1f 41 00 00       	call   f0104f31 <strtol>
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
f0100e30:	68 80 5c 10 f0       	push   $0xf0105c80
f0100e35:	e8 a2 28 00 00       	call   f01036dc <cprintf>
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
f0100e55:	83 ec 18             	sub    $0x18,%esp
	if (argc != 2)
f0100e58:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100e5c:	74 1a                	je     f0100e78 <command_createintarray+0x26>
	{
		cprintf("Usage: create_int_array <array size>\n");
f0100e5e:	83 ec 0c             	sub    $0xc,%esp
f0100e61:	68 90 5c 10 f0       	push   $0xf0105c90
f0100e66:	e8 71 28 00 00       	call   f01036dc <cprintf>
f0100e6b:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100e6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e73:	e9 93 00 00 00       	jmp    f0100f0b <command_createintarray+0xb9>
	}
	int arrLen = strtol(argv[1], NULL, 10);
f0100e78:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e7b:	83 c0 04             	add    $0x4,%eax
f0100e7e:	8b 00                	mov    (%eax),%eax
f0100e80:	83 ec 04             	sub    $0x4,%esp
f0100e83:	6a 0a                	push   $0xa
f0100e85:	6a 00                	push   $0x0
f0100e87:	50                   	push   %eax
f0100e88:	e8 a4 40 00 00       	call   f0104f31 <strtol>
f0100e8d:	83 c4 10             	add    $0x10,%esp
f0100e90:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Write letters starting from 0xF1000000
	unsigned char *ptr = (unsigned char *)0xF1000000;
f0100e93:	c7 45 e8 00 00 00 f1 	movl   $0xf1000000,-0x18(%ebp)
	for (int i = 0; i < arrLen; i++)
f0100e9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100ea1:	eb 13                	jmp    f0100eb6 <command_createintarray+0x64>
		*(ptr + i) = 'A' + i;
f0100ea3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100ea6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ea9:	01 d0                	add    %edx,%eax
f0100eab:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100eae:	83 c2 41             	add    $0x41,%edx
f0100eb1:	88 10                	mov    %dl,(%eax)
	}
	int arrLen = strtol(argv[1], NULL, 10);

	// Write letters starting from 0xF1000000
	unsigned char *ptr = (unsigned char *)0xF1000000;
	for (int i = 0; i < arrLen; i++)
f0100eb3:	ff 45 f4             	incl   -0xc(%ebp)
f0100eb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100eb9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0100ebc:	7c e5                	jl     f0100ea3 <command_createintarray+0x51>
		*(ptr + i) = 'A' + i;

	// Print the array info
	cprintf("\nThe start virtual address of the allocated array is: 0x%x\n", ptr);
f0100ebe:	83 ec 08             	sub    $0x8,%esp
f0100ec1:	ff 75 e8             	pushl  -0x18(%ebp)
f0100ec4:	68 b8 5c 10 f0       	push   $0xf0105cb8
f0100ec9:	e8 0e 28 00 00       	call   f01036dc <cprintf>
f0100ece:	83 c4 10             	add    $0x10,%esp
	for(int i = 0; i < arrLen; i++)
f0100ed1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100ed8:	eb 24                	jmp    f0100efe <command_createintarray+0xac>
		cprintf("Element %d: %c\n", i, *(ptr + i));
f0100eda:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100edd:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ee0:	01 d0                	add    %edx,%eax
f0100ee2:	8a 00                	mov    (%eax),%al
f0100ee4:	0f b6 c0             	movzbl %al,%eax
f0100ee7:	83 ec 04             	sub    $0x4,%esp
f0100eea:	50                   	push   %eax
f0100eeb:	ff 75 f0             	pushl  -0x10(%ebp)
f0100eee:	68 f4 5c 10 f0       	push   $0xf0105cf4
f0100ef3:	e8 e4 27 00 00       	call   f01036dc <cprintf>
f0100ef8:	83 c4 10             	add    $0x10,%esp
	for (int i = 0; i < arrLen; i++)
		*(ptr + i) = 'A' + i;

	// Print the array info
	cprintf("\nThe start virtual address of the allocated array is: 0x%x\n", ptr);
	for(int i = 0; i < arrLen; i++)
f0100efb:	ff 45 f0             	incl   -0x10(%ebp)
f0100efe:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f01:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0100f04:	7c d4                	jl     f0100eda <command_createintarray+0x88>
		cprintf("Element %d: %c\n", i, *(ptr + i));

	return (0);
f0100f06:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f0b:	c9                   	leave  
f0100f0c:	c3                   	ret    

f0100f0d <command_kernel_base_info>:

//===========================================================================
//Lab3.Examples
//=============
int command_kernel_base_info(int number_of_arguments, char **arguments)
{
f0100f0d:	55                   	push   %ebp
f0100f0e:	89 e5                	mov    %esp,%ebp
f0100f10:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "ikb"
	//Comment the following line
	// panic("Function is not implemented yet!");

	uint32 PA;
	uint32 Entry1 = ptr_page_directory[PDX(KERNEL_BASE)];
f0100f13:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0100f18:	8b 80 00 0f 00 00    	mov    0xf00(%eax),%eax
f0100f1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *PT;
	get_page_table(ptr_page_directory, (void *)KERNEL_BASE, 1, &PT);
f0100f21:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0100f26:	8d 55 e8             	lea    -0x18(%ebp),%edx
f0100f29:	52                   	push   %edx
f0100f2a:	6a 01                	push   $0x1
f0100f2c:	68 00 00 00 f0       	push   $0xf0000000
f0100f31:	50                   	push   %eax
f0100f32:	e8 bc 1b 00 00       	call   f0102af3 <get_page_table>
f0100f37:	83 c4 10             	add    $0x10,%esp
	if (!PT) {
f0100f3a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100f3d:	85 c0                	test   %eax,%eax
f0100f3f:	75 17                	jne    f0100f58 <command_kernel_base_info+0x4b>
		cprintf("Error in get_page_table()\n");
f0100f41:	83 ec 0c             	sub    $0xc,%esp
f0100f44:	68 04 5d 10 f0       	push   $0xf0105d04
f0100f49:	e8 8e 27 00 00       	call   f01036dc <cprintf>
f0100f4e:	83 c4 10             	add    $0x10,%esp
		return 1;
f0100f51:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f56:	eb 52                	jmp    f0100faa <command_kernel_base_info+0x9d>
	}
	uint32 entry2 = PT[PTX(KERNEL_BASE)];
f0100f58:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100f5b:	8b 00                	mov    (%eax),%eax
f0100f5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32 frameNum = entry2 >> 12;
f0100f60:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f63:	c1 e8 0c             	shr    $0xc,%eax
f0100f66:	89 45 ec             	mov    %eax,-0x14(%ebp)

	cprintf("Kernel_Base Info:\n");
f0100f69:	83 ec 0c             	sub    $0xc,%esp
f0100f6c:	68 1f 5d 10 f0       	push   $0xf0105d1f
f0100f71:	e8 66 27 00 00       	call   f01036dc <cprintf>
f0100f76:	83 c4 10             	add    $0x10,%esp
	cprintf("\tVirtual Address: 0x%x\n", KERNEL_BASE);
f0100f79:	83 ec 08             	sub    $0x8,%esp
f0100f7c:	68 00 00 00 f0       	push   $0xf0000000
f0100f81:	68 32 5d 10 f0       	push   $0xf0105d32
f0100f86:	e8 51 27 00 00       	call   f01036dc <cprintf>
f0100f8b:	83 c4 10             	add    $0x10,%esp
	cprintf("\tPysical Address: 0x%x\n", frameNum * PAGE_SIZE);
f0100f8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f91:	c1 e0 0c             	shl    $0xc,%eax
f0100f94:	83 ec 08             	sub    $0x8,%esp
f0100f97:	50                   	push   %eax
f0100f98:	68 4a 5d 10 f0       	push   $0xf0105d4a
f0100f9d:	e8 3a 27 00 00       	call   f01036dc <cprintf>
f0100fa2:	83 c4 10             	add    $0x10,%esp
	
	return 0;
f0100fa5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100faa:	c9                   	leave  
f0100fab:	c3                   	ret    

f0100fac <command_del_kernel_base>:

int command_del_kernel_base(int number_of_arguments, char **arguments)
{
f0100fac:	55                   	push   %ebp
f0100fad:	89 e5                	mov    %esp,%ebp
f0100faf:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "dkb"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100fb2:	83 ec 04             	sub    $0x4,%esp
f0100fb5:	68 64 5d 10 f0       	push   $0xf0105d64
f0100fba:	68 74 01 00 00       	push   $0x174
f0100fbf:	68 85 5d 10 f0       	push   $0xf0105d85
f0100fc4:	e8 65 f1 ff ff       	call   f010012e <_panic>

f0100fc9 <command_share_page>:

	return 0;
}

int command_share_page(int number_of_arguments, char **arguments)
{
f0100fc9:	55                   	push   %ebp
f0100fca:	89 e5                	mov    %esp,%ebp
f0100fcc:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB3 Example: fill this function. corresponding command name is "shr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100fcf:	83 ec 04             	sub    $0x4,%esp
f0100fd2:	68 64 5d 10 f0       	push   $0xf0105d64
f0100fd7:	68 7d 01 00 00       	push   $0x17d
f0100fdc:	68 85 5d 10 f0       	push   $0xf0105d85
f0100fe1:	e8 48 f1 ff ff       	call   f010012e <_panic>

f0100fe6 <command_show_mapping>:

//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int argc, char **argv)
{
f0100fe6:	55                   	push   %ebp
f0100fe7:	89 e5                	mov    %esp,%ebp
f0100fe9:	83 ec 28             	sub    $0x28,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 2)
f0100fec:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100ff0:	74 1a                	je     f010100c <command_show_mapping+0x26>
	{
		cprintf("Usage: sm <virtual address>\n");
f0100ff2:	83 ec 0c             	sub    $0xc,%esp
f0100ff5:	68 9b 5d 10 f0       	push   $0xf0105d9b
f0100ffa:	e8 dd 26 00 00       	call   f01036dc <cprintf>
f0100fff:	83 c4 10             	add    $0x10,%esp
		return (0);
f0101002:	b8 00 00 00 00       	mov    $0x0,%eax
f0101007:	e9 f9 00 00 00       	jmp    f0101105 <command_show_mapping+0x11f>
	}
	unsigned int virtualAddress = strtol(argv[1], NULL, 16);
f010100c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010100f:	83 c0 04             	add    $0x4,%eax
f0101012:	8b 00                	mov    (%eax),%eax
f0101014:	83 ec 04             	sub    $0x4,%esp
f0101017:	6a 10                	push   $0x10
f0101019:	6a 00                	push   $0x0
f010101b:	50                   	push   %eax
f010101c:	e8 10 3f 00 00       	call   f0104f31 <strtol>
f0101021:	83 c4 10             	add    $0x10,%esp
f0101024:	89 45 f4             	mov    %eax,-0xc(%ebp)

	cprintf("Directory Index: %d\n", PDX(virtualAddress));
f0101027:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010102a:	c1 e8 16             	shr    $0x16,%eax
f010102d:	83 ec 08             	sub    $0x8,%esp
f0101030:	50                   	push   %eax
f0101031:	68 b8 5d 10 f0       	push   $0xf0105db8
f0101036:	e8 a1 26 00 00       	call   f01036dc <cprintf>
f010103b:	83 c4 10             	add    $0x10,%esp
	cprintf("Page Table Index: %d\n", PTX(virtualAddress));
f010103e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101041:	c1 e8 0c             	shr    $0xc,%eax
f0101044:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	50                   	push   %eax
f010104d:	68 cd 5d 10 f0       	push   $0xf0105dcd
f0101052:	e8 85 26 00 00       	call   f01036dc <cprintf>
f0101057:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int PTE_level1 = ptr_page_directory[PDX(virtualAddress)];
f010105a:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010105f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101062:	c1 ea 16             	shr    $0x16,%edx
f0101065:	c1 e2 02             	shl    $0x2,%edx
f0101068:	01 d0                	add    %edx,%eax
f010106a:	8b 00                	mov    (%eax),%eax
f010106c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned int frame_level1 = PTE_level1 >> 12;
f010106f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101072:	c1 e8 0c             	shr    $0xc,%eax
f0101075:	89 45 ec             	mov    %eax,-0x14(%ebp)
	cprintf("Physical address of the Page Table: %x\n", frame_level1 * PAGE_SIZE);
f0101078:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010107b:	c1 e0 0c             	shl    $0xc,%eax
f010107e:	83 ec 08             	sub    $0x8,%esp
f0101081:	50                   	push   %eax
f0101082:	68 e4 5d 10 f0       	push   $0xf0105de4
f0101087:	e8 50 26 00 00       	call   f01036dc <cprintf>
f010108c:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int *PT_ptr;
	get_page_table(ptr_page_directory, (void *)virtualAddress, 1, &PT_ptr);
f010108f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101092:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101097:	8d 4d dc             	lea    -0x24(%ebp),%ecx
f010109a:	51                   	push   %ecx
f010109b:	6a 01                	push   $0x1
f010109d:	52                   	push   %edx
f010109e:	50                   	push   %eax
f010109f:	e8 4f 1a 00 00       	call   f0102af3 <get_page_table>
f01010a4:	83 c4 10             	add    $0x10,%esp
	unsigned int PTE_level2 = PT_ptr[PTX(virtualAddress)];
f01010a7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010ad:	c1 ea 0c             	shr    $0xc,%edx
f01010b0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01010b6:	c1 e2 02             	shl    $0x2,%edx
f01010b9:	01 d0                	add    %edx,%eax
f01010bb:	8b 00                	mov    (%eax),%eax
f01010bd:	89 45 e8             	mov    %eax,-0x18(%ebp)
	unsigned int frame_level2 = PTE_level2 >> 12;
f01010c0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010c3:	c1 e8 0c             	shr    $0xc,%eax
f01010c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("Frame number of the page itself: %d\n", frame_level2);
f01010c9:	83 ec 08             	sub    $0x8,%esp
f01010cc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01010cf:	68 0c 5e 10 f0       	push   $0xf0105e0c
f01010d4:	e8 03 26 00 00       	call   f01036dc <cprintf>
f01010d9:	83 c4 10             	add    $0x10,%esp
	// ---
	unsigned int usedStatus = (PERM_USED & PTE_level2) == PERM_USED;
f01010dc:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010df:	83 e0 20             	and    $0x20,%eax
f01010e2:	85 c0                	test   %eax,%eax
f01010e4:	0f 95 c0             	setne  %al
f01010e7:	0f b6 c0             	movzbl %al,%eax
f01010ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cprintf("Used status: %d\n", usedStatus);
f01010ed:	83 ec 08             	sub    $0x8,%esp
f01010f0:	ff 75 e0             	pushl  -0x20(%ebp)
f01010f3:	68 31 5e 10 f0       	push   $0xf0105e31
f01010f8:	e8 df 25 00 00       	call   f01036dc <cprintf>
f01010fd:	83 c4 10             	add    $0x10,%esp

	return (0) ;
f0101100:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101105:	c9                   	leave  
f0101106:	c3                   	ret    

f0101107 <command_set_permission>:

int command_set_permission(int argc, char **argv)
{
f0101107:	55                   	push   %ebp
f0101108:	89 e5                	mov    %esp,%ebp
f010110a:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 3) {
f010110d:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0101111:	74 1a                	je     f010112d <command_set_permission+0x26>
		cprintf("Usage: sp <virtual address> <r/w>\n");
f0101113:	83 ec 0c             	sub    $0xc,%esp
f0101116:	68 44 5e 10 f0       	push   $0xf0105e44
f010111b:	e8 bc 25 00 00       	call   f01036dc <cprintf>
f0101120:	83 c4 10             	add    $0x10,%esp
		return (0);
f0101123:	b8 00 00 00 00       	mov    $0x0,%eax
f0101128:	e9 f2 00 00 00       	jmp    f010121f <command_set_permission+0x118>
	}

	uint32 virtualAddress = strtol(argv[1], NULL, 16);
f010112d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101130:	83 c0 04             	add    $0x4,%eax
f0101133:	8b 00                	mov    (%eax),%eax
f0101135:	83 ec 04             	sub    $0x4,%esp
f0101138:	6a 10                	push   $0x10
f010113a:	6a 00                	push   $0x0
f010113c:	50                   	push   %eax
f010113d:	e8 ef 3d 00 00       	call   f0104f31 <strtol>
f0101142:	83 c4 10             	add    $0x10,%esp
f0101145:	89 45 f4             	mov    %eax,-0xc(%ebp)
	char *mode = argv[2];
f0101148:	8b 45 0c             	mov    0xc(%ebp),%eax
f010114b:	8b 40 08             	mov    0x8(%eax),%eax
f010114e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32 *PT;
	if (get_page_table(ptr_page_directory, (void *)virtualAddress, 1, &PT)) {
f0101151:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101154:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101159:	8d 4d e8             	lea    -0x18(%ebp),%ecx
f010115c:	51                   	push   %ecx
f010115d:	6a 01                	push   $0x1
f010115f:	52                   	push   %edx
f0101160:	50                   	push   %eax
f0101161:	e8 8d 19 00 00       	call   f0102af3 <get_page_table>
f0101166:	83 c4 10             	add    $0x10,%esp
f0101169:	85 c0                	test   %eax,%eax
f010116b:	74 1a                	je     f0101187 <command_set_permission+0x80>
		cprintf("Error in get_page_table()\n");
f010116d:	83 ec 0c             	sub    $0xc,%esp
f0101170:	68 04 5d 10 f0       	push   $0xf0105d04
f0101175:	e8 62 25 00 00       	call   f01036dc <cprintf>
f010117a:	83 c4 10             	add    $0x10,%esp
		return (1);
f010117d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101182:	e9 98 00 00 00       	jmp    f010121f <command_set_permission+0x118>
	}
	uint32 entry = PT[PTX(virtualAddress)];
f0101187:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010118a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010118d:	c1 ea 0c             	shr    $0xc,%edx
f0101190:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101196:	c1 e2 02             	shl    $0x2,%edx
f0101199:	01 d0                	add    %edx,%eax
f010119b:	8b 00                	mov    (%eax),%eax
f010119d:	89 45 ec             	mov    %eax,-0x14(%ebp)

	if (strcmp(mode, "w") == 0) // Writable -> Set
f01011a0:	83 ec 08             	sub    $0x8,%esp
f01011a3:	68 67 5e 10 f0       	push   $0xf0105e67
f01011a8:	ff 75 f0             	pushl  -0x10(%ebp)
f01011ab:	e8 2d 3b 00 00       	call   f0104cdd <strcmp>
f01011b0:	83 c4 10             	add    $0x10,%esp
f01011b3:	85 c0                	test   %eax,%eax
f01011b5:	75 1e                	jne    f01011d5 <command_set_permission+0xce>
		PT[PTX(virtualAddress)] = entry | PERM_WRITEABLE;
f01011b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01011ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011bd:	c1 ea 0c             	shr    $0xc,%edx
f01011c0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011c6:	c1 e2 02             	shl    $0x2,%edx
f01011c9:	01 d0                	add    %edx,%eax
f01011cb:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01011ce:	83 ca 02             	or     $0x2,%edx
f01011d1:	89 10                	mov    %edx,(%eax)
f01011d3:	eb 45                	jmp    f010121a <command_set_permission+0x113>
	else if (strcmp(mode, "r") == 0) // Read Only -> Reset
f01011d5:	83 ec 08             	sub    $0x8,%esp
f01011d8:	68 69 5e 10 f0       	push   $0xf0105e69
f01011dd:	ff 75 f0             	pushl  -0x10(%ebp)
f01011e0:	e8 f8 3a 00 00       	call   f0104cdd <strcmp>
f01011e5:	83 c4 10             	add    $0x10,%esp
f01011e8:	85 c0                	test   %eax,%eax
f01011ea:	75 1e                	jne    f010120a <command_set_permission+0x103>
		PT[PTX(virtualAddress)] = entry & ~PERM_WRITEABLE;
f01011ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01011ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011f2:	c1 ea 0c             	shr    $0xc,%edx
f01011f5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011fb:	c1 e2 02             	shl    $0x2,%edx
f01011fe:	01 d0                	add    %edx,%eax
f0101200:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101203:	83 e2 fd             	and    $0xfffffffd,%edx
f0101206:	89 10                	mov    %edx,(%eax)
f0101208:	eb 10                	jmp    f010121a <command_set_permission+0x113>
	else
		cprintf("Usage: sp <virtual address> <r/w>\n");
f010120a:	83 ec 0c             	sub    $0xc,%esp
f010120d:	68 44 5e 10 f0       	push   $0xf0105e44
f0101212:	e8 c5 24 00 00       	call   f01036dc <cprintf>
f0101217:	83 c4 10             	add    $0x10,%esp
	return (0);
f010121a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010121f:	c9                   	leave  
f0101220:	c3                   	ret    

f0101221 <command_share_range>:

int command_share_range(int argc, char **argv)
{
f0101221:	55                   	push   %ebp
f0101222:	89 e5                	mov    %esp,%ebp
f0101224:	83 ec 38             	sub    $0x38,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	//panic("Function is not implemented yet!");

	if (argc != 4) {
f0101227:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f010122b:	74 1a                	je     f0101247 <command_share_range+0x26>
		cprintf("Usage: sr <va1> <va2> <size in KB>\n");
f010122d:	83 ec 0c             	sub    $0xc,%esp
f0101230:	68 6c 5e 10 f0       	push   $0xf0105e6c
f0101235:	e8 a2 24 00 00       	call   f01036dc <cprintf>
f010123a:	83 c4 10             	add    $0x10,%esp
		return (0);
f010123d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101242:	e9 14 01 00 00       	jmp    f010135b <command_share_range+0x13a>
	}

	// Go to the entries in level 2 and set their frame numbers to one of them

	// Read arguments
	uint32 va1 = strtol(argv[1], NULL, 16);
f0101247:	8b 45 0c             	mov    0xc(%ebp),%eax
f010124a:	83 c0 04             	add    $0x4,%eax
f010124d:	8b 00                	mov    (%eax),%eax
f010124f:	83 ec 04             	sub    $0x4,%esp
f0101252:	6a 10                	push   $0x10
f0101254:	6a 00                	push   $0x0
f0101256:	50                   	push   %eax
f0101257:	e8 d5 3c 00 00       	call   f0104f31 <strtol>
f010125c:	83 c4 10             	add    $0x10,%esp
f010125f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32 va2 = strtol(argv[2], NULL, 16);
f0101262:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101265:	83 c0 08             	add    $0x8,%eax
f0101268:	8b 00                	mov    (%eax),%eax
f010126a:	83 ec 04             	sub    $0x4,%esp
f010126d:	6a 10                	push   $0x10
f010126f:	6a 00                	push   $0x0
f0101271:	50                   	push   %eax
f0101272:	e8 ba 3c 00 00       	call   f0104f31 <strtol>
f0101277:	83 c4 10             	add    $0x10,%esp
f010127a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 sizeInKB = strtol(argv[3], NULL, 16);
f010127d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101280:	83 c0 0c             	add    $0xc,%eax
f0101283:	8b 00                	mov    (%eax),%eax
f0101285:	83 ec 04             	sub    $0x4,%esp
f0101288:	6a 10                	push   $0x10
f010128a:	6a 00                	push   $0x0
f010128c:	50                   	push   %eax
f010128d:	e8 9f 3c 00 00       	call   f0104f31 <strtol>
f0101292:	83 c4 10             	add    $0x10,%esp
f0101295:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32 sizeInPages = sizeInKB / PAGE_SIZE;
f0101298:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010129b:	c1 e8 0c             	shr    $0xc,%eax
f010129e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	uint32 *PT1;
	if(get_page_table(ptr_page_directory, (void *)va1, 1, &PT1)) {
f01012a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01012a4:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01012a9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01012ac:	51                   	push   %ecx
f01012ad:	6a 01                	push   $0x1
f01012af:	52                   	push   %edx
f01012b0:	50                   	push   %eax
f01012b1:	e8 3d 18 00 00       	call   f0102af3 <get_page_table>
f01012b6:	83 c4 10             	add    $0x10,%esp
f01012b9:	85 c0                	test   %eax,%eax
f01012bb:	74 1a                	je     f01012d7 <command_share_range+0xb6>
		cprintf("Error in ptr_page_directory()\n");
f01012bd:	83 ec 0c             	sub    $0xc,%esp
f01012c0:	68 90 5e 10 f0       	push   $0xf0105e90
f01012c5:	e8 12 24 00 00       	call   f01036dc <cprintf>
f01012ca:	83 c4 10             	add    $0x10,%esp
		return (0);
f01012cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d2:	e9 84 00 00 00       	jmp    f010135b <command_share_range+0x13a>
	}
	uint32 *ptr1 = PT1 + PTX(va1);
f01012d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01012da:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01012dd:	c1 ea 0c             	shr    $0xc,%edx
f01012e0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01012e6:	c1 e2 02             	shl    $0x2,%edx
f01012e9:	01 d0                	add    %edx,%eax
f01012eb:	89 45 e0             	mov    %eax,-0x20(%ebp)

	uint32 *PT2;
	if(get_page_table(ptr_page_directory, (void *)va2, 1, &PT2)) {
f01012ee:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01012f1:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01012f6:	8d 4d d4             	lea    -0x2c(%ebp),%ecx
f01012f9:	51                   	push   %ecx
f01012fa:	6a 01                	push   $0x1
f01012fc:	52                   	push   %edx
f01012fd:	50                   	push   %eax
f01012fe:	e8 f0 17 00 00       	call   f0102af3 <get_page_table>
f0101303:	83 c4 10             	add    $0x10,%esp
f0101306:	85 c0                	test   %eax,%eax
f0101308:	74 17                	je     f0101321 <command_share_range+0x100>
		cprintf("Error in ptr_page_directory()\n");
f010130a:	83 ec 0c             	sub    $0xc,%esp
f010130d:	68 90 5e 10 f0       	push   $0xf0105e90
f0101312:	e8 c5 23 00 00       	call   f01036dc <cprintf>
f0101317:	83 c4 10             	add    $0x10,%esp
		return (0);
f010131a:	b8 00 00 00 00       	mov    $0x0,%eax
f010131f:	eb 3a                	jmp    f010135b <command_share_range+0x13a>
	}
	uint32 *ptr2 = PT2 + PTX(va2);
f0101321:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101324:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101327:	c1 ea 0c             	shr    $0xc,%edx
f010132a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101330:	c1 e2 02             	shl    $0x2,%edx
f0101333:	01 d0                	add    %edx,%eax
f0101335:	89 45 dc             	mov    %eax,-0x24(%ebp)

	for (uint32 frame1, frame2, i = 0; i < sizeInPages; i++) {
f0101338:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010133f:	eb 0d                	jmp    f010134e <command_share_range+0x12d>
		*ptr2 = *ptr1;
f0101341:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101344:	8b 10                	mov    (%eax),%edx
f0101346:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101349:	89 10                	mov    %edx,(%eax)
		cprintf("Error in ptr_page_directory()\n");
		return (0);
	}
	uint32 *ptr2 = PT2 + PTX(va2);

	for (uint32 frame1, frame2, i = 0; i < sizeInPages; i++) {
f010134b:	ff 45 f4             	incl   -0xc(%ebp)
f010134e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101351:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0101354:	72 eb                	jb     f0101341 <command_share_range+0x120>
		*ptr2 = *ptr1;
	}

	return (0);
f0101356:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010135b:	c9                   	leave  
f010135c:	c3                   	ret    

f010135d <command_nr>:
//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
f010135d:	55                   	push   %ebp
f010135e:	89 e5                	mov    %esp,%ebp
f0101360:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0101363:	83 ec 04             	sub    $0x4,%esp
f0101366:	68 64 5d 10 f0       	push   $0xf0105d64
f010136b:	68 f2 01 00 00       	push   $0x1f2
f0101370:	68 85 5d 10 f0       	push   $0xf0105d85
f0101375:	e8 b4 ed ff ff       	call   f010012e <_panic>

f010137a <command_ap>:
	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
f010137a:	55                   	push   %ebp
f010137b:	89 e5                	mov    %esp,%ebp
f010137d:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "ap"
	//Comment the following line
	//panic("Function is not implemented yet!");

	uint32 va = strtol(arguments[1], NULL, 16);
f0101380:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101383:	83 c0 04             	add    $0x4,%eax
f0101386:	8b 00                	mov    (%eax),%eax
f0101388:	83 ec 04             	sub    $0x4,%esp
f010138b:	6a 10                	push   $0x10
f010138d:	6a 00                	push   $0x0
f010138f:	50                   	push   %eax
f0101390:	e8 9c 3b 00 00       	call   f0104f31 <strtol>
f0101395:	83 c4 10             	add    $0x10,%esp
f0101398:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Frame_Info* ptr_frame_info;
	int ret = allocate_frame(&ptr_frame_info) ;
f010139b:	83 ec 0c             	sub    $0xc,%esp
f010139e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01013a1:	50                   	push   %eax
f01013a2:	e8 84 16 00 00       	call   f0102a2b <allocate_frame>
f01013a7:	83 c4 10             	add    $0x10,%esp
f01013aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	map_frame(ptr_page_directory, ptr_frame_info, (void*)va, PERM_USER | PERM_WRITEABLE);
f01013ad:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f01013b0:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01013b3:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01013b8:	6a 06                	push   $0x6
f01013ba:	51                   	push   %ecx
f01013bb:	52                   	push   %edx
f01013bc:	50                   	push   %eax
f01013bd:	e8 76 18 00 00       	call   f0102c38 <map_frame>
f01013c2:	83 c4 10             	add    $0x10,%esp

	return 0 ;
f01013c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013ca:	c9                   	leave  
f01013cb:	c3                   	ret    

f01013cc <command_fp>:

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
f01013cc:	55                   	push   %ebp
f01013cd:	89 e5                	mov    %esp,%ebp
f01013cf:	83 ec 18             	sub    $0x18,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	//panic("Function is not implemented yet!");

	uint32 va = strtol(arguments[1], NULL, 16);
f01013d2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d5:	83 c0 04             	add    $0x4,%eax
f01013d8:	8b 00                	mov    (%eax),%eax
f01013da:	83 ec 04             	sub    $0x4,%esp
f01013dd:	6a 10                	push   $0x10
f01013df:	6a 00                	push   $0x0
f01013e1:	50                   	push   %eax
f01013e2:	e8 4a 3b 00 00       	call   f0104f31 <strtol>
f01013e7:	83 c4 10             	add    $0x10,%esp
f01013ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Un-map the page at this address
	unmap_frame(ptr_page_directory, (void*)va);
f01013ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01013f0:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01013f5:	83 ec 08             	sub    $0x8,%esp
f01013f8:	52                   	push   %edx
f01013f9:	50                   	push   %eax
f01013fa:	e8 57 19 00 00       	call   f0102d56 <unmap_frame>
f01013ff:	83 c4 10             	add    $0x10,%esp

	return 0;
f0101402:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101407:	c9                   	leave  
f0101408:	c3                   	ret    

f0101409 <command_asp>:
//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
f0101409:	55                   	push   %ebp
f010140a:	89 e5                	mov    %esp,%ebp
f010140c:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");
f010140f:	83 ec 04             	sub    $0x4,%esp
f0101412:	68 64 5d 10 f0       	push   $0xf0105d64
f0101417:	68 1c 02 00 00       	push   $0x21c
f010141c:	68 85 5d 10 f0       	push   $0xf0105d85
f0101421:	e8 08 ed ff ff       	call   f010012e <_panic>

f0101426 <command_cfp>:
	return 0;
}

//[2] Count Free Pages in Range
int command_cfp(int number_of_arguments, char **arguments)
{
f0101426:	55                   	push   %ebp
f0101427:	89 e5                	mov    %esp,%ebp
f0101429:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "cfp"
	//Comment the following line
	panic("Function is not implemented yet!");
f010142c:	83 ec 04             	sub    $0x4,%esp
f010142f:	68 64 5d 10 f0       	push   $0xf0105d64
f0101434:	68 26 02 00 00       	push   $0x226
f0101439:	68 85 5d 10 f0       	push   $0xf0105d85
f010143e:	e8 eb ec ff ff       	call   f010012e <_panic>

f0101443 <command_run>:

//===========================================================================
//Lab6.Examples
//=============
int command_run(int number_of_arguments, char **arguments)
{
f0101443:	55                   	push   %ebp
f0101444:	89 e5                	mov    %esp,%ebp
f0101446:	83 ec 18             	sub    $0x18,%esp
	//[1] Create and initialize a new environment for the program to be run
	struct UserProgramInfo* ptr_program_info = env_create(arguments[1]);
f0101449:	8b 45 0c             	mov    0xc(%ebp),%eax
f010144c:	83 c0 04             	add    $0x4,%eax
f010144f:	8b 00                	mov    (%eax),%eax
f0101451:	83 ec 0c             	sub    $0xc,%esp
f0101454:	50                   	push   %eax
f0101455:	e8 6f 1a 00 00       	call   f0102ec9 <env_create>
f010145a:	83 c4 10             	add    $0x10,%esp
f010145d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0101460:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101464:	75 07                	jne    f010146d <command_run+0x2a>
f0101466:	b8 00 00 00 00       	mov    $0x0,%eax
f010146b:	eb 0f                	jmp    f010147c <command_run+0x39>

	//[2] Run the created environment using "env_run" function
	env_run(ptr_program_info->environment);
f010146d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101470:	8b 40 0c             	mov    0xc(%eax),%eax
f0101473:	83 ec 0c             	sub    $0xc,%esp
f0101476:	50                   	push   %eax
f0101477:	e8 bc 1a 00 00       	call   f0102f38 <env_run>
	return 0;
}
f010147c:	c9                   	leave  
f010147d:	c3                   	ret    

f010147e <command_kill>:

int command_kill(int number_of_arguments, char **arguments)
{
f010147e:	55                   	push   %ebp
f010147f:	89 e5                	mov    %esp,%ebp
f0101481:	83 ec 18             	sub    $0x18,%esp
	//[1] Get the user program info of the program (by searching in the "userPrograms" array
	struct UserProgramInfo* ptr_program_info = get_user_program_info(arguments[1]) ;
f0101484:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101487:	83 c0 04             	add    $0x4,%eax
f010148a:	8b 00                	mov    (%eax),%eax
f010148c:	83 ec 0c             	sub    $0xc,%esp
f010148f:	50                   	push   %eax
f0101490:	e8 70 1f 00 00       	call   f0103405 <get_user_program_info>
f0101495:	83 c4 10             	add    $0x10,%esp
f0101498:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f010149b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010149f:	75 07                	jne    f01014a8 <command_kill+0x2a>
f01014a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a6:	eb 21                	jmp    f01014c9 <command_kill+0x4b>

	//[2] Kill its environment using "env_free" function
	env_free(ptr_program_info->environment);
f01014a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014ab:	8b 40 0c             	mov    0xc(%eax),%eax
f01014ae:	83 ec 0c             	sub    $0xc,%esp
f01014b1:	50                   	push   %eax
f01014b2:	e8 c4 1a 00 00       	call   f0102f7b <env_free>
f01014b7:	83 c4 10             	add    $0x10,%esp
	ptr_program_info->environment = NULL;
f01014ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014bd:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	return 0;
f01014c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014c9:	c9                   	leave  
f01014ca:	c3                   	ret    

f01014cb <command_ft>:

int command_ft(int number_of_arguments, char **arguments)
{
f01014cb:	55                   	push   %ebp
f01014cc:	89 e5                	mov    %esp,%ebp
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
f01014ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014d3:	5d                   	pop    %ebp
f01014d4:	c3                   	ret    

f01014d5 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f01014d5:	55                   	push   %ebp
f01014d6:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f01014d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014db:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f01014e1:	29 d0                	sub    %edx,%eax
f01014e3:	c1 f8 02             	sar    $0x2,%eax
f01014e6:	89 c2                	mov    %eax,%edx
f01014e8:	89 d0                	mov    %edx,%eax
f01014ea:	c1 e0 02             	shl    $0x2,%eax
f01014ed:	01 d0                	add    %edx,%eax
f01014ef:	c1 e0 02             	shl    $0x2,%eax
f01014f2:	01 d0                	add    %edx,%eax
f01014f4:	c1 e0 02             	shl    $0x2,%eax
f01014f7:	01 d0                	add    %edx,%eax
f01014f9:	89 c1                	mov    %eax,%ecx
f01014fb:	c1 e1 08             	shl    $0x8,%ecx
f01014fe:	01 c8                	add    %ecx,%eax
f0101500:	89 c1                	mov    %eax,%ecx
f0101502:	c1 e1 10             	shl    $0x10,%ecx
f0101505:	01 c8                	add    %ecx,%eax
f0101507:	01 c0                	add    %eax,%eax
f0101509:	01 d0                	add    %edx,%eax
}
f010150b:	5d                   	pop    %ebp
f010150c:	c3                   	ret    

f010150d <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f010150d:	55                   	push   %ebp
f010150e:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0101510:	ff 75 08             	pushl  0x8(%ebp)
f0101513:	e8 bd ff ff ff       	call   f01014d5 <to_frame_number>
f0101518:	83 c4 04             	add    $0x4,%esp
f010151b:	c1 e0 0c             	shl    $0xc,%eax
}
f010151e:	c9                   	leave  
f010151f:	c3                   	ret    

f0101520 <nvram_read>:
{
	sizeof(gdt) - 1, (unsigned long) gdt
};

int nvram_read(int r)
{	
f0101520:	55                   	push   %ebp
f0101521:	89 e5                	mov    %esp,%ebp
f0101523:	53                   	push   %ebx
f0101524:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101527:	8b 45 08             	mov    0x8(%ebp),%eax
f010152a:	83 ec 0c             	sub    $0xc,%esp
f010152d:	50                   	push   %eax
f010152e:	e8 f4 20 00 00       	call   f0103627 <mc146818_read>
f0101533:	83 c4 10             	add    $0x10,%esp
f0101536:	89 c3                	mov    %eax,%ebx
f0101538:	8b 45 08             	mov    0x8(%ebp),%eax
f010153b:	40                   	inc    %eax
f010153c:	83 ec 0c             	sub    $0xc,%esp
f010153f:	50                   	push   %eax
f0101540:	e8 e2 20 00 00       	call   f0103627 <mc146818_read>
f0101545:	83 c4 10             	add    $0x10,%esp
f0101548:	c1 e0 08             	shl    $0x8,%eax
f010154b:	09 d8                	or     %ebx,%eax
}
f010154d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101550:	c9                   	leave  
f0101551:	c3                   	ret    

f0101552 <detect_memory>:
	
void detect_memory()
{
f0101552:	55                   	push   %ebp
f0101553:	89 e5                	mov    %esp,%ebp
f0101555:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	size_of_base_mem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PAGE_SIZE);
f0101558:	83 ec 0c             	sub    $0xc,%esp
f010155b:	6a 15                	push   $0x15
f010155d:	e8 be ff ff ff       	call   f0101520 <nvram_read>
f0101562:	83 c4 10             	add    $0x10,%esp
f0101565:	c1 e0 0a             	shl    $0xa,%eax
f0101568:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010156b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010156e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101573:	a3 d4 f7 14 f0       	mov    %eax,0xf014f7d4
	size_of_extended_mem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PAGE_SIZE);
f0101578:	83 ec 0c             	sub    $0xc,%esp
f010157b:	6a 17                	push   $0x17
f010157d:	e8 9e ff ff ff       	call   f0101520 <nvram_read>
f0101582:	83 c4 10             	add    $0x10,%esp
f0101585:	c1 e0 0a             	shl    $0xa,%eax
f0101588:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010158b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010158e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101593:	a3 cc f7 14 f0       	mov    %eax,0xf014f7cc

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (size_of_extended_mem)
f0101598:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f010159d:	85 c0                	test   %eax,%eax
f010159f:	74 11                	je     f01015b2 <detect_memory+0x60>
		maxpa = PHYS_EXTENDED_MEM + size_of_extended_mem;
f01015a1:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f01015a6:	05 00 00 10 00       	add    $0x100000,%eax
f01015ab:	a3 d0 f7 14 f0       	mov    %eax,0xf014f7d0
f01015b0:	eb 0a                	jmp    f01015bc <detect_memory+0x6a>
	else
		maxpa = size_of_extended_mem;
f01015b2:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f01015b7:	a3 d0 f7 14 f0       	mov    %eax,0xf014f7d0

	number_of_frames = maxpa / PAGE_SIZE;
f01015bc:	a1 d0 f7 14 f0       	mov    0xf014f7d0,%eax
f01015c1:	c1 e8 0c             	shr    $0xc,%eax
f01015c4:	a3 c8 f7 14 f0       	mov    %eax,0xf014f7c8

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f01015c9:	a1 d0 f7 14 f0       	mov    0xf014f7d0,%eax
f01015ce:	c1 e8 0a             	shr    $0xa,%eax
f01015d1:	83 ec 08             	sub    $0x8,%esp
f01015d4:	50                   	push   %eax
f01015d5:	68 b0 5e 10 f0       	push   $0xf0105eb0
f01015da:	e8 fd 20 00 00       	call   f01036dc <cprintf>
f01015df:	83 c4 10             	add    $0x10,%esp
	cprintf("base = %dK, extended = %dK\n", (int)(size_of_base_mem/1024), (int)(size_of_extended_mem/1024));
f01015e2:	a1 cc f7 14 f0       	mov    0xf014f7cc,%eax
f01015e7:	c1 e8 0a             	shr    $0xa,%eax
f01015ea:	89 c2                	mov    %eax,%edx
f01015ec:	a1 d4 f7 14 f0       	mov    0xf014f7d4,%eax
f01015f1:	c1 e8 0a             	shr    $0xa,%eax
f01015f4:	83 ec 04             	sub    $0x4,%esp
f01015f7:	52                   	push   %edx
f01015f8:	50                   	push   %eax
f01015f9:	68 d1 5e 10 f0       	push   $0xf0105ed1
f01015fe:	e8 d9 20 00 00       	call   f01036dc <cprintf>
f0101603:	83 c4 10             	add    $0x10,%esp
}
f0101606:	90                   	nop
f0101607:	c9                   	leave  
f0101608:	c3                   	ret    

f0101609 <check_boot_pgdir>:
// but it is a pretty good check.
//
uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va);

void check_boot_pgdir()
{
f0101609:	55                   	push   %ebp
f010160a:	89 e5                	mov    %esp,%ebp
f010160c:	83 ec 28             	sub    $0x28,%esp
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
f010160f:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0101616:	8b 15 c8 f7 14 f0    	mov    0xf014f7c8,%edx
f010161c:	89 d0                	mov    %edx,%eax
f010161e:	01 c0                	add    %eax,%eax
f0101620:	01 d0                	add    %edx,%eax
f0101622:	c1 e0 02             	shl    $0x2,%eax
f0101625:	89 c2                	mov    %eax,%edx
f0101627:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010162a:	01 d0                	add    %edx,%eax
f010162c:	48                   	dec    %eax
f010162d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101630:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101633:	ba 00 00 00 00       	mov    $0x0,%edx
f0101638:	f7 75 f0             	divl   -0x10(%ebp)
f010163b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010163e:	29 d0                	sub    %edx,%eax
f0101640:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (i = 0; i < n; i += PAGE_SIZE)
f0101643:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010164a:	eb 71                	jmp    f01016bd <check_boot_pgdir+0xb4>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);
f010164c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010164f:	8d 90 00 00 00 ef    	lea    -0x11000000(%eax),%edx
f0101655:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010165a:	83 ec 08             	sub    $0x8,%esp
f010165d:	52                   	push   %edx
f010165e:	50                   	push   %eax
f010165f:	e8 f4 01 00 00       	call   f0101858 <check_va2pa>
f0101664:	83 c4 10             	add    $0x10,%esp
f0101667:	89 c2                	mov    %eax,%edx
f0101669:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f010166e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101671:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0101678:	77 14                	ja     f010168e <check_boot_pgdir+0x85>
f010167a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010167d:	68 f0 5e 10 f0       	push   $0xf0105ef0
f0101682:	6a 5e                	push   $0x5e
f0101684:	68 21 5f 10 f0       	push   $0xf0105f21
f0101689:	e8 a0 ea ff ff       	call   f010012e <_panic>
f010168e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101691:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0101697:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010169a:	01 c8                	add    %ecx,%eax
f010169c:	39 c2                	cmp    %eax,%edx
f010169e:	74 16                	je     f01016b6 <check_boot_pgdir+0xad>
f01016a0:	68 30 5f 10 f0       	push   $0xf0105f30
f01016a5:	68 92 5f 10 f0       	push   $0xf0105f92
f01016aa:	6a 5e                	push   $0x5e
f01016ac:	68 21 5f 10 f0       	push   $0xf0105f21
f01016b1:	e8 78 ea ff ff       	call   f010012e <_panic>
{
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
f01016b6:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01016bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016c0:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f01016c3:	72 87                	jb     f010164c <check_boot_pgdir+0x43>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f01016c5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01016cc:	eb 3d                	jmp    f010170b <check_boot_pgdir+0x102>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);
f01016ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016d1:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f01016d7:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01016dc:	83 ec 08             	sub    $0x8,%esp
f01016df:	52                   	push   %edx
f01016e0:	50                   	push   %eax
f01016e1:	e8 72 01 00 00       	call   f0101858 <check_va2pa>
f01016e6:	83 c4 10             	add    $0x10,%esp
f01016e9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f01016ec:	74 16                	je     f0101704 <check_boot_pgdir+0xfb>
f01016ee:	68 a8 5f 10 f0       	push   $0xf0105fa8
f01016f3:	68 92 5f 10 f0       	push   $0xf0105f92
f01016f8:	6a 62                	push   $0x62
f01016fa:	68 21 5f 10 f0       	push   $0xf0105f21
f01016ff:	e8 2a ea ff ff       	call   f010012e <_panic>
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f0101704:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f010170b:	81 7d f4 00 00 00 10 	cmpl   $0x10000000,-0xc(%ebp)
f0101712:	75 ba                	jne    f01016ce <check_boot_pgdir+0xc5>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f0101714:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010171b:	eb 6e                	jmp    f010178b <check_boot_pgdir+0x182>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);
f010171d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101720:	8d 90 00 80 bf ef    	lea    -0x10408000(%eax),%edx
f0101726:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010172b:	83 ec 08             	sub    $0x8,%esp
f010172e:	52                   	push   %edx
f010172f:	50                   	push   %eax
f0101730:	e8 23 01 00 00       	call   f0101858 <check_va2pa>
f0101735:	83 c4 10             	add    $0x10,%esp
f0101738:	c7 45 e0 00 40 11 f0 	movl   $0xf0114000,-0x20(%ebp)
f010173f:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0101746:	77 14                	ja     f010175c <check_boot_pgdir+0x153>
f0101748:	ff 75 e0             	pushl  -0x20(%ebp)
f010174b:	68 f0 5e 10 f0       	push   $0xf0105ef0
f0101750:	6a 66                	push   $0x66
f0101752:	68 21 5f 10 f0       	push   $0xf0105f21
f0101757:	e8 d2 e9 ff ff       	call   f010012e <_panic>
f010175c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010175f:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f0101765:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101768:	01 ca                	add    %ecx,%edx
f010176a:	39 d0                	cmp    %edx,%eax
f010176c:	74 16                	je     f0101784 <check_boot_pgdir+0x17b>
f010176e:	68 e0 5f 10 f0       	push   $0xf0105fe0
f0101773:	68 92 5f 10 f0       	push   $0xf0105f92
f0101778:	6a 66                	push   $0x66
f010177a:	68 21 5f 10 f0       	push   $0xf0105f21
f010177f:	e8 aa e9 ff ff       	call   f010012e <_panic>
	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f0101784:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f010178b:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f0101792:	76 89                	jbe    f010171d <check_boot_pgdir+0x114>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101794:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010179b:	e9 98 00 00 00       	jmp    f0101838 <check_boot_pgdir+0x22f>
		switch (i) {
f01017a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017a3:	2d bb 03 00 00       	sub    $0x3bb,%eax
f01017a8:	83 f8 04             	cmp    $0x4,%eax
f01017ab:	77 29                	ja     f01017d6 <check_boot_pgdir+0x1cd>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
f01017ad:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01017b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017b5:	c1 e2 02             	shl    $0x2,%edx
f01017b8:	01 d0                	add    %edx,%eax
f01017ba:	8b 00                	mov    (%eax),%eax
f01017bc:	85 c0                	test   %eax,%eax
f01017be:	75 71                	jne    f0101831 <check_boot_pgdir+0x228>
f01017c0:	68 56 60 10 f0       	push   $0xf0106056
f01017c5:	68 92 5f 10 f0       	push   $0xf0105f92
f01017ca:	6a 70                	push   $0x70
f01017cc:	68 21 5f 10 f0       	push   $0xf0105f21
f01017d1:	e8 58 e9 ff ff       	call   f010012e <_panic>
			break;
		default:
			if (i >= PDX(KERNEL_BASE))
f01017d6:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f01017dd:	76 29                	jbe    f0101808 <check_boot_pgdir+0x1ff>
				assert(ptr_page_directory[i]);
f01017df:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01017e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017e7:	c1 e2 02             	shl    $0x2,%edx
f01017ea:	01 d0                	add    %edx,%eax
f01017ec:	8b 00                	mov    (%eax),%eax
f01017ee:	85 c0                	test   %eax,%eax
f01017f0:	75 42                	jne    f0101834 <check_boot_pgdir+0x22b>
f01017f2:	68 56 60 10 f0       	push   $0xf0106056
f01017f7:	68 92 5f 10 f0       	push   $0xf0105f92
f01017fc:	6a 74                	push   $0x74
f01017fe:	68 21 5f 10 f0       	push   $0xf0105f21
f0101803:	e8 26 e9 ff ff       	call   f010012e <_panic>
			else				
				assert(ptr_page_directory[i] == 0);
f0101808:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010180d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101810:	c1 e2 02             	shl    $0x2,%edx
f0101813:	01 d0                	add    %edx,%eax
f0101815:	8b 00                	mov    (%eax),%eax
f0101817:	85 c0                	test   %eax,%eax
f0101819:	74 19                	je     f0101834 <check_boot_pgdir+0x22b>
f010181b:	68 6c 60 10 f0       	push   $0xf010606c
f0101820:	68 92 5f 10 f0       	push   $0xf0105f92
f0101825:	6a 76                	push   $0x76
f0101827:	68 21 5f 10 f0       	push   $0xf0105f21
f010182c:	e8 fd e8 ff ff       	call   f010012e <_panic>
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
			break;
f0101831:	90                   	nop
f0101832:	eb 01                	jmp    f0101835 <check_boot_pgdir+0x22c>
		default:
			if (i >= PDX(KERNEL_BASE))
				assert(ptr_page_directory[i]);
			else				
				assert(ptr_page_directory[i] == 0);
			break;
f0101834:	90                   	nop
	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101835:	ff 45 f4             	incl   -0xc(%ebp)
f0101838:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f010183f:	0f 86 5b ff ff ff    	jbe    f01017a0 <check_boot_pgdir+0x197>
			else				
				assert(ptr_page_directory[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f0101845:	83 ec 0c             	sub    $0xc,%esp
f0101848:	68 88 60 10 f0       	push   $0xf0106088
f010184d:	e8 8a 1e 00 00       	call   f01036dc <cprintf>
f0101852:	83 c4 10             	add    $0x10,%esp
}
f0101855:	90                   	nop
f0101856:	c9                   	leave  
f0101857:	c3                   	ret    

f0101858 <check_va2pa>:
// defined by the page directory 'ptr_page_directory'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va)
{
f0101858:	55                   	push   %ebp
f0101859:	89 e5                	mov    %esp,%ebp
f010185b:	83 ec 18             	sub    $0x18,%esp
	uint32 *p;

	ptr_page_directory = &ptr_page_directory[PDX(va)];
f010185e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101861:	c1 e8 16             	shr    $0x16,%eax
f0101864:	c1 e0 02             	shl    $0x2,%eax
f0101867:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*ptr_page_directory & PERM_PRESENT))
f010186a:	8b 45 08             	mov    0x8(%ebp),%eax
f010186d:	8b 00                	mov    (%eax),%eax
f010186f:	83 e0 01             	and    $0x1,%eax
f0101872:	85 c0                	test   %eax,%eax
f0101874:	75 0a                	jne    f0101880 <check_va2pa+0x28>
		return ~0;
f0101876:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010187b:	e9 87 00 00 00       	jmp    f0101907 <check_va2pa+0xaf>
	p = (uint32*) K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(*ptr_page_directory));
f0101880:	8b 45 08             	mov    0x8(%ebp),%eax
f0101883:	8b 00                	mov    (%eax),%eax
f0101885:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010188a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010188d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101890:	c1 e8 0c             	shr    $0xc,%eax
f0101893:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101896:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f010189b:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f010189e:	72 17                	jb     f01018b7 <check_va2pa+0x5f>
f01018a0:	ff 75 f4             	pushl  -0xc(%ebp)
f01018a3:	68 a8 60 10 f0       	push   $0xf01060a8
f01018a8:	68 89 00 00 00       	push   $0x89
f01018ad:	68 21 5f 10 f0       	push   $0xf0105f21
f01018b2:	e8 77 e8 ff ff       	call   f010012e <_panic>
f01018b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018bf:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PERM_PRESENT))
f01018c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018c5:	c1 e8 0c             	shr    $0xc,%eax
f01018c8:	25 ff 03 00 00       	and    $0x3ff,%eax
f01018cd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01018d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018d7:	01 d0                	add    %edx,%eax
f01018d9:	8b 00                	mov    (%eax),%eax
f01018db:	83 e0 01             	and    $0x1,%eax
f01018de:	85 c0                	test   %eax,%eax
f01018e0:	75 07                	jne    f01018e9 <check_va2pa+0x91>
		return ~0;
f01018e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01018e7:	eb 1e                	jmp    f0101907 <check_va2pa+0xaf>
	return EXTRACT_ADDRESS(p[PTX(va)]);
f01018e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018ec:	c1 e8 0c             	shr    $0xc,%eax
f01018ef:	25 ff 03 00 00       	and    $0x3ff,%eax
f01018f4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01018fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018fe:	01 d0                	add    %edx,%eax
f0101900:	8b 00                	mov    (%eax),%eax
f0101902:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f0101907:	c9                   	leave  
f0101908:	c3                   	ret    

f0101909 <tlb_invalidate>:
		
void tlb_invalidate(uint32 *ptr_page_directory, void *virtual_address)
{
f0101909:	55                   	push   %ebp
f010190a:	89 e5                	mov    %esp,%ebp
f010190c:	83 ec 10             	sub    $0x10,%esp
f010190f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101912:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101915:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101918:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(virtual_address);
}
f010191b:	90                   	nop
f010191c:	c9                   	leave  
f010191d:	c3                   	ret    

f010191e <page_check>:

void page_check()
{
f010191e:	55                   	push   %ebp
f010191f:	89 e5                	mov    %esp,%ebp
f0101921:	53                   	push   %ebx
f0101922:	83 ec 24             	sub    $0x24,%esp
	struct Frame_Info *pp, *pp0, *pp1, *pp2;
	struct Linked_List fl;

	// should be able to allocate three frames_info
	pp0 = pp1 = pp2 = 0;
f0101925:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f010192c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010192f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101932:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101935:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(allocate_frame(&pp0) == 0);
f0101938:	83 ec 0c             	sub    $0xc,%esp
f010193b:	8d 45 f0             	lea    -0x10(%ebp),%eax
f010193e:	50                   	push   %eax
f010193f:	e8 e7 10 00 00       	call   f0102a2b <allocate_frame>
f0101944:	83 c4 10             	add    $0x10,%esp
f0101947:	85 c0                	test   %eax,%eax
f0101949:	74 19                	je     f0101964 <page_check+0x46>
f010194b:	68 d7 60 10 f0       	push   $0xf01060d7
f0101950:	68 92 5f 10 f0       	push   $0xf0105f92
f0101955:	68 9d 00 00 00       	push   $0x9d
f010195a:	68 21 5f 10 f0       	push   $0xf0105f21
f010195f:	e8 ca e7 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp1) == 0);
f0101964:	83 ec 0c             	sub    $0xc,%esp
f0101967:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010196a:	50                   	push   %eax
f010196b:	e8 bb 10 00 00       	call   f0102a2b <allocate_frame>
f0101970:	83 c4 10             	add    $0x10,%esp
f0101973:	85 c0                	test   %eax,%eax
f0101975:	74 19                	je     f0101990 <page_check+0x72>
f0101977:	68 f1 60 10 f0       	push   $0xf01060f1
f010197c:	68 92 5f 10 f0       	push   $0xf0105f92
f0101981:	68 9e 00 00 00       	push   $0x9e
f0101986:	68 21 5f 10 f0       	push   $0xf0105f21
f010198b:	e8 9e e7 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp2) == 0);
f0101990:	83 ec 0c             	sub    $0xc,%esp
f0101993:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0101996:	50                   	push   %eax
f0101997:	e8 8f 10 00 00       	call   f0102a2b <allocate_frame>
f010199c:	83 c4 10             	add    $0x10,%esp
f010199f:	85 c0                	test   %eax,%eax
f01019a1:	74 19                	je     f01019bc <page_check+0x9e>
f01019a3:	68 0b 61 10 f0       	push   $0xf010610b
f01019a8:	68 92 5f 10 f0       	push   $0xf0105f92
f01019ad:	68 9f 00 00 00       	push   $0x9f
f01019b2:	68 21 5f 10 f0       	push   $0xf0105f21
f01019b7:	e8 72 e7 ff ff       	call   f010012e <_panic>

	assert(pp0);
f01019bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01019bf:	85 c0                	test   %eax,%eax
f01019c1:	75 19                	jne    f01019dc <page_check+0xbe>
f01019c3:	68 25 61 10 f0       	push   $0xf0106125
f01019c8:	68 92 5f 10 f0       	push   $0xf0105f92
f01019cd:	68 a1 00 00 00       	push   $0xa1
f01019d2:	68 21 5f 10 f0       	push   $0xf0105f21
f01019d7:	e8 52 e7 ff ff       	call   f010012e <_panic>
	assert(pp1 && pp1 != pp0);
f01019dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01019df:	85 c0                	test   %eax,%eax
f01019e1:	74 0a                	je     f01019ed <page_check+0xcf>
f01019e3:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01019e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01019e9:	39 c2                	cmp    %eax,%edx
f01019eb:	75 19                	jne    f0101a06 <page_check+0xe8>
f01019ed:	68 29 61 10 f0       	push   $0xf0106129
f01019f2:	68 92 5f 10 f0       	push   $0xf0105f92
f01019f7:	68 a2 00 00 00       	push   $0xa2
f01019fc:	68 21 5f 10 f0       	push   $0xf0105f21
f0101a01:	e8 28 e7 ff ff       	call   f010012e <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a06:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101a09:	85 c0                	test   %eax,%eax
f0101a0b:	74 14                	je     f0101a21 <page_check+0x103>
f0101a0d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101a10:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101a13:	39 c2                	cmp    %eax,%edx
f0101a15:	74 0a                	je     f0101a21 <page_check+0x103>
f0101a17:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101a1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a1d:	39 c2                	cmp    %eax,%edx
f0101a1f:	75 19                	jne    f0101a3a <page_check+0x11c>
f0101a21:	68 3c 61 10 f0       	push   $0xf010613c
f0101a26:	68 92 5f 10 f0       	push   $0xf0105f92
f0101a2b:	68 a3 00 00 00       	push   $0xa3
f0101a30:	68 21 5f 10 f0       	push   $0xf0105f21
f0101a35:	e8 f4 e6 ff ff       	call   f010012e <_panic>

	// temporarily steal the rest of the free frames_info
	fl = free_frame_list;
f0101a3a:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0101a3f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&free_frame_list);
f0101a42:	c7 05 d8 f7 14 f0 00 	movl   $0x0,0xf014f7d8
f0101a49:	00 00 00 

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101a4c:	83 ec 0c             	sub    $0xc,%esp
f0101a4f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101a52:	50                   	push   %eax
f0101a53:	e8 d3 0f 00 00       	call   f0102a2b <allocate_frame>
f0101a58:	83 c4 10             	add    $0x10,%esp
f0101a5b:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101a5e:	74 19                	je     f0101a79 <page_check+0x15b>
f0101a60:	68 5c 61 10 f0       	push   $0xf010615c
f0101a65:	68 92 5f 10 f0       	push   $0xf0105f92
f0101a6a:	68 aa 00 00 00       	push   $0xaa
f0101a6f:	68 21 5f 10 f0       	push   $0xf0105f21
f0101a74:	e8 b5 e6 ff ff       	call   f010012e <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) < 0);
f0101a79:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101a7c:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101a81:	6a 00                	push   $0x0
f0101a83:	6a 00                	push   $0x0
f0101a85:	52                   	push   %edx
f0101a86:	50                   	push   %eax
f0101a87:	e8 ac 11 00 00       	call   f0102c38 <map_frame>
f0101a8c:	83 c4 10             	add    $0x10,%esp
f0101a8f:	85 c0                	test   %eax,%eax
f0101a91:	78 19                	js     f0101aac <page_check+0x18e>
f0101a93:	68 7c 61 10 f0       	push   $0xf010617c
f0101a98:	68 92 5f 10 f0       	push   $0xf0105f92
f0101a9d:	68 ad 00 00 00       	push   $0xad
f0101aa2:	68 21 5f 10 f0       	push   $0xf0105f21
f0101aa7:	e8 82 e6 ff ff       	call   f010012e <_panic>

	// free pp0 and try again: pp0 should be used for page table
	free_frame(pp0);
f0101aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101aaf:	83 ec 0c             	sub    $0xc,%esp
f0101ab2:	50                   	push   %eax
f0101ab3:	e8 da 0f 00 00       	call   f0102a92 <free_frame>
f0101ab8:	83 c4 10             	add    $0x10,%esp
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) == 0);
f0101abb:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101abe:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101ac3:	6a 00                	push   $0x0
f0101ac5:	6a 00                	push   $0x0
f0101ac7:	52                   	push   %edx
f0101ac8:	50                   	push   %eax
f0101ac9:	e8 6a 11 00 00       	call   f0102c38 <map_frame>
f0101ace:	83 c4 10             	add    $0x10,%esp
f0101ad1:	85 c0                	test   %eax,%eax
f0101ad3:	74 19                	je     f0101aee <page_check+0x1d0>
f0101ad5:	68 ac 61 10 f0       	push   $0xf01061ac
f0101ada:	68 92 5f 10 f0       	push   $0xf0105f92
f0101adf:	68 b1 00 00 00       	push   $0xb1
f0101ae4:	68 21 5f 10 f0       	push   $0xf0105f21
f0101ae9:	e8 40 e6 ff ff       	call   f010012e <_panic>
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101aee:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101af3:	8b 00                	mov    (%eax),%eax
f0101af5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101afa:	89 c3                	mov    %eax,%ebx
f0101afc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101aff:	83 ec 0c             	sub    $0xc,%esp
f0101b02:	50                   	push   %eax
f0101b03:	e8 05 fa ff ff       	call   f010150d <to_physical_address>
f0101b08:	83 c4 10             	add    $0x10,%esp
f0101b0b:	39 c3                	cmp    %eax,%ebx
f0101b0d:	74 19                	je     f0101b28 <page_check+0x20a>
f0101b0f:	68 dc 61 10 f0       	push   $0xf01061dc
f0101b14:	68 92 5f 10 f0       	push   $0xf0105f92
f0101b19:	68 b2 00 00 00       	push   $0xb2
f0101b1e:	68 21 5f 10 f0       	push   $0xf0105f21
f0101b23:	e8 06 e6 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, 0x0) == to_physical_address(pp1));
f0101b28:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101b2d:	83 ec 08             	sub    $0x8,%esp
f0101b30:	6a 00                	push   $0x0
f0101b32:	50                   	push   %eax
f0101b33:	e8 20 fd ff ff       	call   f0101858 <check_va2pa>
f0101b38:	83 c4 10             	add    $0x10,%esp
f0101b3b:	89 c3                	mov    %eax,%ebx
f0101b3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b40:	83 ec 0c             	sub    $0xc,%esp
f0101b43:	50                   	push   %eax
f0101b44:	e8 c4 f9 ff ff       	call   f010150d <to_physical_address>
f0101b49:	83 c4 10             	add    $0x10,%esp
f0101b4c:	39 c3                	cmp    %eax,%ebx
f0101b4e:	74 19                	je     f0101b69 <page_check+0x24b>
f0101b50:	68 20 62 10 f0       	push   $0xf0106220
f0101b55:	68 92 5f 10 f0       	push   $0xf0105f92
f0101b5a:	68 b3 00 00 00       	push   $0xb3
f0101b5f:	68 21 5f 10 f0       	push   $0xf0105f21
f0101b64:	e8 c5 e5 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101b69:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b6c:	8b 40 08             	mov    0x8(%eax),%eax
f0101b6f:	66 83 f8 01          	cmp    $0x1,%ax
f0101b73:	74 19                	je     f0101b8e <page_check+0x270>
f0101b75:	68 61 62 10 f0       	push   $0xf0106261
f0101b7a:	68 92 5f 10 f0       	push   $0xf0105f92
f0101b7f:	68 b4 00 00 00       	push   $0xb4
f0101b84:	68 21 5f 10 f0       	push   $0xf0105f21
f0101b89:	e8 a0 e5 ff ff       	call   f010012e <_panic>
	assert(pp0->references == 1);
f0101b8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b91:	8b 40 08             	mov    0x8(%eax),%eax
f0101b94:	66 83 f8 01          	cmp    $0x1,%ax
f0101b98:	74 19                	je     f0101bb3 <page_check+0x295>
f0101b9a:	68 76 62 10 f0       	push   $0xf0106276
f0101b9f:	68 92 5f 10 f0       	push   $0xf0105f92
f0101ba4:	68 b5 00 00 00       	push   $0xb5
f0101ba9:	68 21 5f 10 f0       	push   $0xf0105f21
f0101bae:	e8 7b e5 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because pp0 is already allocated for page table
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101bb3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101bb6:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101bbb:	6a 00                	push   $0x0
f0101bbd:	68 00 10 00 00       	push   $0x1000
f0101bc2:	52                   	push   %edx
f0101bc3:	50                   	push   %eax
f0101bc4:	e8 6f 10 00 00       	call   f0102c38 <map_frame>
f0101bc9:	83 c4 10             	add    $0x10,%esp
f0101bcc:	85 c0                	test   %eax,%eax
f0101bce:	74 19                	je     f0101be9 <page_check+0x2cb>
f0101bd0:	68 8c 62 10 f0       	push   $0xf010628c
f0101bd5:	68 92 5f 10 f0       	push   $0xf0105f92
f0101bda:	68 b8 00 00 00       	push   $0xb8
f0101bdf:	68 21 5f 10 f0       	push   $0xf0105f21
f0101be4:	e8 45 e5 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101be9:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101bee:	83 ec 08             	sub    $0x8,%esp
f0101bf1:	68 00 10 00 00       	push   $0x1000
f0101bf6:	50                   	push   %eax
f0101bf7:	e8 5c fc ff ff       	call   f0101858 <check_va2pa>
f0101bfc:	83 c4 10             	add    $0x10,%esp
f0101bff:	89 c3                	mov    %eax,%ebx
f0101c01:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101c04:	83 ec 0c             	sub    $0xc,%esp
f0101c07:	50                   	push   %eax
f0101c08:	e8 00 f9 ff ff       	call   f010150d <to_physical_address>
f0101c0d:	83 c4 10             	add    $0x10,%esp
f0101c10:	39 c3                	cmp    %eax,%ebx
f0101c12:	74 19                	je     f0101c2d <page_check+0x30f>
f0101c14:	68 cc 62 10 f0       	push   $0xf01062cc
f0101c19:	68 92 5f 10 f0       	push   $0xf0105f92
f0101c1e:	68 b9 00 00 00       	push   $0xb9
f0101c23:	68 21 5f 10 f0       	push   $0xf0105f21
f0101c28:	e8 01 e5 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101c2d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101c30:	8b 40 08             	mov    0x8(%eax),%eax
f0101c33:	66 83 f8 01          	cmp    $0x1,%ax
f0101c37:	74 19                	je     f0101c52 <page_check+0x334>
f0101c39:	68 13 63 10 f0       	push   $0xf0106313
f0101c3e:	68 92 5f 10 f0       	push   $0xf0105f92
f0101c43:	68 ba 00 00 00       	push   $0xba
f0101c48:	68 21 5f 10 f0       	push   $0xf0105f21
f0101c4d:	e8 dc e4 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101c52:	83 ec 0c             	sub    $0xc,%esp
f0101c55:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101c58:	50                   	push   %eax
f0101c59:	e8 cd 0d 00 00       	call   f0102a2b <allocate_frame>
f0101c5e:	83 c4 10             	add    $0x10,%esp
f0101c61:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101c64:	74 19                	je     f0101c7f <page_check+0x361>
f0101c66:	68 5c 61 10 f0       	push   $0xf010615c
f0101c6b:	68 92 5f 10 f0       	push   $0xf0105f92
f0101c70:	68 bd 00 00 00       	push   $0xbd
f0101c75:	68 21 5f 10 f0       	push   $0xf0105f21
f0101c7a:	e8 af e4 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because it's already there
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101c7f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101c82:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101c87:	6a 00                	push   $0x0
f0101c89:	68 00 10 00 00       	push   $0x1000
f0101c8e:	52                   	push   %edx
f0101c8f:	50                   	push   %eax
f0101c90:	e8 a3 0f 00 00       	call   f0102c38 <map_frame>
f0101c95:	83 c4 10             	add    $0x10,%esp
f0101c98:	85 c0                	test   %eax,%eax
f0101c9a:	74 19                	je     f0101cb5 <page_check+0x397>
f0101c9c:	68 8c 62 10 f0       	push   $0xf010628c
f0101ca1:	68 92 5f 10 f0       	push   $0xf0105f92
f0101ca6:	68 c0 00 00 00       	push   $0xc0
f0101cab:	68 21 5f 10 f0       	push   $0xf0105f21
f0101cb0:	e8 79 e4 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101cb5:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101cba:	83 ec 08             	sub    $0x8,%esp
f0101cbd:	68 00 10 00 00       	push   $0x1000
f0101cc2:	50                   	push   %eax
f0101cc3:	e8 90 fb ff ff       	call   f0101858 <check_va2pa>
f0101cc8:	83 c4 10             	add    $0x10,%esp
f0101ccb:	89 c3                	mov    %eax,%ebx
f0101ccd:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101cd0:	83 ec 0c             	sub    $0xc,%esp
f0101cd3:	50                   	push   %eax
f0101cd4:	e8 34 f8 ff ff       	call   f010150d <to_physical_address>
f0101cd9:	83 c4 10             	add    $0x10,%esp
f0101cdc:	39 c3                	cmp    %eax,%ebx
f0101cde:	74 19                	je     f0101cf9 <page_check+0x3db>
f0101ce0:	68 cc 62 10 f0       	push   $0xf01062cc
f0101ce5:	68 92 5f 10 f0       	push   $0xf0105f92
f0101cea:	68 c1 00 00 00       	push   $0xc1
f0101cef:	68 21 5f 10 f0       	push   $0xf0105f21
f0101cf4:	e8 35 e4 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101cf9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101cfc:	8b 40 08             	mov    0x8(%eax),%eax
f0101cff:	66 83 f8 01          	cmp    $0x1,%ax
f0101d03:	74 19                	je     f0101d1e <page_check+0x400>
f0101d05:	68 13 63 10 f0       	push   $0xf0106313
f0101d0a:	68 92 5f 10 f0       	push   $0xf0105f92
f0101d0f:	68 c2 00 00 00       	push   $0xc2
f0101d14:	68 21 5f 10 f0       	push   $0xf0105f21
f0101d19:	e8 10 e4 ff ff       	call   f010012e <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in map_frame
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101d1e:	83 ec 0c             	sub    $0xc,%esp
f0101d21:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101d24:	50                   	push   %eax
f0101d25:	e8 01 0d 00 00       	call   f0102a2b <allocate_frame>
f0101d2a:	83 c4 10             	add    $0x10,%esp
f0101d2d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101d30:	74 19                	je     f0101d4b <page_check+0x42d>
f0101d32:	68 5c 61 10 f0       	push   $0xf010615c
f0101d37:	68 92 5f 10 f0       	push   $0xf0105f92
f0101d3c:	68 c6 00 00 00       	push   $0xc6
f0101d41:	68 21 5f 10 f0       	push   $0xf0105f21
f0101d46:	e8 e3 e3 ff ff       	call   f010012e <_panic>

	// should not be able to map at PTSIZE because need free frame for page table
	assert(map_frame(ptr_page_directory, pp0, (void*) PTSIZE, 0) < 0);
f0101d4b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101d4e:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101d53:	6a 00                	push   $0x0
f0101d55:	68 00 00 40 00       	push   $0x400000
f0101d5a:	52                   	push   %edx
f0101d5b:	50                   	push   %eax
f0101d5c:	e8 d7 0e 00 00       	call   f0102c38 <map_frame>
f0101d61:	83 c4 10             	add    $0x10,%esp
f0101d64:	85 c0                	test   %eax,%eax
f0101d66:	78 19                	js     f0101d81 <page_check+0x463>
f0101d68:	68 28 63 10 f0       	push   $0xf0106328
f0101d6d:	68 92 5f 10 f0       	push   $0xf0105f92
f0101d72:	68 c9 00 00 00       	push   $0xc9
f0101d77:	68 21 5f 10 f0       	push   $0xf0105f21
f0101d7c:	e8 ad e3 ff ff       	call   f010012e <_panic>

	// insert pp1 at PAGE_SIZE (replacing pp2)
	assert(map_frame(ptr_page_directory, pp1, (void*) PAGE_SIZE, 0) == 0);
f0101d81:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101d84:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101d89:	6a 00                	push   $0x0
f0101d8b:	68 00 10 00 00       	push   $0x1000
f0101d90:	52                   	push   %edx
f0101d91:	50                   	push   %eax
f0101d92:	e8 a1 0e 00 00       	call   f0102c38 <map_frame>
f0101d97:	83 c4 10             	add    $0x10,%esp
f0101d9a:	85 c0                	test   %eax,%eax
f0101d9c:	74 19                	je     f0101db7 <page_check+0x499>
f0101d9e:	68 64 63 10 f0       	push   $0xf0106364
f0101da3:	68 92 5f 10 f0       	push   $0xf0105f92
f0101da8:	68 cc 00 00 00       	push   $0xcc
f0101dad:	68 21 5f 10 f0       	push   $0xf0105f21
f0101db2:	e8 77 e3 ff ff       	call   f010012e <_panic>

	// should have pp1 at both 0 and PAGE_SIZE, pp2 nowhere, ...
	assert(check_va2pa(ptr_page_directory, 0) == to_physical_address(pp1));
f0101db7:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101dbc:	83 ec 08             	sub    $0x8,%esp
f0101dbf:	6a 00                	push   $0x0
f0101dc1:	50                   	push   %eax
f0101dc2:	e8 91 fa ff ff       	call   f0101858 <check_va2pa>
f0101dc7:	83 c4 10             	add    $0x10,%esp
f0101dca:	89 c3                	mov    %eax,%ebx
f0101dcc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101dcf:	83 ec 0c             	sub    $0xc,%esp
f0101dd2:	50                   	push   %eax
f0101dd3:	e8 35 f7 ff ff       	call   f010150d <to_physical_address>
f0101dd8:	83 c4 10             	add    $0x10,%esp
f0101ddb:	39 c3                	cmp    %eax,%ebx
f0101ddd:	74 19                	je     f0101df8 <page_check+0x4da>
f0101ddf:	68 a4 63 10 f0       	push   $0xf01063a4
f0101de4:	68 92 5f 10 f0       	push   $0xf0105f92
f0101de9:	68 cf 00 00 00       	push   $0xcf
f0101dee:	68 21 5f 10 f0       	push   $0xf0105f21
f0101df3:	e8 36 e3 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101df8:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101dfd:	83 ec 08             	sub    $0x8,%esp
f0101e00:	68 00 10 00 00       	push   $0x1000
f0101e05:	50                   	push   %eax
f0101e06:	e8 4d fa ff ff       	call   f0101858 <check_va2pa>
f0101e0b:	83 c4 10             	add    $0x10,%esp
f0101e0e:	89 c3                	mov    %eax,%ebx
f0101e10:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e13:	83 ec 0c             	sub    $0xc,%esp
f0101e16:	50                   	push   %eax
f0101e17:	e8 f1 f6 ff ff       	call   f010150d <to_physical_address>
f0101e1c:	83 c4 10             	add    $0x10,%esp
f0101e1f:	39 c3                	cmp    %eax,%ebx
f0101e21:	74 19                	je     f0101e3c <page_check+0x51e>
f0101e23:	68 e4 63 10 f0       	push   $0xf01063e4
f0101e28:	68 92 5f 10 f0       	push   $0xf0105f92
f0101e2d:	68 d0 00 00 00       	push   $0xd0
f0101e32:	68 21 5f 10 f0       	push   $0xf0105f21
f0101e37:	e8 f2 e2 ff ff       	call   f010012e <_panic>
	// ... and ref counts should reflect this
	assert(pp1->references == 2);
f0101e3c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e3f:	8b 40 08             	mov    0x8(%eax),%eax
f0101e42:	66 83 f8 02          	cmp    $0x2,%ax
f0101e46:	74 19                	je     f0101e61 <page_check+0x543>
f0101e48:	68 2b 64 10 f0       	push   $0xf010642b
f0101e4d:	68 92 5f 10 f0       	push   $0xf0105f92
f0101e52:	68 d2 00 00 00       	push   $0xd2
f0101e57:	68 21 5f 10 f0       	push   $0xf0105f21
f0101e5c:	e8 cd e2 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101e61:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101e64:	8b 40 08             	mov    0x8(%eax),%eax
f0101e67:	66 85 c0             	test   %ax,%ax
f0101e6a:	74 19                	je     f0101e85 <page_check+0x567>
f0101e6c:	68 40 64 10 f0       	push   $0xf0106440
f0101e71:	68 92 5f 10 f0       	push   $0xf0105f92
f0101e76:	68 d3 00 00 00       	push   $0xd3
f0101e7b:	68 21 5f 10 f0       	push   $0xf0105f21
f0101e80:	e8 a9 e2 ff ff       	call   f010012e <_panic>

	// pp2 should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp2);
f0101e85:	83 ec 0c             	sub    $0xc,%esp
f0101e88:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101e8b:	50                   	push   %eax
f0101e8c:	e8 9a 0b 00 00       	call   f0102a2b <allocate_frame>
f0101e91:	83 c4 10             	add    $0x10,%esp
f0101e94:	85 c0                	test   %eax,%eax
f0101e96:	75 0a                	jne    f0101ea2 <page_check+0x584>
f0101e98:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101e9b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101e9e:	39 c2                	cmp    %eax,%edx
f0101ea0:	74 19                	je     f0101ebb <page_check+0x59d>
f0101ea2:	68 58 64 10 f0       	push   $0xf0106458
f0101ea7:	68 92 5f 10 f0       	push   $0xf0105f92
f0101eac:	68 d6 00 00 00       	push   $0xd6
f0101eb1:	68 21 5f 10 f0       	push   $0xf0105f21
f0101eb6:	e8 73 e2 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at 0 should keep pp1 at PAGE_SIZE
	unmap_frame(ptr_page_directory, 0x0);
f0101ebb:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101ec0:	83 ec 08             	sub    $0x8,%esp
f0101ec3:	6a 00                	push   $0x0
f0101ec5:	50                   	push   %eax
f0101ec6:	e8 8b 0e 00 00       	call   f0102d56 <unmap_frame>
f0101ecb:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101ece:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101ed3:	83 ec 08             	sub    $0x8,%esp
f0101ed6:	6a 00                	push   $0x0
f0101ed8:	50                   	push   %eax
f0101ed9:	e8 7a f9 ff ff       	call   f0101858 <check_va2pa>
f0101ede:	83 c4 10             	add    $0x10,%esp
f0101ee1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ee4:	74 19                	je     f0101eff <page_check+0x5e1>
f0101ee6:	68 80 64 10 f0       	push   $0xf0106480
f0101eeb:	68 92 5f 10 f0       	push   $0xf0105f92
f0101ef0:	68 da 00 00 00       	push   $0xda
f0101ef5:	68 21 5f 10 f0       	push   $0xf0105f21
f0101efa:	e8 2f e2 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101eff:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101f04:	83 ec 08             	sub    $0x8,%esp
f0101f07:	68 00 10 00 00       	push   $0x1000
f0101f0c:	50                   	push   %eax
f0101f0d:	e8 46 f9 ff ff       	call   f0101858 <check_va2pa>
f0101f12:	83 c4 10             	add    $0x10,%esp
f0101f15:	89 c3                	mov    %eax,%ebx
f0101f17:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f1a:	83 ec 0c             	sub    $0xc,%esp
f0101f1d:	50                   	push   %eax
f0101f1e:	e8 ea f5 ff ff       	call   f010150d <to_physical_address>
f0101f23:	83 c4 10             	add    $0x10,%esp
f0101f26:	39 c3                	cmp    %eax,%ebx
f0101f28:	74 19                	je     f0101f43 <page_check+0x625>
f0101f2a:	68 e4 63 10 f0       	push   $0xf01063e4
f0101f2f:	68 92 5f 10 f0       	push   $0xf0105f92
f0101f34:	68 db 00 00 00       	push   $0xdb
f0101f39:	68 21 5f 10 f0       	push   $0xf0105f21
f0101f3e:	e8 eb e1 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101f43:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101f46:	8b 40 08             	mov    0x8(%eax),%eax
f0101f49:	66 83 f8 01          	cmp    $0x1,%ax
f0101f4d:	74 19                	je     f0101f68 <page_check+0x64a>
f0101f4f:	68 61 62 10 f0       	push   $0xf0106261
f0101f54:	68 92 5f 10 f0       	push   $0xf0105f92
f0101f59:	68 dc 00 00 00       	push   $0xdc
f0101f5e:	68 21 5f 10 f0       	push   $0xf0105f21
f0101f63:	e8 c6 e1 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101f68:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101f6b:	8b 40 08             	mov    0x8(%eax),%eax
f0101f6e:	66 85 c0             	test   %ax,%ax
f0101f71:	74 19                	je     f0101f8c <page_check+0x66e>
f0101f73:	68 40 64 10 f0       	push   $0xf0106440
f0101f78:	68 92 5f 10 f0       	push   $0xf0105f92
f0101f7d:	68 dd 00 00 00       	push   $0xdd
f0101f82:	68 21 5f 10 f0       	push   $0xf0105f21
f0101f87:	e8 a2 e1 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at PAGE_SIZE should free it
	unmap_frame(ptr_page_directory, (void*) PAGE_SIZE);
f0101f8c:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101f91:	83 ec 08             	sub    $0x8,%esp
f0101f94:	68 00 10 00 00       	push   $0x1000
f0101f99:	50                   	push   %eax
f0101f9a:	e8 b7 0d 00 00       	call   f0102d56 <unmap_frame>
f0101f9f:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101fa2:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101fa7:	83 ec 08             	sub    $0x8,%esp
f0101faa:	6a 00                	push   $0x0
f0101fac:	50                   	push   %eax
f0101fad:	e8 a6 f8 ff ff       	call   f0101858 <check_va2pa>
f0101fb2:	83 c4 10             	add    $0x10,%esp
f0101fb5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fb8:	74 19                	je     f0101fd3 <page_check+0x6b5>
f0101fba:	68 80 64 10 f0       	push   $0xf0106480
f0101fbf:	68 92 5f 10 f0       	push   $0xf0105f92
f0101fc4:	68 e1 00 00 00       	push   $0xe1
f0101fc9:	68 21 5f 10 f0       	push   $0xf0105f21
f0101fce:	e8 5b e1 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == ~0);
f0101fd3:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0101fd8:	83 ec 08             	sub    $0x8,%esp
f0101fdb:	68 00 10 00 00       	push   $0x1000
f0101fe0:	50                   	push   %eax
f0101fe1:	e8 72 f8 ff ff       	call   f0101858 <check_va2pa>
f0101fe6:	83 c4 10             	add    $0x10,%esp
f0101fe9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fec:	74 19                	je     f0102007 <page_check+0x6e9>
f0101fee:	68 ac 64 10 f0       	push   $0xf01064ac
f0101ff3:	68 92 5f 10 f0       	push   $0xf0105f92
f0101ff8:	68 e2 00 00 00       	push   $0xe2
f0101ffd:	68 21 5f 10 f0       	push   $0xf0105f21
f0102002:	e8 27 e1 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 0);
f0102007:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010200a:	8b 40 08             	mov    0x8(%eax),%eax
f010200d:	66 85 c0             	test   %ax,%ax
f0102010:	74 19                	je     f010202b <page_check+0x70d>
f0102012:	68 dd 64 10 f0       	push   $0xf01064dd
f0102017:	68 92 5f 10 f0       	push   $0xf0105f92
f010201c:	68 e3 00 00 00       	push   $0xe3
f0102021:	68 21 5f 10 f0       	push   $0xf0105f21
f0102026:	e8 03 e1 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f010202b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010202e:	8b 40 08             	mov    0x8(%eax),%eax
f0102031:	66 85 c0             	test   %ax,%ax
f0102034:	74 19                	je     f010204f <page_check+0x731>
f0102036:	68 40 64 10 f0       	push   $0xf0106440
f010203b:	68 92 5f 10 f0       	push   $0xf0105f92
f0102040:	68 e4 00 00 00       	push   $0xe4
f0102045:	68 21 5f 10 f0       	push   $0xf0105f21
f010204a:	e8 df e0 ff ff       	call   f010012e <_panic>

	// so it should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp1);
f010204f:	83 ec 0c             	sub    $0xc,%esp
f0102052:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102055:	50                   	push   %eax
f0102056:	e8 d0 09 00 00       	call   f0102a2b <allocate_frame>
f010205b:	83 c4 10             	add    $0x10,%esp
f010205e:	85 c0                	test   %eax,%eax
f0102060:	75 0a                	jne    f010206c <page_check+0x74e>
f0102062:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102065:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102068:	39 c2                	cmp    %eax,%edx
f010206a:	74 19                	je     f0102085 <page_check+0x767>
f010206c:	68 f4 64 10 f0       	push   $0xf01064f4
f0102071:	68 92 5f 10 f0       	push   $0xf0105f92
f0102076:	68 e7 00 00 00       	push   $0xe7
f010207b:	68 21 5f 10 f0       	push   $0xf0105f21
f0102080:	e8 a9 e0 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0102085:	83 ec 0c             	sub    $0xc,%esp
f0102088:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010208b:	50                   	push   %eax
f010208c:	e8 9a 09 00 00       	call   f0102a2b <allocate_frame>
f0102091:	83 c4 10             	add    $0x10,%esp
f0102094:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102097:	74 19                	je     f01020b2 <page_check+0x794>
f0102099:	68 5c 61 10 f0       	push   $0xf010615c
f010209e:	68 92 5f 10 f0       	push   $0xf0105f92
f01020a3:	68 ea 00 00 00       	push   $0xea
f01020a8:	68 21 5f 10 f0       	push   $0xf0105f21
f01020ad:	e8 7c e0 ff ff       	call   f010012e <_panic>

	// forcibly take pp0 back
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f01020b2:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01020b7:	8b 00                	mov    (%eax),%eax
f01020b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01020be:	89 c3                	mov    %eax,%ebx
f01020c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01020c3:	83 ec 0c             	sub    $0xc,%esp
f01020c6:	50                   	push   %eax
f01020c7:	e8 41 f4 ff ff       	call   f010150d <to_physical_address>
f01020cc:	83 c4 10             	add    $0x10,%esp
f01020cf:	39 c3                	cmp    %eax,%ebx
f01020d1:	74 19                	je     f01020ec <page_check+0x7ce>
f01020d3:	68 dc 61 10 f0       	push   $0xf01061dc
f01020d8:	68 92 5f 10 f0       	push   $0xf0105f92
f01020dd:	68 ed 00 00 00       	push   $0xed
f01020e2:	68 21 5f 10 f0       	push   $0xf0105f21
f01020e7:	e8 42 e0 ff ff       	call   f010012e <_panic>
	ptr_page_directory[0] = 0;
f01020ec:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01020f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->references == 1);
f01020f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01020fa:	8b 40 08             	mov    0x8(%eax),%eax
f01020fd:	66 83 f8 01          	cmp    $0x1,%ax
f0102101:	74 19                	je     f010211c <page_check+0x7fe>
f0102103:	68 76 62 10 f0       	push   $0xf0106276
f0102108:	68 92 5f 10 f0       	push   $0xf0105f92
f010210d:	68 ef 00 00 00       	push   $0xef
f0102112:	68 21 5f 10 f0       	push   $0xf0105f21
f0102117:	e8 12 e0 ff ff       	call   f010012e <_panic>
	pp0->references = 0;
f010211c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010211f:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	free_frame_list = fl;
f0102125:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102128:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8

	// free the frames_info we took
	free_frame(pp0);
f010212d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102130:	83 ec 0c             	sub    $0xc,%esp
f0102133:	50                   	push   %eax
f0102134:	e8 59 09 00 00       	call   f0102a92 <free_frame>
f0102139:	83 c4 10             	add    $0x10,%esp
	free_frame(pp1);
f010213c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010213f:	83 ec 0c             	sub    $0xc,%esp
f0102142:	50                   	push   %eax
f0102143:	e8 4a 09 00 00       	call   f0102a92 <free_frame>
f0102148:	83 c4 10             	add    $0x10,%esp
	free_frame(pp2);
f010214b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010214e:	83 ec 0c             	sub    $0xc,%esp
f0102151:	50                   	push   %eax
f0102152:	e8 3b 09 00 00       	call   f0102a92 <free_frame>
f0102157:	83 c4 10             	add    $0x10,%esp

	cprintf("page_check() succeeded!\n");
f010215a:	83 ec 0c             	sub    $0xc,%esp
f010215d:	68 1a 65 10 f0       	push   $0xf010651a
f0102162:	e8 75 15 00 00       	call   f01036dc <cprintf>
f0102167:	83 c4 10             	add    $0x10,%esp
}
f010216a:	90                   	nop
f010216b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010216e:	c9                   	leave  
f010216f:	c3                   	ret    

f0102170 <turn_on_paging>:

void turn_on_paging()
{
f0102170:	55                   	push   %ebp
f0102171:	89 e5                	mov    %esp,%ebp
f0102173:	83 ec 20             	sub    $0x20,%esp
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA (KERNEL_BASE), i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	ptr_page_directory[0] = ptr_page_directory[PDX(KERNEL_BASE)];
f0102176:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010217b:	8b 15 e4 f7 14 f0    	mov    0xf014f7e4,%edx
f0102181:	8b 92 00 0f 00 00    	mov    0xf00(%edx),%edx
f0102187:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(phys_page_directory);
f0102189:	a1 e8 f7 14 f0       	mov    0xf014f7e8,%eax
f010218e:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102191:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102194:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32
rcr0(void)
{
	uint32 val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102197:	0f 20 c0             	mov    %cr0,%eax
f010219a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
f010219d:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// Turn on paging.
	uint32 cr0;
	cr0 = rcr0();
f01021a0:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f01021a3:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f01021aa:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f01021ae:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01021b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static __inline void
lcr0(uint32 val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01021b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01021b7:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNEL_BASE+x => x => x.
	// (x < 4MB so uses paging ptr_page_directory[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f01021ba:	0f 01 15 90 c6 11 f0 	lgdtl  0xf011c690
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01021c1:	b8 23 00 00 00       	mov    $0x23,%eax
f01021c6:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01021c8:	b8 23 00 00 00       	mov    $0x23,%eax
f01021cd:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01021cf:	b8 10 00 00 00       	mov    $0x10,%eax
f01021d4:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01021d6:	b8 10 00 00 00       	mov    $0x10,%eax
f01021db:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01021dd:	b8 10 00 00 00       	mov    $0x10,%eax
f01021e2:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01021e4:	ea eb 21 10 f0 08 00 	ljmp   $0x8,$0xf01021eb
	asm volatile("lldt %%ax" :: "a" (0));
f01021eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01021f0:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNEL_BASE + x => KERNEL_BASE + x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	ptr_page_directory[0] = 0;
f01021f3:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01021f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the ptr_page_directory[0] mapping.
	lcr3(phys_page_directory);
f01021fe:	a1 e8 f7 14 f0       	mov    0xf014f7e8,%eax
f0102203:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102206:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102209:	0f 22 d8             	mov    %eax,%cr3
}
f010220c:	90                   	nop
f010220d:	c9                   	leave  
f010220e:	c3                   	ret    

f010220f <setup_listing_to_all_page_tables_entries>:

void setup_listing_to_all_page_tables_entries()
{
f010220f:	55                   	push   %ebp
f0102210:	89 e5                	mov    %esp,%ebp
f0102212:	83 ec 18             	sub    $0x18,%esp
	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.

	// Permissions: kernel RW, user NONE
	uint32 phys_frame_address = K_PHYSICAL_ADDRESS(ptr_page_directory);
f0102215:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010221a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010221d:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f0102224:	77 17                	ja     f010223d <setup_listing_to_all_page_tables_entries+0x2e>
f0102226:	ff 75 f4             	pushl  -0xc(%ebp)
f0102229:	68 f0 5e 10 f0       	push   $0xf0105ef0
f010222e:	68 39 01 00 00       	push   $0x139
f0102233:	68 21 5f 10 f0       	push   $0xf0105f21
f0102238:	e8 f1 de ff ff       	call   f010012e <_panic>
f010223d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102240:	05 00 00 00 10       	add    $0x10000000,%eax
f0102245:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ptr_page_directory[PDX(VPT)] = CONSTRUCT_ENTRY(phys_frame_address , PERM_PRESENT | PERM_WRITEABLE);
f0102248:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010224d:	05 fc 0e 00 00       	add    $0xefc,%eax
f0102252:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102255:	83 ca 03             	or     $0x3,%edx
f0102258:	89 10                	mov    %edx,(%eax)

	// same for UVPT
	//Permissions: kernel R, user R
	ptr_page_directory[PDX(UVPT)] = K_PHYSICAL_ADDRESS(ptr_page_directory)|PERM_USER|PERM_PRESENT;
f010225a:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010225f:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0102265:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010226a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010226d:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f0102274:	77 17                	ja     f010228d <setup_listing_to_all_page_tables_entries+0x7e>
f0102276:	ff 75 ec             	pushl  -0x14(%ebp)
f0102279:	68 f0 5e 10 f0       	push   $0xf0105ef0
f010227e:	68 3e 01 00 00       	push   $0x13e
f0102283:	68 21 5f 10 f0       	push   $0xf0105f21
f0102288:	e8 a1 de ff ff       	call   f010012e <_panic>
f010228d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102290:	05 00 00 00 10       	add    $0x10000000,%eax
f0102295:	83 c8 05             	or     $0x5,%eax
f0102298:	89 02                	mov    %eax,(%edx)

}
f010229a:	90                   	nop
f010229b:	c9                   	leave  
f010229c:	c3                   	ret    

f010229d <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int envid2env(int32  envid, struct Env **env_store, bool checkperm)
{
f010229d:	55                   	push   %ebp
f010229e:	89 e5                	mov    %esp,%ebp
f01022a0:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01022a3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01022a7:	75 15                	jne    f01022be <envid2env+0x21>
		*env_store = curenv;
f01022a9:	8b 15 50 ef 14 f0    	mov    0xf014ef50,%edx
f01022af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022b2:	89 10                	mov    %edx,(%eax)
		return 0;
f01022b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01022b9:	e9 8c 00 00 00       	jmp    f010234a <envid2env+0xad>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01022be:	8b 15 4c ef 14 f0    	mov    0xf014ef4c,%edx
f01022c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01022c7:	25 ff 03 00 00       	and    $0x3ff,%eax
f01022cc:	89 c1                	mov    %eax,%ecx
f01022ce:	89 c8                	mov    %ecx,%eax
f01022d0:	c1 e0 02             	shl    $0x2,%eax
f01022d3:	01 c8                	add    %ecx,%eax
f01022d5:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01022dc:	01 c8                	add    %ecx,%eax
f01022de:	c1 e0 02             	shl    $0x2,%eax
f01022e1:	01 d0                	add    %edx,%eax
f01022e3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01022e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01022e9:	8b 40 54             	mov    0x54(%eax),%eax
f01022ec:	85 c0                	test   %eax,%eax
f01022ee:	74 0b                	je     f01022fb <envid2env+0x5e>
f01022f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01022f3:	8b 40 4c             	mov    0x4c(%eax),%eax
f01022f6:	3b 45 08             	cmp    0x8(%ebp),%eax
f01022f9:	74 10                	je     f010230b <envid2env+0x6e>
		*env_store = 0;
f01022fb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022fe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102304:	b8 02 00 00 00       	mov    $0x2,%eax
f0102309:	eb 3f                	jmp    f010234a <envid2env+0xad>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010230b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010230f:	74 2c                	je     f010233d <envid2env+0xa0>
f0102311:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102316:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f0102319:	74 22                	je     f010233d <envid2env+0xa0>
f010231b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010231e:	8b 50 50             	mov    0x50(%eax),%edx
f0102321:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102326:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102329:	39 c2                	cmp    %eax,%edx
f010232b:	74 10                	je     f010233d <envid2env+0xa0>
		*env_store = 0;
f010232d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102330:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102336:	b8 02 00 00 00       	mov    $0x2,%eax
f010233b:	eb 0d                	jmp    f010234a <envid2env+0xad>
	}

	*env_store = e;
f010233d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102340:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0102343:	89 10                	mov    %edx,(%eax)
	return 0;
f0102345:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010234a:	c9                   	leave  
f010234b:	c3                   	ret    

f010234c <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f010234c:	55                   	push   %ebp
f010234d:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f010234f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102352:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f0102358:	29 d0                	sub    %edx,%eax
f010235a:	c1 f8 02             	sar    $0x2,%eax
f010235d:	89 c2                	mov    %eax,%edx
f010235f:	89 d0                	mov    %edx,%eax
f0102361:	c1 e0 02             	shl    $0x2,%eax
f0102364:	01 d0                	add    %edx,%eax
f0102366:	c1 e0 02             	shl    $0x2,%eax
f0102369:	01 d0                	add    %edx,%eax
f010236b:	c1 e0 02             	shl    $0x2,%eax
f010236e:	01 d0                	add    %edx,%eax
f0102370:	89 c1                	mov    %eax,%ecx
f0102372:	c1 e1 08             	shl    $0x8,%ecx
f0102375:	01 c8                	add    %ecx,%eax
f0102377:	89 c1                	mov    %eax,%ecx
f0102379:	c1 e1 10             	shl    $0x10,%ecx
f010237c:	01 c8                	add    %ecx,%eax
f010237e:	01 c0                	add    %eax,%eax
f0102380:	01 d0                	add    %edx,%eax
}
f0102382:	5d                   	pop    %ebp
f0102383:	c3                   	ret    

f0102384 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0102384:	55                   	push   %ebp
f0102385:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0102387:	ff 75 08             	pushl  0x8(%ebp)
f010238a:	e8 bd ff ff ff       	call   f010234c <to_frame_number>
f010238f:	83 c4 04             	add    $0x4,%esp
f0102392:	c1 e0 0c             	shl    $0xc,%eax
}
f0102395:	c9                   	leave  
f0102396:	c3                   	ret    

f0102397 <to_frame_info>:

static inline struct Frame_Info* to_frame_info(uint32 physical_address)
{
f0102397:	55                   	push   %ebp
f0102398:	89 e5                	mov    %esp,%ebp
f010239a:	83 ec 08             	sub    $0x8,%esp
	if (PPN(physical_address) >= number_of_frames)
f010239d:	8b 45 08             	mov    0x8(%ebp),%eax
f01023a0:	c1 e8 0c             	shr    $0xc,%eax
f01023a3:	89 c2                	mov    %eax,%edx
f01023a5:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f01023aa:	39 c2                	cmp    %eax,%edx
f01023ac:	72 14                	jb     f01023c2 <to_frame_info+0x2b>
		panic("to_frame_info called with invalid pa");
f01023ae:	83 ec 04             	sub    $0x4,%esp
f01023b1:	68 34 65 10 f0       	push   $0xf0106534
f01023b6:	6a 39                	push   $0x39
f01023b8:	68 59 65 10 f0       	push   $0xf0106559
f01023bd:	e8 6c dd ff ff       	call   f010012e <_panic>
	return &frames_info[PPN(physical_address)];
f01023c2:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f01023c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01023cb:	c1 e8 0c             	shr    $0xc,%eax
f01023ce:	89 c1                	mov    %eax,%ecx
f01023d0:	89 c8                	mov    %ecx,%eax
f01023d2:	01 c0                	add    %eax,%eax
f01023d4:	01 c8                	add    %ecx,%eax
f01023d6:	c1 e0 02             	shl    $0x2,%eax
f01023d9:	01 d0                	add    %edx,%eax
}
f01023db:	c9                   	leave  
f01023dc:	c3                   	ret    

f01023dd <initialize_kernel_VM>:
//
// From USER_TOP to USER_LIMIT, the user is allowed to read but not write.
// Above USER_LIMIT the user cannot read (or write).

void initialize_kernel_VM()
{
f01023dd:	55                   	push   %ebp
f01023de:	89 e5                	mov    %esp,%ebp
f01023e0:	83 ec 28             	sub    $0x28,%esp
	//panic("initialize_kernel_VM: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	ptr_page_directory = boot_allocate_space(PAGE_SIZE, PAGE_SIZE);
f01023e3:	83 ec 08             	sub    $0x8,%esp
f01023e6:	68 00 10 00 00       	push   $0x1000
f01023eb:	68 00 10 00 00       	push   $0x1000
f01023f0:	e8 ca 01 00 00       	call   f01025bf <boot_allocate_space>
f01023f5:	83 c4 10             	add    $0x10,%esp
f01023f8:	a3 e4 f7 14 f0       	mov    %eax,0xf014f7e4
	memset(ptr_page_directory, 0, PAGE_SIZE);
f01023fd:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102402:	83 ec 04             	sub    $0x4,%esp
f0102405:	68 00 10 00 00       	push   $0x1000
f010240a:	6a 00                	push   $0x0
f010240c:	50                   	push   %eax
f010240d:	e8 ad 29 00 00       	call   f0104dbf <memset>
f0102412:	83 c4 10             	add    $0x10,%esp
	phys_page_directory = K_PHYSICAL_ADDRESS(ptr_page_directory);
f0102415:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010241a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010241d:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f0102424:	77 14                	ja     f010243a <initialize_kernel_VM+0x5d>
f0102426:	ff 75 f4             	pushl  -0xc(%ebp)
f0102429:	68 74 65 10 f0       	push   $0xf0106574
f010242e:	6a 3c                	push   $0x3c
f0102430:	68 a5 65 10 f0       	push   $0xf01065a5
f0102435:	e8 f4 dc ff ff       	call   f010012e <_panic>
f010243a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010243d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102442:	a3 e8 f7 14 f0       	mov    %eax,0xf014f7e8
	// Map the kernel stack with VA range :
	//  [KERNEL_STACK_TOP-KERNEL_STACK_SIZE, KERNEL_STACK_TOP), 
	// to physical address : "phys_stack_bottom".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_range(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE, KERNEL_STACK_SIZE, K_PHYSICAL_ADDRESS(ptr_stack_bottom), PERM_WRITEABLE) ;
f0102447:	c7 45 f0 00 40 11 f0 	movl   $0xf0114000,-0x10(%ebp)
f010244e:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0102455:	77 14                	ja     f010246b <initialize_kernel_VM+0x8e>
f0102457:	ff 75 f0             	pushl  -0x10(%ebp)
f010245a:	68 74 65 10 f0       	push   $0xf0106574
f010245f:	6a 44                	push   $0x44
f0102461:	68 a5 65 10 f0       	push   $0xf01065a5
f0102466:	e8 c3 dc ff ff       	call   f010012e <_panic>
f010246b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010246e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102474:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102479:	83 ec 0c             	sub    $0xc,%esp
f010247c:	6a 02                	push   $0x2
f010247e:	52                   	push   %edx
f010247f:	68 00 80 00 00       	push   $0x8000
f0102484:	68 00 80 bf ef       	push   $0xefbf8000
f0102489:	50                   	push   %eax
f010248a:	e8 92 01 00 00       	call   f0102621 <boot_map_range>
f010248f:	83 c4 20             	add    $0x20,%esp
	//      the PA range [0, 2^32 - KERNEL_BASE)
	// We might not have 2^32 - KERNEL_BASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_range(ptr_page_directory, KERNEL_BASE, 0xFFFFFFFF - KERNEL_BASE, 0, PERM_WRITEABLE) ;
f0102492:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102497:	83 ec 0c             	sub    $0xc,%esp
f010249a:	6a 02                	push   $0x2
f010249c:	6a 00                	push   $0x0
f010249e:	68 ff ff ff 0f       	push   $0xfffffff
f01024a3:	68 00 00 00 f0       	push   $0xf0000000
f01024a8:	50                   	push   %eax
f01024a9:	e8 73 01 00 00       	call   f0102621 <boot_map_range>
f01024ae:	83 c4 20             	add    $0x20,%esp
	// Permissions:
	//    - frames_info -- kernel RW, user NONE
	//    - the image mapped at READ_ONLY_FRAMES_INFO  -- kernel R, user R
	// Your code goes here:
	uint32 array_size;
	array_size = number_of_frames * sizeof(struct Frame_Info) ;
f01024b1:	8b 15 c8 f7 14 f0    	mov    0xf014f7c8,%edx
f01024b7:	89 d0                	mov    %edx,%eax
f01024b9:	01 c0                	add    %eax,%eax
f01024bb:	01 d0                	add    %edx,%eax
f01024bd:	c1 e0 02             	shl    $0x2,%eax
f01024c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	frames_info = boot_allocate_space(array_size, PAGE_SIZE);
f01024c3:	83 ec 08             	sub    $0x8,%esp
f01024c6:	68 00 10 00 00       	push   $0x1000
f01024cb:	ff 75 ec             	pushl  -0x14(%ebp)
f01024ce:	e8 ec 00 00 00       	call   f01025bf <boot_allocate_space>
f01024d3:	83 c4 10             	add    $0x10,%esp
f01024d6:	a3 dc f7 14 f0       	mov    %eax,0xf014f7dc
	boot_map_range(ptr_page_directory, READ_ONLY_FRAMES_INFO, array_size, K_PHYSICAL_ADDRESS(frames_info), PERM_USER) ;
f01024db:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f01024e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01024e3:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f01024ea:	77 14                	ja     f0102500 <initialize_kernel_VM+0x123>
f01024ec:	ff 75 e8             	pushl  -0x18(%ebp)
f01024ef:	68 74 65 10 f0       	push   $0xf0106574
f01024f4:	6a 5f                	push   $0x5f
f01024f6:	68 a5 65 10 f0       	push   $0xf01065a5
f01024fb:	e8 2e dc ff ff       	call   f010012e <_panic>
f0102500:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102503:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102509:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010250e:	83 ec 0c             	sub    $0xc,%esp
f0102511:	6a 04                	push   $0x4
f0102513:	52                   	push   %edx
f0102514:	ff 75 ec             	pushl  -0x14(%ebp)
f0102517:	68 00 00 00 ef       	push   $0xef000000
f010251c:	50                   	push   %eax
f010251d:	e8 ff 00 00 00       	call   f0102621 <boot_map_range>
f0102522:	83 c4 20             	add    $0x20,%esp


	// This allows the kernel & user to access any page table entry using a
	// specified VA for each: VPT for kernel and UVPT for User.
	setup_listing_to_all_page_tables_entries();
f0102525:	e8 e5 fc ff ff       	call   f010220f <setup_listing_to_all_page_tables_entries>
	// Permissions:
	//    - envs itself -- kernel RW, user NONE
	//    - the image of envs mapped at UENVS  -- kernel R, user R

	// LAB 3: Your code here.
	int envs_size = NENV * sizeof(struct Env) ;
f010252a:	c7 45 e4 00 90 01 00 	movl   $0x19000,-0x1c(%ebp)

	//allocate space for "envs" array aligned on 4KB boundary
	envs = boot_allocate_space(envs_size, PAGE_SIZE);
f0102531:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102534:	83 ec 08             	sub    $0x8,%esp
f0102537:	68 00 10 00 00       	push   $0x1000
f010253c:	50                   	push   %eax
f010253d:	e8 7d 00 00 00       	call   f01025bf <boot_allocate_space>
f0102542:	83 c4 10             	add    $0x10,%esp
f0102545:	a3 4c ef 14 f0       	mov    %eax,0xf014ef4c

	//make the user to access this array by mapping it to UPAGES linear address (UPAGES is in User/Kernel space)
	boot_map_range(ptr_page_directory, UENVS, envs_size, K_PHYSICAL_ADDRESS(envs), PERM_USER) ;
f010254a:	a1 4c ef 14 f0       	mov    0xf014ef4c,%eax
f010254f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102552:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0102559:	77 14                	ja     f010256f <initialize_kernel_VM+0x192>
f010255b:	ff 75 e0             	pushl  -0x20(%ebp)
f010255e:	68 74 65 10 f0       	push   $0xf0106574
f0102563:	6a 75                	push   $0x75
f0102565:	68 a5 65 10 f0       	push   $0xf01065a5
f010256a:	e8 bf db ff ff       	call   f010012e <_panic>
f010256f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102572:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0102578:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010257b:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f0102580:	83 ec 0c             	sub    $0xc,%esp
f0102583:	6a 04                	push   $0x4
f0102585:	51                   	push   %ecx
f0102586:	52                   	push   %edx
f0102587:	68 00 00 c0 ee       	push   $0xeec00000
f010258c:	50                   	push   %eax
f010258d:	e8 8f 00 00 00       	call   f0102621 <boot_map_range>
f0102592:	83 c4 20             	add    $0x20,%esp

	//update permissions of the corresponding entry in page directory to make it USER with PERMISSION read only
	ptr_page_directory[PDX(UENVS)] = ptr_page_directory[PDX(UENVS)]|(PERM_USER|(PERM_PRESENT & (~PERM_WRITEABLE)));
f0102595:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f010259a:	05 ec 0e 00 00       	add    $0xeec,%eax
f010259f:	8b 15 e4 f7 14 f0    	mov    0xf014f7e4,%edx
f01025a5:	81 c2 ec 0e 00 00    	add    $0xeec,%edx
f01025ab:	8b 12                	mov    (%edx),%edx
f01025ad:	83 ca 05             	or     $0x5,%edx
f01025b0:	89 10                	mov    %edx,(%eax)


	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f01025b2:	e8 52 f0 ff ff       	call   f0101609 <check_boot_pgdir>

	// NOW: Turn off the segmentation by setting the segments' base to 0, and
	// turn on the paging by setting the corresponding flags in control register 0 (cr0)
	turn_on_paging() ;
f01025b7:	e8 b4 fb ff ff       	call   f0102170 <turn_on_paging>
}
f01025bc:	90                   	nop
f01025bd:	c9                   	leave  
f01025be:	c3                   	ret    

f01025bf <boot_allocate_space>:
// It's too early to run out of memory.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
// 
void* boot_allocate_space(uint32 size, uint32 align)
		{
f01025bf:	55                   	push   %ebp
f01025c0:	89 e5                	mov    %esp,%ebp
f01025c2:	83 ec 10             	sub    $0x10,%esp
	// Initialize ptr_free_mem if this is the first time.
	// 'end_of_kernel' is a symbol automatically generated by the linker,
	// which points to the end of the kernel-
	// i.e., the first virtual address that the linker
	// did not assign to any kernel code or global variables.
	if (ptr_free_mem == 0)
f01025c5:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f01025ca:	85 c0                	test   %eax,%eax
f01025cc:	75 0a                	jne    f01025d8 <boot_allocate_space+0x19>
		ptr_free_mem = end_of_kernel;
f01025ce:	c7 05 e0 f7 14 f0 ec 	movl   $0xf014f7ec,0xf014f7e0
f01025d5:	f7 14 f0 

	// Your code here:
	//	Step 1: round ptr_free_mem up to be aligned properly
	ptr_free_mem = ROUNDUP(ptr_free_mem, PAGE_SIZE) ;
f01025d8:	c7 45 fc 00 10 00 00 	movl   $0x1000,-0x4(%ebp)
f01025df:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f01025e4:	89 c2                	mov    %eax,%edx
f01025e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01025e9:	01 d0                	add    %edx,%eax
f01025eb:	48                   	dec    %eax
f01025ec:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01025ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01025f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01025f7:	f7 75 fc             	divl   -0x4(%ebp)
f01025fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01025fd:	29 d0                	sub    %edx,%eax
f01025ff:	a3 e0 f7 14 f0       	mov    %eax,0xf014f7e0

	//	Step 2: save current value of ptr_free_mem as allocated space
	void *ptr_allocated_mem;
	ptr_allocated_mem = ptr_free_mem ;
f0102604:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f0102609:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//	Step 3: increase ptr_free_mem to record allocation
	ptr_free_mem += size ;
f010260c:	8b 15 e0 f7 14 f0    	mov    0xf014f7e0,%edx
f0102612:	8b 45 08             	mov    0x8(%ebp),%eax
f0102615:	01 d0                	add    %edx,%eax
f0102617:	a3 e0 f7 14 f0       	mov    %eax,0xf014f7e0

	//	Step 4: return allocated space
	return ptr_allocated_mem ;
f010261c:	8b 45 f4             	mov    -0xc(%ebp),%eax

		}
f010261f:	c9                   	leave  
f0102620:	c3                   	ret    

f0102621 <boot_map_range>:
//
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
f0102621:	55                   	push   %ebp
f0102622:	89 e5                	mov    %esp,%ebp
f0102624:	83 ec 28             	sub    $0x28,%esp
	int i = 0 ;
f0102627:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
f010262e:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0102635:	8b 55 14             	mov    0x14(%ebp),%edx
f0102638:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010263b:	01 d0                	add    %edx,%eax
f010263d:	48                   	dec    %eax
f010263e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102641:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102644:	ba 00 00 00 00       	mov    $0x0,%edx
f0102649:	f7 75 f0             	divl   -0x10(%ebp)
f010264c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010264f:	29 d0                	sub    %edx,%eax
f0102651:	89 45 14             	mov    %eax,0x14(%ebp)
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f0102654:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010265b:	eb 53                	jmp    f01026b0 <boot_map_range+0x8f>
	{
		uint32 *ptr_page_table = boot_get_page_table(ptr_page_directory, virtual_address, 1) ;
f010265d:	83 ec 04             	sub    $0x4,%esp
f0102660:	6a 01                	push   $0x1
f0102662:	ff 75 0c             	pushl  0xc(%ebp)
f0102665:	ff 75 08             	pushl  0x8(%ebp)
f0102668:	e8 4e 00 00 00       	call   f01026bb <boot_get_page_table>
f010266d:	83 c4 10             	add    $0x10,%esp
f0102670:	89 45 e8             	mov    %eax,-0x18(%ebp)
		uint32 index_page_table = PTX(virtual_address);
f0102673:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102676:	c1 e8 0c             	shr    $0xc,%eax
f0102679:	25 ff 03 00 00       	and    $0x3ff,%eax
f010267e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
f0102681:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102684:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010268b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010268e:	01 c2                	add    %eax,%edx
f0102690:	8b 45 18             	mov    0x18(%ebp),%eax
f0102693:	0b 45 14             	or     0x14(%ebp),%eax
f0102696:	83 c8 01             	or     $0x1,%eax
f0102699:	89 02                	mov    %eax,(%edx)
		physical_address += PAGE_SIZE ;
f010269b:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
		virtual_address += PAGE_SIZE ;
f01026a2:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
	int i = 0 ;
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f01026a9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01026b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026b3:	3b 45 10             	cmp    0x10(%ebp),%eax
f01026b6:	72 a5                	jb     f010265d <boot_map_range+0x3c>
		uint32 index_page_table = PTX(virtual_address);
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
		physical_address += PAGE_SIZE ;
		virtual_address += PAGE_SIZE ;
	}
}
f01026b8:	90                   	nop
f01026b9:	c9                   	leave  
f01026ba:	c3                   	ret    

f01026bb <boot_get_page_table>:
// boot_get_page_table cannot fail.  It's too early to fail.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
uint32* boot_get_page_table(uint32 *ptr_page_directory, uint32 virtual_address, int create)
		{
f01026bb:	55                   	push   %ebp
f01026bc:	89 e5                	mov    %esp,%ebp
f01026be:	83 ec 28             	sub    $0x28,%esp
	uint32 index_page_directory = PDX(virtual_address);
f01026c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026c4:	c1 e8 16             	shr    $0x16,%eax
f01026c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 page_directory_entry = ptr_page_directory[index_page_directory];
f01026ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026cd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01026d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01026d7:	01 d0                	add    %edx,%eax
f01026d9:	8b 00                	mov    (%eax),%eax
f01026db:	89 45 f0             	mov    %eax,-0x10(%ebp)

	uint32 phys_page_table = EXTRACT_ADDRESS(page_directory_entry);
f01026de:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01026e1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table);
f01026e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01026ec:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01026ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01026f2:	c1 e8 0c             	shr    $0xc,%eax
f01026f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01026f8:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f01026fd:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0102700:	72 17                	jb     f0102719 <boot_get_page_table+0x5e>
f0102702:	ff 75 e8             	pushl  -0x18(%ebp)
f0102705:	68 bc 65 10 f0       	push   $0xf01065bc
f010270a:	68 db 00 00 00       	push   $0xdb
f010270f:	68 a5 65 10 f0       	push   $0xf01065a5
f0102714:	e8 15 da ff ff       	call   f010012e <_panic>
f0102719:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010271c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102721:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (phys_page_table == 0)
f0102724:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102728:	75 72                	jne    f010279c <boot_get_page_table+0xe1>
	{
		if (create)
f010272a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010272e:	74 65                	je     f0102795 <boot_get_page_table+0xda>
		{
			ptr_page_table = boot_allocate_space(PAGE_SIZE, PAGE_SIZE) ;
f0102730:	83 ec 08             	sub    $0x8,%esp
f0102733:	68 00 10 00 00       	push   $0x1000
f0102738:	68 00 10 00 00       	push   $0x1000
f010273d:	e8 7d fe ff ff       	call   f01025bf <boot_allocate_space>
f0102742:	83 c4 10             	add    $0x10,%esp
f0102745:	89 45 e0             	mov    %eax,-0x20(%ebp)
			phys_page_table = K_PHYSICAL_ADDRESS(ptr_page_table);
f0102748:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010274b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010274e:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f0102755:	77 17                	ja     f010276e <boot_get_page_table+0xb3>
f0102757:	ff 75 dc             	pushl  -0x24(%ebp)
f010275a:	68 74 65 10 f0       	push   $0xf0106574
f010275f:	68 e1 00 00 00       	push   $0xe1
f0102764:	68 a5 65 10 f0       	push   $0xf01065a5
f0102769:	e8 c0 d9 ff ff       	call   f010012e <_panic>
f010276e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102771:	05 00 00 00 10       	add    $0x10000000,%eax
f0102776:	89 45 ec             	mov    %eax,-0x14(%ebp)
			ptr_page_directory[index_page_directory] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_WRITEABLE);
f0102779:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010277c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102783:	8b 45 08             	mov    0x8(%ebp),%eax
f0102786:	01 d0                	add    %edx,%eax
f0102788:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010278b:	83 ca 03             	or     $0x3,%edx
f010278e:	89 10                	mov    %edx,(%eax)
			return ptr_page_table ;
f0102790:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102793:	eb 0a                	jmp    f010279f <boot_get_page_table+0xe4>
		}
		else
			return 0 ;
f0102795:	b8 00 00 00 00       	mov    $0x0,%eax
f010279a:	eb 03                	jmp    f010279f <boot_get_page_table+0xe4>
	}
	return ptr_page_table ;
f010279c:	8b 45 e0             	mov    -0x20(%ebp),%eax
		}
f010279f:	c9                   	leave  
f01027a0:	c3                   	ret    

f01027a1 <initialize_paging>:
// After this point, ONLY use the functions below
// to allocate and deallocate physical memory via the free_frame_list,
// and NEVER use boot_allocate_space() or the related boot-time functions above.
//
void initialize_paging()
{
f01027a1:	55                   	push   %ebp
f01027a2:	89 e5                	mov    %esp,%ebp
f01027a4:	53                   	push   %ebx
f01027a5:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which frames are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&free_frame_list);
f01027a8:	c7 05 d8 f7 14 f0 00 	movl   $0x0,0xf014f7d8
f01027af:	00 00 00 

	frames_info[0].references = 1;
f01027b2:	a1 dc f7 14 f0       	mov    0xf014f7dc,%eax
f01027b7:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);
f01027bd:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01027c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027c7:	05 ff ff 09 00       	add    $0x9ffff,%eax
f01027cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01027d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01027d7:	f7 75 f0             	divl   -0x10(%ebp)
f01027da:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01027dd:	29 d0                	sub    %edx,%eax
f01027df:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f01027e2:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f01027e9:	e9 90 00 00 00       	jmp    f010287e <initialize_paging+0xdd>
	{
		frames_info[i].references = 0;
f01027ee:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01027f4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01027f7:	89 d0                	mov    %edx,%eax
f01027f9:	01 c0                	add    %eax,%eax
f01027fb:	01 d0                	add    %edx,%eax
f01027fd:	c1 e0 02             	shl    $0x2,%eax
f0102800:	01 c8                	add    %ecx,%eax
f0102802:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f0102808:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f010280e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102811:	89 d0                	mov    %edx,%eax
f0102813:	01 c0                	add    %eax,%eax
f0102815:	01 d0                	add    %edx,%eax
f0102817:	c1 e0 02             	shl    $0x2,%eax
f010281a:	01 c8                	add    %ecx,%eax
f010281c:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102822:	89 10                	mov    %edx,(%eax)
f0102824:	8b 00                	mov    (%eax),%eax
f0102826:	85 c0                	test   %eax,%eax
f0102828:	74 1d                	je     f0102847 <initialize_paging+0xa6>
f010282a:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102830:	8b 1d dc f7 14 f0    	mov    0xf014f7dc,%ebx
f0102836:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0102839:	89 c8                	mov    %ecx,%eax
f010283b:	01 c0                	add    %eax,%eax
f010283d:	01 c8                	add    %ecx,%eax
f010283f:	c1 e0 02             	shl    $0x2,%eax
f0102842:	01 d8                	add    %ebx,%eax
f0102844:	89 42 04             	mov    %eax,0x4(%edx)
f0102847:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f010284d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102850:	89 d0                	mov    %edx,%eax
f0102852:	01 c0                	add    %eax,%eax
f0102854:	01 d0                	add    %edx,%eax
f0102856:	c1 e0 02             	shl    $0x2,%eax
f0102859:	01 c8                	add    %ecx,%eax
f010285b:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f0102860:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102866:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102869:	89 d0                	mov    %edx,%eax
f010286b:	01 c0                	add    %eax,%eax
f010286d:	01 d0                	add    %edx,%eax
f010286f:	c1 e0 02             	shl    $0x2,%eax
f0102872:	01 c8                	add    %ecx,%eax
f0102874:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)

	frames_info[0].references = 1;

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f010287b:	ff 45 f4             	incl   -0xc(%ebp)
f010287e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102881:	85 c0                	test   %eax,%eax
f0102883:	79 05                	jns    f010288a <initialize_paging+0xe9>
f0102885:	05 ff 0f 00 00       	add    $0xfff,%eax
f010288a:	c1 f8 0c             	sar    $0xc,%eax
f010288d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102890:	0f 8f 58 ff ff ff    	jg     f01027ee <initialize_paging+0x4d>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f0102896:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
f010289d:	eb 1d                	jmp    f01028bc <initialize_paging+0x11b>
	{
		frames_info[i].references = 1;
f010289f:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01028a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01028a8:	89 d0                	mov    %edx,%eax
f01028aa:	01 c0                	add    %eax,%eax
f01028ac:	01 d0                	add    %edx,%eax
f01028ae:	c1 e0 02             	shl    $0x2,%eax
f01028b1:	01 c8                	add    %ecx,%eax
f01028b3:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f01028b9:	ff 45 f4             	incl   -0xc(%ebp)
f01028bc:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
f01028c3:	7e da                	jle    f010289f <initialize_paging+0xfe>
	{
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);
f01028c5:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f01028cc:	a1 e0 f7 14 f0       	mov    0xf014f7e0,%eax
f01028d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01028d4:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01028db:	77 17                	ja     f01028f4 <initialize_paging+0x153>
f01028dd:	ff 75 e0             	pushl  -0x20(%ebp)
f01028e0:	68 74 65 10 f0       	push   $0xf0106574
f01028e5:	68 1e 01 00 00       	push   $0x11e
f01028ea:	68 a5 65 10 f0       	push   $0xf01065a5
f01028ef:	e8 3a d8 ff ff       	call   f010012e <_panic>
f01028f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028f7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01028fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102900:	01 d0                	add    %edx,%eax
f0102902:	48                   	dec    %eax
f0102903:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102906:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102909:	ba 00 00 00 00       	mov    $0x0,%edx
f010290e:	f7 75 e4             	divl   -0x1c(%ebp)
f0102911:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102914:	29 d0                	sub    %edx,%eax
f0102916:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f0102919:	c7 45 f4 00 01 00 00 	movl   $0x100,-0xc(%ebp)
f0102920:	eb 1d                	jmp    f010293f <initialize_paging+0x19e>
	{
		frames_info[i].references = 1;
f0102922:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102928:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010292b:	89 d0                	mov    %edx,%eax
f010292d:	01 c0                	add    %eax,%eax
f010292f:	01 d0                	add    %edx,%eax
f0102931:	c1 e0 02             	shl    $0x2,%eax
f0102934:	01 c8                	add    %ecx,%eax
f0102936:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f010293c:	ff 45 f4             	incl   -0xc(%ebp)
f010293f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102942:	85 c0                	test   %eax,%eax
f0102944:	79 05                	jns    f010294b <initialize_paging+0x1aa>
f0102946:	05 ff 0f 00 00       	add    $0xfff,%eax
f010294b:	c1 f8 0c             	sar    $0xc,%eax
f010294e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102951:	7f cf                	jg     f0102922 <initialize_paging+0x181>
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f0102953:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102956:	85 c0                	test   %eax,%eax
f0102958:	79 05                	jns    f010295f <initialize_paging+0x1be>
f010295a:	05 ff 0f 00 00       	add    $0xfff,%eax
f010295f:	c1 f8 0c             	sar    $0xc,%eax
f0102962:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102965:	e9 90 00 00 00       	jmp    f01029fa <initialize_paging+0x259>
	{
		frames_info[i].references = 0;
f010296a:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f0102970:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102973:	89 d0                	mov    %edx,%eax
f0102975:	01 c0                	add    %eax,%eax
f0102977:	01 d0                	add    %edx,%eax
f0102979:	c1 e0 02             	shl    $0x2,%eax
f010297c:	01 c8                	add    %ecx,%eax
f010297e:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f0102984:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f010298a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010298d:	89 d0                	mov    %edx,%eax
f010298f:	01 c0                	add    %eax,%eax
f0102991:	01 d0                	add    %edx,%eax
f0102993:	c1 e0 02             	shl    $0x2,%eax
f0102996:	01 c8                	add    %ecx,%eax
f0102998:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f010299e:	89 10                	mov    %edx,(%eax)
f01029a0:	8b 00                	mov    (%eax),%eax
f01029a2:	85 c0                	test   %eax,%eax
f01029a4:	74 1d                	je     f01029c3 <initialize_paging+0x222>
f01029a6:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f01029ac:	8b 1d dc f7 14 f0    	mov    0xf014f7dc,%ebx
f01029b2:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f01029b5:	89 c8                	mov    %ecx,%eax
f01029b7:	01 c0                	add    %eax,%eax
f01029b9:	01 c8                	add    %ecx,%eax
f01029bb:	c1 e0 02             	shl    $0x2,%eax
f01029be:	01 d8                	add    %ebx,%eax
f01029c0:	89 42 04             	mov    %eax,0x4(%edx)
f01029c3:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01029c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01029cc:	89 d0                	mov    %edx,%eax
f01029ce:	01 c0                	add    %eax,%eax
f01029d0:	01 d0                	add    %edx,%eax
f01029d2:	c1 e0 02             	shl    $0x2,%eax
f01029d5:	01 c8                	add    %ecx,%eax
f01029d7:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f01029dc:	8b 0d dc f7 14 f0    	mov    0xf014f7dc,%ecx
f01029e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01029e5:	89 d0                	mov    %edx,%eax
f01029e7:	01 c0                	add    %eax,%eax
f01029e9:	01 d0                	add    %edx,%eax
f01029eb:	c1 e0 02             	shl    $0x2,%eax
f01029ee:	01 c8                	add    %ecx,%eax
f01029f0:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)
	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f01029f7:	ff 45 f4             	incl   -0xc(%ebp)
f01029fa:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01029fd:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0102a02:	39 c2                	cmp    %eax,%edx
f0102a04:	0f 82 60 ff ff ff    	jb     f010296a <initialize_paging+0x1c9>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}
}
f0102a0a:	90                   	nop
f0102a0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a0e:	c9                   	leave  
f0102a0f:	c3                   	ret    

f0102a10 <initialize_frame_info>:
// Initialize a Frame_Info structure.
// The result has null links and 0 references.
// Note that the corresponding physical frame is NOT initialized!
//
void initialize_frame_info(struct Frame_Info *ptr_frame_info)
{
f0102a10:	55                   	push   %ebp
f0102a11:	89 e5                	mov    %esp,%ebp
f0102a13:	83 ec 08             	sub    $0x8,%esp
	memset(ptr_frame_info, 0, sizeof(*ptr_frame_info));
f0102a16:	83 ec 04             	sub    $0x4,%esp
f0102a19:	6a 0c                	push   $0xc
f0102a1b:	6a 00                	push   $0x0
f0102a1d:	ff 75 08             	pushl  0x8(%ebp)
f0102a20:	e8 9a 23 00 00       	call   f0104dbf <memset>
f0102a25:	83 c4 10             	add    $0x10,%esp
}
f0102a28:	90                   	nop
f0102a29:	c9                   	leave  
f0102a2a:	c3                   	ret    

f0102a2b <allocate_frame>:
//   E_NO_MEM -- otherwise
//
// Hint: use LIST_FIRST, LIST_REMOVE, and initialize_frame_info
// Hint: references should not be incremented
int allocate_frame(struct Frame_Info **ptr_frame_info)
{
f0102a2b:	55                   	push   %ebp
f0102a2c:	89 e5                	mov    %esp,%ebp
f0102a2e:	83 ec 08             	sub    $0x8,%esp
	// Fill this function in	
	*ptr_frame_info = LIST_FIRST(&free_frame_list);
f0102a31:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102a37:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a3a:	89 10                	mov    %edx,(%eax)
	if(*ptr_frame_info == NULL)
f0102a3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a3f:	8b 00                	mov    (%eax),%eax
f0102a41:	85 c0                	test   %eax,%eax
f0102a43:	75 07                	jne    f0102a4c <allocate_frame+0x21>
		return E_NO_MEM;
f0102a45:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102a4a:	eb 44                	jmp    f0102a90 <allocate_frame+0x65>

	LIST_REMOVE(*ptr_frame_info);
f0102a4c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a4f:	8b 00                	mov    (%eax),%eax
f0102a51:	8b 00                	mov    (%eax),%eax
f0102a53:	85 c0                	test   %eax,%eax
f0102a55:	74 12                	je     f0102a69 <allocate_frame+0x3e>
f0102a57:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a5a:	8b 00                	mov    (%eax),%eax
f0102a5c:	8b 00                	mov    (%eax),%eax
f0102a5e:	8b 55 08             	mov    0x8(%ebp),%edx
f0102a61:	8b 12                	mov    (%edx),%edx
f0102a63:	8b 52 04             	mov    0x4(%edx),%edx
f0102a66:	89 50 04             	mov    %edx,0x4(%eax)
f0102a69:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a6c:	8b 00                	mov    (%eax),%eax
f0102a6e:	8b 40 04             	mov    0x4(%eax),%eax
f0102a71:	8b 55 08             	mov    0x8(%ebp),%edx
f0102a74:	8b 12                	mov    (%edx),%edx
f0102a76:	8b 12                	mov    (%edx),%edx
f0102a78:	89 10                	mov    %edx,(%eax)
	initialize_frame_info(*ptr_frame_info);
f0102a7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a7d:	8b 00                	mov    (%eax),%eax
f0102a7f:	83 ec 0c             	sub    $0xc,%esp
f0102a82:	50                   	push   %eax
f0102a83:	e8 88 ff ff ff       	call   f0102a10 <initialize_frame_info>
f0102a88:	83 c4 10             	add    $0x10,%esp
	return 0;
f0102a8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a90:	c9                   	leave  
f0102a91:	c3                   	ret    

f0102a92 <free_frame>:
//
// Return a frame to the free_frame_list.
// (This function should only be called when ptr_frame_info->references reaches 0.)
//
void free_frame(struct Frame_Info *ptr_frame_info)
{
f0102a92:	55                   	push   %ebp
f0102a93:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	LIST_INSERT_HEAD(&free_frame_list, ptr_frame_info);
f0102a95:	8b 15 d8 f7 14 f0    	mov    0xf014f7d8,%edx
f0102a9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a9e:	89 10                	mov    %edx,(%eax)
f0102aa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aa3:	8b 00                	mov    (%eax),%eax
f0102aa5:	85 c0                	test   %eax,%eax
f0102aa7:	74 0b                	je     f0102ab4 <free_frame+0x22>
f0102aa9:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0102aae:	8b 55 08             	mov    0x8(%ebp),%edx
f0102ab1:	89 50 04             	mov    %edx,0x4(%eax)
f0102ab4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ab7:	a3 d8 f7 14 f0       	mov    %eax,0xf014f7d8
f0102abc:	8b 45 08             	mov    0x8(%ebp),%eax
f0102abf:	c7 40 04 d8 f7 14 f0 	movl   $0xf014f7d8,0x4(%eax)
}
f0102ac6:	90                   	nop
f0102ac7:	5d                   	pop    %ebp
f0102ac8:	c3                   	ret    

f0102ac9 <decrement_references>:
//
// Decrement the reference count on a frame
// freeing it if there are no more references.
//
void decrement_references(struct Frame_Info* ptr_frame_info)
{
f0102ac9:	55                   	push   %ebp
f0102aca:	89 e5                	mov    %esp,%ebp
	if (--(ptr_frame_info->references) == 0)
f0102acc:	8b 45 08             	mov    0x8(%ebp),%eax
f0102acf:	8b 40 08             	mov    0x8(%eax),%eax
f0102ad2:	48                   	dec    %eax
f0102ad3:	8b 55 08             	mov    0x8(%ebp),%edx
f0102ad6:	66 89 42 08          	mov    %ax,0x8(%edx)
f0102ada:	8b 45 08             	mov    0x8(%ebp),%eax
f0102add:	8b 40 08             	mov    0x8(%eax),%eax
f0102ae0:	66 85 c0             	test   %ax,%ax
f0102ae3:	75 0b                	jne    f0102af0 <decrement_references+0x27>
		free_frame(ptr_frame_info);
f0102ae5:	ff 75 08             	pushl  0x8(%ebp)
f0102ae8:	e8 a5 ff ff ff       	call   f0102a92 <free_frame>
f0102aed:	83 c4 04             	add    $0x4,%esp
}
f0102af0:	90                   	nop
f0102af1:	c9                   	leave  
f0102af2:	c3                   	ret    

f0102af3 <get_page_table>:
//
// Hint: you can use "to_physical_address()" to turn a Frame_Info*
// into the physical address of the frame it refers to. 

int get_page_table(uint32 *ptr_page_directory, const void *virtual_address, int create, uint32 **ptr_page_table)
{
f0102af3:	55                   	push   %ebp
f0102af4:	89 e5                	mov    %esp,%ebp
f0102af6:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	uint32 page_directory_entry = ptr_page_directory[PDX(virtual_address)];
f0102af9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102afc:	c1 e8 16             	shr    $0x16,%eax
f0102aff:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102b06:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b09:	01 d0                	add    %edx,%eax
f0102b0b:	8b 00                	mov    (%eax),%eax
f0102b0d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	*ptr_page_table = K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(page_directory_entry)) ;
f0102b10:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102b13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102b18:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102b1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b1e:	c1 e8 0c             	shr    $0xc,%eax
f0102b21:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102b24:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0102b29:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f0102b2c:	72 17                	jb     f0102b45 <get_page_table+0x52>
f0102b2e:	ff 75 f0             	pushl  -0x10(%ebp)
f0102b31:	68 bc 65 10 f0       	push   $0xf01065bc
f0102b36:	68 79 01 00 00       	push   $0x179
f0102b3b:	68 a5 65 10 f0       	push   $0xf01065a5
f0102b40:	e8 e9 d5 ff ff       	call   f010012e <_panic>
f0102b45:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102b48:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b4d:	89 c2                	mov    %eax,%edx
f0102b4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b52:	89 10                	mov    %edx,(%eax)

	if (page_directory_entry == 0)
f0102b54:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102b58:	0f 85 d3 00 00 00    	jne    f0102c31 <get_page_table+0x13e>
	{
		if (create)
f0102b5e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102b62:	0f 84 b9 00 00 00    	je     f0102c21 <get_page_table+0x12e>
		{
			struct Frame_Info* ptr_frame_info;
			int err = allocate_frame(&ptr_frame_info) ;
f0102b68:	83 ec 0c             	sub    $0xc,%esp
f0102b6b:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0102b6e:	50                   	push   %eax
f0102b6f:	e8 b7 fe ff ff       	call   f0102a2b <allocate_frame>
f0102b74:	83 c4 10             	add    $0x10,%esp
f0102b77:	89 45 e8             	mov    %eax,-0x18(%ebp)
			if(err == E_NO_MEM)
f0102b7a:	83 7d e8 fc          	cmpl   $0xfffffffc,-0x18(%ebp)
f0102b7e:	75 13                	jne    f0102b93 <get_page_table+0xa0>
			{
				*ptr_page_table = 0;
f0102b80:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b83:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				return E_NO_MEM;
f0102b89:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0102b8e:	e9 a3 00 00 00       	jmp    f0102c36 <get_page_table+0x143>
			}

			uint32 phys_page_table = to_physical_address(ptr_frame_info);
f0102b93:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102b96:	83 ec 0c             	sub    $0xc,%esp
f0102b99:	50                   	push   %eax
f0102b9a:	e8 e5 f7 ff ff       	call   f0102384 <to_physical_address>
f0102b9f:	83 c4 10             	add    $0x10,%esp
f0102ba2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			*ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table) ;
f0102ba5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ba8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bae:	c1 e8 0c             	shr    $0xc,%eax
f0102bb1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102bb4:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0102bb9:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0102bbc:	72 17                	jb     f0102bd5 <get_page_table+0xe2>
f0102bbe:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bc1:	68 bc 65 10 f0       	push   $0xf01065bc
f0102bc6:	68 88 01 00 00       	push   $0x188
f0102bcb:	68 a5 65 10 f0       	push   $0xf01065a5
f0102bd0:	e8 59 d5 ff ff       	call   f010012e <_panic>
f0102bd5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bd8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bdd:	89 c2                	mov    %eax,%edx
f0102bdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be2:	89 10                	mov    %edx,(%eax)

			//initialize new page table by 0's
			memset(*ptr_page_table , 0, PAGE_SIZE);
f0102be4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be7:	8b 00                	mov    (%eax),%eax
f0102be9:	83 ec 04             	sub    $0x4,%esp
f0102bec:	68 00 10 00 00       	push   $0x1000
f0102bf1:	6a 00                	push   $0x0
f0102bf3:	50                   	push   %eax
f0102bf4:	e8 c6 21 00 00       	call   f0104dbf <memset>
f0102bf9:	83 c4 10             	add    $0x10,%esp

			ptr_frame_info->references = 1;
f0102bfc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102bff:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
			ptr_page_directory[PDX(virtual_address)] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_USER | PERM_WRITEABLE);
f0102c05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c08:	c1 e8 16             	shr    $0x16,%eax
f0102c0b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102c12:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c15:	01 d0                	add    %edx,%eax
f0102c17:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c1a:	83 ca 07             	or     $0x7,%edx
f0102c1d:	89 10                	mov    %edx,(%eax)
f0102c1f:	eb 10                	jmp    f0102c31 <get_page_table+0x13e>
		}
		else
		{
			*ptr_page_table = 0;
f0102c21:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c24:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return 0;
f0102c2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c2f:	eb 05                	jmp    f0102c36 <get_page_table+0x143>
		}
	}	
	return 0;
f0102c31:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c36:	c9                   	leave  
f0102c37:	c3                   	ret    

f0102c38 <map_frame>:
//   E_NO_MEM, if page table couldn't be allocated
//
// Hint: implement using get_page_table() and unmap_frame().
//
int map_frame(uint32 *ptr_page_directory, struct Frame_Info *ptr_frame_info, void *virtual_address, int perm)
{
f0102c38:	55                   	push   %ebp
f0102c39:	89 e5                	mov    %esp,%ebp
f0102c3b:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 physical_address = to_physical_address(ptr_frame_info);
f0102c3e:	ff 75 0c             	pushl  0xc(%ebp)
f0102c41:	e8 3e f7 ff ff       	call   f0102384 <to_physical_address>
f0102c46:	83 c4 04             	add    $0x4,%esp
f0102c49:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *ptr_page_table;
	if( get_page_table(ptr_page_directory, virtual_address, 1, &ptr_page_table) == 0)
f0102c4c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102c4f:	50                   	push   %eax
f0102c50:	6a 01                	push   $0x1
f0102c52:	ff 75 10             	pushl  0x10(%ebp)
f0102c55:	ff 75 08             	pushl  0x8(%ebp)
f0102c58:	e8 96 fe ff ff       	call   f0102af3 <get_page_table>
f0102c5d:	83 c4 10             	add    $0x10,%esp
f0102c60:	85 c0                	test   %eax,%eax
f0102c62:	75 7c                	jne    f0102ce0 <map_frame+0xa8>
	{
		uint32 page_table_entry = ptr_page_table[PTX(virtual_address)];
f0102c64:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102c67:	8b 55 10             	mov    0x10(%ebp),%edx
f0102c6a:	c1 ea 0c             	shr    $0xc,%edx
f0102c6d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102c73:	c1 e2 02             	shl    $0x2,%edx
f0102c76:	01 d0                	add    %edx,%eax
f0102c78:	8b 00                	mov    (%eax),%eax
f0102c7a:	89 45 f0             	mov    %eax,-0x10(%ebp)

		//If already mapped
		if ((page_table_entry & PERM_PRESENT) == PERM_PRESENT)
f0102c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c80:	83 e0 01             	and    $0x1,%eax
f0102c83:	85 c0                	test   %eax,%eax
f0102c85:	74 25                	je     f0102cac <map_frame+0x74>
		{
			//on this pa, then do nothing
			if (EXTRACT_ADDRESS(page_table_entry) == physical_address)
f0102c87:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c8a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102c8f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102c92:	75 07                	jne    f0102c9b <map_frame+0x63>
				return 0;
f0102c94:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c99:	eb 4a                	jmp    f0102ce5 <map_frame+0xad>
			//on another pa, then unmap it
			else
				unmap_frame(ptr_page_directory , virtual_address);
f0102c9b:	83 ec 08             	sub    $0x8,%esp
f0102c9e:	ff 75 10             	pushl  0x10(%ebp)
f0102ca1:	ff 75 08             	pushl  0x8(%ebp)
f0102ca4:	e8 ad 00 00 00       	call   f0102d56 <unmap_frame>
f0102ca9:	83 c4 10             	add    $0x10,%esp
		}
		ptr_frame_info->references++;
f0102cac:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102caf:	8b 40 08             	mov    0x8(%eax),%eax
f0102cb2:	40                   	inc    %eax
f0102cb3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102cb6:	66 89 42 08          	mov    %ax,0x8(%edx)
		ptr_page_table[PTX(virtual_address)] = CONSTRUCT_ENTRY(physical_address , perm | PERM_PRESENT);
f0102cba:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102cbd:	8b 55 10             	mov    0x10(%ebp),%edx
f0102cc0:	c1 ea 0c             	shr    $0xc,%edx
f0102cc3:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102cc9:	c1 e2 02             	shl    $0x2,%edx
f0102ccc:	01 c2                	add    %eax,%edx
f0102cce:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd1:	0b 45 f4             	or     -0xc(%ebp),%eax
f0102cd4:	83 c8 01             	or     $0x1,%eax
f0102cd7:	89 02                	mov    %eax,(%edx)

		return 0;
f0102cd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cde:	eb 05                	jmp    f0102ce5 <map_frame+0xad>
	}	
	return E_NO_MEM;
f0102ce0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0102ce5:	c9                   	leave  
f0102ce6:	c3                   	ret    

f0102ce7 <get_frame_info>:
// Return 0 if there is no frame mapped at virtual_address.
//
// Hint: implement using get_page_table() and get_frame_info().
//
struct Frame_Info * get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table)
		{
f0102ce7:	55                   	push   %ebp
f0102ce8:	89 e5                	mov    %esp,%ebp
f0102cea:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in	
	uint32 ret =  get_page_table(ptr_page_directory, virtual_address, 0, ptr_page_table) ;
f0102ced:	ff 75 10             	pushl  0x10(%ebp)
f0102cf0:	6a 00                	push   $0x0
f0102cf2:	ff 75 0c             	pushl  0xc(%ebp)
f0102cf5:	ff 75 08             	pushl  0x8(%ebp)
f0102cf8:	e8 f6 fd ff ff       	call   f0102af3 <get_page_table>
f0102cfd:	83 c4 10             	add    $0x10,%esp
f0102d00:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*ptr_page_table) != 0)
f0102d03:	8b 45 10             	mov    0x10(%ebp),%eax
f0102d06:	8b 00                	mov    (%eax),%eax
f0102d08:	85 c0                	test   %eax,%eax
f0102d0a:	74 43                	je     f0102d4f <get_frame_info+0x68>
	{	
		uint32 index_page_table = PTX(virtual_address);
f0102d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d0f:	c1 e8 0c             	shr    $0xc,%eax
f0102d12:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102d17:	89 45 f0             	mov    %eax,-0x10(%ebp)
		uint32 page_table_entry = (*ptr_page_table)[index_page_table];
f0102d1a:	8b 45 10             	mov    0x10(%ebp),%eax
f0102d1d:	8b 00                	mov    (%eax),%eax
f0102d1f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102d22:	c1 e2 02             	shl    $0x2,%edx
f0102d25:	01 d0                	add    %edx,%eax
f0102d27:	8b 00                	mov    (%eax),%eax
f0102d29:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( page_table_entry != 0)	
f0102d2c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102d30:	74 16                	je     f0102d48 <get_frame_info+0x61>
			return to_frame_info( EXTRACT_ADDRESS ( page_table_entry ) );
f0102d32:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102d35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d3a:	83 ec 0c             	sub    $0xc,%esp
f0102d3d:	50                   	push   %eax
f0102d3e:	e8 54 f6 ff ff       	call   f0102397 <to_frame_info>
f0102d43:	83 c4 10             	add    $0x10,%esp
f0102d46:	eb 0c                	jmp    f0102d54 <get_frame_info+0x6d>
		return 0;
f0102d48:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d4d:	eb 05                	jmp    f0102d54 <get_frame_info+0x6d>
	}
	return 0;
f0102d4f:	b8 00 00 00 00       	mov    $0x0,%eax
		}
f0102d54:	c9                   	leave  
f0102d55:	c3                   	ret    

f0102d56 <unmap_frame>:
//
// Hint: implement using get_frame_info(),
// 	tlb_invalidate(), and decrement_references().
//
void unmap_frame(uint32 *ptr_page_directory, void *virtual_address)
{
f0102d56:	55                   	push   %ebp
f0102d57:	89 e5                	mov    %esp,%ebp
f0102d59:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 *ptr_page_table;
	struct Frame_Info* ptr_frame_info = get_frame_info(ptr_page_directory, virtual_address, &ptr_page_table);
f0102d5c:	83 ec 04             	sub    $0x4,%esp
f0102d5f:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0102d62:	50                   	push   %eax
f0102d63:	ff 75 0c             	pushl  0xc(%ebp)
f0102d66:	ff 75 08             	pushl  0x8(%ebp)
f0102d69:	e8 79 ff ff ff       	call   f0102ce7 <get_frame_info>
f0102d6e:	83 c4 10             	add    $0x10,%esp
f0102d71:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( ptr_frame_info != 0 )
f0102d74:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102d78:	74 39                	je     f0102db3 <unmap_frame+0x5d>
	{
		decrement_references(ptr_frame_info);
f0102d7a:	83 ec 0c             	sub    $0xc,%esp
f0102d7d:	ff 75 f4             	pushl  -0xc(%ebp)
f0102d80:	e8 44 fd ff ff       	call   f0102ac9 <decrement_references>
f0102d85:	83 c4 10             	add    $0x10,%esp
		ptr_page_table[PTX(virtual_address)] = 0;
f0102d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d8b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102d8e:	c1 ea 0c             	shr    $0xc,%edx
f0102d91:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102d97:	c1 e2 02             	shl    $0x2,%edx
f0102d9a:	01 d0                	add    %edx,%eax
f0102d9c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(ptr_page_directory, virtual_address);
f0102da2:	83 ec 08             	sub    $0x8,%esp
f0102da5:	ff 75 0c             	pushl  0xc(%ebp)
f0102da8:	ff 75 08             	pushl  0x8(%ebp)
f0102dab:	e8 59 eb ff ff       	call   f0101909 <tlb_invalidate>
f0102db0:	83 c4 10             	add    $0x10,%esp
	}	
}
f0102db3:	90                   	nop
f0102db4:	c9                   	leave  
f0102db5:	c3                   	ret    

f0102db6 <get_page>:
//		or to allocate any necessary page tables.
// 	HINT: 	remember to free the allocated frame if there is no space 
//		for the necessary page tables

int get_page(uint32* ptr_page_directory, void *virtual_address, int perm)
{
f0102db6:	55                   	push   %ebp
f0102db7:	89 e5                	mov    %esp,%ebp
f0102db9:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("get_page function is not completed yet") ;
f0102dbc:	83 ec 04             	sub    $0x4,%esp
f0102dbf:	68 ec 65 10 f0       	push   $0xf01065ec
f0102dc4:	68 14 02 00 00       	push   $0x214
f0102dc9:	68 a5 65 10 f0       	push   $0xf01065a5
f0102dce:	e8 5b d3 ff ff       	call   f010012e <_panic>

f0102dd3 <calculate_required_frames>:
	return 0 ;
}

//[2] calculate_required_frames: 
uint32 calculate_required_frames(uint32* ptr_page_directory, uint32 start_virtual_address, uint32 size)
{
f0102dd3:	55                   	push   %ebp
f0102dd4:	89 e5                	mov    %esp,%ebp
f0102dd6:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("calculate_required_frames function is not completed yet") ;
f0102dd9:	83 ec 04             	sub    $0x4,%esp
f0102ddc:	68 14 66 10 f0       	push   $0xf0106614
f0102de1:	68 2b 02 00 00       	push   $0x22b
f0102de6:	68 a5 65 10 f0       	push   $0xf01065a5
f0102deb:	e8 3e d3 ff ff       	call   f010012e <_panic>

f0102df0 <calculate_free_frames>:


//[3] calculate_free_frames:

uint32 calculate_free_frames()
{
f0102df0:	55                   	push   %ebp
f0102df1:	89 e5                	mov    %esp,%ebp
f0102df3:	83 ec 10             	sub    $0x10,%esp
	// PROJECT 2008: Your code here.
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
f0102df6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	LIST_FOREACH(ptr, &free_frame_list)
f0102dfd:	a1 d8 f7 14 f0       	mov    0xf014f7d8,%eax
f0102e02:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102e05:	eb 0b                	jmp    f0102e12 <calculate_free_frames+0x22>
	{
		cnt++ ;
f0102e07:	ff 45 f8             	incl   -0x8(%ebp)
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
	LIST_FOREACH(ptr, &free_frame_list)
f0102e0a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102e0d:	8b 00                	mov    (%eax),%eax
f0102e0f:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0102e12:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0102e16:	75 ef                	jne    f0102e07 <calculate_free_frames+0x17>
	{
		cnt++ ;
	}
	return cnt;
f0102e18:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0102e1b:	c9                   	leave  
f0102e1c:	c3                   	ret    

f0102e1d <freeMem>:
//	Steps:
//		1) Unmap all mapped pages in the range [virtual_address, virtual_address + size ]
//		2) Free all mapped page tables in this range

void freeMem(uint32* ptr_page_directory, void *virtual_address, uint32 size)
{
f0102e1d:	55                   	push   %ebp
f0102e1e:	89 e5                	mov    %esp,%ebp
f0102e20:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("freeMem function is not completed yet") ;
f0102e23:	83 ec 04             	sub    $0x4,%esp
f0102e26:	68 4c 66 10 f0       	push   $0xf010664c
f0102e2b:	68 52 02 00 00       	push   $0x252
f0102e30:	68 a5 65 10 f0       	push   $0xf01065a5
f0102e35:	e8 f4 d2 ff ff       	call   f010012e <_panic>

f0102e3a <allocate_environment>:
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	E_NO_FREE_ENV if all NENVS environments are allocated
//
int allocate_environment(struct Env** e)
{	
f0102e3a:	55                   	push   %ebp
f0102e3b:	89 e5                	mov    %esp,%ebp
	if (!(*e = LIST_FIRST(&env_free_list)))
f0102e3d:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102e43:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e46:	89 10                	mov    %edx,(%eax)
f0102e48:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e4b:	8b 00                	mov    (%eax),%eax
f0102e4d:	85 c0                	test   %eax,%eax
f0102e4f:	75 07                	jne    f0102e58 <allocate_environment+0x1e>
		return E_NO_FREE_ENV;
f0102e51:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102e56:	eb 05                	jmp    f0102e5d <allocate_environment+0x23>
	return 0;
f0102e58:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e5d:	5d                   	pop    %ebp
f0102e5e:	c3                   	ret    

f0102e5f <free_environment>:

// Free the given environment "e", simply by adding it to the free environment list.
void free_environment(struct Env* e)
{
f0102e5f:	55                   	push   %ebp
f0102e60:	89 e5                	mov    %esp,%ebp
	curenv = NULL;	
f0102e62:	c7 05 50 ef 14 f0 00 	movl   $0x0,0xf014ef50
f0102e69:	00 00 00 
	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e6f:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e);
f0102e76:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0102e7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e7f:	89 50 44             	mov    %edx,0x44(%eax)
f0102e82:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e85:	8b 40 44             	mov    0x44(%eax),%eax
f0102e88:	85 c0                	test   %eax,%eax
f0102e8a:	74 0e                	je     f0102e9a <free_environment+0x3b>
f0102e8c:	a1 54 ef 14 f0       	mov    0xf014ef54,%eax
f0102e91:	8b 55 08             	mov    0x8(%ebp),%edx
f0102e94:	83 c2 44             	add    $0x44,%edx
f0102e97:	89 50 48             	mov    %edx,0x48(%eax)
f0102e9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e9d:	a3 54 ef 14 f0       	mov    %eax,0xf014ef54
f0102ea2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea5:	c7 40 48 54 ef 14 f0 	movl   $0xf014ef54,0x48(%eax)
}
f0102eac:	90                   	nop
f0102ead:	5d                   	pop    %ebp
f0102eae:	c3                   	ret    

f0102eaf <program_segment_alloc_map>:
//
// if the allocation failed, return E_NO_MEM 
// otherwise return 0
//
static int program_segment_alloc_map(struct Env *e, void *va, uint32 length)
{
f0102eaf:	55                   	push   %ebp
f0102eb0:	89 e5                	mov    %esp,%ebp
f0102eb2:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB6 Hands-on: fill this function. 
	//Comment the following line
	panic("Function is not implemented yet!");
f0102eb5:	83 ec 04             	sub    $0x4,%esp
f0102eb8:	68 d0 66 10 f0       	push   $0xf01066d0
f0102ebd:	6a 7b                	push   $0x7b
f0102ebf:	68 f1 66 10 f0       	push   $0xf01066f1
f0102ec4:	e8 65 d2 ff ff       	call   f010012e <_panic>

f0102ec9 <env_create>:
}

//
// Allocates a new env and loads the named user program into it.
struct UserProgramInfo* env_create(char* user_program_name)
{
f0102ec9:	55                   	push   %ebp
f0102eca:	89 e5                	mov    %esp,%ebp
f0102ecc:	83 ec 38             	sub    $0x38,%esp
	//[1] get pointer to the start of the "user_program_name" program in memory
	// Hint: use "get_user_program_info" function, 
	// you should set the following "ptr_program_start" by the start address of the user program 
	uint8* ptr_program_start = 0; 
f0102ecf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	struct UserProgramInfo* ptr_user_program_info =get_user_program_info(user_program_name);
f0102ed6:	83 ec 0c             	sub    $0xc,%esp
f0102ed9:	ff 75 08             	pushl  0x8(%ebp)
f0102edc:	e8 24 05 00 00       	call   f0103405 <get_user_program_info>
f0102ee1:	83 c4 10             	add    $0x10,%esp
f0102ee4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (ptr_user_program_info == 0)
f0102ee7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0102eeb:	75 07                	jne    f0102ef4 <env_create+0x2b>
		return NULL ;
f0102eed:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ef2:	eb 42                	jmp    f0102f36 <env_create+0x6d>

	ptr_program_start = ptr_user_program_info->ptr_start ;
f0102ef4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102ef7:	8b 40 08             	mov    0x8(%eax),%eax
f0102efa:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//[2] allocate new environment, (from the free environment list)
	//if there's no one, return NULL
	// Hint: use "allocate_environment" function
	struct Env* e = NULL;
f0102efd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	if(allocate_environment(&e) == E_NO_FREE_ENV)
f0102f04:	83 ec 0c             	sub    $0xc,%esp
f0102f07:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f0a:	50                   	push   %eax
f0102f0b:	e8 2a ff ff ff       	call   f0102e3a <allocate_environment>
f0102f10:	83 c4 10             	add    $0x10,%esp
f0102f13:	83 f8 fb             	cmp    $0xfffffffb,%eax
f0102f16:	75 07                	jne    f0102f1f <env_create+0x56>
	{
		return 0;
f0102f18:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f1d:	eb 17                	jmp    f0102f36 <env_create+0x6d>
	}

	//=========================================================
	//TODO: LAB6 Hands-on: fill this part. 
	//Comment the following line
	panic("env_create: directory creation is not implemented yet!");
f0102f1f:	83 ec 04             	sub    $0x4,%esp
f0102f22:	68 0c 67 10 f0       	push   $0xf010670c
f0102f27:	68 9f 00 00 00       	push   $0x9f
f0102f2c:	68 f1 66 10 f0       	push   $0xf01066f1
f0102f31:	e8 f8 d1 ff ff       	call   f010012e <_panic>

	//[11] switch back to the page directory exists before segment loading
	lcr3(kern_phys_pgdir) ;

	return ptr_user_program_info;
}
f0102f36:	c9                   	leave  
f0102f37:	c3                   	ret    

f0102f38 <env_run>:
// Used to run the given environment "e", simply by 
// context switch from curenv to env e.
//  (This function does not return.)
//
void env_run(struct Env *e)
{
f0102f38:	55                   	push   %ebp
f0102f39:	89 e5                	mov    %esp,%ebp
f0102f3b:	83 ec 18             	sub    $0x18,%esp
	if(curenv != e)
f0102f3e:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102f43:	3b 45 08             	cmp    0x8(%ebp),%eax
f0102f46:	74 25                	je     f0102f6d <env_run+0x35>
	{		
		curenv = e ;
f0102f48:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f4b:	a3 50 ef 14 f0       	mov    %eax,0xf014ef50
		curenv->env_runs++ ;
f0102f50:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102f55:	8b 50 58             	mov    0x58(%eax),%edx
f0102f58:	42                   	inc    %edx
f0102f59:	89 50 58             	mov    %edx,0x58(%eax)
		lcr3(curenv->env_cr3) ;	
f0102f5c:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102f61:	8b 40 60             	mov    0x60(%eax),%eax
f0102f64:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f6a:	0f 22 d8             	mov    %eax,%cr3
	}	
	env_pop_tf(&(curenv->env_tf));
f0102f6d:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0102f72:	83 ec 0c             	sub    $0xc,%esp
f0102f75:	50                   	push   %eax
f0102f76:	e8 85 06 00 00       	call   f0103600 <env_pop_tf>

f0102f7b <env_free>:

//
// Frees environment "e" and all memory it uses.
// 
void env_free(struct Env *e)
{
f0102f7b:	55                   	push   %ebp
f0102f7c:	89 e5                	mov    %esp,%ebp
f0102f7e:	83 ec 08             	sub    $0x8,%esp
	// panic("env_free function is not completed yet") ;
	cprintf("some dummy text instead of panicing\n");
f0102f81:	83 ec 0c             	sub    $0xc,%esp
f0102f84:	68 44 67 10 f0       	push   $0xf0106744
f0102f89:	e8 4e 07 00 00       	call   f01036dc <cprintf>
f0102f8e:	83 c4 10             	add    $0x10,%esp

	// [4] switch back to the kernel page directory

	// [5] free the environment (return it back to the free environment list)
	// Hint: use free_environment()
}
f0102f91:	90                   	nop
f0102f92:	c9                   	leave  
f0102f93:	c3                   	ret    

f0102f94 <env_init>:
// Insert in reverse order, so that the first call to allocate_environment()
// returns envs[0].
//
void
env_init(void)
{	
f0102f94:	55                   	push   %ebp
f0102f95:	89 e5                	mov    %esp,%ebp
f0102f97:	53                   	push   %ebx
f0102f98:	83 ec 10             	sub    $0x10,%esp
	int iEnv = NENV-1;
f0102f9b:	c7 45 f8 ff 03 00 00 	movl   $0x3ff,-0x8(%ebp)
	for(; iEnv >= 0; iEnv--)
f0102fa2:	e9 ed 00 00 00       	jmp    f0103094 <env_init+0x100>
	{
		envs[iEnv].env_status = ENV_FREE;
f0102fa7:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102fad:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102fb0:	89 d0                	mov    %edx,%eax
f0102fb2:	c1 e0 02             	shl    $0x2,%eax
f0102fb5:	01 d0                	add    %edx,%eax
f0102fb7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102fbe:	01 d0                	add    %edx,%eax
f0102fc0:	c1 e0 02             	shl    $0x2,%eax
f0102fc3:	01 c8                	add    %ecx,%eax
f0102fc5:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[iEnv].env_id = 0;
f0102fcc:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102fd2:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102fd5:	89 d0                	mov    %edx,%eax
f0102fd7:	c1 e0 02             	shl    $0x2,%eax
f0102fda:	01 d0                	add    %edx,%eax
f0102fdc:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0102fe3:	01 d0                	add    %edx,%eax
f0102fe5:	c1 e0 02             	shl    $0x2,%eax
f0102fe8:	01 c8                	add    %ecx,%eax
f0102fea:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
f0102ff1:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0102ff7:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102ffa:	89 d0                	mov    %edx,%eax
f0102ffc:	c1 e0 02             	shl    $0x2,%eax
f0102fff:	01 d0                	add    %edx,%eax
f0103001:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103008:	01 d0                	add    %edx,%eax
f010300a:	c1 e0 02             	shl    $0x2,%eax
f010300d:	01 c8                	add    %ecx,%eax
f010300f:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0103015:	89 50 44             	mov    %edx,0x44(%eax)
f0103018:	8b 40 44             	mov    0x44(%eax),%eax
f010301b:	85 c0                	test   %eax,%eax
f010301d:	74 2a                	je     f0103049 <env_init+0xb5>
f010301f:	8b 15 54 ef 14 f0    	mov    0xf014ef54,%edx
f0103025:	8b 1d 4c ef 14 f0    	mov    0xf014ef4c,%ebx
f010302b:	8b 4d f8             	mov    -0x8(%ebp),%ecx
f010302e:	89 c8                	mov    %ecx,%eax
f0103030:	c1 e0 02             	shl    $0x2,%eax
f0103033:	01 c8                	add    %ecx,%eax
f0103035:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f010303c:	01 c8                	add    %ecx,%eax
f010303e:	c1 e0 02             	shl    $0x2,%eax
f0103041:	01 d8                	add    %ebx,%eax
f0103043:	83 c0 44             	add    $0x44,%eax
f0103046:	89 42 48             	mov    %eax,0x48(%edx)
f0103049:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f010304f:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0103052:	89 d0                	mov    %edx,%eax
f0103054:	c1 e0 02             	shl    $0x2,%eax
f0103057:	01 d0                	add    %edx,%eax
f0103059:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103060:	01 d0                	add    %edx,%eax
f0103062:	c1 e0 02             	shl    $0x2,%eax
f0103065:	01 c8                	add    %ecx,%eax
f0103067:	a3 54 ef 14 f0       	mov    %eax,0xf014ef54
f010306c:	8b 0d 4c ef 14 f0    	mov    0xf014ef4c,%ecx
f0103072:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0103075:	89 d0                	mov    %edx,%eax
f0103077:	c1 e0 02             	shl    $0x2,%eax
f010307a:	01 d0                	add    %edx,%eax
f010307c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103083:	01 d0                	add    %edx,%eax
f0103085:	c1 e0 02             	shl    $0x2,%eax
f0103088:	01 c8                	add    %ecx,%eax
f010308a:	c7 40 48 54 ef 14 f0 	movl   $0xf014ef54,0x48(%eax)
//
void
env_init(void)
{	
	int iEnv = NENV-1;
	for(; iEnv >= 0; iEnv--)
f0103091:	ff 4d f8             	decl   -0x8(%ebp)
f0103094:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0103098:	0f 89 09 ff ff ff    	jns    f0102fa7 <env_init+0x13>
	{
		envs[iEnv].env_status = ENV_FREE;
		envs[iEnv].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
	}
}
f010309e:	90                   	nop
f010309f:	83 c4 10             	add    $0x10,%esp
f01030a2:	5b                   	pop    %ebx
f01030a3:	5d                   	pop    %ebp
f01030a4:	c3                   	ret    

f01030a5 <complete_environment_initialization>:

void complete_environment_initialization(struct Env* e)
{	
f01030a5:	55                   	push   %ebp
f01030a6:	89 e5                	mov    %esp,%ebp
f01030a8:	83 ec 18             	sub    $0x18,%esp
	//VPT and UVPT map the env's own page table, with
	//different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PERM_PRESENT | PERM_WRITEABLE;
f01030ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ae:	8b 40 5c             	mov    0x5c(%eax),%eax
f01030b1:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f01030b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ba:	8b 40 60             	mov    0x60(%eax),%eax
f01030bd:	83 c8 03             	or     $0x3,%eax
f01030c0:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PERM_PRESENT | PERM_USER;
f01030c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01030c5:	8b 40 5c             	mov    0x5c(%eax),%eax
f01030c8:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f01030ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d1:	8b 40 60             	mov    0x60(%eax),%eax
f01030d4:	83 c8 05             	or     $0x5,%eax
f01030d7:	89 02                	mov    %eax,(%edx)

	int32 generation;	
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01030d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01030dc:	8b 40 4c             	mov    0x4c(%eax),%eax
f01030df:	05 00 10 00 00       	add    $0x1000,%eax
f01030e4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01030e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f01030ec:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01030f0:	7f 07                	jg     f01030f9 <complete_environment_initialization+0x54>
		generation = 1 << ENVGENSHIFT;
f01030f2:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f01030f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01030fc:	8b 15 4c ef 14 f0    	mov    0xf014ef4c,%edx
f0103102:	29 d0                	sub    %edx,%eax
f0103104:	c1 f8 02             	sar    $0x2,%eax
f0103107:	89 c1                	mov    %eax,%ecx
f0103109:	89 c8                	mov    %ecx,%eax
f010310b:	c1 e0 02             	shl    $0x2,%eax
f010310e:	01 c8                	add    %ecx,%eax
f0103110:	c1 e0 07             	shl    $0x7,%eax
f0103113:	29 c8                	sub    %ecx,%eax
f0103115:	c1 e0 03             	shl    $0x3,%eax
f0103118:	01 c8                	add    %ecx,%eax
f010311a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103121:	01 d0                	add    %edx,%eax
f0103123:	c1 e0 02             	shl    $0x2,%eax
f0103126:	01 c8                	add    %ecx,%eax
f0103128:	c1 e0 03             	shl    $0x3,%eax
f010312b:	01 c8                	add    %ecx,%eax
f010312d:	89 c2                	mov    %eax,%edx
f010312f:	c1 e2 06             	shl    $0x6,%edx
f0103132:	29 c2                	sub    %eax,%edx
f0103134:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0103137:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f010313a:	8d 04 95 00 00 00 00 	lea    0x0(,%edx,4),%eax
f0103141:	01 c2                	add    %eax,%edx
f0103143:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0103146:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0103149:	89 d0                	mov    %edx,%eax
f010314b:	f7 d8                	neg    %eax
f010314d:	0b 45 f4             	or     -0xc(%ebp),%eax
f0103150:	89 c2                	mov    %eax,%edx
f0103152:	8b 45 08             	mov    0x8(%ebp),%eax
f0103155:	89 50 4c             	mov    %edx,0x4c(%eax)

	// Set the basic status variables.
	e->env_parent_id = 0;//parent_id;
f0103158:	8b 45 08             	mov    0x8(%ebp),%eax
f010315b:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f0103162:	8b 45 08             	mov    0x8(%ebp),%eax
f0103165:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f010316c:	8b 45 08             	mov    0x8(%ebp),%eax
f010316f:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103176:	8b 45 08             	mov    0x8(%ebp),%eax
f0103179:	83 ec 04             	sub    $0x4,%esp
f010317c:	6a 44                	push   $0x44
f010317e:	6a 00                	push   $0x0
f0103180:	50                   	push   %eax
f0103181:	e8 39 1c 00 00       	call   f0104dbf <memset>
f0103186:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	e->env_tf.tf_ds = GD_UD | 3;
f0103189:	8b 45 08             	mov    0x8(%ebp),%eax
f010318c:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f0103192:	8b 45 08             	mov    0x8(%ebp),%eax
f0103195:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f010319b:	8b 45 08             	mov    0x8(%ebp),%eax
f010319e:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = (uint32*)USTACKTOP;
f01031a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a7:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f01031ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b1:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e);	
f01031b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ba:	8b 40 44             	mov    0x44(%eax),%eax
f01031bd:	85 c0                	test   %eax,%eax
f01031bf:	74 0f                	je     f01031d0 <complete_environment_initialization+0x12b>
f01031c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031c4:	8b 40 44             	mov    0x44(%eax),%eax
f01031c7:	8b 55 08             	mov    0x8(%ebp),%edx
f01031ca:	8b 52 48             	mov    0x48(%edx),%edx
f01031cd:	89 50 48             	mov    %edx,0x48(%eax)
f01031d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d3:	8b 40 48             	mov    0x48(%eax),%eax
f01031d6:	8b 55 08             	mov    0x8(%ebp),%edx
f01031d9:	8b 52 44             	mov    0x44(%edx),%edx
f01031dc:	89 10                	mov    %edx,(%eax)
	return ;
f01031de:	90                   	nop
}
f01031df:	c9                   	leave  
f01031e0:	c3                   	ret    

f01031e1 <PROGRAM_SEGMENT_NEXT>:

struct ProgramSegment* PROGRAM_SEGMENT_NEXT(struct ProgramSegment* seg, uint8* ptr_program_start)
				{
f01031e1:	55                   	push   %ebp
f01031e2:	89 e5                	mov    %esp,%ebp
f01031e4:	83 ec 18             	sub    $0x18,%esp
	int index = (*seg).segment_id++;
f01031e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ea:	8b 40 10             	mov    0x10(%eax),%eax
f01031ed:	8d 48 01             	lea    0x1(%eax),%ecx
f01031f0:	8b 55 08             	mov    0x8(%ebp),%edx
f01031f3:	89 4a 10             	mov    %ecx,0x10(%edx)
f01031f6:	89 45 f4             	mov    %eax,-0xc(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01031f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01031ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103202:	8b 00                	mov    (%eax),%eax
f0103204:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f0103209:	74 17                	je     f0103222 <PROGRAM_SEGMENT_NEXT+0x41>
		panic("Matafa2nash 3ala Keda"); 
f010320b:	83 ec 04             	sub    $0x4,%esp
f010320e:	68 69 67 10 f0       	push   $0xf0106769
f0103213:	68 89 01 00 00       	push   $0x189
f0103218:	68 f1 66 10 f0       	push   $0xf01066f1
f010321d:	e8 0c cf ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f0103222:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103225:	8b 50 1c             	mov    0x1c(%eax),%edx
f0103228:	8b 45 0c             	mov    0xc(%ebp),%eax
f010322b:	01 d0                	add    %edx,%eax
f010322d:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (ph[(*seg).segment_id].p_type != ELF_PROG_LOAD && ((*seg).segment_id < pELFHDR->e_phnum)) (*seg).segment_id++;	
f0103230:	eb 0f                	jmp    f0103241 <PROGRAM_SEGMENT_NEXT+0x60>
f0103232:	8b 45 08             	mov    0x8(%ebp),%eax
f0103235:	8b 40 10             	mov    0x10(%eax),%eax
f0103238:	8d 50 01             	lea    0x1(%eax),%edx
f010323b:	8b 45 08             	mov    0x8(%ebp),%eax
f010323e:	89 50 10             	mov    %edx,0x10(%eax)
f0103241:	8b 45 08             	mov    0x8(%ebp),%eax
f0103244:	8b 40 10             	mov    0x10(%eax),%eax
f0103247:	c1 e0 05             	shl    $0x5,%eax
f010324a:	89 c2                	mov    %eax,%edx
f010324c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010324f:	01 d0                	add    %edx,%eax
f0103251:	8b 00                	mov    (%eax),%eax
f0103253:	83 f8 01             	cmp    $0x1,%eax
f0103256:	74 13                	je     f010326b <PROGRAM_SEGMENT_NEXT+0x8a>
f0103258:	8b 45 08             	mov    0x8(%ebp),%eax
f010325b:	8b 50 10             	mov    0x10(%eax),%edx
f010325e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103261:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103264:	0f b7 c0             	movzwl %ax,%eax
f0103267:	39 c2                	cmp    %eax,%edx
f0103269:	72 c7                	jb     f0103232 <PROGRAM_SEGMENT_NEXT+0x51>
	index = (*seg).segment_id;
f010326b:	8b 45 08             	mov    0x8(%ebp),%eax
f010326e:	8b 40 10             	mov    0x10(%eax),%eax
f0103271:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(index < pELFHDR->e_phnum)
f0103274:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103277:	8b 40 2c             	mov    0x2c(%eax),%eax
f010327a:	0f b7 c0             	movzwl %ax,%eax
f010327d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0103280:	7e 63                	jle    f01032e5 <PROGRAM_SEGMENT_NEXT+0x104>
	{
		(*seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f0103282:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103285:	c1 e0 05             	shl    $0x5,%eax
f0103288:	89 c2                	mov    %eax,%edx
f010328a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010328d:	01 d0                	add    %edx,%eax
f010328f:	8b 50 04             	mov    0x4(%eax),%edx
f0103292:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103295:	01 c2                	add    %eax,%edx
f0103297:	8b 45 08             	mov    0x8(%ebp),%eax
f010329a:	89 10                	mov    %edx,(%eax)
		(*seg).size_in_memory =  ph[index].p_memsz;
f010329c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010329f:	c1 e0 05             	shl    $0x5,%eax
f01032a2:	89 c2                	mov    %eax,%edx
f01032a4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01032a7:	01 d0                	add    %edx,%eax
f01032a9:	8b 50 14             	mov    0x14(%eax),%edx
f01032ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01032af:	89 50 08             	mov    %edx,0x8(%eax)
		(*seg).size_in_file = ph[index].p_filesz;
f01032b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01032b5:	c1 e0 05             	shl    $0x5,%eax
f01032b8:	89 c2                	mov    %eax,%edx
f01032ba:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01032bd:	01 d0                	add    %edx,%eax
f01032bf:	8b 50 10             	mov    0x10(%eax),%edx
f01032c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032c5:	89 50 04             	mov    %edx,0x4(%eax)
		(*seg).virtual_address = (uint8*)ph[index].p_va;
f01032c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01032cb:	c1 e0 05             	shl    $0x5,%eax
f01032ce:	89 c2                	mov    %eax,%edx
f01032d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01032d3:	01 d0                	add    %edx,%eax
f01032d5:	8b 40 08             	mov    0x8(%eax),%eax
f01032d8:	89 c2                	mov    %eax,%edx
f01032da:	8b 45 08             	mov    0x8(%ebp),%eax
f01032dd:	89 50 0c             	mov    %edx,0xc(%eax)
		return seg;
f01032e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e3:	eb 05                	jmp    f01032ea <PROGRAM_SEGMENT_NEXT+0x109>
	}
	return 0;
f01032e5:	b8 00 00 00 00       	mov    $0x0,%eax
				}
f01032ea:	c9                   	leave  
f01032eb:	c3                   	ret    

f01032ec <PROGRAM_SEGMENT_FIRST>:

struct ProgramSegment PROGRAM_SEGMENT_FIRST( uint8* ptr_program_start)
{
f01032ec:	55                   	push   %ebp
f01032ed:	89 e5                	mov    %esp,%ebp
f01032ef:	57                   	push   %edi
f01032f0:	56                   	push   %esi
f01032f1:	53                   	push   %ebx
f01032f2:	83 ec 2c             	sub    $0x2c,%esp
	struct ProgramSegment seg;
	seg.segment_id = 0;
f01032f5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01032fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f0103302:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103305:	8b 00                	mov    (%eax),%eax
f0103307:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f010330c:	74 17                	je     f0103325 <PROGRAM_SEGMENT_FIRST+0x39>
		panic("Matafa2nash 3ala Keda"); 
f010330e:	83 ec 04             	sub    $0x4,%esp
f0103311:	68 69 67 10 f0       	push   $0xf0106769
f0103316:	68 a2 01 00 00       	push   $0x1a2
f010331b:	68 f1 66 10 f0       	push   $0xf01066f1
f0103320:	e8 09 ce ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f0103325:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103328:	8b 50 1c             	mov    0x1c(%eax),%edx
f010332b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010332e:	01 d0                	add    %edx,%eax
f0103330:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while (ph[(seg).segment_id].p_type != ELF_PROG_LOAD && ((seg).segment_id < pELFHDR->e_phnum)) (seg).segment_id++;
f0103333:	eb 07                	jmp    f010333c <PROGRAM_SEGMENT_FIRST+0x50>
f0103335:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103338:	40                   	inc    %eax
f0103339:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010333c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010333f:	c1 e0 05             	shl    $0x5,%eax
f0103342:	89 c2                	mov    %eax,%edx
f0103344:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103347:	01 d0                	add    %edx,%eax
f0103349:	8b 00                	mov    (%eax),%eax
f010334b:	83 f8 01             	cmp    $0x1,%eax
f010334e:	74 10                	je     f0103360 <PROGRAM_SEGMENT_FIRST+0x74>
f0103350:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103353:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103356:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103359:	0f b7 c0             	movzwl %ax,%eax
f010335c:	39 c2                	cmp    %eax,%edx
f010335e:	72 d5                	jb     f0103335 <PROGRAM_SEGMENT_FIRST+0x49>
	int index = (seg).segment_id;
f0103360:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103363:	89 45 dc             	mov    %eax,-0x24(%ebp)

	if(index < pELFHDR->e_phnum)
f0103366:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103369:	8b 40 2c             	mov    0x2c(%eax),%eax
f010336c:	0f b7 c0             	movzwl %ax,%eax
f010336f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f0103372:	7e 68                	jle    f01033dc <PROGRAM_SEGMENT_FIRST+0xf0>
	{	
		(seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f0103374:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103377:	c1 e0 05             	shl    $0x5,%eax
f010337a:	89 c2                	mov    %eax,%edx
f010337c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010337f:	01 d0                	add    %edx,%eax
f0103381:	8b 50 04             	mov    0x4(%eax),%edx
f0103384:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103387:	01 d0                	add    %edx,%eax
f0103389:	89 45 c8             	mov    %eax,-0x38(%ebp)
		(seg).size_in_memory =  ph[index].p_memsz;
f010338c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010338f:	c1 e0 05             	shl    $0x5,%eax
f0103392:	89 c2                	mov    %eax,%edx
f0103394:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103397:	01 d0                	add    %edx,%eax
f0103399:	8b 40 14             	mov    0x14(%eax),%eax
f010339c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		(seg).size_in_file = ph[index].p_filesz;
f010339f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033a2:	c1 e0 05             	shl    $0x5,%eax
f01033a5:	89 c2                	mov    %eax,%edx
f01033a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033aa:	01 d0                	add    %edx,%eax
f01033ac:	8b 40 10             	mov    0x10(%eax),%eax
f01033af:	89 45 cc             	mov    %eax,-0x34(%ebp)
		(seg).virtual_address = (uint8*)ph[index].p_va;
f01033b2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033b5:	c1 e0 05             	shl    $0x5,%eax
f01033b8:	89 c2                	mov    %eax,%edx
f01033ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033bd:	01 d0                	add    %edx,%eax
f01033bf:	8b 40 08             	mov    0x8(%eax),%eax
f01033c2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		return seg;
f01033c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c8:	89 c3                	mov    %eax,%ebx
f01033ca:	8d 45 c8             	lea    -0x38(%ebp),%eax
f01033cd:	ba 05 00 00 00       	mov    $0x5,%edx
f01033d2:	89 df                	mov    %ebx,%edi
f01033d4:	89 c6                	mov    %eax,%esi
f01033d6:	89 d1                	mov    %edx,%ecx
f01033d8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033da:	eb 1c                	jmp    f01033f8 <PROGRAM_SEGMENT_FIRST+0x10c>
	}
	seg.segment_id = -1;
f01033dc:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
	return seg;
f01033e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01033e6:	89 c3                	mov    %eax,%ebx
f01033e8:	8d 45 c8             	lea    -0x38(%ebp),%eax
f01033eb:	ba 05 00 00 00       	mov    $0x5,%edx
f01033f0:	89 df                	mov    %ebx,%edi
f01033f2:	89 c6                	mov    %eax,%esi
f01033f4:	89 d1                	mov    %edx,%ecx
f01033f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
}
f01033f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01033fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033fe:	5b                   	pop    %ebx
f01033ff:	5e                   	pop    %esi
f0103400:	5f                   	pop    %edi
f0103401:	5d                   	pop    %ebp
f0103402:	c2 04 00             	ret    $0x4

f0103405 <get_user_program_info>:

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
f0103405:	55                   	push   %ebp
f0103406:	89 e5                	mov    %esp,%ebp
f0103408:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f010340b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0103412:	eb 23                	jmp    f0103437 <get_user_program_info+0x32>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
f0103414:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103417:	c1 e0 04             	shl    $0x4,%eax
f010341a:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
f010341f:	8b 00                	mov    (%eax),%eax
f0103421:	83 ec 08             	sub    $0x8,%esp
f0103424:	50                   	push   %eax
f0103425:	ff 75 08             	pushl  0x8(%ebp)
f0103428:	e8 b0 18 00 00       	call   f0104cdd <strcmp>
f010342d:	83 c4 10             	add    $0x10,%esp
f0103430:	85 c0                	test   %eax,%eax
f0103432:	74 0f                	je     f0103443 <get_user_program_info+0x3e>
}

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0103434:	ff 45 f4             	incl   -0xc(%ebp)
f0103437:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f010343c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010343f:	7c d3                	jl     f0103414 <get_user_program_info+0xf>
f0103441:	eb 01                	jmp    f0103444 <get_user_program_info+0x3f>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
			break;
f0103443:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f0103444:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f0103449:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010344c:	75 1a                	jne    f0103468 <get_user_program_info+0x63>
	{
		cprintf("Unknown user program '%s'\n", user_program_name);
f010344e:	83 ec 08             	sub    $0x8,%esp
f0103451:	ff 75 08             	pushl  0x8(%ebp)
f0103454:	68 7f 67 10 f0       	push   $0xf010677f
f0103459:	e8 7e 02 00 00       	call   f01036dc <cprintf>
f010345e:	83 c4 10             	add    $0x10,%esp
		return 0;
f0103461:	b8 00 00 00 00       	mov    $0x0,%eax
f0103466:	eb 0b                	jmp    f0103473 <get_user_program_info+0x6e>
	}

	return &userPrograms[i];
f0103468:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010346b:	c1 e0 04             	shl    $0x4,%eax
f010346e:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
				}
f0103473:	c9                   	leave  
f0103474:	c3                   	ret    

f0103475 <get_user_program_info_by_env>:

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
f0103475:	55                   	push   %ebp
f0103476:	89 e5                	mov    %esp,%ebp
f0103478:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f010347b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0103482:	eb 15                	jmp    f0103499 <get_user_program_info_by_env+0x24>
		if (e== userPrograms[i].environment)
f0103484:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103487:	c1 e0 04             	shl    $0x4,%eax
f010348a:	05 ac c6 11 f0       	add    $0xf011c6ac,%eax
f010348f:	8b 00                	mov    (%eax),%eax
f0103491:	3b 45 08             	cmp    0x8(%ebp),%eax
f0103494:	74 0f                	je     f01034a5 <get_user_program_info_by_env+0x30>
				}

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0103496:	ff 45 f4             	incl   -0xc(%ebp)
f0103499:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f010349e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01034a1:	7c e1                	jl     f0103484 <get_user_program_info_by_env+0xf>
f01034a3:	eb 01                	jmp    f01034a6 <get_user_program_info_by_env+0x31>
		if (e== userPrograms[i].environment)
			break;
f01034a5:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f01034a6:	a1 f4 c6 11 f0       	mov    0xf011c6f4,%eax
f01034ab:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01034ae:	75 17                	jne    f01034c7 <get_user_program_info_by_env+0x52>
	{
		cprintf("Unknown user program \n");
f01034b0:	83 ec 0c             	sub    $0xc,%esp
f01034b3:	68 9a 67 10 f0       	push   $0xf010679a
f01034b8:	e8 1f 02 00 00       	call   f01036dc <cprintf>
f01034bd:	83 c4 10             	add    $0x10,%esp
		return 0;
f01034c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01034c5:	eb 0b                	jmp    f01034d2 <get_user_program_info_by_env+0x5d>
	}

	return &userPrograms[i];
f01034c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034ca:	c1 e0 04             	shl    $0x4,%eax
f01034cd:	05 a0 c6 11 f0       	add    $0xf011c6a0,%eax
				}
f01034d2:	c9                   	leave  
f01034d3:	c3                   	ret    

f01034d4 <set_environment_entry_point>:

void set_environment_entry_point(struct UserProgramInfo* ptr_user_program)
{
f01034d4:	55                   	push   %ebp
f01034d5:	89 e5                	mov    %esp,%ebp
f01034d7:	83 ec 18             	sub    $0x18,%esp
	uint8* ptr_program_start=ptr_user_program->ptr_start;
f01034da:	8b 45 08             	mov    0x8(%ebp),%eax
f01034dd:	8b 40 08             	mov    0x8(%eax),%eax
f01034e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Env* e = ptr_user_program->environment;
f01034e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01034e6:	8b 40 0c             	mov    0xc(%eax),%eax
f01034e9:	89 45 f0             	mov    %eax,-0x10(%ebp)

	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01034ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034ef:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01034f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01034f5:	8b 00                	mov    (%eax),%eax
f01034f7:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01034fc:	74 17                	je     f0103515 <set_environment_entry_point+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01034fe:	83 ec 04             	sub    $0x4,%esp
f0103501:	68 69 67 10 f0       	push   $0xf0106769
f0103506:	68 da 01 00 00       	push   $0x1da
f010350b:	68 f1 66 10 f0       	push   $0xf01066f1
f0103510:	e8 19 cc ff ff       	call   f010012e <_panic>
	e->env_tf.tf_eip = (uint32*)pELFHDR->e_entry ;
f0103515:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103518:	8b 40 18             	mov    0x18(%eax),%eax
f010351b:	89 c2                	mov    %eax,%edx
f010351d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103520:	89 50 30             	mov    %edx,0x30(%eax)
}
f0103523:	90                   	nop
f0103524:	c9                   	leave  
f0103525:	c3                   	ret    

f0103526 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0103526:	55                   	push   %ebp
f0103527:	89 e5                	mov    %esp,%ebp
f0103529:	83 ec 08             	sub    $0x8,%esp
	env_free(e);
f010352c:	83 ec 0c             	sub    $0xc,%esp
f010352f:	ff 75 08             	pushl  0x8(%ebp)
f0103532:	e8 44 fa ff ff       	call   f0102f7b <env_free>
f0103537:	83 c4 10             	add    $0x10,%esp

	//cprintf("Destroyed the only environment - nothing more to do!\n");
	while (1)
		run_command_prompt();
f010353a:	e8 12 d4 ff ff       	call   f0100951 <run_command_prompt>
f010353f:	eb f9                	jmp    f010353a <env_destroy+0x14>

f0103541 <env_run_cmd_prmpt>:
}

void env_run_cmd_prmpt()
{
f0103541:	55                   	push   %ebp
f0103542:	89 e5                	mov    %esp,%ebp
f0103544:	83 ec 18             	sub    $0x18,%esp
	struct UserProgramInfo* upi= get_user_program_info_by_env(curenv);	
f0103547:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f010354c:	83 ec 0c             	sub    $0xc,%esp
f010354f:	50                   	push   %eax
f0103550:	e8 20 ff ff ff       	call   f0103475 <get_user_program_info_by_env>
f0103555:	83 c4 10             	add    $0x10,%esp
f0103558:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&curenv->env_tf, 0, sizeof(curenv->env_tf));
f010355b:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103560:	83 ec 04             	sub    $0x4,%esp
f0103563:	6a 44                	push   $0x44
f0103565:	6a 00                	push   $0x0
f0103567:	50                   	push   %eax
f0103568:	e8 52 18 00 00       	call   f0104dbf <memset>
f010356d:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	curenv->env_tf.tf_ds = GD_UD | 3;
f0103570:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103575:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	curenv->env_tf.tf_es = GD_UD | 3;
f010357b:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103580:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	curenv->env_tf.tf_ss = GD_UD | 3;
f0103586:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f010358b:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	curenv->env_tf.tf_esp = (uint32*)USTACKTOP;
f0103591:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103596:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	curenv->env_tf.tf_cs = GD_UT | 3;
f010359d:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f01035a2:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	set_environment_entry_point(upi);
f01035a8:	83 ec 0c             	sub    $0xc,%esp
f01035ab:	ff 75 f4             	pushl  -0xc(%ebp)
f01035ae:	e8 21 ff ff ff       	call   f01034d4 <set_environment_entry_point>
f01035b3:	83 c4 10             	add    $0x10,%esp

	lcr3(K_PHYSICAL_ADDRESS(ptr_page_directory));
f01035b6:	a1 e4 f7 14 f0       	mov    0xf014f7e4,%eax
f01035bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035be:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f01035c5:	77 17                	ja     f01035de <env_run_cmd_prmpt+0x9d>
f01035c7:	ff 75 f0             	pushl  -0x10(%ebp)
f01035ca:	68 b4 67 10 f0       	push   $0xf01067b4
f01035cf:	68 05 02 00 00       	push   $0x205
f01035d4:	68 f1 66 10 f0       	push   $0xf01066f1
f01035d9:	e8 50 cb ff ff       	call   f010012e <_panic>
f01035de:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035e1:	05 00 00 00 10       	add    $0x10000000,%eax
f01035e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01035e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035ec:	0f 22 d8             	mov    %eax,%cr3

	curenv = NULL;
f01035ef:	c7 05 50 ef 14 f0 00 	movl   $0x0,0xf014ef50
f01035f6:	00 00 00 

	while (1)
		run_command_prompt();
f01035f9:	e8 53 d3 ff ff       	call   f0100951 <run_command_prompt>
f01035fe:	eb f9                	jmp    f01035f9 <env_run_cmd_prmpt+0xb8>

f0103600 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103600:	55                   	push   %ebp
f0103601:	89 e5                	mov    %esp,%ebp
f0103603:	83 ec 08             	sub    $0x8,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103606:	8b 65 08             	mov    0x8(%ebp),%esp
f0103609:	61                   	popa   
f010360a:	07                   	pop    %es
f010360b:	1f                   	pop    %ds
f010360c:	83 c4 08             	add    $0x8,%esp
f010360f:	cf                   	iret   
			"\tpopl %%es\n"
			"\tpopl %%ds\n"
			"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
			"\tiret"
			: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103610:	83 ec 04             	sub    $0x4,%esp
f0103613:	68 e5 67 10 f0       	push   $0xf01067e5
f0103618:	68 1c 02 00 00       	push   $0x21c
f010361d:	68 f1 66 10 f0       	push   $0xf01066f1
f0103622:	e8 07 cb ff ff       	call   f010012e <_panic>

f0103627 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103627:	55                   	push   %ebp
f0103628:	89 e5                	mov    %esp,%ebp
f010362a:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f010362d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103630:	0f b6 c0             	movzbl %al,%eax
f0103633:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f010363a:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010363d:	8a 45 f6             	mov    -0xa(%ebp),%al
f0103640:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103643:	ee                   	out    %al,(%dx)
f0103644:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010364b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010364e:	89 c2                	mov    %eax,%edx
f0103650:	ec                   	in     (%dx),%al
f0103651:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f0103654:	8a 45 f7             	mov    -0x9(%ebp),%al
	return inb(IO_RTC+1);
f0103657:	0f b6 c0             	movzbl %al,%eax
}
f010365a:	c9                   	leave  
f010365b:	c3                   	ret    

f010365c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010365c:	55                   	push   %ebp
f010365d:	89 e5                	mov    %esp,%ebp
f010365f:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0103662:	8b 45 08             	mov    0x8(%ebp),%eax
f0103665:	0f b6 c0             	movzbl %al,%eax
f0103668:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f010366f:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103672:	8a 45 f6             	mov    -0xa(%ebp),%al
f0103675:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0103678:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f0103679:	8b 45 0c             	mov    0xc(%ebp),%eax
f010367c:	0f b6 c0             	movzbl %al,%eax
f010367f:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)
f0103686:	88 45 f7             	mov    %al,-0x9(%ebp)
f0103689:	8a 45 f7             	mov    -0x9(%ebp),%al
f010368c:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010368f:	ee                   	out    %al,(%dx)
}
f0103690:	90                   	nop
f0103691:	c9                   	leave  
f0103692:	c3                   	ret    

f0103693 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103693:	55                   	push   %ebp
f0103694:	89 e5                	mov    %esp,%ebp
f0103696:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0103699:	83 ec 0c             	sub    $0xc,%esp
f010369c:	ff 75 08             	pushl  0x8(%ebp)
f010369f:	e8 73 d2 ff ff       	call   f0100917 <cputchar>
f01036a4:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f01036a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036aa:	83 c0 04             	add    $0x4,%eax
f01036ad:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f01036b0:	90                   	nop
f01036b1:	c9                   	leave  
f01036b2:	c3                   	ret    

f01036b3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036b3:	55                   	push   %ebp
f01036b4:	89 e5                	mov    %esp,%ebp
f01036b6:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01036b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036c0:	ff 75 0c             	pushl  0xc(%ebp)
f01036c3:	ff 75 08             	pushl  0x8(%ebp)
f01036c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036c9:	50                   	push   %eax
f01036ca:	68 93 36 10 f0       	push   $0xf0103693
f01036cf:	e8 57 0f 00 00       	call   f010462b <vprintfmt>
f01036d4:	83 c4 10             	add    $0x10,%esp
	return cnt;
f01036d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01036da:	c9                   	leave  
f01036db:	c3                   	ret    

f01036dc <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036dc:	55                   	push   %ebp
f01036dd:	89 e5                	mov    %esp,%ebp
f01036df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036e2:	8d 45 0c             	lea    0xc(%ebp),%eax
f01036e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f01036e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01036eb:	83 ec 08             	sub    $0x8,%esp
f01036ee:	ff 75 f4             	pushl  -0xc(%ebp)
f01036f1:	50                   	push   %eax
f01036f2:	e8 bc ff ff ff       	call   f01036b3 <vcprintf>
f01036f7:	83 c4 10             	add    $0x10,%esp
f01036fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f01036fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0103700:	c9                   	leave  
f0103701:	c3                   	ret    

f0103702 <trapname>:
};
extern  void (*PAGE_FAULT)();
extern  void (*SYSCALL_HANDLER)();

static const char *trapname(int trapno)
{
f0103702:	55                   	push   %ebp
f0103703:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103705:	8b 45 08             	mov    0x8(%ebp),%eax
f0103708:	83 f8 13             	cmp    $0x13,%eax
f010370b:	77 0c                	ja     f0103719 <trapname+0x17>
		return excnames[trapno];
f010370d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103710:	8b 04 85 20 6b 10 f0 	mov    -0xfef94e0(,%eax,4),%eax
f0103717:	eb 12                	jmp    f010372b <trapname+0x29>
	if (trapno == T_SYSCALL)
f0103719:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
f010371d:	75 07                	jne    f0103726 <trapname+0x24>
		return "System call";
f010371f:	b8 00 68 10 f0       	mov    $0xf0106800,%eax
f0103724:	eb 05                	jmp    f010372b <trapname+0x29>
	return "(unknown trap)";
f0103726:	b8 0c 68 10 f0       	mov    $0xf010680c,%eax
}
f010372b:	5d                   	pop    %ebp
f010372c:	c3                   	ret    

f010372d <idt_init>:


void
idt_init(void)
{
f010372d:	55                   	push   %ebp
f010372e:	89 e5                	mov    %esp,%ebp
f0103730:	83 ec 10             	sub    $0x10,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	//initialize idt
	SETGATE(idt[T_PGFLT], 0, GD_KT , &PAGE_FAULT, 0) ;
f0103733:	b8 8c 3c 10 f0       	mov    $0xf0103c8c,%eax
f0103738:	66 a3 d0 ef 14 f0    	mov    %ax,0xf014efd0
f010373e:	66 c7 05 d2 ef 14 f0 	movw   $0x8,0xf014efd2
f0103745:	08 00 
f0103747:	a0 d4 ef 14 f0       	mov    0xf014efd4,%al
f010374c:	83 e0 e0             	and    $0xffffffe0,%eax
f010374f:	a2 d4 ef 14 f0       	mov    %al,0xf014efd4
f0103754:	a0 d4 ef 14 f0       	mov    0xf014efd4,%al
f0103759:	83 e0 1f             	and    $0x1f,%eax
f010375c:	a2 d4 ef 14 f0       	mov    %al,0xf014efd4
f0103761:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103766:	83 e0 f0             	and    $0xfffffff0,%eax
f0103769:	83 c8 0e             	or     $0xe,%eax
f010376c:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f0103771:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103776:	83 e0 ef             	and    $0xffffffef,%eax
f0103779:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f010377e:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103783:	83 e0 9f             	and    $0xffffff9f,%eax
f0103786:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f010378b:	a0 d5 ef 14 f0       	mov    0xf014efd5,%al
f0103790:	83 c8 80             	or     $0xffffff80,%eax
f0103793:	a2 d5 ef 14 f0       	mov    %al,0xf014efd5
f0103798:	b8 8c 3c 10 f0       	mov    $0xf0103c8c,%eax
f010379d:	c1 e8 10             	shr    $0x10,%eax
f01037a0:	66 a3 d6 ef 14 f0    	mov    %ax,0xf014efd6
	SETGATE(idt[T_SYSCALL], 0, GD_KT , &SYSCALL_HANDLER, 3) ;
f01037a6:	b8 90 3c 10 f0       	mov    $0xf0103c90,%eax
f01037ab:	66 a3 e0 f0 14 f0    	mov    %ax,0xf014f0e0
f01037b1:	66 c7 05 e2 f0 14 f0 	movw   $0x8,0xf014f0e2
f01037b8:	08 00 
f01037ba:	a0 e4 f0 14 f0       	mov    0xf014f0e4,%al
f01037bf:	83 e0 e0             	and    $0xffffffe0,%eax
f01037c2:	a2 e4 f0 14 f0       	mov    %al,0xf014f0e4
f01037c7:	a0 e4 f0 14 f0       	mov    0xf014f0e4,%al
f01037cc:	83 e0 1f             	and    $0x1f,%eax
f01037cf:	a2 e4 f0 14 f0       	mov    %al,0xf014f0e4
f01037d4:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01037d9:	83 e0 f0             	and    $0xfffffff0,%eax
f01037dc:	83 c8 0e             	or     $0xe,%eax
f01037df:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01037e4:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01037e9:	83 e0 ef             	and    $0xffffffef,%eax
f01037ec:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01037f1:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f01037f6:	83 c8 60             	or     $0x60,%eax
f01037f9:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f01037fe:	a0 e5 f0 14 f0       	mov    0xf014f0e5,%al
f0103803:	83 c8 80             	or     $0xffffff80,%eax
f0103806:	a2 e5 f0 14 f0       	mov    %al,0xf014f0e5
f010380b:	b8 90 3c 10 f0       	mov    $0xf0103c90,%eax
f0103810:	c1 e8 10             	shr    $0x10,%eax
f0103813:	66 a3 e6 f0 14 f0    	mov    %ax,0xf014f0e6

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KERNEL_STACK_TOP;
f0103819:	c7 05 64 f7 14 f0 00 	movl   $0xefc00000,0xf014f764
f0103820:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f0103823:	66 c7 05 68 f7 14 f0 	movw   $0x10,0xf014f768
f010382a:	10 00 

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32) (&ts),
f010382c:	66 c7 05 88 c6 11 f0 	movw   $0x68,0xf011c688
f0103833:	68 00 
f0103835:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f010383a:	66 a3 8a c6 11 f0    	mov    %ax,0xf011c68a
f0103840:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f0103845:	c1 e8 10             	shr    $0x10,%eax
f0103848:	a2 8c c6 11 f0       	mov    %al,0xf011c68c
f010384d:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f0103852:	83 e0 f0             	and    $0xfffffff0,%eax
f0103855:	83 c8 09             	or     $0x9,%eax
f0103858:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f010385d:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f0103862:	83 c8 10             	or     $0x10,%eax
f0103865:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f010386a:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f010386f:	83 e0 9f             	and    $0xffffff9f,%eax
f0103872:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f0103877:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f010387c:	83 c8 80             	or     $0xffffff80,%eax
f010387f:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f0103884:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f0103889:	83 e0 f0             	and    $0xfffffff0,%eax
f010388c:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f0103891:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f0103896:	83 e0 ef             	and    $0xffffffef,%eax
f0103899:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f010389e:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f01038a3:	83 e0 df             	and    $0xffffffdf,%eax
f01038a6:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f01038ab:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f01038b0:	83 c8 40             	or     $0x40,%eax
f01038b3:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f01038b8:	a0 8e c6 11 f0       	mov    0xf011c68e,%al
f01038bd:	83 e0 7f             	and    $0x7f,%eax
f01038c0:	a2 8e c6 11 f0       	mov    %al,0xf011c68e
f01038c5:	b8 60 f7 14 f0       	mov    $0xf014f760,%eax
f01038ca:	c1 e8 18             	shr    $0x18,%eax
f01038cd:	a2 8f c6 11 f0       	mov    %al,0xf011c68f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;
f01038d2:	a0 8d c6 11 f0       	mov    0xf011c68d,%al
f01038d7:	83 e0 ef             	and    $0xffffffef,%eax
f01038da:	a2 8d c6 11 f0       	mov    %al,0xf011c68d
f01038df:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
}

static __inline void
ltr(uint16 sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038e5:	66 8b 45 fe          	mov    -0x2(%ebp),%ax
f01038e9:	0f 00 d8             	ltr    %ax

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
f01038ec:	0f 01 1d f8 c6 11 f0 	lidtl  0xf011c6f8
}
f01038f3:	90                   	nop
f01038f4:	c9                   	leave  
f01038f5:	c3                   	ret    

f01038f6 <print_trapframe>:

void
print_trapframe(struct Trapframe *tf)
{
f01038f6:	55                   	push   %ebp
f01038f7:	89 e5                	mov    %esp,%ebp
f01038f9:	83 ec 08             	sub    $0x8,%esp
	cprintf("TRAP frame at %p\n", tf);
f01038fc:	83 ec 08             	sub    $0x8,%esp
f01038ff:	ff 75 08             	pushl  0x8(%ebp)
f0103902:	68 1b 68 10 f0       	push   $0xf010681b
f0103907:	e8 d0 fd ff ff       	call   f01036dc <cprintf>
f010390c:	83 c4 10             	add    $0x10,%esp
	print_regs(&tf->tf_regs);
f010390f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103912:	83 ec 0c             	sub    $0xc,%esp
f0103915:	50                   	push   %eax
f0103916:	e8 f6 00 00 00       	call   f0103a11 <print_regs>
f010391b:	83 c4 10             	add    $0x10,%esp
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010391e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103921:	8b 40 20             	mov    0x20(%eax),%eax
f0103924:	0f b7 c0             	movzwl %ax,%eax
f0103927:	83 ec 08             	sub    $0x8,%esp
f010392a:	50                   	push   %eax
f010392b:	68 2d 68 10 f0       	push   $0xf010682d
f0103930:	e8 a7 fd ff ff       	call   f01036dc <cprintf>
f0103935:	83 c4 10             	add    $0x10,%esp
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103938:	8b 45 08             	mov    0x8(%ebp),%eax
f010393b:	8b 40 24             	mov    0x24(%eax),%eax
f010393e:	0f b7 c0             	movzwl %ax,%eax
f0103941:	83 ec 08             	sub    $0x8,%esp
f0103944:	50                   	push   %eax
f0103945:	68 40 68 10 f0       	push   $0xf0106840
f010394a:	e8 8d fd ff ff       	call   f01036dc <cprintf>
f010394f:	83 c4 10             	add    $0x10,%esp
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103952:	8b 45 08             	mov    0x8(%ebp),%eax
f0103955:	8b 40 28             	mov    0x28(%eax),%eax
f0103958:	83 ec 0c             	sub    $0xc,%esp
f010395b:	50                   	push   %eax
f010395c:	e8 a1 fd ff ff       	call   f0103702 <trapname>
f0103961:	83 c4 10             	add    $0x10,%esp
f0103964:	89 c2                	mov    %eax,%edx
f0103966:	8b 45 08             	mov    0x8(%ebp),%eax
f0103969:	8b 40 28             	mov    0x28(%eax),%eax
f010396c:	83 ec 04             	sub    $0x4,%esp
f010396f:	52                   	push   %edx
f0103970:	50                   	push   %eax
f0103971:	68 53 68 10 f0       	push   $0xf0106853
f0103976:	e8 61 fd ff ff       	call   f01036dc <cprintf>
f010397b:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x\n", tf->tf_err);
f010397e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103981:	8b 40 2c             	mov    0x2c(%eax),%eax
f0103984:	83 ec 08             	sub    $0x8,%esp
f0103987:	50                   	push   %eax
f0103988:	68 65 68 10 f0       	push   $0xf0106865
f010398d:	e8 4a fd ff ff       	call   f01036dc <cprintf>
f0103992:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103995:	8b 45 08             	mov    0x8(%ebp),%eax
f0103998:	8b 40 30             	mov    0x30(%eax),%eax
f010399b:	83 ec 08             	sub    $0x8,%esp
f010399e:	50                   	push   %eax
f010399f:	68 74 68 10 f0       	push   $0xf0106874
f01039a4:	e8 33 fd ff ff       	call   f01036dc <cprintf>
f01039a9:	83 c4 10             	add    $0x10,%esp
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01039ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01039af:	8b 40 34             	mov    0x34(%eax),%eax
f01039b2:	0f b7 c0             	movzwl %ax,%eax
f01039b5:	83 ec 08             	sub    $0x8,%esp
f01039b8:	50                   	push   %eax
f01039b9:	68 83 68 10 f0       	push   $0xf0106883
f01039be:	e8 19 fd ff ff       	call   f01036dc <cprintf>
f01039c3:	83 c4 10             	add    $0x10,%esp
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01039c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c9:	8b 40 38             	mov    0x38(%eax),%eax
f01039cc:	83 ec 08             	sub    $0x8,%esp
f01039cf:	50                   	push   %eax
f01039d0:	68 96 68 10 f0       	push   $0xf0106896
f01039d5:	e8 02 fd ff ff       	call   f01036dc <cprintf>
f01039da:	83 c4 10             	add    $0x10,%esp
	cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01039e0:	8b 40 3c             	mov    0x3c(%eax),%eax
f01039e3:	83 ec 08             	sub    $0x8,%esp
f01039e6:	50                   	push   %eax
f01039e7:	68 a5 68 10 f0       	push   $0xf01068a5
f01039ec:	e8 eb fc ff ff       	call   f01036dc <cprintf>
f01039f1:	83 c4 10             	add    $0x10,%esp
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01039f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01039f7:	8b 40 40             	mov    0x40(%eax),%eax
f01039fa:	0f b7 c0             	movzwl %ax,%eax
f01039fd:	83 ec 08             	sub    $0x8,%esp
f0103a00:	50                   	push   %eax
f0103a01:	68 b4 68 10 f0       	push   $0xf01068b4
f0103a06:	e8 d1 fc ff ff       	call   f01036dc <cprintf>
f0103a0b:	83 c4 10             	add    $0x10,%esp
}
f0103a0e:	90                   	nop
f0103a0f:	c9                   	leave  
f0103a10:	c3                   	ret    

f0103a11 <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f0103a11:	55                   	push   %ebp
f0103a12:	89 e5                	mov    %esp,%ebp
f0103a14:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a17:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a1a:	8b 00                	mov    (%eax),%eax
f0103a1c:	83 ec 08             	sub    $0x8,%esp
f0103a1f:	50                   	push   %eax
f0103a20:	68 c7 68 10 f0       	push   $0xf01068c7
f0103a25:	e8 b2 fc ff ff       	call   f01036dc <cprintf>
f0103a2a:	83 c4 10             	add    $0x10,%esp
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a30:	8b 40 04             	mov    0x4(%eax),%eax
f0103a33:	83 ec 08             	sub    $0x8,%esp
f0103a36:	50                   	push   %eax
f0103a37:	68 d6 68 10 f0       	push   $0xf01068d6
f0103a3c:	e8 9b fc ff ff       	call   f01036dc <cprintf>
f0103a41:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a47:	8b 40 08             	mov    0x8(%eax),%eax
f0103a4a:	83 ec 08             	sub    $0x8,%esp
f0103a4d:	50                   	push   %eax
f0103a4e:	68 e5 68 10 f0       	push   $0xf01068e5
f0103a53:	e8 84 fc ff ff       	call   f01036dc <cprintf>
f0103a58:	83 c4 10             	add    $0x10,%esp
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a5e:	8b 40 0c             	mov    0xc(%eax),%eax
f0103a61:	83 ec 08             	sub    $0x8,%esp
f0103a64:	50                   	push   %eax
f0103a65:	68 f4 68 10 f0       	push   $0xf01068f4
f0103a6a:	e8 6d fc ff ff       	call   f01036dc <cprintf>
f0103a6f:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a72:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a75:	8b 40 10             	mov    0x10(%eax),%eax
f0103a78:	83 ec 08             	sub    $0x8,%esp
f0103a7b:	50                   	push   %eax
f0103a7c:	68 03 69 10 f0       	push   $0xf0106903
f0103a81:	e8 56 fc ff ff       	call   f01036dc <cprintf>
f0103a86:	83 c4 10             	add    $0x10,%esp
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a89:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a8c:	8b 40 14             	mov    0x14(%eax),%eax
f0103a8f:	83 ec 08             	sub    $0x8,%esp
f0103a92:	50                   	push   %eax
f0103a93:	68 12 69 10 f0       	push   $0xf0106912
f0103a98:	e8 3f fc ff ff       	call   f01036dc <cprintf>
f0103a9d:	83 c4 10             	add    $0x10,%esp
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103aa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aa3:	8b 40 18             	mov    0x18(%eax),%eax
f0103aa6:	83 ec 08             	sub    $0x8,%esp
f0103aa9:	50                   	push   %eax
f0103aaa:	68 21 69 10 f0       	push   $0xf0106921
f0103aaf:	e8 28 fc ff ff       	call   f01036dc <cprintf>
f0103ab4:	83 c4 10             	add    $0x10,%esp
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ab7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aba:	8b 40 1c             	mov    0x1c(%eax),%eax
f0103abd:	83 ec 08             	sub    $0x8,%esp
f0103ac0:	50                   	push   %eax
f0103ac1:	68 30 69 10 f0       	push   $0xf0106930
f0103ac6:	e8 11 fc ff ff       	call   f01036dc <cprintf>
f0103acb:	83 c4 10             	add    $0x10,%esp
}
f0103ace:	90                   	nop
f0103acf:	c9                   	leave  
f0103ad0:	c3                   	ret    

f0103ad1 <trap_dispatch>:

static void
trap_dispatch(struct Trapframe *tf)
{
f0103ad1:	55                   	push   %ebp
f0103ad2:	89 e5                	mov    %esp,%ebp
f0103ad4:	57                   	push   %edi
f0103ad5:	56                   	push   %esi
f0103ad6:	53                   	push   %ebx
f0103ad7:	83 ec 1c             	sub    $0x1c,%esp
	// Handle processor exceptions.
	// LAB 3: Your code here.

	if(tf->tf_trapno == T_PGFLT)
f0103ada:	8b 45 08             	mov    0x8(%ebp),%eax
f0103add:	8b 40 28             	mov    0x28(%eax),%eax
f0103ae0:	83 f8 0e             	cmp    $0xe,%eax
f0103ae3:	75 13                	jne    f0103af8 <trap_dispatch+0x27>
	{
		page_fault_handler(tf);
f0103ae5:	83 ec 0c             	sub    $0xc,%esp
f0103ae8:	ff 75 08             	pushl  0x8(%ebp)
f0103aeb:	e8 47 01 00 00       	call   f0103c37 <page_fault_handler>
f0103af0:	83 c4 10             	add    $0x10,%esp
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0103af3:	e9 90 00 00 00       	jmp    f0103b88 <trap_dispatch+0xb7>

	if(tf->tf_trapno == T_PGFLT)
	{
		page_fault_handler(tf);
	}
	else if (tf->tf_trapno == T_SYSCALL)
f0103af8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103afb:	8b 40 28             	mov    0x28(%eax),%eax
f0103afe:	83 f8 30             	cmp    $0x30,%eax
f0103b01:	75 42                	jne    f0103b45 <trap_dispatch+0x74>
	{
		uint32 ret = syscall(tf->tf_regs.reg_eax
f0103b03:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b06:	8b 78 04             	mov    0x4(%eax),%edi
f0103b09:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b0c:	8b 30                	mov    (%eax),%esi
f0103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b11:	8b 58 10             	mov    0x10(%eax),%ebx
f0103b14:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b17:	8b 48 18             	mov    0x18(%eax),%ecx
f0103b1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b1d:	8b 50 14             	mov    0x14(%eax),%edx
f0103b20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b23:	8b 40 1c             	mov    0x1c(%eax),%eax
f0103b26:	83 ec 08             	sub    $0x8,%esp
f0103b29:	57                   	push   %edi
f0103b2a:	56                   	push   %esi
f0103b2b:	53                   	push   %ebx
f0103b2c:	51                   	push   %ecx
f0103b2d:	52                   	push   %edx
f0103b2e:	50                   	push   %eax
f0103b2f:	e8 48 04 00 00       	call   f0103f7c <syscall>
f0103b34:	83 c4 20             	add    $0x20,%esp
f0103b37:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			,tf->tf_regs.reg_edx
			,tf->tf_regs.reg_ecx
			,tf->tf_regs.reg_ebx
			,tf->tf_regs.reg_edi
					,tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f0103b3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b3d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103b40:	89 50 1c             	mov    %edx,0x1c(%eax)
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0103b43:	eb 43                	jmp    f0103b88 <trap_dispatch+0xb7>
		tf->tf_regs.reg_eax = ret;
	}
	else
	{
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103b45:	83 ec 0c             	sub    $0xc,%esp
f0103b48:	ff 75 08             	pushl  0x8(%ebp)
f0103b4b:	e8 a6 fd ff ff       	call   f01038f6 <print_trapframe>
f0103b50:	83 c4 10             	add    $0x10,%esp
		if (tf->tf_cs == GD_KT)
f0103b53:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b56:	8b 40 34             	mov    0x34(%eax),%eax
f0103b59:	66 83 f8 08          	cmp    $0x8,%ax
f0103b5d:	75 17                	jne    f0103b76 <trap_dispatch+0xa5>
			panic("unhandled trap in kernel");
f0103b5f:	83 ec 04             	sub    $0x4,%esp
f0103b62:	68 3f 69 10 f0       	push   $0xf010693f
f0103b67:	68 8a 00 00 00       	push   $0x8a
f0103b6c:	68 58 69 10 f0       	push   $0xf0106958
f0103b71:	e8 b8 c5 ff ff       	call   f010012e <_panic>
		else {
			env_destroy(curenv);
f0103b76:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103b7b:	83 ec 0c             	sub    $0xc,%esp
f0103b7e:	50                   	push   %eax
f0103b7f:	e8 a2 f9 ff ff       	call   f0103526 <env_destroy>
f0103b84:	83 c4 10             	add    $0x10,%esp
			return;
f0103b87:	90                   	nop
		}
	}
	return;
}
f0103b88:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b8b:	5b                   	pop    %ebx
f0103b8c:	5e                   	pop    %esi
f0103b8d:	5f                   	pop    %edi
f0103b8e:	5d                   	pop    %ebp
f0103b8f:	c3                   	ret    

f0103b90 <trap>:

void
trap(struct Trapframe *tf)
{
f0103b90:	55                   	push   %ebp
f0103b91:	89 e5                	mov    %esp,%ebp
f0103b93:	57                   	push   %edi
f0103b94:	56                   	push   %esi
f0103b95:	53                   	push   %ebx
f0103b96:	83 ec 0c             	sub    $0xc,%esp
	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f0103b99:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b9c:	8b 40 34             	mov    0x34(%eax),%eax
f0103b9f:	0f b7 c0             	movzwl %ax,%eax
f0103ba2:	83 e0 03             	and    $0x3,%eax
f0103ba5:	83 f8 03             	cmp    $0x3,%eax
f0103ba8:	75 42                	jne    f0103bec <trap+0x5c>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103baa:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103baf:	85 c0                	test   %eax,%eax
f0103bb1:	75 19                	jne    f0103bcc <trap+0x3c>
f0103bb3:	68 64 69 10 f0       	push   $0xf0106964
f0103bb8:	68 6b 69 10 f0       	push   $0xf010696b
f0103bbd:	68 9d 00 00 00       	push   $0x9d
f0103bc2:	68 58 69 10 f0       	push   $0xf0106958
f0103bc7:	e8 62 c5 ff ff       	call   f010012e <_panic>
		curenv->env_tf = *tf;
f0103bcc:	8b 15 50 ef 14 f0    	mov    0xf014ef50,%edx
f0103bd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bd5:	89 c3                	mov    %eax,%ebx
f0103bd7:	b8 11 00 00 00       	mov    $0x11,%eax
f0103bdc:	89 d7                	mov    %edx,%edi
f0103bde:	89 de                	mov    %ebx,%esi
f0103be0:	89 c1                	mov    %eax,%ecx
f0103be2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103be4:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103be9:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103bec:	83 ec 0c             	sub    $0xc,%esp
f0103bef:	ff 75 08             	pushl  0x8(%ebp)
f0103bf2:	e8 da fe ff ff       	call   f0103ad1 <trap_dispatch>
f0103bf7:	83 c4 10             	add    $0x10,%esp

        // Return to the current environment, which should be runnable.
        assert(curenv && curenv->env_status == ENV_RUNNABLE);
f0103bfa:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103bff:	85 c0                	test   %eax,%eax
f0103c01:	74 0d                	je     f0103c10 <trap+0x80>
f0103c03:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c08:	8b 40 54             	mov    0x54(%eax),%eax
f0103c0b:	83 f8 01             	cmp    $0x1,%eax
f0103c0e:	74 19                	je     f0103c29 <trap+0x99>
f0103c10:	68 80 69 10 f0       	push   $0xf0106980
f0103c15:	68 6b 69 10 f0       	push   $0xf010696b
f0103c1a:	68 a7 00 00 00       	push   $0xa7
f0103c1f:	68 58 69 10 f0       	push   $0xf0106958
f0103c24:	e8 05 c5 ff ff       	call   f010012e <_panic>
        env_run(curenv);
f0103c29:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c2e:	83 ec 0c             	sub    $0xc,%esp
f0103c31:	50                   	push   %eax
f0103c32:	e8 01 f3 ff ff       	call   f0102f38 <env_run>

f0103c37 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c37:	55                   	push   %ebp
f0103c38:	89 e5                	mov    %esp,%ebp
f0103c3a:	83 ec 18             	sub    $0x18,%esp

static __inline uint32
rcr2(void)
{
	uint32 val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103c3d:	0f 20 d0             	mov    %cr2,%eax
f0103c40:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
f0103c43:	8b 45 f0             	mov    -0x10(%ebp),%eax
	uint32 fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103c46:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c49:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c4c:	8b 50 30             	mov    0x30(%eax),%edx
	curenv->env_id, fault_va, tf->tf_eip);
f0103c4f:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c54:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103c57:	52                   	push   %edx
f0103c58:	ff 75 f4             	pushl  -0xc(%ebp)
f0103c5b:	50                   	push   %eax
f0103c5c:	68 b0 69 10 f0       	push   $0xf01069b0
f0103c61:	e8 76 fa ff ff       	call   f01036dc <cprintf>
f0103c66:	83 c4 10             	add    $0x10,%esp
	curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103c69:	83 ec 0c             	sub    $0xc,%esp
f0103c6c:	ff 75 08             	pushl  0x8(%ebp)
f0103c6f:	e8 82 fc ff ff       	call   f01038f6 <print_trapframe>
f0103c74:	83 c4 10             	add    $0x10,%esp
	env_destroy(curenv);
f0103c77:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103c7c:	83 ec 0c             	sub    $0xc,%esp
f0103c7f:	50                   	push   %eax
f0103c80:	e8 a1 f8 ff ff       	call   f0103526 <env_destroy>
f0103c85:	83 c4 10             	add    $0x10,%esp

}
f0103c88:	90                   	nop
f0103c89:	c9                   	leave  
f0103c8a:	c3                   	ret    
f0103c8b:	90                   	nop

f0103c8c <PAGE_FAULT>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(PAGE_FAULT, T_PGFLT)		
f0103c8c:	6a 0e                	push   $0xe
f0103c8e:	eb 06                	jmp    f0103c96 <_alltraps>

f0103c90 <SYSCALL_HANDLER>:

TRAPHANDLER_NOEC(SYSCALL_HANDLER, T_SYSCALL)
f0103c90:	6a 00                	push   $0x0
f0103c92:	6a 30                	push   $0x30
f0103c94:	eb 00                	jmp    f0103c96 <_alltraps>

f0103c96 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:

push %ds 
f0103c96:	1e                   	push   %ds
push %es 
f0103c97:	06                   	push   %es
pushal 	
f0103c98:	60                   	pusha  

mov $(GD_KD), %ax 
f0103c99:	66 b8 10 00          	mov    $0x10,%ax
mov %ax,%ds
f0103c9d:	8e d8                	mov    %eax,%ds
mov %ax,%es
f0103c9f:	8e c0                	mov    %eax,%es

push %esp
f0103ca1:	54                   	push   %esp

call trap
f0103ca2:	e8 e9 fe ff ff       	call   f0103b90 <trap>

pop %ecx /* poping the pointer to the tf from the stack so that the stack top is at the values of the registers posuhed by pusha*/
f0103ca7:	59                   	pop    %ecx
popal 	
f0103ca8:	61                   	popa   
pop %es 
f0103ca9:	07                   	pop    %es
pop %ds    
f0103caa:	1f                   	pop    %ds

/*skipping the trap_no and the error code so that the stack top is at the old eip value*/
add $(8),%esp
f0103cab:	83 c4 08             	add    $0x8,%esp

iret
f0103cae:	cf                   	iret   

f0103caf <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0103caf:	55                   	push   %ebp
f0103cb0:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0103cb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cb5:	8b 15 dc f7 14 f0    	mov    0xf014f7dc,%edx
f0103cbb:	29 d0                	sub    %edx,%eax
f0103cbd:	c1 f8 02             	sar    $0x2,%eax
f0103cc0:	89 c2                	mov    %eax,%edx
f0103cc2:	89 d0                	mov    %edx,%eax
f0103cc4:	c1 e0 02             	shl    $0x2,%eax
f0103cc7:	01 d0                	add    %edx,%eax
f0103cc9:	c1 e0 02             	shl    $0x2,%eax
f0103ccc:	01 d0                	add    %edx,%eax
f0103cce:	c1 e0 02             	shl    $0x2,%eax
f0103cd1:	01 d0                	add    %edx,%eax
f0103cd3:	89 c1                	mov    %eax,%ecx
f0103cd5:	c1 e1 08             	shl    $0x8,%ecx
f0103cd8:	01 c8                	add    %ecx,%eax
f0103cda:	89 c1                	mov    %eax,%ecx
f0103cdc:	c1 e1 10             	shl    $0x10,%ecx
f0103cdf:	01 c8                	add    %ecx,%eax
f0103ce1:	01 c0                	add    %eax,%eax
f0103ce3:	01 d0                	add    %edx,%eax
}
f0103ce5:	5d                   	pop    %ebp
f0103ce6:	c3                   	ret    

f0103ce7 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0103ce7:	55                   	push   %ebp
f0103ce8:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0103cea:	ff 75 08             	pushl  0x8(%ebp)
f0103ced:	e8 bd ff ff ff       	call   f0103caf <to_frame_number>
f0103cf2:	83 c4 04             	add    $0x4,%esp
f0103cf5:	c1 e0 0c             	shl    $0xc,%eax
}
f0103cf8:	c9                   	leave  
f0103cf9:	c3                   	ret    

f0103cfa <sys_cputs>:

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void sys_cputs(const char *s, uint32 len)
{
f0103cfa:	55                   	push   %ebp
f0103cfb:	89 e5                	mov    %esp,%ebp
f0103cfd:	83 ec 08             	sub    $0x8,%esp
	// Destroy the environment if not.
	
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103d00:	83 ec 04             	sub    $0x4,%esp
f0103d03:	ff 75 08             	pushl  0x8(%ebp)
f0103d06:	ff 75 0c             	pushl  0xc(%ebp)
f0103d09:	68 70 6b 10 f0       	push   $0xf0106b70
f0103d0e:	e8 c9 f9 ff ff       	call   f01036dc <cprintf>
f0103d13:	83 c4 10             	add    $0x10,%esp
}
f0103d16:	90                   	nop
f0103d17:	c9                   	leave  
f0103d18:	c3                   	ret    

f0103d19 <sys_cgetc>:

// Read a character from the system console.
// Returns the character.
static int
sys_cgetc(void)
{
f0103d19:	55                   	push   %ebp
f0103d1a:	89 e5                	mov    %esp,%ebp
f0103d1c:	83 ec 18             	sub    $0x18,%esp
	int c;

	// The cons_getc() primitive doesn't wait for a character,
	// but the sys_cgetc() system call does.
	while ((c = cons_getc()) == 0)
f0103d1f:	e8 45 cb ff ff       	call   f0100869 <cons_getc>
f0103d24:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103d27:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103d2b:	74 f2                	je     f0103d1f <sys_cgetc+0x6>
		/* do nothing */;

	return c;
f0103d2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0103d30:	c9                   	leave  
f0103d31:	c3                   	ret    

f0103d32 <sys_getenvid>:

// Returns the current environment's envid.
static int32 sys_getenvid(void)
{
f0103d32:	55                   	push   %ebp
f0103d33:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f0103d35:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103d3a:	8b 40 4c             	mov    0x4c(%eax),%eax
}
f0103d3d:	5d                   	pop    %ebp
f0103d3e:	c3                   	ret    

f0103d3f <sys_env_destroy>:
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int sys_env_destroy(int32  envid)
{
f0103d3f:	55                   	push   %ebp
f0103d40:	89 e5                	mov    %esp,%ebp
f0103d42:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103d45:	83 ec 04             	sub    $0x4,%esp
f0103d48:	6a 01                	push   $0x1
f0103d4a:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0103d4d:	50                   	push   %eax
f0103d4e:	ff 75 08             	pushl  0x8(%ebp)
f0103d51:	e8 47 e5 ff ff       	call   f010229d <envid2env>
f0103d56:	83 c4 10             	add    $0x10,%esp
f0103d59:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103d5c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103d60:	79 05                	jns    f0103d67 <sys_env_destroy+0x28>
		return r;
f0103d62:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d65:	eb 5b                	jmp    f0103dc2 <sys_env_destroy+0x83>
	if (e == curenv)
f0103d67:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103d6a:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103d6f:	39 c2                	cmp    %eax,%edx
f0103d71:	75 1b                	jne    f0103d8e <sys_env_destroy+0x4f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103d73:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103d78:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103d7b:	83 ec 08             	sub    $0x8,%esp
f0103d7e:	50                   	push   %eax
f0103d7f:	68 75 6b 10 f0       	push   $0xf0106b75
f0103d84:	e8 53 f9 ff ff       	call   f01036dc <cprintf>
f0103d89:	83 c4 10             	add    $0x10,%esp
f0103d8c:	eb 20                	jmp    f0103dae <sys_env_destroy+0x6f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103d8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103d91:	8b 50 4c             	mov    0x4c(%eax),%edx
f0103d94:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103d99:	8b 40 4c             	mov    0x4c(%eax),%eax
f0103d9c:	83 ec 04             	sub    $0x4,%esp
f0103d9f:	52                   	push   %edx
f0103da0:	50                   	push   %eax
f0103da1:	68 90 6b 10 f0       	push   $0xf0106b90
f0103da6:	e8 31 f9 ff ff       	call   f01036dc <cprintf>
f0103dab:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103dae:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103db1:	83 ec 0c             	sub    $0xc,%esp
f0103db4:	50                   	push   %eax
f0103db5:	e8 6c f7 ff ff       	call   f0103526 <env_destroy>
f0103dba:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103dbd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103dc2:	c9                   	leave  
f0103dc3:	c3                   	ret    

f0103dc4 <sys_env_sleep>:

static void sys_env_sleep()
{
f0103dc4:	55                   	push   %ebp
f0103dc5:	89 e5                	mov    %esp,%ebp
f0103dc7:	83 ec 08             	sub    $0x8,%esp
	env_run_cmd_prmpt();
f0103dca:	e8 72 f7 ff ff       	call   f0103541 <env_run_cmd_prmpt>
}
f0103dcf:	90                   	nop
f0103dd0:	c9                   	leave  
f0103dd1:	c3                   	ret    

f0103dd2 <sys_allocate_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_allocate_page(void *va, int perm)
{
f0103dd2:	55                   	push   %ebp
f0103dd3:	89 e5                	mov    %esp,%ebp
f0103dd5:	83 ec 28             	sub    $0x28,%esp
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
	
	int r;
	struct Env *e = curenv;
f0103dd8:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103ddd:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//if ((r = envid2env(envid, &e, 1)) < 0)
		//return r;
	
	struct Frame_Info *ptr_frame_info ;
	r = allocate_frame(&ptr_frame_info) ;
f0103de0:	83 ec 0c             	sub    $0xc,%esp
f0103de3:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103de6:	50                   	push   %eax
f0103de7:	e8 3f ec ff ff       	call   f0102a2b <allocate_frame>
f0103dec:	83 c4 10             	add    $0x10,%esp
f0103def:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103df2:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0103df6:	75 08                	jne    f0103e00 <sys_allocate_page+0x2e>
		return r ;
f0103df8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103dfb:	e9 cc 00 00 00       	jmp    f0103ecc <sys_allocate_page+0xfa>
	
	//check virtual address to be paged_aligned and < USER_TOP
	if ((uint32)va >= USER_TOP || (uint32)va % PAGE_SIZE != 0)
f0103e00:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e03:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f0103e08:	77 0c                	ja     f0103e16 <sys_allocate_page+0x44>
f0103e0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e0d:	25 ff 0f 00 00       	and    $0xfff,%eax
f0103e12:	85 c0                	test   %eax,%eax
f0103e14:	74 0a                	je     f0103e20 <sys_allocate_page+0x4e>
		return E_INVAL;
f0103e16:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103e1b:	e9 ac 00 00 00       	jmp    f0103ecc <sys_allocate_page+0xfa>
	
	//check permissions to be appropriatess
	if ((perm & (~PERM_AVAILABLE & ~PERM_WRITEABLE)) != (PERM_USER))
f0103e20:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e23:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0103e28:	83 f8 04             	cmp    $0x4,%eax
f0103e2b:	74 0a                	je     f0103e37 <sys_allocate_page+0x65>
		return E_INVAL;
f0103e2d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103e32:	e9 95 00 00 00       	jmp    f0103ecc <sys_allocate_page+0xfa>
	
			
	uint32 physical_address = to_physical_address(ptr_frame_info) ;
f0103e37:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e3a:	83 ec 0c             	sub    $0xc,%esp
f0103e3d:	50                   	push   %eax
f0103e3e:	e8 a4 fe ff ff       	call   f0103ce7 <to_physical_address>
f0103e43:	83 c4 10             	add    $0x10,%esp
f0103e46:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	memset(K_VIRTUAL_ADDRESS(physical_address), 0, PAGE_SIZE);
f0103e49:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e4c:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0103e4f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e52:	c1 e8 0c             	shr    $0xc,%eax
f0103e55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e58:	a1 c8 f7 14 f0       	mov    0xf014f7c8,%eax
f0103e5d:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0103e60:	72 14                	jb     f0103e76 <sys_allocate_page+0xa4>
f0103e62:	ff 75 e8             	pushl  -0x18(%ebp)
f0103e65:	68 a8 6b 10 f0       	push   $0xf0106ba8
f0103e6a:	6a 7a                	push   $0x7a
f0103e6c:	68 d7 6b 10 f0       	push   $0xf0106bd7
f0103e71:	e8 b8 c2 ff ff       	call   f010012e <_panic>
f0103e76:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103e79:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103e7e:	83 ec 04             	sub    $0x4,%esp
f0103e81:	68 00 10 00 00       	push   $0x1000
f0103e86:	6a 00                	push   $0x0
f0103e88:	50                   	push   %eax
f0103e89:	e8 31 0f 00 00       	call   f0104dbf <memset>
f0103e8e:	83 c4 10             	add    $0x10,%esp
		
	r = map_frame(e->env_pgdir, ptr_frame_info, va, perm) ;
f0103e91:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e97:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103e9a:	ff 75 0c             	pushl  0xc(%ebp)
f0103e9d:	ff 75 08             	pushl  0x8(%ebp)
f0103ea0:	52                   	push   %edx
f0103ea1:	50                   	push   %eax
f0103ea2:	e8 91 ed ff ff       	call   f0102c38 <map_frame>
f0103ea7:	83 c4 10             	add    $0x10,%esp
f0103eaa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0103ead:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0103eb1:	75 14                	jne    f0103ec7 <sys_allocate_page+0xf5>
	{
		decrement_references(ptr_frame_info);
f0103eb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103eb6:	83 ec 0c             	sub    $0xc,%esp
f0103eb9:	50                   	push   %eax
f0103eba:	e8 0a ec ff ff       	call   f0102ac9 <decrement_references>
f0103ebf:	83 c4 10             	add    $0x10,%esp
		return r;
f0103ec2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103ec5:	eb 05                	jmp    f0103ecc <sys_allocate_page+0xfa>
	}
	return 0 ;
f0103ec7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ecc:	c9                   	leave  
f0103ecd:	c3                   	ret    

f0103ece <sys_get_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_get_page(void *va, int perm)
{
f0103ece:	55                   	push   %ebp
f0103ecf:	89 e5                	mov    %esp,%ebp
f0103ed1:	83 ec 08             	sub    $0x8,%esp
	return get_page(curenv->env_pgdir, va, perm) ;
f0103ed4:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103ed9:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103edc:	83 ec 04             	sub    $0x4,%esp
f0103edf:	ff 75 0c             	pushl  0xc(%ebp)
f0103ee2:	ff 75 08             	pushl  0x8(%ebp)
f0103ee5:	50                   	push   %eax
f0103ee6:	e8 cb ee ff ff       	call   f0102db6 <get_page>
f0103eeb:	83 c4 10             	add    $0x10,%esp
}
f0103eee:	c9                   	leave  
f0103eef:	c3                   	ret    

f0103ef0 <sys_map_frame>:
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_map_frame(int32 srcenvid, void *srcva, int32 dstenvid, void *dstva, int perm)
{
f0103ef0:	55                   	push   %ebp
f0103ef1:	89 e5                	mov    %esp,%ebp
f0103ef3:	83 ec 08             	sub    $0x8,%esp
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	panic("sys_map_frame not implemented");
f0103ef6:	83 ec 04             	sub    $0x4,%esp
f0103ef9:	68 e6 6b 10 f0       	push   $0xf0106be6
f0103efe:	68 b1 00 00 00       	push   $0xb1
f0103f03:	68 d7 6b 10 f0       	push   $0xf0106bd7
f0103f08:	e8 21 c2 ff ff       	call   f010012e <_panic>

f0103f0d <sys_unmap_frame>:
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int sys_unmap_frame(int32 envid, void *va)
{
f0103f0d:	55                   	push   %ebp
f0103f0e:	89 e5                	mov    %esp,%ebp
f0103f10:	83 ec 08             	sub    $0x8,%esp
	// Hint: This function is a wrapper around page_remove().
	
	// LAB 4: Your code here.
	panic("sys_page_unmap not implemented");
f0103f13:	83 ec 04             	sub    $0x4,%esp
f0103f16:	68 04 6c 10 f0       	push   $0xf0106c04
f0103f1b:	68 c0 00 00 00       	push   $0xc0
f0103f20:	68 d7 6b 10 f0       	push   $0xf0106bd7
f0103f25:	e8 04 c2 ff ff       	call   f010012e <_panic>

f0103f2a <sys_calculate_required_frames>:
}

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
f0103f2a:	55                   	push   %ebp
f0103f2b:	89 e5                	mov    %esp,%ebp
f0103f2d:	83 ec 08             	sub    $0x8,%esp
	return calculate_required_frames(curenv->env_pgdir, start_virtual_address, size); 
f0103f30:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103f35:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103f38:	83 ec 04             	sub    $0x4,%esp
f0103f3b:	ff 75 0c             	pushl  0xc(%ebp)
f0103f3e:	ff 75 08             	pushl  0x8(%ebp)
f0103f41:	50                   	push   %eax
f0103f42:	e8 8c ee ff ff       	call   f0102dd3 <calculate_required_frames>
f0103f47:	83 c4 10             	add    $0x10,%esp
}
f0103f4a:	c9                   	leave  
f0103f4b:	c3                   	ret    

f0103f4c <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
f0103f4c:	55                   	push   %ebp
f0103f4d:	89 e5                	mov    %esp,%ebp
f0103f4f:	83 ec 08             	sub    $0x8,%esp
	return calculate_free_frames();
f0103f52:	e8 99 ee ff ff       	call   f0102df0 <calculate_free_frames>
}
f0103f57:	c9                   	leave  
f0103f58:	c3                   	ret    

f0103f59 <sys_freeMem>:
void sys_freeMem(void* start_virtual_address, uint32 size)
{
f0103f59:	55                   	push   %ebp
f0103f5a:	89 e5                	mov    %esp,%ebp
f0103f5c:	83 ec 08             	sub    $0x8,%esp
	freeMem((uint32*)curenv->env_pgdir, (void*)start_virtual_address, size);
f0103f5f:	a1 50 ef 14 f0       	mov    0xf014ef50,%eax
f0103f64:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103f67:	83 ec 04             	sub    $0x4,%esp
f0103f6a:	ff 75 0c             	pushl  0xc(%ebp)
f0103f6d:	ff 75 08             	pushl  0x8(%ebp)
f0103f70:	50                   	push   %eax
f0103f71:	e8 a7 ee ff ff       	call   f0102e1d <freeMem>
f0103f76:	83 c4 10             	add    $0x10,%esp
	return;
f0103f79:	90                   	nop
}
f0103f7a:	c9                   	leave  
f0103f7b:	c3                   	ret    

f0103f7c <syscall>:
// Dispatches to the correct kernel function, passing the arguments.
uint32
syscall(uint32 syscallno, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
f0103f7c:	55                   	push   %ebp
f0103f7d:	89 e5                	mov    %esp,%ebp
f0103f7f:	56                   	push   %esi
f0103f80:	53                   	push   %ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch(syscallno)
f0103f81:	83 7d 08 0c          	cmpl   $0xc,0x8(%ebp)
f0103f85:	0f 87 19 01 00 00    	ja     f01040a4 <syscall+0x128>
f0103f8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f8e:	c1 e0 02             	shl    $0x2,%eax
f0103f91:	05 24 6c 10 f0       	add    $0xf0106c24,%eax
f0103f96:	8b 00                	mov    (%eax),%eax
f0103f98:	ff e0                	jmp    *%eax
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,a2);
f0103f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f9d:	83 ec 08             	sub    $0x8,%esp
f0103fa0:	ff 75 10             	pushl  0x10(%ebp)
f0103fa3:	50                   	push   %eax
f0103fa4:	e8 51 fd ff ff       	call   f0103cfa <sys_cputs>
f0103fa9:	83 c4 10             	add    $0x10,%esp
			return 0;
f0103fac:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fb1:	e9 f3 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f0103fb6:	e8 5e fd ff ff       	call   f0103d19 <sys_cgetc>
f0103fbb:	e9 e9 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0103fc0:	e8 6d fd ff ff       	call   f0103d32 <sys_getenvid>
f0103fc5:	e9 df 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_env_destroy:
			return sys_env_destroy(a1);
f0103fca:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fcd:	83 ec 0c             	sub    $0xc,%esp
f0103fd0:	50                   	push   %eax
f0103fd1:	e8 69 fd ff ff       	call   f0103d3f <sys_env_destroy>
f0103fd6:	83 c4 10             	add    $0x10,%esp
f0103fd9:	e9 cb 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_env_sleep:
			sys_env_sleep();
f0103fde:	e8 e1 fd ff ff       	call   f0103dc4 <sys_env_sleep>
			return 0;
f0103fe3:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fe8:	e9 bc 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_calc_req_frames:
			return sys_calculate_required_frames(a1, a2);			
f0103fed:	83 ec 08             	sub    $0x8,%esp
f0103ff0:	ff 75 10             	pushl  0x10(%ebp)
f0103ff3:	ff 75 0c             	pushl  0xc(%ebp)
f0103ff6:	e8 2f ff ff ff       	call   f0103f2a <sys_calculate_required_frames>
f0103ffb:	83 c4 10             	add    $0x10,%esp
f0103ffe:	e9 a6 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_calc_free_frames:
			return sys_calculate_free_frames();			
f0104003:	e8 44 ff ff ff       	call   f0103f4c <sys_calculate_free_frames>
f0104008:	e9 9c 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_freeMem:
			sys_freeMem((void*)a1, a2);
f010400d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104010:	83 ec 08             	sub    $0x8,%esp
f0104013:	ff 75 10             	pushl  0x10(%ebp)
f0104016:	50                   	push   %eax
f0104017:	e8 3d ff ff ff       	call   f0103f59 <sys_freeMem>
f010401c:	83 c4 10             	add    $0x10,%esp
			return 0;			
f010401f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104024:	e9 80 00 00 00       	jmp    f01040a9 <syscall+0x12d>
			break;
		//======================
		
		case SYS_allocate_page:
			sys_allocate_page((void*)a1, a2);
f0104029:	8b 55 10             	mov    0x10(%ebp),%edx
f010402c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010402f:	83 ec 08             	sub    $0x8,%esp
f0104032:	52                   	push   %edx
f0104033:	50                   	push   %eax
f0104034:	e8 99 fd ff ff       	call   f0103dd2 <sys_allocate_page>
f0104039:	83 c4 10             	add    $0x10,%esp
			return 0;
f010403c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104041:	eb 66                	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_get_page:
			sys_get_page((void*)a1, a2);
f0104043:	8b 55 10             	mov    0x10(%ebp),%edx
f0104046:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104049:	83 ec 08             	sub    $0x8,%esp
f010404c:	52                   	push   %edx
f010404d:	50                   	push   %eax
f010404e:	e8 7b fe ff ff       	call   f0103ece <sys_get_page>
f0104053:	83 c4 10             	add    $0x10,%esp
			return 0;
f0104056:	b8 00 00 00 00       	mov    $0x0,%eax
f010405b:	eb 4c                	jmp    f01040a9 <syscall+0x12d>
		break;case SYS_map_frame:
			sys_map_frame(a1, (void*)a2, a3, (void*)a4, a5);
f010405d:	8b 75 1c             	mov    0x1c(%ebp),%esi
f0104060:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0104063:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0104066:	8b 55 10             	mov    0x10(%ebp),%edx
f0104069:	8b 45 0c             	mov    0xc(%ebp),%eax
f010406c:	83 ec 0c             	sub    $0xc,%esp
f010406f:	56                   	push   %esi
f0104070:	53                   	push   %ebx
f0104071:	51                   	push   %ecx
f0104072:	52                   	push   %edx
f0104073:	50                   	push   %eax
f0104074:	e8 77 fe ff ff       	call   f0103ef0 <sys_map_frame>
f0104079:	83 c4 20             	add    $0x20,%esp
			return 0;
f010407c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104081:	eb 26                	jmp    f01040a9 <syscall+0x12d>
			break;
		case SYS_unmap_frame:
			sys_unmap_frame(a1, (void*)a2);
f0104083:	8b 55 10             	mov    0x10(%ebp),%edx
f0104086:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104089:	83 ec 08             	sub    $0x8,%esp
f010408c:	52                   	push   %edx
f010408d:	50                   	push   %eax
f010408e:	e8 7a fe ff ff       	call   f0103f0d <sys_unmap_frame>
f0104093:	83 c4 10             	add    $0x10,%esp
			return 0;
f0104096:	b8 00 00 00 00       	mov    $0x0,%eax
f010409b:	eb 0c                	jmp    f01040a9 <syscall+0x12d>
			break;
		case NSYSCALLS:	
			return 	-E_INVAL;
f010409d:	b8 03 00 00 00       	mov    $0x3,%eax
f01040a2:	eb 05                	jmp    f01040a9 <syscall+0x12d>
			break;
	}
	//panic("syscall not implemented");
	return -E_INVAL;
f01040a4:	b8 03 00 00 00       	mov    $0x3,%eax
}
f01040a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01040ac:	5b                   	pop    %ebx
f01040ad:	5e                   	pop    %esi
f01040ae:	5d                   	pop    %ebp
f01040af:	c3                   	ret    

f01040b0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
f01040b0:	55                   	push   %ebp
f01040b1:	89 e5                	mov    %esp,%ebp
f01040b3:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f01040b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040b9:	8b 00                	mov    (%eax),%eax
f01040bb:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01040be:	8b 45 10             	mov    0x10(%ebp),%eax
f01040c1:	8b 00                	mov    (%eax),%eax
f01040c3:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01040c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f01040cd:	e9 ca 00 00 00       	jmp    f010419c <stab_binsearch+0xec>
		int true_m = (l + r) / 2, m = true_m;
f01040d2:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01040d5:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01040d8:	01 d0                	add    %edx,%eax
f01040da:	89 c2                	mov    %eax,%edx
f01040dc:	c1 ea 1f             	shr    $0x1f,%edx
f01040df:	01 d0                	add    %edx,%eax
f01040e1:	d1 f8                	sar    %eax
f01040e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040ec:	eb 03                	jmp    f01040f1 <stab_binsearch+0x41>
			m--;
f01040ee:	ff 4d f0             	decl   -0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01040f4:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01040f7:	7c 1e                	jl     f0104117 <stab_binsearch+0x67>
f01040f9:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01040fc:	89 d0                	mov    %edx,%eax
f01040fe:	01 c0                	add    %eax,%eax
f0104100:	01 d0                	add    %edx,%eax
f0104102:	c1 e0 02             	shl    $0x2,%eax
f0104105:	89 c2                	mov    %eax,%edx
f0104107:	8b 45 08             	mov    0x8(%ebp),%eax
f010410a:	01 d0                	add    %edx,%eax
f010410c:	8a 40 04             	mov    0x4(%eax),%al
f010410f:	0f b6 c0             	movzbl %al,%eax
f0104112:	3b 45 14             	cmp    0x14(%ebp),%eax
f0104115:	75 d7                	jne    f01040ee <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0104117:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010411a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010411d:	7d 09                	jge    f0104128 <stab_binsearch+0x78>
			l = true_m + 1;
f010411f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104122:	40                   	inc    %eax
f0104123:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0104126:	eb 74                	jmp    f010419c <stab_binsearch+0xec>
		}

		// actual binary search
		any_matches = 1;
f0104128:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f010412f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104132:	89 d0                	mov    %edx,%eax
f0104134:	01 c0                	add    %eax,%eax
f0104136:	01 d0                	add    %edx,%eax
f0104138:	c1 e0 02             	shl    $0x2,%eax
f010413b:	89 c2                	mov    %eax,%edx
f010413d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104140:	01 d0                	add    %edx,%eax
f0104142:	8b 40 08             	mov    0x8(%eax),%eax
f0104145:	3b 45 18             	cmp    0x18(%ebp),%eax
f0104148:	73 11                	jae    f010415b <stab_binsearch+0xab>
			*region_left = m;
f010414a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010414d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104150:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f0104152:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104155:	40                   	inc    %eax
f0104156:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0104159:	eb 41                	jmp    f010419c <stab_binsearch+0xec>
		} else if (stabs[m].n_value > addr) {
f010415b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010415e:	89 d0                	mov    %edx,%eax
f0104160:	01 c0                	add    %eax,%eax
f0104162:	01 d0                	add    %edx,%eax
f0104164:	c1 e0 02             	shl    $0x2,%eax
f0104167:	89 c2                	mov    %eax,%edx
f0104169:	8b 45 08             	mov    0x8(%ebp),%eax
f010416c:	01 d0                	add    %edx,%eax
f010416e:	8b 40 08             	mov    0x8(%eax),%eax
f0104171:	3b 45 18             	cmp    0x18(%ebp),%eax
f0104174:	76 14                	jbe    f010418a <stab_binsearch+0xda>
			*region_right = m - 1;
f0104176:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104179:	8d 50 ff             	lea    -0x1(%eax),%edx
f010417c:	8b 45 10             	mov    0x10(%ebp),%eax
f010417f:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0104181:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104184:	48                   	dec    %eax
f0104185:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0104188:	eb 12                	jmp    f010419c <stab_binsearch+0xec>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010418a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010418d:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104190:	89 10                	mov    %edx,(%eax)
			l = m;
f0104192:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104195:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0104198:	83 45 18 04          	addl   $0x4,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f010419c:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010419f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01041a2:	0f 8e 2a ff ff ff    	jle    f01040d2 <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01041a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01041ac:	75 0f                	jne    f01041bd <stab_binsearch+0x10d>
		*region_right = *region_left - 1;
f01041ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041b1:	8b 00                	mov    (%eax),%eax
f01041b3:	8d 50 ff             	lea    -0x1(%eax),%edx
f01041b6:	8b 45 10             	mov    0x10(%ebp),%eax
f01041b9:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f01041bb:	eb 3d                	jmp    f01041fa <stab_binsearch+0x14a>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01041bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01041c0:	8b 00                	mov    (%eax),%eax
f01041c2:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01041c5:	eb 03                	jmp    f01041ca <stab_binsearch+0x11a>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01041c7:	ff 4d fc             	decl   -0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01041ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041cd:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01041cf:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01041d2:	7d 1e                	jge    f01041f2 <stab_binsearch+0x142>
		     l > *region_left && stabs[l].n_type != type;
f01041d4:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01041d7:	89 d0                	mov    %edx,%eax
f01041d9:	01 c0                	add    %eax,%eax
f01041db:	01 d0                	add    %edx,%eax
f01041dd:	c1 e0 02             	shl    $0x2,%eax
f01041e0:	89 c2                	mov    %eax,%edx
f01041e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01041e5:	01 d0                	add    %edx,%eax
f01041e7:	8a 40 04             	mov    0x4(%eax),%al
f01041ea:	0f b6 c0             	movzbl %al,%eax
f01041ed:	3b 45 14             	cmp    0x14(%ebp),%eax
f01041f0:	75 d5                	jne    f01041c7 <stab_binsearch+0x117>
		     l--)
			/* do nothing */;
		*region_left = l;
f01041f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041f5:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01041f8:	89 10                	mov    %edx,(%eax)
	}
}
f01041fa:	90                   	nop
f01041fb:	c9                   	leave  
f01041fc:	c3                   	ret    

f01041fd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uint32*  addr, struct Eipdebuginfo *info)
{
f01041fd:	55                   	push   %ebp
f01041fe:	89 e5                	mov    %esp,%ebp
f0104200:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104203:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104206:	c7 00 58 6c 10 f0    	movl   $0xf0106c58,(%eax)
	info->eip_line = 0;
f010420c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010420f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f0104216:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104219:	c7 40 08 58 6c 10 f0 	movl   $0xf0106c58,0x8(%eax)
	info->eip_fn_namelen = 9;
f0104220:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104223:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f010422a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010422d:	8b 55 08             	mov    0x8(%ebp),%edx
f0104230:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f0104233:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104236:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if ((uint32)addr >= USER_LIMIT) {
f010423d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104240:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104245:	76 1e                	jbe    f0104265 <debuginfo_eip+0x68>
		stabs = __STAB_BEGIN__;
f0104247:	c7 45 f4 b0 6e 10 f0 	movl   $0xf0106eb0,-0xc(%ebp)
		stab_end = __STAB_END__;
f010424e:	c7 45 f0 a8 00 11 f0 	movl   $0xf01100a8,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104255:	c7 45 ec a9 00 11 f0 	movl   $0xf01100a9,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f010425c:	c7 45 e8 76 3b 11 f0 	movl   $0xf0113b76,-0x18(%ebp)
f0104263:	eb 2a                	jmp    f010428f <debuginfo_eip+0x92>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f0104265:	c7 45 e0 00 00 20 00 	movl   $0x200000,-0x20(%ebp)

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		
		stabs = usd->stabs;
f010426c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010426f:	8b 00                	mov    (%eax),%eax
f0104271:	89 45 f4             	mov    %eax,-0xc(%ebp)
		stab_end = usd->stab_end;
f0104274:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104277:	8b 40 04             	mov    0x4(%eax),%eax
f010427a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		stabstr = usd->stabstr;
f010427d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104280:	8b 40 08             	mov    0x8(%eax),%eax
f0104283:	89 45 ec             	mov    %eax,-0x14(%ebp)
		stabstr_end = usd->stabstr_end;
f0104286:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104289:	8b 40 0c             	mov    0xc(%eax),%eax
f010428c:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010428f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104292:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0104295:	76 0a                	jbe    f01042a1 <debuginfo_eip+0xa4>
f0104297:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010429a:	48                   	dec    %eax
f010429b:	8a 00                	mov    (%eax),%al
f010429d:	84 c0                	test   %al,%al
f010429f:	74 0a                	je     f01042ab <debuginfo_eip+0xae>
		return -1;
f01042a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01042a6:	e9 01 02 00 00       	jmp    f01044ac <debuginfo_eip+0x2af>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01042ab:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	rfile = (stab_end - stabs) - 1;
f01042b2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01042b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01042b8:	29 c2                	sub    %eax,%edx
f01042ba:	89 d0                	mov    %edx,%eax
f01042bc:	c1 f8 02             	sar    $0x2,%eax
f01042bf:	89 c2                	mov    %eax,%edx
f01042c1:	89 d0                	mov    %edx,%eax
f01042c3:	c1 e0 02             	shl    $0x2,%eax
f01042c6:	01 d0                	add    %edx,%eax
f01042c8:	c1 e0 02             	shl    $0x2,%eax
f01042cb:	01 d0                	add    %edx,%eax
f01042cd:	c1 e0 02             	shl    $0x2,%eax
f01042d0:	01 d0                	add    %edx,%eax
f01042d2:	89 c1                	mov    %eax,%ecx
f01042d4:	c1 e1 08             	shl    $0x8,%ecx
f01042d7:	01 c8                	add    %ecx,%eax
f01042d9:	89 c1                	mov    %eax,%ecx
f01042db:	c1 e1 10             	shl    $0x10,%ecx
f01042de:	01 c8                	add    %ecx,%eax
f01042e0:	01 c0                	add    %eax,%eax
f01042e2:	01 d0                	add    %edx,%eax
f01042e4:	48                   	dec    %eax
f01042e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042e8:	ff 75 08             	pushl  0x8(%ebp)
f01042eb:	6a 64                	push   $0x64
f01042ed:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01042f0:	50                   	push   %eax
f01042f1:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01042f4:	50                   	push   %eax
f01042f5:	ff 75 f4             	pushl  -0xc(%ebp)
f01042f8:	e8 b3 fd ff ff       	call   f01040b0 <stab_binsearch>
f01042fd:	83 c4 14             	add    $0x14,%esp
	if (lfile == 0)
f0104300:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104303:	85 c0                	test   %eax,%eax
f0104305:	75 0a                	jne    f0104311 <debuginfo_eip+0x114>
		return -1;
f0104307:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010430c:	e9 9b 01 00 00       	jmp    f01044ac <debuginfo_eip+0x2af>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104311:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104314:	89 45 d0             	mov    %eax,-0x30(%ebp)
	rfun = rfile;
f0104317:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010431a:	89 45 cc             	mov    %eax,-0x34(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010431d:	ff 75 08             	pushl  0x8(%ebp)
f0104320:	6a 24                	push   $0x24
f0104322:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0104325:	50                   	push   %eax
f0104326:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0104329:	50                   	push   %eax
f010432a:	ff 75 f4             	pushl  -0xc(%ebp)
f010432d:	e8 7e fd ff ff       	call   f01040b0 <stab_binsearch>
f0104332:	83 c4 14             	add    $0x14,%esp

	if (lfun <= rfun) {
f0104335:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104338:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010433b:	39 c2                	cmp    %eax,%edx
f010433d:	0f 8f 86 00 00 00    	jg     f01043c9 <debuginfo_eip+0x1cc>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104343:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104346:	89 c2                	mov    %eax,%edx
f0104348:	89 d0                	mov    %edx,%eax
f010434a:	01 c0                	add    %eax,%eax
f010434c:	01 d0                	add    %edx,%eax
f010434e:	c1 e0 02             	shl    $0x2,%eax
f0104351:	89 c2                	mov    %eax,%edx
f0104353:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104356:	01 d0                	add    %edx,%eax
f0104358:	8b 00                	mov    (%eax),%eax
f010435a:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010435d:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0104360:	29 d1                	sub    %edx,%ecx
f0104362:	89 ca                	mov    %ecx,%edx
f0104364:	39 d0                	cmp    %edx,%eax
f0104366:	73 22                	jae    f010438a <debuginfo_eip+0x18d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104368:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010436b:	89 c2                	mov    %eax,%edx
f010436d:	89 d0                	mov    %edx,%eax
f010436f:	01 c0                	add    %eax,%eax
f0104371:	01 d0                	add    %edx,%eax
f0104373:	c1 e0 02             	shl    $0x2,%eax
f0104376:	89 c2                	mov    %eax,%edx
f0104378:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010437b:	01 d0                	add    %edx,%eax
f010437d:	8b 10                	mov    (%eax),%edx
f010437f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104382:	01 c2                	add    %eax,%edx
f0104384:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104387:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = (uint32*) stabs[lfun].n_value;
f010438a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010438d:	89 c2                	mov    %eax,%edx
f010438f:	89 d0                	mov    %edx,%eax
f0104391:	01 c0                	add    %eax,%eax
f0104393:	01 d0                	add    %edx,%eax
f0104395:	c1 e0 02             	shl    $0x2,%eax
f0104398:	89 c2                	mov    %eax,%edx
f010439a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010439d:	01 d0                	add    %edx,%eax
f010439f:	8b 50 08             	mov    0x8(%eax),%edx
f01043a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043a5:	89 50 10             	mov    %edx,0x10(%eax)
		addr = (uint32*)(addr - (info->eip_fn_addr));
f01043a8:	8b 55 08             	mov    0x8(%ebp),%edx
f01043ab:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043ae:	8b 40 10             	mov    0x10(%eax),%eax
f01043b1:	29 c2                	sub    %eax,%edx
f01043b3:	89 d0                	mov    %edx,%eax
f01043b5:	c1 f8 02             	sar    $0x2,%eax
f01043b8:	89 45 08             	mov    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f01043bb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01043be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfun;
f01043c1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01043c4:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01043c7:	eb 15                	jmp    f01043de <debuginfo_eip+0x1e1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01043c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043cc:	8b 55 08             	mov    0x8(%ebp),%edx
f01043cf:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f01043d2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01043d5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfile;
f01043d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01043db:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01043de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043e1:	8b 40 08             	mov    0x8(%eax),%eax
f01043e4:	83 ec 08             	sub    $0x8,%esp
f01043e7:	6a 3a                	push   $0x3a
f01043e9:	50                   	push   %eax
f01043ea:	e8 a4 09 00 00       	call   f0104d93 <strfind>
f01043ef:	83 c4 10             	add    $0x10,%esp
f01043f2:	89 c2                	mov    %eax,%edx
f01043f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043f7:	8b 40 08             	mov    0x8(%eax),%eax
f01043fa:	29 c2                	sub    %eax,%edx
f01043fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043ff:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104402:	eb 03                	jmp    f0104407 <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104404:	ff 4d e4             	decl   -0x1c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104407:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010440a:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010440d:	7c 4e                	jl     f010445d <debuginfo_eip+0x260>
	       && stabs[lline].n_type != N_SOL
f010440f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104412:	89 d0                	mov    %edx,%eax
f0104414:	01 c0                	add    %eax,%eax
f0104416:	01 d0                	add    %edx,%eax
f0104418:	c1 e0 02             	shl    $0x2,%eax
f010441b:	89 c2                	mov    %eax,%edx
f010441d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104420:	01 d0                	add    %edx,%eax
f0104422:	8a 40 04             	mov    0x4(%eax),%al
f0104425:	3c 84                	cmp    $0x84,%al
f0104427:	74 34                	je     f010445d <debuginfo_eip+0x260>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104429:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010442c:	89 d0                	mov    %edx,%eax
f010442e:	01 c0                	add    %eax,%eax
f0104430:	01 d0                	add    %edx,%eax
f0104432:	c1 e0 02             	shl    $0x2,%eax
f0104435:	89 c2                	mov    %eax,%edx
f0104437:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010443a:	01 d0                	add    %edx,%eax
f010443c:	8a 40 04             	mov    0x4(%eax),%al
f010443f:	3c 64                	cmp    $0x64,%al
f0104441:	75 c1                	jne    f0104404 <debuginfo_eip+0x207>
f0104443:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104446:	89 d0                	mov    %edx,%eax
f0104448:	01 c0                	add    %eax,%eax
f010444a:	01 d0                	add    %edx,%eax
f010444c:	c1 e0 02             	shl    $0x2,%eax
f010444f:	89 c2                	mov    %eax,%edx
f0104451:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104454:	01 d0                	add    %edx,%eax
f0104456:	8b 40 08             	mov    0x8(%eax),%eax
f0104459:	85 c0                	test   %eax,%eax
f010445b:	74 a7                	je     f0104404 <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010445d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104460:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0104463:	7c 42                	jl     f01044a7 <debuginfo_eip+0x2aa>
f0104465:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104468:	89 d0                	mov    %edx,%eax
f010446a:	01 c0                	add    %eax,%eax
f010446c:	01 d0                	add    %edx,%eax
f010446e:	c1 e0 02             	shl    $0x2,%eax
f0104471:	89 c2                	mov    %eax,%edx
f0104473:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104476:	01 d0                	add    %edx,%eax
f0104478:	8b 00                	mov    (%eax),%eax
f010447a:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010447d:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0104480:	29 d1                	sub    %edx,%ecx
f0104482:	89 ca                	mov    %ecx,%edx
f0104484:	39 d0                	cmp    %edx,%eax
f0104486:	73 1f                	jae    f01044a7 <debuginfo_eip+0x2aa>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104488:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010448b:	89 d0                	mov    %edx,%eax
f010448d:	01 c0                	add    %eax,%eax
f010448f:	01 d0                	add    %edx,%eax
f0104491:	c1 e0 02             	shl    $0x2,%eax
f0104494:	89 c2                	mov    %eax,%edx
f0104496:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104499:	01 d0                	add    %edx,%eax
f010449b:	8b 10                	mov    (%eax),%edx
f010449d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01044a0:	01 c2                	add    %eax,%edx
f01044a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044a5:	89 10                	mov    %edx,(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01044a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044ac:	c9                   	leave  
f01044ad:	c3                   	ret    

f01044ae <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01044ae:	55                   	push   %ebp
f01044af:	89 e5                	mov    %esp,%ebp
f01044b1:	53                   	push   %ebx
f01044b2:	83 ec 14             	sub    $0x14,%esp
f01044b5:	8b 45 10             	mov    0x10(%ebp),%eax
f01044b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01044be:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01044c1:	8b 45 18             	mov    0x18(%ebp),%eax
f01044c4:	ba 00 00 00 00       	mov    $0x0,%edx
f01044c9:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f01044cc:	77 55                	ja     f0104523 <printnum+0x75>
f01044ce:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f01044d1:	72 05                	jb     f01044d8 <printnum+0x2a>
f01044d3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f01044d6:	77 4b                	ja     f0104523 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01044d8:	8b 45 1c             	mov    0x1c(%ebp),%eax
f01044db:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01044de:	8b 45 18             	mov    0x18(%ebp),%eax
f01044e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01044e6:	52                   	push   %edx
f01044e7:	50                   	push   %eax
f01044e8:	ff 75 f4             	pushl  -0xc(%ebp)
f01044eb:	ff 75 f0             	pushl  -0x10(%ebp)
f01044ee:	e8 59 0c 00 00       	call   f010514c <__udivdi3>
f01044f3:	83 c4 10             	add    $0x10,%esp
f01044f6:	83 ec 04             	sub    $0x4,%esp
f01044f9:	ff 75 20             	pushl  0x20(%ebp)
f01044fc:	53                   	push   %ebx
f01044fd:	ff 75 18             	pushl  0x18(%ebp)
f0104500:	52                   	push   %edx
f0104501:	50                   	push   %eax
f0104502:	ff 75 0c             	pushl  0xc(%ebp)
f0104505:	ff 75 08             	pushl  0x8(%ebp)
f0104508:	e8 a1 ff ff ff       	call   f01044ae <printnum>
f010450d:	83 c4 20             	add    $0x20,%esp
f0104510:	eb 1a                	jmp    f010452c <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104512:	83 ec 08             	sub    $0x8,%esp
f0104515:	ff 75 0c             	pushl  0xc(%ebp)
f0104518:	ff 75 20             	pushl  0x20(%ebp)
f010451b:	8b 45 08             	mov    0x8(%ebp),%eax
f010451e:	ff d0                	call   *%eax
f0104520:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104523:	ff 4d 1c             	decl   0x1c(%ebp)
f0104526:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f010452a:	7f e6                	jg     f0104512 <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010452c:	8b 4d 18             	mov    0x18(%ebp),%ecx
f010452f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104534:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104537:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010453a:	53                   	push   %ebx
f010453b:	51                   	push   %ecx
f010453c:	52                   	push   %edx
f010453d:	50                   	push   %eax
f010453e:	e8 19 0d 00 00       	call   f010525c <__umoddi3>
f0104543:	83 c4 10             	add    $0x10,%esp
f0104546:	05 20 6d 10 f0       	add    $0xf0106d20,%eax
f010454b:	8a 00                	mov    (%eax),%al
f010454d:	0f be c0             	movsbl %al,%eax
f0104550:	83 ec 08             	sub    $0x8,%esp
f0104553:	ff 75 0c             	pushl  0xc(%ebp)
f0104556:	50                   	push   %eax
f0104557:	8b 45 08             	mov    0x8(%ebp),%eax
f010455a:	ff d0                	call   *%eax
f010455c:	83 c4 10             	add    $0x10,%esp
}
f010455f:	90                   	nop
f0104560:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104563:	c9                   	leave  
f0104564:	c3                   	ret    

f0104565 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104565:	55                   	push   %ebp
f0104566:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104568:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f010456c:	7e 1c                	jle    f010458a <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f010456e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104571:	8b 00                	mov    (%eax),%eax
f0104573:	8d 50 08             	lea    0x8(%eax),%edx
f0104576:	8b 45 08             	mov    0x8(%ebp),%eax
f0104579:	89 10                	mov    %edx,(%eax)
f010457b:	8b 45 08             	mov    0x8(%ebp),%eax
f010457e:	8b 00                	mov    (%eax),%eax
f0104580:	83 e8 08             	sub    $0x8,%eax
f0104583:	8b 50 04             	mov    0x4(%eax),%edx
f0104586:	8b 00                	mov    (%eax),%eax
f0104588:	eb 40                	jmp    f01045ca <getuint+0x65>
	else if (lflag)
f010458a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010458e:	74 1e                	je     f01045ae <getuint+0x49>
		return va_arg(*ap, unsigned long);
f0104590:	8b 45 08             	mov    0x8(%ebp),%eax
f0104593:	8b 00                	mov    (%eax),%eax
f0104595:	8d 50 04             	lea    0x4(%eax),%edx
f0104598:	8b 45 08             	mov    0x8(%ebp),%eax
f010459b:	89 10                	mov    %edx,(%eax)
f010459d:	8b 45 08             	mov    0x8(%ebp),%eax
f01045a0:	8b 00                	mov    (%eax),%eax
f01045a2:	83 e8 04             	sub    $0x4,%eax
f01045a5:	8b 00                	mov    (%eax),%eax
f01045a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01045ac:	eb 1c                	jmp    f01045ca <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f01045ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b1:	8b 00                	mov    (%eax),%eax
f01045b3:	8d 50 04             	lea    0x4(%eax),%edx
f01045b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b9:	89 10                	mov    %edx,(%eax)
f01045bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01045be:	8b 00                	mov    (%eax),%eax
f01045c0:	83 e8 04             	sub    $0x4,%eax
f01045c3:	8b 00                	mov    (%eax),%eax
f01045c5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01045ca:	5d                   	pop    %ebp
f01045cb:	c3                   	ret    

f01045cc <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01045cc:	55                   	push   %ebp
f01045cd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045cf:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f01045d3:	7e 1c                	jle    f01045f1 <getint+0x25>
		return va_arg(*ap, long long);
f01045d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01045d8:	8b 00                	mov    (%eax),%eax
f01045da:	8d 50 08             	lea    0x8(%eax),%edx
f01045dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01045e0:	89 10                	mov    %edx,(%eax)
f01045e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01045e5:	8b 00                	mov    (%eax),%eax
f01045e7:	83 e8 08             	sub    $0x8,%eax
f01045ea:	8b 50 04             	mov    0x4(%eax),%edx
f01045ed:	8b 00                	mov    (%eax),%eax
f01045ef:	eb 38                	jmp    f0104629 <getint+0x5d>
	else if (lflag)
f01045f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01045f5:	74 1a                	je     f0104611 <getint+0x45>
		return va_arg(*ap, long);
f01045f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01045fa:	8b 00                	mov    (%eax),%eax
f01045fc:	8d 50 04             	lea    0x4(%eax),%edx
f01045ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104602:	89 10                	mov    %edx,(%eax)
f0104604:	8b 45 08             	mov    0x8(%ebp),%eax
f0104607:	8b 00                	mov    (%eax),%eax
f0104609:	83 e8 04             	sub    $0x4,%eax
f010460c:	8b 00                	mov    (%eax),%eax
f010460e:	99                   	cltd   
f010460f:	eb 18                	jmp    f0104629 <getint+0x5d>
	else
		return va_arg(*ap, int);
f0104611:	8b 45 08             	mov    0x8(%ebp),%eax
f0104614:	8b 00                	mov    (%eax),%eax
f0104616:	8d 50 04             	lea    0x4(%eax),%edx
f0104619:	8b 45 08             	mov    0x8(%ebp),%eax
f010461c:	89 10                	mov    %edx,(%eax)
f010461e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104621:	8b 00                	mov    (%eax),%eax
f0104623:	83 e8 04             	sub    $0x4,%eax
f0104626:	8b 00                	mov    (%eax),%eax
f0104628:	99                   	cltd   
}
f0104629:	5d                   	pop    %ebp
f010462a:	c3                   	ret    

f010462b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010462b:	55                   	push   %ebp
f010462c:	89 e5                	mov    %esp,%ebp
f010462e:	56                   	push   %esi
f010462f:	53                   	push   %ebx
f0104630:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104633:	eb 17                	jmp    f010464c <vprintfmt+0x21>
			if (ch == '\0')
f0104635:	85 db                	test   %ebx,%ebx
f0104637:	0f 84 af 03 00 00    	je     f01049ec <vprintfmt+0x3c1>
				return;
			putch(ch, putdat);
f010463d:	83 ec 08             	sub    $0x8,%esp
f0104640:	ff 75 0c             	pushl  0xc(%ebp)
f0104643:	53                   	push   %ebx
f0104644:	8b 45 08             	mov    0x8(%ebp),%eax
f0104647:	ff d0                	call   *%eax
f0104649:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010464c:	8b 45 10             	mov    0x10(%ebp),%eax
f010464f:	8d 50 01             	lea    0x1(%eax),%edx
f0104652:	89 55 10             	mov    %edx,0x10(%ebp)
f0104655:	8a 00                	mov    (%eax),%al
f0104657:	0f b6 d8             	movzbl %al,%ebx
f010465a:	83 fb 25             	cmp    $0x25,%ebx
f010465d:	75 d6                	jne    f0104635 <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f010465f:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f0104663:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f010466a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104671:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0104678:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010467f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104682:	8d 50 01             	lea    0x1(%eax),%edx
f0104685:	89 55 10             	mov    %edx,0x10(%ebp)
f0104688:	8a 00                	mov    (%eax),%al
f010468a:	0f b6 d8             	movzbl %al,%ebx
f010468d:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0104690:	83 f8 55             	cmp    $0x55,%eax
f0104693:	0f 87 2b 03 00 00    	ja     f01049c4 <vprintfmt+0x399>
f0104699:	8b 04 85 44 6d 10 f0 	mov    -0xfef92bc(,%eax,4),%eax
f01046a0:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f01046a2:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f01046a6:	eb d7                	jmp    f010467f <vprintfmt+0x54>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01046a8:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f01046ac:	eb d1                	jmp    f010467f <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01046ae:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f01046b5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01046b8:	89 d0                	mov    %edx,%eax
f01046ba:	c1 e0 02             	shl    $0x2,%eax
f01046bd:	01 d0                	add    %edx,%eax
f01046bf:	01 c0                	add    %eax,%eax
f01046c1:	01 d8                	add    %ebx,%eax
f01046c3:	83 e8 30             	sub    $0x30,%eax
f01046c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f01046c9:	8b 45 10             	mov    0x10(%ebp),%eax
f01046cc:	8a 00                	mov    (%eax),%al
f01046ce:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f01046d1:	83 fb 2f             	cmp    $0x2f,%ebx
f01046d4:	7e 3e                	jle    f0104714 <vprintfmt+0xe9>
f01046d6:	83 fb 39             	cmp    $0x39,%ebx
f01046d9:	7f 39                	jg     f0104714 <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01046db:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01046de:	eb d5                	jmp    f01046b5 <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01046e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01046e3:	83 c0 04             	add    $0x4,%eax
f01046e6:	89 45 14             	mov    %eax,0x14(%ebp)
f01046e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01046ec:	83 e8 04             	sub    $0x4,%eax
f01046ef:	8b 00                	mov    (%eax),%eax
f01046f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f01046f4:	eb 1f                	jmp    f0104715 <vprintfmt+0xea>

		case '.':
			if (width < 0)
f01046f6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01046fa:	79 83                	jns    f010467f <vprintfmt+0x54>
				width = 0;
f01046fc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0104703:	e9 77 ff ff ff       	jmp    f010467f <vprintfmt+0x54>

		case '#':
			altflag = 1;
f0104708:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f010470f:	e9 6b ff ff ff       	jmp    f010467f <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f0104714:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0104715:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104719:	0f 89 60 ff ff ff    	jns    f010467f <vprintfmt+0x54>
				width = precision, precision = -1;
f010471f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104722:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104725:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f010472c:	e9 4e ff ff ff       	jmp    f010467f <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104731:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
f0104734:	e9 46 ff ff ff       	jmp    f010467f <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104739:	8b 45 14             	mov    0x14(%ebp),%eax
f010473c:	83 c0 04             	add    $0x4,%eax
f010473f:	89 45 14             	mov    %eax,0x14(%ebp)
f0104742:	8b 45 14             	mov    0x14(%ebp),%eax
f0104745:	83 e8 04             	sub    $0x4,%eax
f0104748:	8b 00                	mov    (%eax),%eax
f010474a:	83 ec 08             	sub    $0x8,%esp
f010474d:	ff 75 0c             	pushl  0xc(%ebp)
f0104750:	50                   	push   %eax
f0104751:	8b 45 08             	mov    0x8(%ebp),%eax
f0104754:	ff d0                	call   *%eax
f0104756:	83 c4 10             	add    $0x10,%esp
			break;
f0104759:	e9 89 02 00 00       	jmp    f01049e7 <vprintfmt+0x3bc>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010475e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104761:	83 c0 04             	add    $0x4,%eax
f0104764:	89 45 14             	mov    %eax,0x14(%ebp)
f0104767:	8b 45 14             	mov    0x14(%ebp),%eax
f010476a:	83 e8 04             	sub    $0x4,%eax
f010476d:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f010476f:	85 db                	test   %ebx,%ebx
f0104771:	79 02                	jns    f0104775 <vprintfmt+0x14a>
				err = -err;
f0104773:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0104775:	83 fb 07             	cmp    $0x7,%ebx
f0104778:	7f 0b                	jg     f0104785 <vprintfmt+0x15a>
f010477a:	8b 34 9d 00 6d 10 f0 	mov    -0xfef9300(,%ebx,4),%esi
f0104781:	85 f6                	test   %esi,%esi
f0104783:	75 19                	jne    f010479e <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
f0104785:	53                   	push   %ebx
f0104786:	68 31 6d 10 f0       	push   $0xf0106d31
f010478b:	ff 75 0c             	pushl  0xc(%ebp)
f010478e:	ff 75 08             	pushl  0x8(%ebp)
f0104791:	e8 5e 02 00 00       	call   f01049f4 <printfmt>
f0104796:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0104799:	e9 49 02 00 00       	jmp    f01049e7 <vprintfmt+0x3bc>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f010479e:	56                   	push   %esi
f010479f:	68 3a 6d 10 f0       	push   $0xf0106d3a
f01047a4:	ff 75 0c             	pushl  0xc(%ebp)
f01047a7:	ff 75 08             	pushl  0x8(%ebp)
f01047aa:	e8 45 02 00 00       	call   f01049f4 <printfmt>
f01047af:	83 c4 10             	add    $0x10,%esp
			break;
f01047b2:	e9 30 02 00 00       	jmp    f01049e7 <vprintfmt+0x3bc>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01047ba:	83 c0 04             	add    $0x4,%eax
f01047bd:	89 45 14             	mov    %eax,0x14(%ebp)
f01047c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c3:	83 e8 04             	sub    $0x4,%eax
f01047c6:	8b 30                	mov    (%eax),%esi
f01047c8:	85 f6                	test   %esi,%esi
f01047ca:	75 05                	jne    f01047d1 <vprintfmt+0x1a6>
				p = "(null)";
f01047cc:	be 3d 6d 10 f0       	mov    $0xf0106d3d,%esi
			if (width > 0 && padc != '-')
f01047d1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01047d5:	7e 6d                	jle    f0104844 <vprintfmt+0x219>
f01047d7:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f01047db:	74 67                	je     f0104844 <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
f01047dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047e0:	83 ec 08             	sub    $0x8,%esp
f01047e3:	50                   	push   %eax
f01047e4:	56                   	push   %esi
f01047e5:	e8 0a 04 00 00       	call   f0104bf4 <strnlen>
f01047ea:	83 c4 10             	add    $0x10,%esp
f01047ed:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f01047f0:	eb 16                	jmp    f0104808 <vprintfmt+0x1dd>
					putch(padc, putdat);
f01047f2:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f01047f6:	83 ec 08             	sub    $0x8,%esp
f01047f9:	ff 75 0c             	pushl  0xc(%ebp)
f01047fc:	50                   	push   %eax
f01047fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104800:	ff d0                	call   *%eax
f0104802:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104805:	ff 4d e4             	decl   -0x1c(%ebp)
f0104808:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010480c:	7f e4                	jg     f01047f2 <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010480e:	eb 34                	jmp    f0104844 <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
f0104810:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104814:	74 1c                	je     f0104832 <vprintfmt+0x207>
f0104816:	83 fb 1f             	cmp    $0x1f,%ebx
f0104819:	7e 05                	jle    f0104820 <vprintfmt+0x1f5>
f010481b:	83 fb 7e             	cmp    $0x7e,%ebx
f010481e:	7e 12                	jle    f0104832 <vprintfmt+0x207>
					putch('?', putdat);
f0104820:	83 ec 08             	sub    $0x8,%esp
f0104823:	ff 75 0c             	pushl  0xc(%ebp)
f0104826:	6a 3f                	push   $0x3f
f0104828:	8b 45 08             	mov    0x8(%ebp),%eax
f010482b:	ff d0                	call   *%eax
f010482d:	83 c4 10             	add    $0x10,%esp
f0104830:	eb 0f                	jmp    f0104841 <vprintfmt+0x216>
				else
					putch(ch, putdat);
f0104832:	83 ec 08             	sub    $0x8,%esp
f0104835:	ff 75 0c             	pushl  0xc(%ebp)
f0104838:	53                   	push   %ebx
f0104839:	8b 45 08             	mov    0x8(%ebp),%eax
f010483c:	ff d0                	call   *%eax
f010483e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104841:	ff 4d e4             	decl   -0x1c(%ebp)
f0104844:	89 f0                	mov    %esi,%eax
f0104846:	8d 70 01             	lea    0x1(%eax),%esi
f0104849:	8a 00                	mov    (%eax),%al
f010484b:	0f be d8             	movsbl %al,%ebx
f010484e:	85 db                	test   %ebx,%ebx
f0104850:	74 24                	je     f0104876 <vprintfmt+0x24b>
f0104852:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104856:	78 b8                	js     f0104810 <vprintfmt+0x1e5>
f0104858:	ff 4d e0             	decl   -0x20(%ebp)
f010485b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010485f:	79 af                	jns    f0104810 <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104861:	eb 13                	jmp    f0104876 <vprintfmt+0x24b>
				putch(' ', putdat);
f0104863:	83 ec 08             	sub    $0x8,%esp
f0104866:	ff 75 0c             	pushl  0xc(%ebp)
f0104869:	6a 20                	push   $0x20
f010486b:	8b 45 08             	mov    0x8(%ebp),%eax
f010486e:	ff d0                	call   *%eax
f0104870:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104873:	ff 4d e4             	decl   -0x1c(%ebp)
f0104876:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010487a:	7f e7                	jg     f0104863 <vprintfmt+0x238>
				putch(' ', putdat);
			break;
f010487c:	e9 66 01 00 00       	jmp    f01049e7 <vprintfmt+0x3bc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104881:	83 ec 08             	sub    $0x8,%esp
f0104884:	ff 75 e8             	pushl  -0x18(%ebp)
f0104887:	8d 45 14             	lea    0x14(%ebp),%eax
f010488a:	50                   	push   %eax
f010488b:	e8 3c fd ff ff       	call   f01045cc <getint>
f0104890:	83 c4 10             	add    $0x10,%esp
f0104893:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104896:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0104899:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010489c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010489f:	85 d2                	test   %edx,%edx
f01048a1:	79 23                	jns    f01048c6 <vprintfmt+0x29b>
				putch('-', putdat);
f01048a3:	83 ec 08             	sub    $0x8,%esp
f01048a6:	ff 75 0c             	pushl  0xc(%ebp)
f01048a9:	6a 2d                	push   $0x2d
f01048ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01048ae:	ff d0                	call   *%eax
f01048b0:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f01048b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01048b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01048b9:	f7 d8                	neg    %eax
f01048bb:	83 d2 00             	adc    $0x0,%edx
f01048be:	f7 da                	neg    %edx
f01048c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048c3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f01048c6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01048cd:	e9 bc 00 00 00       	jmp    f010498e <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01048d2:	83 ec 08             	sub    $0x8,%esp
f01048d5:	ff 75 e8             	pushl  -0x18(%ebp)
f01048d8:	8d 45 14             	lea    0x14(%ebp),%eax
f01048db:	50                   	push   %eax
f01048dc:	e8 84 fc ff ff       	call   f0104565 <getuint>
f01048e1:	83 c4 10             	add    $0x10,%esp
f01048e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048e7:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f01048ea:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01048f1:	e9 98 00 00 00       	jmp    f010498e <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01048f6:	83 ec 08             	sub    $0x8,%esp
f01048f9:	ff 75 0c             	pushl  0xc(%ebp)
f01048fc:	6a 58                	push   $0x58
f01048fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104901:	ff d0                	call   *%eax
f0104903:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f0104906:	83 ec 08             	sub    $0x8,%esp
f0104909:	ff 75 0c             	pushl  0xc(%ebp)
f010490c:	6a 58                	push   $0x58
f010490e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104911:	ff d0                	call   *%eax
f0104913:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f0104916:	83 ec 08             	sub    $0x8,%esp
f0104919:	ff 75 0c             	pushl  0xc(%ebp)
f010491c:	6a 58                	push   $0x58
f010491e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104921:	ff d0                	call   *%eax
f0104923:	83 c4 10             	add    $0x10,%esp
			break;
f0104926:	e9 bc 00 00 00       	jmp    f01049e7 <vprintfmt+0x3bc>

		// pointer
		case 'p':
			putch('0', putdat);
f010492b:	83 ec 08             	sub    $0x8,%esp
f010492e:	ff 75 0c             	pushl  0xc(%ebp)
f0104931:	6a 30                	push   $0x30
f0104933:	8b 45 08             	mov    0x8(%ebp),%eax
f0104936:	ff d0                	call   *%eax
f0104938:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f010493b:	83 ec 08             	sub    $0x8,%esp
f010493e:	ff 75 0c             	pushl  0xc(%ebp)
f0104941:	6a 78                	push   $0x78
f0104943:	8b 45 08             	mov    0x8(%ebp),%eax
f0104946:	ff d0                	call   *%eax
f0104948:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
f010494b:	8b 45 14             	mov    0x14(%ebp),%eax
f010494e:	83 c0 04             	add    $0x4,%eax
f0104951:	89 45 14             	mov    %eax,0x14(%ebp)
f0104954:	8b 45 14             	mov    0x14(%ebp),%eax
f0104957:	83 e8 04             	sub    $0x4,%eax
f010495a:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010495c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010495f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
f0104966:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f010496d:	eb 1f                	jmp    f010498e <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010496f:	83 ec 08             	sub    $0x8,%esp
f0104972:	ff 75 e8             	pushl  -0x18(%ebp)
f0104975:	8d 45 14             	lea    0x14(%ebp),%eax
f0104978:	50                   	push   %eax
f0104979:	e8 e7 fb ff ff       	call   f0104565 <getuint>
f010497e:	83 c4 10             	add    $0x10,%esp
f0104981:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104984:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0104987:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f010498e:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f0104992:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104995:	83 ec 04             	sub    $0x4,%esp
f0104998:	52                   	push   %edx
f0104999:	ff 75 e4             	pushl  -0x1c(%ebp)
f010499c:	50                   	push   %eax
f010499d:	ff 75 f4             	pushl  -0xc(%ebp)
f01049a0:	ff 75 f0             	pushl  -0x10(%ebp)
f01049a3:	ff 75 0c             	pushl  0xc(%ebp)
f01049a6:	ff 75 08             	pushl  0x8(%ebp)
f01049a9:	e8 00 fb ff ff       	call   f01044ae <printnum>
f01049ae:	83 c4 20             	add    $0x20,%esp
			break;
f01049b1:	eb 34                	jmp    f01049e7 <vprintfmt+0x3bc>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01049b3:	83 ec 08             	sub    $0x8,%esp
f01049b6:	ff 75 0c             	pushl  0xc(%ebp)
f01049b9:	53                   	push   %ebx
f01049ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01049bd:	ff d0                	call   *%eax
f01049bf:	83 c4 10             	add    $0x10,%esp
			break;
f01049c2:	eb 23                	jmp    f01049e7 <vprintfmt+0x3bc>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01049c4:	83 ec 08             	sub    $0x8,%esp
f01049c7:	ff 75 0c             	pushl  0xc(%ebp)
f01049ca:	6a 25                	push   $0x25
f01049cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01049cf:	ff d0                	call   *%eax
f01049d1:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f01049d4:	ff 4d 10             	decl   0x10(%ebp)
f01049d7:	eb 03                	jmp    f01049dc <vprintfmt+0x3b1>
f01049d9:	ff 4d 10             	decl   0x10(%ebp)
f01049dc:	8b 45 10             	mov    0x10(%ebp),%eax
f01049df:	48                   	dec    %eax
f01049e0:	8a 00                	mov    (%eax),%al
f01049e2:	3c 25                	cmp    $0x25,%al
f01049e4:	75 f3                	jne    f01049d9 <vprintfmt+0x3ae>
				/* do nothing */;
			break;
f01049e6:	90                   	nop
		}
	}
f01049e7:	e9 47 fc ff ff       	jmp    f0104633 <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f01049ec:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01049ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01049f0:	5b                   	pop    %ebx
f01049f1:	5e                   	pop    %esi
f01049f2:	5d                   	pop    %ebp
f01049f3:	c3                   	ret    

f01049f4 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01049f4:	55                   	push   %ebp
f01049f5:	89 e5                	mov    %esp,%ebp
f01049f7:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01049fa:	8d 45 10             	lea    0x10(%ebp),%eax
f01049fd:	83 c0 04             	add    $0x4,%eax
f0104a00:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0104a03:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a06:	ff 75 f4             	pushl  -0xc(%ebp)
f0104a09:	50                   	push   %eax
f0104a0a:	ff 75 0c             	pushl  0xc(%ebp)
f0104a0d:	ff 75 08             	pushl  0x8(%ebp)
f0104a10:	e8 16 fc ff ff       	call   f010462b <vprintfmt>
f0104a15:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f0104a18:	90                   	nop
f0104a19:	c9                   	leave  
f0104a1a:	c3                   	ret    

f0104a1b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104a1b:	55                   	push   %ebp
f0104a1c:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f0104a1e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a21:	8b 40 08             	mov    0x8(%eax),%eax
f0104a24:	8d 50 01             	lea    0x1(%eax),%edx
f0104a27:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a2a:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f0104a2d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a30:	8b 10                	mov    (%eax),%edx
f0104a32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a35:	8b 40 04             	mov    0x4(%eax),%eax
f0104a38:	39 c2                	cmp    %eax,%edx
f0104a3a:	73 12                	jae    f0104a4e <sprintputch+0x33>
		*b->buf++ = ch;
f0104a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a3f:	8b 00                	mov    (%eax),%eax
f0104a41:	8d 48 01             	lea    0x1(%eax),%ecx
f0104a44:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a47:	89 0a                	mov    %ecx,(%edx)
f0104a49:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a4c:	88 10                	mov    %dl,(%eax)
}
f0104a4e:	90                   	nop
f0104a4f:	5d                   	pop    %ebp
f0104a50:	c3                   	ret    

f0104a51 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a51:	55                   	push   %ebp
f0104a52:	89 e5                	mov    %esp,%ebp
f0104a54:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a57:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a5d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a60:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104a63:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a66:	01 d0                	add    %edx,%eax
f0104a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104a6b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a72:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0104a76:	74 06                	je     f0104a7e <vsnprintf+0x2d>
f0104a78:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104a7c:	7f 07                	jg     f0104a85 <vsnprintf+0x34>
		return -E_INVAL;
f0104a7e:	b8 03 00 00 00       	mov    $0x3,%eax
f0104a83:	eb 20                	jmp    f0104aa5 <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a85:	ff 75 14             	pushl  0x14(%ebp)
f0104a88:	ff 75 10             	pushl  0x10(%ebp)
f0104a8b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a8e:	50                   	push   %eax
f0104a8f:	68 1b 4a 10 f0       	push   $0xf0104a1b
f0104a94:	e8 92 fb ff ff       	call   f010462b <vprintfmt>
f0104a99:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f0104a9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a9f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104aa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0104aa5:	c9                   	leave  
f0104aa6:	c3                   	ret    

f0104aa7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104aa7:	55                   	push   %ebp
f0104aa8:	89 e5                	mov    %esp,%ebp
f0104aaa:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104aad:	8d 45 10             	lea    0x10(%ebp),%eax
f0104ab0:	83 c0 04             	add    $0x4,%eax
f0104ab3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0104ab6:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ab9:	ff 75 f4             	pushl  -0xc(%ebp)
f0104abc:	50                   	push   %eax
f0104abd:	ff 75 0c             	pushl  0xc(%ebp)
f0104ac0:	ff 75 08             	pushl  0x8(%ebp)
f0104ac3:	e8 89 ff ff ff       	call   f0104a51 <vsnprintf>
f0104ac8:	83 c4 10             	add    $0x10,%esp
f0104acb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f0104ace:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0104ad1:	c9                   	leave  
f0104ad2:	c3                   	ret    

f0104ad3 <readline>:

#define BUFLEN 1024
//static char buf[BUFLEN];

void readline(const char *prompt, char* buf)
{
f0104ad3:	55                   	push   %ebp
f0104ad4:	89 e5                	mov    %esp,%ebp
f0104ad6:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;
	
	if (prompt != NULL)
f0104ad9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0104add:	74 13                	je     f0104af2 <readline+0x1f>
		cprintf("%s", prompt);
f0104adf:	83 ec 08             	sub    $0x8,%esp
f0104ae2:	ff 75 08             	pushl  0x8(%ebp)
f0104ae5:	68 9c 6e 10 f0       	push   $0xf0106e9c
f0104aea:	e8 ed eb ff ff       	call   f01036dc <cprintf>
f0104aef:	83 c4 10             	add    $0x10,%esp

	
	i = 0;
f0104af2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);	
f0104af9:	83 ec 0c             	sub    $0xc,%esp
f0104afc:	6a 00                	push   $0x0
f0104afe:	e8 44 be ff ff       	call   f0100947 <iscons>
f0104b03:	83 c4 10             	add    $0x10,%esp
f0104b06:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f0104b09:	e8 20 be ff ff       	call   f010092e <getchar>
f0104b0e:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f0104b11:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0104b15:	79 22                	jns    f0104b39 <readline+0x66>
			if (c != -E_EOF)
f0104b17:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
f0104b1b:	0f 84 ad 00 00 00    	je     f0104bce <readline+0xfb>
				cprintf("read error: %e\n", c);			
f0104b21:	83 ec 08             	sub    $0x8,%esp
f0104b24:	ff 75 ec             	pushl  -0x14(%ebp)
f0104b27:	68 9f 6e 10 f0       	push   $0xf0106e9f
f0104b2c:	e8 ab eb ff ff       	call   f01036dc <cprintf>
f0104b31:	83 c4 10             	add    $0x10,%esp
			return;
f0104b34:	e9 95 00 00 00       	jmp    f0104bce <readline+0xfb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b39:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0104b3d:	7e 34                	jle    f0104b73 <readline+0xa0>
f0104b3f:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f0104b46:	7f 2b                	jg     f0104b73 <readline+0xa0>
			if (echoing)
f0104b48:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104b4c:	74 0e                	je     f0104b5c <readline+0x89>
				cputchar(c);
f0104b4e:	83 ec 0c             	sub    $0xc,%esp
f0104b51:	ff 75 ec             	pushl  -0x14(%ebp)
f0104b54:	e8 be bd ff ff       	call   f0100917 <cputchar>
f0104b59:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b5f:	8d 50 01             	lea    0x1(%eax),%edx
f0104b62:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0104b65:	89 c2                	mov    %eax,%edx
f0104b67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b6a:	01 d0                	add    %edx,%eax
f0104b6c:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0104b6f:	88 10                	mov    %dl,(%eax)
f0104b71:	eb 56                	jmp    f0104bc9 <readline+0xf6>
		} else if (c == '\b' && i > 0) {
f0104b73:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0104b77:	75 1f                	jne    f0104b98 <readline+0xc5>
f0104b79:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104b7d:	7e 19                	jle    f0104b98 <readline+0xc5>
			if (echoing)
f0104b7f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104b83:	74 0e                	je     f0104b93 <readline+0xc0>
				cputchar(c);
f0104b85:	83 ec 0c             	sub    $0xc,%esp
f0104b88:	ff 75 ec             	pushl  -0x14(%ebp)
f0104b8b:	e8 87 bd ff ff       	call   f0100917 <cputchar>
f0104b90:	83 c4 10             	add    $0x10,%esp
			i--;
f0104b93:	ff 4d f4             	decl   -0xc(%ebp)
f0104b96:	eb 31                	jmp    f0104bc9 <readline+0xf6>
		} else if (c == '\n' || c == '\r') {
f0104b98:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0104b9c:	74 0a                	je     f0104ba8 <readline+0xd5>
f0104b9e:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f0104ba2:	0f 85 61 ff ff ff    	jne    f0104b09 <readline+0x36>
			if (echoing)
f0104ba8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104bac:	74 0e                	je     f0104bbc <readline+0xe9>
				cputchar(c);
f0104bae:	83 ec 0c             	sub    $0xc,%esp
f0104bb1:	ff 75 ec             	pushl  -0x14(%ebp)
f0104bb4:	e8 5e bd ff ff       	call   f0100917 <cputchar>
f0104bb9:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;	
f0104bbc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bc2:	01 d0                	add    %edx,%eax
f0104bc4:	c6 00 00             	movb   $0x0,(%eax)
			return;		
f0104bc7:	eb 06                	jmp    f0104bcf <readline+0xfc>
		}
	}
f0104bc9:	e9 3b ff ff ff       	jmp    f0104b09 <readline+0x36>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);			
			return;
f0104bce:	90                   	nop
				cputchar(c);
			buf[i] = 0;	
			return;		
		}
	}
}
f0104bcf:	c9                   	leave  
f0104bd0:	c3                   	ret    

f0104bd1 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0104bd1:	55                   	push   %ebp
f0104bd2:	89 e5                	mov    %esp,%ebp
f0104bd4:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0104bd7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104bde:	eb 06                	jmp    f0104be6 <strlen+0x15>
		n++;
f0104be0:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104be3:	ff 45 08             	incl   0x8(%ebp)
f0104be6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104be9:	8a 00                	mov    (%eax),%al
f0104beb:	84 c0                	test   %al,%al
f0104bed:	75 f1                	jne    f0104be0 <strlen+0xf>
		n++;
	return n;
f0104bef:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104bf2:	c9                   	leave  
f0104bf3:	c3                   	ret    

f0104bf4 <strnlen>:

int
strnlen(const char *s, uint32 size)
{
f0104bf4:	55                   	push   %ebp
f0104bf5:	89 e5                	mov    %esp,%ebp
f0104bf7:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bfa:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104c01:	eb 09                	jmp    f0104c0c <strnlen+0x18>
		n++;
f0104c03:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104c06:	ff 45 08             	incl   0x8(%ebp)
f0104c09:	ff 4d 0c             	decl   0xc(%ebp)
f0104c0c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104c10:	74 09                	je     f0104c1b <strnlen+0x27>
f0104c12:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c15:	8a 00                	mov    (%eax),%al
f0104c17:	84 c0                	test   %al,%al
f0104c19:	75 e8                	jne    f0104c03 <strnlen+0xf>
		n++;
	return n;
f0104c1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104c1e:	c9                   	leave  
f0104c1f:	c3                   	ret    

f0104c20 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104c20:	55                   	push   %ebp
f0104c21:	89 e5                	mov    %esp,%ebp
f0104c23:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0104c26:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c29:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0104c2c:	90                   	nop
f0104c2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c30:	8d 50 01             	lea    0x1(%eax),%edx
f0104c33:	89 55 08             	mov    %edx,0x8(%ebp)
f0104c36:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c39:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104c3c:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0104c3f:	8a 12                	mov    (%edx),%dl
f0104c41:	88 10                	mov    %dl,(%eax)
f0104c43:	8a 00                	mov    (%eax),%al
f0104c45:	84 c0                	test   %al,%al
f0104c47:	75 e4                	jne    f0104c2d <strcpy+0xd>
		/* do nothing */;
	return ret;
f0104c49:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0104c4c:	c9                   	leave  
f0104c4d:	c3                   	ret    

f0104c4e <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
f0104c4e:	55                   	push   %ebp
f0104c4f:	89 e5                	mov    %esp,%ebp
f0104c51:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
f0104c54:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c57:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0104c5a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0104c61:	eb 1f                	jmp    f0104c82 <strncpy+0x34>
		*dst++ = *src;
f0104c63:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c66:	8d 50 01             	lea    0x1(%eax),%edx
f0104c69:	89 55 08             	mov    %edx,0x8(%ebp)
f0104c6c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c6f:	8a 12                	mov    (%edx),%dl
f0104c71:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0104c73:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c76:	8a 00                	mov    (%eax),%al
f0104c78:	84 c0                	test   %al,%al
f0104c7a:	74 03                	je     f0104c7f <strncpy+0x31>
			src++;
f0104c7c:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c7f:	ff 45 fc             	incl   -0x4(%ebp)
f0104c82:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104c85:	3b 45 10             	cmp    0x10(%ebp),%eax
f0104c88:	72 d9                	jb     f0104c63 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0104c8a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104c8d:	c9                   	leave  
f0104c8e:	c3                   	ret    

f0104c8f <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
f0104c8f:	55                   	push   %ebp
f0104c90:	89 e5                	mov    %esp,%ebp
f0104c92:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f0104c95:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c98:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0104c9b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104c9f:	74 30                	je     f0104cd1 <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
f0104ca1:	eb 16                	jmp    f0104cb9 <strlcpy+0x2a>
			*dst++ = *src++;
f0104ca3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ca6:	8d 50 01             	lea    0x1(%eax),%edx
f0104ca9:	89 55 08             	mov    %edx,0x8(%ebp)
f0104cac:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104caf:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104cb2:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0104cb5:	8a 12                	mov    (%edx),%dl
f0104cb7:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104cb9:	ff 4d 10             	decl   0x10(%ebp)
f0104cbc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104cc0:	74 09                	je     f0104ccb <strlcpy+0x3c>
f0104cc2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cc5:	8a 00                	mov    (%eax),%al
f0104cc7:	84 c0                	test   %al,%al
f0104cc9:	75 d8                	jne    f0104ca3 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0104ccb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cce:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104cd1:	8b 55 08             	mov    0x8(%ebp),%edx
f0104cd4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104cd7:	29 c2                	sub    %eax,%edx
f0104cd9:	89 d0                	mov    %edx,%eax
}
f0104cdb:	c9                   	leave  
f0104cdc:	c3                   	ret    

f0104cdd <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104cdd:	55                   	push   %ebp
f0104cde:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0104ce0:	eb 06                	jmp    f0104ce8 <strcmp+0xb>
		p++, q++;
f0104ce2:	ff 45 08             	incl   0x8(%ebp)
f0104ce5:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ceb:	8a 00                	mov    (%eax),%al
f0104ced:	84 c0                	test   %al,%al
f0104cef:	74 0e                	je     f0104cff <strcmp+0x22>
f0104cf1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cf4:	8a 10                	mov    (%eax),%dl
f0104cf6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cf9:	8a 00                	mov    (%eax),%al
f0104cfb:	38 c2                	cmp    %al,%dl
f0104cfd:	74 e3                	je     f0104ce2 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104cff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d02:	8a 00                	mov    (%eax),%al
f0104d04:	0f b6 d0             	movzbl %al,%edx
f0104d07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d0a:	8a 00                	mov    (%eax),%al
f0104d0c:	0f b6 c0             	movzbl %al,%eax
f0104d0f:	29 c2                	sub    %eax,%edx
f0104d11:	89 d0                	mov    %edx,%eax
}
f0104d13:	5d                   	pop    %ebp
f0104d14:	c3                   	ret    

f0104d15 <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
f0104d15:	55                   	push   %ebp
f0104d16:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0104d18:	eb 09                	jmp    f0104d23 <strncmp+0xe>
		n--, p++, q++;
f0104d1a:	ff 4d 10             	decl   0x10(%ebp)
f0104d1d:	ff 45 08             	incl   0x8(%ebp)
f0104d20:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
f0104d23:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104d27:	74 17                	je     f0104d40 <strncmp+0x2b>
f0104d29:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d2c:	8a 00                	mov    (%eax),%al
f0104d2e:	84 c0                	test   %al,%al
f0104d30:	74 0e                	je     f0104d40 <strncmp+0x2b>
f0104d32:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d35:	8a 10                	mov    (%eax),%dl
f0104d37:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d3a:	8a 00                	mov    (%eax),%al
f0104d3c:	38 c2                	cmp    %al,%dl
f0104d3e:	74 da                	je     f0104d1a <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0104d40:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104d44:	75 07                	jne    f0104d4d <strncmp+0x38>
		return 0;
f0104d46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d4b:	eb 14                	jmp    f0104d61 <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104d4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d50:	8a 00                	mov    (%eax),%al
f0104d52:	0f b6 d0             	movzbl %al,%edx
f0104d55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d58:	8a 00                	mov    (%eax),%al
f0104d5a:	0f b6 c0             	movzbl %al,%eax
f0104d5d:	29 c2                	sub    %eax,%edx
f0104d5f:	89 d0                	mov    %edx,%eax
}
f0104d61:	5d                   	pop    %ebp
f0104d62:	c3                   	ret    

f0104d63 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104d63:	55                   	push   %ebp
f0104d64:	89 e5                	mov    %esp,%ebp
f0104d66:	83 ec 04             	sub    $0x4,%esp
f0104d69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d6c:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104d6f:	eb 12                	jmp    f0104d83 <strchr+0x20>
		if (*s == c)
f0104d71:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d74:	8a 00                	mov    (%eax),%al
f0104d76:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104d79:	75 05                	jne    f0104d80 <strchr+0x1d>
			return (char *) s;
f0104d7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d7e:	eb 11                	jmp    f0104d91 <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104d80:	ff 45 08             	incl   0x8(%ebp)
f0104d83:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d86:	8a 00                	mov    (%eax),%al
f0104d88:	84 c0                	test   %al,%al
f0104d8a:	75 e5                	jne    f0104d71 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0104d8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d91:	c9                   	leave  
f0104d92:	c3                   	ret    

f0104d93 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104d93:	55                   	push   %ebp
f0104d94:	89 e5                	mov    %esp,%ebp
f0104d96:	83 ec 04             	sub    $0x4,%esp
f0104d99:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d9c:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0104d9f:	eb 0d                	jmp    f0104dae <strfind+0x1b>
		if (*s == c)
f0104da1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104da4:	8a 00                	mov    (%eax),%al
f0104da6:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0104da9:	74 0e                	je     f0104db9 <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104dab:	ff 45 08             	incl   0x8(%ebp)
f0104dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104db1:	8a 00                	mov    (%eax),%al
f0104db3:	84 c0                	test   %al,%al
f0104db5:	75 ea                	jne    f0104da1 <strfind+0xe>
f0104db7:	eb 01                	jmp    f0104dba <strfind+0x27>
		if (*s == c)
			break;
f0104db9:	90                   	nop
	return (char *) s;
f0104dba:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104dbd:	c9                   	leave  
f0104dbe:	c3                   	ret    

f0104dbf <memset>:


void *
memset(void *v, int c, uint32 n)
{
f0104dbf:	55                   	push   %ebp
f0104dc0:	89 e5                	mov    %esp,%ebp
f0104dc2:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f0104dc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dc8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0104dcb:	8b 45 10             	mov    0x10(%ebp),%eax
f0104dce:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f0104dd1:	eb 0e                	jmp    f0104de1 <memset+0x22>
		*p++ = c;
f0104dd3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104dd6:	8d 50 01             	lea    0x1(%eax),%edx
f0104dd9:	89 55 fc             	mov    %edx,-0x4(%ebp)
f0104ddc:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ddf:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0104de1:	ff 4d f8             	decl   -0x8(%ebp)
f0104de4:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0104de8:	79 e9                	jns    f0104dd3 <memset+0x14>
		*p++ = c;

	return v;
f0104dea:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104ded:	c9                   	leave  
f0104dee:	c3                   	ret    

f0104def <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
f0104def:	55                   	push   %ebp
f0104df0:	89 e5                	mov    %esp,%ebp
f0104df2:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0104df5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104df8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0104dfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dfe:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (n-- > 0)
f0104e01:	eb 16                	jmp    f0104e19 <memcpy+0x2a>
		*d++ = *s++;
f0104e03:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104e06:	8d 50 01             	lea    0x1(%eax),%edx
f0104e09:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104e0c:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104e0f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104e12:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104e15:	8a 12                	mov    (%edx),%dl
f0104e17:	88 10                	mov    %dl,(%eax)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0104e19:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e1c:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104e1f:	89 55 10             	mov    %edx,0x10(%ebp)
f0104e22:	85 c0                	test   %eax,%eax
f0104e24:	75 dd                	jne    f0104e03 <memcpy+0x14>
		*d++ = *s++;

	return dst;
f0104e26:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104e29:	c9                   	leave  
f0104e2a:	c3                   	ret    

f0104e2b <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
f0104e2b:	55                   	push   %ebp
f0104e2c:	89 e5                	mov    %esp,%ebp
f0104e2e:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f0104e31:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e34:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0104e37:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e3a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f0104e3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104e40:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0104e43:	73 50                	jae    f0104e95 <memmove+0x6a>
f0104e45:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104e48:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e4b:	01 d0                	add    %edx,%eax
f0104e4d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0104e50:	76 43                	jbe    f0104e95 <memmove+0x6a>
		s += n;
f0104e52:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e55:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f0104e58:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e5b:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f0104e5e:	eb 10                	jmp    f0104e70 <memmove+0x45>
			*--d = *--s;
f0104e60:	ff 4d f8             	decl   -0x8(%ebp)
f0104e63:	ff 4d fc             	decl   -0x4(%ebp)
f0104e66:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104e69:	8a 10                	mov    (%eax),%dl
f0104e6b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104e6e:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0104e70:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e73:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104e76:	89 55 10             	mov    %edx,0x10(%ebp)
f0104e79:	85 c0                	test   %eax,%eax
f0104e7b:	75 e3                	jne    f0104e60 <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104e7d:	eb 23                	jmp    f0104ea2 <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0104e7f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104e82:	8d 50 01             	lea    0x1(%eax),%edx
f0104e85:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0104e88:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104e8b:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104e8e:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0104e91:	8a 12                	mov    (%edx),%dl
f0104e93:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0104e95:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e98:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104e9b:	89 55 10             	mov    %edx,0x10(%ebp)
f0104e9e:	85 c0                	test   %eax,%eax
f0104ea0:	75 dd                	jne    f0104e7f <memmove+0x54>
			*d++ = *s++;

	return dst;
f0104ea2:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104ea5:	c9                   	leave  
f0104ea6:	c3                   	ret    

f0104ea7 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
f0104ea7:	55                   	push   %ebp
f0104ea8:	89 e5                	mov    %esp,%ebp
f0104eaa:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
f0104ead:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eb0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
f0104eb3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104eb6:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0104eb9:	eb 2a                	jmp    f0104ee5 <memcmp+0x3e>
		if (*s1 != *s2)
f0104ebb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104ebe:	8a 10                	mov    (%eax),%dl
f0104ec0:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104ec3:	8a 00                	mov    (%eax),%al
f0104ec5:	38 c2                	cmp    %al,%dl
f0104ec7:	74 16                	je     f0104edf <memcmp+0x38>
			return (int) *s1 - (int) *s2;
f0104ec9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104ecc:	8a 00                	mov    (%eax),%al
f0104ece:	0f b6 d0             	movzbl %al,%edx
f0104ed1:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0104ed4:	8a 00                	mov    (%eax),%al
f0104ed6:	0f b6 c0             	movzbl %al,%eax
f0104ed9:	29 c2                	sub    %eax,%edx
f0104edb:	89 d0                	mov    %edx,%eax
f0104edd:	eb 18                	jmp    f0104ef7 <memcmp+0x50>
		s1++, s2++;
f0104edf:	ff 45 fc             	incl   -0x4(%ebp)
f0104ee2:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
f0104ee5:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ee8:	8d 50 ff             	lea    -0x1(%eax),%edx
f0104eeb:	89 55 10             	mov    %edx,0x10(%ebp)
f0104eee:	85 c0                	test   %eax,%eax
f0104ef0:	75 c9                	jne    f0104ebb <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104ef2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ef7:	c9                   	leave  
f0104ef8:	c3                   	ret    

f0104ef9 <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
f0104ef9:	55                   	push   %ebp
f0104efa:	89 e5                	mov    %esp,%ebp
f0104efc:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0104eff:	8b 55 08             	mov    0x8(%ebp),%edx
f0104f02:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f05:	01 d0                	add    %edx,%eax
f0104f07:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0104f0a:	eb 15                	jmp    f0104f21 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104f0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f0f:	8a 00                	mov    (%eax),%al
f0104f11:	0f b6 d0             	movzbl %al,%edx
f0104f14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f17:	0f b6 c0             	movzbl %al,%eax
f0104f1a:	39 c2                	cmp    %eax,%edx
f0104f1c:	74 0d                	je     f0104f2b <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104f1e:	ff 45 08             	incl   0x8(%ebp)
f0104f21:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f24:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0104f27:	72 e3                	jb     f0104f0c <memfind+0x13>
f0104f29:	eb 01                	jmp    f0104f2c <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f0104f2b:	90                   	nop
	return (void *) s;
f0104f2c:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0104f2f:	c9                   	leave  
f0104f30:	c3                   	ret    

f0104f31 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104f31:	55                   	push   %ebp
f0104f32:	89 e5                	mov    %esp,%ebp
f0104f34:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0104f37:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0104f3e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f45:	eb 03                	jmp    f0104f4a <strtol+0x19>
		s++;
f0104f47:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104f4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f4d:	8a 00                	mov    (%eax),%al
f0104f4f:	3c 20                	cmp    $0x20,%al
f0104f51:	74 f4                	je     f0104f47 <strtol+0x16>
f0104f53:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f56:	8a 00                	mov    (%eax),%al
f0104f58:	3c 09                	cmp    $0x9,%al
f0104f5a:	74 eb                	je     f0104f47 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104f5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f5f:	8a 00                	mov    (%eax),%al
f0104f61:	3c 2b                	cmp    $0x2b,%al
f0104f63:	75 05                	jne    f0104f6a <strtol+0x39>
		s++;
f0104f65:	ff 45 08             	incl   0x8(%ebp)
f0104f68:	eb 13                	jmp    f0104f7d <strtol+0x4c>
	else if (*s == '-')
f0104f6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f6d:	8a 00                	mov    (%eax),%al
f0104f6f:	3c 2d                	cmp    $0x2d,%al
f0104f71:	75 0a                	jne    f0104f7d <strtol+0x4c>
		s++, neg = 1;
f0104f73:	ff 45 08             	incl   0x8(%ebp)
f0104f76:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104f7d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104f81:	74 06                	je     f0104f89 <strtol+0x58>
f0104f83:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0104f87:	75 20                	jne    f0104fa9 <strtol+0x78>
f0104f89:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f8c:	8a 00                	mov    (%eax),%al
f0104f8e:	3c 30                	cmp    $0x30,%al
f0104f90:	75 17                	jne    f0104fa9 <strtol+0x78>
f0104f92:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f95:	40                   	inc    %eax
f0104f96:	8a 00                	mov    (%eax),%al
f0104f98:	3c 78                	cmp    $0x78,%al
f0104f9a:	75 0d                	jne    f0104fa9 <strtol+0x78>
		s += 2, base = 16;
f0104f9c:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0104fa0:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0104fa7:	eb 28                	jmp    f0104fd1 <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
f0104fa9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104fad:	75 15                	jne    f0104fc4 <strtol+0x93>
f0104faf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fb2:	8a 00                	mov    (%eax),%al
f0104fb4:	3c 30                	cmp    $0x30,%al
f0104fb6:	75 0c                	jne    f0104fc4 <strtol+0x93>
		s++, base = 8;
f0104fb8:	ff 45 08             	incl   0x8(%ebp)
f0104fbb:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0104fc2:	eb 0d                	jmp    f0104fd1 <strtol+0xa0>
	else if (base == 0)
f0104fc4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104fc8:	75 07                	jne    f0104fd1 <strtol+0xa0>
		base = 10;
f0104fca:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104fd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fd4:	8a 00                	mov    (%eax),%al
f0104fd6:	3c 2f                	cmp    $0x2f,%al
f0104fd8:	7e 19                	jle    f0104ff3 <strtol+0xc2>
f0104fda:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fdd:	8a 00                	mov    (%eax),%al
f0104fdf:	3c 39                	cmp    $0x39,%al
f0104fe1:	7f 10                	jg     f0104ff3 <strtol+0xc2>
			dig = *s - '0';
f0104fe3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fe6:	8a 00                	mov    (%eax),%al
f0104fe8:	0f be c0             	movsbl %al,%eax
f0104feb:	83 e8 30             	sub    $0x30,%eax
f0104fee:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104ff1:	eb 42                	jmp    f0105035 <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
f0104ff3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ff6:	8a 00                	mov    (%eax),%al
f0104ff8:	3c 60                	cmp    $0x60,%al
f0104ffa:	7e 19                	jle    f0105015 <strtol+0xe4>
f0104ffc:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fff:	8a 00                	mov    (%eax),%al
f0105001:	3c 7a                	cmp    $0x7a,%al
f0105003:	7f 10                	jg     f0105015 <strtol+0xe4>
			dig = *s - 'a' + 10;
f0105005:	8b 45 08             	mov    0x8(%ebp),%eax
f0105008:	8a 00                	mov    (%eax),%al
f010500a:	0f be c0             	movsbl %al,%eax
f010500d:	83 e8 57             	sub    $0x57,%eax
f0105010:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0105013:	eb 20                	jmp    f0105035 <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
f0105015:	8b 45 08             	mov    0x8(%ebp),%eax
f0105018:	8a 00                	mov    (%eax),%al
f010501a:	3c 40                	cmp    $0x40,%al
f010501c:	7e 39                	jle    f0105057 <strtol+0x126>
f010501e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105021:	8a 00                	mov    (%eax),%al
f0105023:	3c 5a                	cmp    $0x5a,%al
f0105025:	7f 30                	jg     f0105057 <strtol+0x126>
			dig = *s - 'A' + 10;
f0105027:	8b 45 08             	mov    0x8(%ebp),%eax
f010502a:	8a 00                	mov    (%eax),%al
f010502c:	0f be c0             	movsbl %al,%eax
f010502f:	83 e8 37             	sub    $0x37,%eax
f0105032:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0105035:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105038:	3b 45 10             	cmp    0x10(%ebp),%eax
f010503b:	7d 19                	jge    f0105056 <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
f010503d:	ff 45 08             	incl   0x8(%ebp)
f0105040:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0105043:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105047:	89 c2                	mov    %eax,%edx
f0105049:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010504c:	01 d0                	add    %edx,%eax
f010504e:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0105051:	e9 7b ff ff ff       	jmp    f0104fd1 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f0105056:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0105057:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010505b:	74 08                	je     f0105065 <strtol+0x134>
		*endptr = (char *) s;
f010505d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105060:	8b 55 08             	mov    0x8(%ebp),%edx
f0105063:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0105065:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0105069:	74 07                	je     f0105072 <strtol+0x141>
f010506b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010506e:	f7 d8                	neg    %eax
f0105070:	eb 03                	jmp    f0105075 <strtol+0x144>
f0105072:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0105075:	c9                   	leave  
f0105076:	c3                   	ret    

f0105077 <strsplit>:

int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
f0105077:	55                   	push   %ebp
f0105078:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
f010507a:	8b 45 14             	mov    0x14(%ebp),%eax
f010507d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
f0105083:	8b 45 14             	mov    0x14(%ebp),%eax
f0105086:	8b 00                	mov    (%eax),%eax
f0105088:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010508f:	8b 45 10             	mov    0x10(%ebp),%eax
f0105092:	01 d0                	add    %edx,%eax
f0105094:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f010509a:	eb 0c                	jmp    f01050a8 <strsplit+0x31>
			*string++ = 0;
f010509c:	8b 45 08             	mov    0x8(%ebp),%eax
f010509f:	8d 50 01             	lea    0x1(%eax),%edx
f01050a2:	89 55 08             	mov    %edx,0x8(%ebp)
f01050a5:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f01050a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01050ab:	8a 00                	mov    (%eax),%al
f01050ad:	84 c0                	test   %al,%al
f01050af:	74 18                	je     f01050c9 <strsplit+0x52>
f01050b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01050b4:	8a 00                	mov    (%eax),%al
f01050b6:	0f be c0             	movsbl %al,%eax
f01050b9:	50                   	push   %eax
f01050ba:	ff 75 0c             	pushl  0xc(%ebp)
f01050bd:	e8 a1 fc ff ff       	call   f0104d63 <strchr>
f01050c2:	83 c4 08             	add    $0x8,%esp
f01050c5:	85 c0                	test   %eax,%eax
f01050c7:	75 d3                	jne    f010509c <strsplit+0x25>
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
f01050c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01050cc:	8a 00                	mov    (%eax),%al
f01050ce:	84 c0                	test   %al,%al
f01050d0:	74 5a                	je     f010512c <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1) 
f01050d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01050d5:	8b 00                	mov    (%eax),%eax
f01050d7:	83 f8 0f             	cmp    $0xf,%eax
f01050da:	75 07                	jne    f01050e3 <strsplit+0x6c>
		{
			return 0;
f01050dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01050e1:	eb 66                	jmp    f0105149 <strsplit+0xd2>
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
f01050e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01050e6:	8b 00                	mov    (%eax),%eax
f01050e8:	8d 48 01             	lea    0x1(%eax),%ecx
f01050eb:	8b 55 14             	mov    0x14(%ebp),%edx
f01050ee:	89 0a                	mov    %ecx,(%edx)
f01050f0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01050f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01050fa:	01 c2                	add    %eax,%edx
f01050fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01050ff:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
f0105101:	eb 03                	jmp    f0105106 <strsplit+0x8f>
			string++;
f0105103:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
f0105106:	8b 45 08             	mov    0x8(%ebp),%eax
f0105109:	8a 00                	mov    (%eax),%al
f010510b:	84 c0                	test   %al,%al
f010510d:	74 8b                	je     f010509a <strsplit+0x23>
f010510f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105112:	8a 00                	mov    (%eax),%al
f0105114:	0f be c0             	movsbl %al,%eax
f0105117:	50                   	push   %eax
f0105118:	ff 75 0c             	pushl  0xc(%ebp)
f010511b:	e8 43 fc ff ff       	call   f0104d63 <strchr>
f0105120:	83 c4 08             	add    $0x8,%esp
f0105123:	85 c0                	test   %eax,%eax
f0105125:	74 dc                	je     f0105103 <strsplit+0x8c>
			string++;
	}
f0105127:	e9 6e ff ff ff       	jmp    f010509a <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
f010512c:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
f010512d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105130:	8b 00                	mov    (%eax),%eax
f0105132:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0105139:	8b 45 10             	mov    0x10(%ebp),%eax
f010513c:	01 d0                	add    %edx,%eax
f010513e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
f0105144:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0105149:	c9                   	leave  
f010514a:	c3                   	ret    
f010514b:	90                   	nop

f010514c <__udivdi3>:
f010514c:	55                   	push   %ebp
f010514d:	57                   	push   %edi
f010514e:	56                   	push   %esi
f010514f:	53                   	push   %ebx
f0105150:	83 ec 1c             	sub    $0x1c,%esp
f0105153:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105157:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f010515b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010515f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105163:	89 ca                	mov    %ecx,%edx
f0105165:	89 f8                	mov    %edi,%eax
f0105167:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010516b:	85 f6                	test   %esi,%esi
f010516d:	75 2d                	jne    f010519c <__udivdi3+0x50>
f010516f:	39 cf                	cmp    %ecx,%edi
f0105171:	77 65                	ja     f01051d8 <__udivdi3+0x8c>
f0105173:	89 fd                	mov    %edi,%ebp
f0105175:	85 ff                	test   %edi,%edi
f0105177:	75 0b                	jne    f0105184 <__udivdi3+0x38>
f0105179:	b8 01 00 00 00       	mov    $0x1,%eax
f010517e:	31 d2                	xor    %edx,%edx
f0105180:	f7 f7                	div    %edi
f0105182:	89 c5                	mov    %eax,%ebp
f0105184:	31 d2                	xor    %edx,%edx
f0105186:	89 c8                	mov    %ecx,%eax
f0105188:	f7 f5                	div    %ebp
f010518a:	89 c1                	mov    %eax,%ecx
f010518c:	89 d8                	mov    %ebx,%eax
f010518e:	f7 f5                	div    %ebp
f0105190:	89 cf                	mov    %ecx,%edi
f0105192:	89 fa                	mov    %edi,%edx
f0105194:	83 c4 1c             	add    $0x1c,%esp
f0105197:	5b                   	pop    %ebx
f0105198:	5e                   	pop    %esi
f0105199:	5f                   	pop    %edi
f010519a:	5d                   	pop    %ebp
f010519b:	c3                   	ret    
f010519c:	39 ce                	cmp    %ecx,%esi
f010519e:	77 28                	ja     f01051c8 <__udivdi3+0x7c>
f01051a0:	0f bd fe             	bsr    %esi,%edi
f01051a3:	83 f7 1f             	xor    $0x1f,%edi
f01051a6:	75 40                	jne    f01051e8 <__udivdi3+0x9c>
f01051a8:	39 ce                	cmp    %ecx,%esi
f01051aa:	72 0a                	jb     f01051b6 <__udivdi3+0x6a>
f01051ac:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01051b0:	0f 87 9e 00 00 00    	ja     f0105254 <__udivdi3+0x108>
f01051b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01051bb:	89 fa                	mov    %edi,%edx
f01051bd:	83 c4 1c             	add    $0x1c,%esp
f01051c0:	5b                   	pop    %ebx
f01051c1:	5e                   	pop    %esi
f01051c2:	5f                   	pop    %edi
f01051c3:	5d                   	pop    %ebp
f01051c4:	c3                   	ret    
f01051c5:	8d 76 00             	lea    0x0(%esi),%esi
f01051c8:	31 ff                	xor    %edi,%edi
f01051ca:	31 c0                	xor    %eax,%eax
f01051cc:	89 fa                	mov    %edi,%edx
f01051ce:	83 c4 1c             	add    $0x1c,%esp
f01051d1:	5b                   	pop    %ebx
f01051d2:	5e                   	pop    %esi
f01051d3:	5f                   	pop    %edi
f01051d4:	5d                   	pop    %ebp
f01051d5:	c3                   	ret    
f01051d6:	66 90                	xchg   %ax,%ax
f01051d8:	89 d8                	mov    %ebx,%eax
f01051da:	f7 f7                	div    %edi
f01051dc:	31 ff                	xor    %edi,%edi
f01051de:	89 fa                	mov    %edi,%edx
f01051e0:	83 c4 1c             	add    $0x1c,%esp
f01051e3:	5b                   	pop    %ebx
f01051e4:	5e                   	pop    %esi
f01051e5:	5f                   	pop    %edi
f01051e6:	5d                   	pop    %ebp
f01051e7:	c3                   	ret    
f01051e8:	bd 20 00 00 00       	mov    $0x20,%ebp
f01051ed:	89 eb                	mov    %ebp,%ebx
f01051ef:	29 fb                	sub    %edi,%ebx
f01051f1:	89 f9                	mov    %edi,%ecx
f01051f3:	d3 e6                	shl    %cl,%esi
f01051f5:	89 c5                	mov    %eax,%ebp
f01051f7:	88 d9                	mov    %bl,%cl
f01051f9:	d3 ed                	shr    %cl,%ebp
f01051fb:	89 e9                	mov    %ebp,%ecx
f01051fd:	09 f1                	or     %esi,%ecx
f01051ff:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105203:	89 f9                	mov    %edi,%ecx
f0105205:	d3 e0                	shl    %cl,%eax
f0105207:	89 c5                	mov    %eax,%ebp
f0105209:	89 d6                	mov    %edx,%esi
f010520b:	88 d9                	mov    %bl,%cl
f010520d:	d3 ee                	shr    %cl,%esi
f010520f:	89 f9                	mov    %edi,%ecx
f0105211:	d3 e2                	shl    %cl,%edx
f0105213:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105217:	88 d9                	mov    %bl,%cl
f0105219:	d3 e8                	shr    %cl,%eax
f010521b:	09 c2                	or     %eax,%edx
f010521d:	89 d0                	mov    %edx,%eax
f010521f:	89 f2                	mov    %esi,%edx
f0105221:	f7 74 24 0c          	divl   0xc(%esp)
f0105225:	89 d6                	mov    %edx,%esi
f0105227:	89 c3                	mov    %eax,%ebx
f0105229:	f7 e5                	mul    %ebp
f010522b:	39 d6                	cmp    %edx,%esi
f010522d:	72 19                	jb     f0105248 <__udivdi3+0xfc>
f010522f:	74 0b                	je     f010523c <__udivdi3+0xf0>
f0105231:	89 d8                	mov    %ebx,%eax
f0105233:	31 ff                	xor    %edi,%edi
f0105235:	e9 58 ff ff ff       	jmp    f0105192 <__udivdi3+0x46>
f010523a:	66 90                	xchg   %ax,%ax
f010523c:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105240:	89 f9                	mov    %edi,%ecx
f0105242:	d3 e2                	shl    %cl,%edx
f0105244:	39 c2                	cmp    %eax,%edx
f0105246:	73 e9                	jae    f0105231 <__udivdi3+0xe5>
f0105248:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010524b:	31 ff                	xor    %edi,%edi
f010524d:	e9 40 ff ff ff       	jmp    f0105192 <__udivdi3+0x46>
f0105252:	66 90                	xchg   %ax,%ax
f0105254:	31 c0                	xor    %eax,%eax
f0105256:	e9 37 ff ff ff       	jmp    f0105192 <__udivdi3+0x46>
f010525b:	90                   	nop

f010525c <__umoddi3>:
f010525c:	55                   	push   %ebp
f010525d:	57                   	push   %edi
f010525e:	56                   	push   %esi
f010525f:	53                   	push   %ebx
f0105260:	83 ec 1c             	sub    $0x1c,%esp
f0105263:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105267:	8b 74 24 34          	mov    0x34(%esp),%esi
f010526b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010526f:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105273:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105277:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010527b:	89 f3                	mov    %esi,%ebx
f010527d:	89 fa                	mov    %edi,%edx
f010527f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105283:	89 34 24             	mov    %esi,(%esp)
f0105286:	85 c0                	test   %eax,%eax
f0105288:	75 1a                	jne    f01052a4 <__umoddi3+0x48>
f010528a:	39 f7                	cmp    %esi,%edi
f010528c:	0f 86 a2 00 00 00    	jbe    f0105334 <__umoddi3+0xd8>
f0105292:	89 c8                	mov    %ecx,%eax
f0105294:	89 f2                	mov    %esi,%edx
f0105296:	f7 f7                	div    %edi
f0105298:	89 d0                	mov    %edx,%eax
f010529a:	31 d2                	xor    %edx,%edx
f010529c:	83 c4 1c             	add    $0x1c,%esp
f010529f:	5b                   	pop    %ebx
f01052a0:	5e                   	pop    %esi
f01052a1:	5f                   	pop    %edi
f01052a2:	5d                   	pop    %ebp
f01052a3:	c3                   	ret    
f01052a4:	39 f0                	cmp    %esi,%eax
f01052a6:	0f 87 ac 00 00 00    	ja     f0105358 <__umoddi3+0xfc>
f01052ac:	0f bd e8             	bsr    %eax,%ebp
f01052af:	83 f5 1f             	xor    $0x1f,%ebp
f01052b2:	0f 84 ac 00 00 00    	je     f0105364 <__umoddi3+0x108>
f01052b8:	bf 20 00 00 00       	mov    $0x20,%edi
f01052bd:	29 ef                	sub    %ebp,%edi
f01052bf:	89 fe                	mov    %edi,%esi
f01052c1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01052c5:	89 e9                	mov    %ebp,%ecx
f01052c7:	d3 e0                	shl    %cl,%eax
f01052c9:	89 d7                	mov    %edx,%edi
f01052cb:	89 f1                	mov    %esi,%ecx
f01052cd:	d3 ef                	shr    %cl,%edi
f01052cf:	09 c7                	or     %eax,%edi
f01052d1:	89 e9                	mov    %ebp,%ecx
f01052d3:	d3 e2                	shl    %cl,%edx
f01052d5:	89 14 24             	mov    %edx,(%esp)
f01052d8:	89 d8                	mov    %ebx,%eax
f01052da:	d3 e0                	shl    %cl,%eax
f01052dc:	89 c2                	mov    %eax,%edx
f01052de:	8b 44 24 08          	mov    0x8(%esp),%eax
f01052e2:	d3 e0                	shl    %cl,%eax
f01052e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052e8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01052ec:	89 f1                	mov    %esi,%ecx
f01052ee:	d3 e8                	shr    %cl,%eax
f01052f0:	09 d0                	or     %edx,%eax
f01052f2:	d3 eb                	shr    %cl,%ebx
f01052f4:	89 da                	mov    %ebx,%edx
f01052f6:	f7 f7                	div    %edi
f01052f8:	89 d3                	mov    %edx,%ebx
f01052fa:	f7 24 24             	mull   (%esp)
f01052fd:	89 c6                	mov    %eax,%esi
f01052ff:	89 d1                	mov    %edx,%ecx
f0105301:	39 d3                	cmp    %edx,%ebx
f0105303:	0f 82 87 00 00 00    	jb     f0105390 <__umoddi3+0x134>
f0105309:	0f 84 91 00 00 00    	je     f01053a0 <__umoddi3+0x144>
f010530f:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105313:	29 f2                	sub    %esi,%edx
f0105315:	19 cb                	sbb    %ecx,%ebx
f0105317:	89 d8                	mov    %ebx,%eax
f0105319:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f010531d:	d3 e0                	shl    %cl,%eax
f010531f:	89 e9                	mov    %ebp,%ecx
f0105321:	d3 ea                	shr    %cl,%edx
f0105323:	09 d0                	or     %edx,%eax
f0105325:	89 e9                	mov    %ebp,%ecx
f0105327:	d3 eb                	shr    %cl,%ebx
f0105329:	89 da                	mov    %ebx,%edx
f010532b:	83 c4 1c             	add    $0x1c,%esp
f010532e:	5b                   	pop    %ebx
f010532f:	5e                   	pop    %esi
f0105330:	5f                   	pop    %edi
f0105331:	5d                   	pop    %ebp
f0105332:	c3                   	ret    
f0105333:	90                   	nop
f0105334:	89 fd                	mov    %edi,%ebp
f0105336:	85 ff                	test   %edi,%edi
f0105338:	75 0b                	jne    f0105345 <__umoddi3+0xe9>
f010533a:	b8 01 00 00 00       	mov    $0x1,%eax
f010533f:	31 d2                	xor    %edx,%edx
f0105341:	f7 f7                	div    %edi
f0105343:	89 c5                	mov    %eax,%ebp
f0105345:	89 f0                	mov    %esi,%eax
f0105347:	31 d2                	xor    %edx,%edx
f0105349:	f7 f5                	div    %ebp
f010534b:	89 c8                	mov    %ecx,%eax
f010534d:	f7 f5                	div    %ebp
f010534f:	89 d0                	mov    %edx,%eax
f0105351:	e9 44 ff ff ff       	jmp    f010529a <__umoddi3+0x3e>
f0105356:	66 90                	xchg   %ax,%ax
f0105358:	89 c8                	mov    %ecx,%eax
f010535a:	89 f2                	mov    %esi,%edx
f010535c:	83 c4 1c             	add    $0x1c,%esp
f010535f:	5b                   	pop    %ebx
f0105360:	5e                   	pop    %esi
f0105361:	5f                   	pop    %edi
f0105362:	5d                   	pop    %ebp
f0105363:	c3                   	ret    
f0105364:	3b 04 24             	cmp    (%esp),%eax
f0105367:	72 06                	jb     f010536f <__umoddi3+0x113>
f0105369:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f010536d:	77 0f                	ja     f010537e <__umoddi3+0x122>
f010536f:	89 f2                	mov    %esi,%edx
f0105371:	29 f9                	sub    %edi,%ecx
f0105373:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0105377:	89 14 24             	mov    %edx,(%esp)
f010537a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010537e:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105382:	8b 14 24             	mov    (%esp),%edx
f0105385:	83 c4 1c             	add    $0x1c,%esp
f0105388:	5b                   	pop    %ebx
f0105389:	5e                   	pop    %esi
f010538a:	5f                   	pop    %edi
f010538b:	5d                   	pop    %ebp
f010538c:	c3                   	ret    
f010538d:	8d 76 00             	lea    0x0(%esi),%esi
f0105390:	2b 04 24             	sub    (%esp),%eax
f0105393:	19 fa                	sbb    %edi,%edx
f0105395:	89 d1                	mov    %edx,%ecx
f0105397:	89 c6                	mov    %eax,%esi
f0105399:	e9 71 ff ff ff       	jmp    f010530f <__umoddi3+0xb3>
f010539e:	66 90                	xchg   %ax,%ax
f01053a0:	39 44 24 04          	cmp    %eax,0x4(%esp)
f01053a4:	72 ea                	jb     f0105390 <__umoddi3+0x134>
f01053a6:	89 d9                	mov    %ebx,%ecx
f01053a8:	e9 62 ff ff ff       	jmp    f010530f <__umoddi3+0xb3>
