
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
f0100015:	0f 01 15 18 00 12 00 	lgdtl  0x120018

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
f0100033:	bc bc ff 11 f0       	mov    $0xf011ffbc,%esp

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
f0100045:	ba 5c 44 15 f0       	mov    $0xf015445c,%edx
f010004a:	b8 b2 2c 15 f0       	mov    $0xf0152cb2,%eax
f010004f:	29 c2                	sub    %eax,%edx
f0100051:	89 d0                	mov    %edx,%eax
f0100053:	83 ec 04             	sub    $0x4,%esp
f0100056:	50                   	push   %eax
f0100057:	6a 00                	push   $0x0
f0100059:	68 b2 2c 15 f0       	push   $0xf0152cb2
f010005e:	e8 04 61 00 00       	call   f0106167 <memset>
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
f0100070:	e8 76 14 00 00       	call   f01014eb <detect_memory>
	initialize_kernel_VM();
f0100075:	e8 08 37 00 00       	call   f0103782 <initialize_kernel_VM>
	initialize_paging();
f010007a:	e8 c7 3a 00 00       	call   f0103b46 <initialize_paging>
	page_check();
f010007f:	e8 33 18 00 00       	call   f01018b7 <page_check>

	
	// Lab 3 user environment initialization functions
	env_init();
f0100084:	e8 b4 42 00 00       	call   f010433d <env_init>
	idt_init();
f0100089:	e8 48 4a 00 00       	call   f0104ad6 <idt_init>

	
	// start the kernel command prompt.
	while (1==1)
	{
		cprintf("\nWelcome to the FOS kernel command prompt!\n");
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	68 60 67 10 f0       	push   $0xf0106760
f0100096:	e8 ea 49 00 00       	call   f0104a85 <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
		cprintf("Type 'help' for a list of commands.\n");	
f010009e:	83 ec 0c             	sub    $0xc,%esp
f01000a1:	68 8c 67 10 f0       	push   $0xf010678c
f01000a6:	e8 da 49 00 00       	call   f0104a85 <cprintf>
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
f01000be:	68 b1 67 10 f0       	push   $0xf01067b1
f01000c3:	e8 bd 49 00 00       	call   f0104a85 <cprintf>
f01000c8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f01000cb:	83 ec 0c             	sub    $0xc,%esp
f01000ce:	68 b8 67 10 f0       	push   $0xf01067b8
f01000d3:	e8 ad 49 00 00       	call   f0104a85 <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	68 00 68 10 f0       	push   $0xf0106800
f01000e3:	e8 9d 49 00 00       	call   f0104a85 <cprintf>
f01000e8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                   !! FCIS says HELLO !!                     !!\n");
f01000eb:	83 ec 0c             	sub    $0xc,%esp
f01000ee:	68 48 68 10 f0       	push   $0xf0106848
f01000f3:	e8 8d 49 00 00       	call   f0104a85 <cprintf>
f01000f8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000fb:	83 ec 0c             	sub    $0xc,%esp
f01000fe:	68 00 68 10 f0       	push   $0xf0106800
f0100103:	e8 7d 49 00 00       	call   f0104a85 <cprintf>
f0100108:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	68 b8 67 10 f0       	push   $0xf01067b8
f0100113:	e8 6d 49 00 00       	call   f0104a85 <cprintf>
f0100118:	83 c4 10             	add    $0x10,%esp
	cprintf("\n\n\n\n");	
f010011b:	83 ec 0c             	sub    $0xc,%esp
f010011e:	68 8d 68 10 f0       	push   $0xf010688d
f0100123:	e8 5d 49 00 00       	call   f0104a85 <cprintf>
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
f0100134:	a1 c0 2c 15 f0       	mov    0xf0152cc0,%eax
f0100139:	85 c0                	test   %eax,%eax
f010013b:	74 02                	je     f010013f <_panic+0x11>
		goto dead;
f010013d:	eb 49                	jmp    f0100188 <_panic+0x5a>
	panicstr = fmt;
f010013f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100142:	a3 c0 2c 15 f0       	mov    %eax,0xf0152cc0

	va_start(ap, fmt);
f0100147:	8d 45 10             	lea    0x10(%ebp),%eax
f010014a:	83 c0 04             	add    $0x4,%eax
f010014d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100150:	83 ec 04             	sub    $0x4,%esp
f0100153:	ff 75 0c             	pushl  0xc(%ebp)
f0100156:	ff 75 08             	pushl  0x8(%ebp)
f0100159:	68 92 68 10 f0       	push   $0xf0106892
f010015e:	e8 22 49 00 00       	call   f0104a85 <cprintf>
f0100163:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f0100166:	8b 45 10             	mov    0x10(%ebp),%eax
f0100169:	83 ec 08             	sub    $0x8,%esp
f010016c:	ff 75 f4             	pushl  -0xc(%ebp)
f010016f:	50                   	push   %eax
f0100170:	e8 e7 48 00 00       	call   f0104a5c <vcprintf>
f0100175:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f0100178:	83 ec 0c             	sub    $0xc,%esp
f010017b:	68 aa 68 10 f0       	push   $0xf01068aa
f0100180:	e8 00 49 00 00       	call   f0104a85 <cprintf>
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
f01001a7:	68 ac 68 10 f0       	push   $0xf01068ac
f01001ac:	e8 d4 48 00 00       	call   f0104a85 <cprintf>
f01001b1:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01001b7:	83 ec 08             	sub    $0x8,%esp
f01001ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01001bd:	50                   	push   %eax
f01001be:	e8 99 48 00 00       	call   f0104a5c <vcprintf>
f01001c3:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001c6:	83 ec 0c             	sub    $0xc,%esp
f01001c9:	68 aa 68 10 f0       	push   $0xf01068aa
f01001ce:	e8 b2 48 00 00       	call   f0104a85 <cprintf>
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
f0100221:	a1 e0 2c 15 f0       	mov    0xf0152ce0,%eax
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
f01002dc:	a3 e0 2c 15 f0       	mov    %eax,0xf0152ce0
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
f01003f4:	c7 05 e4 2c 15 f0 b4 	movl   $0x3b4,0xf0152ce4
f01003fb:	03 00 00 
f01003fe:	eb 14                	jmp    f0100414 <cga_init+0x52>
	} else {
		*cp = was;
f0100400:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100403:	66 8b 45 fa          	mov    -0x6(%ebp),%ax
f0100407:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
f010040a:	c7 05 e4 2c 15 f0 d4 	movl   $0x3d4,0xf0152ce4
f0100411:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100414:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
f0100419:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010041c:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
f0100420:	8a 45 e0             	mov    -0x20(%ebp),%al
f0100423:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100426:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100427:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
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
f0100445:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
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
f0100458:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
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
f0100476:	a3 e8 2c 15 f0       	mov    %eax,0xf0152ce8
	crt_pos = pos;
f010047b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010047e:	66 a3 ec 2c 15 f0    	mov    %ax,0xf0152cec
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
f01004cb:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f01004d1:	66 85 c0             	test   %ax,%ax
f01004d4:	0f 84 d0 00 00 00    	je     f01005aa <cga_putc+0x123>
			crt_pos--;
f01004da:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f01004e0:	48                   	dec    %eax
f01004e1:	66 a3 ec 2c 15 f0    	mov    %ax,0xf0152cec
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e7:	8b 15 e8 2c 15 f0    	mov    0xf0152ce8,%edx
f01004ed:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
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
f010050a:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f0100510:	83 c0 50             	add    $0x50,%eax
f0100513:	66 a3 ec 2c 15 f0    	mov    %ax,0xf0152cec
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100519:	66 8b 0d ec 2c 15 f0 	mov    0xf0152cec,%cx
f0100520:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f0100526:	bb 50 00 00 00       	mov    $0x50,%ebx
f010052b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100530:	66 f7 f3             	div    %bx
f0100533:	89 d0                	mov    %edx,%eax
f0100535:	29 c1                	sub    %eax,%ecx
f0100537:	89 c8                	mov    %ecx,%eax
f0100539:	66 a3 ec 2c 15 f0    	mov    %ax,0xf0152cec
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
f0100584:	8b 0d e8 2c 15 f0    	mov    0xf0152ce8,%ecx
f010058a:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f0100590:	8d 50 01             	lea    0x1(%eax),%edx
f0100593:	66 89 15 ec 2c 15 f0 	mov    %dx,0xf0152cec
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
f01005ab:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f01005b1:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005b5:	76 58                	jbe    f010060f <cga_putc+0x188>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
f01005b7:	a1 e8 2c 15 f0       	mov    0xf0152ce8,%eax
f01005bc:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c2:	a1 e8 2c 15 f0       	mov    0xf0152ce8,%eax
f01005c7:	83 ec 04             	sub    $0x4,%esp
f01005ca:	68 00 0f 00 00       	push   $0xf00
f01005cf:	52                   	push   %edx
f01005d0:	50                   	push   %eax
f01005d1:	e8 c1 5b 00 00       	call   f0106197 <memcpy>
f01005d6:	83 c4 10             	add    $0x10,%esp
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005d9:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f01005e0:	eb 15                	jmp    f01005f7 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
f01005e2:	8b 15 e8 2c 15 f0    	mov    0xf0152ce8,%edx
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
f0100600:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f0100606:	83 e8 50             	sub    $0x50,%eax
f0100609:	66 a3 ec 2c 15 f0    	mov    %ax,0xf0152cec
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010060f:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
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
f0100622:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f0100628:	66 c1 e8 08          	shr    $0x8,%ax
f010062c:	0f b6 c0             	movzbl %al,%eax
f010062f:	8b 15 e4 2c 15 f0    	mov    0xf0152ce4,%edx
f0100635:	42                   	inc    %edx
f0100636:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0100639:	88 45 e1             	mov    %al,-0x1f(%ebp)
f010063c:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010063f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100642:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f0100643:	a1 e4 2c 15 f0       	mov    0xf0152ce4,%eax
f0100648:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010064b:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
f010064f:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100652:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100655:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100656:	66 a1 ec 2c 15 f0    	mov    0xf0152cec,%ax
f010065c:	0f b6 c0             	movzbl %al,%eax
f010065f:	8b 15 e4 2c 15 f0    	mov    0xf0152ce4,%edx
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
f01006c2:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f01006c7:	83 c8 40             	or     $0x40,%eax
f01006ca:	a3 08 2f 15 f0       	mov    %eax,0xf0152f08
		return 0;
f01006cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d4:	e9 21 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (data & 0x80) {
f01006d9:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006dc:	84 c0                	test   %al,%al
f01006de:	79 44                	jns    f0100724 <kbd_proc_data+0xab>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006e0:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
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
f01006fe:	8a 80 20 00 12 f0    	mov    -0xfedffe0(%eax),%al
f0100704:	83 c8 40             	or     $0x40,%eax
f0100707:	0f b6 c0             	movzbl %al,%eax
f010070a:	f7 d0                	not    %eax
f010070c:	89 c2                	mov    %eax,%edx
f010070e:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f0100713:	21 d0                	and    %edx,%eax
f0100715:	a3 08 2f 15 f0       	mov    %eax,0xf0152f08
		return 0;
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
f010071f:	e9 d6 00 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (shift & E0ESC) {
f0100724:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f0100729:	83 e0 40             	and    $0x40,%eax
f010072c:	85 c0                	test   %eax,%eax
f010072e:	74 11                	je     f0100741 <kbd_proc_data+0xc8>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100730:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f0100734:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f0100739:	83 e0 bf             	and    $0xffffffbf,%eax
f010073c:	a3 08 2f 15 f0       	mov    %eax,0xf0152f08
	}

	shift |= shiftcode[data];
f0100741:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100745:	8a 80 20 00 12 f0    	mov    -0xfedffe0(%eax),%al
f010074b:	0f b6 d0             	movzbl %al,%edx
f010074e:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f0100753:	09 d0                	or     %edx,%eax
f0100755:	a3 08 2f 15 f0       	mov    %eax,0xf0152f08
	shift ^= togglecode[data];
f010075a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010075e:	8a 80 20 01 12 f0    	mov    -0xfedfee0(%eax),%al
f0100764:	0f b6 d0             	movzbl %al,%edx
f0100767:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f010076c:	31 d0                	xor    %edx,%eax
f010076e:	a3 08 2f 15 f0       	mov    %eax,0xf0152f08

	c = charcode[shift & (CTL | SHIFT)][data];
f0100773:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f0100778:	83 e0 03             	and    $0x3,%eax
f010077b:	8b 14 85 20 05 12 f0 	mov    -0xfedfae0(,%eax,4),%edx
f0100782:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100786:	01 d0                	add    %edx,%eax
f0100788:	8a 00                	mov    (%eax),%al
f010078a:	0f b6 c0             	movzbl %al,%eax
f010078d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f0100790:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
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
f01007be:	a1 08 2f 15 f0       	mov    0xf0152f08,%eax
f01007c3:	f7 d0                	not    %eax
f01007c5:	83 e0 06             	and    $0x6,%eax
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	75 2b                	jne    f01007f7 <kbd_proc_data+0x17e>
f01007cc:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f01007d3:	75 22                	jne    f01007f7 <kbd_proc_data+0x17e>
		cprintf("Rebooting!\n");
f01007d5:	83 ec 0c             	sub    $0xc,%esp
f01007d8:	68 c6 68 10 f0       	push   $0xf01068c6
f01007dd:	e8 a3 42 00 00       	call   f0104a85 <cprintf>
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
f010082b:	a1 04 2f 15 f0       	mov    0xf0152f04,%eax
f0100830:	8d 50 01             	lea    0x1(%eax),%edx
f0100833:	89 15 04 2f 15 f0    	mov    %edx,0xf0152f04
f0100839:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010083c:	88 90 00 2d 15 f0    	mov    %dl,-0xfead300(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100842:	a1 04 2f 15 f0       	mov    0xf0152f04,%eax
f0100847:	3d 00 02 00 00       	cmp    $0x200,%eax
f010084c:	75 0a                	jne    f0100858 <cons_intr+0x3d>
			cons.wpos = 0;
f010084e:	c7 05 04 2f 15 f0 00 	movl   $0x0,0xf0152f04
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
f0100879:	8b 15 00 2f 15 f0    	mov    0xf0152f00,%edx
f010087f:	a1 04 2f 15 f0       	mov    0xf0152f04,%eax
f0100884:	39 c2                	cmp    %eax,%edx
f0100886:	74 35                	je     f01008bd <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
f0100888:	a1 00 2f 15 f0       	mov    0xf0152f00,%eax
f010088d:	8d 50 01             	lea    0x1(%eax),%edx
f0100890:	89 15 00 2f 15 f0    	mov    %edx,0xf0152f00
f0100896:	8a 80 00 2d 15 f0    	mov    -0xfead300(%eax),%al
f010089c:	0f b6 c0             	movzbl %al,%eax
f010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008a2:	a1 00 2f 15 f0       	mov    0xf0152f00,%eax
f01008a7:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008ac:	75 0a                	jne    f01008b8 <cons_getc+0x4f>
			cons.rpos = 0;
f01008ae:	c7 05 00 2f 15 f0 00 	movl   $0x0,0xf0152f00
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
f01008fb:	a1 e0 2c 15 f0       	mov    0xf0152ce0,%eax
f0100900:	85 c0                	test   %eax,%eax
f0100902:	75 10                	jne    f0100914 <console_initialize+0x2e>
		cprintf("Serial port does not exist!\n");
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	68 d2 68 10 f0       	push   $0xf01068d2
f010090c:	e8 74 41 00 00       	call   f0104a85 <cprintf>
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

int firstTime = 1;

//invoke the command prompt
void run_command_prompt()
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	81 ec 08 04 00 00    	sub    $0x408,%esp
	//CAUTION: DON'T CHANGE OR COMMENT THESE LINE======
	if (firstTime)
f010095a:	a1 18 06 12 f0       	mov    0xf0120618,%eax
f010095f:	85 c0                	test   %eax,%eax
f0100961:	74 11                	je     f0100974 <run_command_prompt+0x23>
	{
		firstTime = 0;
f0100963:	c7 05 18 06 12 f0 00 	movl   $0x0,0xf0120618
f010096a:	00 00 00 
		TestAss1();
f010096d:	e8 73 19 00 00       	call   f01022e5 <TestAss1>
f0100972:	eb 10                	jmp    f0100984 <run_command_prompt+0x33>
	}
	else
	{
		cprintf("Test failed.\n");
f0100974:	83 ec 0c             	sub    $0xc,%esp
f0100977:	68 ff 6c 10 f0       	push   $0xf0106cff
f010097c:	e8 04 41 00 00       	call   f0104a85 <cprintf>
f0100981:	83 c4 10             	add    $0x10,%esp
	char command_line[1024];

	while (1==1)
	{
		//get command line
		readline("FOS> ", command_line);
f0100984:	83 ec 08             	sub    $0x8,%esp
f0100987:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f010098d:	50                   	push   %eax
f010098e:	68 0d 6d 10 f0       	push   $0xf0106d0d
f0100993:	e8 e3 54 00 00       	call   f0105e7b <readline>
f0100998:	83 c4 10             	add    $0x10,%esp

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
f010099b:	83 ec 0c             	sub    $0xc,%esp
f010099e:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f01009a4:	50                   	push   %eax
f01009a5:	e8 0d 00 00 00       	call   f01009b7 <execute_command>
f01009aa:	83 c4 10             	add    $0x10,%esp
f01009ad:	85 c0                	test   %eax,%eax
f01009af:	78 02                	js     f01009b3 <run_command_prompt+0x62>
				break;
	}
f01009b1:	eb d1                	jmp    f0100984 <run_command_prompt+0x33>
		readline("FOS> ", command_line);

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
				break;
f01009b3:	90                   	nop
	}
}
f01009b4:	90                   	nop
f01009b5:	c9                   	leave  
f01009b6:	c3                   	ret    

f01009b7 <execute_command>:
#define WHITESPACE "\t\r\n "

//Function to parse any command and execute it
//(simply by calling its corresponding function)
int execute_command(char *command_string)
{
f01009b7:	55                   	push   %ebp
f01009b8:	89 e5                	mov    %esp,%ebp
f01009ba:	83 ec 58             	sub    $0x58,%esp
	int number_of_arguments;
	//allocate array of char * of size MAX_ARGUMENTS = 16 found in string.h
	char *arguments[MAX_ARGUMENTS];


	strsplit(command_string, WHITESPACE, arguments, &number_of_arguments) ;
f01009bd:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01009c0:	50                   	push   %eax
f01009c1:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01009c4:	50                   	push   %eax
f01009c5:	68 13 6d 10 f0       	push   $0xf0106d13
f01009ca:	ff 75 08             	pushl  0x8(%ebp)
f01009cd:	e8 4d 5a 00 00       	call   f010641f <strsplit>
f01009d2:	83 c4 10             	add    $0x10,%esp
	if (number_of_arguments == 0)
f01009d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009d8:	85 c0                	test   %eax,%eax
f01009da:	75 0a                	jne    f01009e6 <execute_command+0x2f>
		return 0;
f01009dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01009e1:	e9 95 00 00 00       	jmp    f0100a7b <execute_command+0xc4>

	// Lookup in the commands array and execute the command
	int command_found = 0;
f01009e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009ed:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01009f4:	eb 33                	jmp    f0100a29 <execute_command+0x72>
	{
		if (strcmp(arguments[0], commands[i].name) == 0)
f01009f6:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01009f9:	89 d0                	mov    %edx,%eax
f01009fb:	01 c0                	add    %eax,%eax
f01009fd:	01 d0                	add    %edx,%eax
f01009ff:	c1 e0 02             	shl    $0x2,%eax
f0100a02:	05 40 05 12 f0       	add    $0xf0120540,%eax
f0100a07:	8b 10                	mov    (%eax),%edx
f0100a09:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a0c:	83 ec 08             	sub    $0x8,%esp
f0100a0f:	52                   	push   %edx
f0100a10:	50                   	push   %eax
f0100a11:	e8 6f 56 00 00       	call   f0106085 <strcmp>
f0100a16:	83 c4 10             	add    $0x10,%esp
f0100a19:	85 c0                	test   %eax,%eax
f0100a1b:	75 09                	jne    f0100a26 <execute_command+0x6f>
		{
			command_found = 1;
f0100a1d:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
			break;
f0100a24:	eb 0b                	jmp    f0100a31 <execute_command+0x7a>
		return 0;

	// Lookup in the commands array and execute the command
	int command_found = 0;
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a26:	ff 45 f0             	incl   -0x10(%ebp)
f0100a29:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a2c:	83 f8 11             	cmp    $0x11,%eax
f0100a2f:	76 c5                	jbe    f01009f6 <execute_command+0x3f>
			command_found = 1;
			break;
		}
	}

	if(command_found)
f0100a31:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100a35:	74 2b                	je     f0100a62 <execute_command+0xab>
	{
		int return_value;
		return_value = commands[i].function_to_execute(number_of_arguments, arguments);
f0100a37:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a3a:	89 d0                	mov    %edx,%eax
f0100a3c:	01 c0                	add    %eax,%eax
f0100a3e:	01 d0                	add    %edx,%eax
f0100a40:	c1 e0 02             	shl    $0x2,%eax
f0100a43:	05 48 05 12 f0       	add    $0xf0120548,%eax
f0100a48:	8b 00                	mov    (%eax),%eax
f0100a4a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a4d:	83 ec 08             	sub    $0x8,%esp
f0100a50:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a53:	51                   	push   %ecx
f0100a54:	52                   	push   %edx
f0100a55:	ff d0                	call   *%eax
f0100a57:	83 c4 10             	add    $0x10,%esp
f0100a5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
		return return_value;
f0100a5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a60:	eb 19                	jmp    f0100a7b <execute_command+0xc4>
	}
	else
	{
		//if not found, then it's unknown command
		cprintf("Unknown command '%s'\n", arguments[0]);
f0100a62:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a65:	83 ec 08             	sub    $0x8,%esp
f0100a68:	50                   	push   %eax
f0100a69:	68 18 6d 10 f0       	push   $0xf0106d18
f0100a6e:	e8 12 40 00 00       	call   f0104a85 <cprintf>
f0100a73:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100a76:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0100a7b:	c9                   	leave  
f0100a7c:	c3                   	ret    

f0100a7d <command_help>:
/***************************************/
/*DON'T change the following functions*/
/***************************************/
//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
f0100a7d:	55                   	push   %ebp
f0100a7e:	89 e5                	mov    %esp,%ebp
f0100a80:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100a8a:	eb 3b                	jmp    f0100ac7 <command_help+0x4a>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);
f0100a8c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a8f:	89 d0                	mov    %edx,%eax
f0100a91:	01 c0                	add    %eax,%eax
f0100a93:	01 d0                	add    %edx,%eax
f0100a95:	c1 e0 02             	shl    $0x2,%eax
f0100a98:	05 44 05 12 f0       	add    $0xf0120544,%eax
f0100a9d:	8b 10                	mov    (%eax),%edx
f0100a9f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100aa2:	89 c8                	mov    %ecx,%eax
f0100aa4:	01 c0                	add    %eax,%eax
f0100aa6:	01 c8                	add    %ecx,%eax
f0100aa8:	c1 e0 02             	shl    $0x2,%eax
f0100aab:	05 40 05 12 f0       	add    $0xf0120540,%eax
f0100ab0:	8b 00                	mov    (%eax),%eax
f0100ab2:	83 ec 04             	sub    $0x4,%esp
f0100ab5:	52                   	push   %edx
f0100ab6:	50                   	push   %eax
f0100ab7:	68 2e 6d 10 f0       	push   $0xf0106d2e
f0100abc:	e8 c4 3f 00 00       	call   f0104a85 <cprintf>
f0100ac1:	83 c4 10             	add    $0x10,%esp
/***************************************/
//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100ac4:	ff 45 f4             	incl   -0xc(%ebp)
f0100ac7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aca:	83 f8 11             	cmp    $0x11,%eax
f0100acd:	76 bd                	jbe    f0100a8c <command_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);

	cprintf("-------------------\n");
f0100acf:	83 ec 0c             	sub    $0xc,%esp
f0100ad2:	68 37 6d 10 f0       	push   $0xf0106d37
f0100ad7:	e8 a9 3f 00 00       	call   f0104a85 <cprintf>
f0100adc:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100adf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ae4:	c9                   	leave  
f0100ae5:	c3                   	ret    

f0100ae6 <command_kernel_info>:

/*DON'T change this function*/
//print information about kernel addresses and kernel size
int command_kernel_info(int number_of_arguments, char **arguments )
{
f0100ae6:	55                   	push   %ebp
f0100ae7:	89 e5                	mov    %esp,%ebp
f0100ae9:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_kernel[], end_of_kernel_code_section[], start_of_uninitialized_data_section[], end_of_kernel[];

	cprintf("Special kernel symbols:\n");
f0100aec:	83 ec 0c             	sub    $0xc,%esp
f0100aef:	68 4c 6d 10 f0       	push   $0xf0106d4c
f0100af4:	e8 8c 3f 00 00       	call   f0104a85 <cprintf>
f0100af9:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
f0100afc:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100b01:	83 ec 04             	sub    $0x4,%esp
f0100b04:	50                   	push   %eax
f0100b05:	68 0c 00 10 f0       	push   $0xf010000c
f0100b0a:	68 68 6d 10 f0       	push   $0xf0106d68
f0100b0f:	e8 71 3f 00 00       	call   f0104a85 <cprintf>
f0100b14:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
f0100b17:	b8 55 67 10 00       	mov    $0x106755,%eax
f0100b1c:	83 ec 04             	sub    $0x4,%esp
f0100b1f:	50                   	push   %eax
f0100b20:	68 55 67 10 f0       	push   $0xf0106755
f0100b25:	68 a4 6d 10 f0       	push   $0xf0106da4
f0100b2a:	e8 56 3f 00 00       	call   f0104a85 <cprintf>
f0100b2f:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
f0100b32:	b8 b2 2c 15 00       	mov    $0x152cb2,%eax
f0100b37:	83 ec 04             	sub    $0x4,%esp
f0100b3a:	50                   	push   %eax
f0100b3b:	68 b2 2c 15 f0       	push   $0xf0152cb2
f0100b40:	68 e0 6d 10 f0       	push   $0xf0106de0
f0100b45:	e8 3b 3f 00 00       	call   f0104a85 <cprintf>
f0100b4a:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
f0100b4d:	b8 5c 44 15 00       	mov    $0x15445c,%eax
f0100b52:	83 ec 04             	sub    $0x4,%esp
f0100b55:	50                   	push   %eax
f0100b56:	68 5c 44 15 f0       	push   $0xf015445c
f0100b5b:	68 28 6e 10 f0       	push   $0xf0106e28
f0100b60:	e8 20 3f 00 00       	call   f0104a85 <cprintf>
f0100b65:	83 c4 10             	add    $0x10,%esp
	cprintf("Kernel executable memory footprint: %d KB\n",
			(end_of_kernel-start_of_kernel+1023)/1024);
f0100b68:	b8 5c 44 15 f0       	mov    $0xf015445c,%eax
f0100b6d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100b73:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100b78:	29 c2                	sub    %eax,%edx
f0100b7a:	89 d0                	mov    %edx,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
	cprintf("Kernel executable memory footprint: %d KB\n",
f0100b7c:	85 c0                	test   %eax,%eax
f0100b7e:	79 05                	jns    f0100b85 <command_kernel_info+0x9f>
f0100b80:	05 ff 03 00 00       	add    $0x3ff,%eax
f0100b85:	c1 f8 0a             	sar    $0xa,%eax
f0100b88:	83 ec 08             	sub    $0x8,%esp
f0100b8b:	50                   	push   %eax
f0100b8c:	68 64 6e 10 f0       	push   $0xf0106e64
f0100b91:	e8 ef 3e 00 00       	call   f0104a85 <cprintf>
f0100b96:	83 c4 10             	add    $0x10,%esp
			(end_of_kernel-start_of_kernel+1023)/1024);
	return 0;
f0100b99:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b9e:	c9                   	leave  
f0100b9f:	c3                   	ret    

f0100ba0 <command_readmem>:


/*DON'T change this function*/
int command_readmem(int number_of_arguments, char **arguments)
{
f0100ba0:	55                   	push   %ebp
f0100ba1:	89 e5                	mov    %esp,%ebp
f0100ba3:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100ba6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ba9:	83 c0 04             	add    $0x4,%eax
f0100bac:	8b 00                	mov    (%eax),%eax
f0100bae:	83 ec 04             	sub    $0x4,%esp
f0100bb1:	6a 10                	push   $0x10
f0100bb3:	6a 00                	push   $0x0
f0100bb5:	50                   	push   %eax
f0100bb6:	e8 1e 57 00 00       	call   f01062d9 <strtol>
f0100bbb:	83 c4 10             	add    $0x10,%esp
f0100bbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address ) ;
f0100bc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100bc4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	cprintf("value at address %x = %c\n", ptr, *ptr);
f0100bc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bca:	8a 00                	mov    (%eax),%al
f0100bcc:	0f b6 c0             	movzbl %al,%eax
f0100bcf:	83 ec 04             	sub    $0x4,%esp
f0100bd2:	50                   	push   %eax
f0100bd3:	ff 75 f0             	pushl  -0x10(%ebp)
f0100bd6:	68 8f 6e 10 f0       	push   $0xf0106e8f
f0100bdb:	e8 a5 3e 00 00       	call   f0104a85 <cprintf>
f0100be0:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100be3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100be8:	c9                   	leave  
f0100be9:	c3                   	ret    

f0100bea <command_writemem>:

/*DON'T change this function*/
int command_writemem(int number_of_arguments, char **arguments)
{
f0100bea:	55                   	push   %ebp
f0100beb:	89 e5                	mov    %esp,%ebp
f0100bed:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bf3:	83 c0 04             	add    $0x4,%eax
f0100bf6:	8b 00                	mov    (%eax),%eax
f0100bf8:	83 ec 04             	sub    $0x4,%esp
f0100bfb:	6a 10                	push   $0x10
f0100bfd:	6a 00                	push   $0x0
f0100bff:	50                   	push   %eax
f0100c00:	e8 d4 56 00 00       	call   f01062d9 <strtol>
f0100c05:	83 c4 10             	add    $0x10,%esp
f0100c08:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address) ;
f0100c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c0e:	89 45 f0             	mov    %eax,-0x10(%ebp)

	*ptr = arguments[2][0];
f0100c11:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c14:	83 c0 08             	add    $0x8,%eax
f0100c17:	8b 00                	mov    (%eax),%eax
f0100c19:	8a 00                	mov    (%eax),%al
f0100c1b:	88 c2                	mov    %al,%dl
f0100c1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c20:	88 10                	mov    %dl,(%eax)

	return 0;
f0100c22:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c27:	c9                   	leave  
f0100c28:	c3                   	ret    

f0100c29 <command_meminfo>:

/*DON'T change this function*/
int command_meminfo(int number_of_arguments, char **arguments)
{
f0100c29:	55                   	push   %ebp
f0100c2a:	89 e5                	mov    %esp,%ebp
f0100c2c:	83 ec 08             	sub    $0x8,%esp
	cprintf("Free frames = %d\n", calculate_free_frames());
f0100c2f:	e8 61 35 00 00       	call   f0104195 <calculate_free_frames>
f0100c34:	83 ec 08             	sub    $0x8,%esp
f0100c37:	50                   	push   %eax
f0100c38:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0100c3d:	e8 43 3e 00 00       	call   f0104a85 <cprintf>
f0100c42:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c45:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c4a:	c9                   	leave  
f0100c4b:	c3                   	ret    

f0100c4c <command_ver>:
//===========================================================================
//Lab1 Examples
//=============
/*DON'T change this function*/
int command_ver(int number_of_arguments, char **arguments)
{
f0100c4c:	55                   	push   %ebp
f0100c4d:	89 e5                	mov    %esp,%ebp
f0100c4f:	83 ec 08             	sub    $0x8,%esp
	cprintf("FOS version 0.1\n") ;
f0100c52:	83 ec 0c             	sub    $0xc,%esp
f0100c55:	68 bb 6e 10 f0       	push   $0xf0106ebb
f0100c5a:	e8 26 3e 00 00       	call   f0104a85 <cprintf>
f0100c5f:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c62:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c67:	c9                   	leave  
f0100c68:	c3                   	ret    

f0100c69 <command_add>:

/*DON'T change this function*/
int command_add(int number_of_arguments, char **arguments)
{
f0100c69:	55                   	push   %ebp
f0100c6a:	89 e5                	mov    %esp,%ebp
f0100c6c:	83 ec 18             	sub    $0x18,%esp
	int n1 = strtol(arguments[1], NULL, 10);
f0100c6f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c72:	83 c0 04             	add    $0x4,%eax
f0100c75:	8b 00                	mov    (%eax),%eax
f0100c77:	83 ec 04             	sub    $0x4,%esp
f0100c7a:	6a 0a                	push   $0xa
f0100c7c:	6a 00                	push   $0x0
f0100c7e:	50                   	push   %eax
f0100c7f:	e8 55 56 00 00       	call   f01062d9 <strtol>
f0100c84:	83 c4 10             	add    $0x10,%esp
f0100c87:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int n2 = strtol(arguments[2], NULL, 10);
f0100c8a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c8d:	83 c0 08             	add    $0x8,%eax
f0100c90:	8b 00                	mov    (%eax),%eax
f0100c92:	83 ec 04             	sub    $0x4,%esp
f0100c95:	6a 0a                	push   $0xa
f0100c97:	6a 00                	push   $0x0
f0100c99:	50                   	push   %eax
f0100c9a:	e8 3a 56 00 00       	call   f01062d9 <strtol>
f0100c9f:	83 c4 10             	add    $0x10,%esp
f0100ca2:	89 45 f0             	mov    %eax,-0x10(%ebp)

	int res = n1 + n2 ;
f0100ca5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100ca8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cab:	01 d0                	add    %edx,%eax
f0100cad:	89 45 ec             	mov    %eax,-0x14(%ebp)
	cprintf("res=%d\n", res);
f0100cb0:	83 ec 08             	sub    $0x8,%esp
f0100cb3:	ff 75 ec             	pushl  -0x14(%ebp)
f0100cb6:	68 cc 6e 10 f0       	push   $0xf0106ecc
f0100cbb:	e8 c5 3d 00 00       	call   f0104a85 <cprintf>
f0100cc0:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100cc3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cc8:	c9                   	leave  
f0100cc9:	c3                   	ret    

f0100cca <command_cnia>:
int arraysCnt = 0;
int* lastArrAddress = (int*)0xF1000000;

/*DON'T change this function*/
int command_cnia(int number_of_arguments, char **arguments )
{
f0100cca:	55                   	push   %ebp
f0100ccb:	89 e5                	mov    %esp,%ebp
f0100ccd:	83 ec 08             	sub    $0x8,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CreateIntArray() FUNCTION
	CreateIntArray(number_of_arguments, arguments);
f0100cd0:	83 ec 08             	sub    $0x8,%esp
f0100cd3:	ff 75 0c             	pushl  0xc(%ebp)
f0100cd6:	ff 75 08             	pushl  0x8(%ebp)
f0100cd9:	e8 0a 00 00 00       	call   f0100ce8 <CreateIntArray>
f0100cde:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100ce1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ce6:	c9                   	leave  
f0100ce7:	c3                   	ret    

f0100ce8 <CreateIntArray>:
/*---------------------------------------------------------*/
int* CreateIntArray(int numOfArgs, char** arguments)
{
f0100ce8:	55                   	push   %ebp
f0100ce9:	89 e5                	mov    %esp,%ebp
f0100ceb:	53                   	push   %ebx
f0100cec:	83 ec 14             	sub    $0x14,%esp
	//put your logic here
	//...
	int curArrInd = arraysCnt;
f0100cef:	a1 0c 2f 15 f0       	mov    0xf0152f0c,%eax
f0100cf4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	strcpy(allArrays[curArrInd].name, arguments[1]);
f0100cf7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cfa:	83 c0 04             	add    $0x4,%eax
f0100cfd:	8b 10                	mov    (%eax),%edx
f0100cff:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100d02:	89 c8                	mov    %ecx,%eax
f0100d04:	01 c0                	add    %eax,%eax
f0100d06:	01 c8                	add    %ecx,%eax
f0100d08:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100d0f:	01 c8                	add    %ecx,%eax
f0100d11:	c1 e0 02             	shl    $0x2,%eax
f0100d14:	05 a0 37 15 f0       	add    $0xf01537a0,%eax
f0100d19:	83 ec 08             	sub    $0x8,%esp
f0100d1c:	52                   	push   %edx
f0100d1d:	50                   	push   %eax
f0100d1e:	e8 a5 52 00 00       	call   f0105fc8 <strcpy>
f0100d23:	83 c4 10             	add    $0x10,%esp
	allArrays[curArrInd].startAddress = lastArrAddress ;
f0100d26:	8b 15 1c 06 12 f0    	mov    0xf012061c,%edx
f0100d2c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100d2f:	89 c8                	mov    %ecx,%eax
f0100d31:	01 c0                	add    %eax,%eax
f0100d33:	01 c8                	add    %ecx,%eax
f0100d35:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100d3c:	01 c8                	add    %ecx,%eax
f0100d3e:	c1 e0 02             	shl    $0x2,%eax
f0100d41:	05 04 38 15 f0       	add    $0xf0153804,%eax
f0100d46:	89 10                	mov    %edx,(%eax)
	allArrays[curArrInd].size = strtol(arguments[2], NULL, 10);
f0100d48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d4b:	83 c0 08             	add    $0x8,%eax
f0100d4e:	8b 00                	mov    (%eax),%eax
f0100d50:	83 ec 04             	sub    $0x4,%esp
f0100d53:	6a 0a                	push   $0xa
f0100d55:	6a 00                	push   $0x0
f0100d57:	50                   	push   %eax
f0100d58:	e8 7c 55 00 00       	call   f01062d9 <strtol>
f0100d5d:	83 c4 10             	add    $0x10,%esp
f0100d60:	89 c2                	mov    %eax,%edx
f0100d62:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100d65:	89 c8                	mov    %ecx,%eax
f0100d67:	01 c0                	add    %eax,%eax
f0100d69:	01 c8                	add    %ecx,%eax
f0100d6b:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100d72:	01 c8                	add    %ecx,%eax
f0100d74:	c1 e0 02             	shl    $0x2,%eax
f0100d77:	05 08 38 15 f0       	add    $0xf0153808,%eax
f0100d7c:	89 10                	mov    %edx,(%eax)
	int i ;
	for (i = 0 ; i < numOfArgs - 3; i++)
f0100d7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100d85:	eb 4e                	jmp    f0100dd5 <CreateIntArray+0xed>
	{
		allArrays[curArrInd].startAddress[i] = strtol(arguments[3+i], NULL, 10) ;
f0100d87:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d8a:	89 d0                	mov    %edx,%eax
f0100d8c:	01 c0                	add    %eax,%eax
f0100d8e:	01 d0                	add    %edx,%eax
f0100d90:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d97:	01 d0                	add    %edx,%eax
f0100d99:	c1 e0 02             	shl    $0x2,%eax
f0100d9c:	05 04 38 15 f0       	add    $0xf0153804,%eax
f0100da1:	8b 00                	mov    (%eax),%eax
f0100da3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100da6:	c1 e2 02             	shl    $0x2,%edx
f0100da9:	8d 1c 10             	lea    (%eax,%edx,1),%ebx
f0100dac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100daf:	83 c0 03             	add    $0x3,%eax
f0100db2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0100db9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dbc:	01 d0                	add    %edx,%eax
f0100dbe:	8b 00                	mov    (%eax),%eax
f0100dc0:	83 ec 04             	sub    $0x4,%esp
f0100dc3:	6a 0a                	push   $0xa
f0100dc5:	6a 00                	push   $0x0
f0100dc7:	50                   	push   %eax
f0100dc8:	e8 0c 55 00 00       	call   f01062d9 <strtol>
f0100dcd:	83 c4 10             	add    $0x10,%esp
f0100dd0:	89 03                	mov    %eax,(%ebx)

	strcpy(allArrays[curArrInd].name, arguments[1]);
	allArrays[curArrInd].startAddress = lastArrAddress ;
	allArrays[curArrInd].size = strtol(arguments[2], NULL, 10);
	int i ;
	for (i = 0 ; i < numOfArgs - 3; i++)
f0100dd2:	ff 45 f4             	incl   -0xc(%ebp)
f0100dd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dd8:	83 e8 03             	sub    $0x3,%eax
f0100ddb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0100dde:	7f a7                	jg     f0100d87 <CreateIntArray+0x9f>
	{
		allArrays[curArrInd].startAddress[i] = strtol(arguments[3+i], NULL, 10) ;
	}
	for (i = numOfArgs - 3 ; i < allArrays[curArrInd].size ; i++)
f0100de0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100de3:	83 e8 03             	sub    $0x3,%eax
f0100de6:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100de9:	eb 2d                	jmp    f0100e18 <CreateIntArray+0x130>
	{
		allArrays[curArrInd].startAddress[i] = 0 ;
f0100deb:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100dee:	89 d0                	mov    %edx,%eax
f0100df0:	01 c0                	add    %eax,%eax
f0100df2:	01 d0                	add    %edx,%eax
f0100df4:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100dfb:	01 d0                	add    %edx,%eax
f0100dfd:	c1 e0 02             	shl    $0x2,%eax
f0100e00:	05 04 38 15 f0       	add    $0xf0153804,%eax
f0100e05:	8b 00                	mov    (%eax),%eax
f0100e07:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100e0a:	c1 e2 02             	shl    $0x2,%edx
f0100e0d:	01 d0                	add    %edx,%eax
f0100e0f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	int i ;
	for (i = 0 ; i < numOfArgs - 3; i++)
	{
		allArrays[curArrInd].startAddress[i] = strtol(arguments[3+i], NULL, 10) ;
	}
	for (i = numOfArgs - 3 ; i < allArrays[curArrInd].size ; i++)
f0100e15:	ff 45 f4             	incl   -0xc(%ebp)
f0100e18:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100e1b:	89 d0                	mov    %edx,%eax
f0100e1d:	01 c0                	add    %eax,%eax
f0100e1f:	01 d0                	add    %edx,%eax
f0100e21:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100e28:	01 d0                	add    %edx,%eax
f0100e2a:	c1 e0 02             	shl    $0x2,%eax
f0100e2d:	05 08 38 15 f0       	add    $0xf0153808,%eax
f0100e32:	8b 00                	mov    (%eax),%eax
f0100e34:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0100e37:	7f b2                	jg     f0100deb <CreateIntArray+0x103>
	{
		allArrays[curArrInd].startAddress[i] = 0 ;
	}
	arraysCnt++;
f0100e39:	a1 0c 2f 15 f0       	mov    0xf0152f0c,%eax
f0100e3e:	40                   	inc    %eax
f0100e3f:	a3 0c 2f 15 f0       	mov    %eax,0xf0152f0c
	lastArrAddress += allArrays[curArrInd].size;
f0100e44:	8b 0d 1c 06 12 f0    	mov    0xf012061c,%ecx
f0100e4a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100e4d:	89 d0                	mov    %edx,%eax
f0100e4f:	01 c0                	add    %eax,%eax
f0100e51:	01 d0                	add    %edx,%eax
f0100e53:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100e5a:	01 d0                	add    %edx,%eax
f0100e5c:	c1 e0 02             	shl    $0x2,%eax
f0100e5f:	05 08 38 15 f0       	add    $0xf0153808,%eax
f0100e64:	8b 00                	mov    (%eax),%eax
f0100e66:	c1 e0 02             	shl    $0x2,%eax
f0100e69:	01 c8                	add    %ecx,%eax
f0100e6b:	a3 1c 06 12 f0       	mov    %eax,0xf012061c

	return allArrays[curArrInd].startAddress ;
f0100e70:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100e73:	89 d0                	mov    %edx,%eax
f0100e75:	01 c0                	add    %eax,%eax
f0100e77:	01 d0                	add    %edx,%eax
f0100e79:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100e80:	01 d0                	add    %edx,%eax
f0100e82:	c1 e0 02             	shl    $0x2,%eax
f0100e85:	05 04 38 15 f0       	add    $0xf0153804,%eax
f0100e8a:	8b 00                	mov    (%eax),%eax
}
f0100e8c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e8f:	c9                   	leave  
f0100e90:	c3                   	ret    

f0100e91 <command_show_mapping>:

//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int number_of_arguments, char **arguments)
{
f0100e91:	55                   	push   %ebp
f0100e92:	89 e5                	mov    %esp,%ebp
f0100e94:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100e97:	83 ec 04             	sub    $0x4,%esp
f0100e9a:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100e9f:	68 47 01 00 00       	push   $0x147
f0100ea4:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100ea9:	e8 80 f2 ff ff       	call   f010012e <_panic>

f0100eae <command_set_permission>:

	return 0 ;
}

int command_set_permission(int number_of_arguments, char **arguments)
{
f0100eae:	55                   	push   %ebp
f0100eaf:	89 e5                	mov    %esp,%ebp
f0100eb1:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100eb4:	83 ec 04             	sub    $0x4,%esp
f0100eb7:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100ebc:	68 50 01 00 00       	push   $0x150
f0100ec1:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100ec6:	e8 63 f2 ff ff       	call   f010012e <_panic>

f0100ecb <command_share_range>:

	return 0 ;
}

int command_share_range(int number_of_arguments, char **arguments)
{
f0100ecb:	55                   	push   %ebp
f0100ecc:	89 e5                	mov    %esp,%ebp
f0100ece:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100ed1:	83 ec 04             	sub    $0x4,%esp
f0100ed4:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100ed9:	68 59 01 00 00       	push   $0x159
f0100ede:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100ee3:	e8 46 f2 ff ff       	call   f010012e <_panic>

f0100ee8 <command_nr>:
//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
f0100ee8:	55                   	push   %ebp
f0100ee9:	89 e5                	mov    %esp,%ebp
f0100eeb:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100eee:	83 ec 04             	sub    $0x4,%esp
f0100ef1:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100ef6:	68 66 01 00 00       	push   $0x166
f0100efb:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100f00:	e8 29 f2 ff ff       	call   f010012e <_panic>

f0100f05 <command_ap>:
	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
f0100f05:	55                   	push   %ebp
f0100f06:	89 e5                	mov    %esp,%ebp
f0100f08:	83 ec 18             	sub    $0x18,%esp
	//Comment the following line
	//panic("Function is not implemented yet!");
	uint32 va = strtol(arguments[1], NULL, 16);
f0100f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0e:	83 c0 04             	add    $0x4,%eax
f0100f11:	8b 00                	mov    (%eax),%eax
f0100f13:	83 ec 04             	sub    $0x4,%esp
f0100f16:	6a 10                	push   $0x10
f0100f18:	6a 00                	push   $0x0
f0100f1a:	50                   	push   %eax
f0100f1b:	e8 b9 53 00 00       	call   f01062d9 <strtol>
f0100f20:	83 c4 10             	add    $0x10,%esp
f0100f23:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Frame_Info* ptr_frame_info;
	int ret = allocate_frame(&ptr_frame_info) ;
f0100f26:	83 ec 0c             	sub    $0xc,%esp
f0100f29:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0100f2c:	50                   	push   %eax
f0100f2d:	e8 9e 2e 00 00       	call   f0103dd0 <allocate_frame>
f0100f32:	83 c4 10             	add    $0x10,%esp
f0100f35:	89 45 f0             	mov    %eax,-0x10(%ebp)
	map_frame(ptr_page_directory, ptr_frame_info, (void*)va, 3);
f0100f38:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100f3b:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100f3e:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0100f43:	6a 03                	push   $0x3
f0100f45:	51                   	push   %ecx
f0100f46:	52                   	push   %edx
f0100f47:	50                   	push   %eax
f0100f48:	e8 90 30 00 00       	call   f0103fdd <map_frame>
f0100f4d:	83 c4 10             	add    $0x10,%esp

	return 0 ;
f0100f50:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f55:	c9                   	leave  
f0100f56:	c3                   	ret    

f0100f57 <command_fp>:

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
f0100f57:	55                   	push   %ebp
f0100f58:	89 e5                	mov    %esp,%ebp
f0100f5a:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100f5d:	83 ec 04             	sub    $0x4,%esp
f0100f60:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100f65:	68 7d 01 00 00       	push   $0x17d
f0100f6a:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100f6f:	e8 ba f1 ff ff       	call   f010012e <_panic>

f0100f74 <command_asp>:
//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
f0100f74:	55                   	push   %ebp
f0100f75:	89 e5                	mov    %esp,%ebp
f0100f77:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100f7a:	83 ec 04             	sub    $0x4,%esp
f0100f7d:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0100f82:	68 8a 01 00 00       	push   $0x18a
f0100f87:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0100f8c:	e8 9d f1 ff ff       	call   f010012e <_panic>

f0100f91 <command_ft>:
}



int command_ft(int number_of_arguments, char **arguments)
{
f0100f91:	55                   	push   %ebp
f0100f92:	89 e5                	mov    %esp,%ebp
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
f0100f94:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f99:	5d                   	pop    %ebp
f0100f9a:	c3                   	ret    

f0100f9b <command_cav>:
//========================================================
//Q1:Calculate Array Variance	(2 MARKS)
//========================================================
/*DON'T change this function*/
int command_cav(int number_of_arguments, char **arguments )
{
f0100f9b:	55                   	push   %ebp
f0100f9c:	89 e5                	mov    %esp,%ebp
f0100f9e:	83 ec 18             	sub    $0x18,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CalcArrVar() FUNCTION
	int var = CalcArrVar(arguments);
f0100fa1:	83 ec 0c             	sub    $0xc,%esp
f0100fa4:	ff 75 0c             	pushl  0xc(%ebp)
f0100fa7:	e8 29 00 00 00       	call   f0100fd5 <CalcArrVar>
f0100fac:	83 c4 10             	add    $0x10,%esp
f0100faf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("variance of %s = %d\n", arguments[1], var);
f0100fb2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb5:	83 c0 04             	add    $0x4,%eax
f0100fb8:	8b 00                	mov    (%eax),%eax
f0100fba:	83 ec 04             	sub    $0x4,%esp
f0100fbd:	ff 75 f4             	pushl  -0xc(%ebp)
f0100fc0:	50                   	push   %eax
f0100fc1:	68 0b 6f 10 f0       	push   $0xf0106f0b
f0100fc6:	e8 ba 3a 00 00       	call   f0104a85 <cprintf>
f0100fcb:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100fce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fd3:	c9                   	leave  
f0100fd4:	c3                   	ret    

f0100fd5 <CalcArrVar>:

/*FILL this function
 * arguments[1]: array name
 */
int CalcArrVar(char** arguments)
{
f0100fd5:	55                   	push   %ebp
f0100fd6:	89 e5                	mov    %esp,%ebp
f0100fd8:	83 ec 28             	sub    $0x28,%esp
	//...
	//Comment the following line first
	//panic("The function is not implemented yet");

	// Find the array
	char *arrName = arguments[1];
f0100fdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fde:	8b 40 04             	mov    0x4(%eax),%eax
f0100fe1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int arrIndex = -1;
f0100fe4:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
	for (int i = 0; i < arraysCnt; i++)
f0100feb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100ff2:	eb 36                	jmp    f010102a <CalcArrVar+0x55>
		if (strcmp(arrName, allArrays[i].name) == 0)
f0100ff4:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100ff7:	89 d0                	mov    %edx,%eax
f0100ff9:	01 c0                	add    %eax,%eax
f0100ffb:	01 d0                	add    %edx,%eax
f0100ffd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0101004:	01 d0                	add    %edx,%eax
f0101006:	c1 e0 02             	shl    $0x2,%eax
f0101009:	05 a0 37 15 f0       	add    $0xf01537a0,%eax
f010100e:	83 ec 08             	sub    $0x8,%esp
f0101011:	50                   	push   %eax
f0101012:	ff 75 e0             	pushl  -0x20(%ebp)
f0101015:	e8 6b 50 00 00       	call   f0106085 <strcmp>
f010101a:	83 c4 10             	add    $0x10,%esp
f010101d:	85 c0                	test   %eax,%eax
f010101f:	75 06                	jne    f0101027 <CalcArrVar+0x52>
			arrIndex = i;
f0101021:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101024:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//panic("The function is not implemented yet");

	// Find the array
	char *arrName = arguments[1];
	int arrIndex = -1;
	for (int i = 0; i < arraysCnt; i++)
f0101027:	ff 45 f0             	incl   -0x10(%ebp)
f010102a:	a1 0c 2f 15 f0       	mov    0xf0152f0c,%eax
f010102f:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101032:	7c c0                	jl     f0100ff4 <CalcArrVar+0x1f>
		if (strcmp(arrName, allArrays[i].name) == 0)
			arrIndex = i;
	if (arrIndex == -1) {
f0101034:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f0101038:	75 1d                	jne    f0101057 <CalcArrVar+0x82>
		cprintf("There is no such array named \"%s\"\n", arrName);
f010103a:	83 ec 08             	sub    $0x8,%esp
f010103d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101040:	68 20 6f 10 f0       	push   $0xf0106f20
f0101045:	e8 3b 3a 00 00       	call   f0104a85 <cprintf>
f010104a:	83 c4 10             	add    $0x10,%esp
		return (-1);
f010104d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101052:	e9 c1 00 00 00       	jmp    f0101118 <CalcArrVar+0x143>
	}
	struct ArrayInfo *arr = &allArrays[arrIndex];
f0101057:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010105a:	89 d0                	mov    %edx,%eax
f010105c:	01 c0                	add    %eax,%eax
f010105e:	01 d0                	add    %edx,%eax
f0101060:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0101067:	01 d0                	add    %edx,%eax
f0101069:	c1 e0 02             	shl    $0x2,%eax
f010106c:	05 a0 37 15 f0       	add    $0xf01537a0,%eax
f0101071:	89 45 dc             	mov    %eax,-0x24(%ebp)

	// Calculate mean
	uint32 sum = 0;
f0101074:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	for (int i = 0; i < arr->size; i++) {
f010107b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f0101082:	eb 16                	jmp    f010109a <CalcArrVar+0xc5>
		sum += arr->startAddress[i];
f0101084:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101087:	8b 40 64             	mov    0x64(%eax),%eax
f010108a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010108d:	c1 e2 02             	shl    $0x2,%edx
f0101090:	01 d0                	add    %edx,%eax
f0101092:	8b 00                	mov    (%eax),%eax
f0101094:	01 45 ec             	add    %eax,-0x14(%ebp)
	}
	struct ArrayInfo *arr = &allArrays[arrIndex];

	// Calculate mean
	uint32 sum = 0;
	for (int i = 0; i < arr->size; i++) {
f0101097:	ff 45 e8             	incl   -0x18(%ebp)
f010109a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010109d:	8b 40 68             	mov    0x68(%eax),%eax
f01010a0:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f01010a3:	7f df                	jg     f0101084 <CalcArrVar+0xaf>
		sum += arr->startAddress[i];
	}
	int mean = sum / arr->size;
f01010a5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010a8:	8b 40 68             	mov    0x68(%eax),%eax
f01010ab:	89 c1                	mov    %eax,%ecx
f01010ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01010b0:	ba 00 00 00 00       	mov    $0x0,%edx
f01010b5:	f7 f1                	div    %ecx
f01010b7:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Calculate Variance
	sum = 0;
f01010ba:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	for (int i = 0; i < arr->size; i++)
f01010c1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01010c8:	eb 31                	jmp    f01010fb <CalcArrVar+0x126>
		sum += (arr->startAddress[i] - mean) * (arr->startAddress[i] - mean);
f01010ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010cd:	8b 40 64             	mov    0x64(%eax),%eax
f01010d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010d3:	c1 e2 02             	shl    $0x2,%edx
f01010d6:	01 d0                	add    %edx,%eax
f01010d8:	8b 00                	mov    (%eax),%eax
f01010da:	2b 45 d8             	sub    -0x28(%ebp),%eax
f01010dd:	89 c2                	mov    %eax,%edx
f01010df:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010e2:	8b 40 64             	mov    0x64(%eax),%eax
f01010e5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010e8:	c1 e1 02             	shl    $0x2,%ecx
f01010eb:	01 c8                	add    %ecx,%eax
f01010ed:	8b 00                	mov    (%eax),%eax
f01010ef:	2b 45 d8             	sub    -0x28(%ebp),%eax
f01010f2:	0f af c2             	imul   %edx,%eax
f01010f5:	01 45 ec             	add    %eax,-0x14(%ebp)
	}
	int mean = sum / arr->size;

	// Calculate Variance
	sum = 0;
	for (int i = 0; i < arr->size; i++)
f01010f8:	ff 45 e4             	incl   -0x1c(%ebp)
f01010fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010fe:	8b 40 68             	mov    0x68(%eax),%eax
f0101101:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0101104:	7f c4                	jg     f01010ca <CalcArrVar+0xf5>
		sum += (arr->startAddress[i] - mean) * (arr->startAddress[i] - mean);
	return (sum / arr->size);
f0101106:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101109:	8b 40 68             	mov    0x68(%eax),%eax
f010110c:	89 c1                	mov    %eax,%ecx
f010110e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101111:	ba 00 00 00 00       	mov    $0x0,%edx
f0101116:	f7 f1                	div    %ecx
}
f0101118:	c9                   	leave  
f0101119:	c3                   	ret    

f010111a <command_cvp>:
//========================================================
//Q2:Connect Virtual Address to Physical Frame  (3 MARKS)
//========================================================
/*DON'T change this function*/
int command_cvp(int number_of_arguments, char **arguments )
{
f010111a:	55                   	push   %ebp
f010111b:	89 e5                	mov    %esp,%ebp
f010111d:	83 ec 18             	sub    $0x18,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE WriteDistinctChars() FUNCTION
	uint32 tableEntry = ConnectVirtualToPhysicalFrame(arguments) ;
f0101120:	83 ec 0c             	sub    $0xc,%esp
f0101123:	ff 75 0c             	pushl  0xc(%ebp)
f0101126:	e8 20 00 00 00       	call   f010114b <ConnectVirtualToPhysicalFrame>
f010112b:	83 c4 10             	add    $0x10,%esp
f010112e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("The table entry after connection = %08x\n", tableEntry);
f0101131:	83 ec 08             	sub    $0x8,%esp
f0101134:	ff 75 f4             	pushl  -0xc(%ebp)
f0101137:	68 44 6f 10 f0       	push   $0xf0106f44
f010113c:	e8 44 39 00 00       	call   f0104a85 <cprintf>
f0101141:	83 c4 10             	add    $0x10,%esp

	return 0;
f0101144:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101149:	c9                   	leave  
f010114a:	c3                   	ret    

f010114b <ConnectVirtualToPhysicalFrame>:
 * arguments[3]: <r/w>: 'r' for read-only permission, 'w' for read/write permission
 * Return:
 * 		page table ENTRY of the <virtual address> after applying the connection
 */
uint32 ConnectVirtualToPhysicalFrame(char** arguments)
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	83 ec 28             	sub    $0x28,%esp
	//...
	//Comment the following line first
	//panic("The function is not implemented yet");

	// Get the entry
	uint32 va = strtol(arguments[1], NULL, 16);
f0101151:	8b 45 08             	mov    0x8(%ebp),%eax
f0101154:	83 c0 04             	add    $0x4,%eax
f0101157:	8b 00                	mov    (%eax),%eax
f0101159:	83 ec 04             	sub    $0x4,%esp
f010115c:	6a 10                	push   $0x10
f010115e:	6a 00                	push   $0x0
f0101160:	50                   	push   %eax
f0101161:	e8 73 51 00 00       	call   f01062d9 <strtol>
f0101166:	83 c4 10             	add    $0x10,%esp
f0101169:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 new_frame_num = strtol(arguments[2], NULL, 10);
f010116c:	8b 45 08             	mov    0x8(%ebp),%eax
f010116f:	83 c0 08             	add    $0x8,%eax
f0101172:	8b 00                	mov    (%eax),%eax
f0101174:	83 ec 04             	sub    $0x4,%esp
f0101177:	6a 0a                	push   $0xa
f0101179:	6a 00                	push   $0x0
f010117b:	50                   	push   %eax
f010117c:	e8 58 51 00 00       	call   f01062d9 <strtol>
f0101181:	83 c4 10             	add    $0x10,%esp
f0101184:	89 45 f0             	mov    %eax,-0x10(%ebp)
	char *mode = arguments[3];
f0101187:	8b 45 08             	mov    0x8(%ebp),%eax
f010118a:	8b 40 0c             	mov    0xc(%eax),%eax
f010118d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *PT;
	if (get_page_table(ptr_page_directory, (void *)va, 1, &PT)) {
f0101190:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101193:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101198:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f010119b:	51                   	push   %ecx
f010119c:	6a 01                	push   $0x1
f010119e:	52                   	push   %edx
f010119f:	50                   	push   %eax
f01011a0:	e8 f3 2c 00 00       	call   f0103e98 <get_page_table>
f01011a5:	83 c4 10             	add    $0x10,%esp
f01011a8:	85 c0                	test   %eax,%eax
f01011aa:	74 1a                	je     f01011c6 <ConnectVirtualToPhysicalFrame+0x7b>
		cprintf("Error in get_page_table()\n");
f01011ac:	83 ec 0c             	sub    $0xc,%esp
f01011af:	68 6d 6f 10 f0       	push   $0xf0106f6d
f01011b4:	e8 cc 38 00 00       	call   f0104a85 <cprintf>
f01011b9:	83 c4 10             	add    $0x10,%esp
		return (1);
f01011bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01011c1:	e9 99 01 00 00       	jmp    f010135f <ConnectVirtualToPhysicalFrame+0x214>
	}

	// Overwrite the frame number
	uint32 old_frame_num = (PT[PTX(va)] >> 12) << 12;
f01011c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011cc:	c1 ea 0c             	shr    $0xc,%edx
f01011cf:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011d5:	c1 e2 02             	shl    $0x2,%edx
f01011d8:	01 d0                	add    %edx,%eax
f01011da:	8b 00                	mov    (%eax),%eax
f01011dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01011e1:	89 45 e8             	mov    %eax,-0x18(%ebp)
	new_frame_num = new_frame_num << 12;
f01011e4:	c1 65 f0 0c          	shll   $0xc,-0x10(%ebp)
	PT[PTX(va)] -= old_frame_num;
f01011e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011ee:	c1 ea 0c             	shr    $0xc,%edx
f01011f1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01011f7:	c1 e2 02             	shl    $0x2,%edx
f01011fa:	01 c2                	add    %eax,%edx
f01011fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011ff:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101202:	c1 e9 0c             	shr    $0xc,%ecx
f0101205:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f010120b:	c1 e1 02             	shl    $0x2,%ecx
f010120e:	01 c8                	add    %ecx,%eax
f0101210:	8b 00                	mov    (%eax),%eax
f0101212:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101215:	89 02                	mov    %eax,(%edx)
	PT[PTX(va)] += new_frame_num;
f0101217:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010121a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010121d:	c1 ea 0c             	shr    $0xc,%edx
f0101220:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101226:	c1 e2 02             	shl    $0x2,%edx
f0101229:	01 d0                	add    %edx,%eax
f010122b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010122e:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101231:	c1 e9 0c             	shr    $0xc,%ecx
f0101234:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f010123a:	c1 e1 02             	shl    $0x2,%ecx
f010123d:	01 ca                	add    %ecx,%edx
f010123f:	8b 0a                	mov    (%edx),%ecx
f0101241:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101244:	01 ca                	add    %ecx,%edx
f0101246:	89 10                	mov    %edx,(%eax)

	// Overwrite the writing permission
	if (strcmp(mode, "w") == 0)// Writable -> Set
f0101248:	83 ec 08             	sub    $0x8,%esp
f010124b:	68 88 6f 10 f0       	push   $0xf0106f88
f0101250:	ff 75 ec             	pushl  -0x14(%ebp)
f0101253:	e8 2d 4e 00 00       	call   f0106085 <strcmp>
f0101258:	83 c4 10             	add    $0x10,%esp
f010125b:	85 c0                	test   %eax,%eax
f010125d:	75 31                	jne    f0101290 <ConnectVirtualToPhysicalFrame+0x145>
		PT[PTX(va)] |= PERM_WRITEABLE;
f010125f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101262:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101265:	c1 ea 0c             	shr    $0xc,%edx
f0101268:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010126e:	c1 e2 02             	shl    $0x2,%edx
f0101271:	01 d0                	add    %edx,%eax
f0101273:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101276:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101279:	c1 e9 0c             	shr    $0xc,%ecx
f010127c:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0101282:	c1 e1 02             	shl    $0x2,%ecx
f0101285:	01 ca                	add    %ecx,%edx
f0101287:	8b 12                	mov    (%edx),%edx
f0101289:	83 ca 02             	or     $0x2,%edx
f010128c:	89 10                	mov    %edx,(%eax)
f010128e:	eb 58                	jmp    f01012e8 <ConnectVirtualToPhysicalFrame+0x19d>
	else if (strcmp(mode, "r") == 0) // Read Only -> not Writable -> Reset
f0101290:	83 ec 08             	sub    $0x8,%esp
f0101293:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101298:	ff 75 ec             	pushl  -0x14(%ebp)
f010129b:	e8 e5 4d 00 00       	call   f0106085 <strcmp>
f01012a0:	83 c4 10             	add    $0x10,%esp
f01012a3:	85 c0                	test   %eax,%eax
f01012a5:	75 31                	jne    f01012d8 <ConnectVirtualToPhysicalFrame+0x18d>
		PT[PTX(va)] &= ~PERM_WRITEABLE;
f01012a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012ad:	c1 ea 0c             	shr    $0xc,%edx
f01012b0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01012b6:	c1 e2 02             	shl    $0x2,%edx
f01012b9:	01 d0                	add    %edx,%eax
f01012bb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012be:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f01012c1:	c1 e9 0c             	shr    $0xc,%ecx
f01012c4:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f01012ca:	c1 e1 02             	shl    $0x2,%ecx
f01012cd:	01 ca                	add    %ecx,%edx
f01012cf:	8b 12                	mov    (%edx),%edx
f01012d1:	83 e2 fd             	and    $0xfffffffd,%edx
f01012d4:	89 10                	mov    %edx,(%eax)
f01012d6:	eb 10                	jmp    f01012e8 <ConnectVirtualToPhysicalFrame+0x19d>
	else
		cprintf("Usage: cvp <virtual address in HEX> <frame num> <r/w>\n");
f01012d8:	83 ec 0c             	sub    $0xc,%esp
f01012db:	68 8c 6f 10 f0       	push   $0xf0106f8c
f01012e0:	e8 a0 37 00 00       	call   f0104a85 <cprintf>
f01012e5:	83 c4 10             	add    $0x10,%esp

	// set present bit
	PT[PTX(va)] = PT[PTX(va)] | PERM_PRESENT;
f01012e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012ee:	c1 ea 0c             	shr    $0xc,%edx
f01012f1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01012f7:	c1 e2 02             	shl    $0x2,%edx
f01012fa:	01 d0                	add    %edx,%eax
f01012fc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012ff:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101302:	c1 e9 0c             	shr    $0xc,%ecx
f0101305:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f010130b:	c1 e1 02             	shl    $0x2,%ecx
f010130e:	01 ca                	add    %ecx,%edx
f0101310:	8b 12                	mov    (%edx),%edx
f0101312:	83 ca 01             	or     $0x1,%edx
f0101315:	89 10                	mov    %edx,(%eax)

	// reset some other bits
	PT[PTX(va)] &= (~PERM_USER & ~PERM_USED & ~(0b111000000000));
f0101317:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010131a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010131d:	c1 ea 0c             	shr    $0xc,%edx
f0101320:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101326:	c1 e2 02             	shl    $0x2,%edx
f0101329:	01 d0                	add    %edx,%eax
f010132b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010132e:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101331:	c1 e9 0c             	shr    $0xc,%ecx
f0101334:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f010133a:	c1 e1 02             	shl    $0x2,%ecx
f010133d:	01 ca                	add    %ecx,%edx
f010133f:	8b 12                	mov    (%edx),%edx
f0101341:	81 e2 db f1 ff ff    	and    $0xfffff1db,%edx
f0101347:	89 10                	mov    %edx,(%eax)

	return (PT[PTX(va)]);
f0101349:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010134c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010134f:	c1 ea 0c             	shr    $0xc,%edx
f0101352:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101358:	c1 e2 02             	shl    $0x2,%edx
f010135b:	01 d0                	add    %edx,%eax
f010135d:	8b 00                	mov    (%eax),%eax
}
f010135f:	c9                   	leave  
f0101360:	c3                   	ret    

f0101361 <command_cmps>:
//Q3) Count modified pages in a virtual range	(2 MARKS)
//========================================================

/*DON'T change this function*/
int command_cmps(int number_of_arguments, char **arguments )
{
f0101361:	55                   	push   %ebp
f0101362:	89 e5                	mov    %esp,%ebp
f0101364:	83 ec 18             	sub    $0x18,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE FindInArray() FUNCTION
	int cnt = CountModifiedPagesInRange(arguments) ;
f0101367:	83 ec 0c             	sub    $0xc,%esp
f010136a:	ff 75 0c             	pushl  0xc(%ebp)
f010136d:	e8 20 00 00 00       	call   f0101392 <CountModifiedPagesInRange>
f0101372:	83 c4 10             	add    $0x10,%esp
f0101375:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("num of modified pages in the given range = %d\n", cnt) ;
f0101378:	83 ec 08             	sub    $0x8,%esp
f010137b:	ff 75 f4             	pushl  -0xc(%ebp)
f010137e:	68 c4 6f 10 f0       	push   $0xf0106fc4
f0101383:	e8 fd 36 00 00       	call   f0104a85 <cprintf>
f0101388:	83 c4 10             	add    $0x10,%esp

	return 0;
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101390:	c9                   	leave  
f0101391:	c3                   	ret    

f0101392 <CountModifiedPagesInRange>:
 * You may need to use PERM_MODIFIED
 * There's a constant in the code called PAGE_SIZE which equal to 4KB
 * You can use ROUNDDOWN and ROUNDUP functions, described below in order to round the virtual addresses on multiple of PAGE_SIZE (4 KB)
 */
int CountModifiedPagesInRange(char** arguments)
{
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	83 ec 28             	sub    $0x28,%esp
	//put your logic here
	//...
	//Comment the following line first
	//panic("The function is not implemented yet");

	uint32 startVA = strtol(arguments[1], NULL, 16);
f0101398:	8b 45 08             	mov    0x8(%ebp),%eax
f010139b:	83 c0 04             	add    $0x4,%eax
f010139e:	8b 00                	mov    (%eax),%eax
f01013a0:	83 ec 04             	sub    $0x4,%esp
f01013a3:	6a 10                	push   $0x10
f01013a5:	6a 00                	push   $0x0
f01013a7:	50                   	push   %eax
f01013a8:	e8 2c 4f 00 00       	call   f01062d9 <strtol>
f01013ad:	83 c4 10             	add    $0x10,%esp
f01013b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	startVA /= PAGE_SIZE;
f01013b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013b6:	c1 e8 0c             	shr    $0xc,%eax
f01013b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	startVA *= PAGE_SIZE;
f01013bc:	c1 65 ec 0c          	shll   $0xc,-0x14(%ebp)

	uint32 endVA = strtol(arguments[2], NULL, 16);
f01013c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c3:	83 c0 08             	add    $0x8,%eax
f01013c6:	8b 00                	mov    (%eax),%eax
f01013c8:	83 ec 04             	sub    $0x4,%esp
f01013cb:	6a 10                	push   $0x10
f01013cd:	6a 00                	push   $0x0
f01013cf:	50                   	push   %eax
f01013d0:	e8 04 4f 00 00       	call   f01062d9 <strtol>
f01013d5:	83 c4 10             	add    $0x10,%esp
f01013d8:	89 45 e8             	mov    %eax,-0x18(%ebp)

	uint32 counter = 0;
f01013db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	uint32 *PT;
	for (uint32 i = startVA; i <= endVA; i += PAGE_SIZE) {
f01013e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01013e8:	eb 3f                	jmp    f0101429 <CountModifiedPagesInRange+0x97>
		get_page_table(ptr_page_directory, (void *)i, 1, &PT);
f01013ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01013ed:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01013f2:	8d 4d e4             	lea    -0x1c(%ebp),%ecx
f01013f5:	51                   	push   %ecx
f01013f6:	6a 01                	push   $0x1
f01013f8:	52                   	push   %edx
f01013f9:	50                   	push   %eax
f01013fa:	e8 99 2a 00 00       	call   f0103e98 <get_page_table>
f01013ff:	83 c4 10             	add    $0x10,%esp
		if ((PT[PTX(i)] & PERM_MODIFIED) > 0) // if modified
f0101402:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101405:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101408:	c1 ea 0c             	shr    $0xc,%edx
f010140b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101411:	c1 e2 02             	shl    $0x2,%edx
f0101414:	01 d0                	add    %edx,%eax
f0101416:	8b 00                	mov    (%eax),%eax
f0101418:	83 e0 40             	and    $0x40,%eax
f010141b:	85 c0                	test   %eax,%eax
f010141d:	74 03                	je     f0101422 <CountModifiedPagesInRange+0x90>
			counter++;
f010141f:	ff 45 f4             	incl   -0xc(%ebp)
	uint32 endVA = strtol(arguments[2], NULL, 16);

	uint32 counter = 0;

	uint32 *PT;
	for (uint32 i = startVA; i <= endVA; i += PAGE_SIZE) {
f0101422:	81 45 f0 00 10 00 00 	addl   $0x1000,-0x10(%ebp)
f0101429:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010142c:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010142f:	76 b9                	jbe    f01013ea <CountModifiedPagesInRange+0x58>
		get_page_table(ptr_page_directory, (void *)i, 1, &PT);
		if ((PT[PTX(i)] & PERM_MODIFIED) > 0) // if modified
			counter++;
	}
	return counter;
f0101431:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0101434:	c9                   	leave  
f0101435:	c3                   	ret    

f0101436 <command_tup>:

//Q4) Transfer User Page	(3 MARKS)
//========================================================
/*DON'T change this function*/
int command_tup(int number_of_arguments, char **arguments )
{
f0101436:	55                   	push   %ebp
f0101437:	89 e5                	mov    %esp,%ebp
f0101439:	83 ec 08             	sub    $0x8,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE TransferUserPage() FUNCTION
	TransferUserPage(arguments);
f010143c:	83 ec 0c             	sub    $0xc,%esp
f010143f:	ff 75 0c             	pushl  0xc(%ebp)
f0101442:	e8 0a 00 00 00       	call   f0101451 <TransferUserPage>
f0101447:	83 c4 10             	add    $0x10,%esp

	return 0;
f010144a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010144f:	c9                   	leave  
f0101450:	c3                   	ret    

f0101451 <TransferUserPage>:
 * arguments[1]: source virtual address in HEX
 * arguments[2]: destination virtual address in HEX
 * arguments[3]: transfer mode (c: copy, m: move)
 */
void TransferUserPage(char** arguments)
{
f0101451:	55                   	push   %ebp
f0101452:	89 e5                	mov    %esp,%ebp
f0101454:	83 ec 08             	sub    $0x8,%esp
	//TODO: Assignment.Q4

	//Comment the following line first
	panic("The function is not implemented yet");
f0101457:	83 ec 04             	sub    $0x4,%esp
f010145a:	68 f4 6f 10 f0       	push   $0xf0106ff4
f010145f:	68 55 02 00 00       	push   $0x255
f0101464:	68 f5 6e 10 f0       	push   $0xf0106ef5
f0101469:	e8 c0 ec ff ff       	call   f010012e <_panic>

f010146e <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f010146e:	55                   	push   %ebp
f010146f:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0101471:	8b 45 08             	mov    0x8(%ebp),%eax
f0101474:	8b 15 4c 44 15 f0    	mov    0xf015444c,%edx
f010147a:	29 d0                	sub    %edx,%eax
f010147c:	c1 f8 02             	sar    $0x2,%eax
f010147f:	89 c2                	mov    %eax,%edx
f0101481:	89 d0                	mov    %edx,%eax
f0101483:	c1 e0 02             	shl    $0x2,%eax
f0101486:	01 d0                	add    %edx,%eax
f0101488:	c1 e0 02             	shl    $0x2,%eax
f010148b:	01 d0                	add    %edx,%eax
f010148d:	c1 e0 02             	shl    $0x2,%eax
f0101490:	01 d0                	add    %edx,%eax
f0101492:	89 c1                	mov    %eax,%ecx
f0101494:	c1 e1 08             	shl    $0x8,%ecx
f0101497:	01 c8                	add    %ecx,%eax
f0101499:	89 c1                	mov    %eax,%ecx
f010149b:	c1 e1 10             	shl    $0x10,%ecx
f010149e:	01 c8                	add    %ecx,%eax
f01014a0:	01 c0                	add    %eax,%eax
f01014a2:	01 d0                	add    %edx,%eax
}
f01014a4:	5d                   	pop    %ebp
f01014a5:	c3                   	ret    

f01014a6 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f01014a6:	55                   	push   %ebp
f01014a7:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f01014a9:	ff 75 08             	pushl  0x8(%ebp)
f01014ac:	e8 bd ff ff ff       	call   f010146e <to_frame_number>
f01014b1:	83 c4 04             	add    $0x4,%esp
f01014b4:	c1 e0 0c             	shl    $0xc,%eax
}
f01014b7:	c9                   	leave  
f01014b8:	c3                   	ret    

f01014b9 <nvram_read>:
{
	sizeof(gdt) - 1, (unsigned long) gdt
};

int nvram_read(int r)
{	
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
f01014bc:	53                   	push   %ebx
f01014bd:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01014c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c3:	83 ec 0c             	sub    $0xc,%esp
f01014c6:	50                   	push   %eax
f01014c7:	e8 04 35 00 00       	call   f01049d0 <mc146818_read>
f01014cc:	83 c4 10             	add    $0x10,%esp
f01014cf:	89 c3                	mov    %eax,%ebx
f01014d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d4:	40                   	inc    %eax
f01014d5:	83 ec 0c             	sub    $0xc,%esp
f01014d8:	50                   	push   %eax
f01014d9:	e8 f2 34 00 00       	call   f01049d0 <mc146818_read>
f01014de:	83 c4 10             	add    $0x10,%esp
f01014e1:	c1 e0 08             	shl    $0x8,%eax
f01014e4:	09 d8                	or     %ebx,%eax
}
f01014e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014e9:	c9                   	leave  
f01014ea:	c3                   	ret    

f01014eb <detect_memory>:
	
void detect_memory()
{
f01014eb:	55                   	push   %ebp
f01014ec:	89 e5                	mov    %esp,%ebp
f01014ee:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	size_of_base_mem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PAGE_SIZE);
f01014f1:	83 ec 0c             	sub    $0xc,%esp
f01014f4:	6a 15                	push   $0x15
f01014f6:	e8 be ff ff ff       	call   f01014b9 <nvram_read>
f01014fb:	83 c4 10             	add    $0x10,%esp
f01014fe:	c1 e0 0a             	shl    $0xa,%eax
f0101501:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101504:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101507:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010150c:	a3 94 37 15 f0       	mov    %eax,0xf0153794
	size_of_extended_mem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PAGE_SIZE);
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	6a 17                	push   $0x17
f0101516:	e8 9e ff ff ff       	call   f01014b9 <nvram_read>
f010151b:	83 c4 10             	add    $0x10,%esp
f010151e:	c1 e0 0a             	shl    $0xa,%eax
f0101521:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101524:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101527:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010152c:	a3 8c 37 15 f0       	mov    %eax,0xf015378c

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (size_of_extended_mem)
f0101531:	a1 8c 37 15 f0       	mov    0xf015378c,%eax
f0101536:	85 c0                	test   %eax,%eax
f0101538:	74 11                	je     f010154b <detect_memory+0x60>
		maxpa = PHYS_EXTENDED_MEM + size_of_extended_mem;
f010153a:	a1 8c 37 15 f0       	mov    0xf015378c,%eax
f010153f:	05 00 00 10 00       	add    $0x100000,%eax
f0101544:	a3 90 37 15 f0       	mov    %eax,0xf0153790
f0101549:	eb 0a                	jmp    f0101555 <detect_memory+0x6a>
	else
		maxpa = size_of_extended_mem;
f010154b:	a1 8c 37 15 f0       	mov    0xf015378c,%eax
f0101550:	a3 90 37 15 f0       	mov    %eax,0xf0153790

	number_of_frames = maxpa / PAGE_SIZE;
f0101555:	a1 90 37 15 f0       	mov    0xf0153790,%eax
f010155a:	c1 e8 0c             	shr    $0xc,%eax
f010155d:	a3 88 37 15 f0       	mov    %eax,0xf0153788

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0101562:	a1 90 37 15 f0       	mov    0xf0153790,%eax
f0101567:	c1 e8 0a             	shr    $0xa,%eax
f010156a:	83 ec 08             	sub    $0x8,%esp
f010156d:	50                   	push   %eax
f010156e:	68 18 70 10 f0       	push   $0xf0107018
f0101573:	e8 0d 35 00 00       	call   f0104a85 <cprintf>
f0101578:	83 c4 10             	add    $0x10,%esp
	cprintf("base = %dK, extended = %dK\n", (int)(size_of_base_mem/1024), (int)(size_of_extended_mem/1024));
f010157b:	a1 8c 37 15 f0       	mov    0xf015378c,%eax
f0101580:	c1 e8 0a             	shr    $0xa,%eax
f0101583:	89 c2                	mov    %eax,%edx
f0101585:	a1 94 37 15 f0       	mov    0xf0153794,%eax
f010158a:	c1 e8 0a             	shr    $0xa,%eax
f010158d:	83 ec 04             	sub    $0x4,%esp
f0101590:	52                   	push   %edx
f0101591:	50                   	push   %eax
f0101592:	68 39 70 10 f0       	push   $0xf0107039
f0101597:	e8 e9 34 00 00       	call   f0104a85 <cprintf>
f010159c:	83 c4 10             	add    $0x10,%esp
}
f010159f:	90                   	nop
f01015a0:	c9                   	leave  
f01015a1:	c3                   	ret    

f01015a2 <check_boot_pgdir>:
// but it is a pretty good check.
//
uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va);

void check_boot_pgdir()
{
f01015a2:	55                   	push   %ebp
f01015a3:	89 e5                	mov    %esp,%ebp
f01015a5:	83 ec 28             	sub    $0x28,%esp
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
f01015a8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01015af:	8b 15 88 37 15 f0    	mov    0xf0153788,%edx
f01015b5:	89 d0                	mov    %edx,%eax
f01015b7:	01 c0                	add    %eax,%eax
f01015b9:	01 d0                	add    %edx,%eax
f01015bb:	c1 e0 02             	shl    $0x2,%eax
f01015be:	89 c2                	mov    %eax,%edx
f01015c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01015c3:	01 d0                	add    %edx,%eax
f01015c5:	48                   	dec    %eax
f01015c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01015c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01015d1:	f7 75 f0             	divl   -0x10(%ebp)
f01015d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015d7:	29 d0                	sub    %edx,%eax
f01015d9:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (i = 0; i < n; i += PAGE_SIZE)
f01015dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01015e3:	eb 71                	jmp    f0101656 <check_boot_pgdir+0xb4>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);
f01015e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015e8:	8d 90 00 00 00 ef    	lea    -0x11000000(%eax),%edx
f01015ee:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01015f3:	83 ec 08             	sub    $0x8,%esp
f01015f6:	52                   	push   %edx
f01015f7:	50                   	push   %eax
f01015f8:	e8 f4 01 00 00       	call   f01017f1 <check_va2pa>
f01015fd:	83 c4 10             	add    $0x10,%esp
f0101600:	89 c2                	mov    %eax,%edx
f0101602:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0101607:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010160a:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0101611:	77 14                	ja     f0101627 <check_boot_pgdir+0x85>
f0101613:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101616:	68 58 70 10 f0       	push   $0xf0107058
f010161b:	6a 5e                	push   $0x5e
f010161d:	68 89 70 10 f0       	push   $0xf0107089
f0101622:	e8 07 eb ff ff       	call   f010012e <_panic>
f0101627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010162a:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0101630:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101633:	01 c8                	add    %ecx,%eax
f0101635:	39 c2                	cmp    %eax,%edx
f0101637:	74 16                	je     f010164f <check_boot_pgdir+0xad>
f0101639:	68 98 70 10 f0       	push   $0xf0107098
f010163e:	68 fa 70 10 f0       	push   $0xf01070fa
f0101643:	6a 5e                	push   $0x5e
f0101645:	68 89 70 10 f0       	push   $0xf0107089
f010164a:	e8 df ea ff ff       	call   f010012e <_panic>
{
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
f010164f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101656:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101659:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010165c:	72 87                	jb     f01015e5 <check_boot_pgdir+0x43>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f010165e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101665:	eb 3d                	jmp    f01016a4 <check_boot_pgdir+0x102>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);
f0101667:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010166a:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0101670:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101675:	83 ec 08             	sub    $0x8,%esp
f0101678:	52                   	push   %edx
f0101679:	50                   	push   %eax
f010167a:	e8 72 01 00 00       	call   f01017f1 <check_va2pa>
f010167f:	83 c4 10             	add    $0x10,%esp
f0101682:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0101685:	74 16                	je     f010169d <check_boot_pgdir+0xfb>
f0101687:	68 10 71 10 f0       	push   $0xf0107110
f010168c:	68 fa 70 10 f0       	push   $0xf01070fa
f0101691:	6a 62                	push   $0x62
f0101693:	68 89 70 10 f0       	push   $0xf0107089
f0101698:	e8 91 ea ff ff       	call   f010012e <_panic>
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f010169d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01016a4:	81 7d f4 00 00 00 10 	cmpl   $0x10000000,-0xc(%ebp)
f01016ab:	75 ba                	jne    f0101667 <check_boot_pgdir+0xc5>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f01016ad:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01016b4:	eb 6e                	jmp    f0101724 <check_boot_pgdir+0x182>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);
f01016b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016b9:	8d 90 00 80 bf ef    	lea    -0x10408000(%eax),%edx
f01016bf:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01016c4:	83 ec 08             	sub    $0x8,%esp
f01016c7:	52                   	push   %edx
f01016c8:	50                   	push   %eax
f01016c9:	e8 23 01 00 00       	call   f01017f1 <check_va2pa>
f01016ce:	83 c4 10             	add    $0x10,%esp
f01016d1:	c7 45 e0 00 80 11 f0 	movl   $0xf0118000,-0x20(%ebp)
f01016d8:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01016df:	77 14                	ja     f01016f5 <check_boot_pgdir+0x153>
f01016e1:	ff 75 e0             	pushl  -0x20(%ebp)
f01016e4:	68 58 70 10 f0       	push   $0xf0107058
f01016e9:	6a 66                	push   $0x66
f01016eb:	68 89 70 10 f0       	push   $0xf0107089
f01016f0:	e8 39 ea ff ff       	call   f010012e <_panic>
f01016f5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01016f8:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f01016fe:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101701:	01 ca                	add    %ecx,%edx
f0101703:	39 d0                	cmp    %edx,%eax
f0101705:	74 16                	je     f010171d <check_boot_pgdir+0x17b>
f0101707:	68 48 71 10 f0       	push   $0xf0107148
f010170c:	68 fa 70 10 f0       	push   $0xf01070fa
f0101711:	6a 66                	push   $0x66
f0101713:	68 89 70 10 f0       	push   $0xf0107089
f0101718:	e8 11 ea ff ff       	call   f010012e <_panic>
	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f010171d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101724:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f010172b:	76 89                	jbe    f01016b6 <check_boot_pgdir+0x114>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f010172d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101734:	e9 98 00 00 00       	jmp    f01017d1 <check_boot_pgdir+0x22f>
		switch (i) {
f0101739:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010173c:	2d bb 03 00 00       	sub    $0x3bb,%eax
f0101741:	83 f8 04             	cmp    $0x4,%eax
f0101744:	77 29                	ja     f010176f <check_boot_pgdir+0x1cd>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
f0101746:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010174b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010174e:	c1 e2 02             	shl    $0x2,%edx
f0101751:	01 d0                	add    %edx,%eax
f0101753:	8b 00                	mov    (%eax),%eax
f0101755:	85 c0                	test   %eax,%eax
f0101757:	75 71                	jne    f01017ca <check_boot_pgdir+0x228>
f0101759:	68 be 71 10 f0       	push   $0xf01071be
f010175e:	68 fa 70 10 f0       	push   $0xf01070fa
f0101763:	6a 70                	push   $0x70
f0101765:	68 89 70 10 f0       	push   $0xf0107089
f010176a:	e8 bf e9 ff ff       	call   f010012e <_panic>
			break;
		default:
			if (i >= PDX(KERNEL_BASE))
f010176f:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f0101776:	76 29                	jbe    f01017a1 <check_boot_pgdir+0x1ff>
				assert(ptr_page_directory[i]);
f0101778:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010177d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101780:	c1 e2 02             	shl    $0x2,%edx
f0101783:	01 d0                	add    %edx,%eax
f0101785:	8b 00                	mov    (%eax),%eax
f0101787:	85 c0                	test   %eax,%eax
f0101789:	75 42                	jne    f01017cd <check_boot_pgdir+0x22b>
f010178b:	68 be 71 10 f0       	push   $0xf01071be
f0101790:	68 fa 70 10 f0       	push   $0xf01070fa
f0101795:	6a 74                	push   $0x74
f0101797:	68 89 70 10 f0       	push   $0xf0107089
f010179c:	e8 8d e9 ff ff       	call   f010012e <_panic>
			else				
				assert(ptr_page_directory[i] == 0);
f01017a1:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01017a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01017a9:	c1 e2 02             	shl    $0x2,%edx
f01017ac:	01 d0                	add    %edx,%eax
f01017ae:	8b 00                	mov    (%eax),%eax
f01017b0:	85 c0                	test   %eax,%eax
f01017b2:	74 19                	je     f01017cd <check_boot_pgdir+0x22b>
f01017b4:	68 d4 71 10 f0       	push   $0xf01071d4
f01017b9:	68 fa 70 10 f0       	push   $0xf01070fa
f01017be:	6a 76                	push   $0x76
f01017c0:	68 89 70 10 f0       	push   $0xf0107089
f01017c5:	e8 64 e9 ff ff       	call   f010012e <_panic>
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
			break;
f01017ca:	90                   	nop
f01017cb:	eb 01                	jmp    f01017ce <check_boot_pgdir+0x22c>
		default:
			if (i >= PDX(KERNEL_BASE))
				assert(ptr_page_directory[i]);
			else				
				assert(ptr_page_directory[i] == 0);
			break;
f01017cd:	90                   	nop
	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01017ce:	ff 45 f4             	incl   -0xc(%ebp)
f01017d1:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f01017d8:	0f 86 5b ff ff ff    	jbe    f0101739 <check_boot_pgdir+0x197>
			else				
				assert(ptr_page_directory[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f01017de:	83 ec 0c             	sub    $0xc,%esp
f01017e1:	68 f0 71 10 f0       	push   $0xf01071f0
f01017e6:	e8 9a 32 00 00       	call   f0104a85 <cprintf>
f01017eb:	83 c4 10             	add    $0x10,%esp
}
f01017ee:	90                   	nop
f01017ef:	c9                   	leave  
f01017f0:	c3                   	ret    

f01017f1 <check_va2pa>:
// defined by the page directory 'ptr_page_directory'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va)
{
f01017f1:	55                   	push   %ebp
f01017f2:	89 e5                	mov    %esp,%ebp
f01017f4:	83 ec 18             	sub    $0x18,%esp
	uint32 *p;

	ptr_page_directory = &ptr_page_directory[PDX(va)];
f01017f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017fa:	c1 e8 16             	shr    $0x16,%eax
f01017fd:	c1 e0 02             	shl    $0x2,%eax
f0101800:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*ptr_page_directory & PERM_PRESENT))
f0101803:	8b 45 08             	mov    0x8(%ebp),%eax
f0101806:	8b 00                	mov    (%eax),%eax
f0101808:	83 e0 01             	and    $0x1,%eax
f010180b:	85 c0                	test   %eax,%eax
f010180d:	75 0a                	jne    f0101819 <check_va2pa+0x28>
		return ~0;
f010180f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101814:	e9 87 00 00 00       	jmp    f01018a0 <check_va2pa+0xaf>
	p = (uint32*) K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(*ptr_page_directory));
f0101819:	8b 45 08             	mov    0x8(%ebp),%eax
f010181c:	8b 00                	mov    (%eax),%eax
f010181e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101823:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101826:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101829:	c1 e8 0c             	shr    $0xc,%eax
f010182c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010182f:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0101834:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101837:	72 17                	jb     f0101850 <check_va2pa+0x5f>
f0101839:	ff 75 f4             	pushl  -0xc(%ebp)
f010183c:	68 10 72 10 f0       	push   $0xf0107210
f0101841:	68 89 00 00 00       	push   $0x89
f0101846:	68 89 70 10 f0       	push   $0xf0107089
f010184b:	e8 de e8 ff ff       	call   f010012e <_panic>
f0101850:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101853:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101858:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PERM_PRESENT))
f010185b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010185e:	c1 e8 0c             	shr    $0xc,%eax
f0101861:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101866:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010186d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101870:	01 d0                	add    %edx,%eax
f0101872:	8b 00                	mov    (%eax),%eax
f0101874:	83 e0 01             	and    $0x1,%eax
f0101877:	85 c0                	test   %eax,%eax
f0101879:	75 07                	jne    f0101882 <check_va2pa+0x91>
		return ~0;
f010187b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101880:	eb 1e                	jmp    f01018a0 <check_va2pa+0xaf>
	return EXTRACT_ADDRESS(p[PTX(va)]);
f0101882:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101885:	c1 e8 0c             	shr    $0xc,%eax
f0101888:	25 ff 03 00 00       	and    $0x3ff,%eax
f010188d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101894:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101897:	01 d0                	add    %edx,%eax
f0101899:	8b 00                	mov    (%eax),%eax
f010189b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f01018a0:	c9                   	leave  
f01018a1:	c3                   	ret    

f01018a2 <tlb_invalidate>:
		
void tlb_invalidate(uint32 *ptr_page_directory, void *virtual_address)
{
f01018a2:	55                   	push   %ebp
f01018a3:	89 e5                	mov    %esp,%ebp
f01018a5:	83 ec 10             	sub    $0x10,%esp
f01018a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018ab:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01018ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01018b1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(virtual_address);
}
f01018b4:	90                   	nop
f01018b5:	c9                   	leave  
f01018b6:	c3                   	ret    

f01018b7 <page_check>:

void page_check()
{
f01018b7:	55                   	push   %ebp
f01018b8:	89 e5                	mov    %esp,%ebp
f01018ba:	53                   	push   %ebx
f01018bb:	83 ec 24             	sub    $0x24,%esp
	struct Frame_Info *pp, *pp0, *pp1, *pp2;
	struct Linked_List fl;

	// should be able to allocate three frames_info
	pp0 = pp1 = pp2 = 0;
f01018be:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f01018c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01018c8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01018cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01018ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(allocate_frame(&pp0) == 0);
f01018d1:	83 ec 0c             	sub    $0xc,%esp
f01018d4:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01018d7:	50                   	push   %eax
f01018d8:	e8 f3 24 00 00       	call   f0103dd0 <allocate_frame>
f01018dd:	83 c4 10             	add    $0x10,%esp
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	74 19                	je     f01018fd <page_check+0x46>
f01018e4:	68 3f 72 10 f0       	push   $0xf010723f
f01018e9:	68 fa 70 10 f0       	push   $0xf01070fa
f01018ee:	68 9d 00 00 00       	push   $0x9d
f01018f3:	68 89 70 10 f0       	push   $0xf0107089
f01018f8:	e8 31 e8 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp1) == 0);
f01018fd:	83 ec 0c             	sub    $0xc,%esp
f0101900:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101903:	50                   	push   %eax
f0101904:	e8 c7 24 00 00       	call   f0103dd0 <allocate_frame>
f0101909:	83 c4 10             	add    $0x10,%esp
f010190c:	85 c0                	test   %eax,%eax
f010190e:	74 19                	je     f0101929 <page_check+0x72>
f0101910:	68 59 72 10 f0       	push   $0xf0107259
f0101915:	68 fa 70 10 f0       	push   $0xf01070fa
f010191a:	68 9e 00 00 00       	push   $0x9e
f010191f:	68 89 70 10 f0       	push   $0xf0107089
f0101924:	e8 05 e8 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp2) == 0);
f0101929:	83 ec 0c             	sub    $0xc,%esp
f010192c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f010192f:	50                   	push   %eax
f0101930:	e8 9b 24 00 00       	call   f0103dd0 <allocate_frame>
f0101935:	83 c4 10             	add    $0x10,%esp
f0101938:	85 c0                	test   %eax,%eax
f010193a:	74 19                	je     f0101955 <page_check+0x9e>
f010193c:	68 73 72 10 f0       	push   $0xf0107273
f0101941:	68 fa 70 10 f0       	push   $0xf01070fa
f0101946:	68 9f 00 00 00       	push   $0x9f
f010194b:	68 89 70 10 f0       	push   $0xf0107089
f0101950:	e8 d9 e7 ff ff       	call   f010012e <_panic>

	assert(pp0);
f0101955:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101958:	85 c0                	test   %eax,%eax
f010195a:	75 19                	jne    f0101975 <page_check+0xbe>
f010195c:	68 8d 72 10 f0       	push   $0xf010728d
f0101961:	68 fa 70 10 f0       	push   $0xf01070fa
f0101966:	68 a1 00 00 00       	push   $0xa1
f010196b:	68 89 70 10 f0       	push   $0xf0107089
f0101970:	e8 b9 e7 ff ff       	call   f010012e <_panic>
	assert(pp1 && pp1 != pp0);
f0101975:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101978:	85 c0                	test   %eax,%eax
f010197a:	74 0a                	je     f0101986 <page_check+0xcf>
f010197c:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010197f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101982:	39 c2                	cmp    %eax,%edx
f0101984:	75 19                	jne    f010199f <page_check+0xe8>
f0101986:	68 91 72 10 f0       	push   $0xf0107291
f010198b:	68 fa 70 10 f0       	push   $0xf01070fa
f0101990:	68 a2 00 00 00       	push   $0xa2
f0101995:	68 89 70 10 f0       	push   $0xf0107089
f010199a:	e8 8f e7 ff ff       	call   f010012e <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010199f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01019a2:	85 c0                	test   %eax,%eax
f01019a4:	74 14                	je     f01019ba <page_check+0x103>
f01019a6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01019a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01019ac:	39 c2                	cmp    %eax,%edx
f01019ae:	74 0a                	je     f01019ba <page_check+0x103>
f01019b0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01019b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01019b6:	39 c2                	cmp    %eax,%edx
f01019b8:	75 19                	jne    f01019d3 <page_check+0x11c>
f01019ba:	68 a4 72 10 f0       	push   $0xf01072a4
f01019bf:	68 fa 70 10 f0       	push   $0xf01070fa
f01019c4:	68 a3 00 00 00       	push   $0xa3
f01019c9:	68 89 70 10 f0       	push   $0xf0107089
f01019ce:	e8 5b e7 ff ff       	call   f010012e <_panic>

	// temporarily steal the rest of the free frames_info
	fl = free_frame_list;
f01019d3:	a1 48 44 15 f0       	mov    0xf0154448,%eax
f01019d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&free_frame_list);
f01019db:	c7 05 48 44 15 f0 00 	movl   $0x0,0xf0154448
f01019e2:	00 00 00 

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f01019e5:	83 ec 0c             	sub    $0xc,%esp
f01019e8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01019eb:	50                   	push   %eax
f01019ec:	e8 df 23 00 00       	call   f0103dd0 <allocate_frame>
f01019f1:	83 c4 10             	add    $0x10,%esp
f01019f4:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01019f7:	74 19                	je     f0101a12 <page_check+0x15b>
f01019f9:	68 c4 72 10 f0       	push   $0xf01072c4
f01019fe:	68 fa 70 10 f0       	push   $0xf01070fa
f0101a03:	68 aa 00 00 00       	push   $0xaa
f0101a08:	68 89 70 10 f0       	push   $0xf0107089
f0101a0d:	e8 1c e7 ff ff       	call   f010012e <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) < 0);
f0101a12:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101a15:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101a1a:	6a 00                	push   $0x0
f0101a1c:	6a 00                	push   $0x0
f0101a1e:	52                   	push   %edx
f0101a1f:	50                   	push   %eax
f0101a20:	e8 b8 25 00 00       	call   f0103fdd <map_frame>
f0101a25:	83 c4 10             	add    $0x10,%esp
f0101a28:	85 c0                	test   %eax,%eax
f0101a2a:	78 19                	js     f0101a45 <page_check+0x18e>
f0101a2c:	68 e4 72 10 f0       	push   $0xf01072e4
f0101a31:	68 fa 70 10 f0       	push   $0xf01070fa
f0101a36:	68 ad 00 00 00       	push   $0xad
f0101a3b:	68 89 70 10 f0       	push   $0xf0107089
f0101a40:	e8 e9 e6 ff ff       	call   f010012e <_panic>

	// free pp0 and try again: pp0 should be used for page table
	free_frame(pp0);
f0101a45:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a48:	83 ec 0c             	sub    $0xc,%esp
f0101a4b:	50                   	push   %eax
f0101a4c:	e8 e6 23 00 00       	call   f0103e37 <free_frame>
f0101a51:	83 c4 10             	add    $0x10,%esp
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) == 0);
f0101a54:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101a57:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101a5c:	6a 00                	push   $0x0
f0101a5e:	6a 00                	push   $0x0
f0101a60:	52                   	push   %edx
f0101a61:	50                   	push   %eax
f0101a62:	e8 76 25 00 00       	call   f0103fdd <map_frame>
f0101a67:	83 c4 10             	add    $0x10,%esp
f0101a6a:	85 c0                	test   %eax,%eax
f0101a6c:	74 19                	je     f0101a87 <page_check+0x1d0>
f0101a6e:	68 14 73 10 f0       	push   $0xf0107314
f0101a73:	68 fa 70 10 f0       	push   $0xf01070fa
f0101a78:	68 b1 00 00 00       	push   $0xb1
f0101a7d:	68 89 70 10 f0       	push   $0xf0107089
f0101a82:	e8 a7 e6 ff ff       	call   f010012e <_panic>
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101a87:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101a8c:	8b 00                	mov    (%eax),%eax
f0101a8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a93:	89 c3                	mov    %eax,%ebx
f0101a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a98:	83 ec 0c             	sub    $0xc,%esp
f0101a9b:	50                   	push   %eax
f0101a9c:	e8 05 fa ff ff       	call   f01014a6 <to_physical_address>
f0101aa1:	83 c4 10             	add    $0x10,%esp
f0101aa4:	39 c3                	cmp    %eax,%ebx
f0101aa6:	74 19                	je     f0101ac1 <page_check+0x20a>
f0101aa8:	68 44 73 10 f0       	push   $0xf0107344
f0101aad:	68 fa 70 10 f0       	push   $0xf01070fa
f0101ab2:	68 b2 00 00 00       	push   $0xb2
f0101ab7:	68 89 70 10 f0       	push   $0xf0107089
f0101abc:	e8 6d e6 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, 0x0) == to_physical_address(pp1));
f0101ac1:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101ac6:	83 ec 08             	sub    $0x8,%esp
f0101ac9:	6a 00                	push   $0x0
f0101acb:	50                   	push   %eax
f0101acc:	e8 20 fd ff ff       	call   f01017f1 <check_va2pa>
f0101ad1:	83 c4 10             	add    $0x10,%esp
f0101ad4:	89 c3                	mov    %eax,%ebx
f0101ad6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ad9:	83 ec 0c             	sub    $0xc,%esp
f0101adc:	50                   	push   %eax
f0101add:	e8 c4 f9 ff ff       	call   f01014a6 <to_physical_address>
f0101ae2:	83 c4 10             	add    $0x10,%esp
f0101ae5:	39 c3                	cmp    %eax,%ebx
f0101ae7:	74 19                	je     f0101b02 <page_check+0x24b>
f0101ae9:	68 88 73 10 f0       	push   $0xf0107388
f0101aee:	68 fa 70 10 f0       	push   $0xf01070fa
f0101af3:	68 b3 00 00 00       	push   $0xb3
f0101af8:	68 89 70 10 f0       	push   $0xf0107089
f0101afd:	e8 2c e6 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101b02:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b05:	8b 40 08             	mov    0x8(%eax),%eax
f0101b08:	66 83 f8 01          	cmp    $0x1,%ax
f0101b0c:	74 19                	je     f0101b27 <page_check+0x270>
f0101b0e:	68 c9 73 10 f0       	push   $0xf01073c9
f0101b13:	68 fa 70 10 f0       	push   $0xf01070fa
f0101b18:	68 b4 00 00 00       	push   $0xb4
f0101b1d:	68 89 70 10 f0       	push   $0xf0107089
f0101b22:	e8 07 e6 ff ff       	call   f010012e <_panic>
	assert(pp0->references == 1);
f0101b27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b2a:	8b 40 08             	mov    0x8(%eax),%eax
f0101b2d:	66 83 f8 01          	cmp    $0x1,%ax
f0101b31:	74 19                	je     f0101b4c <page_check+0x295>
f0101b33:	68 de 73 10 f0       	push   $0xf01073de
f0101b38:	68 fa 70 10 f0       	push   $0xf01070fa
f0101b3d:	68 b5 00 00 00       	push   $0xb5
f0101b42:	68 89 70 10 f0       	push   $0xf0107089
f0101b47:	e8 e2 e5 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because pp0 is already allocated for page table
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101b4c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101b4f:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101b54:	6a 00                	push   $0x0
f0101b56:	68 00 10 00 00       	push   $0x1000
f0101b5b:	52                   	push   %edx
f0101b5c:	50                   	push   %eax
f0101b5d:	e8 7b 24 00 00       	call   f0103fdd <map_frame>
f0101b62:	83 c4 10             	add    $0x10,%esp
f0101b65:	85 c0                	test   %eax,%eax
f0101b67:	74 19                	je     f0101b82 <page_check+0x2cb>
f0101b69:	68 f4 73 10 f0       	push   $0xf01073f4
f0101b6e:	68 fa 70 10 f0       	push   $0xf01070fa
f0101b73:	68 b8 00 00 00       	push   $0xb8
f0101b78:	68 89 70 10 f0       	push   $0xf0107089
f0101b7d:	e8 ac e5 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101b82:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101b87:	83 ec 08             	sub    $0x8,%esp
f0101b8a:	68 00 10 00 00       	push   $0x1000
f0101b8f:	50                   	push   %eax
f0101b90:	e8 5c fc ff ff       	call   f01017f1 <check_va2pa>
f0101b95:	83 c4 10             	add    $0x10,%esp
f0101b98:	89 c3                	mov    %eax,%ebx
f0101b9a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101b9d:	83 ec 0c             	sub    $0xc,%esp
f0101ba0:	50                   	push   %eax
f0101ba1:	e8 00 f9 ff ff       	call   f01014a6 <to_physical_address>
f0101ba6:	83 c4 10             	add    $0x10,%esp
f0101ba9:	39 c3                	cmp    %eax,%ebx
f0101bab:	74 19                	je     f0101bc6 <page_check+0x30f>
f0101bad:	68 34 74 10 f0       	push   $0xf0107434
f0101bb2:	68 fa 70 10 f0       	push   $0xf01070fa
f0101bb7:	68 b9 00 00 00       	push   $0xb9
f0101bbc:	68 89 70 10 f0       	push   $0xf0107089
f0101bc1:	e8 68 e5 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101bc6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101bc9:	8b 40 08             	mov    0x8(%eax),%eax
f0101bcc:	66 83 f8 01          	cmp    $0x1,%ax
f0101bd0:	74 19                	je     f0101beb <page_check+0x334>
f0101bd2:	68 7b 74 10 f0       	push   $0xf010747b
f0101bd7:	68 fa 70 10 f0       	push   $0xf01070fa
f0101bdc:	68 ba 00 00 00       	push   $0xba
f0101be1:	68 89 70 10 f0       	push   $0xf0107089
f0101be6:	e8 43 e5 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101beb:	83 ec 0c             	sub    $0xc,%esp
f0101bee:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101bf1:	50                   	push   %eax
f0101bf2:	e8 d9 21 00 00       	call   f0103dd0 <allocate_frame>
f0101bf7:	83 c4 10             	add    $0x10,%esp
f0101bfa:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101bfd:	74 19                	je     f0101c18 <page_check+0x361>
f0101bff:	68 c4 72 10 f0       	push   $0xf01072c4
f0101c04:	68 fa 70 10 f0       	push   $0xf01070fa
f0101c09:	68 bd 00 00 00       	push   $0xbd
f0101c0e:	68 89 70 10 f0       	push   $0xf0107089
f0101c13:	e8 16 e5 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because it's already there
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101c18:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101c1b:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101c20:	6a 00                	push   $0x0
f0101c22:	68 00 10 00 00       	push   $0x1000
f0101c27:	52                   	push   %edx
f0101c28:	50                   	push   %eax
f0101c29:	e8 af 23 00 00       	call   f0103fdd <map_frame>
f0101c2e:	83 c4 10             	add    $0x10,%esp
f0101c31:	85 c0                	test   %eax,%eax
f0101c33:	74 19                	je     f0101c4e <page_check+0x397>
f0101c35:	68 f4 73 10 f0       	push   $0xf01073f4
f0101c3a:	68 fa 70 10 f0       	push   $0xf01070fa
f0101c3f:	68 c0 00 00 00       	push   $0xc0
f0101c44:	68 89 70 10 f0       	push   $0xf0107089
f0101c49:	e8 e0 e4 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101c4e:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101c53:	83 ec 08             	sub    $0x8,%esp
f0101c56:	68 00 10 00 00       	push   $0x1000
f0101c5b:	50                   	push   %eax
f0101c5c:	e8 90 fb ff ff       	call   f01017f1 <check_va2pa>
f0101c61:	83 c4 10             	add    $0x10,%esp
f0101c64:	89 c3                	mov    %eax,%ebx
f0101c66:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101c69:	83 ec 0c             	sub    $0xc,%esp
f0101c6c:	50                   	push   %eax
f0101c6d:	e8 34 f8 ff ff       	call   f01014a6 <to_physical_address>
f0101c72:	83 c4 10             	add    $0x10,%esp
f0101c75:	39 c3                	cmp    %eax,%ebx
f0101c77:	74 19                	je     f0101c92 <page_check+0x3db>
f0101c79:	68 34 74 10 f0       	push   $0xf0107434
f0101c7e:	68 fa 70 10 f0       	push   $0xf01070fa
f0101c83:	68 c1 00 00 00       	push   $0xc1
f0101c88:	68 89 70 10 f0       	push   $0xf0107089
f0101c8d:	e8 9c e4 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101c92:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101c95:	8b 40 08             	mov    0x8(%eax),%eax
f0101c98:	66 83 f8 01          	cmp    $0x1,%ax
f0101c9c:	74 19                	je     f0101cb7 <page_check+0x400>
f0101c9e:	68 7b 74 10 f0       	push   $0xf010747b
f0101ca3:	68 fa 70 10 f0       	push   $0xf01070fa
f0101ca8:	68 c2 00 00 00       	push   $0xc2
f0101cad:	68 89 70 10 f0       	push   $0xf0107089
f0101cb2:	e8 77 e4 ff ff       	call   f010012e <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in map_frame
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101cb7:	83 ec 0c             	sub    $0xc,%esp
f0101cba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101cbd:	50                   	push   %eax
f0101cbe:	e8 0d 21 00 00       	call   f0103dd0 <allocate_frame>
f0101cc3:	83 c4 10             	add    $0x10,%esp
f0101cc6:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101cc9:	74 19                	je     f0101ce4 <page_check+0x42d>
f0101ccb:	68 c4 72 10 f0       	push   $0xf01072c4
f0101cd0:	68 fa 70 10 f0       	push   $0xf01070fa
f0101cd5:	68 c6 00 00 00       	push   $0xc6
f0101cda:	68 89 70 10 f0       	push   $0xf0107089
f0101cdf:	e8 4a e4 ff ff       	call   f010012e <_panic>

	// should not be able to map at PTSIZE because need free frame for page table
	assert(map_frame(ptr_page_directory, pp0, (void*) PTSIZE, 0) < 0);
f0101ce4:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101ce7:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101cec:	6a 00                	push   $0x0
f0101cee:	68 00 00 40 00       	push   $0x400000
f0101cf3:	52                   	push   %edx
f0101cf4:	50                   	push   %eax
f0101cf5:	e8 e3 22 00 00       	call   f0103fdd <map_frame>
f0101cfa:	83 c4 10             	add    $0x10,%esp
f0101cfd:	85 c0                	test   %eax,%eax
f0101cff:	78 19                	js     f0101d1a <page_check+0x463>
f0101d01:	68 90 74 10 f0       	push   $0xf0107490
f0101d06:	68 fa 70 10 f0       	push   $0xf01070fa
f0101d0b:	68 c9 00 00 00       	push   $0xc9
f0101d10:	68 89 70 10 f0       	push   $0xf0107089
f0101d15:	e8 14 e4 ff ff       	call   f010012e <_panic>

	// insert pp1 at PAGE_SIZE (replacing pp2)
	assert(map_frame(ptr_page_directory, pp1, (void*) PAGE_SIZE, 0) == 0);
f0101d1a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101d1d:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101d22:	6a 00                	push   $0x0
f0101d24:	68 00 10 00 00       	push   $0x1000
f0101d29:	52                   	push   %edx
f0101d2a:	50                   	push   %eax
f0101d2b:	e8 ad 22 00 00       	call   f0103fdd <map_frame>
f0101d30:	83 c4 10             	add    $0x10,%esp
f0101d33:	85 c0                	test   %eax,%eax
f0101d35:	74 19                	je     f0101d50 <page_check+0x499>
f0101d37:	68 cc 74 10 f0       	push   $0xf01074cc
f0101d3c:	68 fa 70 10 f0       	push   $0xf01070fa
f0101d41:	68 cc 00 00 00       	push   $0xcc
f0101d46:	68 89 70 10 f0       	push   $0xf0107089
f0101d4b:	e8 de e3 ff ff       	call   f010012e <_panic>

	// should have pp1 at both 0 and PAGE_SIZE, pp2 nowhere, ...
	assert(check_va2pa(ptr_page_directory, 0) == to_physical_address(pp1));
f0101d50:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101d55:	83 ec 08             	sub    $0x8,%esp
f0101d58:	6a 00                	push   $0x0
f0101d5a:	50                   	push   %eax
f0101d5b:	e8 91 fa ff ff       	call   f01017f1 <check_va2pa>
f0101d60:	83 c4 10             	add    $0x10,%esp
f0101d63:	89 c3                	mov    %eax,%ebx
f0101d65:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d68:	83 ec 0c             	sub    $0xc,%esp
f0101d6b:	50                   	push   %eax
f0101d6c:	e8 35 f7 ff ff       	call   f01014a6 <to_physical_address>
f0101d71:	83 c4 10             	add    $0x10,%esp
f0101d74:	39 c3                	cmp    %eax,%ebx
f0101d76:	74 19                	je     f0101d91 <page_check+0x4da>
f0101d78:	68 0c 75 10 f0       	push   $0xf010750c
f0101d7d:	68 fa 70 10 f0       	push   $0xf01070fa
f0101d82:	68 cf 00 00 00       	push   $0xcf
f0101d87:	68 89 70 10 f0       	push   $0xf0107089
f0101d8c:	e8 9d e3 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101d91:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101d96:	83 ec 08             	sub    $0x8,%esp
f0101d99:	68 00 10 00 00       	push   $0x1000
f0101d9e:	50                   	push   %eax
f0101d9f:	e8 4d fa ff ff       	call   f01017f1 <check_va2pa>
f0101da4:	83 c4 10             	add    $0x10,%esp
f0101da7:	89 c3                	mov    %eax,%ebx
f0101da9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101dac:	83 ec 0c             	sub    $0xc,%esp
f0101daf:	50                   	push   %eax
f0101db0:	e8 f1 f6 ff ff       	call   f01014a6 <to_physical_address>
f0101db5:	83 c4 10             	add    $0x10,%esp
f0101db8:	39 c3                	cmp    %eax,%ebx
f0101dba:	74 19                	je     f0101dd5 <page_check+0x51e>
f0101dbc:	68 4c 75 10 f0       	push   $0xf010754c
f0101dc1:	68 fa 70 10 f0       	push   $0xf01070fa
f0101dc6:	68 d0 00 00 00       	push   $0xd0
f0101dcb:	68 89 70 10 f0       	push   $0xf0107089
f0101dd0:	e8 59 e3 ff ff       	call   f010012e <_panic>
	// ... and ref counts should reflect this
	assert(pp1->references == 2);
f0101dd5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101dd8:	8b 40 08             	mov    0x8(%eax),%eax
f0101ddb:	66 83 f8 02          	cmp    $0x2,%ax
f0101ddf:	74 19                	je     f0101dfa <page_check+0x543>
f0101de1:	68 93 75 10 f0       	push   $0xf0107593
f0101de6:	68 fa 70 10 f0       	push   $0xf01070fa
f0101deb:	68 d2 00 00 00       	push   $0xd2
f0101df0:	68 89 70 10 f0       	push   $0xf0107089
f0101df5:	e8 34 e3 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101dfa:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101dfd:	8b 40 08             	mov    0x8(%eax),%eax
f0101e00:	66 85 c0             	test   %ax,%ax
f0101e03:	74 19                	je     f0101e1e <page_check+0x567>
f0101e05:	68 a8 75 10 f0       	push   $0xf01075a8
f0101e0a:	68 fa 70 10 f0       	push   $0xf01070fa
f0101e0f:	68 d3 00 00 00       	push   $0xd3
f0101e14:	68 89 70 10 f0       	push   $0xf0107089
f0101e19:	e8 10 e3 ff ff       	call   f010012e <_panic>

	// pp2 should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp2);
f0101e1e:	83 ec 0c             	sub    $0xc,%esp
f0101e21:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101e24:	50                   	push   %eax
f0101e25:	e8 a6 1f 00 00       	call   f0103dd0 <allocate_frame>
f0101e2a:	83 c4 10             	add    $0x10,%esp
f0101e2d:	85 c0                	test   %eax,%eax
f0101e2f:	75 0a                	jne    f0101e3b <page_check+0x584>
f0101e31:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101e34:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101e37:	39 c2                	cmp    %eax,%edx
f0101e39:	74 19                	je     f0101e54 <page_check+0x59d>
f0101e3b:	68 c0 75 10 f0       	push   $0xf01075c0
f0101e40:	68 fa 70 10 f0       	push   $0xf01070fa
f0101e45:	68 d6 00 00 00       	push   $0xd6
f0101e4a:	68 89 70 10 f0       	push   $0xf0107089
f0101e4f:	e8 da e2 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at 0 should keep pp1 at PAGE_SIZE
	unmap_frame(ptr_page_directory, 0x0);
f0101e54:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101e59:	83 ec 08             	sub    $0x8,%esp
f0101e5c:	6a 00                	push   $0x0
f0101e5e:	50                   	push   %eax
f0101e5f:	e8 97 22 00 00       	call   f01040fb <unmap_frame>
f0101e64:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101e67:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101e6c:	83 ec 08             	sub    $0x8,%esp
f0101e6f:	6a 00                	push   $0x0
f0101e71:	50                   	push   %eax
f0101e72:	e8 7a f9 ff ff       	call   f01017f1 <check_va2pa>
f0101e77:	83 c4 10             	add    $0x10,%esp
f0101e7a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7d:	74 19                	je     f0101e98 <page_check+0x5e1>
f0101e7f:	68 e8 75 10 f0       	push   $0xf01075e8
f0101e84:	68 fa 70 10 f0       	push   $0xf01070fa
f0101e89:	68 da 00 00 00       	push   $0xda
f0101e8e:	68 89 70 10 f0       	push   $0xf0107089
f0101e93:	e8 96 e2 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f0101e98:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101e9d:	83 ec 08             	sub    $0x8,%esp
f0101ea0:	68 00 10 00 00       	push   $0x1000
f0101ea5:	50                   	push   %eax
f0101ea6:	e8 46 f9 ff ff       	call   f01017f1 <check_va2pa>
f0101eab:	83 c4 10             	add    $0x10,%esp
f0101eae:	89 c3                	mov    %eax,%ebx
f0101eb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101eb3:	83 ec 0c             	sub    $0xc,%esp
f0101eb6:	50                   	push   %eax
f0101eb7:	e8 ea f5 ff ff       	call   f01014a6 <to_physical_address>
f0101ebc:	83 c4 10             	add    $0x10,%esp
f0101ebf:	39 c3                	cmp    %eax,%ebx
f0101ec1:	74 19                	je     f0101edc <page_check+0x625>
f0101ec3:	68 4c 75 10 f0       	push   $0xf010754c
f0101ec8:	68 fa 70 10 f0       	push   $0xf01070fa
f0101ecd:	68 db 00 00 00       	push   $0xdb
f0101ed2:	68 89 70 10 f0       	push   $0xf0107089
f0101ed7:	e8 52 e2 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101edc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101edf:	8b 40 08             	mov    0x8(%eax),%eax
f0101ee2:	66 83 f8 01          	cmp    $0x1,%ax
f0101ee6:	74 19                	je     f0101f01 <page_check+0x64a>
f0101ee8:	68 c9 73 10 f0       	push   $0xf01073c9
f0101eed:	68 fa 70 10 f0       	push   $0xf01070fa
f0101ef2:	68 dc 00 00 00       	push   $0xdc
f0101ef7:	68 89 70 10 f0       	push   $0xf0107089
f0101efc:	e8 2d e2 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101f01:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101f04:	8b 40 08             	mov    0x8(%eax),%eax
f0101f07:	66 85 c0             	test   %ax,%ax
f0101f0a:	74 19                	je     f0101f25 <page_check+0x66e>
f0101f0c:	68 a8 75 10 f0       	push   $0xf01075a8
f0101f11:	68 fa 70 10 f0       	push   $0xf01070fa
f0101f16:	68 dd 00 00 00       	push   $0xdd
f0101f1b:	68 89 70 10 f0       	push   $0xf0107089
f0101f20:	e8 09 e2 ff ff       	call   f010012e <_panic>

	// unmapping pp1 at PAGE_SIZE should free it
	unmap_frame(ptr_page_directory, (void*) PAGE_SIZE);
f0101f25:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101f2a:	83 ec 08             	sub    $0x8,%esp
f0101f2d:	68 00 10 00 00       	push   $0x1000
f0101f32:	50                   	push   %eax
f0101f33:	e8 c3 21 00 00       	call   f01040fb <unmap_frame>
f0101f38:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f0101f3b:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101f40:	83 ec 08             	sub    $0x8,%esp
f0101f43:	6a 00                	push   $0x0
f0101f45:	50                   	push   %eax
f0101f46:	e8 a6 f8 ff ff       	call   f01017f1 <check_va2pa>
f0101f4b:	83 c4 10             	add    $0x10,%esp
f0101f4e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f51:	74 19                	je     f0101f6c <page_check+0x6b5>
f0101f53:	68 e8 75 10 f0       	push   $0xf01075e8
f0101f58:	68 fa 70 10 f0       	push   $0xf01070fa
f0101f5d:	68 e1 00 00 00       	push   $0xe1
f0101f62:	68 89 70 10 f0       	push   $0xf0107089
f0101f67:	e8 c2 e1 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == ~0);
f0101f6c:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0101f71:	83 ec 08             	sub    $0x8,%esp
f0101f74:	68 00 10 00 00       	push   $0x1000
f0101f79:	50                   	push   %eax
f0101f7a:	e8 72 f8 ff ff       	call   f01017f1 <check_va2pa>
f0101f7f:	83 c4 10             	add    $0x10,%esp
f0101f82:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f85:	74 19                	je     f0101fa0 <page_check+0x6e9>
f0101f87:	68 14 76 10 f0       	push   $0xf0107614
f0101f8c:	68 fa 70 10 f0       	push   $0xf01070fa
f0101f91:	68 e2 00 00 00       	push   $0xe2
f0101f96:	68 89 70 10 f0       	push   $0xf0107089
f0101f9b:	e8 8e e1 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 0);
f0101fa0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101fa3:	8b 40 08             	mov    0x8(%eax),%eax
f0101fa6:	66 85 c0             	test   %ax,%ax
f0101fa9:	74 19                	je     f0101fc4 <page_check+0x70d>
f0101fab:	68 45 76 10 f0       	push   $0xf0107645
f0101fb0:	68 fa 70 10 f0       	push   $0xf01070fa
f0101fb5:	68 e3 00 00 00       	push   $0xe3
f0101fba:	68 89 70 10 f0       	push   $0xf0107089
f0101fbf:	e8 6a e1 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0101fc4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101fc7:	8b 40 08             	mov    0x8(%eax),%eax
f0101fca:	66 85 c0             	test   %ax,%ax
f0101fcd:	74 19                	je     f0101fe8 <page_check+0x731>
f0101fcf:	68 a8 75 10 f0       	push   $0xf01075a8
f0101fd4:	68 fa 70 10 f0       	push   $0xf01070fa
f0101fd9:	68 e4 00 00 00       	push   $0xe4
f0101fde:	68 89 70 10 f0       	push   $0xf0107089
f0101fe3:	e8 46 e1 ff ff       	call   f010012e <_panic>

	// so it should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp1);
f0101fe8:	83 ec 0c             	sub    $0xc,%esp
f0101feb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101fee:	50                   	push   %eax
f0101fef:	e8 dc 1d 00 00       	call   f0103dd0 <allocate_frame>
f0101ff4:	83 c4 10             	add    $0x10,%esp
f0101ff7:	85 c0                	test   %eax,%eax
f0101ff9:	75 0a                	jne    f0102005 <page_check+0x74e>
f0101ffb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101ffe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102001:	39 c2                	cmp    %eax,%edx
f0102003:	74 19                	je     f010201e <page_check+0x767>
f0102005:	68 5c 76 10 f0       	push   $0xf010765c
f010200a:	68 fa 70 10 f0       	push   $0xf01070fa
f010200f:	68 e7 00 00 00       	push   $0xe7
f0102014:	68 89 70 10 f0       	push   $0xf0107089
f0102019:	e8 10 e1 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f010201e:	83 ec 0c             	sub    $0xc,%esp
f0102021:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102024:	50                   	push   %eax
f0102025:	e8 a6 1d 00 00       	call   f0103dd0 <allocate_frame>
f010202a:	83 c4 10             	add    $0x10,%esp
f010202d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102030:	74 19                	je     f010204b <page_check+0x794>
f0102032:	68 c4 72 10 f0       	push   $0xf01072c4
f0102037:	68 fa 70 10 f0       	push   $0xf01070fa
f010203c:	68 ea 00 00 00       	push   $0xea
f0102041:	68 89 70 10 f0       	push   $0xf0107089
f0102046:	e8 e3 e0 ff ff       	call   f010012e <_panic>

	// forcibly take pp0 back
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f010204b:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102050:	8b 00                	mov    (%eax),%eax
f0102052:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102057:	89 c3                	mov    %eax,%ebx
f0102059:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010205c:	83 ec 0c             	sub    $0xc,%esp
f010205f:	50                   	push   %eax
f0102060:	e8 41 f4 ff ff       	call   f01014a6 <to_physical_address>
f0102065:	83 c4 10             	add    $0x10,%esp
f0102068:	39 c3                	cmp    %eax,%ebx
f010206a:	74 19                	je     f0102085 <page_check+0x7ce>
f010206c:	68 44 73 10 f0       	push   $0xf0107344
f0102071:	68 fa 70 10 f0       	push   $0xf01070fa
f0102076:	68 ed 00 00 00       	push   $0xed
f010207b:	68 89 70 10 f0       	push   $0xf0107089
f0102080:	e8 a9 e0 ff ff       	call   f010012e <_panic>
	ptr_page_directory[0] = 0;
f0102085:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010208a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->references == 1);
f0102090:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102093:	8b 40 08             	mov    0x8(%eax),%eax
f0102096:	66 83 f8 01          	cmp    $0x1,%ax
f010209a:	74 19                	je     f01020b5 <page_check+0x7fe>
f010209c:	68 de 73 10 f0       	push   $0xf01073de
f01020a1:	68 fa 70 10 f0       	push   $0xf01070fa
f01020a6:	68 ef 00 00 00       	push   $0xef
f01020ab:	68 89 70 10 f0       	push   $0xf0107089
f01020b0:	e8 79 e0 ff ff       	call   f010012e <_panic>
	pp0->references = 0;
f01020b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01020b8:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	free_frame_list = fl;
f01020be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01020c1:	a3 48 44 15 f0       	mov    %eax,0xf0154448

	// free the frames_info we took
	free_frame(pp0);
f01020c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01020c9:	83 ec 0c             	sub    $0xc,%esp
f01020cc:	50                   	push   %eax
f01020cd:	e8 65 1d 00 00       	call   f0103e37 <free_frame>
f01020d2:	83 c4 10             	add    $0x10,%esp
	free_frame(pp1);
f01020d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020d8:	83 ec 0c             	sub    $0xc,%esp
f01020db:	50                   	push   %eax
f01020dc:	e8 56 1d 00 00       	call   f0103e37 <free_frame>
f01020e1:	83 c4 10             	add    $0x10,%esp
	free_frame(pp2);
f01020e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01020e7:	83 ec 0c             	sub    $0xc,%esp
f01020ea:	50                   	push   %eax
f01020eb:	e8 47 1d 00 00       	call   f0103e37 <free_frame>
f01020f0:	83 c4 10             	add    $0x10,%esp

	cprintf("page_check() succeeded!\n");
f01020f3:	83 ec 0c             	sub    $0xc,%esp
f01020f6:	68 82 76 10 f0       	push   $0xf0107682
f01020fb:	e8 85 29 00 00       	call   f0104a85 <cprintf>
f0102100:	83 c4 10             	add    $0x10,%esp
}
f0102103:	90                   	nop
f0102104:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102107:	c9                   	leave  
f0102108:	c3                   	ret    

f0102109 <turn_on_paging>:

void turn_on_paging()
{
f0102109:	55                   	push   %ebp
f010210a:	89 e5                	mov    %esp,%ebp
f010210c:	83 ec 20             	sub    $0x20,%esp
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA (KERNEL_BASE), i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	ptr_page_directory[0] = ptr_page_directory[PDX(KERNEL_BASE)];
f010210f:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102114:	8b 15 54 44 15 f0    	mov    0xf0154454,%edx
f010211a:	8b 92 00 0f 00 00    	mov    0xf00(%edx),%edx
f0102120:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(phys_page_directory);
f0102122:	a1 58 44 15 f0       	mov    0xf0154458,%eax
f0102127:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010212a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010212d:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32
rcr0(void)
{
	uint32 val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102130:	0f 20 c0             	mov    %cr0,%eax
f0102133:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
f0102136:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// Turn on paging.
	uint32 cr0;
	cr0 = rcr0();
f0102139:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f010213c:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f0102143:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f0102147:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010214a:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static __inline void
lcr0(uint32 val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010214d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102150:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNEL_BASE+x => x => x.
	// (x < 4MB so uses paging ptr_page_directory[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f0102153:	0f 01 15 50 06 12 f0 	lgdtl  0xf0120650
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010215a:	b8 23 00 00 00       	mov    $0x23,%eax
f010215f:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102161:	b8 23 00 00 00       	mov    $0x23,%eax
f0102166:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102168:	b8 10 00 00 00       	mov    $0x10,%eax
f010216d:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010216f:	b8 10 00 00 00       	mov    $0x10,%eax
f0102174:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102176:	b8 10 00 00 00       	mov    $0x10,%eax
f010217b:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f010217d:	ea 84 21 10 f0 08 00 	ljmp   $0x8,$0xf0102184
	asm volatile("lldt %%ax" :: "a" (0));
f0102184:	b8 00 00 00 00       	mov    $0x0,%eax
f0102189:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNEL_BASE + x => KERNEL_BASE + x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	ptr_page_directory[0] = 0;
f010218c:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102191:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the ptr_page_directory[0] mapping.
	lcr3(phys_page_directory);
f0102197:	a1 58 44 15 f0       	mov    0xf0154458,%eax
f010219c:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010219f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01021a2:	0f 22 d8             	mov    %eax,%cr3
}
f01021a5:	90                   	nop
f01021a6:	c9                   	leave  
f01021a7:	c3                   	ret    

f01021a8 <setup_listing_to_all_page_tables_entries>:

void setup_listing_to_all_page_tables_entries()
{
f01021a8:	55                   	push   %ebp
f01021a9:	89 e5                	mov    %esp,%ebp
f01021ab:	83 ec 18             	sub    $0x18,%esp
	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.

	// Permissions: kernel RW, user NONE
	uint32 phys_frame_address = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01021ae:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01021b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01021b6:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f01021bd:	77 17                	ja     f01021d6 <setup_listing_to_all_page_tables_entries+0x2e>
f01021bf:	ff 75 f4             	pushl  -0xc(%ebp)
f01021c2:	68 58 70 10 f0       	push   $0xf0107058
f01021c7:	68 39 01 00 00       	push   $0x139
f01021cc:	68 89 70 10 f0       	push   $0xf0107089
f01021d1:	e8 58 df ff ff       	call   f010012e <_panic>
f01021d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01021d9:	05 00 00 00 10       	add    $0x10000000,%eax
f01021de:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ptr_page_directory[PDX(VPT)] = CONSTRUCT_ENTRY(phys_frame_address , PERM_PRESENT | PERM_WRITEABLE);
f01021e1:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01021e6:	05 fc 0e 00 00       	add    $0xefc,%eax
f01021eb:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01021ee:	83 ca 03             	or     $0x3,%edx
f01021f1:	89 10                	mov    %edx,(%eax)

	// same for UVPT
	//Permissions: kernel R, user R
	ptr_page_directory[PDX(UVPT)] = K_PHYSICAL_ADDRESS(ptr_page_directory)|PERM_USER|PERM_PRESENT;
f01021f3:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01021f8:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f01021fe:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102203:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102206:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f010220d:	77 17                	ja     f0102226 <setup_listing_to_all_page_tables_entries+0x7e>
f010220f:	ff 75 ec             	pushl  -0x14(%ebp)
f0102212:	68 58 70 10 f0       	push   $0xf0107058
f0102217:	68 3e 01 00 00       	push   $0x13e
f010221c:	68 89 70 10 f0       	push   $0xf0107089
f0102221:	e8 08 df ff ff       	call   f010012e <_panic>
f0102226:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102229:	05 00 00 00 10       	add    $0x10000000,%eax
f010222e:	83 c8 05             	or     $0x5,%eax
f0102231:	89 02                	mov    %eax,(%edx)

}
f0102233:	90                   	nop
f0102234:	c9                   	leave  
f0102235:	c3                   	ret    

f0102236 <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int envid2env(int32  envid, struct Env **env_store, bool checkperm)
{
f0102236:	55                   	push   %ebp
f0102237:	89 e5                	mov    %esp,%ebp
f0102239:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010223c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102240:	75 15                	jne    f0102257 <envid2env+0x21>
		*env_store = curenv;
f0102242:	8b 15 14 2f 15 f0    	mov    0xf0152f14,%edx
f0102248:	8b 45 0c             	mov    0xc(%ebp),%eax
f010224b:	89 10                	mov    %edx,(%eax)
		return 0;
f010224d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102252:	e9 8c 00 00 00       	jmp    f01022e3 <envid2env+0xad>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102257:	8b 15 10 2f 15 f0    	mov    0xf0152f10,%edx
f010225d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102260:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102265:	89 c1                	mov    %eax,%ecx
f0102267:	89 c8                	mov    %ecx,%eax
f0102269:	c1 e0 02             	shl    $0x2,%eax
f010226c:	01 c8                	add    %ecx,%eax
f010226e:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0102275:	01 c8                	add    %ecx,%eax
f0102277:	c1 e0 02             	shl    $0x2,%eax
f010227a:	01 d0                	add    %edx,%eax
f010227c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010227f:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102282:	8b 40 54             	mov    0x54(%eax),%eax
f0102285:	85 c0                	test   %eax,%eax
f0102287:	74 0b                	je     f0102294 <envid2env+0x5e>
f0102289:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010228c:	8b 40 4c             	mov    0x4c(%eax),%eax
f010228f:	3b 45 08             	cmp    0x8(%ebp),%eax
f0102292:	74 10                	je     f01022a4 <envid2env+0x6e>
		*env_store = 0;
f0102294:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102297:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010229d:	b8 02 00 00 00       	mov    $0x2,%eax
f01022a2:	eb 3f                	jmp    f01022e3 <envid2env+0xad>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01022a4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01022a8:	74 2c                	je     f01022d6 <envid2env+0xa0>
f01022aa:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01022af:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f01022b2:	74 22                	je     f01022d6 <envid2env+0xa0>
f01022b4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01022b7:	8b 50 50             	mov    0x50(%eax),%edx
f01022ba:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01022bf:	8b 40 4c             	mov    0x4c(%eax),%eax
f01022c2:	39 c2                	cmp    %eax,%edx
f01022c4:	74 10                	je     f01022d6 <envid2env+0xa0>
		*env_store = 0;
f01022c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022c9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01022cf:	b8 02 00 00 00       	mov    $0x2,%eax
f01022d4:	eb 0d                	jmp    f01022e3 <envid2env+0xad>
	}

	*env_store = e;
f01022d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022d9:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01022dc:	89 10                	mov    %edx,(%eax)
	return 0;
f01022de:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01022e3:	c9                   	leave  
f01022e4:	c3                   	ret    

f01022e5 <TestAss1>:

//define the white-space symbols
#define WHITESPACE "\t\r\n "

void TestAss1()
{
f01022e5:	55                   	push   %ebp
f01022e6:	89 e5                	mov    %esp,%ebp
f01022e8:	83 ec 08             	sub    $0x8,%esp
	cprintf("\n========================\n");
f01022eb:	83 ec 0c             	sub    $0xc,%esp
f01022ee:	68 9c 76 10 f0       	push   $0xf010769c
f01022f3:	e8 8d 27 00 00       	call   f0104a85 <cprintf>
f01022f8:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q1:\n");
f01022fb:	83 ec 0c             	sub    $0xc,%esp
f01022fe:	68 b7 76 10 f0       	push   $0xf01076b7
f0102303:	e8 7d 27 00 00       	call   f0104a85 <cprintf>
f0102308:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f010230b:	83 ec 0c             	sub    $0xc,%esp
f010230e:	68 d1 76 10 f0       	push   $0xf01076d1
f0102313:	e8 6d 27 00 00       	call   f0104a85 <cprintf>
f0102318:	83 c4 10             	add    $0x10,%esp
	TestAss1Q1();
f010231b:	e8 a2 00 00 00       	call   f01023c2 <TestAss1Q1>
	cprintf("\n========================\n");
f0102320:	83 ec 0c             	sub    $0xc,%esp
f0102323:	68 9c 76 10 f0       	push   $0xf010769c
f0102328:	e8 58 27 00 00       	call   f0104a85 <cprintf>
f010232d:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q2:\n");
f0102330:	83 ec 0c             	sub    $0xc,%esp
f0102333:	68 eb 76 10 f0       	push   $0xf01076eb
f0102338:	e8 48 27 00 00       	call   f0104a85 <cprintf>
f010233d:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f0102340:	83 ec 0c             	sub    $0xc,%esp
f0102343:	68 d1 76 10 f0       	push   $0xf01076d1
f0102348:	e8 38 27 00 00       	call   f0104a85 <cprintf>
f010234d:	83 c4 10             	add    $0x10,%esp
	TestAss1Q2();
f0102350:	e8 c9 02 00 00       	call   f010261e <TestAss1Q2>
	cprintf("\n========================\n");
f0102355:	83 ec 0c             	sub    $0xc,%esp
f0102358:	68 9c 76 10 f0       	push   $0xf010769c
f010235d:	e8 23 27 00 00       	call   f0104a85 <cprintf>
f0102362:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q3:\n");
f0102365:	83 ec 0c             	sub    $0xc,%esp
f0102368:	68 05 77 10 f0       	push   $0xf0107705
f010236d:	e8 13 27 00 00       	call   f0104a85 <cprintf>
f0102372:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f0102375:	83 ec 0c             	sub    $0xc,%esp
f0102378:	68 d1 76 10 f0       	push   $0xf01076d1
f010237d:	e8 03 27 00 00       	call   f0104a85 <cprintf>
f0102382:	83 c4 10             	add    $0x10,%esp
	TestAss1Q3();
f0102385:	e8 82 05 00 00       	call   f010290c <TestAss1Q3>
	cprintf("\n========================\n");
f010238a:	83 ec 0c             	sub    $0xc,%esp
f010238d:	68 9c 76 10 f0       	push   $0xf010769c
f0102392:	e8 ee 26 00 00       	call   f0104a85 <cprintf>
f0102397:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q4:\n");
f010239a:	83 ec 0c             	sub    $0xc,%esp
f010239d:	68 1f 77 10 f0       	push   $0xf010771f
f01023a2:	e8 de 26 00 00       	call   f0104a85 <cprintf>
f01023a7:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f01023aa:	83 ec 0c             	sub    $0xc,%esp
f01023ad:	68 d1 76 10 f0       	push   $0xf01076d1
f01023b2:	e8 ce 26 00 00       	call   f0104a85 <cprintf>
f01023b7:	83 c4 10             	add    $0x10,%esp
	TestAss1Q4();
f01023ba:	e8 9d 08 00 00       	call   f0102c5c <TestAss1Q4>
}
f01023bf:	90                   	nop
f01023c0:	c9                   	leave  
f01023c1:	c3                   	ret    

f01023c2 <TestAss1Q1>:

int TestAss1Q1()
{
f01023c2:	55                   	push   %ebp
f01023c3:	89 e5                	mov    %esp,%ebp
f01023c5:	57                   	push   %edi
f01023c6:	56                   	push   %esi
f01023c7:	53                   	push   %ebx
f01023c8:	81 ec fc 01 00 00    	sub    $0x1fc,%esp
	int retValue = 1;
f01023ce:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int i = 0;
f01023d5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	//Create first array
	char cr1[100] = "cnia _x4 3 10 20 30";
f01023dc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f01023e2:	bb fe 77 10 f0       	mov    $0xf01077fe,%ebx
f01023e7:	ba 05 00 00 00       	mov    $0x5,%edx
f01023ec:	89 c7                	mov    %eax,%edi
f01023ee:	89 de                	mov    %ebx,%esi
f01023f0:	89 d1                	mov    %edx,%ecx
f01023f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01023f4:	8d 55 84             	lea    -0x7c(%ebp),%edx
f01023f7:	b9 14 00 00 00       	mov    $0x14,%ecx
f01023fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102401:	89 d7                	mov    %edx,%edi
f0102403:	f3 ab                	rep stos %eax,%es:(%edi)
	int numOfArgs = 0;
f0102405:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f010240c:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f010240f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102415:	50                   	push   %eax
f0102416:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010241c:	50                   	push   %eax
f010241d:	68 39 77 10 f0       	push   $0xf0107739
f0102422:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0102428:	50                   	push   %eax
f0102429:	e8 f1 3f 00 00       	call   f010641f <strsplit>
f010242e:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
f0102431:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0102437:	83 ec 08             	sub    $0x8,%esp
f010243a:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0102440:	52                   	push   %edx
f0102441:	50                   	push   %eax
f0102442:	e8 a1 e8 ff ff       	call   f0100ce8 <CreateIntArray>
f0102447:	83 c4 10             	add    $0x10,%esp
f010244a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f010244d:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f0102454:	77 16                	ja     f010246c <TestAss1Q1+0xaa>
f0102456:	68 3e 77 10 f0       	push   $0xf010773e
f010245b:	68 57 77 10 f0       	push   $0xf0107757
f0102460:	6a 26                	push   $0x26
f0102462:	68 6c 77 10 f0       	push   $0xf010776c
f0102467:	e8 c2 dc ff ff       	call   f010012e <_panic>


	//Create second array
	char cr2[100] = "cnia _y4 4 400 400";
f010246c:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f0102472:	bb 62 78 10 f0       	mov    $0xf0107862,%ebx
f0102477:	ba 13 00 00 00       	mov    $0x13,%edx
f010247c:	89 c7                	mov    %eax,%edi
f010247e:	89 de                	mov    %ebx,%esi
f0102480:	89 d1                	mov    %edx,%ecx
f0102482:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102484:	8d 95 db fe ff ff    	lea    -0x125(%ebp),%edx
f010248a:	b9 51 00 00 00       	mov    $0x51,%ecx
f010248f:	b0 00                	mov    $0x0,%al
f0102491:	89 d7                	mov    %edx,%edi
f0102493:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102495:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f010249c:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f010249f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01024a5:	50                   	push   %eax
f01024a6:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f01024ac:	50                   	push   %eax
f01024ad:	68 39 77 10 f0       	push   $0xf0107739
f01024b2:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f01024b8:	50                   	push   %eax
f01024b9:	e8 61 3f 00 00       	call   f010641f <strsplit>
f01024be:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args);
f01024c1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f01024c7:	83 ec 08             	sub    $0x8,%esp
f01024ca:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f01024d0:	52                   	push   %edx
f01024d1:	50                   	push   %eax
f01024d2:	e8 11 e8 ff ff       	call   f0100ce8 <CreateIntArray>
f01024d7:	83 c4 10             	add    $0x10,%esp
f01024da:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF1000000);
f01024dd:	81 7d d8 ff ff ff f0 	cmpl   $0xf0ffffff,-0x28(%ebp)
f01024e4:	77 16                	ja     f01024fc <TestAss1Q1+0x13a>
f01024e6:	68 79 77 10 f0       	push   $0xf0107779
f01024eb:	68 57 77 10 f0       	push   $0xf0107757
f01024f0:	6a 2f                	push   $0x2f
f01024f2:	68 6c 77 10 f0       	push   $0xf010776c
f01024f7:	e8 32 dc ff ff       	call   f010012e <_panic>

	int ret =0 ;
f01024fc:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

	//Calculate var of 1st array
	char v1[100] = "cav _x4";
f0102503:	c7 85 64 fe ff ff 63 	movl   $0x20766163,-0x19c(%ebp)
f010250a:	61 76 20 
f010250d:	c7 85 68 fe ff ff 5f 	movl   $0x34785f,-0x198(%ebp)
f0102514:	78 34 00 
f0102517:	8d 95 6c fe ff ff    	lea    -0x194(%ebp),%edx
f010251d:	b9 17 00 00 00       	mov    $0x17,%ecx
f0102522:	b8 00 00 00 00       	mov    $0x0,%eax
f0102527:	89 d7                	mov    %edx,%edi
f0102529:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(v1, WHITESPACE, args, &numOfArgs) ;
f010252b:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102531:	50                   	push   %eax
f0102532:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102538:	50                   	push   %eax
f0102539:	68 39 77 10 f0       	push   $0xf0107739
f010253e:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
f0102544:	50                   	push   %eax
f0102545:	e8 d5 3e 00 00       	call   f010641f <strsplit>
f010254a:	83 c4 10             	add    $0x10,%esp
	ret = CalcArrVar(args) ;
f010254d:	83 ec 0c             	sub    $0xc,%esp
f0102550:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102556:	50                   	push   %eax
f0102557:	e8 79 ea ff ff       	call   f0100fd5 <CalcArrVar>
f010255c:	83 c4 10             	add    $0x10,%esp
f010255f:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	if (ret != 66)
f0102562:	83 7d d4 42          	cmpl   $0x42,-0x2c(%ebp)
f0102566:	74 1a                	je     f0102582 <TestAss1Q1+0x1c0>
	{
		cprintf("[EVAL] #1 CalcArrVar: Failed\n");
f0102568:	83 ec 0c             	sub    $0xc,%esp
f010256b:	68 92 77 10 f0       	push   $0xf0107792
f0102570:	e8 10 25 00 00       	call   f0104a85 <cprintf>
f0102575:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102578:	b8 01 00 00 00       	mov    $0x1,%eax
f010257d:	e9 94 00 00 00       	jmp    f0102616 <TestAss1Q1+0x254>
	}

	//Calculate var of 2nd array
	char v2[100] = "cav _y4";
f0102582:	c7 85 00 fe ff ff 63 	movl   $0x20766163,-0x200(%ebp)
f0102589:	61 76 20 
f010258c:	c7 85 04 fe ff ff 5f 	movl   $0x34795f,-0x1fc(%ebp)
f0102593:	79 34 00 
f0102596:	8d 95 08 fe ff ff    	lea    -0x1f8(%ebp),%edx
f010259c:	b9 17 00 00 00       	mov    $0x17,%ecx
f01025a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01025a6:	89 d7                	mov    %edx,%edi
f01025a8:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(v2, WHITESPACE, args, &numOfArgs) ;
f01025aa:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01025b0:	50                   	push   %eax
f01025b1:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f01025b7:	50                   	push   %eax
f01025b8:	68 39 77 10 f0       	push   $0xf0107739
f01025bd:	8d 85 00 fe ff ff    	lea    -0x200(%ebp),%eax
f01025c3:	50                   	push   %eax
f01025c4:	e8 56 3e 00 00       	call   f010641f <strsplit>
f01025c9:	83 c4 10             	add    $0x10,%esp
	ret = CalcArrVar(args) ;
f01025cc:	83 ec 0c             	sub    $0xc,%esp
f01025cf:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f01025d5:	50                   	push   %eax
f01025d6:	e8 fa e9 ff ff       	call   f0100fd5 <CalcArrVar>
f01025db:	83 c4 10             	add    $0x10,%esp
f01025de:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	if (ret != 40000)
f01025e1:	81 7d d4 40 9c 00 00 	cmpl   $0x9c40,-0x2c(%ebp)
f01025e8:	74 17                	je     f0102601 <TestAss1Q1+0x23f>
	{
		cprintf("[EVAL] #2 CalcArrVar: Failed\n");
f01025ea:	83 ec 0c             	sub    $0xc,%esp
f01025ed:	68 b0 77 10 f0       	push   $0xf01077b0
f01025f2:	e8 8e 24 00 00       	call   f0104a85 <cprintf>
f01025f7:	83 c4 10             	add    $0x10,%esp
		return 1;
f01025fa:	b8 01 00 00 00       	mov    $0x1,%eax
f01025ff:	eb 15                	jmp    f0102616 <TestAss1Q1+0x254>
	}

	cprintf("[EVAL] CalcArrVar: Succeeded. Evaluation = 1\n");
f0102601:	83 ec 0c             	sub    $0xc,%esp
f0102604:	68 d0 77 10 f0       	push   $0xf01077d0
f0102609:	e8 77 24 00 00       	call   f0104a85 <cprintf>
f010260e:	83 c4 10             	add    $0x10,%esp

	return 1;
f0102611:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0102616:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102619:	5b                   	pop    %ebx
f010261a:	5e                   	pop    %esi
f010261b:	5f                   	pop    %edi
f010261c:	5d                   	pop    %ebp
f010261d:	c3                   	ret    

f010261e <TestAss1Q2>:

int TestAss1Q2()
{
f010261e:	55                   	push   %ebp
f010261f:	89 e5                	mov    %esp,%ebp
f0102621:	57                   	push   %edi
f0102622:	56                   	push   %esi
f0102623:	53                   	push   %ebx
f0102624:	81 ec ac 01 00 00    	sub    $0x1ac,%esp
	//Connect with write permission
	char cr1[100] = "cvp 0x0 768 w";
f010262a:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
f0102630:	bb d9 7a 10 f0       	mov    $0xf0107ad9,%ebx
f0102635:	ba 0e 00 00 00       	mov    $0xe,%edx
f010263a:	89 c7                	mov    %eax,%edi
f010263c:	89 de                	mov    %ebx,%esi
f010263e:	89 d1                	mov    %edx,%ecx
f0102640:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102642:	8d 95 6a ff ff ff    	lea    -0x96(%ebp),%edx
f0102648:	b9 56 00 00 00       	mov    $0x56,%ecx
f010264d:	b0 00                	mov    $0x0,%al
f010264f:	89 d7                	mov    %edx,%edi
f0102651:	f3 aa                	rep stos %al,%es:(%edi)
	int numOfArgs = 0;
f0102653:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
f010265a:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f010265d:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
f0102663:	50                   	push   %eax
f0102664:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f010266a:	50                   	push   %eax
f010266b:	68 39 77 10 f0       	push   $0xf0107739
f0102670:	8d 85 5c ff ff ff    	lea    -0xa4(%ebp),%eax
f0102676:	50                   	push   %eax
f0102677:	e8 a3 3d 00 00       	call   f010641f <strsplit>
f010267c:	83 c4 10             	add    $0x10,%esp

	int ref1 = frames_info[0x00300000 / PAGE_SIZE].references;
f010267f:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0102684:	05 00 24 00 00       	add    $0x2400,%eax
f0102689:	8b 40 08             	mov    0x8(%eax),%eax
f010268c:	0f b7 c0             	movzwl %ax,%eax
f010268f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uint32 entry = ConnectVirtualToPhysicalFrame(args) ;
f0102692:	83 ec 0c             	sub    $0xc,%esp
f0102695:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f010269b:	50                   	push   %eax
f010269c:	e8 aa ea ff ff       	call   f010114b <ConnectVirtualToPhysicalFrame>
f01026a1:	83 c4 10             	add    $0x10,%esp
f01026a4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	char *ptr1, *ptr2, *ptr3;
	ptr1 = (char*)0x0; *ptr1 = 'A' ;
f01026a7:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01026ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01026b1:	c6 00 41             	movb   $0x41,(%eax)
	int ref2 = frames_info[0x00300000 / PAGE_SIZE].references;
f01026b4:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f01026b9:	05 00 24 00 00       	add    $0x2400,%eax
f01026be:	8b 40 08             	mov    0x8(%eax),%eax
f01026c1:	0f b7 c0             	movzwl %ax,%eax
f01026c4:	89 45 d8             	mov    %eax,-0x28(%ebp)

	if ((ref2 - ref1) != 0)
f01026c7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01026ca:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f01026cd:	74 1a                	je     f01026e9 <TestAss1Q2+0xcb>
	{
		cprintf("Test1: Failed. You should manually implement the connection logic using paging data structures ONLY. [DON'T update the references]. Evaluation = 0\n");
f01026cf:	83 ec 0c             	sub    $0xc,%esp
f01026d2:	68 c8 78 10 f0       	push   $0xf01078c8
f01026d7:	e8 a9 23 00 00       	call   f0104a85 <cprintf>
f01026dc:	83 c4 10             	add    $0x10,%esp
		return 0;
f01026df:	b8 00 00 00 00       	mov    $0x0,%eax
f01026e4:	e9 1b 02 00 00       	jmp    f0102904 <TestAss1Q2+0x2e6>
	}

	uint32 f = entry & 0xFFFFF000 ;
f01026e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01026ec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (*ptr1 != 'A' || (f != 0x00300000) || ((entry & PERM_WRITEABLE) == 0))
f01026f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01026f7:	8a 00                	mov    (%eax),%al
f01026f9:	3c 41                	cmp    $0x41,%al
f01026fb:	75 13                	jne    f0102710 <TestAss1Q2+0xf2>
f01026fd:	81 7d d4 00 00 30 00 	cmpl   $0x300000,-0x2c(%ebp)
f0102704:	75 0a                	jne    f0102710 <TestAss1Q2+0xf2>
f0102706:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102709:	83 e0 02             	and    $0x2,%eax
f010270c:	85 c0                	test   %eax,%eax
f010270e:	75 1a                	jne    f010272a <TestAss1Q2+0x10c>
	{
		cprintf("Test2: Failed. Evaluation = 0\n");
f0102710:	83 ec 0c             	sub    $0xc,%esp
f0102713:	68 5c 79 10 f0       	push   $0xf010795c
f0102718:	e8 68 23 00 00       	call   f0104a85 <cprintf>
f010271d:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102720:	b8 00 00 00 00       	mov    $0x0,%eax
f0102725:	e9 da 01 00 00       	jmp    f0102904 <TestAss1Q2+0x2e6>
	}

	//Connect with read permission on same pa
	char cr2[100] = "cvp 0x00004000 768 r";
f010272a:	8d 85 b4 fe ff ff    	lea    -0x14c(%ebp),%eax
f0102730:	bb 3d 7b 10 f0       	mov    $0xf0107b3d,%ebx
f0102735:	ba 15 00 00 00       	mov    $0x15,%edx
f010273a:	89 c7                	mov    %eax,%edi
f010273c:	89 de                	mov    %ebx,%esi
f010273e:	89 d1                	mov    %edx,%ecx
f0102740:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102742:	8d 95 c9 fe ff ff    	lea    -0x137(%ebp),%edx
f0102748:	b9 4f 00 00 00       	mov    $0x4f,%ecx
f010274d:	b0 00                	mov    $0x0,%al
f010274f:	89 d7                	mov    %edx,%edi
f0102751:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f0102753:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
f0102759:	50                   	push   %eax
f010275a:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f0102760:	50                   	push   %eax
f0102761:	68 39 77 10 f0       	push   $0xf0107739
f0102766:	8d 85 b4 fe ff ff    	lea    -0x14c(%ebp),%eax
f010276c:	50                   	push   %eax
f010276d:	e8 ad 3c 00 00       	call   f010641f <strsplit>
f0102772:	83 c4 10             	add    $0x10,%esp

	entry = ConnectVirtualToPhysicalFrame(args) ;
f0102775:	83 ec 0c             	sub    $0xc,%esp
f0102778:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f010277e:	50                   	push   %eax
f010277f:	e8 c7 e9 ff ff       	call   f010114b <ConnectVirtualToPhysicalFrame>
f0102784:	83 c4 10             	add    $0x10,%esp
f0102787:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ptr2 = (char*)0x00004000;
f010278a:	c7 45 d0 00 40 00 00 	movl   $0x4000,-0x30(%ebp)

	int ref3 = frames_info[0x00300000 / PAGE_SIZE].references;
f0102791:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0102796:	05 00 24 00 00       	add    $0x2400,%eax
f010279b:	8b 40 08             	mov    0x8(%eax),%eax
f010279e:	0f b7 c0             	movzwl %ax,%eax
f01027a1:	89 45 cc             	mov    %eax,-0x34(%ebp)

	if ((ref3 - ref2) != 0)
f01027a4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027a7:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f01027aa:	74 1a                	je     f01027c6 <TestAss1Q2+0x1a8>
	{
		cprintf("Test3: Failed. You should manually implement the connection logic using paging data structures ONLY. [DON'T update the references]. Evaluation = 0.25\n");
f01027ac:	83 ec 0c             	sub    $0xc,%esp
f01027af:	68 7c 79 10 f0       	push   $0xf010797c
f01027b4:	e8 cc 22 00 00       	call   f0104a85 <cprintf>
f01027b9:	83 c4 10             	add    $0x10,%esp
		return 0;
f01027bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01027c1:	e9 3e 01 00 00       	jmp    f0102904 <TestAss1Q2+0x2e6>
	}

	f = entry & 0xFFFFF000 ;
f01027c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (*ptr1 != 'A' || *ptr2 != 'A' || (f != 0x00300000) || ((entry & PERM_WRITEABLE) != 0))
f01027d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027d4:	8a 00                	mov    (%eax),%al
f01027d6:	3c 41                	cmp    $0x41,%al
f01027d8:	75 1c                	jne    f01027f6 <TestAss1Q2+0x1d8>
f01027da:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01027dd:	8a 00                	mov    (%eax),%al
f01027df:	3c 41                	cmp    $0x41,%al
f01027e1:	75 13                	jne    f01027f6 <TestAss1Q2+0x1d8>
f01027e3:	81 7d d4 00 00 30 00 	cmpl   $0x300000,-0x2c(%ebp)
f01027ea:	75 0a                	jne    f01027f6 <TestAss1Q2+0x1d8>
f01027ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027ef:	83 e0 02             	and    $0x2,%eax
f01027f2:	85 c0                	test   %eax,%eax
f01027f4:	74 1a                	je     f0102810 <TestAss1Q2+0x1f2>
	{
		cprintf("Test4: Failed. Evaluation = 0.5\n");
f01027f6:	83 ec 0c             	sub    $0xc,%esp
f01027f9:	68 14 7a 10 f0       	push   $0xf0107a14
f01027fe:	e8 82 22 00 00       	call   f0104a85 <cprintf>
f0102803:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102806:	b8 00 00 00 00       	mov    $0x0,%eax
f010280b:	e9 f4 00 00 00       	jmp    f0102904 <TestAss1Q2+0x2e6>
	}

	//Connect with write permission on already connected page
	char cr3[100] = "cvp 0x00004000 1024 w";
f0102810:	8d 85 50 fe ff ff    	lea    -0x1b0(%ebp),%eax
f0102816:	bb a1 7b 10 f0       	mov    $0xf0107ba1,%ebx
f010281b:	ba 16 00 00 00       	mov    $0x16,%edx
f0102820:	89 c7                	mov    %eax,%edi
f0102822:	89 de                	mov    %ebx,%esi
f0102824:	89 d1                	mov    %edx,%ecx
f0102826:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102828:	8d 95 66 fe ff ff    	lea    -0x19a(%ebp),%edx
f010282e:	b9 4e 00 00 00       	mov    $0x4e,%ecx
f0102833:	b0 00                	mov    $0x0,%al
f0102835:	89 d7                	mov    %edx,%edi
f0102837:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f0102839:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
f010283f:	50                   	push   %eax
f0102840:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f0102846:	50                   	push   %eax
f0102847:	68 39 77 10 f0       	push   $0xf0107739
f010284c:	8d 85 50 fe ff ff    	lea    -0x1b0(%ebp),%eax
f0102852:	50                   	push   %eax
f0102853:	e8 c7 3b 00 00       	call   f010641f <strsplit>
f0102858:	83 c4 10             	add    $0x10,%esp
	int r1 = frames_info[0x00400000 / PAGE_SIZE].references;
f010285b:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0102860:	05 00 30 00 00       	add    $0x3000,%eax
f0102865:	8b 40 08             	mov    0x8(%eax),%eax
f0102868:	0f b7 c0             	movzwl %ax,%eax
f010286b:	89 45 c8             	mov    %eax,-0x38(%ebp)

	entry = ConnectVirtualToPhysicalFrame(args) ;
f010286e:	83 ec 0c             	sub    $0xc,%esp
f0102871:	8d 85 18 ff ff ff    	lea    -0xe8(%ebp),%eax
f0102877:	50                   	push   %eax
f0102878:	e8 ce e8 ff ff       	call   f010114b <ConnectVirtualToPhysicalFrame>
f010287d:	83 c4 10             	add    $0x10,%esp
f0102880:	89 45 e0             	mov    %eax,-0x20(%ebp)

	ptr2 = (char*)0x00004000; *ptr2 = 'B';
f0102883:	c7 45 d0 00 40 00 00 	movl   $0x4000,-0x30(%ebp)
f010288a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010288d:	c6 00 42             	movb   $0x42,(%eax)

	int ref4 = frames_info[0x00300000 / PAGE_SIZE].references;
f0102890:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0102895:	05 00 24 00 00       	add    $0x2400,%eax
f010289a:	8b 40 08             	mov    0x8(%eax),%eax
f010289d:	0f b7 c0             	movzwl %ax,%eax
f01028a0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	int r2 = frames_info[0x00400000 / PAGE_SIZE].references;
f01028a3:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f01028a8:	05 00 30 00 00       	add    $0x3000,%eax
f01028ad:	8b 40 08             	mov    0x8(%eax),%eax
f01028b0:	0f b7 c0             	movzwl %ax,%eax
f01028b3:	89 45 c0             	mov    %eax,-0x40(%ebp)

	if (*ptr1 != 'A' || *ptr2 != 'B' || (ref4 - ref1) != 0 || (r2 - r1) != 0)
f01028b6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028b9:	8a 00                	mov    (%eax),%al
f01028bb:	3c 41                	cmp    $0x41,%al
f01028bd:	75 19                	jne    f01028d8 <TestAss1Q2+0x2ba>
f01028bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01028c2:	8a 00                	mov    (%eax),%al
f01028c4:	3c 42                	cmp    $0x42,%al
f01028c6:	75 10                	jne    f01028d8 <TestAss1Q2+0x2ba>
f01028c8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01028cb:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f01028ce:	75 08                	jne    f01028d8 <TestAss1Q2+0x2ba>
f01028d0:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01028d3:	3b 45 c8             	cmp    -0x38(%ebp),%eax
f01028d6:	74 17                	je     f01028ef <TestAss1Q2+0x2d1>
	{
		cprintf("Test5: Failed [DON'T USE MAP_FRAME()! Implement the connection by yourself]. Evaluation = 0.5\n");
f01028d8:	83 ec 0c             	sub    $0xc,%esp
f01028db:	68 38 7a 10 f0       	push   $0xf0107a38
f01028e0:	e8 a0 21 00 00       	call   f0104a85 <cprintf>
f01028e5:	83 c4 10             	add    $0x10,%esp
		return 0;
f01028e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01028ed:	eb 15                	jmp    f0102904 <TestAss1Q2+0x2e6>
	}

	cprintf("[EVAL] ConnectVirtualToPhysicalFrame: Succeeded. Evaluation = 1\n");
f01028ef:	83 ec 0c             	sub    $0xc,%esp
f01028f2:	68 98 7a 10 f0       	push   $0xf0107a98
f01028f7:	e8 89 21 00 00       	call   f0104a85 <cprintf>
f01028fc:	83 c4 10             	add    $0x10,%esp

	return 0;
f01028ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102904:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102907:	5b                   	pop    %ebx
f0102908:	5e                   	pop    %esi
f0102909:	5f                   	pop    %edi
f010290a:	5d                   	pop    %ebp
f010290b:	c3                   	ret    

f010290c <TestAss1Q3>:

int TestAss1Q3()
{
f010290c:	55                   	push   %ebp
f010290d:	89 e5                	mov    %esp,%ebp
f010290f:	57                   	push   %edi
f0102910:	56                   	push   %esi
f0102911:	53                   	push   %ebx
f0102912:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
	int i = 0;
f0102918:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	//Not modified range
	char cr1[100] = "cmps 0xF0000000 0xF0005000";
f010291f:	8d 85 78 ff ff ff    	lea    -0x88(%ebp),%eax
f0102925:	bb 45 7d 10 f0       	mov    $0xf0107d45,%ebx
f010292a:	ba 1b 00 00 00       	mov    $0x1b,%edx
f010292f:	89 c7                	mov    %eax,%edi
f0102931:	89 de                	mov    %ebx,%esi
f0102933:	89 d1                	mov    %edx,%ecx
f0102935:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102937:	8d 55 93             	lea    -0x6d(%ebp),%edx
f010293a:	b9 49 00 00 00       	mov    $0x49,%ecx
f010293f:	b0 00                	mov    $0x0,%al
f0102941:	89 d7                	mov    %edx,%edi
f0102943:	f3 aa                	rep stos %al,%es:(%edi)
	int numOfArgs = 0;
f0102945:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
f010294c:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f010294f:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
f0102955:	50                   	push   %eax
f0102956:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f010295c:	50                   	push   %eax
f010295d:	68 39 77 10 f0       	push   $0xf0107739
f0102962:	8d 85 78 ff ff ff    	lea    -0x88(%ebp),%eax
f0102968:	50                   	push   %eax
f0102969:	e8 b1 3a 00 00       	call   f010641f <strsplit>
f010296e:	83 c4 10             	add    $0x10,%esp

	int cnt = CountModifiedPagesInRange(args) ;
f0102971:	83 ec 0c             	sub    $0xc,%esp
f0102974:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f010297a:	50                   	push   %eax
f010297b:	e8 12 ea ff ff       	call   f0101392 <CountModifiedPagesInRange>
f0102980:	83 c4 10             	add    $0x10,%esp
f0102983:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (cnt != 0)
f0102986:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010298a:	74 1a                	je     f01029a6 <TestAss1Q3+0x9a>
	{
		cprintf("[EVAL] #1 CntModPages: Failed. Evaluation = 0\n");
f010298c:	83 ec 0c             	sub    $0xc,%esp
f010298f:	68 08 7c 10 f0       	push   $0xf0107c08
f0102994:	e8 ec 20 00 00       	call   f0104a85 <cprintf>
f0102999:	83 c4 10             	add    $0x10,%esp
		return 0;
f010299c:	b8 00 00 00 00       	mov    $0x0,%eax
f01029a1:	e9 ae 02 00 00       	jmp    f0102c54 <TestAss1Q3+0x348>
	}

	//Modify 3 pages in the range
	char *ptr ;
	ptr = (char*)0xF0000000 ; *ptr = 'A';
f01029a6:	c7 45 dc 00 00 00 f0 	movl   $0xf0000000,-0x24(%ebp)
f01029ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029b0:	c6 00 41             	movb   $0x41,(%eax)
	ptr = (char*)0xF0000005 ; *ptr = 'B';
f01029b3:	c7 45 dc 05 00 00 f0 	movl   $0xf0000005,-0x24(%ebp)
f01029ba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029bd:	c6 00 42             	movb   $0x42,(%eax)
	ptr = (char*)0xF0003000 ; *ptr = 'C';
f01029c0:	c7 45 dc 00 30 00 f0 	movl   $0xf0003000,-0x24(%ebp)
f01029c7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029ca:	c6 00 43             	movb   $0x43,(%eax)
	ptr = (char*)0xF0004FFF ; *ptr = 'D';
f01029cd:	c7 45 dc ff 4f 00 f0 	movl   $0xf0004fff,-0x24(%ebp)
f01029d4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029d7:	c6 00 44             	movb   $0x44,(%eax)

	char cr2[100] = "cmps 0xF0000000 0xF0005000";
f01029da:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
f01029e0:	bb 45 7d 10 f0       	mov    $0xf0107d45,%ebx
f01029e5:	ba 1b 00 00 00       	mov    $0x1b,%edx
f01029ea:	89 c7                	mov    %eax,%edi
f01029ec:	89 de                	mov    %ebx,%esi
f01029ee:	89 d1                	mov    %edx,%ecx
f01029f0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01029f2:	8d 95 eb fe ff ff    	lea    -0x115(%ebp),%edx
f01029f8:	b9 49 00 00 00       	mov    $0x49,%ecx
f01029fd:	b0 00                	mov    $0x0,%al
f01029ff:	89 d7                	mov    %edx,%edi
f0102a01:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f0102a03:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
f0102a09:	50                   	push   %eax
f0102a0a:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102a10:	50                   	push   %eax
f0102a11:	68 39 77 10 f0       	push   $0xf0107739
f0102a16:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	e8 fd 39 00 00       	call   f010641f <strsplit>
f0102a22:	83 c4 10             	add    $0x10,%esp

	cnt = CountModifiedPagesInRange(args) ;
f0102a25:	83 ec 0c             	sub    $0xc,%esp
f0102a28:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102a2e:	50                   	push   %eax
f0102a2f:	e8 5e e9 ff ff       	call   f0101392 <CountModifiedPagesInRange>
f0102a34:	83 c4 10             	add    $0x10,%esp
f0102a37:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (cnt != 3)
f0102a3a:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
f0102a3e:	74 1a                	je     f0102a5a <TestAss1Q3+0x14e>
	{
		cprintf("[EVAL] #2 CntModPages: Failed. Evaluation = 0.15\n");
f0102a40:	83 ec 0c             	sub    $0xc,%esp
f0102a43:	68 38 7c 10 f0       	push   $0xf0107c38
f0102a48:	e8 38 20 00 00       	call   f0104a85 <cprintf>
f0102a4d:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102a50:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a55:	e9 fa 01 00 00       	jmp    f0102c54 <TestAss1Q3+0x348>
	}


	//Modify 1 page outside the range
	ptr = (char*)0xF0005000 ; *ptr = 'X';
f0102a5a:	c7 45 dc 00 50 00 f0 	movl   $0xf0005000,-0x24(%ebp)
f0102a61:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a64:	c6 00 58             	movb   $0x58,(%eax)

	char cr3[100] = "cmps 0xF0000000 0xF0005000";
f0102a67:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
f0102a6d:	bb 45 7d 10 f0       	mov    $0xf0107d45,%ebx
f0102a72:	ba 1b 00 00 00       	mov    $0x1b,%edx
f0102a77:	89 c7                	mov    %eax,%edi
f0102a79:	89 de                	mov    %ebx,%esi
f0102a7b:	89 d1                	mov    %edx,%ecx
f0102a7d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102a7f:	8d 95 87 fe ff ff    	lea    -0x179(%ebp),%edx
f0102a85:	b9 49 00 00 00       	mov    $0x49,%ecx
f0102a8a:	b0 00                	mov    $0x0,%al
f0102a8c:	89 d7                	mov    %edx,%edi
f0102a8e:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f0102a90:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
f0102a96:	50                   	push   %eax
f0102a97:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102a9d:	50                   	push   %eax
f0102a9e:	68 39 77 10 f0       	push   $0xf0107739
f0102aa3:	8d 85 6c fe ff ff    	lea    -0x194(%ebp),%eax
f0102aa9:	50                   	push   %eax
f0102aaa:	e8 70 39 00 00       	call   f010641f <strsplit>
f0102aaf:	83 c4 10             	add    $0x10,%esp

	cnt = CountModifiedPagesInRange(args) ;
f0102ab2:	83 ec 0c             	sub    $0xc,%esp
f0102ab5:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102abb:	50                   	push   %eax
f0102abc:	e8 d1 e8 ff ff       	call   f0101392 <CountModifiedPagesInRange>
f0102ac1:	83 c4 10             	add    $0x10,%esp
f0102ac4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (cnt != 3)
f0102ac7:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
f0102acb:	74 1a                	je     f0102ae7 <TestAss1Q3+0x1db>
	{
		cprintf("[EVAL] #3 CntModPages: Failed. Evaluation = 0.30\n");
f0102acd:	83 ec 0c             	sub    $0xc,%esp
f0102ad0:	68 6c 7c 10 f0       	push   $0xf0107c6c
f0102ad5:	e8 ab 1f 00 00       	call   f0104a85 <cprintf>
f0102ada:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102add:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae2:	e9 6d 01 00 00       	jmp    f0102c54 <TestAss1Q3+0x348>
	}

	//range across multiple tables
	ptr = (char*)0xF03FF000 ; *ptr = 'A';
f0102ae7:	c7 45 dc 00 f0 3f f0 	movl   $0xf03ff000,-0x24(%ebp)
f0102aee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102af1:	c6 00 41             	movb   $0x41,(%eax)
	ptr = (char*)0xF0405000 ; *ptr = 'B';
f0102af4:	c7 45 dc 00 50 40 f0 	movl   $0xf0405000,-0x24(%ebp)
f0102afb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102afe:	c6 00 42             	movb   $0x42,(%eax)
	ptr = (char*)0xF0900000 ; *ptr = 'C';
f0102b01:	c7 45 dc 00 00 90 f0 	movl   $0xf0900000,-0x24(%ebp)
f0102b08:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b0b:	c6 00 43             	movb   $0x43,(%eax)
	ptr = (char*)0xF0903000 ; *ptr = 'D';
f0102b0e:	c7 45 dc 00 30 90 f0 	movl   $0xf0903000,-0x24(%ebp)
f0102b15:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b18:	c6 00 44             	movb   $0x44,(%eax)
	ptr = (char*)0xF0904000 ; *ptr = 'E';
f0102b1b:	c7 45 dc 00 40 90 f0 	movl   $0xf0904000,-0x24(%ebp)
f0102b22:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b25:	c6 00 45             	movb   $0x45,(%eax)
	ptr = (char*)0xF0905000 ; *ptr = 'X';
f0102b28:	c7 45 dc 00 50 90 f0 	movl   $0xf0905000,-0x24(%ebp)
f0102b2f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b32:	c6 00 58             	movb   $0x58,(%eax)

	char cr4[100] = "cmps 0xF03FF000 0xF0905000";
f0102b35:	8d 85 08 fe ff ff    	lea    -0x1f8(%ebp),%eax
f0102b3b:	bb a9 7d 10 f0       	mov    $0xf0107da9,%ebx
f0102b40:	ba 1b 00 00 00       	mov    $0x1b,%edx
f0102b45:	89 c7                	mov    %eax,%edi
f0102b47:	89 de                	mov    %ebx,%esi
f0102b49:	89 d1                	mov    %edx,%ecx
f0102b4b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102b4d:	8d 95 23 fe ff ff    	lea    -0x1dd(%ebp),%edx
f0102b53:	b9 49 00 00 00       	mov    $0x49,%ecx
f0102b58:	b0 00                	mov    $0x0,%al
f0102b5a:	89 d7                	mov    %edx,%edi
f0102b5c:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;
f0102b5e:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
f0102b64:	50                   	push   %eax
f0102b65:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102b6b:	50                   	push   %eax
f0102b6c:	68 39 77 10 f0       	push   $0xf0107739
f0102b71:	8d 85 08 fe ff ff    	lea    -0x1f8(%ebp),%eax
f0102b77:	50                   	push   %eax
f0102b78:	e8 a2 38 00 00       	call   f010641f <strsplit>
f0102b7d:	83 c4 10             	add    $0x10,%esp

	cnt = CountModifiedPagesInRange(args) ;
f0102b80:	83 ec 0c             	sub    $0xc,%esp
f0102b83:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102b89:	50                   	push   %eax
f0102b8a:	e8 03 e8 ff ff       	call   f0101392 <CountModifiedPagesInRange>
f0102b8f:	83 c4 10             	add    $0x10,%esp
f0102b92:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (cnt != 5)
f0102b95:	83 7d e0 05          	cmpl   $0x5,-0x20(%ebp)
f0102b99:	74 1a                	je     f0102bb5 <TestAss1Q3+0x2a9>
	{
		cprintf("[EVAL] #4 CntModPages: Failed. Evaluation = 0.45\n");
f0102b9b:	83 ec 0c             	sub    $0xc,%esp
f0102b9e:	68 a0 7c 10 f0       	push   $0xf0107ca0
f0102ba3:	e8 dd 1e 00 00       	call   f0104a85 <cprintf>
f0102ba8:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102bab:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb0:	e9 9f 00 00 00       	jmp    f0102c54 <TestAss1Q3+0x348>
	}

	//range across multiple tables & not on page boundary
	ptr = (char*)0xF0403333 ; *ptr = 'X';
f0102bb5:	c7 45 dc 33 33 40 f0 	movl   $0xf0403333,-0x24(%ebp)
f0102bbc:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102bbf:	c6 00 58             	movb   $0x58,(%eax)

	char cr5[100] = "cmps 0xF03FFFF0 0xF040500F";
f0102bc2:	8d 85 a4 fd ff ff    	lea    -0x25c(%ebp),%eax
f0102bc8:	bb 0d 7e 10 f0       	mov    $0xf0107e0d,%ebx
f0102bcd:	ba 1b 00 00 00       	mov    $0x1b,%edx
f0102bd2:	89 c7                	mov    %eax,%edi
f0102bd4:	89 de                	mov    %ebx,%esi
f0102bd6:	89 d1                	mov    %edx,%ecx
f0102bd8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102bda:	8d 95 bf fd ff ff    	lea    -0x241(%ebp),%edx
f0102be0:	b9 49 00 00 00       	mov    $0x49,%ecx
f0102be5:	b0 00                	mov    $0x0,%al
f0102be7:	89 d7                	mov    %edx,%edi
f0102be9:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;
f0102beb:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
f0102bf1:	50                   	push   %eax
f0102bf2:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102bf8:	50                   	push   %eax
f0102bf9:	68 39 77 10 f0       	push   $0xf0107739
f0102bfe:	8d 85 a4 fd ff ff    	lea    -0x25c(%ebp),%eax
f0102c04:	50                   	push   %eax
f0102c05:	e8 15 38 00 00       	call   f010641f <strsplit>
f0102c0a:	83 c4 10             	add    $0x10,%esp

	cnt = CountModifiedPagesInRange(args) ;
f0102c0d:	83 ec 0c             	sub    $0xc,%esp
f0102c10:	8d 85 34 ff ff ff    	lea    -0xcc(%ebp),%eax
f0102c16:	50                   	push   %eax
f0102c17:	e8 76 e7 ff ff       	call   f0101392 <CountModifiedPagesInRange>
f0102c1c:	83 c4 10             	add    $0x10,%esp
f0102c1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (cnt != 3)
f0102c22:	83 7d e0 03          	cmpl   $0x3,-0x20(%ebp)
f0102c26:	74 17                	je     f0102c3f <TestAss1Q3+0x333>
	{
		cprintf("[EVAL] #5 CntModPages: Failed. Evaluation = 0.70\n");
f0102c28:	83 ec 0c             	sub    $0xc,%esp
f0102c2b:	68 d4 7c 10 f0       	push   $0xf0107cd4
f0102c30:	e8 50 1e 00 00       	call   f0104a85 <cprintf>
f0102c35:	83 c4 10             	add    $0x10,%esp
		return 0;
f0102c38:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c3d:	eb 15                	jmp    f0102c54 <TestAss1Q3+0x348>
	}

	cprintf("[EVAL] CountModifiedPagesInRange: Succeeded. Evaluation = 1\n");
f0102c3f:	83 ec 0c             	sub    $0xc,%esp
f0102c42:	68 08 7d 10 f0       	push   $0xf0107d08
f0102c47:	e8 39 1e 00 00       	call   f0104a85 <cprintf>
f0102c4c:	83 c4 10             	add    $0x10,%esp

	return 0;
f0102c4f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c54:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c57:	5b                   	pop    %ebx
f0102c58:	5e                   	pop    %esi
f0102c59:	5f                   	pop    %edi
f0102c5a:	5d                   	pop    %ebp
f0102c5b:	c3                   	ret    

f0102c5c <TestAss1Q4>:

int TestAss1Q4()
{
f0102c5c:	55                   	push   %ebp
f0102c5d:	89 e5                	mov    %esp,%ebp
f0102c5f:	57                   	push   %edi
f0102c60:	56                   	push   %esi
f0102c61:	53                   	push   %ebx
f0102c62:	81 ec ec 04 00 00    	sub    $0x4ec,%esp
	int eval = 0;
f0102c68:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	char *ptr1, *ptr2, *ptr3, *ptr4, *ptr5, *ptr6, *ptr7;
	int kilo = 1024;
f0102c6f:	c7 45 dc 00 04 00 00 	movl   $0x400,-0x24(%ebp)
	int mega = 1024 * 1024;
f0102c76:	c7 45 d8 00 00 10 00 	movl   $0x100000,-0x28(%ebp)

	ClearUserSpace();
f0102c7d:	e8 3d 0a 00 00       	call   f01036bf <ClearUserSpace>
	cprintf("\nPART I: [COPY] Destination page exists [25% MARK]\n");
f0102c82:	83 ec 0c             	sub    $0xc,%esp
f0102c85:	68 74 7e 10 f0       	push   $0xf0107e74
f0102c8a:	e8 f6 1d 00 00       	call   f0104a85 <cprintf>
f0102c8f:	83 c4 10             	add    $0x10,%esp
	//=================================================
	//PART I: [COPY] Destination page exists [25% MARK]
	//=================================================
	char ap1[100] = "ap 0x500000";
f0102c92:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
f0102c98:	bb b9 81 10 f0       	mov    $0xf01081b9,%ebx
f0102c9d:	ba 03 00 00 00       	mov    $0x3,%edx
f0102ca2:	89 c7                	mov    %eax,%edi
f0102ca4:	89 de                	mov    %ebx,%esi
f0102ca6:	89 d1                	mov    %edx,%ecx
f0102ca8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102caa:	8d 95 4c ff ff ff    	lea    -0xb4(%ebp),%edx
f0102cb0:	b9 16 00 00 00       	mov    $0x16,%ecx
f0102cb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cba:	89 d7                	mov    %edx,%edi
f0102cbc:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap1);
f0102cbe:	83 ec 0c             	sub    $0xc,%esp
f0102cc1:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
f0102cc7:	50                   	push   %eax
f0102cc8:	e8 ea dc ff ff       	call   f01009b7 <execute_command>
f0102ccd:	83 c4 10             	add    $0x10,%esp

	ptr1 = (char*) 0x500000;
f0102cd0:	c7 45 d4 00 00 50 00 	movl   $0x500000,-0x2c(%ebp)
	*ptr1 = 'a';
f0102cd7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cda:	c6 00 61             	movb   $0x61,(%eax)
	ptr1 = (char*) 0x500100;
f0102cdd:	c7 45 d4 00 01 50 00 	movl   $0x500100,-0x2c(%ebp)
	*ptr1 = 'b';
f0102ce4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ce7:	c6 00 62             	movb   $0x62,(%eax)
	ptr1 = (char*) 0x500FFF;
f0102cea:	c7 45 d4 ff 0f 50 00 	movl   $0x500fff,-0x2c(%ebp)
	*ptr1 = 'c';
f0102cf1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cf4:	c6 00 63             	movb   $0x63,(%eax)
	char ap2[100] = "ap 0x502000";
f0102cf7:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
f0102cfd:	bb 1d 82 10 f0       	mov    $0xf010821d,%ebx
f0102d02:	ba 03 00 00 00       	mov    $0x3,%edx
f0102d07:	89 c7                	mov    %eax,%edi
f0102d09:	89 de                	mov    %ebx,%esi
f0102d0b:	89 d1                	mov    %edx,%ecx
f0102d0d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102d0f:	8d 95 e8 fe ff ff    	lea    -0x118(%ebp),%edx
f0102d15:	b9 16 00 00 00       	mov    $0x16,%ecx
f0102d1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d1f:	89 d7                	mov    %edx,%edi
f0102d21:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap2);
f0102d23:	83 ec 0c             	sub    $0xc,%esp
f0102d26:	8d 85 dc fe ff ff    	lea    -0x124(%ebp),%eax
f0102d2c:	50                   	push   %eax
f0102d2d:	e8 85 dc ff ff       	call   f01009b7 <execute_command>
f0102d32:	83 c4 10             	add    $0x10,%esp
	uint32 *ptr_table;
	struct Frame_Info *srcFI1 = get_frame_info(ptr_page_directory, (void*)0x500000, &ptr_table);
f0102d35:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102d3a:	83 ec 04             	sub    $0x4,%esp
f0102d3d:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0102d43:	52                   	push   %edx
f0102d44:	68 00 00 50 00       	push   $0x500000
f0102d49:	50                   	push   %eax
f0102d4a:	e8 3d 13 00 00       	call   f010408c <get_frame_info>
f0102d4f:	83 c4 10             	add    $0x10,%esp
f0102d52:	89 45 d0             	mov    %eax,-0x30(%ebp)
	struct Frame_Info *dstFI1 = get_frame_info(ptr_page_directory, (void*)0x502000, &ptr_table);
f0102d55:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102d5a:	83 ec 04             	sub    $0x4,%esp
f0102d5d:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0102d63:	52                   	push   %edx
f0102d64:	68 00 20 50 00       	push   $0x502000
f0102d69:	50                   	push   %eax
f0102d6a:	e8 1d 13 00 00       	call   f010408c <get_frame_info>
f0102d6f:	83 c4 10             	add    $0x10,%esp
f0102d72:	89 45 cc             	mov    %eax,-0x34(%ebp)

	int ff1 = calculate_free_frames();
f0102d75:	e8 1b 14 00 00       	call   f0104195 <calculate_free_frames>
f0102d7a:	89 45 c8             	mov    %eax,-0x38(%ebp)

	char cmd1[100] = "tup 0x500000 0x502000 c";
f0102d7d:	8d 85 74 fe ff ff    	lea    -0x18c(%ebp),%eax
f0102d83:	bb 81 82 10 f0       	mov    $0xf0108281,%ebx
f0102d88:	ba 06 00 00 00       	mov    $0x6,%edx
f0102d8d:	89 c7                	mov    %eax,%edi
f0102d8f:	89 de                	mov    %ebx,%esi
f0102d91:	89 d1                	mov    %edx,%ecx
f0102d93:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102d95:	8d 95 8c fe ff ff    	lea    -0x174(%ebp),%edx
f0102d9b:	b9 13 00 00 00       	mov    $0x13,%ecx
f0102da0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102da5:	89 d7                	mov    %edx,%edi
f0102da7:	f3 ab                	rep stos %eax,%es:(%edi)
	int numOfArgs = 0;
f0102da9:	c7 85 70 fe ff ff 00 	movl   $0x0,-0x190(%ebp)
f0102db0:	00 00 00 
	char *args[MAX_ARGUMENTS];
	strsplit(cmd1, WHITESPACE, args, &numOfArgs);
f0102db3:	8d 85 70 fe ff ff    	lea    -0x190(%ebp),%eax
f0102db9:	50                   	push   %eax
f0102dba:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0102dc0:	50                   	push   %eax
f0102dc1:	68 39 77 10 f0       	push   $0xf0107739
f0102dc6:	8d 85 74 fe ff ff    	lea    -0x18c(%ebp),%eax
f0102dcc:	50                   	push   %eax
f0102dcd:	e8 4d 36 00 00       	call   f010641f <strsplit>
f0102dd2:	83 c4 10             	add    $0x10,%esp
	TransferUserPage(args);
f0102dd5:	83 ec 0c             	sub    $0xc,%esp
f0102dd8:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0102dde:	50                   	push   %eax
f0102ddf:	e8 6d e6 ff ff       	call   f0101451 <TransferUserPage>
f0102de4:	83 c4 10             	add    $0x10,%esp
	int ff2 = calculate_free_frames();
f0102de7:	e8 a9 13 00 00       	call   f0104195 <calculate_free_frames>
f0102dec:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	struct Frame_Info *srcFI2 = get_frame_info(ptr_page_directory, (void*)0x500000, &ptr_table);
f0102def:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102df4:	83 ec 04             	sub    $0x4,%esp
f0102df7:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0102dfd:	52                   	push   %edx
f0102dfe:	68 00 00 50 00       	push   $0x500000
f0102e03:	50                   	push   %eax
f0102e04:	e8 83 12 00 00       	call   f010408c <get_frame_info>
f0102e09:	83 c4 10             	add    $0x10,%esp
f0102e0c:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct Frame_Info *dstFI2 = get_frame_info(ptr_page_directory, (void*)0x502000, &ptr_table);
f0102e0f:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0102e14:	83 ec 04             	sub    $0x4,%esp
f0102e17:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0102e1d:	52                   	push   %edx
f0102e1e:	68 00 20 50 00       	push   $0x502000
f0102e23:	50                   	push   %eax
f0102e24:	e8 63 12 00 00       	call   f010408c <get_frame_info>
f0102e29:	83 c4 10             	add    $0x10,%esp
f0102e2c:	89 45 bc             	mov    %eax,-0x44(%ebp)

	int failed = 0;
f0102e2f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (ff1 != ff2 || srcFI1 != srcFI2 || dstFI1 != dstFI2) {
f0102e36:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102e39:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
f0102e3c:	75 10                	jne    f0102e4e <TestAss1Q4+0x1f2>
f0102e3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102e41:	3b 45 c0             	cmp    -0x40(%ebp),%eax
f0102e44:	75 08                	jne    f0102e4e <TestAss1Q4+0x1f2>
f0102e46:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102e49:	3b 45 bc             	cmp    -0x44(%ebp),%eax
f0102e4c:	74 17                	je     f0102e65 <TestAss1Q4+0x209>
		cprintf("[EVAL] #0 TransferUserPage: Failed.\n");
f0102e4e:	83 ec 0c             	sub    $0xc,%esp
f0102e51:	68 a8 7e 10 f0       	push   $0xf0107ea8
f0102e56:	e8 2a 1c 00 00       	call   f0104a85 <cprintf>
f0102e5b:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0102e5e:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}

	if (CB(0x500000, 0) != 1 || CB(0x502000, 0) != 1) {
f0102e65:	83 ec 08             	sub    $0x8,%esp
f0102e68:	6a 00                	push   $0x0
f0102e6a:	68 00 00 50 00       	push   $0x500000
f0102e6f:	e8 e3 07 00 00       	call   f0103657 <CB>
f0102e74:	83 c4 10             	add    $0x10,%esp
f0102e77:	83 f8 01             	cmp    $0x1,%eax
f0102e7a:	75 17                	jne    f0102e93 <TestAss1Q4+0x237>
f0102e7c:	83 ec 08             	sub    $0x8,%esp
f0102e7f:	6a 00                	push   $0x0
f0102e81:	68 00 20 50 00       	push   $0x502000
f0102e86:	e8 cc 07 00 00       	call   f0103657 <CB>
f0102e8b:	83 c4 10             	add    $0x10,%esp
f0102e8e:	83 f8 01             	cmp    $0x1,%eax
f0102e91:	74 17                	je     f0102eaa <TestAss1Q4+0x24e>
		cprintf("[EVAL] #1 TransferUserPage: Failed.\n");
f0102e93:	83 ec 0c             	sub    $0xc,%esp
f0102e96:	68 d0 7e 10 f0       	push   $0xf0107ed0
f0102e9b:	e8 e5 1b 00 00       	call   f0104a85 <cprintf>
f0102ea0:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0102ea3:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	ptr1 = (char*) 0x500000;
f0102eaa:	c7 45 d4 00 00 50 00 	movl   $0x500000,-0x2c(%ebp)
	*ptr1 = 'z';
f0102eb1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102eb4:	c6 00 7a             	movb   $0x7a,(%eax)
	ptr2 = (char*) 0x502000;
f0102eb7:	c7 45 b8 00 20 50 00 	movl   $0x502000,-0x48(%ebp)
	ptr3 = (char*) 0x502100;
f0102ebe:	c7 45 b4 00 21 50 00 	movl   $0x502100,-0x4c(%ebp)
	ptr4 = (char*) 0x502FFF;
f0102ec5:	c7 45 b0 ff 2f 50 00 	movl   $0x502fff,-0x50(%ebp)
	if ((*ptr1) != 'z' || (*ptr2) != 'a' || (*ptr3) != 'b' || (*ptr4) != 'c') {
f0102ecc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ecf:	8a 00                	mov    (%eax),%al
f0102ed1:	3c 7a                	cmp    $0x7a,%al
f0102ed3:	75 1b                	jne    f0102ef0 <TestAss1Q4+0x294>
f0102ed5:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0102ed8:	8a 00                	mov    (%eax),%al
f0102eda:	3c 61                	cmp    $0x61,%al
f0102edc:	75 12                	jne    f0102ef0 <TestAss1Q4+0x294>
f0102ede:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0102ee1:	8a 00                	mov    (%eax),%al
f0102ee3:	3c 62                	cmp    $0x62,%al
f0102ee5:	75 09                	jne    f0102ef0 <TestAss1Q4+0x294>
f0102ee7:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0102eea:	8a 00                	mov    (%eax),%al
f0102eec:	3c 63                	cmp    $0x63,%al
f0102eee:	74 17                	je     f0102f07 <TestAss1Q4+0x2ab>
		failed = 1;
f0102ef0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		cprintf("[EVAL] #2 TransferUserPage: Failed.\n");
f0102ef7:	83 ec 0c             	sub    $0xc,%esp
f0102efa:	68 f8 7e 10 f0       	push   $0xf0107ef8
f0102eff:	e8 81 1b 00 00       	call   f0104a85 <cprintf>
f0102f04:	83 c4 10             	add    $0x10,%esp
		//return 0;
	}

	if (failed == 0)
f0102f07:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102f0b:	75 04                	jne    f0102f11 <TestAss1Q4+0x2b5>
		eval += 25;
f0102f0d:	83 45 e4 19          	addl   $0x19,-0x1c(%ebp)
	//ff1 = ff2 ;

	cprintf("\nPART II: [COPY] Destination page NOT exists [25% MARK]\n");
f0102f11:	83 ec 0c             	sub    $0xc,%esp
f0102f14:	68 20 7f 10 f0       	push   $0xf0107f20
f0102f19:	e8 67 1b 00 00       	call   f0104a85 <cprintf>
f0102f1e:	83 c4 10             	add    $0x10,%esp
	//======================================================
	//PART II: [COPY] Destination page NOT exists [25% MARK]
	//======================================================
	char ap3[100] = "ap 0x600000";
f0102f21:	8d 85 cc fd ff ff    	lea    -0x234(%ebp),%eax
f0102f27:	bb e5 82 10 f0       	mov    $0xf01082e5,%ebx
f0102f2c:	ba 03 00 00 00       	mov    $0x3,%edx
f0102f31:	89 c7                	mov    %eax,%edi
f0102f33:	89 de                	mov    %ebx,%esi
f0102f35:	89 d1                	mov    %edx,%ecx
f0102f37:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102f39:	8d 95 d8 fd ff ff    	lea    -0x228(%ebp),%edx
f0102f3f:	b9 16 00 00 00       	mov    $0x16,%ecx
f0102f44:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f49:	89 d7                	mov    %edx,%edi
f0102f4b:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap3);
f0102f4d:	83 ec 0c             	sub    $0xc,%esp
f0102f50:	8d 85 cc fd ff ff    	lea    -0x234(%ebp),%eax
f0102f56:	50                   	push   %eax
f0102f57:	e8 5b da ff ff       	call   f01009b7 <execute_command>
f0102f5c:	83 c4 10             	add    $0x10,%esp

	ptr1 = (char*) 0x600000;
f0102f5f:	c7 45 d4 00 00 60 00 	movl   $0x600000,-0x2c(%ebp)
	*ptr1 = 'a';
f0102f66:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f69:	c6 00 61             	movb   $0x61,(%eax)
	ptr1 = (char*) 0x600100;
f0102f6c:	c7 45 d4 00 01 60 00 	movl   $0x600100,-0x2c(%ebp)
	*ptr1 = 'b';
f0102f73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f76:	c6 00 62             	movb   $0x62,(%eax)
	ptr1 = (char*) 0x600FFF;
f0102f79:	c7 45 d4 ff 0f 60 00 	movl   $0x600fff,-0x2c(%ebp)
	*ptr1 = 'c';
f0102f80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f83:	c6 00 63             	movb   $0x63,(%eax)

	ff1 = calculate_free_frames();
f0102f86:	e8 0a 12 00 00       	call   f0104195 <calculate_free_frames>
f0102f8b:	89 45 c8             	mov    %eax,-0x38(%ebp)

	char cmd2[100] = "tup 0x600000 0x800000 c";
f0102f8e:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
f0102f94:	bb 49 83 10 f0       	mov    $0xf0108349,%ebx
f0102f99:	ba 06 00 00 00       	mov    $0x6,%edx
f0102f9e:	89 c7                	mov    %eax,%edi
f0102fa0:	89 de                	mov    %ebx,%esi
f0102fa2:	89 d1                	mov    %edx,%ecx
f0102fa4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102fa6:	8d 95 80 fd ff ff    	lea    -0x280(%ebp),%edx
f0102fac:	b9 13 00 00 00       	mov    $0x13,%ecx
f0102fb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fb6:	89 d7                	mov    %edx,%edi
f0102fb8:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(cmd2, WHITESPACE, args, &numOfArgs);
f0102fba:	8d 85 70 fe ff ff    	lea    -0x190(%ebp),%eax
f0102fc0:	50                   	push   %eax
f0102fc1:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0102fc7:	50                   	push   %eax
f0102fc8:	68 39 77 10 f0       	push   $0xf0107739
f0102fcd:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
f0102fd3:	50                   	push   %eax
f0102fd4:	e8 46 34 00 00       	call   f010641f <strsplit>
f0102fd9:	83 c4 10             	add    $0x10,%esp

	TransferUserPage(args);
f0102fdc:	83 ec 0c             	sub    $0xc,%esp
f0102fdf:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0102fe5:	50                   	push   %eax
f0102fe6:	e8 66 e4 ff ff       	call   f0101451 <TransferUserPage>
f0102feb:	83 c4 10             	add    $0x10,%esp

	ff2 = calculate_free_frames();
f0102fee:	e8 a2 11 00 00       	call   f0104195 <calculate_free_frames>
f0102ff3:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	failed = 0;
f0102ff6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (ff1 - ff2 != 2) {
f0102ffd:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103000:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f0103003:	83 f8 02             	cmp    $0x2,%eax
f0103006:	74 17                	je     f010301f <TestAss1Q4+0x3c3>
		cprintf("[EVAL] #3 TransferUserPage: Failed.\n");
f0103008:	83 ec 0c             	sub    $0xc,%esp
f010300b:	68 5c 7f 10 f0       	push   $0xf0107f5c
f0103010:	e8 70 1a 00 00       	call   f0104a85 <cprintf>
f0103015:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0103018:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	if (CB(0x600000, 0) != 1 || CB(0x800000, 0) != 1) {
f010301f:	83 ec 08             	sub    $0x8,%esp
f0103022:	6a 00                	push   $0x0
f0103024:	68 00 00 60 00       	push   $0x600000
f0103029:	e8 29 06 00 00       	call   f0103657 <CB>
f010302e:	83 c4 10             	add    $0x10,%esp
f0103031:	83 f8 01             	cmp    $0x1,%eax
f0103034:	75 17                	jne    f010304d <TestAss1Q4+0x3f1>
f0103036:	83 ec 08             	sub    $0x8,%esp
f0103039:	6a 00                	push   $0x0
f010303b:	68 00 00 80 00       	push   $0x800000
f0103040:	e8 12 06 00 00       	call   f0103657 <CB>
f0103045:	83 c4 10             	add    $0x10,%esp
f0103048:	83 f8 01             	cmp    $0x1,%eax
f010304b:	74 17                	je     f0103064 <TestAss1Q4+0x408>
		cprintf("[EVAL] #4 TransferUserPage: Failed.\n");
f010304d:	83 ec 0c             	sub    $0xc,%esp
f0103050:	68 84 7f 10 f0       	push   $0xf0107f84
f0103055:	e8 2b 1a 00 00       	call   f0104a85 <cprintf>
f010305a:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f010305d:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	ff1 = calculate_free_frames();
f0103064:	e8 2c 11 00 00       	call   f0104195 <calculate_free_frames>
f0103069:	89 45 c8             	mov    %eax,-0x38(%ebp)

	char cmd3[100] = "tup 0x600000 0x900000 c";
f010306c:	8d 85 04 fd ff ff    	lea    -0x2fc(%ebp),%eax
f0103072:	bb ad 83 10 f0       	mov    $0xf01083ad,%ebx
f0103077:	ba 06 00 00 00       	mov    $0x6,%edx
f010307c:	89 c7                	mov    %eax,%edi
f010307e:	89 de                	mov    %ebx,%esi
f0103080:	89 d1                	mov    %edx,%ecx
f0103082:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103084:	8d 95 1c fd ff ff    	lea    -0x2e4(%ebp),%edx
f010308a:	b9 13 00 00 00       	mov    $0x13,%ecx
f010308f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103094:	89 d7                	mov    %edx,%edi
f0103096:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(cmd3, WHITESPACE, args, &numOfArgs);
f0103098:	8d 85 70 fe ff ff    	lea    -0x190(%ebp),%eax
f010309e:	50                   	push   %eax
f010309f:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f01030a5:	50                   	push   %eax
f01030a6:	68 39 77 10 f0       	push   $0xf0107739
f01030ab:	8d 85 04 fd ff ff    	lea    -0x2fc(%ebp),%eax
f01030b1:	50                   	push   %eax
f01030b2:	e8 68 33 00 00       	call   f010641f <strsplit>
f01030b7:	83 c4 10             	add    $0x10,%esp

	TransferUserPage(args);
f01030ba:	83 ec 0c             	sub    $0xc,%esp
f01030bd:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f01030c3:	50                   	push   %eax
f01030c4:	e8 88 e3 ff ff       	call   f0101451 <TransferUserPage>
f01030c9:	83 c4 10             	add    $0x10,%esp

	ff2 = calculate_free_frames();
f01030cc:	e8 c4 10 00 00       	call   f0104195 <calculate_free_frames>
f01030d1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if (ff1 - ff2 != 1) {
f01030d4:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01030d7:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f01030da:	83 f8 01             	cmp    $0x1,%eax
f01030dd:	74 17                	je     f01030f6 <TestAss1Q4+0x49a>
		cprintf("[EVAL] #5 TransferUserPage: Failed.\n");
f01030df:	83 ec 0c             	sub    $0xc,%esp
f01030e2:	68 ac 7f 10 f0       	push   $0xf0107fac
f01030e7:	e8 99 19 00 00       	call   f0104a85 <cprintf>
f01030ec:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f01030ef:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	if (CB(0x600000, 0) != 1 || CB(0x900000, 0) != 1) {
f01030f6:	83 ec 08             	sub    $0x8,%esp
f01030f9:	6a 00                	push   $0x0
f01030fb:	68 00 00 60 00       	push   $0x600000
f0103100:	e8 52 05 00 00       	call   f0103657 <CB>
f0103105:	83 c4 10             	add    $0x10,%esp
f0103108:	83 f8 01             	cmp    $0x1,%eax
f010310b:	75 17                	jne    f0103124 <TestAss1Q4+0x4c8>
f010310d:	83 ec 08             	sub    $0x8,%esp
f0103110:	6a 00                	push   $0x0
f0103112:	68 00 00 90 00       	push   $0x900000
f0103117:	e8 3b 05 00 00       	call   f0103657 <CB>
f010311c:	83 c4 10             	add    $0x10,%esp
f010311f:	83 f8 01             	cmp    $0x1,%eax
f0103122:	74 17                	je     f010313b <TestAss1Q4+0x4df>
		cprintf("[EVAL] #6 TransferUserPage: Failed.\n");
f0103124:	83 ec 0c             	sub    $0xc,%esp
f0103127:	68 d4 7f 10 f0       	push   $0xf0107fd4
f010312c:	e8 54 19 00 00       	call   f0104a85 <cprintf>
f0103131:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0103134:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	ptr1 = (char*) 0x600000;
f010313b:	c7 45 d4 00 00 60 00 	movl   $0x600000,-0x2c(%ebp)
	*ptr1 = 'z';
f0103142:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103145:	c6 00 7a             	movb   $0x7a,(%eax)
	ptr2 = (char*) 0x600100;
f0103148:	c7 45 b8 00 01 60 00 	movl   $0x600100,-0x48(%ebp)
	ptr3 = (char*) 0x800000;
f010314f:	c7 45 b4 00 00 80 00 	movl   $0x800000,-0x4c(%ebp)
	ptr4 = (char*) 0x800100;
f0103156:	c7 45 b0 00 01 80 00 	movl   $0x800100,-0x50(%ebp)
	ptr5 = (char*) 0x800FFF;
f010315d:	c7 45 ac ff 0f 80 00 	movl   $0x800fff,-0x54(%ebp)
	ptr6 = (char*) 0x900000;
f0103164:	c7 45 a8 00 00 90 00 	movl   $0x900000,-0x58(%ebp)
	ptr7 = (char*) 0x900FFF;
f010316b:	c7 45 a4 ff 0f 90 00 	movl   $0x900fff,-0x5c(%ebp)
	if ((*ptr1) != 'z' || (*ptr2) != 'b' || (*ptr3) != 'a' || (*ptr4) != 'b' || (*ptr5) != 'c'
f0103172:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103175:	8a 00                	mov    (%eax),%al
f0103177:	3c 7a                	cmp    $0x7a,%al
f0103179:	75 36                	jne    f01031b1 <TestAss1Q4+0x555>
f010317b:	8b 45 b8             	mov    -0x48(%ebp),%eax
f010317e:	8a 00                	mov    (%eax),%al
f0103180:	3c 62                	cmp    $0x62,%al
f0103182:	75 2d                	jne    f01031b1 <TestAss1Q4+0x555>
f0103184:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0103187:	8a 00                	mov    (%eax),%al
f0103189:	3c 61                	cmp    $0x61,%al
f010318b:	75 24                	jne    f01031b1 <TestAss1Q4+0x555>
f010318d:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0103190:	8a 00                	mov    (%eax),%al
f0103192:	3c 62                	cmp    $0x62,%al
f0103194:	75 1b                	jne    f01031b1 <TestAss1Q4+0x555>
f0103196:	8b 45 ac             	mov    -0x54(%ebp),%eax
f0103199:	8a 00                	mov    (%eax),%al
f010319b:	3c 63                	cmp    $0x63,%al
f010319d:	75 12                	jne    f01031b1 <TestAss1Q4+0x555>
			|| (*ptr6) != 'a'|| (*ptr7) != 'c') {
f010319f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01031a2:	8a 00                	mov    (%eax),%al
f01031a4:	3c 61                	cmp    $0x61,%al
f01031a6:	75 09                	jne    f01031b1 <TestAss1Q4+0x555>
f01031a8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01031ab:	8a 00                	mov    (%eax),%al
f01031ad:	3c 63                	cmp    $0x63,%al
f01031af:	74 17                	je     f01031c8 <TestAss1Q4+0x56c>
		cprintf("[EVAL] #7 TransferUserPage: Failed.\n");
f01031b1:	83 ec 0c             	sub    $0xc,%esp
f01031b4:	68 fc 7f 10 f0       	push   $0xf0107ffc
f01031b9:	e8 c7 18 00 00       	call   f0104a85 <cprintf>
f01031be:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f01031c1:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	if (failed == 0)
f01031c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01031cc:	75 04                	jne    f01031d2 <TestAss1Q4+0x576>
		eval += 25 ;
f01031ce:	83 45 e4 19          	addl   $0x19,-0x1c(%ebp)

	cprintf("\nPART III: [MOVE] Destination page exists [25% MARK]\n");
f01031d2:	83 ec 0c             	sub    $0xc,%esp
f01031d5:	68 24 80 10 f0       	push   $0xf0108024
f01031da:	e8 a6 18 00 00       	call   f0104a85 <cprintf>
f01031df:	83 c4 10             	add    $0x10,%esp
	//===================================================
	//PART III: [MOVE] Destination page exists [25% MARK]
	//===================================================
	char ap4[100] = "ap 0xC00000";
f01031e2:	8d 85 a0 fc ff ff    	lea    -0x360(%ebp),%eax
f01031e8:	bb 11 84 10 f0       	mov    $0xf0108411,%ebx
f01031ed:	ba 03 00 00 00       	mov    $0x3,%edx
f01031f2:	89 c7                	mov    %eax,%edi
f01031f4:	89 de                	mov    %ebx,%esi
f01031f6:	89 d1                	mov    %edx,%ecx
f01031f8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031fa:	8d 95 ac fc ff ff    	lea    -0x354(%ebp),%edx
f0103200:	b9 16 00 00 00       	mov    $0x16,%ecx
f0103205:	b8 00 00 00 00       	mov    $0x0,%eax
f010320a:	89 d7                	mov    %edx,%edi
f010320c:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap4);
f010320e:	83 ec 0c             	sub    $0xc,%esp
f0103211:	8d 85 a0 fc ff ff    	lea    -0x360(%ebp),%eax
f0103217:	50                   	push   %eax
f0103218:	e8 9a d7 ff ff       	call   f01009b7 <execute_command>
f010321d:	83 c4 10             	add    $0x10,%esp

	ptr1 = (char*) 0xC00000;
f0103220:	c7 45 d4 00 00 c0 00 	movl   $0xc00000,-0x2c(%ebp)
	*ptr1 = 'x';
f0103227:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010322a:	c6 00 78             	movb   $0x78,(%eax)
	ptr1 = (char*) 0xC00100;
f010322d:	c7 45 d4 00 01 c0 00 	movl   $0xc00100,-0x2c(%ebp)
	*ptr1 = 'y';
f0103234:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103237:	c6 00 79             	movb   $0x79,(%eax)
	ptr1 = (char*) 0xC00FFF;
f010323a:	c7 45 d4 ff 0f c0 00 	movl   $0xc00fff,-0x2c(%ebp)
	*ptr1 = 'z';
f0103241:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103244:	c6 00 7a             	movb   $0x7a,(%eax)
	char ap5[100] = "ap 0xC02000";
f0103247:	8d 85 3c fc ff ff    	lea    -0x3c4(%ebp),%eax
f010324d:	bb 75 84 10 f0       	mov    $0xf0108475,%ebx
f0103252:	ba 03 00 00 00       	mov    $0x3,%edx
f0103257:	89 c7                	mov    %eax,%edi
f0103259:	89 de                	mov    %ebx,%esi
f010325b:	89 d1                	mov    %edx,%ecx
f010325d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010325f:	8d 95 48 fc ff ff    	lea    -0x3b8(%ebp),%edx
f0103265:	b9 16 00 00 00       	mov    $0x16,%ecx
f010326a:	b8 00 00 00 00       	mov    $0x0,%eax
f010326f:	89 d7                	mov    %edx,%edi
f0103271:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap5);
f0103273:	83 ec 0c             	sub    $0xc,%esp
f0103276:	8d 85 3c fc ff ff    	lea    -0x3c4(%ebp),%eax
f010327c:	50                   	push   %eax
f010327d:	e8 35 d7 ff ff       	call   f01009b7 <execute_command>
f0103282:	83 c4 10             	add    $0x10,%esp

	srcFI1 = get_frame_info(ptr_page_directory, (void*)0xC00000, &ptr_table);
f0103285:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010328a:	83 ec 04             	sub    $0x4,%esp
f010328d:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0103293:	52                   	push   %edx
f0103294:	68 00 00 c0 00       	push   $0xc00000
f0103299:	50                   	push   %eax
f010329a:	e8 ed 0d 00 00       	call   f010408c <get_frame_info>
f010329f:	83 c4 10             	add    $0x10,%esp
f01032a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	dstFI1 = get_frame_info(ptr_page_directory, (void*)0xC02000, &ptr_table);
f01032a5:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01032aa:	83 ec 04             	sub    $0x4,%esp
f01032ad:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f01032b3:	52                   	push   %edx
f01032b4:	68 00 20 c0 00       	push   $0xc02000
f01032b9:	50                   	push   %eax
f01032ba:	e8 cd 0d 00 00       	call   f010408c <get_frame_info>
f01032bf:	83 c4 10             	add    $0x10,%esp
f01032c2:	89 45 cc             	mov    %eax,-0x34(%ebp)

	ff1 = calculate_free_frames();
f01032c5:	e8 cb 0e 00 00       	call   f0104195 <calculate_free_frames>
f01032ca:	89 45 c8             	mov    %eax,-0x38(%ebp)

	char cmd4[100] = "tup 0xC00000 0xC02000 m";
f01032cd:	8d 85 d8 fb ff ff    	lea    -0x428(%ebp),%eax
f01032d3:	bb d9 84 10 f0       	mov    $0xf01084d9,%ebx
f01032d8:	ba 06 00 00 00       	mov    $0x6,%edx
f01032dd:	89 c7                	mov    %eax,%edi
f01032df:	89 de                	mov    %ebx,%esi
f01032e1:	89 d1                	mov    %edx,%ecx
f01032e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032e5:	8d 95 f0 fb ff ff    	lea    -0x410(%ebp),%edx
f01032eb:	b9 13 00 00 00       	mov    $0x13,%ecx
f01032f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01032f5:	89 d7                	mov    %edx,%edi
f01032f7:	f3 ab                	rep stos %eax,%es:(%edi)

	strsplit(cmd4, WHITESPACE, args, &numOfArgs);
f01032f9:	8d 85 70 fe ff ff    	lea    -0x190(%ebp),%eax
f01032ff:	50                   	push   %eax
f0103300:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0103306:	50                   	push   %eax
f0103307:	68 39 77 10 f0       	push   $0xf0107739
f010330c:	8d 85 d8 fb ff ff    	lea    -0x428(%ebp),%eax
f0103312:	50                   	push   %eax
f0103313:	e8 07 31 00 00       	call   f010641f <strsplit>
f0103318:	83 c4 10             	add    $0x10,%esp

	TransferUserPage(args);
f010331b:	83 ec 0c             	sub    $0xc,%esp
f010331e:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0103324:	50                   	push   %eax
f0103325:	e8 27 e1 ff ff       	call   f0101451 <TransferUserPage>
f010332a:	83 c4 10             	add    $0x10,%esp

	ff2 = calculate_free_frames();
f010332d:	e8 63 0e 00 00       	call   f0104195 <calculate_free_frames>
f0103332:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	srcFI2 = get_frame_info(ptr_page_directory, (void*)0xC00000, &ptr_table);
f0103335:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010333a:	83 ec 04             	sub    $0x4,%esp
f010333d:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0103343:	52                   	push   %edx
f0103344:	68 00 00 c0 00       	push   $0xc00000
f0103349:	50                   	push   %eax
f010334a:	e8 3d 0d 00 00       	call   f010408c <get_frame_info>
f010334f:	83 c4 10             	add    $0x10,%esp
f0103352:	89 45 c0             	mov    %eax,-0x40(%ebp)
	dstFI2 = get_frame_info(ptr_page_directory, (void*)0xC02000, &ptr_table);
f0103355:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010335a:	83 ec 04             	sub    $0x4,%esp
f010335d:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0103363:	52                   	push   %edx
f0103364:	68 00 20 c0 00       	push   $0xc02000
f0103369:	50                   	push   %eax
f010336a:	e8 1d 0d 00 00       	call   f010408c <get_frame_info>
f010336f:	83 c4 10             	add    $0x10,%esp
f0103372:	89 45 bc             	mov    %eax,-0x44(%ebp)

	failed = 0;
f0103375:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (ff2 - ff1 != 1 || srcFI1->references > 1 || srcFI2 != NULL) {
f010337c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010337f:	2b 45 c8             	sub    -0x38(%ebp),%eax
f0103382:	83 f8 01             	cmp    $0x1,%eax
f0103385:	75 12                	jne    f0103399 <TestAss1Q4+0x73d>
f0103387:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010338a:	8b 40 08             	mov    0x8(%eax),%eax
f010338d:	66 83 f8 01          	cmp    $0x1,%ax
f0103391:	77 06                	ja     f0103399 <TestAss1Q4+0x73d>
f0103393:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f0103397:	74 17                	je     f01033b0 <TestAss1Q4+0x754>
		cprintf("[EVAL] #8 TransferUserPage: Failed.\n");
f0103399:	83 ec 0c             	sub    $0xc,%esp
f010339c:	68 5c 80 10 f0       	push   $0xf010805c
f01033a1:	e8 df 16 00 00       	call   f0104a85 <cprintf>
f01033a6:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f01033a9:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}

	if (CB(0xC00000, 0) != 0 || CB(0xC02000, 0) != 1) {
f01033b0:	83 ec 08             	sub    $0x8,%esp
f01033b3:	6a 00                	push   $0x0
f01033b5:	68 00 00 c0 00       	push   $0xc00000
f01033ba:	e8 98 02 00 00       	call   f0103657 <CB>
f01033bf:	83 c4 10             	add    $0x10,%esp
f01033c2:	85 c0                	test   %eax,%eax
f01033c4:	75 17                	jne    f01033dd <TestAss1Q4+0x781>
f01033c6:	83 ec 08             	sub    $0x8,%esp
f01033c9:	6a 00                	push   $0x0
f01033cb:	68 00 20 c0 00       	push   $0xc02000
f01033d0:	e8 82 02 00 00       	call   f0103657 <CB>
f01033d5:	83 c4 10             	add    $0x10,%esp
f01033d8:	83 f8 01             	cmp    $0x1,%eax
f01033db:	74 17                	je     f01033f4 <TestAss1Q4+0x798>
		cprintf("[EVAL] #9 TransferUserPage: Failed.\n");
f01033dd:	83 ec 0c             	sub    $0xc,%esp
f01033e0:	68 84 80 10 f0       	push   $0xf0108084
f01033e5:	e8 9b 16 00 00       	call   f0104a85 <cprintf>
f01033ea:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f01033ed:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}

	ptr1 = (char*) 0xC02000;
f01033f4:	c7 45 d4 00 20 c0 00 	movl   $0xc02000,-0x2c(%ebp)
	ptr2 = (char*) 0xC02100;
f01033fb:	c7 45 b8 00 21 c0 00 	movl   $0xc02100,-0x48(%ebp)
	ptr3 = (char*) 0xC02FFF;
f0103402:	c7 45 b4 ff 2f c0 00 	movl   $0xc02fff,-0x4c(%ebp)
	if ((*ptr1) != 'x' || (*ptr2) != 'y' || (*ptr3) != 'z') {
f0103409:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010340c:	8a 00                	mov    (%eax),%al
f010340e:	3c 78                	cmp    $0x78,%al
f0103410:	75 12                	jne    f0103424 <TestAss1Q4+0x7c8>
f0103412:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0103415:	8a 00                	mov    (%eax),%al
f0103417:	3c 79                	cmp    $0x79,%al
f0103419:	75 09                	jne    f0103424 <TestAss1Q4+0x7c8>
f010341b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f010341e:	8a 00                	mov    (%eax),%al
f0103420:	3c 7a                	cmp    $0x7a,%al
f0103422:	74 17                	je     f010343b <TestAss1Q4+0x7df>
		cprintf("[EVAL] #10 TransferUserPage: Failed.\n");
f0103424:	83 ec 0c             	sub    $0xc,%esp
f0103427:	68 ac 80 10 f0       	push   $0xf01080ac
f010342c:	e8 54 16 00 00       	call   f0104a85 <cprintf>
f0103431:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0103434:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}

	if (failed == 0)
f010343b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010343f:	75 04                	jne    f0103445 <TestAss1Q4+0x7e9>
		eval += 25 ;
f0103441:	83 45 e4 19          	addl   $0x19,-0x1c(%ebp)
	//ff1 = ff2 ;

	cprintf("\nPART IV: [MOVE] Destination page NOT exists [25% MARK]\n");
f0103445:	83 ec 0c             	sub    $0xc,%esp
f0103448:	68 d4 80 10 f0       	push   $0xf01080d4
f010344d:	e8 33 16 00 00       	call   f0104a85 <cprintf>
f0103452:	83 c4 10             	add    $0x10,%esp

	//======================================================
	//PART IV: [MOVE] Destination page NOT exists [25% MARK]
	//======================================================
	char ap6[100] = "ap 0xD00000";
f0103455:	8d 85 74 fb ff ff    	lea    -0x48c(%ebp),%eax
f010345b:	bb 3d 85 10 f0       	mov    $0xf010853d,%ebx
f0103460:	ba 03 00 00 00       	mov    $0x3,%edx
f0103465:	89 c7                	mov    %eax,%edi
f0103467:	89 de                	mov    %ebx,%esi
f0103469:	89 d1                	mov    %edx,%ecx
f010346b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010346d:	8d 95 80 fb ff ff    	lea    -0x480(%ebp),%edx
f0103473:	b9 16 00 00 00       	mov    $0x16,%ecx
f0103478:	b8 00 00 00 00       	mov    $0x0,%eax
f010347d:	89 d7                	mov    %edx,%edi
f010347f:	f3 ab                	rep stos %eax,%es:(%edi)
	execute_command(ap6);
f0103481:	83 ec 0c             	sub    $0xc,%esp
f0103484:	8d 85 74 fb ff ff    	lea    -0x48c(%ebp),%eax
f010348a:	50                   	push   %eax
f010348b:	e8 27 d5 ff ff       	call   f01009b7 <execute_command>
f0103490:	83 c4 10             	add    $0x10,%esp

	ptr1 = (char*) 0xD00000;
f0103493:	c7 45 d4 00 00 d0 00 	movl   $0xd00000,-0x2c(%ebp)
	*ptr1 = 'x';
f010349a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010349d:	c6 00 78             	movb   $0x78,(%eax)
	ptr1 = (char*) 0xD00100;
f01034a0:	c7 45 d4 00 01 d0 00 	movl   $0xd00100,-0x2c(%ebp)
	*ptr1 = 'y';
f01034a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034aa:	c6 00 79             	movb   $0x79,(%eax)
	ptr1 = (char*) 0xD00FFF;
f01034ad:	c7 45 d4 ff 0f d0 00 	movl   $0xd00fff,-0x2c(%ebp)
	*ptr1 = 'z';
f01034b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034b7:	c6 00 7a             	movb   $0x7a,(%eax)

	srcFI1 = get_frame_info(ptr_page_directory, (void*)0xD00000, &ptr_table);
f01034ba:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01034bf:	83 ec 04             	sub    $0x4,%esp
f01034c2:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f01034c8:	52                   	push   %edx
f01034c9:	68 00 00 d0 00       	push   $0xd00000
f01034ce:	50                   	push   %eax
f01034cf:	e8 b8 0b 00 00       	call   f010408c <get_frame_info>
f01034d4:	83 c4 10             	add    $0x10,%esp
f01034d7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	ff1 = calculate_free_frames();
f01034da:	e8 b6 0c 00 00       	call   f0104195 <calculate_free_frames>
f01034df:	89 45 c8             	mov    %eax,-0x38(%ebp)

	char cmd5[100] = "tup 0xD00000 0x1000000 m";
f01034e2:	8d 85 10 fb ff ff    	lea    -0x4f0(%ebp),%eax
f01034e8:	bb a1 85 10 f0       	mov    $0xf01085a1,%ebx
f01034ed:	ba 19 00 00 00       	mov    $0x19,%edx
f01034f2:	89 c7                	mov    %eax,%edi
f01034f4:	89 de                	mov    %ebx,%esi
f01034f6:	89 d1                	mov    %edx,%ecx
f01034f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01034fa:	8d 95 29 fb ff ff    	lea    -0x4d7(%ebp),%edx
f0103500:	b9 4b 00 00 00       	mov    $0x4b,%ecx
f0103505:	b0 00                	mov    $0x0,%al
f0103507:	89 d7                	mov    %edx,%edi
f0103509:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(cmd5, WHITESPACE, args, &numOfArgs);
f010350b:	8d 85 70 fe ff ff    	lea    -0x190(%ebp),%eax
f0103511:	50                   	push   %eax
f0103512:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0103518:	50                   	push   %eax
f0103519:	68 39 77 10 f0       	push   $0xf0107739
f010351e:	8d 85 10 fb ff ff    	lea    -0x4f0(%ebp),%eax
f0103524:	50                   	push   %eax
f0103525:	e8 f5 2e 00 00       	call   f010641f <strsplit>
f010352a:	83 c4 10             	add    $0x10,%esp

	TransferUserPage(args);
f010352d:	83 ec 0c             	sub    $0xc,%esp
f0103530:	8d 85 30 fe ff ff    	lea    -0x1d0(%ebp),%eax
f0103536:	50                   	push   %eax
f0103537:	e8 15 df ff ff       	call   f0101451 <TransferUserPage>
f010353c:	83 c4 10             	add    $0x10,%esp

	ff2 = calculate_free_frames();
f010353f:	e8 51 0c 00 00       	call   f0104195 <calculate_free_frames>
f0103544:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	srcFI2 = get_frame_info(ptr_page_directory, (void*)0xD00000, &ptr_table);
f0103547:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010354c:	83 ec 04             	sub    $0x4,%esp
f010354f:	8d 95 d8 fe ff ff    	lea    -0x128(%ebp),%edx
f0103555:	52                   	push   %edx
f0103556:	68 00 00 d0 00       	push   $0xd00000
f010355b:	50                   	push   %eax
f010355c:	e8 2b 0b 00 00       	call   f010408c <get_frame_info>
f0103561:	83 c4 10             	add    $0x10,%esp
f0103564:	89 45 c0             	mov    %eax,-0x40(%ebp)

	failed = 0;
f0103567:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	if (ff1 - ff2 != 1 || srcFI1->references > 1 || srcFI2 != NULL) {
f010356e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103571:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f0103574:	83 f8 01             	cmp    $0x1,%eax
f0103577:	75 12                	jne    f010358b <TestAss1Q4+0x92f>
f0103579:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010357c:	8b 40 08             	mov    0x8(%eax),%eax
f010357f:	66 83 f8 01          	cmp    $0x1,%ax
f0103583:	77 06                	ja     f010358b <TestAss1Q4+0x92f>
f0103585:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f0103589:	74 17                	je     f01035a2 <TestAss1Q4+0x946>
		cprintf("[EVAL] #11 TransferUserPage: Failed.\n");
f010358b:	83 ec 0c             	sub    $0xc,%esp
f010358e:	68 10 81 10 f0       	push   $0xf0108110
f0103593:	e8 ed 14 00 00       	call   f0104a85 <cprintf>
f0103598:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f010359b:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	if (CB(0xD00000, 0) != 0 || CB(0x1000000, 0) != 1) {
f01035a2:	83 ec 08             	sub    $0x8,%esp
f01035a5:	6a 00                	push   $0x0
f01035a7:	68 00 00 d0 00       	push   $0xd00000
f01035ac:	e8 a6 00 00 00       	call   f0103657 <CB>
f01035b1:	83 c4 10             	add    $0x10,%esp
f01035b4:	85 c0                	test   %eax,%eax
f01035b6:	75 17                	jne    f01035cf <TestAss1Q4+0x973>
f01035b8:	83 ec 08             	sub    $0x8,%esp
f01035bb:	6a 00                	push   $0x0
f01035bd:	68 00 00 00 01       	push   $0x1000000
f01035c2:	e8 90 00 00 00       	call   f0103657 <CB>
f01035c7:	83 c4 10             	add    $0x10,%esp
f01035ca:	83 f8 01             	cmp    $0x1,%eax
f01035cd:	74 17                	je     f01035e6 <TestAss1Q4+0x98a>
		cprintf("[EVAL] #12 TransferUserPage: Failed.\n");
f01035cf:	83 ec 0c             	sub    $0xc,%esp
f01035d2:	68 38 81 10 f0       	push   $0xf0108138
f01035d7:	e8 a9 14 00 00       	call   f0104a85 <cprintf>
f01035dc:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f01035df:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}

	ptr1 = (char*) 0x1000000;
f01035e6:	c7 45 d4 00 00 00 01 	movl   $0x1000000,-0x2c(%ebp)
	ptr2 = (char*) 0x1000100;
f01035ed:	c7 45 b8 00 01 00 01 	movl   $0x1000100,-0x48(%ebp)
	ptr3 = (char*) 0x1000FFF;
f01035f4:	c7 45 b4 ff 0f 00 01 	movl   $0x1000fff,-0x4c(%ebp)

	if ((*ptr1) != 'x' || (*ptr2) != 'y' || (*ptr3) != 'z') {
f01035fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01035fe:	8a 00                	mov    (%eax),%al
f0103600:	3c 78                	cmp    $0x78,%al
f0103602:	75 12                	jne    f0103616 <TestAss1Q4+0x9ba>
f0103604:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0103607:	8a 00                	mov    (%eax),%al
f0103609:	3c 79                	cmp    $0x79,%al
f010360b:	75 09                	jne    f0103616 <TestAss1Q4+0x9ba>
f010360d:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0103610:	8a 00                	mov    (%eax),%al
f0103612:	3c 7a                	cmp    $0x7a,%al
f0103614:	74 17                	je     f010362d <TestAss1Q4+0x9d1>
		cprintf("[EVAL] #13 TransferUserPage: Failed.\n");
f0103616:	83 ec 0c             	sub    $0xc,%esp
f0103619:	68 60 81 10 f0       	push   $0xf0108160
f010361e:	e8 62 14 00 00       	call   f0104a85 <cprintf>
f0103623:	83 c4 10             	add    $0x10,%esp
		failed = 1;
f0103626:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
		//return 0;
	}
	if (failed == 0)
f010362d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103631:	75 04                	jne    f0103637 <TestAss1Q4+0x9db>
		eval += 25;
f0103633:	83 45 e4 19          	addl   $0x19,-0x1c(%ebp)

	cprintf("\n[EVAL] TransferUserPage. Final Evaluation = %d\n", eval);
f0103637:	83 ec 08             	sub    $0x8,%esp
f010363a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010363d:	68 88 81 10 f0       	push   $0xf0108188
f0103642:	e8 3e 14 00 00       	call   f0104a85 <cprintf>
f0103647:	83 c4 10             	add    $0x10,%esp

	return 0;
f010364a:	b8 00 00 00 00       	mov    $0x0,%eax

}
f010364f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103652:	5b                   	pop    %ebx
f0103653:	5e                   	pop    %esi
f0103654:	5f                   	pop    %edi
f0103655:	5d                   	pop    %ebp
f0103656:	c3                   	ret    

f0103657 <CB>:

int CB(uint32 va, int bn)
{
f0103657:	55                   	push   %ebp
f0103658:	89 e5                	mov    %esp,%ebp
f010365a:	83 ec 18             	sub    $0x18,%esp
	uint32 *ptr_table = NULL;
f010365d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	uint32 mask = 1<<bn;
f0103664:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103667:	ba 01 00 00 00       	mov    $0x1,%edx
f010366c:	88 c1                	mov    %al,%cl
f010366e:	d3 e2                	shl    %cl,%edx
f0103670:	89 d0                	mov    %edx,%eax
f0103672:	89 45 f4             	mov    %eax,-0xc(%ebp)
	get_page_table(ptr_page_directory, (void*)va, 0, &ptr_table);
f0103675:	8b 55 08             	mov    0x8(%ebp),%edx
f0103678:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010367d:	8d 4d f0             	lea    -0x10(%ebp),%ecx
f0103680:	51                   	push   %ecx
f0103681:	6a 00                	push   $0x0
f0103683:	52                   	push   %edx
f0103684:	50                   	push   %eax
f0103685:	e8 0e 08 00 00       	call   f0103e98 <get_page_table>
f010368a:	83 c4 10             	add    $0x10,%esp
	if (ptr_table == NULL) return -1;
f010368d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103690:	85 c0                	test   %eax,%eax
f0103692:	75 07                	jne    f010369b <CB+0x44>
f0103694:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103699:	eb 22                	jmp    f01036bd <CB+0x66>
	return (ptr_table[PTX(va)] & mask) == mask ? 1 : 0 ;
f010369b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010369e:	8b 55 08             	mov    0x8(%ebp),%edx
f01036a1:	c1 ea 0c             	shr    $0xc,%edx
f01036a4:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01036aa:	c1 e2 02             	shl    $0x2,%edx
f01036ad:	01 d0                	add    %edx,%eax
f01036af:	8b 00                	mov    (%eax),%eax
f01036b1:	23 45 f4             	and    -0xc(%ebp),%eax
f01036b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f01036b7:	0f 94 c0             	sete   %al
f01036ba:	0f b6 c0             	movzbl %al,%eax
}
f01036bd:	c9                   	leave  
f01036be:	c3                   	ret    

f01036bf <ClearUserSpace>:

void ClearUserSpace()
{
f01036bf:	55                   	push   %ebp
f01036c0:	89 e5                	mov    %esp,%ebp
f01036c2:	83 ec 10             	sub    $0x10,%esp
	for (int i = 0; i < PDX(USER_TOP); ++i) {
f01036c5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01036cc:	eb 16                	jmp    f01036e4 <ClearUserSpace+0x25>
		ptr_page_directory[i] = 0;
f01036ce:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01036d3:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01036d6:	c1 e2 02             	shl    $0x2,%edx
f01036d9:	01 d0                	add    %edx,%eax
f01036db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return (ptr_table[PTX(va)] & mask) == mask ? 1 : 0 ;
}

void ClearUserSpace()
{
	for (int i = 0; i < PDX(USER_TOP); ++i) {
f01036e1:	ff 45 fc             	incl   -0x4(%ebp)
f01036e4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01036e7:	3d ba 03 00 00       	cmp    $0x3ba,%eax
f01036ec:	76 e0                	jbe    f01036ce <ClearUserSpace+0xf>
		ptr_page_directory[i] = 0;
	}
}
f01036ee:	90                   	nop
f01036ef:	c9                   	leave  
f01036f0:	c3                   	ret    

f01036f1 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f01036f1:	55                   	push   %ebp
f01036f2:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f01036f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f7:	8b 15 4c 44 15 f0    	mov    0xf015444c,%edx
f01036fd:	29 d0                	sub    %edx,%eax
f01036ff:	c1 f8 02             	sar    $0x2,%eax
f0103702:	89 c2                	mov    %eax,%edx
f0103704:	89 d0                	mov    %edx,%eax
f0103706:	c1 e0 02             	shl    $0x2,%eax
f0103709:	01 d0                	add    %edx,%eax
f010370b:	c1 e0 02             	shl    $0x2,%eax
f010370e:	01 d0                	add    %edx,%eax
f0103710:	c1 e0 02             	shl    $0x2,%eax
f0103713:	01 d0                	add    %edx,%eax
f0103715:	89 c1                	mov    %eax,%ecx
f0103717:	c1 e1 08             	shl    $0x8,%ecx
f010371a:	01 c8                	add    %ecx,%eax
f010371c:	89 c1                	mov    %eax,%ecx
f010371e:	c1 e1 10             	shl    $0x10,%ecx
f0103721:	01 c8                	add    %ecx,%eax
f0103723:	01 c0                	add    %eax,%eax
f0103725:	01 d0                	add    %edx,%eax
}
f0103727:	5d                   	pop    %ebp
f0103728:	c3                   	ret    

f0103729 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0103729:	55                   	push   %ebp
f010372a:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f010372c:	ff 75 08             	pushl  0x8(%ebp)
f010372f:	e8 bd ff ff ff       	call   f01036f1 <to_frame_number>
f0103734:	83 c4 04             	add    $0x4,%esp
f0103737:	c1 e0 0c             	shl    $0xc,%eax
}
f010373a:	c9                   	leave  
f010373b:	c3                   	ret    

f010373c <to_frame_info>:

static inline struct Frame_Info* to_frame_info(uint32 physical_address)
{
f010373c:	55                   	push   %ebp
f010373d:	89 e5                	mov    %esp,%ebp
f010373f:	83 ec 08             	sub    $0x8,%esp
	if (PPN(physical_address) >= number_of_frames)
f0103742:	8b 45 08             	mov    0x8(%ebp),%eax
f0103745:	c1 e8 0c             	shr    $0xc,%eax
f0103748:	89 c2                	mov    %eax,%edx
f010374a:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f010374f:	39 c2                	cmp    %eax,%edx
f0103751:	72 14                	jb     f0103767 <to_frame_info+0x2b>
		panic("to_frame_info called with invalid pa");
f0103753:	83 ec 04             	sub    $0x4,%esp
f0103756:	68 08 86 10 f0       	push   $0xf0108608
f010375b:	6a 39                	push   $0x39
f010375d:	68 2d 86 10 f0       	push   $0xf010862d
f0103762:	e8 c7 c9 ff ff       	call   f010012e <_panic>
	return &frames_info[PPN(physical_address)];
f0103767:	8b 15 4c 44 15 f0    	mov    0xf015444c,%edx
f010376d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103770:	c1 e8 0c             	shr    $0xc,%eax
f0103773:	89 c1                	mov    %eax,%ecx
f0103775:	89 c8                	mov    %ecx,%eax
f0103777:	01 c0                	add    %eax,%eax
f0103779:	01 c8                	add    %ecx,%eax
f010377b:	c1 e0 02             	shl    $0x2,%eax
f010377e:	01 d0                	add    %edx,%eax
}
f0103780:	c9                   	leave  
f0103781:	c3                   	ret    

f0103782 <initialize_kernel_VM>:
//
// From USER_TOP to USER_LIMIT, the user is allowed to read but not write.
// Above USER_LIMIT the user cannot read (or write).

void initialize_kernel_VM()
{
f0103782:	55                   	push   %ebp
f0103783:	89 e5                	mov    %esp,%ebp
f0103785:	83 ec 28             	sub    $0x28,%esp
	//panic("initialize_kernel_VM: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	ptr_page_directory = boot_allocate_space(PAGE_SIZE, PAGE_SIZE);
f0103788:	83 ec 08             	sub    $0x8,%esp
f010378b:	68 00 10 00 00       	push   $0x1000
f0103790:	68 00 10 00 00       	push   $0x1000
f0103795:	e8 ca 01 00 00       	call   f0103964 <boot_allocate_space>
f010379a:	83 c4 10             	add    $0x10,%esp
f010379d:	a3 54 44 15 f0       	mov    %eax,0xf0154454
	memset(ptr_page_directory, 0, PAGE_SIZE);
f01037a2:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01037a7:	83 ec 04             	sub    $0x4,%esp
f01037aa:	68 00 10 00 00       	push   $0x1000
f01037af:	6a 00                	push   $0x0
f01037b1:	50                   	push   %eax
f01037b2:	e8 b0 29 00 00       	call   f0106167 <memset>
f01037b7:	83 c4 10             	add    $0x10,%esp
	phys_page_directory = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01037ba:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01037bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01037c2:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f01037c9:	77 14                	ja     f01037df <initialize_kernel_VM+0x5d>
f01037cb:	ff 75 f4             	pushl  -0xc(%ebp)
f01037ce:	68 48 86 10 f0       	push   $0xf0108648
f01037d3:	6a 3c                	push   $0x3c
f01037d5:	68 79 86 10 f0       	push   $0xf0108679
f01037da:	e8 4f c9 ff ff       	call   f010012e <_panic>
f01037df:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037e2:	05 00 00 00 10       	add    $0x10000000,%eax
f01037e7:	a3 58 44 15 f0       	mov    %eax,0xf0154458
	// Map the kernel stack with VA range :
	//  [KERNEL_STACK_TOP-KERNEL_STACK_SIZE, KERNEL_STACK_TOP), 
	// to physical address : "phys_stack_bottom".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_range(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE, KERNEL_STACK_SIZE, K_PHYSICAL_ADDRESS(ptr_stack_bottom), PERM_WRITEABLE) ;
f01037ec:	c7 45 f0 00 80 11 f0 	movl   $0xf0118000,-0x10(%ebp)
f01037f3:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f01037fa:	77 14                	ja     f0103810 <initialize_kernel_VM+0x8e>
f01037fc:	ff 75 f0             	pushl  -0x10(%ebp)
f01037ff:	68 48 86 10 f0       	push   $0xf0108648
f0103804:	6a 44                	push   $0x44
f0103806:	68 79 86 10 f0       	push   $0xf0108679
f010380b:	e8 1e c9 ff ff       	call   f010012e <_panic>
f0103810:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103813:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103819:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010381e:	83 ec 0c             	sub    $0xc,%esp
f0103821:	6a 02                	push   $0x2
f0103823:	52                   	push   %edx
f0103824:	68 00 80 00 00       	push   $0x8000
f0103829:	68 00 80 bf ef       	push   $0xefbf8000
f010382e:	50                   	push   %eax
f010382f:	e8 92 01 00 00       	call   f01039c6 <boot_map_range>
f0103834:	83 c4 20             	add    $0x20,%esp
	//      the PA range [0, 2^32 - KERNEL_BASE)
	// We might not have 2^32 - KERNEL_BASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_range(ptr_page_directory, KERNEL_BASE, 0xFFFFFFFF - KERNEL_BASE, 0, PERM_WRITEABLE) ;
f0103837:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010383c:	83 ec 0c             	sub    $0xc,%esp
f010383f:	6a 02                	push   $0x2
f0103841:	6a 00                	push   $0x0
f0103843:	68 ff ff ff 0f       	push   $0xfffffff
f0103848:	68 00 00 00 f0       	push   $0xf0000000
f010384d:	50                   	push   %eax
f010384e:	e8 73 01 00 00       	call   f01039c6 <boot_map_range>
f0103853:	83 c4 20             	add    $0x20,%esp
	// Permissions:
	//    - frames_info -- kernel RW, user NONE
	//    - the image mapped at READ_ONLY_FRAMES_INFO  -- kernel R, user R
	// Your code goes here:
	uint32 array_size;
	array_size = number_of_frames * sizeof(struct Frame_Info) ;
f0103856:	8b 15 88 37 15 f0    	mov    0xf0153788,%edx
f010385c:	89 d0                	mov    %edx,%eax
f010385e:	01 c0                	add    %eax,%eax
f0103860:	01 d0                	add    %edx,%eax
f0103862:	c1 e0 02             	shl    $0x2,%eax
f0103865:	89 45 ec             	mov    %eax,-0x14(%ebp)
	frames_info = boot_allocate_space(array_size, PAGE_SIZE);
f0103868:	83 ec 08             	sub    $0x8,%esp
f010386b:	68 00 10 00 00       	push   $0x1000
f0103870:	ff 75 ec             	pushl  -0x14(%ebp)
f0103873:	e8 ec 00 00 00       	call   f0103964 <boot_allocate_space>
f0103878:	83 c4 10             	add    $0x10,%esp
f010387b:	a3 4c 44 15 f0       	mov    %eax,0xf015444c
	boot_map_range(ptr_page_directory, READ_ONLY_FRAMES_INFO, array_size, K_PHYSICAL_ADDRESS(frames_info), PERM_USER) ;
f0103880:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0103885:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0103888:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f010388f:	77 14                	ja     f01038a5 <initialize_kernel_VM+0x123>
f0103891:	ff 75 e8             	pushl  -0x18(%ebp)
f0103894:	68 48 86 10 f0       	push   $0xf0108648
f0103899:	6a 5f                	push   $0x5f
f010389b:	68 79 86 10 f0       	push   $0xf0108679
f01038a0:	e8 89 c8 ff ff       	call   f010012e <_panic>
f01038a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01038a8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01038ae:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f01038b3:	83 ec 0c             	sub    $0xc,%esp
f01038b6:	6a 04                	push   $0x4
f01038b8:	52                   	push   %edx
f01038b9:	ff 75 ec             	pushl  -0x14(%ebp)
f01038bc:	68 00 00 00 ef       	push   $0xef000000
f01038c1:	50                   	push   %eax
f01038c2:	e8 ff 00 00 00       	call   f01039c6 <boot_map_range>
f01038c7:	83 c4 20             	add    $0x20,%esp


	// This allows the kernel & user to access any page table entry using a
	// specified VA for each: VPT for kernel and UVPT for User.
	setup_listing_to_all_page_tables_entries();
f01038ca:	e8 d9 e8 ff ff       	call   f01021a8 <setup_listing_to_all_page_tables_entries>
	// Permissions:
	//    - envs itself -- kernel RW, user NONE
	//    - the image of envs mapped at UENVS  -- kernel R, user R

	// LAB 3: Your code here.
	int envs_size = NENV * sizeof(struct Env) ;
f01038cf:	c7 45 e4 00 90 01 00 	movl   $0x19000,-0x1c(%ebp)

	//allocate space for "envs" array aligned on 4KB boundary
	envs = boot_allocate_space(envs_size, PAGE_SIZE);
f01038d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038d9:	83 ec 08             	sub    $0x8,%esp
f01038dc:	68 00 10 00 00       	push   $0x1000
f01038e1:	50                   	push   %eax
f01038e2:	e8 7d 00 00 00       	call   f0103964 <boot_allocate_space>
f01038e7:	83 c4 10             	add    $0x10,%esp
f01038ea:	a3 10 2f 15 f0       	mov    %eax,0xf0152f10

	//make the user to access this array by mapping it to UPAGES linear address (UPAGES is in User/Kernel space)
	boot_map_range(ptr_page_directory, UENVS, envs_size, K_PHYSICAL_ADDRESS(envs), PERM_USER) ;
f01038ef:	a1 10 2f 15 f0       	mov    0xf0152f10,%eax
f01038f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01038f7:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01038fe:	77 14                	ja     f0103914 <initialize_kernel_VM+0x192>
f0103900:	ff 75 e0             	pushl  -0x20(%ebp)
f0103903:	68 48 86 10 f0       	push   $0xf0108648
f0103908:	6a 75                	push   $0x75
f010390a:	68 79 86 10 f0       	push   $0xf0108679
f010390f:	e8 1a c8 ff ff       	call   f010012e <_panic>
f0103914:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103917:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f010391d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103920:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0103925:	83 ec 0c             	sub    $0xc,%esp
f0103928:	6a 04                	push   $0x4
f010392a:	51                   	push   %ecx
f010392b:	52                   	push   %edx
f010392c:	68 00 00 c0 ee       	push   $0xeec00000
f0103931:	50                   	push   %eax
f0103932:	e8 8f 00 00 00       	call   f01039c6 <boot_map_range>
f0103937:	83 c4 20             	add    $0x20,%esp

	//update permissions of the corresponding entry in page directory to make it USER with PERMISSION read only
	ptr_page_directory[PDX(UENVS)] = ptr_page_directory[PDX(UENVS)]|(PERM_USER|(PERM_PRESENT & (~PERM_WRITEABLE)));
f010393a:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f010393f:	05 ec 0e 00 00       	add    $0xeec,%eax
f0103944:	8b 15 54 44 15 f0    	mov    0xf0154454,%edx
f010394a:	81 c2 ec 0e 00 00    	add    $0xeec,%edx
f0103950:	8b 12                	mov    (%edx),%edx
f0103952:	83 ca 05             	or     $0x5,%edx
f0103955:	89 10                	mov    %edx,(%eax)


	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f0103957:	e8 46 dc ff ff       	call   f01015a2 <check_boot_pgdir>

	// NOW: Turn off the segmentation by setting the segments' base to 0, and
	// turn on the paging by setting the corresponding flags in control register 0 (cr0)
	turn_on_paging() ;
f010395c:	e8 a8 e7 ff ff       	call   f0102109 <turn_on_paging>
}
f0103961:	90                   	nop
f0103962:	c9                   	leave  
f0103963:	c3                   	ret    

f0103964 <boot_allocate_space>:
// It's too early to run out of memory.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
// 
void* boot_allocate_space(uint32 size, uint32 align)
		{
f0103964:	55                   	push   %ebp
f0103965:	89 e5                	mov    %esp,%ebp
f0103967:	83 ec 10             	sub    $0x10,%esp
	// Initialize ptr_free_mem if this is the first time.
	// 'end_of_kernel' is a symbol automatically generated by the linker,
	// which points to the end of the kernel-
	// i.e., the first virtual address that the linker
	// did not assign to any kernel code or global variables.
	if (ptr_free_mem == 0)
f010396a:	a1 50 44 15 f0       	mov    0xf0154450,%eax
f010396f:	85 c0                	test   %eax,%eax
f0103971:	75 0a                	jne    f010397d <boot_allocate_space+0x19>
		ptr_free_mem = end_of_kernel;
f0103973:	c7 05 50 44 15 f0 5c 	movl   $0xf015445c,0xf0154450
f010397a:	44 15 f0 

	// Your code here:
	//	Step 1: round ptr_free_mem up to be aligned properly
	ptr_free_mem = ROUNDUP(ptr_free_mem, PAGE_SIZE) ;
f010397d:	c7 45 fc 00 10 00 00 	movl   $0x1000,-0x4(%ebp)
f0103984:	a1 50 44 15 f0       	mov    0xf0154450,%eax
f0103989:	89 c2                	mov    %eax,%edx
f010398b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010398e:	01 d0                	add    %edx,%eax
f0103990:	48                   	dec    %eax
f0103991:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103994:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0103997:	ba 00 00 00 00       	mov    $0x0,%edx
f010399c:	f7 75 fc             	divl   -0x4(%ebp)
f010399f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01039a2:	29 d0                	sub    %edx,%eax
f01039a4:	a3 50 44 15 f0       	mov    %eax,0xf0154450

	//	Step 2: save current value of ptr_free_mem as allocated space
	void *ptr_allocated_mem;
	ptr_allocated_mem = ptr_free_mem ;
f01039a9:	a1 50 44 15 f0       	mov    0xf0154450,%eax
f01039ae:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//	Step 3: increase ptr_free_mem to record allocation
	ptr_free_mem += size ;
f01039b1:	8b 15 50 44 15 f0    	mov    0xf0154450,%edx
f01039b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ba:	01 d0                	add    %edx,%eax
f01039bc:	a3 50 44 15 f0       	mov    %eax,0xf0154450

	//	Step 4: return allocated space
	return ptr_allocated_mem ;
f01039c1:	8b 45 f4             	mov    -0xc(%ebp),%eax

		}
f01039c4:	c9                   	leave  
f01039c5:	c3                   	ret    

f01039c6 <boot_map_range>:
//
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
f01039c6:	55                   	push   %ebp
f01039c7:	89 e5                	mov    %esp,%ebp
f01039c9:	83 ec 28             	sub    $0x28,%esp
	int i = 0 ;
f01039cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
f01039d3:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01039da:	8b 55 14             	mov    0x14(%ebp),%edx
f01039dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01039e0:	01 d0                	add    %edx,%eax
f01039e2:	48                   	dec    %eax
f01039e3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039e9:	ba 00 00 00 00       	mov    $0x0,%edx
f01039ee:	f7 75 f0             	divl   -0x10(%ebp)
f01039f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039f4:	29 d0                	sub    %edx,%eax
f01039f6:	89 45 14             	mov    %eax,0x14(%ebp)
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f01039f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0103a00:	eb 53                	jmp    f0103a55 <boot_map_range+0x8f>
	{
		uint32 *ptr_page_table = boot_get_page_table(ptr_page_directory, virtual_address, 1) ;
f0103a02:	83 ec 04             	sub    $0x4,%esp
f0103a05:	6a 01                	push   $0x1
f0103a07:	ff 75 0c             	pushl  0xc(%ebp)
f0103a0a:	ff 75 08             	pushl  0x8(%ebp)
f0103a0d:	e8 4e 00 00 00       	call   f0103a60 <boot_get_page_table>
f0103a12:	83 c4 10             	add    $0x10,%esp
f0103a15:	89 45 e8             	mov    %eax,-0x18(%ebp)
		uint32 index_page_table = PTX(virtual_address);
f0103a18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a1b:	c1 e8 0c             	shr    $0xc,%eax
f0103a1e:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103a23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
f0103a26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a29:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103a30:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103a33:	01 c2                	add    %eax,%edx
f0103a35:	8b 45 18             	mov    0x18(%ebp),%eax
f0103a38:	0b 45 14             	or     0x14(%ebp),%eax
f0103a3b:	83 c8 01             	or     $0x1,%eax
f0103a3e:	89 02                	mov    %eax,(%edx)
		physical_address += PAGE_SIZE ;
f0103a40:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
		virtual_address += PAGE_SIZE ;
f0103a47:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
	int i = 0 ;
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f0103a4e:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0103a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a58:	3b 45 10             	cmp    0x10(%ebp),%eax
f0103a5b:	72 a5                	jb     f0103a02 <boot_map_range+0x3c>
		uint32 index_page_table = PTX(virtual_address);
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
		physical_address += PAGE_SIZE ;
		virtual_address += PAGE_SIZE ;
	}
}
f0103a5d:	90                   	nop
f0103a5e:	c9                   	leave  
f0103a5f:	c3                   	ret    

f0103a60 <boot_get_page_table>:
// boot_get_page_table cannot fail.  It's too early to fail.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
uint32* boot_get_page_table(uint32 *ptr_page_directory, uint32 virtual_address, int create)
		{
f0103a60:	55                   	push   %ebp
f0103a61:	89 e5                	mov    %esp,%ebp
f0103a63:	83 ec 28             	sub    $0x28,%esp
	uint32 index_page_directory = PDX(virtual_address);
f0103a66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a69:	c1 e8 16             	shr    $0x16,%eax
f0103a6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 page_directory_entry = ptr_page_directory[index_page_directory];
f0103a6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a72:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103a79:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a7c:	01 d0                	add    %edx,%eax
f0103a7e:	8b 00                	mov    (%eax),%eax
f0103a80:	89 45 f0             	mov    %eax,-0x10(%ebp)

	uint32 phys_page_table = EXTRACT_ADDRESS(page_directory_entry);
f0103a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103a8b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table);
f0103a8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a91:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0103a94:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103a97:	c1 e8 0c             	shr    $0xc,%eax
f0103a9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a9d:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0103aa2:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0103aa5:	72 17                	jb     f0103abe <boot_get_page_table+0x5e>
f0103aa7:	ff 75 e8             	pushl  -0x18(%ebp)
f0103aaa:	68 90 86 10 f0       	push   $0xf0108690
f0103aaf:	68 db 00 00 00       	push   $0xdb
f0103ab4:	68 79 86 10 f0       	push   $0xf0108679
f0103ab9:	e8 70 c6 ff ff       	call   f010012e <_panic>
f0103abe:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103ac1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103ac6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (phys_page_table == 0)
f0103ac9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103acd:	75 72                	jne    f0103b41 <boot_get_page_table+0xe1>
	{
		if (create)
f0103acf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103ad3:	74 65                	je     f0103b3a <boot_get_page_table+0xda>
		{
			ptr_page_table = boot_allocate_space(PAGE_SIZE, PAGE_SIZE) ;
f0103ad5:	83 ec 08             	sub    $0x8,%esp
f0103ad8:	68 00 10 00 00       	push   $0x1000
f0103add:	68 00 10 00 00       	push   $0x1000
f0103ae2:	e8 7d fe ff ff       	call   f0103964 <boot_allocate_space>
f0103ae7:	83 c4 10             	add    $0x10,%esp
f0103aea:	89 45 e0             	mov    %eax,-0x20(%ebp)
			phys_page_table = K_PHYSICAL_ADDRESS(ptr_page_table);
f0103aed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103af0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103af3:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f0103afa:	77 17                	ja     f0103b13 <boot_get_page_table+0xb3>
f0103afc:	ff 75 dc             	pushl  -0x24(%ebp)
f0103aff:	68 48 86 10 f0       	push   $0xf0108648
f0103b04:	68 e1 00 00 00       	push   $0xe1
f0103b09:	68 79 86 10 f0       	push   $0xf0108679
f0103b0e:	e8 1b c6 ff ff       	call   f010012e <_panic>
f0103b13:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b16:	05 00 00 00 10       	add    $0x10000000,%eax
f0103b1b:	89 45 ec             	mov    %eax,-0x14(%ebp)
			ptr_page_directory[index_page_directory] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_WRITEABLE);
f0103b1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103b21:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103b28:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b2b:	01 d0                	add    %edx,%eax
f0103b2d:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0103b30:	83 ca 03             	or     $0x3,%edx
f0103b33:	89 10                	mov    %edx,(%eax)
			return ptr_page_table ;
f0103b35:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b38:	eb 0a                	jmp    f0103b44 <boot_get_page_table+0xe4>
		}
		else
			return 0 ;
f0103b3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b3f:	eb 03                	jmp    f0103b44 <boot_get_page_table+0xe4>
	}
	return ptr_page_table ;
f0103b41:	8b 45 e0             	mov    -0x20(%ebp),%eax
		}
f0103b44:	c9                   	leave  
f0103b45:	c3                   	ret    

f0103b46 <initialize_paging>:
// After this point, ONLY use the functions below
// to allocate and deallocate physical memory via the free_frame_list,
// and NEVER use boot_allocate_space() or the related boot-time functions above.
//
void initialize_paging()
{
f0103b46:	55                   	push   %ebp
f0103b47:	89 e5                	mov    %esp,%ebp
f0103b49:	53                   	push   %ebx
f0103b4a:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which frames are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&free_frame_list);
f0103b4d:	c7 05 48 44 15 f0 00 	movl   $0x0,0xf0154448
f0103b54:	00 00 00 

	frames_info[0].references = 1;
f0103b57:	a1 4c 44 15 f0       	mov    0xf015444c,%eax
f0103b5c:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);
f0103b62:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0103b69:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103b6c:	05 ff ff 09 00       	add    $0x9ffff,%eax
f0103b71:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103b74:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103b77:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b7c:	f7 75 f0             	divl   -0x10(%ebp)
f0103b7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103b82:	29 d0                	sub    %edx,%eax
f0103b84:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f0103b87:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f0103b8e:	e9 90 00 00 00       	jmp    f0103c23 <initialize_paging+0xdd>
	{
		frames_info[i].references = 0;
f0103b93:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103b99:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103b9c:	89 d0                	mov    %edx,%eax
f0103b9e:	01 c0                	add    %eax,%eax
f0103ba0:	01 d0                	add    %edx,%eax
f0103ba2:	c1 e0 02             	shl    $0x2,%eax
f0103ba5:	01 c8                	add    %ecx,%eax
f0103ba7:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f0103bad:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103bb3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103bb6:	89 d0                	mov    %edx,%eax
f0103bb8:	01 c0                	add    %eax,%eax
f0103bba:	01 d0                	add    %edx,%eax
f0103bbc:	c1 e0 02             	shl    $0x2,%eax
f0103bbf:	01 c8                	add    %ecx,%eax
f0103bc1:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103bc7:	89 10                	mov    %edx,(%eax)
f0103bc9:	8b 00                	mov    (%eax),%eax
f0103bcb:	85 c0                	test   %eax,%eax
f0103bcd:	74 1d                	je     f0103bec <initialize_paging+0xa6>
f0103bcf:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103bd5:	8b 1d 4c 44 15 f0    	mov    0xf015444c,%ebx
f0103bdb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0103bde:	89 c8                	mov    %ecx,%eax
f0103be0:	01 c0                	add    %eax,%eax
f0103be2:	01 c8                	add    %ecx,%eax
f0103be4:	c1 e0 02             	shl    $0x2,%eax
f0103be7:	01 d8                	add    %ebx,%eax
f0103be9:	89 42 04             	mov    %eax,0x4(%edx)
f0103bec:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103bf2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103bf5:	89 d0                	mov    %edx,%eax
f0103bf7:	01 c0                	add    %eax,%eax
f0103bf9:	01 d0                	add    %edx,%eax
f0103bfb:	c1 e0 02             	shl    $0x2,%eax
f0103bfe:	01 c8                	add    %ecx,%eax
f0103c00:	a3 48 44 15 f0       	mov    %eax,0xf0154448
f0103c05:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103c0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103c0e:	89 d0                	mov    %edx,%eax
f0103c10:	01 c0                	add    %eax,%eax
f0103c12:	01 d0                	add    %edx,%eax
f0103c14:	c1 e0 02             	shl    $0x2,%eax
f0103c17:	01 c8                	add    %ecx,%eax
f0103c19:	c7 40 04 48 44 15 f0 	movl   $0xf0154448,0x4(%eax)

	frames_info[0].references = 1;

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f0103c20:	ff 45 f4             	incl   -0xc(%ebp)
f0103c23:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103c26:	85 c0                	test   %eax,%eax
f0103c28:	79 05                	jns    f0103c2f <initialize_paging+0xe9>
f0103c2a:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103c2f:	c1 f8 0c             	sar    $0xc,%eax
f0103c32:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0103c35:	0f 8f 58 ff ff ff    	jg     f0103b93 <initialize_paging+0x4d>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f0103c3b:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
f0103c42:	eb 1d                	jmp    f0103c61 <initialize_paging+0x11b>
	{
		frames_info[i].references = 1;
f0103c44:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103c4a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103c4d:	89 d0                	mov    %edx,%eax
f0103c4f:	01 c0                	add    %eax,%eax
f0103c51:	01 d0                	add    %edx,%eax
f0103c53:	c1 e0 02             	shl    $0x2,%eax
f0103c56:	01 c8                	add    %ecx,%eax
f0103c58:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f0103c5e:	ff 45 f4             	incl   -0xc(%ebp)
f0103c61:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
f0103c68:	7e da                	jle    f0103c44 <initialize_paging+0xfe>
	{
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);
f0103c6a:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f0103c71:	a1 50 44 15 f0       	mov    0xf0154450,%eax
f0103c76:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103c79:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0103c80:	77 17                	ja     f0103c99 <initialize_paging+0x153>
f0103c82:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c85:	68 48 86 10 f0       	push   $0xf0108648
f0103c8a:	68 1e 01 00 00       	push   $0x11e
f0103c8f:	68 79 86 10 f0       	push   $0xf0108679
f0103c94:	e8 95 c4 ff ff       	call   f010012e <_panic>
f0103c99:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c9c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103ca2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103ca5:	01 d0                	add    %edx,%eax
f0103ca7:	48                   	dec    %eax
f0103ca8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103cab:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103cae:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cb3:	f7 75 e4             	divl   -0x1c(%ebp)
f0103cb6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103cb9:	29 d0                	sub    %edx,%eax
f0103cbb:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f0103cbe:	c7 45 f4 00 01 00 00 	movl   $0x100,-0xc(%ebp)
f0103cc5:	eb 1d                	jmp    f0103ce4 <initialize_paging+0x19e>
	{
		frames_info[i].references = 1;
f0103cc7:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103ccd:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103cd0:	89 d0                	mov    %edx,%eax
f0103cd2:	01 c0                	add    %eax,%eax
f0103cd4:	01 d0                	add    %edx,%eax
f0103cd6:	c1 e0 02             	shl    $0x2,%eax
f0103cd9:	01 c8                	add    %ecx,%eax
f0103cdb:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f0103ce1:	ff 45 f4             	incl   -0xc(%ebp)
f0103ce4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103ce7:	85 c0                	test   %eax,%eax
f0103ce9:	79 05                	jns    f0103cf0 <initialize_paging+0x1aa>
f0103ceb:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103cf0:	c1 f8 0c             	sar    $0xc,%eax
f0103cf3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0103cf6:	7f cf                	jg     f0103cc7 <initialize_paging+0x181>
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f0103cf8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103cfb:	85 c0                	test   %eax,%eax
f0103cfd:	79 05                	jns    f0103d04 <initialize_paging+0x1be>
f0103cff:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103d04:	c1 f8 0c             	sar    $0xc,%eax
f0103d07:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103d0a:	e9 90 00 00 00       	jmp    f0103d9f <initialize_paging+0x259>
	{
		frames_info[i].references = 0;
f0103d0f:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103d15:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103d18:	89 d0                	mov    %edx,%eax
f0103d1a:	01 c0                	add    %eax,%eax
f0103d1c:	01 d0                	add    %edx,%eax
f0103d1e:	c1 e0 02             	shl    $0x2,%eax
f0103d21:	01 c8                	add    %ecx,%eax
f0103d23:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f0103d29:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103d2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103d32:	89 d0                	mov    %edx,%eax
f0103d34:	01 c0                	add    %eax,%eax
f0103d36:	01 d0                	add    %edx,%eax
f0103d38:	c1 e0 02             	shl    $0x2,%eax
f0103d3b:	01 c8                	add    %ecx,%eax
f0103d3d:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103d43:	89 10                	mov    %edx,(%eax)
f0103d45:	8b 00                	mov    (%eax),%eax
f0103d47:	85 c0                	test   %eax,%eax
f0103d49:	74 1d                	je     f0103d68 <initialize_paging+0x222>
f0103d4b:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103d51:	8b 1d 4c 44 15 f0    	mov    0xf015444c,%ebx
f0103d57:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0103d5a:	89 c8                	mov    %ecx,%eax
f0103d5c:	01 c0                	add    %eax,%eax
f0103d5e:	01 c8                	add    %ecx,%eax
f0103d60:	c1 e0 02             	shl    $0x2,%eax
f0103d63:	01 d8                	add    %ebx,%eax
f0103d65:	89 42 04             	mov    %eax,0x4(%edx)
f0103d68:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103d6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103d71:	89 d0                	mov    %edx,%eax
f0103d73:	01 c0                	add    %eax,%eax
f0103d75:	01 d0                	add    %edx,%eax
f0103d77:	c1 e0 02             	shl    $0x2,%eax
f0103d7a:	01 c8                	add    %ecx,%eax
f0103d7c:	a3 48 44 15 f0       	mov    %eax,0xf0154448
f0103d81:	8b 0d 4c 44 15 f0    	mov    0xf015444c,%ecx
f0103d87:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103d8a:	89 d0                	mov    %edx,%eax
f0103d8c:	01 c0                	add    %eax,%eax
f0103d8e:	01 d0                	add    %edx,%eax
f0103d90:	c1 e0 02             	shl    $0x2,%eax
f0103d93:	01 c8                	add    %ecx,%eax
f0103d95:	c7 40 04 48 44 15 f0 	movl   $0xf0154448,0x4(%eax)
	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f0103d9c:	ff 45 f4             	incl   -0xc(%ebp)
f0103d9f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103da2:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0103da7:	39 c2                	cmp    %eax,%edx
f0103da9:	0f 82 60 ff ff ff    	jb     f0103d0f <initialize_paging+0x1c9>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}
}
f0103daf:	90                   	nop
f0103db0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103db3:	c9                   	leave  
f0103db4:	c3                   	ret    

f0103db5 <initialize_frame_info>:
// Initialize a Frame_Info structure.
// The result has null links and 0 references.
// Note that the corresponding physical frame is NOT initialized!
//
void initialize_frame_info(struct Frame_Info *ptr_frame_info)
{
f0103db5:	55                   	push   %ebp
f0103db6:	89 e5                	mov    %esp,%ebp
f0103db8:	83 ec 08             	sub    $0x8,%esp
	memset(ptr_frame_info, 0, sizeof(*ptr_frame_info));
f0103dbb:	83 ec 04             	sub    $0x4,%esp
f0103dbe:	6a 0c                	push   $0xc
f0103dc0:	6a 00                	push   $0x0
f0103dc2:	ff 75 08             	pushl  0x8(%ebp)
f0103dc5:	e8 9d 23 00 00       	call   f0106167 <memset>
f0103dca:	83 c4 10             	add    $0x10,%esp
}
f0103dcd:	90                   	nop
f0103dce:	c9                   	leave  
f0103dcf:	c3                   	ret    

f0103dd0 <allocate_frame>:
//   E_NO_MEM -- otherwise
//
// Hint: use LIST_FIRST, LIST_REMOVE, and initialize_frame_info
// Hint: references should not be incremented
int allocate_frame(struct Frame_Info **ptr_frame_info)
{
f0103dd0:	55                   	push   %ebp
f0103dd1:	89 e5                	mov    %esp,%ebp
f0103dd3:	83 ec 08             	sub    $0x8,%esp
	// Fill this function in	
	*ptr_frame_info = LIST_FIRST(&free_frame_list);
f0103dd6:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103ddc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ddf:	89 10                	mov    %edx,(%eax)
	if(*ptr_frame_info == NULL)
f0103de1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103de4:	8b 00                	mov    (%eax),%eax
f0103de6:	85 c0                	test   %eax,%eax
f0103de8:	75 07                	jne    f0103df1 <allocate_frame+0x21>
		return E_NO_MEM;
f0103dea:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103def:	eb 44                	jmp    f0103e35 <allocate_frame+0x65>

	LIST_REMOVE(*ptr_frame_info);
f0103df1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103df4:	8b 00                	mov    (%eax),%eax
f0103df6:	8b 00                	mov    (%eax),%eax
f0103df8:	85 c0                	test   %eax,%eax
f0103dfa:	74 12                	je     f0103e0e <allocate_frame+0x3e>
f0103dfc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dff:	8b 00                	mov    (%eax),%eax
f0103e01:	8b 00                	mov    (%eax),%eax
f0103e03:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e06:	8b 12                	mov    (%edx),%edx
f0103e08:	8b 52 04             	mov    0x4(%edx),%edx
f0103e0b:	89 50 04             	mov    %edx,0x4(%eax)
f0103e0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e11:	8b 00                	mov    (%eax),%eax
f0103e13:	8b 40 04             	mov    0x4(%eax),%eax
f0103e16:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e19:	8b 12                	mov    (%edx),%edx
f0103e1b:	8b 12                	mov    (%edx),%edx
f0103e1d:	89 10                	mov    %edx,(%eax)
	initialize_frame_info(*ptr_frame_info);
f0103e1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e22:	8b 00                	mov    (%eax),%eax
f0103e24:	83 ec 0c             	sub    $0xc,%esp
f0103e27:	50                   	push   %eax
f0103e28:	e8 88 ff ff ff       	call   f0103db5 <initialize_frame_info>
f0103e2d:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103e30:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e35:	c9                   	leave  
f0103e36:	c3                   	ret    

f0103e37 <free_frame>:
//
// Return a frame to the free_frame_list.
// (This function should only be called when ptr_frame_info->references reaches 0.)
//
void free_frame(struct Frame_Info *ptr_frame_info)
{
f0103e37:	55                   	push   %ebp
f0103e38:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	LIST_INSERT_HEAD(&free_frame_list, ptr_frame_info);
f0103e3a:	8b 15 48 44 15 f0    	mov    0xf0154448,%edx
f0103e40:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e43:	89 10                	mov    %edx,(%eax)
f0103e45:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e48:	8b 00                	mov    (%eax),%eax
f0103e4a:	85 c0                	test   %eax,%eax
f0103e4c:	74 0b                	je     f0103e59 <free_frame+0x22>
f0103e4e:	a1 48 44 15 f0       	mov    0xf0154448,%eax
f0103e53:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e56:	89 50 04             	mov    %edx,0x4(%eax)
f0103e59:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e5c:	a3 48 44 15 f0       	mov    %eax,0xf0154448
f0103e61:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e64:	c7 40 04 48 44 15 f0 	movl   $0xf0154448,0x4(%eax)
}
f0103e6b:	90                   	nop
f0103e6c:	5d                   	pop    %ebp
f0103e6d:	c3                   	ret    

f0103e6e <decrement_references>:
//
// Decrement the reference count on a frame
// freeing it if there are no more references.
//
void decrement_references(struct Frame_Info* ptr_frame_info)
{
f0103e6e:	55                   	push   %ebp
f0103e6f:	89 e5                	mov    %esp,%ebp
	if (--(ptr_frame_info->references) == 0)
f0103e71:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e74:	8b 40 08             	mov    0x8(%eax),%eax
f0103e77:	48                   	dec    %eax
f0103e78:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e7b:	66 89 42 08          	mov    %ax,0x8(%edx)
f0103e7f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e82:	8b 40 08             	mov    0x8(%eax),%eax
f0103e85:	66 85 c0             	test   %ax,%ax
f0103e88:	75 0b                	jne    f0103e95 <decrement_references+0x27>
		free_frame(ptr_frame_info);
f0103e8a:	ff 75 08             	pushl  0x8(%ebp)
f0103e8d:	e8 a5 ff ff ff       	call   f0103e37 <free_frame>
f0103e92:	83 c4 04             	add    $0x4,%esp
}
f0103e95:	90                   	nop
f0103e96:	c9                   	leave  
f0103e97:	c3                   	ret    

f0103e98 <get_page_table>:
//
// Hint: you can use "to_physical_address()" to turn a Frame_Info*
// into the physical address of the frame it refers to. 

int get_page_table(uint32 *ptr_page_directory, const void *virtual_address, int create, uint32 **ptr_page_table)
{
f0103e98:	55                   	push   %ebp
f0103e99:	89 e5                	mov    %esp,%ebp
f0103e9b:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	uint32 page_directory_entry = ptr_page_directory[PDX(virtual_address)];
f0103e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ea1:	c1 e8 16             	shr    $0x16,%eax
f0103ea4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103eab:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eae:	01 d0                	add    %edx,%eax
f0103eb0:	8b 00                	mov    (%eax),%eax
f0103eb2:	89 45 f4             	mov    %eax,-0xc(%ebp)

	*ptr_page_table = K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(page_directory_entry)) ;
f0103eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103eb8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103ebd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103ec0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103ec3:	c1 e8 0c             	shr    $0xc,%eax
f0103ec6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103ec9:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0103ece:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f0103ed1:	72 17                	jb     f0103eea <get_page_table+0x52>
f0103ed3:	ff 75 f0             	pushl  -0x10(%ebp)
f0103ed6:	68 90 86 10 f0       	push   $0xf0108690
f0103edb:	68 79 01 00 00       	push   $0x179
f0103ee0:	68 79 86 10 f0       	push   $0xf0108679
f0103ee5:	e8 44 c2 ff ff       	call   f010012e <_panic>
f0103eea:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103eed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103ef2:	89 c2                	mov    %eax,%edx
f0103ef4:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ef7:	89 10                	mov    %edx,(%eax)

	if (page_directory_entry == 0)
f0103ef9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0103efd:	0f 85 d3 00 00 00    	jne    f0103fd6 <get_page_table+0x13e>
	{
		if (create)
f0103f03:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103f07:	0f 84 b9 00 00 00    	je     f0103fc6 <get_page_table+0x12e>
		{
			struct Frame_Info* ptr_frame_info;
			int err = allocate_frame(&ptr_frame_info) ;
f0103f0d:	83 ec 0c             	sub    $0xc,%esp
f0103f10:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103f13:	50                   	push   %eax
f0103f14:	e8 b7 fe ff ff       	call   f0103dd0 <allocate_frame>
f0103f19:	83 c4 10             	add    $0x10,%esp
f0103f1c:	89 45 e8             	mov    %eax,-0x18(%ebp)
			if(err == E_NO_MEM)
f0103f1f:	83 7d e8 fc          	cmpl   $0xfffffffc,-0x18(%ebp)
f0103f23:	75 13                	jne    f0103f38 <get_page_table+0xa0>
			{
				*ptr_page_table = 0;
f0103f25:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f28:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				return E_NO_MEM;
f0103f2e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103f33:	e9 a3 00 00 00       	jmp    f0103fdb <get_page_table+0x143>
			}

			uint32 phys_page_table = to_physical_address(ptr_frame_info);
f0103f38:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f3b:	83 ec 0c             	sub    $0xc,%esp
f0103f3e:	50                   	push   %eax
f0103f3f:	e8 e5 f7 ff ff       	call   f0103729 <to_physical_address>
f0103f44:	83 c4 10             	add    $0x10,%esp
f0103f47:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			*ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table) ;
f0103f4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f4d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f53:	c1 e8 0c             	shr    $0xc,%eax
f0103f56:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103f59:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0103f5e:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0103f61:	72 17                	jb     f0103f7a <get_page_table+0xe2>
f0103f63:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f66:	68 90 86 10 f0       	push   $0xf0108690
f0103f6b:	68 88 01 00 00       	push   $0x188
f0103f70:	68 79 86 10 f0       	push   $0xf0108679
f0103f75:	e8 b4 c1 ff ff       	call   f010012e <_panic>
f0103f7a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f7d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103f82:	89 c2                	mov    %eax,%edx
f0103f84:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f87:	89 10                	mov    %edx,(%eax)

			//initialize new page table by 0's
			memset(*ptr_page_table , 0, PAGE_SIZE);
f0103f89:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f8c:	8b 00                	mov    (%eax),%eax
f0103f8e:	83 ec 04             	sub    $0x4,%esp
f0103f91:	68 00 10 00 00       	push   $0x1000
f0103f96:	6a 00                	push   $0x0
f0103f98:	50                   	push   %eax
f0103f99:	e8 c9 21 00 00       	call   f0106167 <memset>
f0103f9e:	83 c4 10             	add    $0x10,%esp

			ptr_frame_info->references = 1;
f0103fa1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103fa4:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
			ptr_page_directory[PDX(virtual_address)] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_USER | PERM_WRITEABLE);
f0103faa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fad:	c1 e8 16             	shr    $0x16,%eax
f0103fb0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0103fb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fba:	01 d0                	add    %edx,%eax
f0103fbc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103fbf:	83 ca 07             	or     $0x7,%edx
f0103fc2:	89 10                	mov    %edx,(%eax)
f0103fc4:	eb 10                	jmp    f0103fd6 <get_page_table+0x13e>
		}
		else
		{
			*ptr_page_table = 0;
f0103fc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fc9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return 0;
f0103fcf:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fd4:	eb 05                	jmp    f0103fdb <get_page_table+0x143>
		}
	}	
	return 0;
f0103fd6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103fdb:	c9                   	leave  
f0103fdc:	c3                   	ret    

f0103fdd <map_frame>:
//   E_NO_MEM, if page table couldn't be allocated
//
// Hint: implement using get_page_table() and unmap_frame().
//
int map_frame(uint32 *ptr_page_directory, struct Frame_Info *ptr_frame_info, void *virtual_address, int perm)
{
f0103fdd:	55                   	push   %ebp
f0103fde:	89 e5                	mov    %esp,%ebp
f0103fe0:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 physical_address = to_physical_address(ptr_frame_info);
f0103fe3:	ff 75 0c             	pushl  0xc(%ebp)
f0103fe6:	e8 3e f7 ff ff       	call   f0103729 <to_physical_address>
f0103feb:	83 c4 04             	add    $0x4,%esp
f0103fee:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *ptr_page_table;
	if( get_page_table(ptr_page_directory, virtual_address, 1, &ptr_page_table) == 0)
f0103ff1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103ff4:	50                   	push   %eax
f0103ff5:	6a 01                	push   $0x1
f0103ff7:	ff 75 10             	pushl  0x10(%ebp)
f0103ffa:	ff 75 08             	pushl  0x8(%ebp)
f0103ffd:	e8 96 fe ff ff       	call   f0103e98 <get_page_table>
f0104002:	83 c4 10             	add    $0x10,%esp
f0104005:	85 c0                	test   %eax,%eax
f0104007:	75 7c                	jne    f0104085 <map_frame+0xa8>
	{
		uint32 page_table_entry = ptr_page_table[PTX(virtual_address)];
f0104009:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010400c:	8b 55 10             	mov    0x10(%ebp),%edx
f010400f:	c1 ea 0c             	shr    $0xc,%edx
f0104012:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104018:	c1 e2 02             	shl    $0x2,%edx
f010401b:	01 d0                	add    %edx,%eax
f010401d:	8b 00                	mov    (%eax),%eax
f010401f:	89 45 f0             	mov    %eax,-0x10(%ebp)

		//If already mapped
		if ((page_table_entry & PERM_PRESENT) == PERM_PRESENT)
f0104022:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104025:	83 e0 01             	and    $0x1,%eax
f0104028:	85 c0                	test   %eax,%eax
f010402a:	74 25                	je     f0104051 <map_frame+0x74>
		{
			//on this pa, then do nothing
			if (EXTRACT_ADDRESS(page_table_entry) == physical_address)
f010402c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010402f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104034:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0104037:	75 07                	jne    f0104040 <map_frame+0x63>
				return 0;
f0104039:	b8 00 00 00 00       	mov    $0x0,%eax
f010403e:	eb 4a                	jmp    f010408a <map_frame+0xad>
			//on another pa, then unmap it
			else
				unmap_frame(ptr_page_directory , virtual_address);
f0104040:	83 ec 08             	sub    $0x8,%esp
f0104043:	ff 75 10             	pushl  0x10(%ebp)
f0104046:	ff 75 08             	pushl  0x8(%ebp)
f0104049:	e8 ad 00 00 00       	call   f01040fb <unmap_frame>
f010404e:	83 c4 10             	add    $0x10,%esp
		}
		ptr_frame_info->references++;
f0104051:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104054:	8b 40 08             	mov    0x8(%eax),%eax
f0104057:	40                   	inc    %eax
f0104058:	8b 55 0c             	mov    0xc(%ebp),%edx
f010405b:	66 89 42 08          	mov    %ax,0x8(%edx)
		ptr_page_table[PTX(virtual_address)] = CONSTRUCT_ENTRY(physical_address , perm | PERM_PRESENT);
f010405f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104062:	8b 55 10             	mov    0x10(%ebp),%edx
f0104065:	c1 ea 0c             	shr    $0xc,%edx
f0104068:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010406e:	c1 e2 02             	shl    $0x2,%edx
f0104071:	01 c2                	add    %eax,%edx
f0104073:	8b 45 14             	mov    0x14(%ebp),%eax
f0104076:	0b 45 f4             	or     -0xc(%ebp),%eax
f0104079:	83 c8 01             	or     $0x1,%eax
f010407c:	89 02                	mov    %eax,(%edx)

		return 0;
f010407e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104083:	eb 05                	jmp    f010408a <map_frame+0xad>
	}	
	return E_NO_MEM;
f0104085:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f010408a:	c9                   	leave  
f010408b:	c3                   	ret    

f010408c <get_frame_info>:
// Return 0 if there is no frame mapped at virtual_address.
//
// Hint: implement using get_page_table() and get_frame_info().
//
struct Frame_Info * get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table)
		{
f010408c:	55                   	push   %ebp
f010408d:	89 e5                	mov    %esp,%ebp
f010408f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in	
	uint32 ret =  get_page_table(ptr_page_directory, virtual_address, 0, ptr_page_table) ;
f0104092:	ff 75 10             	pushl  0x10(%ebp)
f0104095:	6a 00                	push   $0x0
f0104097:	ff 75 0c             	pushl  0xc(%ebp)
f010409a:	ff 75 08             	pushl  0x8(%ebp)
f010409d:	e8 f6 fd ff ff       	call   f0103e98 <get_page_table>
f01040a2:	83 c4 10             	add    $0x10,%esp
f01040a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*ptr_page_table) != 0)
f01040a8:	8b 45 10             	mov    0x10(%ebp),%eax
f01040ab:	8b 00                	mov    (%eax),%eax
f01040ad:	85 c0                	test   %eax,%eax
f01040af:	74 43                	je     f01040f4 <get_frame_info+0x68>
	{	
		uint32 index_page_table = PTX(virtual_address);
f01040b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040b4:	c1 e8 0c             	shr    $0xc,%eax
f01040b7:	25 ff 03 00 00       	and    $0x3ff,%eax
f01040bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
		uint32 page_table_entry = (*ptr_page_table)[index_page_table];
f01040bf:	8b 45 10             	mov    0x10(%ebp),%eax
f01040c2:	8b 00                	mov    (%eax),%eax
f01040c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01040c7:	c1 e2 02             	shl    $0x2,%edx
f01040ca:	01 d0                	add    %edx,%eax
f01040cc:	8b 00                	mov    (%eax),%eax
f01040ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( page_table_entry != 0)	
f01040d1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01040d5:	74 16                	je     f01040ed <get_frame_info+0x61>
			return to_frame_info( EXTRACT_ADDRESS ( page_table_entry ) );
f01040d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01040da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01040df:	83 ec 0c             	sub    $0xc,%esp
f01040e2:	50                   	push   %eax
f01040e3:	e8 54 f6 ff ff       	call   f010373c <to_frame_info>
f01040e8:	83 c4 10             	add    $0x10,%esp
f01040eb:	eb 0c                	jmp    f01040f9 <get_frame_info+0x6d>
		return 0;
f01040ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01040f2:	eb 05                	jmp    f01040f9 <get_frame_info+0x6d>
	}
	return 0;
f01040f4:	b8 00 00 00 00       	mov    $0x0,%eax
		}
f01040f9:	c9                   	leave  
f01040fa:	c3                   	ret    

f01040fb <unmap_frame>:
//
// Hint: implement using get_frame_info(),
// 	tlb_invalidate(), and decrement_references().
//
void unmap_frame(uint32 *ptr_page_directory, void *virtual_address)
{
f01040fb:	55                   	push   %ebp
f01040fc:	89 e5                	mov    %esp,%ebp
f01040fe:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 *ptr_page_table;
	struct Frame_Info* ptr_frame_info = get_frame_info(ptr_page_directory, virtual_address, &ptr_page_table);
f0104101:	83 ec 04             	sub    $0x4,%esp
f0104104:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0104107:	50                   	push   %eax
f0104108:	ff 75 0c             	pushl  0xc(%ebp)
f010410b:	ff 75 08             	pushl  0x8(%ebp)
f010410e:	e8 79 ff ff ff       	call   f010408c <get_frame_info>
f0104113:	83 c4 10             	add    $0x10,%esp
f0104116:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( ptr_frame_info != 0 )
f0104119:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010411d:	74 39                	je     f0104158 <unmap_frame+0x5d>
	{
		decrement_references(ptr_frame_info);
f010411f:	83 ec 0c             	sub    $0xc,%esp
f0104122:	ff 75 f4             	pushl  -0xc(%ebp)
f0104125:	e8 44 fd ff ff       	call   f0103e6e <decrement_references>
f010412a:	83 c4 10             	add    $0x10,%esp
		ptr_page_table[PTX(virtual_address)] = 0;
f010412d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104130:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104133:	c1 ea 0c             	shr    $0xc,%edx
f0104136:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010413c:	c1 e2 02             	shl    $0x2,%edx
f010413f:	01 d0                	add    %edx,%eax
f0104141:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(ptr_page_directory, virtual_address);
f0104147:	83 ec 08             	sub    $0x8,%esp
f010414a:	ff 75 0c             	pushl  0xc(%ebp)
f010414d:	ff 75 08             	pushl  0x8(%ebp)
f0104150:	e8 4d d7 ff ff       	call   f01018a2 <tlb_invalidate>
f0104155:	83 c4 10             	add    $0x10,%esp
	}	
}
f0104158:	90                   	nop
f0104159:	c9                   	leave  
f010415a:	c3                   	ret    

f010415b <get_page>:
//		or to allocate any necessary page tables.
// 	HINT: 	remember to free the allocated frame if there is no space 
//		for the necessary page tables

int get_page(uint32* ptr_page_directory, void *virtual_address, int perm)
{
f010415b:	55                   	push   %ebp
f010415c:	89 e5                	mov    %esp,%ebp
f010415e:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("get_page function is not completed yet") ;
f0104161:	83 ec 04             	sub    $0x4,%esp
f0104164:	68 c0 86 10 f0       	push   $0xf01086c0
f0104169:	68 14 02 00 00       	push   $0x214
f010416e:	68 79 86 10 f0       	push   $0xf0108679
f0104173:	e8 b6 bf ff ff       	call   f010012e <_panic>

f0104178 <calculate_required_frames>:
	return 0 ;
}

//[2] calculate_required_frames: 
uint32 calculate_required_frames(uint32* ptr_page_directory, uint32 start_virtual_address, uint32 size)
{
f0104178:	55                   	push   %ebp
f0104179:	89 e5                	mov    %esp,%ebp
f010417b:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("calculate_required_frames function is not completed yet") ;
f010417e:	83 ec 04             	sub    $0x4,%esp
f0104181:	68 e8 86 10 f0       	push   $0xf01086e8
f0104186:	68 2b 02 00 00       	push   $0x22b
f010418b:	68 79 86 10 f0       	push   $0xf0108679
f0104190:	e8 99 bf ff ff       	call   f010012e <_panic>

f0104195 <calculate_free_frames>:


//[3] calculate_free_frames:

uint32 calculate_free_frames()
{
f0104195:	55                   	push   %ebp
f0104196:	89 e5                	mov    %esp,%ebp
f0104198:	83 ec 10             	sub    $0x10,%esp
	// PROJECT 2008: Your code here.
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
f010419b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	LIST_FOREACH(ptr, &free_frame_list)
f01041a2:	a1 48 44 15 f0       	mov    0xf0154448,%eax
f01041a7:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01041aa:	eb 0b                	jmp    f01041b7 <calculate_free_frames+0x22>
	{
		cnt++ ;
f01041ac:	ff 45 f8             	incl   -0x8(%ebp)
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
	LIST_FOREACH(ptr, &free_frame_list)
f01041af:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01041b2:	8b 00                	mov    (%eax),%eax
f01041b4:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01041b7:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f01041bb:	75 ef                	jne    f01041ac <calculate_free_frames+0x17>
	{
		cnt++ ;
	}
	return cnt;
f01041bd:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f01041c0:	c9                   	leave  
f01041c1:	c3                   	ret    

f01041c2 <freeMem>:
//	Steps:
//		1) Unmap all mapped pages in the range [virtual_address, virtual_address + size ]
//		2) Free all mapped page tables in this range

void freeMem(uint32* ptr_page_directory, void *virtual_address, uint32 size)
{
f01041c2:	55                   	push   %ebp
f01041c3:	89 e5                	mov    %esp,%ebp
f01041c5:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("freeMem function is not completed yet") ;
f01041c8:	83 ec 04             	sub    $0x4,%esp
f01041cb:	68 20 87 10 f0       	push   $0xf0108720
f01041d0:	68 52 02 00 00       	push   $0x252
f01041d5:	68 79 86 10 f0       	push   $0xf0108679
f01041da:	e8 4f bf ff ff       	call   f010012e <_panic>

f01041df <allocate_environment>:
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	E_NO_FREE_ENV if all NENVS environments are allocated
//
int allocate_environment(struct Env** e)
{	
f01041df:	55                   	push   %ebp
f01041e0:	89 e5                	mov    %esp,%ebp
	if (!(*e = LIST_FIRST(&env_free_list)))
f01041e2:	8b 15 18 2f 15 f0    	mov    0xf0152f18,%edx
f01041e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01041eb:	89 10                	mov    %edx,(%eax)
f01041ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01041f0:	8b 00                	mov    (%eax),%eax
f01041f2:	85 c0                	test   %eax,%eax
f01041f4:	75 07                	jne    f01041fd <allocate_environment+0x1e>
		return E_NO_FREE_ENV;
f01041f6:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01041fb:	eb 05                	jmp    f0104202 <allocate_environment+0x23>
	return 0;
f01041fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104202:	5d                   	pop    %ebp
f0104203:	c3                   	ret    

f0104204 <free_environment>:

// Free the given environment "e", simply by adding it to the free environment list.
void free_environment(struct Env* e)
{
f0104204:	55                   	push   %ebp
f0104205:	89 e5                	mov    %esp,%ebp
	curenv = NULL;	
f0104207:	c7 05 14 2f 15 f0 00 	movl   $0x0,0xf0152f14
f010420e:	00 00 00 
	// return the environment to the free list
	e->env_status = ENV_FREE;
f0104211:	8b 45 08             	mov    0x8(%ebp),%eax
f0104214:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e);
f010421b:	8b 15 18 2f 15 f0    	mov    0xf0152f18,%edx
f0104221:	8b 45 08             	mov    0x8(%ebp),%eax
f0104224:	89 50 44             	mov    %edx,0x44(%eax)
f0104227:	8b 45 08             	mov    0x8(%ebp),%eax
f010422a:	8b 40 44             	mov    0x44(%eax),%eax
f010422d:	85 c0                	test   %eax,%eax
f010422f:	74 0e                	je     f010423f <free_environment+0x3b>
f0104231:	a1 18 2f 15 f0       	mov    0xf0152f18,%eax
f0104236:	8b 55 08             	mov    0x8(%ebp),%edx
f0104239:	83 c2 44             	add    $0x44,%edx
f010423c:	89 50 48             	mov    %edx,0x48(%eax)
f010423f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104242:	a3 18 2f 15 f0       	mov    %eax,0xf0152f18
f0104247:	8b 45 08             	mov    0x8(%ebp),%eax
f010424a:	c7 40 48 18 2f 15 f0 	movl   $0xf0152f18,0x48(%eax)
}
f0104251:	90                   	nop
f0104252:	5d                   	pop    %ebp
f0104253:	c3                   	ret    

f0104254 <program_segment_alloc_map>:
//
// if the allocation failed, return E_NO_MEM 
// otherwise return 0
//
static int program_segment_alloc_map(struct Env *e, void *va, uint32 length)
{
f0104254:	55                   	push   %ebp
f0104255:	89 e5                	mov    %esp,%ebp
f0104257:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB6 Hands-on: fill this function. 
	//Comment the following line
	panic("Function is not implemented yet!");
f010425a:	83 ec 04             	sub    $0x4,%esp
f010425d:	68 a4 87 10 f0       	push   $0xf01087a4
f0104262:	6a 7b                	push   $0x7b
f0104264:	68 c5 87 10 f0       	push   $0xf01087c5
f0104269:	e8 c0 be ff ff       	call   f010012e <_panic>

f010426e <env_create>:
}

//
// Allocates a new env and loads the named user program into it.
struct UserProgramInfo* env_create(char* user_program_name)
{
f010426e:	55                   	push   %ebp
f010426f:	89 e5                	mov    %esp,%ebp
f0104271:	83 ec 38             	sub    $0x38,%esp
	//[1] get pointer to the start of the "user_program_name" program in memory
	// Hint: use "get_user_program_info" function, 
	// you should set the following "ptr_program_start" by the start address of the user program 
	uint8* ptr_program_start = 0; 
f0104274:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	struct UserProgramInfo* ptr_user_program_info =get_user_program_info(user_program_name);
f010427b:	83 ec 0c             	sub    $0xc,%esp
f010427e:	ff 75 08             	pushl  0x8(%ebp)
f0104281:	e8 28 05 00 00       	call   f01047ae <get_user_program_info>
f0104286:	83 c4 10             	add    $0x10,%esp
f0104289:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (ptr_user_program_info == 0)
f010428c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104290:	75 07                	jne    f0104299 <env_create+0x2b>
		return NULL ;
f0104292:	b8 00 00 00 00       	mov    $0x0,%eax
f0104297:	eb 42                	jmp    f01042db <env_create+0x6d>

	ptr_program_start = ptr_user_program_info->ptr_start ;
f0104299:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010429c:	8b 40 08             	mov    0x8(%eax),%eax
f010429f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//[2] allocate new environment, (from the free environment list)
	//if there's no one, return NULL
	// Hint: use "allocate_environment" function
	struct Env* e = NULL;
f01042a2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	if(allocate_environment(&e) == E_NO_FREE_ENV)
f01042a9:	83 ec 0c             	sub    $0xc,%esp
f01042ac:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01042af:	50                   	push   %eax
f01042b0:	e8 2a ff ff ff       	call   f01041df <allocate_environment>
f01042b5:	83 c4 10             	add    $0x10,%esp
f01042b8:	83 f8 fb             	cmp    $0xfffffffb,%eax
f01042bb:	75 07                	jne    f01042c4 <env_create+0x56>
	{
		return 0;
f01042bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01042c2:	eb 17                	jmp    f01042db <env_create+0x6d>
	}

	//=========================================================
	//TODO: LAB6 Hands-on: fill this part. 
	//Comment the following line
	panic("env_create: directory creation is not implemented yet!");
f01042c4:	83 ec 04             	sub    $0x4,%esp
f01042c7:	68 e0 87 10 f0       	push   $0xf01087e0
f01042cc:	68 9f 00 00 00       	push   $0x9f
f01042d1:	68 c5 87 10 f0       	push   $0xf01087c5
f01042d6:	e8 53 be ff ff       	call   f010012e <_panic>

	//[11] switch back to the page directory exists before segment loading
	lcr3(kern_phys_pgdir) ;

	return ptr_user_program_info;
}
f01042db:	c9                   	leave  
f01042dc:	c3                   	ret    

f01042dd <env_run>:
// Used to run the given environment "e", simply by 
// context switch from curenv to env e.
//  (This function does not return.)
//
void env_run(struct Env *e)
{
f01042dd:	55                   	push   %ebp
f01042de:	89 e5                	mov    %esp,%ebp
f01042e0:	83 ec 18             	sub    $0x18,%esp
	if(curenv != e)
f01042e3:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01042e8:	3b 45 08             	cmp    0x8(%ebp),%eax
f01042eb:	74 25                	je     f0104312 <env_run+0x35>
	{		
		curenv = e ;
f01042ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01042f0:	a3 14 2f 15 f0       	mov    %eax,0xf0152f14
		curenv->env_runs++ ;
f01042f5:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01042fa:	8b 50 58             	mov    0x58(%eax),%edx
f01042fd:	42                   	inc    %edx
f01042fe:	89 50 58             	mov    %edx,0x58(%eax)
		lcr3(curenv->env_cr3) ;	
f0104301:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104306:	8b 40 60             	mov    0x60(%eax),%eax
f0104309:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010430c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010430f:	0f 22 d8             	mov    %eax,%cr3
	}	
	env_pop_tf(&(curenv->env_tf));
f0104312:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104317:	83 ec 0c             	sub    $0xc,%esp
f010431a:	50                   	push   %eax
f010431b:	e8 89 06 00 00       	call   f01049a9 <env_pop_tf>

f0104320 <env_free>:

//
// Frees environment "e" and all memory it uses.
// 
void env_free(struct Env *e)
{
f0104320:	55                   	push   %ebp
f0104321:	89 e5                	mov    %esp,%ebp
f0104323:	83 ec 08             	sub    $0x8,%esp
	panic("env_free function is not completed yet") ;
f0104326:	83 ec 04             	sub    $0x4,%esp
f0104329:	68 18 88 10 f0       	push   $0xf0108818
f010432e:	68 2f 01 00 00       	push   $0x12f
f0104333:	68 c5 87 10 f0       	push   $0xf01087c5
f0104338:	e8 f1 bd ff ff       	call   f010012e <_panic>

f010433d <env_init>:
// Insert in reverse order, so that the first call to allocate_environment()
// returns envs[0].
//
void
env_init(void)
{	
f010433d:	55                   	push   %ebp
f010433e:	89 e5                	mov    %esp,%ebp
f0104340:	53                   	push   %ebx
f0104341:	83 ec 10             	sub    $0x10,%esp
	int iEnv = NENV-1;
f0104344:	c7 45 f8 ff 03 00 00 	movl   $0x3ff,-0x8(%ebp)
	for(; iEnv >= 0; iEnv--)
f010434b:	e9 ed 00 00 00       	jmp    f010443d <env_init+0x100>
	{
		envs[iEnv].env_status = ENV_FREE;
f0104350:	8b 0d 10 2f 15 f0    	mov    0xf0152f10,%ecx
f0104356:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0104359:	89 d0                	mov    %edx,%eax
f010435b:	c1 e0 02             	shl    $0x2,%eax
f010435e:	01 d0                	add    %edx,%eax
f0104360:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104367:	01 d0                	add    %edx,%eax
f0104369:	c1 e0 02             	shl    $0x2,%eax
f010436c:	01 c8                	add    %ecx,%eax
f010436e:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[iEnv].env_id = 0;
f0104375:	8b 0d 10 2f 15 f0    	mov    0xf0152f10,%ecx
f010437b:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010437e:	89 d0                	mov    %edx,%eax
f0104380:	c1 e0 02             	shl    $0x2,%eax
f0104383:	01 d0                	add    %edx,%eax
f0104385:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010438c:	01 d0                	add    %edx,%eax
f010438e:	c1 e0 02             	shl    $0x2,%eax
f0104391:	01 c8                	add    %ecx,%eax
f0104393:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
f010439a:	8b 0d 10 2f 15 f0    	mov    0xf0152f10,%ecx
f01043a0:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01043a3:	89 d0                	mov    %edx,%eax
f01043a5:	c1 e0 02             	shl    $0x2,%eax
f01043a8:	01 d0                	add    %edx,%eax
f01043aa:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01043b1:	01 d0                	add    %edx,%eax
f01043b3:	c1 e0 02             	shl    $0x2,%eax
f01043b6:	01 c8                	add    %ecx,%eax
f01043b8:	8b 15 18 2f 15 f0    	mov    0xf0152f18,%edx
f01043be:	89 50 44             	mov    %edx,0x44(%eax)
f01043c1:	8b 40 44             	mov    0x44(%eax),%eax
f01043c4:	85 c0                	test   %eax,%eax
f01043c6:	74 2a                	je     f01043f2 <env_init+0xb5>
f01043c8:	8b 15 18 2f 15 f0    	mov    0xf0152f18,%edx
f01043ce:	8b 1d 10 2f 15 f0    	mov    0xf0152f10,%ebx
f01043d4:	8b 4d f8             	mov    -0x8(%ebp),%ecx
f01043d7:	89 c8                	mov    %ecx,%eax
f01043d9:	c1 e0 02             	shl    $0x2,%eax
f01043dc:	01 c8                	add    %ecx,%eax
f01043de:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01043e5:	01 c8                	add    %ecx,%eax
f01043e7:	c1 e0 02             	shl    $0x2,%eax
f01043ea:	01 d8                	add    %ebx,%eax
f01043ec:	83 c0 44             	add    $0x44,%eax
f01043ef:	89 42 48             	mov    %eax,0x48(%edx)
f01043f2:	8b 0d 10 2f 15 f0    	mov    0xf0152f10,%ecx
f01043f8:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01043fb:	89 d0                	mov    %edx,%eax
f01043fd:	c1 e0 02             	shl    $0x2,%eax
f0104400:	01 d0                	add    %edx,%eax
f0104402:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104409:	01 d0                	add    %edx,%eax
f010440b:	c1 e0 02             	shl    $0x2,%eax
f010440e:	01 c8                	add    %ecx,%eax
f0104410:	a3 18 2f 15 f0       	mov    %eax,0xf0152f18
f0104415:	8b 0d 10 2f 15 f0    	mov    0xf0152f10,%ecx
f010441b:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010441e:	89 d0                	mov    %edx,%eax
f0104420:	c1 e0 02             	shl    $0x2,%eax
f0104423:	01 d0                	add    %edx,%eax
f0104425:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010442c:	01 d0                	add    %edx,%eax
f010442e:	c1 e0 02             	shl    $0x2,%eax
f0104431:	01 c8                	add    %ecx,%eax
f0104433:	c7 40 48 18 2f 15 f0 	movl   $0xf0152f18,0x48(%eax)
//
void
env_init(void)
{	
	int iEnv = NENV-1;
	for(; iEnv >= 0; iEnv--)
f010443a:	ff 4d f8             	decl   -0x8(%ebp)
f010443d:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0104441:	0f 89 09 ff ff ff    	jns    f0104350 <env_init+0x13>
	{
		envs[iEnv].env_status = ENV_FREE;
		envs[iEnv].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
	}
}
f0104447:	90                   	nop
f0104448:	83 c4 10             	add    $0x10,%esp
f010444b:	5b                   	pop    %ebx
f010444c:	5d                   	pop    %ebp
f010444d:	c3                   	ret    

f010444e <complete_environment_initialization>:

void complete_environment_initialization(struct Env* e)
{	
f010444e:	55                   	push   %ebp
f010444f:	89 e5                	mov    %esp,%ebp
f0104451:	83 ec 18             	sub    $0x18,%esp
	//VPT and UVPT map the env's own page table, with
	//different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PERM_PRESENT | PERM_WRITEABLE;
f0104454:	8b 45 08             	mov    0x8(%ebp),%eax
f0104457:	8b 40 5c             	mov    0x5c(%eax),%eax
f010445a:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f0104460:	8b 45 08             	mov    0x8(%ebp),%eax
f0104463:	8b 40 60             	mov    0x60(%eax),%eax
f0104466:	83 c8 03             	or     $0x3,%eax
f0104469:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PERM_PRESENT | PERM_USER;
f010446b:	8b 45 08             	mov    0x8(%ebp),%eax
f010446e:	8b 40 5c             	mov    0x5c(%eax),%eax
f0104471:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f0104477:	8b 45 08             	mov    0x8(%ebp),%eax
f010447a:	8b 40 60             	mov    0x60(%eax),%eax
f010447d:	83 c8 05             	or     $0x5,%eax
f0104480:	89 02                	mov    %eax,(%edx)

	int32 generation;	
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0104482:	8b 45 08             	mov    0x8(%ebp),%eax
f0104485:	8b 40 4c             	mov    0x4c(%eax),%eax
f0104488:	05 00 10 00 00       	add    $0x1000,%eax
f010448d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0104492:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f0104495:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104499:	7f 07                	jg     f01044a2 <complete_environment_initialization+0x54>
		generation = 1 << ENVGENSHIFT;
f010449b:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f01044a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01044a5:	8b 15 10 2f 15 f0    	mov    0xf0152f10,%edx
f01044ab:	29 d0                	sub    %edx,%eax
f01044ad:	c1 f8 02             	sar    $0x2,%eax
f01044b0:	89 c1                	mov    %eax,%ecx
f01044b2:	89 c8                	mov    %ecx,%eax
f01044b4:	c1 e0 02             	shl    $0x2,%eax
f01044b7:	01 c8                	add    %ecx,%eax
f01044b9:	c1 e0 07             	shl    $0x7,%eax
f01044bc:	29 c8                	sub    %ecx,%eax
f01044be:	c1 e0 03             	shl    $0x3,%eax
f01044c1:	01 c8                	add    %ecx,%eax
f01044c3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01044ca:	01 d0                	add    %edx,%eax
f01044cc:	c1 e0 02             	shl    $0x2,%eax
f01044cf:	01 c8                	add    %ecx,%eax
f01044d1:	c1 e0 03             	shl    $0x3,%eax
f01044d4:	01 c8                	add    %ecx,%eax
f01044d6:	89 c2                	mov    %eax,%edx
f01044d8:	c1 e2 06             	shl    $0x6,%edx
f01044db:	29 c2                	sub    %eax,%edx
f01044dd:	8d 04 12             	lea    (%edx,%edx,1),%eax
f01044e0:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f01044e3:	8d 04 95 00 00 00 00 	lea    0x0(,%edx,4),%eax
f01044ea:	01 c2                	add    %eax,%edx
f01044ec:	8d 04 12             	lea    (%edx,%edx,1),%eax
f01044ef:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f01044f2:	89 d0                	mov    %edx,%eax
f01044f4:	f7 d8                	neg    %eax
f01044f6:	0b 45 f4             	or     -0xc(%ebp),%eax
f01044f9:	89 c2                	mov    %eax,%edx
f01044fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01044fe:	89 50 4c             	mov    %edx,0x4c(%eax)

	// Set the basic status variables.
	e->env_parent_id = 0;//parent_id;
f0104501:	8b 45 08             	mov    0x8(%ebp),%eax
f0104504:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f010450b:	8b 45 08             	mov    0x8(%ebp),%eax
f010450e:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f0104515:	8b 45 08             	mov    0x8(%ebp),%eax
f0104518:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010451f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104522:	83 ec 04             	sub    $0x4,%esp
f0104525:	6a 44                	push   $0x44
f0104527:	6a 00                	push   $0x0
f0104529:	50                   	push   %eax
f010452a:	e8 38 1c 00 00       	call   f0106167 <memset>
f010452f:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	e->env_tf.tf_ds = GD_UD | 3;
f0104532:	8b 45 08             	mov    0x8(%ebp),%eax
f0104535:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f010453b:	8b 45 08             	mov    0x8(%ebp),%eax
f010453e:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f0104544:	8b 45 08             	mov    0x8(%ebp),%eax
f0104547:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = (uint32*)USTACKTOP;
f010454d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104550:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f0104557:	8b 45 08             	mov    0x8(%ebp),%eax
f010455a:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e);	
f0104560:	8b 45 08             	mov    0x8(%ebp),%eax
f0104563:	8b 40 44             	mov    0x44(%eax),%eax
f0104566:	85 c0                	test   %eax,%eax
f0104568:	74 0f                	je     f0104579 <complete_environment_initialization+0x12b>
f010456a:	8b 45 08             	mov    0x8(%ebp),%eax
f010456d:	8b 40 44             	mov    0x44(%eax),%eax
f0104570:	8b 55 08             	mov    0x8(%ebp),%edx
f0104573:	8b 52 48             	mov    0x48(%edx),%edx
f0104576:	89 50 48             	mov    %edx,0x48(%eax)
f0104579:	8b 45 08             	mov    0x8(%ebp),%eax
f010457c:	8b 40 48             	mov    0x48(%eax),%eax
f010457f:	8b 55 08             	mov    0x8(%ebp),%edx
f0104582:	8b 52 44             	mov    0x44(%edx),%edx
f0104585:	89 10                	mov    %edx,(%eax)
	return ;
f0104587:	90                   	nop
}
f0104588:	c9                   	leave  
f0104589:	c3                   	ret    

f010458a <PROGRAM_SEGMENT_NEXT>:

struct ProgramSegment* PROGRAM_SEGMENT_NEXT(struct ProgramSegment* seg, uint8* ptr_program_start)
				{
f010458a:	55                   	push   %ebp
f010458b:	89 e5                	mov    %esp,%ebp
f010458d:	83 ec 18             	sub    $0x18,%esp
	int index = (*seg).segment_id++;
f0104590:	8b 45 08             	mov    0x8(%ebp),%eax
f0104593:	8b 40 10             	mov    0x10(%eax),%eax
f0104596:	8d 48 01             	lea    0x1(%eax),%ecx
f0104599:	8b 55 08             	mov    0x8(%ebp),%edx
f010459c:	89 4a 10             	mov    %ecx,0x10(%edx)
f010459f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01045a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01045a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01045ab:	8b 00                	mov    (%eax),%eax
f01045ad:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01045b2:	74 17                	je     f01045cb <PROGRAM_SEGMENT_NEXT+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01045b4:	83 ec 04             	sub    $0x4,%esp
f01045b7:	68 3f 88 10 f0       	push   $0xf010883f
f01045bc:	68 88 01 00 00       	push   $0x188
f01045c1:	68 c5 87 10 f0       	push   $0xf01087c5
f01045c6:	e8 63 bb ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01045cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01045ce:	8b 50 1c             	mov    0x1c(%eax),%edx
f01045d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045d4:	01 d0                	add    %edx,%eax
f01045d6:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (ph[(*seg).segment_id].p_type != ELF_PROG_LOAD && ((*seg).segment_id < pELFHDR->e_phnum)) (*seg).segment_id++;	
f01045d9:	eb 0f                	jmp    f01045ea <PROGRAM_SEGMENT_NEXT+0x60>
f01045db:	8b 45 08             	mov    0x8(%ebp),%eax
f01045de:	8b 40 10             	mov    0x10(%eax),%eax
f01045e1:	8d 50 01             	lea    0x1(%eax),%edx
f01045e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01045e7:	89 50 10             	mov    %edx,0x10(%eax)
f01045ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01045ed:	8b 40 10             	mov    0x10(%eax),%eax
f01045f0:	c1 e0 05             	shl    $0x5,%eax
f01045f3:	89 c2                	mov    %eax,%edx
f01045f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01045f8:	01 d0                	add    %edx,%eax
f01045fa:	8b 00                	mov    (%eax),%eax
f01045fc:	83 f8 01             	cmp    $0x1,%eax
f01045ff:	74 13                	je     f0104614 <PROGRAM_SEGMENT_NEXT+0x8a>
f0104601:	8b 45 08             	mov    0x8(%ebp),%eax
f0104604:	8b 50 10             	mov    0x10(%eax),%edx
f0104607:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010460a:	8b 40 2c             	mov    0x2c(%eax),%eax
f010460d:	0f b7 c0             	movzwl %ax,%eax
f0104610:	39 c2                	cmp    %eax,%edx
f0104612:	72 c7                	jb     f01045db <PROGRAM_SEGMENT_NEXT+0x51>
	index = (*seg).segment_id;
f0104614:	8b 45 08             	mov    0x8(%ebp),%eax
f0104617:	8b 40 10             	mov    0x10(%eax),%eax
f010461a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(index < pELFHDR->e_phnum)
f010461d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104620:	8b 40 2c             	mov    0x2c(%eax),%eax
f0104623:	0f b7 c0             	movzwl %ax,%eax
f0104626:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0104629:	7e 63                	jle    f010468e <PROGRAM_SEGMENT_NEXT+0x104>
	{
		(*seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f010462b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010462e:	c1 e0 05             	shl    $0x5,%eax
f0104631:	89 c2                	mov    %eax,%edx
f0104633:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104636:	01 d0                	add    %edx,%eax
f0104638:	8b 50 04             	mov    0x4(%eax),%edx
f010463b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010463e:	01 c2                	add    %eax,%edx
f0104640:	8b 45 08             	mov    0x8(%ebp),%eax
f0104643:	89 10                	mov    %edx,(%eax)
		(*seg).size_in_memory =  ph[index].p_memsz;
f0104645:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104648:	c1 e0 05             	shl    $0x5,%eax
f010464b:	89 c2                	mov    %eax,%edx
f010464d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104650:	01 d0                	add    %edx,%eax
f0104652:	8b 50 14             	mov    0x14(%eax),%edx
f0104655:	8b 45 08             	mov    0x8(%ebp),%eax
f0104658:	89 50 08             	mov    %edx,0x8(%eax)
		(*seg).size_in_file = ph[index].p_filesz;
f010465b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010465e:	c1 e0 05             	shl    $0x5,%eax
f0104661:	89 c2                	mov    %eax,%edx
f0104663:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104666:	01 d0                	add    %edx,%eax
f0104668:	8b 50 10             	mov    0x10(%eax),%edx
f010466b:	8b 45 08             	mov    0x8(%ebp),%eax
f010466e:	89 50 04             	mov    %edx,0x4(%eax)
		(*seg).virtual_address = (uint8*)ph[index].p_va;
f0104671:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104674:	c1 e0 05             	shl    $0x5,%eax
f0104677:	89 c2                	mov    %eax,%edx
f0104679:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010467c:	01 d0                	add    %edx,%eax
f010467e:	8b 40 08             	mov    0x8(%eax),%eax
f0104681:	89 c2                	mov    %eax,%edx
f0104683:	8b 45 08             	mov    0x8(%ebp),%eax
f0104686:	89 50 0c             	mov    %edx,0xc(%eax)
		return seg;
f0104689:	8b 45 08             	mov    0x8(%ebp),%eax
f010468c:	eb 05                	jmp    f0104693 <PROGRAM_SEGMENT_NEXT+0x109>
	}
	return 0;
f010468e:	b8 00 00 00 00       	mov    $0x0,%eax
				}
f0104693:	c9                   	leave  
f0104694:	c3                   	ret    

f0104695 <PROGRAM_SEGMENT_FIRST>:

struct ProgramSegment PROGRAM_SEGMENT_FIRST( uint8* ptr_program_start)
{
f0104695:	55                   	push   %ebp
f0104696:	89 e5                	mov    %esp,%ebp
f0104698:	57                   	push   %edi
f0104699:	56                   	push   %esi
f010469a:	53                   	push   %ebx
f010469b:	83 ec 2c             	sub    $0x2c,%esp
	struct ProgramSegment seg;
	seg.segment_id = 0;
f010469e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01046a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01046ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046ae:	8b 00                	mov    (%eax),%eax
f01046b0:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01046b5:	74 17                	je     f01046ce <PROGRAM_SEGMENT_FIRST+0x39>
		panic("Matafa2nash 3ala Keda"); 
f01046b7:	83 ec 04             	sub    $0x4,%esp
f01046ba:	68 3f 88 10 f0       	push   $0xf010883f
f01046bf:	68 a1 01 00 00       	push   $0x1a1
f01046c4:	68 c5 87 10 f0       	push   $0xf01087c5
f01046c9:	e8 60 ba ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01046ce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046d1:	8b 50 1c             	mov    0x1c(%eax),%edx
f01046d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01046d7:	01 d0                	add    %edx,%eax
f01046d9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while (ph[(seg).segment_id].p_type != ELF_PROG_LOAD && ((seg).segment_id < pELFHDR->e_phnum)) (seg).segment_id++;
f01046dc:	eb 07                	jmp    f01046e5 <PROGRAM_SEGMENT_FIRST+0x50>
f01046de:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01046e1:	40                   	inc    %eax
f01046e2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01046e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01046e8:	c1 e0 05             	shl    $0x5,%eax
f01046eb:	89 c2                	mov    %eax,%edx
f01046ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046f0:	01 d0                	add    %edx,%eax
f01046f2:	8b 00                	mov    (%eax),%eax
f01046f4:	83 f8 01             	cmp    $0x1,%eax
f01046f7:	74 10                	je     f0104709 <PROGRAM_SEGMENT_FIRST+0x74>
f01046f9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01046fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046ff:	8b 40 2c             	mov    0x2c(%eax),%eax
f0104702:	0f b7 c0             	movzwl %ax,%eax
f0104705:	39 c2                	cmp    %eax,%edx
f0104707:	72 d5                	jb     f01046de <PROGRAM_SEGMENT_FIRST+0x49>
	int index = (seg).segment_id;
f0104709:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010470c:	89 45 dc             	mov    %eax,-0x24(%ebp)

	if(index < pELFHDR->e_phnum)
f010470f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104712:	8b 40 2c             	mov    0x2c(%eax),%eax
f0104715:	0f b7 c0             	movzwl %ax,%eax
f0104718:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010471b:	7e 68                	jle    f0104785 <PROGRAM_SEGMENT_FIRST+0xf0>
	{	
		(seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f010471d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104720:	c1 e0 05             	shl    $0x5,%eax
f0104723:	89 c2                	mov    %eax,%edx
f0104725:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104728:	01 d0                	add    %edx,%eax
f010472a:	8b 50 04             	mov    0x4(%eax),%edx
f010472d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104730:	01 d0                	add    %edx,%eax
f0104732:	89 45 c8             	mov    %eax,-0x38(%ebp)
		(seg).size_in_memory =  ph[index].p_memsz;
f0104735:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104738:	c1 e0 05             	shl    $0x5,%eax
f010473b:	89 c2                	mov    %eax,%edx
f010473d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104740:	01 d0                	add    %edx,%eax
f0104742:	8b 40 14             	mov    0x14(%eax),%eax
f0104745:	89 45 d0             	mov    %eax,-0x30(%ebp)
		(seg).size_in_file = ph[index].p_filesz;
f0104748:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010474b:	c1 e0 05             	shl    $0x5,%eax
f010474e:	89 c2                	mov    %eax,%edx
f0104750:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104753:	01 d0                	add    %edx,%eax
f0104755:	8b 40 10             	mov    0x10(%eax),%eax
f0104758:	89 45 cc             	mov    %eax,-0x34(%ebp)
		(seg).virtual_address = (uint8*)ph[index].p_va;
f010475b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010475e:	c1 e0 05             	shl    $0x5,%eax
f0104761:	89 c2                	mov    %eax,%edx
f0104763:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104766:	01 d0                	add    %edx,%eax
f0104768:	8b 40 08             	mov    0x8(%eax),%eax
f010476b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		return seg;
f010476e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104771:	89 c3                	mov    %eax,%ebx
f0104773:	8d 45 c8             	lea    -0x38(%ebp),%eax
f0104776:	ba 05 00 00 00       	mov    $0x5,%edx
f010477b:	89 df                	mov    %ebx,%edi
f010477d:	89 c6                	mov    %eax,%esi
f010477f:	89 d1                	mov    %edx,%ecx
f0104781:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104783:	eb 1c                	jmp    f01047a1 <PROGRAM_SEGMENT_FIRST+0x10c>
	}
	seg.segment_id = -1;
f0104785:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
	return seg;
f010478c:	8b 45 08             	mov    0x8(%ebp),%eax
f010478f:	89 c3                	mov    %eax,%ebx
f0104791:	8d 45 c8             	lea    -0x38(%ebp),%eax
f0104794:	ba 05 00 00 00       	mov    $0x5,%edx
f0104799:	89 df                	mov    %ebx,%edi
f010479b:	89 c6                	mov    %eax,%esi
f010479d:	89 d1                	mov    %edx,%ecx
f010479f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
}
f01047a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01047a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047a7:	5b                   	pop    %ebx
f01047a8:	5e                   	pop    %esi
f01047a9:	5f                   	pop    %edi
f01047aa:	5d                   	pop    %ebp
f01047ab:	c2 04 00             	ret    $0x4

f01047ae <get_user_program_info>:

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
f01047ae:	55                   	push   %ebp
f01047af:	89 e5                	mov    %esp,%ebp
f01047b1:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f01047b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01047bb:	eb 23                	jmp    f01047e0 <get_user_program_info+0x32>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
f01047bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01047c0:	c1 e0 04             	shl    $0x4,%eax
f01047c3:	05 60 06 12 f0       	add    $0xf0120660,%eax
f01047c8:	8b 00                	mov    (%eax),%eax
f01047ca:	83 ec 08             	sub    $0x8,%esp
f01047cd:	50                   	push   %eax
f01047ce:	ff 75 08             	pushl  0x8(%ebp)
f01047d1:	e8 af 18 00 00       	call   f0106085 <strcmp>
f01047d6:	83 c4 10             	add    $0x10,%esp
f01047d9:	85 c0                	test   %eax,%eax
f01047db:	74 0f                	je     f01047ec <get_user_program_info+0x3e>
}

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f01047dd:	ff 45 f4             	incl   -0xc(%ebp)
f01047e0:	a1 b4 06 12 f0       	mov    0xf01206b4,%eax
f01047e5:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01047e8:	7c d3                	jl     f01047bd <get_user_program_info+0xf>
f01047ea:	eb 01                	jmp    f01047ed <get_user_program_info+0x3f>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
			break;
f01047ec:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f01047ed:	a1 b4 06 12 f0       	mov    0xf01206b4,%eax
f01047f2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01047f5:	75 1a                	jne    f0104811 <get_user_program_info+0x63>
	{
		cprintf("Unknown user program '%s'\n", user_program_name);
f01047f7:	83 ec 08             	sub    $0x8,%esp
f01047fa:	ff 75 08             	pushl  0x8(%ebp)
f01047fd:	68 55 88 10 f0       	push   $0xf0108855
f0104802:	e8 7e 02 00 00       	call   f0104a85 <cprintf>
f0104807:	83 c4 10             	add    $0x10,%esp
		return 0;
f010480a:	b8 00 00 00 00       	mov    $0x0,%eax
f010480f:	eb 0b                	jmp    f010481c <get_user_program_info+0x6e>
	}

	return &userPrograms[i];
f0104811:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104814:	c1 e0 04             	shl    $0x4,%eax
f0104817:	05 60 06 12 f0       	add    $0xf0120660,%eax
				}
f010481c:	c9                   	leave  
f010481d:	c3                   	ret    

f010481e <get_user_program_info_by_env>:

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
f010481e:	55                   	push   %ebp
f010481f:	89 e5                	mov    %esp,%ebp
f0104821:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0104824:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010482b:	eb 15                	jmp    f0104842 <get_user_program_info_by_env+0x24>
		if (e== userPrograms[i].environment)
f010482d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104830:	c1 e0 04             	shl    $0x4,%eax
f0104833:	05 6c 06 12 f0       	add    $0xf012066c,%eax
f0104838:	8b 00                	mov    (%eax),%eax
f010483a:	3b 45 08             	cmp    0x8(%ebp),%eax
f010483d:	74 0f                	je     f010484e <get_user_program_info_by_env+0x30>
				}

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f010483f:	ff 45 f4             	incl   -0xc(%ebp)
f0104842:	a1 b4 06 12 f0       	mov    0xf01206b4,%eax
f0104847:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010484a:	7c e1                	jl     f010482d <get_user_program_info_by_env+0xf>
f010484c:	eb 01                	jmp    f010484f <get_user_program_info_by_env+0x31>
		if (e== userPrograms[i].environment)
			break;
f010484e:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f010484f:	a1 b4 06 12 f0       	mov    0xf01206b4,%eax
f0104854:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0104857:	75 17                	jne    f0104870 <get_user_program_info_by_env+0x52>
	{
		cprintf("Unknown user program \n");
f0104859:	83 ec 0c             	sub    $0xc,%esp
f010485c:	68 70 88 10 f0       	push   $0xf0108870
f0104861:	e8 1f 02 00 00       	call   f0104a85 <cprintf>
f0104866:	83 c4 10             	add    $0x10,%esp
		return 0;
f0104869:	b8 00 00 00 00       	mov    $0x0,%eax
f010486e:	eb 0b                	jmp    f010487b <get_user_program_info_by_env+0x5d>
	}

	return &userPrograms[i];
f0104870:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104873:	c1 e0 04             	shl    $0x4,%eax
f0104876:	05 60 06 12 f0       	add    $0xf0120660,%eax
				}
f010487b:	c9                   	leave  
f010487c:	c3                   	ret    

f010487d <set_environment_entry_point>:

void set_environment_entry_point(struct UserProgramInfo* ptr_user_program)
{
f010487d:	55                   	push   %ebp
f010487e:	89 e5                	mov    %esp,%ebp
f0104880:	83 ec 18             	sub    $0x18,%esp
	uint8* ptr_program_start=ptr_user_program->ptr_start;
f0104883:	8b 45 08             	mov    0x8(%ebp),%eax
f0104886:	8b 40 08             	mov    0x8(%eax),%eax
f0104889:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Env* e = ptr_user_program->environment;
f010488c:	8b 45 08             	mov    0x8(%ebp),%eax
f010488f:	8b 40 0c             	mov    0xc(%eax),%eax
f0104892:	89 45 f0             	mov    %eax,-0x10(%ebp)

	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f0104895:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104898:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f010489b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010489e:	8b 00                	mov    (%eax),%eax
f01048a0:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01048a5:	74 17                	je     f01048be <set_environment_entry_point+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01048a7:	83 ec 04             	sub    $0x4,%esp
f01048aa:	68 3f 88 10 f0       	push   $0xf010883f
f01048af:	68 d9 01 00 00       	push   $0x1d9
f01048b4:	68 c5 87 10 f0       	push   $0xf01087c5
f01048b9:	e8 70 b8 ff ff       	call   f010012e <_panic>
	e->env_tf.tf_eip = (uint32*)pELFHDR->e_entry ;
f01048be:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01048c1:	8b 40 18             	mov    0x18(%eax),%eax
f01048c4:	89 c2                	mov    %eax,%edx
f01048c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01048c9:	89 50 30             	mov    %edx,0x30(%eax)
}
f01048cc:	90                   	nop
f01048cd:	c9                   	leave  
f01048ce:	c3                   	ret    

f01048cf <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f01048cf:	55                   	push   %ebp
f01048d0:	89 e5                	mov    %esp,%ebp
f01048d2:	83 ec 08             	sub    $0x8,%esp
	env_free(e);
f01048d5:	83 ec 0c             	sub    $0xc,%esp
f01048d8:	ff 75 08             	pushl  0x8(%ebp)
f01048db:	e8 40 fa ff ff       	call   f0104320 <env_free>
f01048e0:	83 c4 10             	add    $0x10,%esp

	//cprintf("Destroyed the only environment - nothing more to do!\n");
	while (1)
		run_command_prompt();
f01048e3:	e8 69 c0 ff ff       	call   f0100951 <run_command_prompt>
f01048e8:	eb f9                	jmp    f01048e3 <env_destroy+0x14>

f01048ea <env_run_cmd_prmpt>:
}

void env_run_cmd_prmpt()
{
f01048ea:	55                   	push   %ebp
f01048eb:	89 e5                	mov    %esp,%ebp
f01048ed:	83 ec 18             	sub    $0x18,%esp
	struct UserProgramInfo* upi= get_user_program_info_by_env(curenv);	
f01048f0:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01048f5:	83 ec 0c             	sub    $0xc,%esp
f01048f8:	50                   	push   %eax
f01048f9:	e8 20 ff ff ff       	call   f010481e <get_user_program_info_by_env>
f01048fe:	83 c4 10             	add    $0x10,%esp
f0104901:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&curenv->env_tf, 0, sizeof(curenv->env_tf));
f0104904:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104909:	83 ec 04             	sub    $0x4,%esp
f010490c:	6a 44                	push   $0x44
f010490e:	6a 00                	push   $0x0
f0104910:	50                   	push   %eax
f0104911:	e8 51 18 00 00       	call   f0106167 <memset>
f0104916:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	curenv->env_tf.tf_ds = GD_UD | 3;
f0104919:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f010491e:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	curenv->env_tf.tf_es = GD_UD | 3;
f0104924:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104929:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	curenv->env_tf.tf_ss = GD_UD | 3;
f010492f:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104934:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	curenv->env_tf.tf_esp = (uint32*)USTACKTOP;
f010493a:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f010493f:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	curenv->env_tf.tf_cs = GD_UT | 3;
f0104946:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f010494b:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	set_environment_entry_point(upi);
f0104951:	83 ec 0c             	sub    $0xc,%esp
f0104954:	ff 75 f4             	pushl  -0xc(%ebp)
f0104957:	e8 21 ff ff ff       	call   f010487d <set_environment_entry_point>
f010495c:	83 c4 10             	add    $0x10,%esp

	lcr3(K_PHYSICAL_ADDRESS(ptr_page_directory));
f010495f:	a1 54 44 15 f0       	mov    0xf0154454,%eax
f0104964:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104967:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f010496e:	77 17                	ja     f0104987 <env_run_cmd_prmpt+0x9d>
f0104970:	ff 75 f0             	pushl  -0x10(%ebp)
f0104973:	68 88 88 10 f0       	push   $0xf0108888
f0104978:	68 04 02 00 00       	push   $0x204
f010497d:	68 c5 87 10 f0       	push   $0xf01087c5
f0104982:	e8 a7 b7 ff ff       	call   f010012e <_panic>
f0104987:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010498a:	05 00 00 00 10       	add    $0x10000000,%eax
f010498f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104992:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104995:	0f 22 d8             	mov    %eax,%cr3

	curenv = NULL;
f0104998:	c7 05 14 2f 15 f0 00 	movl   $0x0,0xf0152f14
f010499f:	00 00 00 

	while (1)
		run_command_prompt();
f01049a2:	e8 aa bf ff ff       	call   f0100951 <run_command_prompt>
f01049a7:	eb f9                	jmp    f01049a2 <env_run_cmd_prmpt+0xb8>

f01049a9 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01049a9:	55                   	push   %ebp
f01049aa:	89 e5                	mov    %esp,%ebp
f01049ac:	83 ec 08             	sub    $0x8,%esp
	__asm __volatile("movl %0,%%esp\n"
f01049af:	8b 65 08             	mov    0x8(%ebp),%esp
f01049b2:	61                   	popa   
f01049b3:	07                   	pop    %es
f01049b4:	1f                   	pop    %ds
f01049b5:	83 c4 08             	add    $0x8,%esp
f01049b8:	cf                   	iret   
			"\tpopl %%es\n"
			"\tpopl %%ds\n"
			"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
			"\tiret"
			: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01049b9:	83 ec 04             	sub    $0x4,%esp
f01049bc:	68 b9 88 10 f0       	push   $0xf01088b9
f01049c1:	68 1b 02 00 00       	push   $0x21b
f01049c6:	68 c5 87 10 f0       	push   $0xf01087c5
f01049cb:	e8 5e b7 ff ff       	call   f010012e <_panic>

f01049d0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01049d0:	55                   	push   %ebp
f01049d1:	89 e5                	mov    %esp,%ebp
f01049d3:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f01049d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01049d9:	0f b6 c0             	movzbl %al,%eax
f01049dc:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f01049e3:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01049e6:	8a 45 f6             	mov    -0xa(%ebp),%al
f01049e9:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01049ec:	ee                   	out    %al,(%dx)
f01049ed:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01049f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01049f7:	89 c2                	mov    %eax,%edx
f01049f9:	ec                   	in     (%dx),%al
f01049fa:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01049fd:	8a 45 f7             	mov    -0x9(%ebp),%al
	return inb(IO_RTC+1);
f0104a00:	0f b6 c0             	movzbl %al,%eax
}
f0104a03:	c9                   	leave  
f0104a04:	c3                   	ret    

f0104a05 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0104a05:	55                   	push   %ebp
f0104a06:	89 e5                	mov    %esp,%ebp
f0104a08:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0104a0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a0e:	0f b6 c0             	movzbl %al,%eax
f0104a11:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0104a18:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0104a1b:	8a 45 f6             	mov    -0xa(%ebp),%al
f0104a1e:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0104a21:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f0104a22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a25:	0f b6 c0             	movzbl %al,%eax
f0104a28:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)
f0104a2f:	88 45 f7             	mov    %al,-0x9(%ebp)
f0104a32:	8a 45 f7             	mov    -0x9(%ebp),%al
f0104a35:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0104a38:	ee                   	out    %al,(%dx)
}
f0104a39:	90                   	nop
f0104a3a:	c9                   	leave  
f0104a3b:	c3                   	ret    

f0104a3c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0104a3c:	55                   	push   %ebp
f0104a3d:	89 e5                	mov    %esp,%ebp
f0104a3f:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0104a42:	83 ec 0c             	sub    $0xc,%esp
f0104a45:	ff 75 08             	pushl  0x8(%ebp)
f0104a48:	e8 ca be ff ff       	call   f0100917 <cputchar>
f0104a4d:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f0104a50:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a53:	83 c0 04             	add    $0x4,%eax
f0104a56:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0104a59:	90                   	nop
f0104a5a:	c9                   	leave  
f0104a5b:	c3                   	ret    

f0104a5c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0104a5c:	55                   	push   %ebp
f0104a5d:	89 e5                	mov    %esp,%ebp
f0104a5f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0104a62:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0104a69:	ff 75 0c             	pushl  0xc(%ebp)
f0104a6c:	ff 75 08             	pushl  0x8(%ebp)
f0104a6f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104a72:	50                   	push   %eax
f0104a73:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0104a78:	e8 56 0f 00 00       	call   f01059d3 <vprintfmt>
f0104a7d:	83 c4 10             	add    $0x10,%esp
	return cnt;
f0104a80:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0104a83:	c9                   	leave  
f0104a84:	c3                   	ret    

f0104a85 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0104a85:	55                   	push   %ebp
f0104a86:	89 e5                	mov    %esp,%ebp
f0104a88:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104a8b:	8d 45 0c             	lea    0xc(%ebp),%eax
f0104a8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f0104a91:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a94:	83 ec 08             	sub    $0x8,%esp
f0104a97:	ff 75 f4             	pushl  -0xc(%ebp)
f0104a9a:	50                   	push   %eax
f0104a9b:	e8 bc ff ff ff       	call   f0104a5c <vcprintf>
f0104aa0:	83 c4 10             	add    $0x10,%esp
f0104aa3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f0104aa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0104aa9:	c9                   	leave  
f0104aaa:	c3                   	ret    

f0104aab <trapname>:
};
extern  void (*PAGE_FAULT)();
extern  void (*SYSCALL_HANDLER)();

static const char *trapname(int trapno)
{
f0104aab:	55                   	push   %ebp
f0104aac:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0104aae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab1:	83 f8 13             	cmp    $0x13,%eax
f0104ab4:	77 0c                	ja     f0104ac2 <trapname+0x17>
		return excnames[trapno];
f0104ab6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab9:	8b 04 85 00 8c 10 f0 	mov    -0xfef7400(,%eax,4),%eax
f0104ac0:	eb 12                	jmp    f0104ad4 <trapname+0x29>
	if (trapno == T_SYSCALL)
f0104ac2:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
f0104ac6:	75 07                	jne    f0104acf <trapname+0x24>
		return "System call";
f0104ac8:	b8 e0 88 10 f0       	mov    $0xf01088e0,%eax
f0104acd:	eb 05                	jmp    f0104ad4 <trapname+0x29>
	return "(unknown trap)";
f0104acf:	b8 ec 88 10 f0       	mov    $0xf01088ec,%eax
}
f0104ad4:	5d                   	pop    %ebp
f0104ad5:	c3                   	ret    

f0104ad6 <idt_init>:


void
idt_init(void)
{
f0104ad6:	55                   	push   %ebp
f0104ad7:	89 e5                	mov    %esp,%ebp
f0104ad9:	83 ec 10             	sub    $0x10,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	//initialize idt
	SETGATE(idt[T_PGFLT], 0, GD_KT , &PAGE_FAULT, 0) ;
f0104adc:	b8 34 50 10 f0       	mov    $0xf0105034,%eax
f0104ae1:	66 a3 90 2f 15 f0    	mov    %ax,0xf0152f90
f0104ae7:	66 c7 05 92 2f 15 f0 	movw   $0x8,0xf0152f92
f0104aee:	08 00 
f0104af0:	a0 94 2f 15 f0       	mov    0xf0152f94,%al
f0104af5:	83 e0 e0             	and    $0xffffffe0,%eax
f0104af8:	a2 94 2f 15 f0       	mov    %al,0xf0152f94
f0104afd:	a0 94 2f 15 f0       	mov    0xf0152f94,%al
f0104b02:	83 e0 1f             	and    $0x1f,%eax
f0104b05:	a2 94 2f 15 f0       	mov    %al,0xf0152f94
f0104b0a:	a0 95 2f 15 f0       	mov    0xf0152f95,%al
f0104b0f:	83 e0 f0             	and    $0xfffffff0,%eax
f0104b12:	83 c8 0e             	or     $0xe,%eax
f0104b15:	a2 95 2f 15 f0       	mov    %al,0xf0152f95
f0104b1a:	a0 95 2f 15 f0       	mov    0xf0152f95,%al
f0104b1f:	83 e0 ef             	and    $0xffffffef,%eax
f0104b22:	a2 95 2f 15 f0       	mov    %al,0xf0152f95
f0104b27:	a0 95 2f 15 f0       	mov    0xf0152f95,%al
f0104b2c:	83 e0 9f             	and    $0xffffff9f,%eax
f0104b2f:	a2 95 2f 15 f0       	mov    %al,0xf0152f95
f0104b34:	a0 95 2f 15 f0       	mov    0xf0152f95,%al
f0104b39:	83 c8 80             	or     $0xffffff80,%eax
f0104b3c:	a2 95 2f 15 f0       	mov    %al,0xf0152f95
f0104b41:	b8 34 50 10 f0       	mov    $0xf0105034,%eax
f0104b46:	c1 e8 10             	shr    $0x10,%eax
f0104b49:	66 a3 96 2f 15 f0    	mov    %ax,0xf0152f96
	SETGATE(idt[T_SYSCALL], 0, GD_KT , &SYSCALL_HANDLER, 3) ;
f0104b4f:	b8 38 50 10 f0       	mov    $0xf0105038,%eax
f0104b54:	66 a3 a0 30 15 f0    	mov    %ax,0xf01530a0
f0104b5a:	66 c7 05 a2 30 15 f0 	movw   $0x8,0xf01530a2
f0104b61:	08 00 
f0104b63:	a0 a4 30 15 f0       	mov    0xf01530a4,%al
f0104b68:	83 e0 e0             	and    $0xffffffe0,%eax
f0104b6b:	a2 a4 30 15 f0       	mov    %al,0xf01530a4
f0104b70:	a0 a4 30 15 f0       	mov    0xf01530a4,%al
f0104b75:	83 e0 1f             	and    $0x1f,%eax
f0104b78:	a2 a4 30 15 f0       	mov    %al,0xf01530a4
f0104b7d:	a0 a5 30 15 f0       	mov    0xf01530a5,%al
f0104b82:	83 e0 f0             	and    $0xfffffff0,%eax
f0104b85:	83 c8 0e             	or     $0xe,%eax
f0104b88:	a2 a5 30 15 f0       	mov    %al,0xf01530a5
f0104b8d:	a0 a5 30 15 f0       	mov    0xf01530a5,%al
f0104b92:	83 e0 ef             	and    $0xffffffef,%eax
f0104b95:	a2 a5 30 15 f0       	mov    %al,0xf01530a5
f0104b9a:	a0 a5 30 15 f0       	mov    0xf01530a5,%al
f0104b9f:	83 c8 60             	or     $0x60,%eax
f0104ba2:	a2 a5 30 15 f0       	mov    %al,0xf01530a5
f0104ba7:	a0 a5 30 15 f0       	mov    0xf01530a5,%al
f0104bac:	83 c8 80             	or     $0xffffff80,%eax
f0104baf:	a2 a5 30 15 f0       	mov    %al,0xf01530a5
f0104bb4:	b8 38 50 10 f0       	mov    $0xf0105038,%eax
f0104bb9:	c1 e8 10             	shr    $0x10,%eax
f0104bbc:	66 a3 a6 30 15 f0    	mov    %ax,0xf01530a6

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KERNEL_STACK_TOP;
f0104bc2:	c7 05 24 37 15 f0 00 	movl   $0xefc00000,0xf0153724
f0104bc9:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f0104bcc:	66 c7 05 28 37 15 f0 	movw   $0x10,0xf0153728
f0104bd3:	10 00 

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32) (&ts),
f0104bd5:	66 c7 05 48 06 12 f0 	movw   $0x68,0xf0120648
f0104bdc:	68 00 
f0104bde:	b8 20 37 15 f0       	mov    $0xf0153720,%eax
f0104be3:	66 a3 4a 06 12 f0    	mov    %ax,0xf012064a
f0104be9:	b8 20 37 15 f0       	mov    $0xf0153720,%eax
f0104bee:	c1 e8 10             	shr    $0x10,%eax
f0104bf1:	a2 4c 06 12 f0       	mov    %al,0xf012064c
f0104bf6:	a0 4d 06 12 f0       	mov    0xf012064d,%al
f0104bfb:	83 e0 f0             	and    $0xfffffff0,%eax
f0104bfe:	83 c8 09             	or     $0x9,%eax
f0104c01:	a2 4d 06 12 f0       	mov    %al,0xf012064d
f0104c06:	a0 4d 06 12 f0       	mov    0xf012064d,%al
f0104c0b:	83 c8 10             	or     $0x10,%eax
f0104c0e:	a2 4d 06 12 f0       	mov    %al,0xf012064d
f0104c13:	a0 4d 06 12 f0       	mov    0xf012064d,%al
f0104c18:	83 e0 9f             	and    $0xffffff9f,%eax
f0104c1b:	a2 4d 06 12 f0       	mov    %al,0xf012064d
f0104c20:	a0 4d 06 12 f0       	mov    0xf012064d,%al
f0104c25:	83 c8 80             	or     $0xffffff80,%eax
f0104c28:	a2 4d 06 12 f0       	mov    %al,0xf012064d
f0104c2d:	a0 4e 06 12 f0       	mov    0xf012064e,%al
f0104c32:	83 e0 f0             	and    $0xfffffff0,%eax
f0104c35:	a2 4e 06 12 f0       	mov    %al,0xf012064e
f0104c3a:	a0 4e 06 12 f0       	mov    0xf012064e,%al
f0104c3f:	83 e0 ef             	and    $0xffffffef,%eax
f0104c42:	a2 4e 06 12 f0       	mov    %al,0xf012064e
f0104c47:	a0 4e 06 12 f0       	mov    0xf012064e,%al
f0104c4c:	83 e0 df             	and    $0xffffffdf,%eax
f0104c4f:	a2 4e 06 12 f0       	mov    %al,0xf012064e
f0104c54:	a0 4e 06 12 f0       	mov    0xf012064e,%al
f0104c59:	83 c8 40             	or     $0x40,%eax
f0104c5c:	a2 4e 06 12 f0       	mov    %al,0xf012064e
f0104c61:	a0 4e 06 12 f0       	mov    0xf012064e,%al
f0104c66:	83 e0 7f             	and    $0x7f,%eax
f0104c69:	a2 4e 06 12 f0       	mov    %al,0xf012064e
f0104c6e:	b8 20 37 15 f0       	mov    $0xf0153720,%eax
f0104c73:	c1 e8 18             	shr    $0x18,%eax
f0104c76:	a2 4f 06 12 f0       	mov    %al,0xf012064f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;
f0104c7b:	a0 4d 06 12 f0       	mov    0xf012064d,%al
f0104c80:	83 e0 ef             	and    $0xffffffef,%eax
f0104c83:	a2 4d 06 12 f0       	mov    %al,0xf012064d
f0104c88:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
}

static __inline void
ltr(uint16 sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0104c8e:	66 8b 45 fe          	mov    -0x2(%ebp),%ax
f0104c92:	0f 00 d8             	ltr    %ax

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
f0104c95:	0f 01 1d b8 06 12 f0 	lidtl  0xf01206b8
}
f0104c9c:	90                   	nop
f0104c9d:	c9                   	leave  
f0104c9e:	c3                   	ret    

f0104c9f <print_trapframe>:

void
print_trapframe(struct Trapframe *tf)
{
f0104c9f:	55                   	push   %ebp
f0104ca0:	89 e5                	mov    %esp,%ebp
f0104ca2:	83 ec 08             	sub    $0x8,%esp
	cprintf("TRAP frame at %p\n", tf);
f0104ca5:	83 ec 08             	sub    $0x8,%esp
f0104ca8:	ff 75 08             	pushl  0x8(%ebp)
f0104cab:	68 fb 88 10 f0       	push   $0xf01088fb
f0104cb0:	e8 d0 fd ff ff       	call   f0104a85 <cprintf>
f0104cb5:	83 c4 10             	add    $0x10,%esp
	print_regs(&tf->tf_regs);
f0104cb8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cbb:	83 ec 0c             	sub    $0xc,%esp
f0104cbe:	50                   	push   %eax
f0104cbf:	e8 f6 00 00 00       	call   f0104dba <print_regs>
f0104cc4:	83 c4 10             	add    $0x10,%esp
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104cc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cca:	8b 40 20             	mov    0x20(%eax),%eax
f0104ccd:	0f b7 c0             	movzwl %ax,%eax
f0104cd0:	83 ec 08             	sub    $0x8,%esp
f0104cd3:	50                   	push   %eax
f0104cd4:	68 0d 89 10 f0       	push   $0xf010890d
f0104cd9:	e8 a7 fd ff ff       	call   f0104a85 <cprintf>
f0104cde:	83 c4 10             	add    $0x10,%esp
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104ce1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ce4:	8b 40 24             	mov    0x24(%eax),%eax
f0104ce7:	0f b7 c0             	movzwl %ax,%eax
f0104cea:	83 ec 08             	sub    $0x8,%esp
f0104ced:	50                   	push   %eax
f0104cee:	68 20 89 10 f0       	push   $0xf0108920
f0104cf3:	e8 8d fd ff ff       	call   f0104a85 <cprintf>
f0104cf8:	83 c4 10             	add    $0x10,%esp
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104cfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cfe:	8b 40 28             	mov    0x28(%eax),%eax
f0104d01:	83 ec 0c             	sub    $0xc,%esp
f0104d04:	50                   	push   %eax
f0104d05:	e8 a1 fd ff ff       	call   f0104aab <trapname>
f0104d0a:	83 c4 10             	add    $0x10,%esp
f0104d0d:	89 c2                	mov    %eax,%edx
f0104d0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d12:	8b 40 28             	mov    0x28(%eax),%eax
f0104d15:	83 ec 04             	sub    $0x4,%esp
f0104d18:	52                   	push   %edx
f0104d19:	50                   	push   %eax
f0104d1a:	68 33 89 10 f0       	push   $0xf0108933
f0104d1f:	e8 61 fd ff ff       	call   f0104a85 <cprintf>
f0104d24:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x\n", tf->tf_err);
f0104d27:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d2a:	8b 40 2c             	mov    0x2c(%eax),%eax
f0104d2d:	83 ec 08             	sub    $0x8,%esp
f0104d30:	50                   	push   %eax
f0104d31:	68 45 89 10 f0       	push   $0xf0108945
f0104d36:	e8 4a fd ff ff       	call   f0104a85 <cprintf>
f0104d3b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104d3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d41:	8b 40 30             	mov    0x30(%eax),%eax
f0104d44:	83 ec 08             	sub    $0x8,%esp
f0104d47:	50                   	push   %eax
f0104d48:	68 54 89 10 f0       	push   $0xf0108954
f0104d4d:	e8 33 fd ff ff       	call   f0104a85 <cprintf>
f0104d52:	83 c4 10             	add    $0x10,%esp
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104d55:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d58:	8b 40 34             	mov    0x34(%eax),%eax
f0104d5b:	0f b7 c0             	movzwl %ax,%eax
f0104d5e:	83 ec 08             	sub    $0x8,%esp
f0104d61:	50                   	push   %eax
f0104d62:	68 63 89 10 f0       	push   $0xf0108963
f0104d67:	e8 19 fd ff ff       	call   f0104a85 <cprintf>
f0104d6c:	83 c4 10             	add    $0x10,%esp
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104d6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d72:	8b 40 38             	mov    0x38(%eax),%eax
f0104d75:	83 ec 08             	sub    $0x8,%esp
f0104d78:	50                   	push   %eax
f0104d79:	68 76 89 10 f0       	push   $0xf0108976
f0104d7e:	e8 02 fd ff ff       	call   f0104a85 <cprintf>
f0104d83:	83 c4 10             	add    $0x10,%esp
	cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104d86:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d89:	8b 40 3c             	mov    0x3c(%eax),%eax
f0104d8c:	83 ec 08             	sub    $0x8,%esp
f0104d8f:	50                   	push   %eax
f0104d90:	68 85 89 10 f0       	push   $0xf0108985
f0104d95:	e8 eb fc ff ff       	call   f0104a85 <cprintf>
f0104d9a:	83 c4 10             	add    $0x10,%esp
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104d9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104da0:	8b 40 40             	mov    0x40(%eax),%eax
f0104da3:	0f b7 c0             	movzwl %ax,%eax
f0104da6:	83 ec 08             	sub    $0x8,%esp
f0104da9:	50                   	push   %eax
f0104daa:	68 94 89 10 f0       	push   $0xf0108994
f0104daf:	e8 d1 fc ff ff       	call   f0104a85 <cprintf>
f0104db4:	83 c4 10             	add    $0x10,%esp
}
f0104db7:	90                   	nop
f0104db8:	c9                   	leave  
f0104db9:	c3                   	ret    

f0104dba <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f0104dba:	55                   	push   %ebp
f0104dbb:	89 e5                	mov    %esp,%ebp
f0104dbd:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104dc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dc3:	8b 00                	mov    (%eax),%eax
f0104dc5:	83 ec 08             	sub    $0x8,%esp
f0104dc8:	50                   	push   %eax
f0104dc9:	68 a7 89 10 f0       	push   $0xf01089a7
f0104dce:	e8 b2 fc ff ff       	call   f0104a85 <cprintf>
f0104dd3:	83 c4 10             	add    $0x10,%esp
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104dd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dd9:	8b 40 04             	mov    0x4(%eax),%eax
f0104ddc:	83 ec 08             	sub    $0x8,%esp
f0104ddf:	50                   	push   %eax
f0104de0:	68 b6 89 10 f0       	push   $0xf01089b6
f0104de5:	e8 9b fc ff ff       	call   f0104a85 <cprintf>
f0104dea:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104ded:	8b 45 08             	mov    0x8(%ebp),%eax
f0104df0:	8b 40 08             	mov    0x8(%eax),%eax
f0104df3:	83 ec 08             	sub    $0x8,%esp
f0104df6:	50                   	push   %eax
f0104df7:	68 c5 89 10 f0       	push   $0xf01089c5
f0104dfc:	e8 84 fc ff ff       	call   f0104a85 <cprintf>
f0104e01:	83 c4 10             	add    $0x10,%esp
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104e04:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e07:	8b 40 0c             	mov    0xc(%eax),%eax
f0104e0a:	83 ec 08             	sub    $0x8,%esp
f0104e0d:	50                   	push   %eax
f0104e0e:	68 d4 89 10 f0       	push   $0xf01089d4
f0104e13:	e8 6d fc ff ff       	call   f0104a85 <cprintf>
f0104e18:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104e1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e1e:	8b 40 10             	mov    0x10(%eax),%eax
f0104e21:	83 ec 08             	sub    $0x8,%esp
f0104e24:	50                   	push   %eax
f0104e25:	68 e3 89 10 f0       	push   $0xf01089e3
f0104e2a:	e8 56 fc ff ff       	call   f0104a85 <cprintf>
f0104e2f:	83 c4 10             	add    $0x10,%esp
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104e32:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e35:	8b 40 14             	mov    0x14(%eax),%eax
f0104e38:	83 ec 08             	sub    $0x8,%esp
f0104e3b:	50                   	push   %eax
f0104e3c:	68 f2 89 10 f0       	push   $0xf01089f2
f0104e41:	e8 3f fc ff ff       	call   f0104a85 <cprintf>
f0104e46:	83 c4 10             	add    $0x10,%esp
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104e49:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e4c:	8b 40 18             	mov    0x18(%eax),%eax
f0104e4f:	83 ec 08             	sub    $0x8,%esp
f0104e52:	50                   	push   %eax
f0104e53:	68 01 8a 10 f0       	push   $0xf0108a01
f0104e58:	e8 28 fc ff ff       	call   f0104a85 <cprintf>
f0104e5d:	83 c4 10             	add    $0x10,%esp
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104e60:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e63:	8b 40 1c             	mov    0x1c(%eax),%eax
f0104e66:	83 ec 08             	sub    $0x8,%esp
f0104e69:	50                   	push   %eax
f0104e6a:	68 10 8a 10 f0       	push   $0xf0108a10
f0104e6f:	e8 11 fc ff ff       	call   f0104a85 <cprintf>
f0104e74:	83 c4 10             	add    $0x10,%esp
}
f0104e77:	90                   	nop
f0104e78:	c9                   	leave  
f0104e79:	c3                   	ret    

f0104e7a <trap_dispatch>:

static void
trap_dispatch(struct Trapframe *tf)
{
f0104e7a:	55                   	push   %ebp
f0104e7b:	89 e5                	mov    %esp,%ebp
f0104e7d:	57                   	push   %edi
f0104e7e:	56                   	push   %esi
f0104e7f:	53                   	push   %ebx
f0104e80:	83 ec 1c             	sub    $0x1c,%esp
	// Handle processor exceptions.
	// LAB 3: Your code here.

	if(tf->tf_trapno == T_PGFLT)
f0104e83:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e86:	8b 40 28             	mov    0x28(%eax),%eax
f0104e89:	83 f8 0e             	cmp    $0xe,%eax
f0104e8c:	75 13                	jne    f0104ea1 <trap_dispatch+0x27>
	{
		page_fault_handler(tf);
f0104e8e:	83 ec 0c             	sub    $0xc,%esp
f0104e91:	ff 75 08             	pushl  0x8(%ebp)
f0104e94:	e8 47 01 00 00       	call   f0104fe0 <page_fault_handler>
f0104e99:	83 c4 10             	add    $0x10,%esp
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0104e9c:	e9 90 00 00 00       	jmp    f0104f31 <trap_dispatch+0xb7>

	if(tf->tf_trapno == T_PGFLT)
	{
		page_fault_handler(tf);
	}
	else if (tf->tf_trapno == T_SYSCALL)
f0104ea1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ea4:	8b 40 28             	mov    0x28(%eax),%eax
f0104ea7:	83 f8 30             	cmp    $0x30,%eax
f0104eaa:	75 42                	jne    f0104eee <trap_dispatch+0x74>
	{
		uint32 ret = syscall(tf->tf_regs.reg_eax
f0104eac:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eaf:	8b 78 04             	mov    0x4(%eax),%edi
f0104eb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eb5:	8b 30                	mov    (%eax),%esi
f0104eb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eba:	8b 58 10             	mov    0x10(%eax),%ebx
f0104ebd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ec0:	8b 48 18             	mov    0x18(%eax),%ecx
f0104ec3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ec6:	8b 50 14             	mov    0x14(%eax),%edx
f0104ec9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ecc:	8b 40 1c             	mov    0x1c(%eax),%eax
f0104ecf:	83 ec 08             	sub    $0x8,%esp
f0104ed2:	57                   	push   %edi
f0104ed3:	56                   	push   %esi
f0104ed4:	53                   	push   %ebx
f0104ed5:	51                   	push   %ecx
f0104ed6:	52                   	push   %edx
f0104ed7:	50                   	push   %eax
f0104ed8:	e8 47 04 00 00       	call   f0105324 <syscall>
f0104edd:	83 c4 20             	add    $0x20,%esp
f0104ee0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			,tf->tf_regs.reg_edx
			,tf->tf_regs.reg_ecx
			,tf->tf_regs.reg_ebx
			,tf->tf_regs.reg_edi
					,tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f0104ee3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ee6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104ee9:	89 50 1c             	mov    %edx,0x1c(%eax)
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0104eec:	eb 43                	jmp    f0104f31 <trap_dispatch+0xb7>
		tf->tf_regs.reg_eax = ret;
	}
	else
	{
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0104eee:	83 ec 0c             	sub    $0xc,%esp
f0104ef1:	ff 75 08             	pushl  0x8(%ebp)
f0104ef4:	e8 a6 fd ff ff       	call   f0104c9f <print_trapframe>
f0104ef9:	83 c4 10             	add    $0x10,%esp
		if (tf->tf_cs == GD_KT)
f0104efc:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eff:	8b 40 34             	mov    0x34(%eax),%eax
f0104f02:	66 83 f8 08          	cmp    $0x8,%ax
f0104f06:	75 17                	jne    f0104f1f <trap_dispatch+0xa5>
			panic("unhandled trap in kernel");
f0104f08:	83 ec 04             	sub    $0x4,%esp
f0104f0b:	68 1f 8a 10 f0       	push   $0xf0108a1f
f0104f10:	68 8a 00 00 00       	push   $0x8a
f0104f15:	68 38 8a 10 f0       	push   $0xf0108a38
f0104f1a:	e8 0f b2 ff ff       	call   f010012e <_panic>
		else {
			env_destroy(curenv);
f0104f1f:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104f24:	83 ec 0c             	sub    $0xc,%esp
f0104f27:	50                   	push   %eax
f0104f28:	e8 a2 f9 ff ff       	call   f01048cf <env_destroy>
f0104f2d:	83 c4 10             	add    $0x10,%esp
			return;
f0104f30:	90                   	nop
		}
	}
	return;
}
f0104f31:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f34:	5b                   	pop    %ebx
f0104f35:	5e                   	pop    %esi
f0104f36:	5f                   	pop    %edi
f0104f37:	5d                   	pop    %ebp
f0104f38:	c3                   	ret    

f0104f39 <trap>:

void
trap(struct Trapframe *tf)
{
f0104f39:	55                   	push   %ebp
f0104f3a:	89 e5                	mov    %esp,%ebp
f0104f3c:	57                   	push   %edi
f0104f3d:	56                   	push   %esi
f0104f3e:	53                   	push   %ebx
f0104f3f:	83 ec 0c             	sub    $0xc,%esp
	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f0104f42:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f45:	8b 40 34             	mov    0x34(%eax),%eax
f0104f48:	0f b7 c0             	movzwl %ax,%eax
f0104f4b:	83 e0 03             	and    $0x3,%eax
f0104f4e:	83 f8 03             	cmp    $0x3,%eax
f0104f51:	75 42                	jne    f0104f95 <trap+0x5c>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0104f53:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104f58:	85 c0                	test   %eax,%eax
f0104f5a:	75 19                	jne    f0104f75 <trap+0x3c>
f0104f5c:	68 44 8a 10 f0       	push   $0xf0108a44
f0104f61:	68 4b 8a 10 f0       	push   $0xf0108a4b
f0104f66:	68 9d 00 00 00       	push   $0x9d
f0104f6b:	68 38 8a 10 f0       	push   $0xf0108a38
f0104f70:	e8 b9 b1 ff ff       	call   f010012e <_panic>
		curenv->env_tf = *tf;
f0104f75:	8b 15 14 2f 15 f0    	mov    0xf0152f14,%edx
f0104f7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f7e:	89 c3                	mov    %eax,%ebx
f0104f80:	b8 11 00 00 00       	mov    $0x11,%eax
f0104f85:	89 d7                	mov    %edx,%edi
f0104f87:	89 de                	mov    %ebx,%esi
f0104f89:	89 c1                	mov    %eax,%ecx
f0104f8b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104f8d:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104f92:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0104f95:	83 ec 0c             	sub    $0xc,%esp
f0104f98:	ff 75 08             	pushl  0x8(%ebp)
f0104f9b:	e8 da fe ff ff       	call   f0104e7a <trap_dispatch>
f0104fa0:	83 c4 10             	add    $0x10,%esp

        // Return to the current environment, which should be runnable.
        assert(curenv && curenv->env_status == ENV_RUNNABLE);
f0104fa3:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104fa8:	85 c0                	test   %eax,%eax
f0104faa:	74 0d                	je     f0104fb9 <trap+0x80>
f0104fac:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104fb1:	8b 40 54             	mov    0x54(%eax),%eax
f0104fb4:	83 f8 01             	cmp    $0x1,%eax
f0104fb7:	74 19                	je     f0104fd2 <trap+0x99>
f0104fb9:	68 60 8a 10 f0       	push   $0xf0108a60
f0104fbe:	68 4b 8a 10 f0       	push   $0xf0108a4b
f0104fc3:	68 a7 00 00 00       	push   $0xa7
f0104fc8:	68 38 8a 10 f0       	push   $0xf0108a38
f0104fcd:	e8 5c b1 ff ff       	call   f010012e <_panic>
        env_run(curenv);
f0104fd2:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0104fd7:	83 ec 0c             	sub    $0xc,%esp
f0104fda:	50                   	push   %eax
f0104fdb:	e8 fd f2 ff ff       	call   f01042dd <env_run>

f0104fe0 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104fe0:	55                   	push   %ebp
f0104fe1:	89 e5                	mov    %esp,%ebp
f0104fe3:	83 ec 18             	sub    $0x18,%esp

static __inline uint32
rcr2(void)
{
	uint32 val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0104fe6:	0f 20 d0             	mov    %cr2,%eax
f0104fe9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
f0104fec:	8b 45 f0             	mov    -0x10(%ebp),%eax
	uint32 fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0104fef:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104ff2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ff5:	8b 50 30             	mov    0x30(%eax),%edx
	curenv->env_id, fault_va, tf->tf_eip);
f0104ff8:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104ffd:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105000:	52                   	push   %edx
f0105001:	ff 75 f4             	pushl  -0xc(%ebp)
f0105004:	50                   	push   %eax
f0105005:	68 90 8a 10 f0       	push   $0xf0108a90
f010500a:	e8 76 fa ff ff       	call   f0104a85 <cprintf>
f010500f:	83 c4 10             	add    $0x10,%esp
	curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0105012:	83 ec 0c             	sub    $0xc,%esp
f0105015:	ff 75 08             	pushl  0x8(%ebp)
f0105018:	e8 82 fc ff ff       	call   f0104c9f <print_trapframe>
f010501d:	83 c4 10             	add    $0x10,%esp
	env_destroy(curenv);
f0105020:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105025:	83 ec 0c             	sub    $0xc,%esp
f0105028:	50                   	push   %eax
f0105029:	e8 a1 f8 ff ff       	call   f01048cf <env_destroy>
f010502e:	83 c4 10             	add    $0x10,%esp

}
f0105031:	90                   	nop
f0105032:	c9                   	leave  
f0105033:	c3                   	ret    

f0105034 <PAGE_FAULT>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(PAGE_FAULT, T_PGFLT)		
f0105034:	6a 0e                	push   $0xe
f0105036:	eb 06                	jmp    f010503e <_alltraps>

f0105038 <SYSCALL_HANDLER>:

TRAPHANDLER_NOEC(SYSCALL_HANDLER, T_SYSCALL)
f0105038:	6a 00                	push   $0x0
f010503a:	6a 30                	push   $0x30
f010503c:	eb 00                	jmp    f010503e <_alltraps>

f010503e <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:

push %ds 
f010503e:	1e                   	push   %ds
push %es 
f010503f:	06                   	push   %es
pushal 	
f0105040:	60                   	pusha  

mov $(GD_KD), %ax 
f0105041:	66 b8 10 00          	mov    $0x10,%ax
mov %ax,%ds
f0105045:	8e d8                	mov    %eax,%ds
mov %ax,%es
f0105047:	8e c0                	mov    %eax,%es

push %esp
f0105049:	54                   	push   %esp

call trap
f010504a:	e8 ea fe ff ff       	call   f0104f39 <trap>

pop %ecx /* poping the pointer to the tf from the stack so that the stack top is at the values of the registers posuhed by pusha*/
f010504f:	59                   	pop    %ecx
popal 	
f0105050:	61                   	popa   
pop %es 
f0105051:	07                   	pop    %es
pop %ds    
f0105052:	1f                   	pop    %ds

/*skipping the trap_no and the error code so that the stack top is at the old eip value*/
add $(8),%esp
f0105053:	83 c4 08             	add    $0x8,%esp

iret
f0105056:	cf                   	iret   

f0105057 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0105057:	55                   	push   %ebp
f0105058:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f010505a:	8b 45 08             	mov    0x8(%ebp),%eax
f010505d:	8b 15 4c 44 15 f0    	mov    0xf015444c,%edx
f0105063:	29 d0                	sub    %edx,%eax
f0105065:	c1 f8 02             	sar    $0x2,%eax
f0105068:	89 c2                	mov    %eax,%edx
f010506a:	89 d0                	mov    %edx,%eax
f010506c:	c1 e0 02             	shl    $0x2,%eax
f010506f:	01 d0                	add    %edx,%eax
f0105071:	c1 e0 02             	shl    $0x2,%eax
f0105074:	01 d0                	add    %edx,%eax
f0105076:	c1 e0 02             	shl    $0x2,%eax
f0105079:	01 d0                	add    %edx,%eax
f010507b:	89 c1                	mov    %eax,%ecx
f010507d:	c1 e1 08             	shl    $0x8,%ecx
f0105080:	01 c8                	add    %ecx,%eax
f0105082:	89 c1                	mov    %eax,%ecx
f0105084:	c1 e1 10             	shl    $0x10,%ecx
f0105087:	01 c8                	add    %ecx,%eax
f0105089:	01 c0                	add    %eax,%eax
f010508b:	01 d0                	add    %edx,%eax
}
f010508d:	5d                   	pop    %ebp
f010508e:	c3                   	ret    

f010508f <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f010508f:	55                   	push   %ebp
f0105090:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0105092:	ff 75 08             	pushl  0x8(%ebp)
f0105095:	e8 bd ff ff ff       	call   f0105057 <to_frame_number>
f010509a:	83 c4 04             	add    $0x4,%esp
f010509d:	c1 e0 0c             	shl    $0xc,%eax
}
f01050a0:	c9                   	leave  
f01050a1:	c3                   	ret    

f01050a2 <sys_cputs>:

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void sys_cputs(const char *s, uint32 len)
{
f01050a2:	55                   	push   %ebp
f01050a3:	89 e5                	mov    %esp,%ebp
f01050a5:	83 ec 08             	sub    $0x8,%esp
	// Destroy the environment if not.
	
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01050a8:	83 ec 04             	sub    $0x4,%esp
f01050ab:	ff 75 08             	pushl  0x8(%ebp)
f01050ae:	ff 75 0c             	pushl  0xc(%ebp)
f01050b1:	68 50 8c 10 f0       	push   $0xf0108c50
f01050b6:	e8 ca f9 ff ff       	call   f0104a85 <cprintf>
f01050bb:	83 c4 10             	add    $0x10,%esp
}
f01050be:	90                   	nop
f01050bf:	c9                   	leave  
f01050c0:	c3                   	ret    

f01050c1 <sys_cgetc>:

// Read a character from the system console.
// Returns the character.
static int
sys_cgetc(void)
{
f01050c1:	55                   	push   %ebp
f01050c2:	89 e5                	mov    %esp,%ebp
f01050c4:	83 ec 18             	sub    $0x18,%esp
	int c;

	// The cons_getc() primitive doesn't wait for a character,
	// but the sys_cgetc() system call does.
	while ((c = cons_getc()) == 0)
f01050c7:	e8 9d b7 ff ff       	call   f0100869 <cons_getc>
f01050cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01050cf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01050d3:	74 f2                	je     f01050c7 <sys_cgetc+0x6>
		/* do nothing */;

	return c;
f01050d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01050d8:	c9                   	leave  
f01050d9:	c3                   	ret    

f01050da <sys_getenvid>:

// Returns the current environment's envid.
static int32 sys_getenvid(void)
{
f01050da:	55                   	push   %ebp
f01050db:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f01050dd:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01050e2:	8b 40 4c             	mov    0x4c(%eax),%eax
}
f01050e5:	5d                   	pop    %ebp
f01050e6:	c3                   	ret    

f01050e7 <sys_env_destroy>:
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int sys_env_destroy(int32  envid)
{
f01050e7:	55                   	push   %ebp
f01050e8:	89 e5                	mov    %esp,%ebp
f01050ea:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01050ed:	83 ec 04             	sub    $0x4,%esp
f01050f0:	6a 01                	push   $0x1
f01050f2:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01050f5:	50                   	push   %eax
f01050f6:	ff 75 08             	pushl  0x8(%ebp)
f01050f9:	e8 38 d1 ff ff       	call   f0102236 <envid2env>
f01050fe:	83 c4 10             	add    $0x10,%esp
f0105101:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0105104:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0105108:	79 05                	jns    f010510f <sys_env_destroy+0x28>
		return r;
f010510a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010510d:	eb 5b                	jmp    f010516a <sys_env_destroy+0x83>
	if (e == curenv)
f010510f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105112:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105117:	39 c2                	cmp    %eax,%edx
f0105119:	75 1b                	jne    f0105136 <sys_env_destroy+0x4f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010511b:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105120:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105123:	83 ec 08             	sub    $0x8,%esp
f0105126:	50                   	push   %eax
f0105127:	68 55 8c 10 f0       	push   $0xf0108c55
f010512c:	e8 54 f9 ff ff       	call   f0104a85 <cprintf>
f0105131:	83 c4 10             	add    $0x10,%esp
f0105134:	eb 20                	jmp    f0105156 <sys_env_destroy+0x6f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0105136:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105139:	8b 50 4c             	mov    0x4c(%eax),%edx
f010513c:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105141:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105144:	83 ec 04             	sub    $0x4,%esp
f0105147:	52                   	push   %edx
f0105148:	50                   	push   %eax
f0105149:	68 70 8c 10 f0       	push   $0xf0108c70
f010514e:	e8 32 f9 ff ff       	call   f0104a85 <cprintf>
f0105153:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0105156:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105159:	83 ec 0c             	sub    $0xc,%esp
f010515c:	50                   	push   %eax
f010515d:	e8 6d f7 ff ff       	call   f01048cf <env_destroy>
f0105162:	83 c4 10             	add    $0x10,%esp
	return 0;
f0105165:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010516a:	c9                   	leave  
f010516b:	c3                   	ret    

f010516c <sys_env_sleep>:

static void sys_env_sleep()
{
f010516c:	55                   	push   %ebp
f010516d:	89 e5                	mov    %esp,%ebp
f010516f:	83 ec 08             	sub    $0x8,%esp
	env_run_cmd_prmpt();
f0105172:	e8 73 f7 ff ff       	call   f01048ea <env_run_cmd_prmpt>
}
f0105177:	90                   	nop
f0105178:	c9                   	leave  
f0105179:	c3                   	ret    

f010517a <sys_allocate_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_allocate_page(void *va, int perm)
{
f010517a:	55                   	push   %ebp
f010517b:	89 e5                	mov    %esp,%ebp
f010517d:	83 ec 28             	sub    $0x28,%esp
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
	
	int r;
	struct Env *e = curenv;
f0105180:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105185:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//if ((r = envid2env(envid, &e, 1)) < 0)
		//return r;
	
	struct Frame_Info *ptr_frame_info ;
	r = allocate_frame(&ptr_frame_info) ;
f0105188:	83 ec 0c             	sub    $0xc,%esp
f010518b:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010518e:	50                   	push   %eax
f010518f:	e8 3c ec ff ff       	call   f0103dd0 <allocate_frame>
f0105194:	83 c4 10             	add    $0x10,%esp
f0105197:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f010519a:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f010519e:	75 08                	jne    f01051a8 <sys_allocate_page+0x2e>
		return r ;
f01051a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01051a3:	e9 cc 00 00 00       	jmp    f0105274 <sys_allocate_page+0xfa>
	
	//check virtual address to be paged_aligned and < USER_TOP
	if ((uint32)va >= USER_TOP || (uint32)va % PAGE_SIZE != 0)
f01051a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01051ab:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f01051b0:	77 0c                	ja     f01051be <sys_allocate_page+0x44>
f01051b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01051b5:	25 ff 0f 00 00       	and    $0xfff,%eax
f01051ba:	85 c0                	test   %eax,%eax
f01051bc:	74 0a                	je     f01051c8 <sys_allocate_page+0x4e>
		return E_INVAL;
f01051be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051c3:	e9 ac 00 00 00       	jmp    f0105274 <sys_allocate_page+0xfa>
	
	//check permissions to be appropriatess
	if ((perm & (~PERM_AVAILABLE & ~PERM_WRITEABLE)) != (PERM_USER))
f01051c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051cb:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f01051d0:	83 f8 04             	cmp    $0x4,%eax
f01051d3:	74 0a                	je     f01051df <sys_allocate_page+0x65>
		return E_INVAL;
f01051d5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01051da:	e9 95 00 00 00       	jmp    f0105274 <sys_allocate_page+0xfa>
	
			
	uint32 physical_address = to_physical_address(ptr_frame_info) ;
f01051df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051e2:	83 ec 0c             	sub    $0xc,%esp
f01051e5:	50                   	push   %eax
f01051e6:	e8 a4 fe ff ff       	call   f010508f <to_physical_address>
f01051eb:	83 c4 10             	add    $0x10,%esp
f01051ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	memset(K_VIRTUAL_ADDRESS(physical_address), 0, PAGE_SIZE);
f01051f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01051f4:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01051f7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01051fa:	c1 e8 0c             	shr    $0xc,%eax
f01051fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105200:	a1 88 37 15 f0       	mov    0xf0153788,%eax
f0105205:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0105208:	72 14                	jb     f010521e <sys_allocate_page+0xa4>
f010520a:	ff 75 e8             	pushl  -0x18(%ebp)
f010520d:	68 88 8c 10 f0       	push   $0xf0108c88
f0105212:	6a 7a                	push   $0x7a
f0105214:	68 b7 8c 10 f0       	push   $0xf0108cb7
f0105219:	e8 10 af ff ff       	call   f010012e <_panic>
f010521e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105221:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0105226:	83 ec 04             	sub    $0x4,%esp
f0105229:	68 00 10 00 00       	push   $0x1000
f010522e:	6a 00                	push   $0x0
f0105230:	50                   	push   %eax
f0105231:	e8 31 0f 00 00       	call   f0106167 <memset>
f0105236:	83 c4 10             	add    $0x10,%esp
		
	r = map_frame(e->env_pgdir, ptr_frame_info, va, perm) ;
f0105239:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010523c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010523f:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105242:	ff 75 0c             	pushl  0xc(%ebp)
f0105245:	ff 75 08             	pushl  0x8(%ebp)
f0105248:	52                   	push   %edx
f0105249:	50                   	push   %eax
f010524a:	e8 8e ed ff ff       	call   f0103fdd <map_frame>
f010524f:	83 c4 10             	add    $0x10,%esp
f0105252:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0105255:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0105259:	75 14                	jne    f010526f <sys_allocate_page+0xf5>
	{
		decrement_references(ptr_frame_info);
f010525b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010525e:	83 ec 0c             	sub    $0xc,%esp
f0105261:	50                   	push   %eax
f0105262:	e8 07 ec ff ff       	call   f0103e6e <decrement_references>
f0105267:	83 c4 10             	add    $0x10,%esp
		return r;
f010526a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010526d:	eb 05                	jmp    f0105274 <sys_allocate_page+0xfa>
	}
	return 0 ;
f010526f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105274:	c9                   	leave  
f0105275:	c3                   	ret    

f0105276 <sys_get_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_get_page(void *va, int perm)
{
f0105276:	55                   	push   %ebp
f0105277:	89 e5                	mov    %esp,%ebp
f0105279:	83 ec 08             	sub    $0x8,%esp
	return get_page(curenv->env_pgdir, va, perm) ;
f010527c:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f0105281:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105284:	83 ec 04             	sub    $0x4,%esp
f0105287:	ff 75 0c             	pushl  0xc(%ebp)
f010528a:	ff 75 08             	pushl  0x8(%ebp)
f010528d:	50                   	push   %eax
f010528e:	e8 c8 ee ff ff       	call   f010415b <get_page>
f0105293:	83 c4 10             	add    $0x10,%esp
}
f0105296:	c9                   	leave  
f0105297:	c3                   	ret    

f0105298 <sys_map_frame>:
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_map_frame(int32 srcenvid, void *srcva, int32 dstenvid, void *dstva, int perm)
{
f0105298:	55                   	push   %ebp
f0105299:	89 e5                	mov    %esp,%ebp
f010529b:	83 ec 08             	sub    $0x8,%esp
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	panic("sys_map_frame not implemented");
f010529e:	83 ec 04             	sub    $0x4,%esp
f01052a1:	68 c6 8c 10 f0       	push   $0xf0108cc6
f01052a6:	68 b1 00 00 00       	push   $0xb1
f01052ab:	68 b7 8c 10 f0       	push   $0xf0108cb7
f01052b0:	e8 79 ae ff ff       	call   f010012e <_panic>

f01052b5 <sys_unmap_frame>:
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int sys_unmap_frame(int32 envid, void *va)
{
f01052b5:	55                   	push   %ebp
f01052b6:	89 e5                	mov    %esp,%ebp
f01052b8:	83 ec 08             	sub    $0x8,%esp
	// Hint: This function is a wrapper around page_remove().
	
	// LAB 4: Your code here.
	panic("sys_page_unmap not implemented");
f01052bb:	83 ec 04             	sub    $0x4,%esp
f01052be:	68 e4 8c 10 f0       	push   $0xf0108ce4
f01052c3:	68 c0 00 00 00       	push   $0xc0
f01052c8:	68 b7 8c 10 f0       	push   $0xf0108cb7
f01052cd:	e8 5c ae ff ff       	call   f010012e <_panic>

f01052d2 <sys_calculate_required_frames>:
}

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
f01052d2:	55                   	push   %ebp
f01052d3:	89 e5                	mov    %esp,%ebp
f01052d5:	83 ec 08             	sub    $0x8,%esp
	return calculate_required_frames(curenv->env_pgdir, start_virtual_address, size); 
f01052d8:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f01052dd:	8b 40 5c             	mov    0x5c(%eax),%eax
f01052e0:	83 ec 04             	sub    $0x4,%esp
f01052e3:	ff 75 0c             	pushl  0xc(%ebp)
f01052e6:	ff 75 08             	pushl  0x8(%ebp)
f01052e9:	50                   	push   %eax
f01052ea:	e8 89 ee ff ff       	call   f0104178 <calculate_required_frames>
f01052ef:	83 c4 10             	add    $0x10,%esp
}
f01052f2:	c9                   	leave  
f01052f3:	c3                   	ret    

f01052f4 <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
f01052f4:	55                   	push   %ebp
f01052f5:	89 e5                	mov    %esp,%ebp
f01052f7:	83 ec 08             	sub    $0x8,%esp
	return calculate_free_frames();
f01052fa:	e8 96 ee ff ff       	call   f0104195 <calculate_free_frames>
}
f01052ff:	c9                   	leave  
f0105300:	c3                   	ret    

f0105301 <sys_freeMem>:
void sys_freeMem(void* start_virtual_address, uint32 size)
{
f0105301:	55                   	push   %ebp
f0105302:	89 e5                	mov    %esp,%ebp
f0105304:	83 ec 08             	sub    $0x8,%esp
	freeMem((uint32*)curenv->env_pgdir, (void*)start_virtual_address, size);
f0105307:	a1 14 2f 15 f0       	mov    0xf0152f14,%eax
f010530c:	8b 40 5c             	mov    0x5c(%eax),%eax
f010530f:	83 ec 04             	sub    $0x4,%esp
f0105312:	ff 75 0c             	pushl  0xc(%ebp)
f0105315:	ff 75 08             	pushl  0x8(%ebp)
f0105318:	50                   	push   %eax
f0105319:	e8 a4 ee ff ff       	call   f01041c2 <freeMem>
f010531e:	83 c4 10             	add    $0x10,%esp
	return;
f0105321:	90                   	nop
}
f0105322:	c9                   	leave  
f0105323:	c3                   	ret    

f0105324 <syscall>:
// Dispatches to the correct kernel function, passing the arguments.
uint32
syscall(uint32 syscallno, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
f0105324:	55                   	push   %ebp
f0105325:	89 e5                	mov    %esp,%ebp
f0105327:	56                   	push   %esi
f0105328:	53                   	push   %ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch(syscallno)
f0105329:	83 7d 08 0c          	cmpl   $0xc,0x8(%ebp)
f010532d:	0f 87 19 01 00 00    	ja     f010544c <syscall+0x128>
f0105333:	8b 45 08             	mov    0x8(%ebp),%eax
f0105336:	c1 e0 02             	shl    $0x2,%eax
f0105339:	05 04 8d 10 f0       	add    $0xf0108d04,%eax
f010533e:	8b 00                	mov    (%eax),%eax
f0105340:	ff e0                	jmp    *%eax
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,a2);
f0105342:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105345:	83 ec 08             	sub    $0x8,%esp
f0105348:	ff 75 10             	pushl  0x10(%ebp)
f010534b:	50                   	push   %eax
f010534c:	e8 51 fd ff ff       	call   f01050a2 <sys_cputs>
f0105351:	83 c4 10             	add    $0x10,%esp
			return 0;
f0105354:	b8 00 00 00 00       	mov    $0x0,%eax
f0105359:	e9 f3 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f010535e:	e8 5e fd ff ff       	call   f01050c1 <sys_cgetc>
f0105363:	e9 e9 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0105368:	e8 6d fd ff ff       	call   f01050da <sys_getenvid>
f010536d:	e9 df 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_env_destroy:
			return sys_env_destroy(a1);
f0105372:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105375:	83 ec 0c             	sub    $0xc,%esp
f0105378:	50                   	push   %eax
f0105379:	e8 69 fd ff ff       	call   f01050e7 <sys_env_destroy>
f010537e:	83 c4 10             	add    $0x10,%esp
f0105381:	e9 cb 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_env_sleep:
			sys_env_sleep();
f0105386:	e8 e1 fd ff ff       	call   f010516c <sys_env_sleep>
			return 0;
f010538b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105390:	e9 bc 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_calc_req_frames:
			return sys_calculate_required_frames(a1, a2);			
f0105395:	83 ec 08             	sub    $0x8,%esp
f0105398:	ff 75 10             	pushl  0x10(%ebp)
f010539b:	ff 75 0c             	pushl  0xc(%ebp)
f010539e:	e8 2f ff ff ff       	call   f01052d2 <sys_calculate_required_frames>
f01053a3:	83 c4 10             	add    $0x10,%esp
f01053a6:	e9 a6 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_calc_free_frames:
			return sys_calculate_free_frames();			
f01053ab:	e8 44 ff ff ff       	call   f01052f4 <sys_calculate_free_frames>
f01053b0:	e9 9c 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_freeMem:
			sys_freeMem((void*)a1, a2);
f01053b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053b8:	83 ec 08             	sub    $0x8,%esp
f01053bb:	ff 75 10             	pushl  0x10(%ebp)
f01053be:	50                   	push   %eax
f01053bf:	e8 3d ff ff ff       	call   f0105301 <sys_freeMem>
f01053c4:	83 c4 10             	add    $0x10,%esp
			return 0;			
f01053c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01053cc:	e9 80 00 00 00       	jmp    f0105451 <syscall+0x12d>
			break;
		//======================
		
		case SYS_allocate_page:
			sys_allocate_page((void*)a1, a2);
f01053d1:	8b 55 10             	mov    0x10(%ebp),%edx
f01053d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053d7:	83 ec 08             	sub    $0x8,%esp
f01053da:	52                   	push   %edx
f01053db:	50                   	push   %eax
f01053dc:	e8 99 fd ff ff       	call   f010517a <sys_allocate_page>
f01053e1:	83 c4 10             	add    $0x10,%esp
			return 0;
f01053e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01053e9:	eb 66                	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_get_page:
			sys_get_page((void*)a1, a2);
f01053eb:	8b 55 10             	mov    0x10(%ebp),%edx
f01053ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053f1:	83 ec 08             	sub    $0x8,%esp
f01053f4:	52                   	push   %edx
f01053f5:	50                   	push   %eax
f01053f6:	e8 7b fe ff ff       	call   f0105276 <sys_get_page>
f01053fb:	83 c4 10             	add    $0x10,%esp
			return 0;
f01053fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105403:	eb 4c                	jmp    f0105451 <syscall+0x12d>
		break;case SYS_map_frame:
			sys_map_frame(a1, (void*)a2, a3, (void*)a4, a5);
f0105405:	8b 75 1c             	mov    0x1c(%ebp),%esi
f0105408:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010540b:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010540e:	8b 55 10             	mov    0x10(%ebp),%edx
f0105411:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105414:	83 ec 0c             	sub    $0xc,%esp
f0105417:	56                   	push   %esi
f0105418:	53                   	push   %ebx
f0105419:	51                   	push   %ecx
f010541a:	52                   	push   %edx
f010541b:	50                   	push   %eax
f010541c:	e8 77 fe ff ff       	call   f0105298 <sys_map_frame>
f0105421:	83 c4 20             	add    $0x20,%esp
			return 0;
f0105424:	b8 00 00 00 00       	mov    $0x0,%eax
f0105429:	eb 26                	jmp    f0105451 <syscall+0x12d>
			break;
		case SYS_unmap_frame:
			sys_unmap_frame(a1, (void*)a2);
f010542b:	8b 55 10             	mov    0x10(%ebp),%edx
f010542e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105431:	83 ec 08             	sub    $0x8,%esp
f0105434:	52                   	push   %edx
f0105435:	50                   	push   %eax
f0105436:	e8 7a fe ff ff       	call   f01052b5 <sys_unmap_frame>
f010543b:	83 c4 10             	add    $0x10,%esp
			return 0;
f010543e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105443:	eb 0c                	jmp    f0105451 <syscall+0x12d>
			break;
		case NSYSCALLS:	
			return 	-E_INVAL;
f0105445:	b8 03 00 00 00       	mov    $0x3,%eax
f010544a:	eb 05                	jmp    f0105451 <syscall+0x12d>
			break;
	}
	//panic("syscall not implemented");
	return -E_INVAL;
f010544c:	b8 03 00 00 00       	mov    $0x3,%eax
}
f0105451:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105454:	5b                   	pop    %ebx
f0105455:	5e                   	pop    %esi
f0105456:	5d                   	pop    %ebp
f0105457:	c3                   	ret    

f0105458 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
f0105458:	55                   	push   %ebp
f0105459:	89 e5                	mov    %esp,%ebp
f010545b:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f010545e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105461:	8b 00                	mov    (%eax),%eax
f0105463:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0105466:	8b 45 10             	mov    0x10(%ebp),%eax
f0105469:	8b 00                	mov    (%eax),%eax
f010546b:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010546e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f0105475:	e9 ca 00 00 00       	jmp    f0105544 <stab_binsearch+0xec>
		int true_m = (l + r) / 2, m = true_m;
f010547a:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010547d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0105480:	01 d0                	add    %edx,%eax
f0105482:	89 c2                	mov    %eax,%edx
f0105484:	c1 ea 1f             	shr    $0x1f,%edx
f0105487:	01 d0                	add    %edx,%eax
f0105489:	d1 f8                	sar    %eax
f010548b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010548e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105491:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0105494:	eb 03                	jmp    f0105499 <stab_binsearch+0x41>
			m--;
f0105496:	ff 4d f0             	decl   -0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0105499:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010549c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010549f:	7c 1e                	jl     f01054bf <stab_binsearch+0x67>
f01054a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01054a4:	89 d0                	mov    %edx,%eax
f01054a6:	01 c0                	add    %eax,%eax
f01054a8:	01 d0                	add    %edx,%eax
f01054aa:	c1 e0 02             	shl    $0x2,%eax
f01054ad:	89 c2                	mov    %eax,%edx
f01054af:	8b 45 08             	mov    0x8(%ebp),%eax
f01054b2:	01 d0                	add    %edx,%eax
f01054b4:	8a 40 04             	mov    0x4(%eax),%al
f01054b7:	0f b6 c0             	movzbl %al,%eax
f01054ba:	3b 45 14             	cmp    0x14(%ebp),%eax
f01054bd:	75 d7                	jne    f0105496 <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f01054bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01054c2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01054c5:	7d 09                	jge    f01054d0 <stab_binsearch+0x78>
			l = true_m + 1;
f01054c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01054ca:	40                   	inc    %eax
f01054cb:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f01054ce:	eb 74                	jmp    f0105544 <stab_binsearch+0xec>
		}

		// actual binary search
		any_matches = 1;
f01054d0:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f01054d7:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01054da:	89 d0                	mov    %edx,%eax
f01054dc:	01 c0                	add    %eax,%eax
f01054de:	01 d0                	add    %edx,%eax
f01054e0:	c1 e0 02             	shl    $0x2,%eax
f01054e3:	89 c2                	mov    %eax,%edx
f01054e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01054e8:	01 d0                	add    %edx,%eax
f01054ea:	8b 40 08             	mov    0x8(%eax),%eax
f01054ed:	3b 45 18             	cmp    0x18(%ebp),%eax
f01054f0:	73 11                	jae    f0105503 <stab_binsearch+0xab>
			*region_left = m;
f01054f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01054f5:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01054f8:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f01054fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01054fd:	40                   	inc    %eax
f01054fe:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0105501:	eb 41                	jmp    f0105544 <stab_binsearch+0xec>
		} else if (stabs[m].n_value > addr) {
f0105503:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105506:	89 d0                	mov    %edx,%eax
f0105508:	01 c0                	add    %eax,%eax
f010550a:	01 d0                	add    %edx,%eax
f010550c:	c1 e0 02             	shl    $0x2,%eax
f010550f:	89 c2                	mov    %eax,%edx
f0105511:	8b 45 08             	mov    0x8(%ebp),%eax
f0105514:	01 d0                	add    %edx,%eax
f0105516:	8b 40 08             	mov    0x8(%eax),%eax
f0105519:	3b 45 18             	cmp    0x18(%ebp),%eax
f010551c:	76 14                	jbe    f0105532 <stab_binsearch+0xda>
			*region_right = m - 1;
f010551e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105521:	8d 50 ff             	lea    -0x1(%eax),%edx
f0105524:	8b 45 10             	mov    0x10(%ebp),%eax
f0105527:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0105529:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010552c:	48                   	dec    %eax
f010552d:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0105530:	eb 12                	jmp    f0105544 <stab_binsearch+0xec>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0105532:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105535:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105538:	89 10                	mov    %edx,(%eax)
			l = m;
f010553a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010553d:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0105540:	83 45 18 04          	addl   $0x4,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0105544:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0105547:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f010554a:	0f 8e 2a ff ff ff    	jle    f010547a <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0105550:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0105554:	75 0f                	jne    f0105565 <stab_binsearch+0x10d>
		*region_right = *region_left - 1;
f0105556:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105559:	8b 00                	mov    (%eax),%eax
f010555b:	8d 50 ff             	lea    -0x1(%eax),%edx
f010555e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105561:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0105563:	eb 3d                	jmp    f01055a2 <stab_binsearch+0x14a>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105565:	8b 45 10             	mov    0x10(%ebp),%eax
f0105568:	8b 00                	mov    (%eax),%eax
f010556a:	89 45 fc             	mov    %eax,-0x4(%ebp)
f010556d:	eb 03                	jmp    f0105572 <stab_binsearch+0x11a>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010556f:	ff 4d fc             	decl   -0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0105572:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105575:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105577:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010557a:	7d 1e                	jge    f010559a <stab_binsearch+0x142>
		     l > *region_left && stabs[l].n_type != type;
f010557c:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010557f:	89 d0                	mov    %edx,%eax
f0105581:	01 c0                	add    %eax,%eax
f0105583:	01 d0                	add    %edx,%eax
f0105585:	c1 e0 02             	shl    $0x2,%eax
f0105588:	89 c2                	mov    %eax,%edx
f010558a:	8b 45 08             	mov    0x8(%ebp),%eax
f010558d:	01 d0                	add    %edx,%eax
f010558f:	8a 40 04             	mov    0x4(%eax),%al
f0105592:	0f b6 c0             	movzbl %al,%eax
f0105595:	3b 45 14             	cmp    0x14(%ebp),%eax
f0105598:	75 d5                	jne    f010556f <stab_binsearch+0x117>
		     l--)
			/* do nothing */;
		*region_left = l;
f010559a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010559d:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01055a0:	89 10                	mov    %edx,(%eax)
	}
}
f01055a2:	90                   	nop
f01055a3:	c9                   	leave  
f01055a4:	c3                   	ret    

f01055a5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uint32*  addr, struct Eipdebuginfo *info)
{
f01055a5:	55                   	push   %ebp
f01055a6:	89 e5                	mov    %esp,%ebp
f01055a8:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01055ab:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055ae:	c7 00 38 8d 10 f0    	movl   $0xf0108d38,(%eax)
	info->eip_line = 0;
f01055b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055b7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f01055be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055c1:	c7 40 08 38 8d 10 f0 	movl   $0xf0108d38,0x8(%eax)
	info->eip_fn_namelen = 9;
f01055c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055cb:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f01055d2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055d5:	8b 55 08             	mov    0x8(%ebp),%edx
f01055d8:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f01055db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01055de:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if ((uint32)addr >= USER_LIMIT) {
f01055e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01055e8:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f01055ed:	76 1e                	jbe    f010560d <debuginfo_eip+0x68>
		stabs = __STAB_BEGIN__;
f01055ef:	c7 45 f4 90 8f 10 f0 	movl   $0xf0108f90,-0xc(%ebp)
		stab_end = __STAB_END__;
f01055f6:	c7 45 f0 c0 34 11 f0 	movl   $0xf01134c0,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f01055fd:	c7 45 ec c1 34 11 f0 	movl   $0xf01134c1,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f0105604:	c7 45 e8 d7 72 11 f0 	movl   $0xf01172d7,-0x18(%ebp)
f010560b:	eb 2a                	jmp    f0105637 <debuginfo_eip+0x92>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f010560d:	c7 45 e0 00 00 20 00 	movl   $0x200000,-0x20(%ebp)

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		
		stabs = usd->stabs;
f0105614:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105617:	8b 00                	mov    (%eax),%eax
f0105619:	89 45 f4             	mov    %eax,-0xc(%ebp)
		stab_end = usd->stab_end;
f010561c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010561f:	8b 40 04             	mov    0x4(%eax),%eax
f0105622:	89 45 f0             	mov    %eax,-0x10(%ebp)
		stabstr = usd->stabstr;
f0105625:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105628:	8b 40 08             	mov    0x8(%eax),%eax
f010562b:	89 45 ec             	mov    %eax,-0x14(%ebp)
		stabstr_end = usd->stabstr_end;
f010562e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105631:	8b 40 0c             	mov    0xc(%eax),%eax
f0105634:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105637:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010563a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f010563d:	76 0a                	jbe    f0105649 <debuginfo_eip+0xa4>
f010563f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105642:	48                   	dec    %eax
f0105643:	8a 00                	mov    (%eax),%al
f0105645:	84 c0                	test   %al,%al
f0105647:	74 0a                	je     f0105653 <debuginfo_eip+0xae>
		return -1;
f0105649:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010564e:	e9 01 02 00 00       	jmp    f0105854 <debuginfo_eip+0x2af>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0105653:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	rfile = (stab_end - stabs) - 1;
f010565a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010565d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105660:	29 c2                	sub    %eax,%edx
f0105662:	89 d0                	mov    %edx,%eax
f0105664:	c1 f8 02             	sar    $0x2,%eax
f0105667:	89 c2                	mov    %eax,%edx
f0105669:	89 d0                	mov    %edx,%eax
f010566b:	c1 e0 02             	shl    $0x2,%eax
f010566e:	01 d0                	add    %edx,%eax
f0105670:	c1 e0 02             	shl    $0x2,%eax
f0105673:	01 d0                	add    %edx,%eax
f0105675:	c1 e0 02             	shl    $0x2,%eax
f0105678:	01 d0                	add    %edx,%eax
f010567a:	89 c1                	mov    %eax,%ecx
f010567c:	c1 e1 08             	shl    $0x8,%ecx
f010567f:	01 c8                	add    %ecx,%eax
f0105681:	89 c1                	mov    %eax,%ecx
f0105683:	c1 e1 10             	shl    $0x10,%ecx
f0105686:	01 c8                	add    %ecx,%eax
f0105688:	01 c0                	add    %eax,%eax
f010568a:	01 d0                	add    %edx,%eax
f010568c:	48                   	dec    %eax
f010568d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105690:	ff 75 08             	pushl  0x8(%ebp)
f0105693:	6a 64                	push   $0x64
f0105695:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0105698:	50                   	push   %eax
f0105699:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010569c:	50                   	push   %eax
f010569d:	ff 75 f4             	pushl  -0xc(%ebp)
f01056a0:	e8 b3 fd ff ff       	call   f0105458 <stab_binsearch>
f01056a5:	83 c4 14             	add    $0x14,%esp
	if (lfile == 0)
f01056a8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01056ab:	85 c0                	test   %eax,%eax
f01056ad:	75 0a                	jne    f01056b9 <debuginfo_eip+0x114>
		return -1;
f01056af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01056b4:	e9 9b 01 00 00       	jmp    f0105854 <debuginfo_eip+0x2af>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01056b9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01056bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	rfun = rfile;
f01056bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01056c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01056c5:	ff 75 08             	pushl  0x8(%ebp)
f01056c8:	6a 24                	push   $0x24
f01056ca:	8d 45 cc             	lea    -0x34(%ebp),%eax
f01056cd:	50                   	push   %eax
f01056ce:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01056d1:	50                   	push   %eax
f01056d2:	ff 75 f4             	pushl  -0xc(%ebp)
f01056d5:	e8 7e fd ff ff       	call   f0105458 <stab_binsearch>
f01056da:	83 c4 14             	add    $0x14,%esp

	if (lfun <= rfun) {
f01056dd:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01056e0:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01056e3:	39 c2                	cmp    %eax,%edx
f01056e5:	0f 8f 86 00 00 00    	jg     f0105771 <debuginfo_eip+0x1cc>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01056eb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01056ee:	89 c2                	mov    %eax,%edx
f01056f0:	89 d0                	mov    %edx,%eax
f01056f2:	01 c0                	add    %eax,%eax
f01056f4:	01 d0                	add    %edx,%eax
f01056f6:	c1 e0 02             	shl    $0x2,%eax
f01056f9:	89 c2                	mov    %eax,%edx
f01056fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01056fe:	01 d0                	add    %edx,%eax
f0105700:	8b 00                	mov    (%eax),%eax
f0105702:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0105705:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0105708:	29 d1                	sub    %edx,%ecx
f010570a:	89 ca                	mov    %ecx,%edx
f010570c:	39 d0                	cmp    %edx,%eax
f010570e:	73 22                	jae    f0105732 <debuginfo_eip+0x18d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0105710:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105713:	89 c2                	mov    %eax,%edx
f0105715:	89 d0                	mov    %edx,%eax
f0105717:	01 c0                	add    %eax,%eax
f0105719:	01 d0                	add    %edx,%eax
f010571b:	c1 e0 02             	shl    $0x2,%eax
f010571e:	89 c2                	mov    %eax,%edx
f0105720:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105723:	01 d0                	add    %edx,%eax
f0105725:	8b 10                	mov    (%eax),%edx
f0105727:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010572a:	01 c2                	add    %eax,%edx
f010572c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010572f:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = (uint32*) stabs[lfun].n_value;
f0105732:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105735:	89 c2                	mov    %eax,%edx
f0105737:	89 d0                	mov    %edx,%eax
f0105739:	01 c0                	add    %eax,%eax
f010573b:	01 d0                	add    %edx,%eax
f010573d:	c1 e0 02             	shl    $0x2,%eax
f0105740:	89 c2                	mov    %eax,%edx
f0105742:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105745:	01 d0                	add    %edx,%eax
f0105747:	8b 50 08             	mov    0x8(%eax),%edx
f010574a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010574d:	89 50 10             	mov    %edx,0x10(%eax)
		addr = (uint32*)(addr - (info->eip_fn_addr));
f0105750:	8b 55 08             	mov    0x8(%ebp),%edx
f0105753:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105756:	8b 40 10             	mov    0x10(%eax),%eax
f0105759:	29 c2                	sub    %eax,%edx
f010575b:	89 d0                	mov    %edx,%eax
f010575d:	c1 f8 02             	sar    $0x2,%eax
f0105760:	89 45 08             	mov    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0105763:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105766:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfun;
f0105769:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010576c:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010576f:	eb 15                	jmp    f0105786 <debuginfo_eip+0x1e1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0105771:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105774:	8b 55 08             	mov    0x8(%ebp),%edx
f0105777:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f010577a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010577d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfile;
f0105780:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105783:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105786:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105789:	8b 40 08             	mov    0x8(%eax),%eax
f010578c:	83 ec 08             	sub    $0x8,%esp
f010578f:	6a 3a                	push   $0x3a
f0105791:	50                   	push   %eax
f0105792:	e8 a4 09 00 00       	call   f010613b <strfind>
f0105797:	83 c4 10             	add    $0x10,%esp
f010579a:	89 c2                	mov    %eax,%edx
f010579c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010579f:	8b 40 08             	mov    0x8(%eax),%eax
f01057a2:	29 c2                	sub    %eax,%edx
f01057a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01057a7:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01057aa:	eb 03                	jmp    f01057af <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01057ac:	ff 4d e4             	decl   -0x1c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01057af:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01057b2:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01057b5:	7c 4e                	jl     f0105805 <debuginfo_eip+0x260>
	       && stabs[lline].n_type != N_SOL
f01057b7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01057ba:	89 d0                	mov    %edx,%eax
f01057bc:	01 c0                	add    %eax,%eax
f01057be:	01 d0                	add    %edx,%eax
f01057c0:	c1 e0 02             	shl    $0x2,%eax
f01057c3:	89 c2                	mov    %eax,%edx
f01057c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01057c8:	01 d0                	add    %edx,%eax
f01057ca:	8a 40 04             	mov    0x4(%eax),%al
f01057cd:	3c 84                	cmp    $0x84,%al
f01057cf:	74 34                	je     f0105805 <debuginfo_eip+0x260>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01057d1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01057d4:	89 d0                	mov    %edx,%eax
f01057d6:	01 c0                	add    %eax,%eax
f01057d8:	01 d0                	add    %edx,%eax
f01057da:	c1 e0 02             	shl    $0x2,%eax
f01057dd:	89 c2                	mov    %eax,%edx
f01057df:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01057e2:	01 d0                	add    %edx,%eax
f01057e4:	8a 40 04             	mov    0x4(%eax),%al
f01057e7:	3c 64                	cmp    $0x64,%al
f01057e9:	75 c1                	jne    f01057ac <debuginfo_eip+0x207>
f01057eb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01057ee:	89 d0                	mov    %edx,%eax
f01057f0:	01 c0                	add    %eax,%eax
f01057f2:	01 d0                	add    %edx,%eax
f01057f4:	c1 e0 02             	shl    $0x2,%eax
f01057f7:	89 c2                	mov    %eax,%edx
f01057f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01057fc:	01 d0                	add    %edx,%eax
f01057fe:	8b 40 08             	mov    0x8(%eax),%eax
f0105801:	85 c0                	test   %eax,%eax
f0105803:	74 a7                	je     f01057ac <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0105805:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105808:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010580b:	7c 42                	jl     f010584f <debuginfo_eip+0x2aa>
f010580d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105810:	89 d0                	mov    %edx,%eax
f0105812:	01 c0                	add    %eax,%eax
f0105814:	01 d0                	add    %edx,%eax
f0105816:	c1 e0 02             	shl    $0x2,%eax
f0105819:	89 c2                	mov    %eax,%edx
f010581b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010581e:	01 d0                	add    %edx,%eax
f0105820:	8b 00                	mov    (%eax),%eax
f0105822:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0105825:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0105828:	29 d1                	sub    %edx,%ecx
f010582a:	89 ca                	mov    %ecx,%edx
f010582c:	39 d0                	cmp    %edx,%eax
f010582e:	73 1f                	jae    f010584f <debuginfo_eip+0x2aa>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105830:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105833:	89 d0                	mov    %edx,%eax
f0105835:	01 c0                	add    %eax,%eax
f0105837:	01 d0                	add    %edx,%eax
f0105839:	c1 e0 02             	shl    $0x2,%eax
f010583c:	89 c2                	mov    %eax,%edx
f010583e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105841:	01 d0                	add    %edx,%eax
f0105843:	8b 10                	mov    (%eax),%edx
f0105845:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105848:	01 c2                	add    %eax,%edx
f010584a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010584d:	89 10                	mov    %edx,(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f010584f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105854:	c9                   	leave  
f0105855:	c3                   	ret    

f0105856 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105856:	55                   	push   %ebp
f0105857:	89 e5                	mov    %esp,%ebp
f0105859:	53                   	push   %ebx
f010585a:	83 ec 14             	sub    $0x14,%esp
f010585d:	8b 45 10             	mov    0x10(%ebp),%eax
f0105860:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105863:	8b 45 14             	mov    0x14(%ebp),%eax
f0105866:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105869:	8b 45 18             	mov    0x18(%ebp),%eax
f010586c:	ba 00 00 00 00       	mov    $0x0,%edx
f0105871:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0105874:	77 55                	ja     f01058cb <printnum+0x75>
f0105876:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0105879:	72 05                	jb     f0105880 <printnum+0x2a>
f010587b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f010587e:	77 4b                	ja     f01058cb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105880:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0105883:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0105886:	8b 45 18             	mov    0x18(%ebp),%eax
f0105889:	ba 00 00 00 00       	mov    $0x0,%edx
f010588e:	52                   	push   %edx
f010588f:	50                   	push   %eax
f0105890:	ff 75 f4             	pushl  -0xc(%ebp)
f0105893:	ff 75 f0             	pushl  -0x10(%ebp)
f0105896:	e8 59 0c 00 00       	call   f01064f4 <__udivdi3>
f010589b:	83 c4 10             	add    $0x10,%esp
f010589e:	83 ec 04             	sub    $0x4,%esp
f01058a1:	ff 75 20             	pushl  0x20(%ebp)
f01058a4:	53                   	push   %ebx
f01058a5:	ff 75 18             	pushl  0x18(%ebp)
f01058a8:	52                   	push   %edx
f01058a9:	50                   	push   %eax
f01058aa:	ff 75 0c             	pushl  0xc(%ebp)
f01058ad:	ff 75 08             	pushl  0x8(%ebp)
f01058b0:	e8 a1 ff ff ff       	call   f0105856 <printnum>
f01058b5:	83 c4 20             	add    $0x20,%esp
f01058b8:	eb 1a                	jmp    f01058d4 <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01058ba:	83 ec 08             	sub    $0x8,%esp
f01058bd:	ff 75 0c             	pushl  0xc(%ebp)
f01058c0:	ff 75 20             	pushl  0x20(%ebp)
f01058c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01058c6:	ff d0                	call   *%eax
f01058c8:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01058cb:	ff 4d 1c             	decl   0x1c(%ebp)
f01058ce:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f01058d2:	7f e6                	jg     f01058ba <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01058d4:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01058d7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01058dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01058df:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01058e2:	53                   	push   %ebx
f01058e3:	51                   	push   %ecx
f01058e4:	52                   	push   %edx
f01058e5:	50                   	push   %eax
f01058e6:	e8 19 0d 00 00       	call   f0106604 <__umoddi3>
f01058eb:	83 c4 10             	add    $0x10,%esp
f01058ee:	05 00 8e 10 f0       	add    $0xf0108e00,%eax
f01058f3:	8a 00                	mov    (%eax),%al
f01058f5:	0f be c0             	movsbl %al,%eax
f01058f8:	83 ec 08             	sub    $0x8,%esp
f01058fb:	ff 75 0c             	pushl  0xc(%ebp)
f01058fe:	50                   	push   %eax
f01058ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0105902:	ff d0                	call   *%eax
f0105904:	83 c4 10             	add    $0x10,%esp
}
f0105907:	90                   	nop
f0105908:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010590b:	c9                   	leave  
f010590c:	c3                   	ret    

f010590d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010590d:	55                   	push   %ebp
f010590e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105910:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0105914:	7e 1c                	jle    f0105932 <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f0105916:	8b 45 08             	mov    0x8(%ebp),%eax
f0105919:	8b 00                	mov    (%eax),%eax
f010591b:	8d 50 08             	lea    0x8(%eax),%edx
f010591e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105921:	89 10                	mov    %edx,(%eax)
f0105923:	8b 45 08             	mov    0x8(%ebp),%eax
f0105926:	8b 00                	mov    (%eax),%eax
f0105928:	83 e8 08             	sub    $0x8,%eax
f010592b:	8b 50 04             	mov    0x4(%eax),%edx
f010592e:	8b 00                	mov    (%eax),%eax
f0105930:	eb 40                	jmp    f0105972 <getuint+0x65>
	else if (lflag)
f0105932:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105936:	74 1e                	je     f0105956 <getuint+0x49>
		return va_arg(*ap, unsigned long);
f0105938:	8b 45 08             	mov    0x8(%ebp),%eax
f010593b:	8b 00                	mov    (%eax),%eax
f010593d:	8d 50 04             	lea    0x4(%eax),%edx
f0105940:	8b 45 08             	mov    0x8(%ebp),%eax
f0105943:	89 10                	mov    %edx,(%eax)
f0105945:	8b 45 08             	mov    0x8(%ebp),%eax
f0105948:	8b 00                	mov    (%eax),%eax
f010594a:	83 e8 04             	sub    $0x4,%eax
f010594d:	8b 00                	mov    (%eax),%eax
f010594f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105954:	eb 1c                	jmp    f0105972 <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f0105956:	8b 45 08             	mov    0x8(%ebp),%eax
f0105959:	8b 00                	mov    (%eax),%eax
f010595b:	8d 50 04             	lea    0x4(%eax),%edx
f010595e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105961:	89 10                	mov    %edx,(%eax)
f0105963:	8b 45 08             	mov    0x8(%ebp),%eax
f0105966:	8b 00                	mov    (%eax),%eax
f0105968:	83 e8 04             	sub    $0x4,%eax
f010596b:	8b 00                	mov    (%eax),%eax
f010596d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105972:	5d                   	pop    %ebp
f0105973:	c3                   	ret    

f0105974 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0105974:	55                   	push   %ebp
f0105975:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105977:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f010597b:	7e 1c                	jle    f0105999 <getint+0x25>
		return va_arg(*ap, long long);
f010597d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105980:	8b 00                	mov    (%eax),%eax
f0105982:	8d 50 08             	lea    0x8(%eax),%edx
f0105985:	8b 45 08             	mov    0x8(%ebp),%eax
f0105988:	89 10                	mov    %edx,(%eax)
f010598a:	8b 45 08             	mov    0x8(%ebp),%eax
f010598d:	8b 00                	mov    (%eax),%eax
f010598f:	83 e8 08             	sub    $0x8,%eax
f0105992:	8b 50 04             	mov    0x4(%eax),%edx
f0105995:	8b 00                	mov    (%eax),%eax
f0105997:	eb 38                	jmp    f01059d1 <getint+0x5d>
	else if (lflag)
f0105999:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010599d:	74 1a                	je     f01059b9 <getint+0x45>
		return va_arg(*ap, long);
f010599f:	8b 45 08             	mov    0x8(%ebp),%eax
f01059a2:	8b 00                	mov    (%eax),%eax
f01059a4:	8d 50 04             	lea    0x4(%eax),%edx
f01059a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01059aa:	89 10                	mov    %edx,(%eax)
f01059ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01059af:	8b 00                	mov    (%eax),%eax
f01059b1:	83 e8 04             	sub    $0x4,%eax
f01059b4:	8b 00                	mov    (%eax),%eax
f01059b6:	99                   	cltd   
f01059b7:	eb 18                	jmp    f01059d1 <getint+0x5d>
	else
		return va_arg(*ap, int);
f01059b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01059bc:	8b 00                	mov    (%eax),%eax
f01059be:	8d 50 04             	lea    0x4(%eax),%edx
f01059c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01059c4:	89 10                	mov    %edx,(%eax)
f01059c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01059c9:	8b 00                	mov    (%eax),%eax
f01059cb:	83 e8 04             	sub    $0x4,%eax
f01059ce:	8b 00                	mov    (%eax),%eax
f01059d0:	99                   	cltd   
}
f01059d1:	5d                   	pop    %ebp
f01059d2:	c3                   	ret    

f01059d3 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01059d3:	55                   	push   %ebp
f01059d4:	89 e5                	mov    %esp,%ebp
f01059d6:	56                   	push   %esi
f01059d7:	53                   	push   %ebx
f01059d8:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01059db:	eb 17                	jmp    f01059f4 <vprintfmt+0x21>
			if (ch == '\0')
f01059dd:	85 db                	test   %ebx,%ebx
f01059df:	0f 84 af 03 00 00    	je     f0105d94 <vprintfmt+0x3c1>
				return;
			putch(ch, putdat);
f01059e5:	83 ec 08             	sub    $0x8,%esp
f01059e8:	ff 75 0c             	pushl  0xc(%ebp)
f01059eb:	53                   	push   %ebx
f01059ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01059ef:	ff d0                	call   *%eax
f01059f1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01059f4:	8b 45 10             	mov    0x10(%ebp),%eax
f01059f7:	8d 50 01             	lea    0x1(%eax),%edx
f01059fa:	89 55 10             	mov    %edx,0x10(%ebp)
f01059fd:	8a 00                	mov    (%eax),%al
f01059ff:	0f b6 d8             	movzbl %al,%ebx
f0105a02:	83 fb 25             	cmp    $0x25,%ebx
f0105a05:	75 d6                	jne    f01059dd <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0105a07:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f0105a0b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0105a12:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0105a19:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0105a20:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105a27:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a2a:	8d 50 01             	lea    0x1(%eax),%edx
f0105a2d:	89 55 10             	mov    %edx,0x10(%ebp)
f0105a30:	8a 00                	mov    (%eax),%al
f0105a32:	0f b6 d8             	movzbl %al,%ebx
f0105a35:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0105a38:	83 f8 55             	cmp    $0x55,%eax
f0105a3b:	0f 87 2b 03 00 00    	ja     f0105d6c <vprintfmt+0x399>
f0105a41:	8b 04 85 24 8e 10 f0 	mov    -0xfef71dc(,%eax,4),%eax
f0105a48:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f0105a4a:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f0105a4e:	eb d7                	jmp    f0105a27 <vprintfmt+0x54>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105a50:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0105a54:	eb d1                	jmp    f0105a27 <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105a56:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f0105a5d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105a60:	89 d0                	mov    %edx,%eax
f0105a62:	c1 e0 02             	shl    $0x2,%eax
f0105a65:	01 d0                	add    %edx,%eax
f0105a67:	01 c0                	add    %eax,%eax
f0105a69:	01 d8                	add    %ebx,%eax
f0105a6b:	83 e8 30             	sub    $0x30,%eax
f0105a6e:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f0105a71:	8b 45 10             	mov    0x10(%ebp),%eax
f0105a74:	8a 00                	mov    (%eax),%al
f0105a76:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f0105a79:	83 fb 2f             	cmp    $0x2f,%ebx
f0105a7c:	7e 3e                	jle    f0105abc <vprintfmt+0xe9>
f0105a7e:	83 fb 39             	cmp    $0x39,%ebx
f0105a81:	7f 39                	jg     f0105abc <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105a83:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105a86:	eb d5                	jmp    f0105a5d <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105a88:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a8b:	83 c0 04             	add    $0x4,%eax
f0105a8e:	89 45 14             	mov    %eax,0x14(%ebp)
f0105a91:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a94:	83 e8 04             	sub    $0x4,%eax
f0105a97:	8b 00                	mov    (%eax),%eax
f0105a99:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f0105a9c:	eb 1f                	jmp    f0105abd <vprintfmt+0xea>

		case '.':
			if (width < 0)
f0105a9e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105aa2:	79 83                	jns    f0105a27 <vprintfmt+0x54>
				width = 0;
f0105aa4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0105aab:	e9 77 ff ff ff       	jmp    f0105a27 <vprintfmt+0x54>

		case '#':
			altflag = 1;
f0105ab0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0105ab7:	e9 6b ff ff ff       	jmp    f0105a27 <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f0105abc:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0105abd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105ac1:	0f 89 60 ff ff ff    	jns    f0105a27 <vprintfmt+0x54>
				width = precision, precision = -1;
f0105ac7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105aca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105acd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f0105ad4:	e9 4e ff ff ff       	jmp    f0105a27 <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105ad9:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
f0105adc:	e9 46 ff ff ff       	jmp    f0105a27 <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105ae1:	8b 45 14             	mov    0x14(%ebp),%eax
f0105ae4:	83 c0 04             	add    $0x4,%eax
f0105ae7:	89 45 14             	mov    %eax,0x14(%ebp)
f0105aea:	8b 45 14             	mov    0x14(%ebp),%eax
f0105aed:	83 e8 04             	sub    $0x4,%eax
f0105af0:	8b 00                	mov    (%eax),%eax
f0105af2:	83 ec 08             	sub    $0x8,%esp
f0105af5:	ff 75 0c             	pushl  0xc(%ebp)
f0105af8:	50                   	push   %eax
f0105af9:	8b 45 08             	mov    0x8(%ebp),%eax
f0105afc:	ff d0                	call   *%eax
f0105afe:	83 c4 10             	add    $0x10,%esp
			break;
f0105b01:	e9 89 02 00 00       	jmp    f0105d8f <vprintfmt+0x3bc>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105b06:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b09:	83 c0 04             	add    $0x4,%eax
f0105b0c:	89 45 14             	mov    %eax,0x14(%ebp)
f0105b0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b12:	83 e8 04             	sub    $0x4,%eax
f0105b15:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f0105b17:	85 db                	test   %ebx,%ebx
f0105b19:	79 02                	jns    f0105b1d <vprintfmt+0x14a>
				err = -err;
f0105b1b:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0105b1d:	83 fb 07             	cmp    $0x7,%ebx
f0105b20:	7f 0b                	jg     f0105b2d <vprintfmt+0x15a>
f0105b22:	8b 34 9d e0 8d 10 f0 	mov    -0xfef7220(,%ebx,4),%esi
f0105b29:	85 f6                	test   %esi,%esi
f0105b2b:	75 19                	jne    f0105b46 <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
f0105b2d:	53                   	push   %ebx
f0105b2e:	68 11 8e 10 f0       	push   $0xf0108e11
f0105b33:	ff 75 0c             	pushl  0xc(%ebp)
f0105b36:	ff 75 08             	pushl  0x8(%ebp)
f0105b39:	e8 5e 02 00 00       	call   f0105d9c <printfmt>
f0105b3e:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0105b41:	e9 49 02 00 00       	jmp    f0105d8f <vprintfmt+0x3bc>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0105b46:	56                   	push   %esi
f0105b47:	68 1a 8e 10 f0       	push   $0xf0108e1a
f0105b4c:	ff 75 0c             	pushl  0xc(%ebp)
f0105b4f:	ff 75 08             	pushl  0x8(%ebp)
f0105b52:	e8 45 02 00 00       	call   f0105d9c <printfmt>
f0105b57:	83 c4 10             	add    $0x10,%esp
			break;
f0105b5a:	e9 30 02 00 00       	jmp    f0105d8f <vprintfmt+0x3bc>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105b5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b62:	83 c0 04             	add    $0x4,%eax
f0105b65:	89 45 14             	mov    %eax,0x14(%ebp)
f0105b68:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b6b:	83 e8 04             	sub    $0x4,%eax
f0105b6e:	8b 30                	mov    (%eax),%esi
f0105b70:	85 f6                	test   %esi,%esi
f0105b72:	75 05                	jne    f0105b79 <vprintfmt+0x1a6>
				p = "(null)";
f0105b74:	be 1d 8e 10 f0       	mov    $0xf0108e1d,%esi
			if (width > 0 && padc != '-')
f0105b79:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105b7d:	7e 6d                	jle    f0105bec <vprintfmt+0x219>
f0105b7f:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f0105b83:	74 67                	je     f0105bec <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
f0105b85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105b88:	83 ec 08             	sub    $0x8,%esp
f0105b8b:	50                   	push   %eax
f0105b8c:	56                   	push   %esi
f0105b8d:	e8 0a 04 00 00       	call   f0105f9c <strnlen>
f0105b92:	83 c4 10             	add    $0x10,%esp
f0105b95:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0105b98:	eb 16                	jmp    f0105bb0 <vprintfmt+0x1dd>
					putch(padc, putdat);
f0105b9a:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f0105b9e:	83 ec 08             	sub    $0x8,%esp
f0105ba1:	ff 75 0c             	pushl  0xc(%ebp)
f0105ba4:	50                   	push   %eax
f0105ba5:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ba8:	ff d0                	call   *%eax
f0105baa:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105bad:	ff 4d e4             	decl   -0x1c(%ebp)
f0105bb0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105bb4:	7f e4                	jg     f0105b9a <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105bb6:	eb 34                	jmp    f0105bec <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
f0105bb8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105bbc:	74 1c                	je     f0105bda <vprintfmt+0x207>
f0105bbe:	83 fb 1f             	cmp    $0x1f,%ebx
f0105bc1:	7e 05                	jle    f0105bc8 <vprintfmt+0x1f5>
f0105bc3:	83 fb 7e             	cmp    $0x7e,%ebx
f0105bc6:	7e 12                	jle    f0105bda <vprintfmt+0x207>
					putch('?', putdat);
f0105bc8:	83 ec 08             	sub    $0x8,%esp
f0105bcb:	ff 75 0c             	pushl  0xc(%ebp)
f0105bce:	6a 3f                	push   $0x3f
f0105bd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bd3:	ff d0                	call   *%eax
f0105bd5:	83 c4 10             	add    $0x10,%esp
f0105bd8:	eb 0f                	jmp    f0105be9 <vprintfmt+0x216>
				else
					putch(ch, putdat);
f0105bda:	83 ec 08             	sub    $0x8,%esp
f0105bdd:	ff 75 0c             	pushl  0xc(%ebp)
f0105be0:	53                   	push   %ebx
f0105be1:	8b 45 08             	mov    0x8(%ebp),%eax
f0105be4:	ff d0                	call   *%eax
f0105be6:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105be9:	ff 4d e4             	decl   -0x1c(%ebp)
f0105bec:	89 f0                	mov    %esi,%eax
f0105bee:	8d 70 01             	lea    0x1(%eax),%esi
f0105bf1:	8a 00                	mov    (%eax),%al
f0105bf3:	0f be d8             	movsbl %al,%ebx
f0105bf6:	85 db                	test   %ebx,%ebx
f0105bf8:	74 24                	je     f0105c1e <vprintfmt+0x24b>
f0105bfa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105bfe:	78 b8                	js     f0105bb8 <vprintfmt+0x1e5>
f0105c00:	ff 4d e0             	decl   -0x20(%ebp)
f0105c03:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105c07:	79 af                	jns    f0105bb8 <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105c09:	eb 13                	jmp    f0105c1e <vprintfmt+0x24b>
				putch(' ', putdat);
f0105c0b:	83 ec 08             	sub    $0x8,%esp
f0105c0e:	ff 75 0c             	pushl  0xc(%ebp)
f0105c11:	6a 20                	push   $0x20
f0105c13:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c16:	ff d0                	call   *%eax
f0105c18:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105c1b:	ff 4d e4             	decl   -0x1c(%ebp)
f0105c1e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105c22:	7f e7                	jg     f0105c0b <vprintfmt+0x238>
				putch(' ', putdat);
			break;
f0105c24:	e9 66 01 00 00       	jmp    f0105d8f <vprintfmt+0x3bc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105c29:	83 ec 08             	sub    $0x8,%esp
f0105c2c:	ff 75 e8             	pushl  -0x18(%ebp)
f0105c2f:	8d 45 14             	lea    0x14(%ebp),%eax
f0105c32:	50                   	push   %eax
f0105c33:	e8 3c fd ff ff       	call   f0105974 <getint>
f0105c38:	83 c4 10             	add    $0x10,%esp
f0105c3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105c3e:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0105c41:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105c44:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0105c47:	85 d2                	test   %edx,%edx
f0105c49:	79 23                	jns    f0105c6e <vprintfmt+0x29b>
				putch('-', putdat);
f0105c4b:	83 ec 08             	sub    $0x8,%esp
f0105c4e:	ff 75 0c             	pushl  0xc(%ebp)
f0105c51:	6a 2d                	push   $0x2d
f0105c53:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c56:	ff d0                	call   *%eax
f0105c58:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f0105c5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105c5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0105c61:	f7 d8                	neg    %eax
f0105c63:	83 d2 00             	adc    $0x0,%edx
f0105c66:	f7 da                	neg    %edx
f0105c68:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105c6b:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f0105c6e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0105c75:	e9 bc 00 00 00       	jmp    f0105d36 <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105c7a:	83 ec 08             	sub    $0x8,%esp
f0105c7d:	ff 75 e8             	pushl  -0x18(%ebp)
f0105c80:	8d 45 14             	lea    0x14(%ebp),%eax
f0105c83:	50                   	push   %eax
f0105c84:	e8 84 fc ff ff       	call   f010590d <getuint>
f0105c89:	83 c4 10             	add    $0x10,%esp
f0105c8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105c8f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f0105c92:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0105c99:	e9 98 00 00 00       	jmp    f0105d36 <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0105c9e:	83 ec 08             	sub    $0x8,%esp
f0105ca1:	ff 75 0c             	pushl  0xc(%ebp)
f0105ca4:	6a 58                	push   $0x58
f0105ca6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ca9:	ff d0                	call   *%eax
f0105cab:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f0105cae:	83 ec 08             	sub    $0x8,%esp
f0105cb1:	ff 75 0c             	pushl  0xc(%ebp)
f0105cb4:	6a 58                	push   $0x58
f0105cb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cb9:	ff d0                	call   *%eax
f0105cbb:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f0105cbe:	83 ec 08             	sub    $0x8,%esp
f0105cc1:	ff 75 0c             	pushl  0xc(%ebp)
f0105cc4:	6a 58                	push   $0x58
f0105cc6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cc9:	ff d0                	call   *%eax
f0105ccb:	83 c4 10             	add    $0x10,%esp
			break;
f0105cce:	e9 bc 00 00 00       	jmp    f0105d8f <vprintfmt+0x3bc>

		// pointer
		case 'p':
			putch('0', putdat);
f0105cd3:	83 ec 08             	sub    $0x8,%esp
f0105cd6:	ff 75 0c             	pushl  0xc(%ebp)
f0105cd9:	6a 30                	push   $0x30
f0105cdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cde:	ff d0                	call   *%eax
f0105ce0:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f0105ce3:	83 ec 08             	sub    $0x8,%esp
f0105ce6:	ff 75 0c             	pushl  0xc(%ebp)
f0105ce9:	6a 78                	push   $0x78
f0105ceb:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cee:	ff d0                	call   *%eax
f0105cf0:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
f0105cf3:	8b 45 14             	mov    0x14(%ebp),%eax
f0105cf6:	83 c0 04             	add    $0x4,%eax
f0105cf9:	89 45 14             	mov    %eax,0x14(%ebp)
f0105cfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0105cff:	83 e8 04             	sub    $0x4,%eax
f0105d02:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105d04:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105d07:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
f0105d0e:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f0105d15:	eb 1f                	jmp    f0105d36 <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105d17:	83 ec 08             	sub    $0x8,%esp
f0105d1a:	ff 75 e8             	pushl  -0x18(%ebp)
f0105d1d:	8d 45 14             	lea    0x14(%ebp),%eax
f0105d20:	50                   	push   %eax
f0105d21:	e8 e7 fb ff ff       	call   f010590d <getuint>
f0105d26:	83 c4 10             	add    $0x10,%esp
f0105d29:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105d2c:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0105d2f:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105d36:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f0105d3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105d3d:	83 ec 04             	sub    $0x4,%esp
f0105d40:	52                   	push   %edx
f0105d41:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105d44:	50                   	push   %eax
f0105d45:	ff 75 f4             	pushl  -0xc(%ebp)
f0105d48:	ff 75 f0             	pushl  -0x10(%ebp)
f0105d4b:	ff 75 0c             	pushl  0xc(%ebp)
f0105d4e:	ff 75 08             	pushl  0x8(%ebp)
f0105d51:	e8 00 fb ff ff       	call   f0105856 <printnum>
f0105d56:	83 c4 20             	add    $0x20,%esp
			break;
f0105d59:	eb 34                	jmp    f0105d8f <vprintfmt+0x3bc>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105d5b:	83 ec 08             	sub    $0x8,%esp
f0105d5e:	ff 75 0c             	pushl  0xc(%ebp)
f0105d61:	53                   	push   %ebx
f0105d62:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d65:	ff d0                	call   *%eax
f0105d67:	83 c4 10             	add    $0x10,%esp
			break;
f0105d6a:	eb 23                	jmp    f0105d8f <vprintfmt+0x3bc>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105d6c:	83 ec 08             	sub    $0x8,%esp
f0105d6f:	ff 75 0c             	pushl  0xc(%ebp)
f0105d72:	6a 25                	push   $0x25
f0105d74:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d77:	ff d0                	call   *%eax
f0105d79:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105d7c:	ff 4d 10             	decl   0x10(%ebp)
f0105d7f:	eb 03                	jmp    f0105d84 <vprintfmt+0x3b1>
f0105d81:	ff 4d 10             	decl   0x10(%ebp)
f0105d84:	8b 45 10             	mov    0x10(%ebp),%eax
f0105d87:	48                   	dec    %eax
f0105d88:	8a 00                	mov    (%eax),%al
f0105d8a:	3c 25                	cmp    $0x25,%al
f0105d8c:	75 f3                	jne    f0105d81 <vprintfmt+0x3ae>
				/* do nothing */;
			break;
f0105d8e:	90                   	nop
		}
	}
f0105d8f:	e9 47 fc ff ff       	jmp    f01059db <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f0105d94:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0105d95:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d98:	5b                   	pop    %ebx
f0105d99:	5e                   	pop    %esi
f0105d9a:	5d                   	pop    %ebp
f0105d9b:	c3                   	ret    

f0105d9c <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105d9c:	55                   	push   %ebp
f0105d9d:	89 e5                	mov    %esp,%ebp
f0105d9f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0105da2:	8d 45 10             	lea    0x10(%ebp),%eax
f0105da5:	83 c0 04             	add    $0x4,%eax
f0105da8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0105dab:	8b 45 10             	mov    0x10(%ebp),%eax
f0105dae:	ff 75 f4             	pushl  -0xc(%ebp)
f0105db1:	50                   	push   %eax
f0105db2:	ff 75 0c             	pushl  0xc(%ebp)
f0105db5:	ff 75 08             	pushl  0x8(%ebp)
f0105db8:	e8 16 fc ff ff       	call   f01059d3 <vprintfmt>
f0105dbd:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f0105dc0:	90                   	nop
f0105dc1:	c9                   	leave  
f0105dc2:	c3                   	ret    

f0105dc3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105dc3:	55                   	push   %ebp
f0105dc4:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f0105dc6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105dc9:	8b 40 08             	mov    0x8(%eax),%eax
f0105dcc:	8d 50 01             	lea    0x1(%eax),%edx
f0105dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105dd2:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f0105dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105dd8:	8b 10                	mov    (%eax),%edx
f0105dda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105ddd:	8b 40 04             	mov    0x4(%eax),%eax
f0105de0:	39 c2                	cmp    %eax,%edx
f0105de2:	73 12                	jae    f0105df6 <sprintputch+0x33>
		*b->buf++ = ch;
f0105de4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105de7:	8b 00                	mov    (%eax),%eax
f0105de9:	8d 48 01             	lea    0x1(%eax),%ecx
f0105dec:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105def:	89 0a                	mov    %ecx,(%edx)
f0105df1:	8b 55 08             	mov    0x8(%ebp),%edx
f0105df4:	88 10                	mov    %dl,(%eax)
}
f0105df6:	90                   	nop
f0105df7:	5d                   	pop    %ebp
f0105df8:	c3                   	ret    

f0105df9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105df9:	55                   	push   %ebp
f0105dfa:	89 e5                	mov    %esp,%ebp
f0105dfc:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105dff:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e02:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105e05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105e08:	8d 50 ff             	lea    -0x1(%eax),%edx
f0105e0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e0e:	01 d0                	add    %edx,%eax
f0105e10:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105e13:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105e1a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0105e1e:	74 06                	je     f0105e26 <vsnprintf+0x2d>
f0105e20:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105e24:	7f 07                	jg     f0105e2d <vsnprintf+0x34>
		return -E_INVAL;
f0105e26:	b8 03 00 00 00       	mov    $0x3,%eax
f0105e2b:	eb 20                	jmp    f0105e4d <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105e2d:	ff 75 14             	pushl  0x14(%ebp)
f0105e30:	ff 75 10             	pushl  0x10(%ebp)
f0105e33:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105e36:	50                   	push   %eax
f0105e37:	68 c3 5d 10 f0       	push   $0xf0105dc3
f0105e3c:	e8 92 fb ff ff       	call   f01059d3 <vprintfmt>
f0105e41:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f0105e44:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105e47:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105e4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0105e4d:	c9                   	leave  
f0105e4e:	c3                   	ret    

f0105e4f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105e4f:	55                   	push   %ebp
f0105e50:	89 e5                	mov    %esp,%ebp
f0105e52:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105e55:	8d 45 10             	lea    0x10(%ebp),%eax
f0105e58:	83 c0 04             	add    $0x4,%eax
f0105e5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0105e5e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105e61:	ff 75 f4             	pushl  -0xc(%ebp)
f0105e64:	50                   	push   %eax
f0105e65:	ff 75 0c             	pushl  0xc(%ebp)
f0105e68:	ff 75 08             	pushl  0x8(%ebp)
f0105e6b:	e8 89 ff ff ff       	call   f0105df9 <vsnprintf>
f0105e70:	83 c4 10             	add    $0x10,%esp
f0105e73:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f0105e76:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0105e79:	c9                   	leave  
f0105e7a:	c3                   	ret    

f0105e7b <readline>:

#define BUFLEN 1024
//static char buf[BUFLEN];

void readline(const char *prompt, char* buf)
{
f0105e7b:	55                   	push   %ebp
f0105e7c:	89 e5                	mov    %esp,%ebp
f0105e7e:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;
	
	if (prompt != NULL)
f0105e81:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0105e85:	74 13                	je     f0105e9a <readline+0x1f>
		cprintf("%s", prompt);
f0105e87:	83 ec 08             	sub    $0x8,%esp
f0105e8a:	ff 75 08             	pushl  0x8(%ebp)
f0105e8d:	68 7c 8f 10 f0       	push   $0xf0108f7c
f0105e92:	e8 ee eb ff ff       	call   f0104a85 <cprintf>
f0105e97:	83 c4 10             	add    $0x10,%esp

	
	i = 0;
f0105e9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);	
f0105ea1:	83 ec 0c             	sub    $0xc,%esp
f0105ea4:	6a 00                	push   $0x0
f0105ea6:	e8 9c aa ff ff       	call   f0100947 <iscons>
f0105eab:	83 c4 10             	add    $0x10,%esp
f0105eae:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f0105eb1:	e8 78 aa ff ff       	call   f010092e <getchar>
f0105eb6:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f0105eb9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0105ebd:	79 22                	jns    f0105ee1 <readline+0x66>
			if (c != -E_EOF)
f0105ebf:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
f0105ec3:	0f 84 ad 00 00 00    	je     f0105f76 <readline+0xfb>
				cprintf("read error: %e\n", c);			
f0105ec9:	83 ec 08             	sub    $0x8,%esp
f0105ecc:	ff 75 ec             	pushl  -0x14(%ebp)
f0105ecf:	68 7f 8f 10 f0       	push   $0xf0108f7f
f0105ed4:	e8 ac eb ff ff       	call   f0104a85 <cprintf>
f0105ed9:	83 c4 10             	add    $0x10,%esp
			return;
f0105edc:	e9 95 00 00 00       	jmp    f0105f76 <readline+0xfb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105ee1:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0105ee5:	7e 34                	jle    f0105f1b <readline+0xa0>
f0105ee7:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f0105eee:	7f 2b                	jg     f0105f1b <readline+0xa0>
			if (echoing)
f0105ef0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0105ef4:	74 0e                	je     f0105f04 <readline+0x89>
				cputchar(c);
f0105ef6:	83 ec 0c             	sub    $0xc,%esp
f0105ef9:	ff 75 ec             	pushl  -0x14(%ebp)
f0105efc:	e8 16 aa ff ff       	call   f0100917 <cputchar>
f0105f01:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105f07:	8d 50 01             	lea    0x1(%eax),%edx
f0105f0a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0105f0d:	89 c2                	mov    %eax,%edx
f0105f0f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105f12:	01 d0                	add    %edx,%eax
f0105f14:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0105f17:	88 10                	mov    %dl,(%eax)
f0105f19:	eb 56                	jmp    f0105f71 <readline+0xf6>
		} else if (c == '\b' && i > 0) {
f0105f1b:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0105f1f:	75 1f                	jne    f0105f40 <readline+0xc5>
f0105f21:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0105f25:	7e 19                	jle    f0105f40 <readline+0xc5>
			if (echoing)
f0105f27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0105f2b:	74 0e                	je     f0105f3b <readline+0xc0>
				cputchar(c);
f0105f2d:	83 ec 0c             	sub    $0xc,%esp
f0105f30:	ff 75 ec             	pushl  -0x14(%ebp)
f0105f33:	e8 df a9 ff ff       	call   f0100917 <cputchar>
f0105f38:	83 c4 10             	add    $0x10,%esp
			i--;
f0105f3b:	ff 4d f4             	decl   -0xc(%ebp)
f0105f3e:	eb 31                	jmp    f0105f71 <readline+0xf6>
		} else if (c == '\n' || c == '\r') {
f0105f40:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0105f44:	74 0a                	je     f0105f50 <readline+0xd5>
f0105f46:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f0105f4a:	0f 85 61 ff ff ff    	jne    f0105eb1 <readline+0x36>
			if (echoing)
f0105f50:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0105f54:	74 0e                	je     f0105f64 <readline+0xe9>
				cputchar(c);
f0105f56:	83 ec 0c             	sub    $0xc,%esp
f0105f59:	ff 75 ec             	pushl  -0x14(%ebp)
f0105f5c:	e8 b6 a9 ff ff       	call   f0100917 <cputchar>
f0105f61:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;	
f0105f64:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0105f67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105f6a:	01 d0                	add    %edx,%eax
f0105f6c:	c6 00 00             	movb   $0x0,(%eax)
			return;		
f0105f6f:	eb 06                	jmp    f0105f77 <readline+0xfc>
		}
	}
f0105f71:	e9 3b ff ff ff       	jmp    f0105eb1 <readline+0x36>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);			
			return;
f0105f76:	90                   	nop
				cputchar(c);
			buf[i] = 0;	
			return;		
		}
	}
}
f0105f77:	c9                   	leave  
f0105f78:	c3                   	ret    

f0105f79 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0105f79:	55                   	push   %ebp
f0105f7a:	89 e5                	mov    %esp,%ebp
f0105f7c:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0105f7f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0105f86:	eb 06                	jmp    f0105f8e <strlen+0x15>
		n++;
f0105f88:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105f8b:	ff 45 08             	incl   0x8(%ebp)
f0105f8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f91:	8a 00                	mov    (%eax),%al
f0105f93:	84 c0                	test   %al,%al
f0105f95:	75 f1                	jne    f0105f88 <strlen+0xf>
		n++;
	return n;
f0105f97:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0105f9a:	c9                   	leave  
f0105f9b:	c3                   	ret    

f0105f9c <strnlen>:

int
strnlen(const char *s, uint32 size)
{
f0105f9c:	55                   	push   %ebp
f0105f9d:	89 e5                	mov    %esp,%ebp
f0105f9f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105fa2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0105fa9:	eb 09                	jmp    f0105fb4 <strnlen+0x18>
		n++;
f0105fab:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105fae:	ff 45 08             	incl   0x8(%ebp)
f0105fb1:	ff 4d 0c             	decl   0xc(%ebp)
f0105fb4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105fb8:	74 09                	je     f0105fc3 <strnlen+0x27>
f0105fba:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fbd:	8a 00                	mov    (%eax),%al
f0105fbf:	84 c0                	test   %al,%al
f0105fc1:	75 e8                	jne    f0105fab <strnlen+0xf>
		n++;
	return n;
f0105fc3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0105fc6:	c9                   	leave  
f0105fc7:	c3                   	ret    

f0105fc8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105fc8:	55                   	push   %ebp
f0105fc9:	89 e5                	mov    %esp,%ebp
f0105fcb:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0105fce:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fd1:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0105fd4:	90                   	nop
f0105fd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fd8:	8d 50 01             	lea    0x1(%eax),%edx
f0105fdb:	89 55 08             	mov    %edx,0x8(%ebp)
f0105fde:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105fe1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0105fe4:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0105fe7:	8a 12                	mov    (%edx),%dl
f0105fe9:	88 10                	mov    %dl,(%eax)
f0105feb:	8a 00                	mov    (%eax),%al
f0105fed:	84 c0                	test   %al,%al
f0105fef:	75 e4                	jne    f0105fd5 <strcpy+0xd>
		/* do nothing */;
	return ret;
f0105ff1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0105ff4:	c9                   	leave  
f0105ff5:	c3                   	ret    

f0105ff6 <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
f0105ff6:	55                   	push   %ebp
f0105ff7:	89 e5                	mov    %esp,%ebp
f0105ff9:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
f0105ffc:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fff:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0106002:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0106009:	eb 1f                	jmp    f010602a <strncpy+0x34>
		*dst++ = *src;
f010600b:	8b 45 08             	mov    0x8(%ebp),%eax
f010600e:	8d 50 01             	lea    0x1(%eax),%edx
f0106011:	89 55 08             	mov    %edx,0x8(%ebp)
f0106014:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106017:	8a 12                	mov    (%edx),%dl
f0106019:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f010601b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010601e:	8a 00                	mov    (%eax),%al
f0106020:	84 c0                	test   %al,%al
f0106022:	74 03                	je     f0106027 <strncpy+0x31>
			src++;
f0106024:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0106027:	ff 45 fc             	incl   -0x4(%ebp)
f010602a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010602d:	3b 45 10             	cmp    0x10(%ebp),%eax
f0106030:	72 d9                	jb     f010600b <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0106032:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0106035:	c9                   	leave  
f0106036:	c3                   	ret    

f0106037 <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
f0106037:	55                   	push   %ebp
f0106038:	89 e5                	mov    %esp,%ebp
f010603a:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f010603d:	8b 45 08             	mov    0x8(%ebp),%eax
f0106040:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0106043:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106047:	74 30                	je     f0106079 <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
f0106049:	eb 16                	jmp    f0106061 <strlcpy+0x2a>
			*dst++ = *src++;
f010604b:	8b 45 08             	mov    0x8(%ebp),%eax
f010604e:	8d 50 01             	lea    0x1(%eax),%edx
f0106051:	89 55 08             	mov    %edx,0x8(%ebp)
f0106054:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106057:	8d 4a 01             	lea    0x1(%edx),%ecx
f010605a:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f010605d:	8a 12                	mov    (%edx),%dl
f010605f:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0106061:	ff 4d 10             	decl   0x10(%ebp)
f0106064:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106068:	74 09                	je     f0106073 <strlcpy+0x3c>
f010606a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010606d:	8a 00                	mov    (%eax),%al
f010606f:	84 c0                	test   %al,%al
f0106071:	75 d8                	jne    f010604b <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0106073:	8b 45 08             	mov    0x8(%ebp),%eax
f0106076:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0106079:	8b 55 08             	mov    0x8(%ebp),%edx
f010607c:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010607f:	29 c2                	sub    %eax,%edx
f0106081:	89 d0                	mov    %edx,%eax
}
f0106083:	c9                   	leave  
f0106084:	c3                   	ret    

f0106085 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0106085:	55                   	push   %ebp
f0106086:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0106088:	eb 06                	jmp    f0106090 <strcmp+0xb>
		p++, q++;
f010608a:	ff 45 08             	incl   0x8(%ebp)
f010608d:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0106090:	8b 45 08             	mov    0x8(%ebp),%eax
f0106093:	8a 00                	mov    (%eax),%al
f0106095:	84 c0                	test   %al,%al
f0106097:	74 0e                	je     f01060a7 <strcmp+0x22>
f0106099:	8b 45 08             	mov    0x8(%ebp),%eax
f010609c:	8a 10                	mov    (%eax),%dl
f010609e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01060a1:	8a 00                	mov    (%eax),%al
f01060a3:	38 c2                	cmp    %al,%dl
f01060a5:	74 e3                	je     f010608a <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01060a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01060aa:	8a 00                	mov    (%eax),%al
f01060ac:	0f b6 d0             	movzbl %al,%edx
f01060af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01060b2:	8a 00                	mov    (%eax),%al
f01060b4:	0f b6 c0             	movzbl %al,%eax
f01060b7:	29 c2                	sub    %eax,%edx
f01060b9:	89 d0                	mov    %edx,%eax
}
f01060bb:	5d                   	pop    %ebp
f01060bc:	c3                   	ret    

f01060bd <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
f01060bd:	55                   	push   %ebp
f01060be:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f01060c0:	eb 09                	jmp    f01060cb <strncmp+0xe>
		n--, p++, q++;
f01060c2:	ff 4d 10             	decl   0x10(%ebp)
f01060c5:	ff 45 08             	incl   0x8(%ebp)
f01060c8:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
f01060cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01060cf:	74 17                	je     f01060e8 <strncmp+0x2b>
f01060d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01060d4:	8a 00                	mov    (%eax),%al
f01060d6:	84 c0                	test   %al,%al
f01060d8:	74 0e                	je     f01060e8 <strncmp+0x2b>
f01060da:	8b 45 08             	mov    0x8(%ebp),%eax
f01060dd:	8a 10                	mov    (%eax),%dl
f01060df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01060e2:	8a 00                	mov    (%eax),%al
f01060e4:	38 c2                	cmp    %al,%dl
f01060e6:	74 da                	je     f01060c2 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f01060e8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01060ec:	75 07                	jne    f01060f5 <strncmp+0x38>
		return 0;
f01060ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01060f3:	eb 14                	jmp    f0106109 <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01060f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01060f8:	8a 00                	mov    (%eax),%al
f01060fa:	0f b6 d0             	movzbl %al,%edx
f01060fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106100:	8a 00                	mov    (%eax),%al
f0106102:	0f b6 c0             	movzbl %al,%eax
f0106105:	29 c2                	sub    %eax,%edx
f0106107:	89 d0                	mov    %edx,%eax
}
f0106109:	5d                   	pop    %ebp
f010610a:	c3                   	ret    

f010610b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010610b:	55                   	push   %ebp
f010610c:	89 e5                	mov    %esp,%ebp
f010610e:	83 ec 04             	sub    $0x4,%esp
f0106111:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106114:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0106117:	eb 12                	jmp    f010612b <strchr+0x20>
		if (*s == c)
f0106119:	8b 45 08             	mov    0x8(%ebp),%eax
f010611c:	8a 00                	mov    (%eax),%al
f010611e:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0106121:	75 05                	jne    f0106128 <strchr+0x1d>
			return (char *) s;
f0106123:	8b 45 08             	mov    0x8(%ebp),%eax
f0106126:	eb 11                	jmp    f0106139 <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0106128:	ff 45 08             	incl   0x8(%ebp)
f010612b:	8b 45 08             	mov    0x8(%ebp),%eax
f010612e:	8a 00                	mov    (%eax),%al
f0106130:	84 c0                	test   %al,%al
f0106132:	75 e5                	jne    f0106119 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0106134:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106139:	c9                   	leave  
f010613a:	c3                   	ret    

f010613b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010613b:	55                   	push   %ebp
f010613c:	89 e5                	mov    %esp,%ebp
f010613e:	83 ec 04             	sub    $0x4,%esp
f0106141:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106144:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0106147:	eb 0d                	jmp    f0106156 <strfind+0x1b>
		if (*s == c)
f0106149:	8b 45 08             	mov    0x8(%ebp),%eax
f010614c:	8a 00                	mov    (%eax),%al
f010614e:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0106151:	74 0e                	je     f0106161 <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0106153:	ff 45 08             	incl   0x8(%ebp)
f0106156:	8b 45 08             	mov    0x8(%ebp),%eax
f0106159:	8a 00                	mov    (%eax),%al
f010615b:	84 c0                	test   %al,%al
f010615d:	75 ea                	jne    f0106149 <strfind+0xe>
f010615f:	eb 01                	jmp    f0106162 <strfind+0x27>
		if (*s == c)
			break;
f0106161:	90                   	nop
	return (char *) s;
f0106162:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106165:	c9                   	leave  
f0106166:	c3                   	ret    

f0106167 <memset>:


void *
memset(void *v, int c, uint32 n)
{
f0106167:	55                   	push   %ebp
f0106168:	89 e5                	mov    %esp,%ebp
f010616a:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f010616d:	8b 45 08             	mov    0x8(%ebp),%eax
f0106170:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0106173:	8b 45 10             	mov    0x10(%ebp),%eax
f0106176:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f0106179:	eb 0e                	jmp    f0106189 <memset+0x22>
		*p++ = c;
f010617b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010617e:	8d 50 01             	lea    0x1(%eax),%edx
f0106181:	89 55 fc             	mov    %edx,-0x4(%ebp)
f0106184:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106187:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0106189:	ff 4d f8             	decl   -0x8(%ebp)
f010618c:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0106190:	79 e9                	jns    f010617b <memset+0x14>
		*p++ = c;

	return v;
f0106192:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106195:	c9                   	leave  
f0106196:	c3                   	ret    

f0106197 <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
f0106197:	55                   	push   %ebp
f0106198:	89 e5                	mov    %esp,%ebp
f010619a:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f010619d:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061a0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f01061a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01061a6:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (n-- > 0)
f01061a9:	eb 16                	jmp    f01061c1 <memcpy+0x2a>
		*d++ = *s++;
f01061ab:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01061ae:	8d 50 01             	lea    0x1(%eax),%edx
f01061b1:	89 55 f8             	mov    %edx,-0x8(%ebp)
f01061b4:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01061b7:	8d 4a 01             	lea    0x1(%edx),%ecx
f01061ba:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f01061bd:	8a 12                	mov    (%edx),%dl
f01061bf:	88 10                	mov    %dl,(%eax)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f01061c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01061c4:	8d 50 ff             	lea    -0x1(%eax),%edx
f01061c7:	89 55 10             	mov    %edx,0x10(%ebp)
f01061ca:	85 c0                	test   %eax,%eax
f01061cc:	75 dd                	jne    f01061ab <memcpy+0x14>
		*d++ = *s++;

	return dst;
f01061ce:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01061d1:	c9                   	leave  
f01061d2:	c3                   	ret    

f01061d3 <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
f01061d3:	55                   	push   %ebp
f01061d4:	89 e5                	mov    %esp,%ebp
f01061d6:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f01061d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061dc:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f01061df:	8b 45 08             	mov    0x8(%ebp),%eax
f01061e2:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f01061e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01061e8:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01061eb:	73 50                	jae    f010623d <memmove+0x6a>
f01061ed:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01061f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01061f3:	01 d0                	add    %edx,%eax
f01061f5:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01061f8:	76 43                	jbe    f010623d <memmove+0x6a>
		s += n;
f01061fa:	8b 45 10             	mov    0x10(%ebp),%eax
f01061fd:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f0106200:	8b 45 10             	mov    0x10(%ebp),%eax
f0106203:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f0106206:	eb 10                	jmp    f0106218 <memmove+0x45>
			*--d = *--s;
f0106208:	ff 4d f8             	decl   -0x8(%ebp)
f010620b:	ff 4d fc             	decl   -0x4(%ebp)
f010620e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106211:	8a 10                	mov    (%eax),%dl
f0106213:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106216:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0106218:	8b 45 10             	mov    0x10(%ebp),%eax
f010621b:	8d 50 ff             	lea    -0x1(%eax),%edx
f010621e:	89 55 10             	mov    %edx,0x10(%ebp)
f0106221:	85 c0                	test   %eax,%eax
f0106223:	75 e3                	jne    f0106208 <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0106225:	eb 23                	jmp    f010624a <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0106227:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010622a:	8d 50 01             	lea    0x1(%eax),%edx
f010622d:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0106230:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0106233:	8d 4a 01             	lea    0x1(%edx),%ecx
f0106236:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0106239:	8a 12                	mov    (%edx),%dl
f010623b:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f010623d:	8b 45 10             	mov    0x10(%ebp),%eax
f0106240:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106243:	89 55 10             	mov    %edx,0x10(%ebp)
f0106246:	85 c0                	test   %eax,%eax
f0106248:	75 dd                	jne    f0106227 <memmove+0x54>
			*d++ = *s++;

	return dst;
f010624a:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010624d:	c9                   	leave  
f010624e:	c3                   	ret    

f010624f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
f010624f:	55                   	push   %ebp
f0106250:	89 e5                	mov    %esp,%ebp
f0106252:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
f0106255:	8b 45 08             	mov    0x8(%ebp),%eax
f0106258:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
f010625b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010625e:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0106261:	eb 2a                	jmp    f010628d <memcmp+0x3e>
		if (*s1 != *s2)
f0106263:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106266:	8a 10                	mov    (%eax),%dl
f0106268:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010626b:	8a 00                	mov    (%eax),%al
f010626d:	38 c2                	cmp    %al,%dl
f010626f:	74 16                	je     f0106287 <memcmp+0x38>
			return (int) *s1 - (int) *s2;
f0106271:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106274:	8a 00                	mov    (%eax),%al
f0106276:	0f b6 d0             	movzbl %al,%edx
f0106279:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010627c:	8a 00                	mov    (%eax),%al
f010627e:	0f b6 c0             	movzbl %al,%eax
f0106281:	29 c2                	sub    %eax,%edx
f0106283:	89 d0                	mov    %edx,%eax
f0106285:	eb 18                	jmp    f010629f <memcmp+0x50>
		s1++, s2++;
f0106287:	ff 45 fc             	incl   -0x4(%ebp)
f010628a:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
f010628d:	8b 45 10             	mov    0x10(%ebp),%eax
f0106290:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106293:	89 55 10             	mov    %edx,0x10(%ebp)
f0106296:	85 c0                	test   %eax,%eax
f0106298:	75 c9                	jne    f0106263 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010629a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010629f:	c9                   	leave  
f01062a0:	c3                   	ret    

f01062a1 <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
f01062a1:	55                   	push   %ebp
f01062a2:	89 e5                	mov    %esp,%ebp
f01062a4:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f01062a7:	8b 55 08             	mov    0x8(%ebp),%edx
f01062aa:	8b 45 10             	mov    0x10(%ebp),%eax
f01062ad:	01 d0                	add    %edx,%eax
f01062af:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f01062b2:	eb 15                	jmp    f01062c9 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01062b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01062b7:	8a 00                	mov    (%eax),%al
f01062b9:	0f b6 d0             	movzbl %al,%edx
f01062bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01062bf:	0f b6 c0             	movzbl %al,%eax
f01062c2:	39 c2                	cmp    %eax,%edx
f01062c4:	74 0d                	je     f01062d3 <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01062c6:	ff 45 08             	incl   0x8(%ebp)
f01062c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01062cc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01062cf:	72 e3                	jb     f01062b4 <memfind+0x13>
f01062d1:	eb 01                	jmp    f01062d4 <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f01062d3:	90                   	nop
	return (void *) s;
f01062d4:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01062d7:	c9                   	leave  
f01062d8:	c3                   	ret    

f01062d9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01062d9:	55                   	push   %ebp
f01062da:	89 e5                	mov    %esp,%ebp
f01062dc:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f01062df:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f01062e6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01062ed:	eb 03                	jmp    f01062f2 <strtol+0x19>
		s++;
f01062ef:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01062f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01062f5:	8a 00                	mov    (%eax),%al
f01062f7:	3c 20                	cmp    $0x20,%al
f01062f9:	74 f4                	je     f01062ef <strtol+0x16>
f01062fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01062fe:	8a 00                	mov    (%eax),%al
f0106300:	3c 09                	cmp    $0x9,%al
f0106302:	74 eb                	je     f01062ef <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0106304:	8b 45 08             	mov    0x8(%ebp),%eax
f0106307:	8a 00                	mov    (%eax),%al
f0106309:	3c 2b                	cmp    $0x2b,%al
f010630b:	75 05                	jne    f0106312 <strtol+0x39>
		s++;
f010630d:	ff 45 08             	incl   0x8(%ebp)
f0106310:	eb 13                	jmp    f0106325 <strtol+0x4c>
	else if (*s == '-')
f0106312:	8b 45 08             	mov    0x8(%ebp),%eax
f0106315:	8a 00                	mov    (%eax),%al
f0106317:	3c 2d                	cmp    $0x2d,%al
f0106319:	75 0a                	jne    f0106325 <strtol+0x4c>
		s++, neg = 1;
f010631b:	ff 45 08             	incl   0x8(%ebp)
f010631e:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0106325:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106329:	74 06                	je     f0106331 <strtol+0x58>
f010632b:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f010632f:	75 20                	jne    f0106351 <strtol+0x78>
f0106331:	8b 45 08             	mov    0x8(%ebp),%eax
f0106334:	8a 00                	mov    (%eax),%al
f0106336:	3c 30                	cmp    $0x30,%al
f0106338:	75 17                	jne    f0106351 <strtol+0x78>
f010633a:	8b 45 08             	mov    0x8(%ebp),%eax
f010633d:	40                   	inc    %eax
f010633e:	8a 00                	mov    (%eax),%al
f0106340:	3c 78                	cmp    $0x78,%al
f0106342:	75 0d                	jne    f0106351 <strtol+0x78>
		s += 2, base = 16;
f0106344:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0106348:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f010634f:	eb 28                	jmp    f0106379 <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
f0106351:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106355:	75 15                	jne    f010636c <strtol+0x93>
f0106357:	8b 45 08             	mov    0x8(%ebp),%eax
f010635a:	8a 00                	mov    (%eax),%al
f010635c:	3c 30                	cmp    $0x30,%al
f010635e:	75 0c                	jne    f010636c <strtol+0x93>
		s++, base = 8;
f0106360:	ff 45 08             	incl   0x8(%ebp)
f0106363:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f010636a:	eb 0d                	jmp    f0106379 <strtol+0xa0>
	else if (base == 0)
f010636c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106370:	75 07                	jne    f0106379 <strtol+0xa0>
		base = 10;
f0106372:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0106379:	8b 45 08             	mov    0x8(%ebp),%eax
f010637c:	8a 00                	mov    (%eax),%al
f010637e:	3c 2f                	cmp    $0x2f,%al
f0106380:	7e 19                	jle    f010639b <strtol+0xc2>
f0106382:	8b 45 08             	mov    0x8(%ebp),%eax
f0106385:	8a 00                	mov    (%eax),%al
f0106387:	3c 39                	cmp    $0x39,%al
f0106389:	7f 10                	jg     f010639b <strtol+0xc2>
			dig = *s - '0';
f010638b:	8b 45 08             	mov    0x8(%ebp),%eax
f010638e:	8a 00                	mov    (%eax),%al
f0106390:	0f be c0             	movsbl %al,%eax
f0106393:	83 e8 30             	sub    $0x30,%eax
f0106396:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0106399:	eb 42                	jmp    f01063dd <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
f010639b:	8b 45 08             	mov    0x8(%ebp),%eax
f010639e:	8a 00                	mov    (%eax),%al
f01063a0:	3c 60                	cmp    $0x60,%al
f01063a2:	7e 19                	jle    f01063bd <strtol+0xe4>
f01063a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01063a7:	8a 00                	mov    (%eax),%al
f01063a9:	3c 7a                	cmp    $0x7a,%al
f01063ab:	7f 10                	jg     f01063bd <strtol+0xe4>
			dig = *s - 'a' + 10;
f01063ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01063b0:	8a 00                	mov    (%eax),%al
f01063b2:	0f be c0             	movsbl %al,%eax
f01063b5:	83 e8 57             	sub    $0x57,%eax
f01063b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01063bb:	eb 20                	jmp    f01063dd <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
f01063bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01063c0:	8a 00                	mov    (%eax),%al
f01063c2:	3c 40                	cmp    $0x40,%al
f01063c4:	7e 39                	jle    f01063ff <strtol+0x126>
f01063c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01063c9:	8a 00                	mov    (%eax),%al
f01063cb:	3c 5a                	cmp    $0x5a,%al
f01063cd:	7f 30                	jg     f01063ff <strtol+0x126>
			dig = *s - 'A' + 10;
f01063cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01063d2:	8a 00                	mov    (%eax),%al
f01063d4:	0f be c0             	movsbl %al,%eax
f01063d7:	83 e8 37             	sub    $0x37,%eax
f01063da:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f01063dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01063e0:	3b 45 10             	cmp    0x10(%ebp),%eax
f01063e3:	7d 19                	jge    f01063fe <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
f01063e5:	ff 45 08             	incl   0x8(%ebp)
f01063e8:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01063eb:	0f af 45 10          	imul   0x10(%ebp),%eax
f01063ef:	89 c2                	mov    %eax,%edx
f01063f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01063f4:	01 d0                	add    %edx,%eax
f01063f6:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f01063f9:	e9 7b ff ff ff       	jmp    f0106379 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f01063fe:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01063ff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106403:	74 08                	je     f010640d <strtol+0x134>
		*endptr = (char *) s;
f0106405:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106408:	8b 55 08             	mov    0x8(%ebp),%edx
f010640b:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f010640d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0106411:	74 07                	je     f010641a <strtol+0x141>
f0106413:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106416:	f7 d8                	neg    %eax
f0106418:	eb 03                	jmp    f010641d <strtol+0x144>
f010641a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f010641d:	c9                   	leave  
f010641e:	c3                   	ret    

f010641f <strsplit>:

int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
f010641f:	55                   	push   %ebp
f0106420:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
f0106422:	8b 45 14             	mov    0x14(%ebp),%eax
f0106425:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
f010642b:	8b 45 14             	mov    0x14(%ebp),%eax
f010642e:	8b 00                	mov    (%eax),%eax
f0106430:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0106437:	8b 45 10             	mov    0x10(%ebp),%eax
f010643a:	01 d0                	add    %edx,%eax
f010643c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0106442:	eb 0c                	jmp    f0106450 <strsplit+0x31>
			*string++ = 0;
f0106444:	8b 45 08             	mov    0x8(%ebp),%eax
f0106447:	8d 50 01             	lea    0x1(%eax),%edx
f010644a:	89 55 08             	mov    %edx,0x8(%ebp)
f010644d:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0106450:	8b 45 08             	mov    0x8(%ebp),%eax
f0106453:	8a 00                	mov    (%eax),%al
f0106455:	84 c0                	test   %al,%al
f0106457:	74 18                	je     f0106471 <strsplit+0x52>
f0106459:	8b 45 08             	mov    0x8(%ebp),%eax
f010645c:	8a 00                	mov    (%eax),%al
f010645e:	0f be c0             	movsbl %al,%eax
f0106461:	50                   	push   %eax
f0106462:	ff 75 0c             	pushl  0xc(%ebp)
f0106465:	e8 a1 fc ff ff       	call   f010610b <strchr>
f010646a:	83 c4 08             	add    $0x8,%esp
f010646d:	85 c0                	test   %eax,%eax
f010646f:	75 d3                	jne    f0106444 <strsplit+0x25>
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
f0106471:	8b 45 08             	mov    0x8(%ebp),%eax
f0106474:	8a 00                	mov    (%eax),%al
f0106476:	84 c0                	test   %al,%al
f0106478:	74 5a                	je     f01064d4 <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1) 
f010647a:	8b 45 14             	mov    0x14(%ebp),%eax
f010647d:	8b 00                	mov    (%eax),%eax
f010647f:	83 f8 0f             	cmp    $0xf,%eax
f0106482:	75 07                	jne    f010648b <strsplit+0x6c>
		{
			return 0;
f0106484:	b8 00 00 00 00       	mov    $0x0,%eax
f0106489:	eb 66                	jmp    f01064f1 <strsplit+0xd2>
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
f010648b:	8b 45 14             	mov    0x14(%ebp),%eax
f010648e:	8b 00                	mov    (%eax),%eax
f0106490:	8d 48 01             	lea    0x1(%eax),%ecx
f0106493:	8b 55 14             	mov    0x14(%ebp),%edx
f0106496:	89 0a                	mov    %ecx,(%edx)
f0106498:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010649f:	8b 45 10             	mov    0x10(%ebp),%eax
f01064a2:	01 c2                	add    %eax,%edx
f01064a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01064a7:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
f01064a9:	eb 03                	jmp    f01064ae <strsplit+0x8f>
			string++;
f01064ab:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
f01064ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01064b1:	8a 00                	mov    (%eax),%al
f01064b3:	84 c0                	test   %al,%al
f01064b5:	74 8b                	je     f0106442 <strsplit+0x23>
f01064b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01064ba:	8a 00                	mov    (%eax),%al
f01064bc:	0f be c0             	movsbl %al,%eax
f01064bf:	50                   	push   %eax
f01064c0:	ff 75 0c             	pushl  0xc(%ebp)
f01064c3:	e8 43 fc ff ff       	call   f010610b <strchr>
f01064c8:	83 c4 08             	add    $0x8,%esp
f01064cb:	85 c0                	test   %eax,%eax
f01064cd:	74 dc                	je     f01064ab <strsplit+0x8c>
			string++;
	}
f01064cf:	e9 6e ff ff ff       	jmp    f0106442 <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
f01064d4:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
f01064d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01064d8:	8b 00                	mov    (%eax),%eax
f01064da:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01064e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01064e4:	01 d0                	add    %edx,%eax
f01064e6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
f01064ec:	b8 01 00 00 00       	mov    $0x1,%eax
}
f01064f1:	c9                   	leave  
f01064f2:	c3                   	ret    
f01064f3:	90                   	nop

f01064f4 <__udivdi3>:
f01064f4:	55                   	push   %ebp
f01064f5:	57                   	push   %edi
f01064f6:	56                   	push   %esi
f01064f7:	53                   	push   %ebx
f01064f8:	83 ec 1c             	sub    $0x1c,%esp
f01064fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01064ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0106503:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106507:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010650b:	89 ca                	mov    %ecx,%edx
f010650d:	89 f8                	mov    %edi,%eax
f010650f:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0106513:	85 f6                	test   %esi,%esi
f0106515:	75 2d                	jne    f0106544 <__udivdi3+0x50>
f0106517:	39 cf                	cmp    %ecx,%edi
f0106519:	77 65                	ja     f0106580 <__udivdi3+0x8c>
f010651b:	89 fd                	mov    %edi,%ebp
f010651d:	85 ff                	test   %edi,%edi
f010651f:	75 0b                	jne    f010652c <__udivdi3+0x38>
f0106521:	b8 01 00 00 00       	mov    $0x1,%eax
f0106526:	31 d2                	xor    %edx,%edx
f0106528:	f7 f7                	div    %edi
f010652a:	89 c5                	mov    %eax,%ebp
f010652c:	31 d2                	xor    %edx,%edx
f010652e:	89 c8                	mov    %ecx,%eax
f0106530:	f7 f5                	div    %ebp
f0106532:	89 c1                	mov    %eax,%ecx
f0106534:	89 d8                	mov    %ebx,%eax
f0106536:	f7 f5                	div    %ebp
f0106538:	89 cf                	mov    %ecx,%edi
f010653a:	89 fa                	mov    %edi,%edx
f010653c:	83 c4 1c             	add    $0x1c,%esp
f010653f:	5b                   	pop    %ebx
f0106540:	5e                   	pop    %esi
f0106541:	5f                   	pop    %edi
f0106542:	5d                   	pop    %ebp
f0106543:	c3                   	ret    
f0106544:	39 ce                	cmp    %ecx,%esi
f0106546:	77 28                	ja     f0106570 <__udivdi3+0x7c>
f0106548:	0f bd fe             	bsr    %esi,%edi
f010654b:	83 f7 1f             	xor    $0x1f,%edi
f010654e:	75 40                	jne    f0106590 <__udivdi3+0x9c>
f0106550:	39 ce                	cmp    %ecx,%esi
f0106552:	72 0a                	jb     f010655e <__udivdi3+0x6a>
f0106554:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0106558:	0f 87 9e 00 00 00    	ja     f01065fc <__udivdi3+0x108>
f010655e:	b8 01 00 00 00       	mov    $0x1,%eax
f0106563:	89 fa                	mov    %edi,%edx
f0106565:	83 c4 1c             	add    $0x1c,%esp
f0106568:	5b                   	pop    %ebx
f0106569:	5e                   	pop    %esi
f010656a:	5f                   	pop    %edi
f010656b:	5d                   	pop    %ebp
f010656c:	c3                   	ret    
f010656d:	8d 76 00             	lea    0x0(%esi),%esi
f0106570:	31 ff                	xor    %edi,%edi
f0106572:	31 c0                	xor    %eax,%eax
f0106574:	89 fa                	mov    %edi,%edx
f0106576:	83 c4 1c             	add    $0x1c,%esp
f0106579:	5b                   	pop    %ebx
f010657a:	5e                   	pop    %esi
f010657b:	5f                   	pop    %edi
f010657c:	5d                   	pop    %ebp
f010657d:	c3                   	ret    
f010657e:	66 90                	xchg   %ax,%ax
f0106580:	89 d8                	mov    %ebx,%eax
f0106582:	f7 f7                	div    %edi
f0106584:	31 ff                	xor    %edi,%edi
f0106586:	89 fa                	mov    %edi,%edx
f0106588:	83 c4 1c             	add    $0x1c,%esp
f010658b:	5b                   	pop    %ebx
f010658c:	5e                   	pop    %esi
f010658d:	5f                   	pop    %edi
f010658e:	5d                   	pop    %ebp
f010658f:	c3                   	ret    
f0106590:	bd 20 00 00 00       	mov    $0x20,%ebp
f0106595:	89 eb                	mov    %ebp,%ebx
f0106597:	29 fb                	sub    %edi,%ebx
f0106599:	89 f9                	mov    %edi,%ecx
f010659b:	d3 e6                	shl    %cl,%esi
f010659d:	89 c5                	mov    %eax,%ebp
f010659f:	88 d9                	mov    %bl,%cl
f01065a1:	d3 ed                	shr    %cl,%ebp
f01065a3:	89 e9                	mov    %ebp,%ecx
f01065a5:	09 f1                	or     %esi,%ecx
f01065a7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01065ab:	89 f9                	mov    %edi,%ecx
f01065ad:	d3 e0                	shl    %cl,%eax
f01065af:	89 c5                	mov    %eax,%ebp
f01065b1:	89 d6                	mov    %edx,%esi
f01065b3:	88 d9                	mov    %bl,%cl
f01065b5:	d3 ee                	shr    %cl,%esi
f01065b7:	89 f9                	mov    %edi,%ecx
f01065b9:	d3 e2                	shl    %cl,%edx
f01065bb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01065bf:	88 d9                	mov    %bl,%cl
f01065c1:	d3 e8                	shr    %cl,%eax
f01065c3:	09 c2                	or     %eax,%edx
f01065c5:	89 d0                	mov    %edx,%eax
f01065c7:	89 f2                	mov    %esi,%edx
f01065c9:	f7 74 24 0c          	divl   0xc(%esp)
f01065cd:	89 d6                	mov    %edx,%esi
f01065cf:	89 c3                	mov    %eax,%ebx
f01065d1:	f7 e5                	mul    %ebp
f01065d3:	39 d6                	cmp    %edx,%esi
f01065d5:	72 19                	jb     f01065f0 <__udivdi3+0xfc>
f01065d7:	74 0b                	je     f01065e4 <__udivdi3+0xf0>
f01065d9:	89 d8                	mov    %ebx,%eax
f01065db:	31 ff                	xor    %edi,%edi
f01065dd:	e9 58 ff ff ff       	jmp    f010653a <__udivdi3+0x46>
f01065e2:	66 90                	xchg   %ax,%ax
f01065e4:	8b 54 24 08          	mov    0x8(%esp),%edx
f01065e8:	89 f9                	mov    %edi,%ecx
f01065ea:	d3 e2                	shl    %cl,%edx
f01065ec:	39 c2                	cmp    %eax,%edx
f01065ee:	73 e9                	jae    f01065d9 <__udivdi3+0xe5>
f01065f0:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01065f3:	31 ff                	xor    %edi,%edi
f01065f5:	e9 40 ff ff ff       	jmp    f010653a <__udivdi3+0x46>
f01065fa:	66 90                	xchg   %ax,%ax
f01065fc:	31 c0                	xor    %eax,%eax
f01065fe:	e9 37 ff ff ff       	jmp    f010653a <__udivdi3+0x46>
f0106603:	90                   	nop

f0106604 <__umoddi3>:
f0106604:	55                   	push   %ebp
f0106605:	57                   	push   %edi
f0106606:	56                   	push   %esi
f0106607:	53                   	push   %ebx
f0106608:	83 ec 1c             	sub    $0x1c,%esp
f010660b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010660f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0106613:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106617:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010661b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010661f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106623:	89 f3                	mov    %esi,%ebx
f0106625:	89 fa                	mov    %edi,%edx
f0106627:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010662b:	89 34 24             	mov    %esi,(%esp)
f010662e:	85 c0                	test   %eax,%eax
f0106630:	75 1a                	jne    f010664c <__umoddi3+0x48>
f0106632:	39 f7                	cmp    %esi,%edi
f0106634:	0f 86 a2 00 00 00    	jbe    f01066dc <__umoddi3+0xd8>
f010663a:	89 c8                	mov    %ecx,%eax
f010663c:	89 f2                	mov    %esi,%edx
f010663e:	f7 f7                	div    %edi
f0106640:	89 d0                	mov    %edx,%eax
f0106642:	31 d2                	xor    %edx,%edx
f0106644:	83 c4 1c             	add    $0x1c,%esp
f0106647:	5b                   	pop    %ebx
f0106648:	5e                   	pop    %esi
f0106649:	5f                   	pop    %edi
f010664a:	5d                   	pop    %ebp
f010664b:	c3                   	ret    
f010664c:	39 f0                	cmp    %esi,%eax
f010664e:	0f 87 ac 00 00 00    	ja     f0106700 <__umoddi3+0xfc>
f0106654:	0f bd e8             	bsr    %eax,%ebp
f0106657:	83 f5 1f             	xor    $0x1f,%ebp
f010665a:	0f 84 ac 00 00 00    	je     f010670c <__umoddi3+0x108>
f0106660:	bf 20 00 00 00       	mov    $0x20,%edi
f0106665:	29 ef                	sub    %ebp,%edi
f0106667:	89 fe                	mov    %edi,%esi
f0106669:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010666d:	89 e9                	mov    %ebp,%ecx
f010666f:	d3 e0                	shl    %cl,%eax
f0106671:	89 d7                	mov    %edx,%edi
f0106673:	89 f1                	mov    %esi,%ecx
f0106675:	d3 ef                	shr    %cl,%edi
f0106677:	09 c7                	or     %eax,%edi
f0106679:	89 e9                	mov    %ebp,%ecx
f010667b:	d3 e2                	shl    %cl,%edx
f010667d:	89 14 24             	mov    %edx,(%esp)
f0106680:	89 d8                	mov    %ebx,%eax
f0106682:	d3 e0                	shl    %cl,%eax
f0106684:	89 c2                	mov    %eax,%edx
f0106686:	8b 44 24 08          	mov    0x8(%esp),%eax
f010668a:	d3 e0                	shl    %cl,%eax
f010668c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106690:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106694:	89 f1                	mov    %esi,%ecx
f0106696:	d3 e8                	shr    %cl,%eax
f0106698:	09 d0                	or     %edx,%eax
f010669a:	d3 eb                	shr    %cl,%ebx
f010669c:	89 da                	mov    %ebx,%edx
f010669e:	f7 f7                	div    %edi
f01066a0:	89 d3                	mov    %edx,%ebx
f01066a2:	f7 24 24             	mull   (%esp)
f01066a5:	89 c6                	mov    %eax,%esi
f01066a7:	89 d1                	mov    %edx,%ecx
f01066a9:	39 d3                	cmp    %edx,%ebx
f01066ab:	0f 82 87 00 00 00    	jb     f0106738 <__umoddi3+0x134>
f01066b1:	0f 84 91 00 00 00    	je     f0106748 <__umoddi3+0x144>
f01066b7:	8b 54 24 04          	mov    0x4(%esp),%edx
f01066bb:	29 f2                	sub    %esi,%edx
f01066bd:	19 cb                	sbb    %ecx,%ebx
f01066bf:	89 d8                	mov    %ebx,%eax
f01066c1:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f01066c5:	d3 e0                	shl    %cl,%eax
f01066c7:	89 e9                	mov    %ebp,%ecx
f01066c9:	d3 ea                	shr    %cl,%edx
f01066cb:	09 d0                	or     %edx,%eax
f01066cd:	89 e9                	mov    %ebp,%ecx
f01066cf:	d3 eb                	shr    %cl,%ebx
f01066d1:	89 da                	mov    %ebx,%edx
f01066d3:	83 c4 1c             	add    $0x1c,%esp
f01066d6:	5b                   	pop    %ebx
f01066d7:	5e                   	pop    %esi
f01066d8:	5f                   	pop    %edi
f01066d9:	5d                   	pop    %ebp
f01066da:	c3                   	ret    
f01066db:	90                   	nop
f01066dc:	89 fd                	mov    %edi,%ebp
f01066de:	85 ff                	test   %edi,%edi
f01066e0:	75 0b                	jne    f01066ed <__umoddi3+0xe9>
f01066e2:	b8 01 00 00 00       	mov    $0x1,%eax
f01066e7:	31 d2                	xor    %edx,%edx
f01066e9:	f7 f7                	div    %edi
f01066eb:	89 c5                	mov    %eax,%ebp
f01066ed:	89 f0                	mov    %esi,%eax
f01066ef:	31 d2                	xor    %edx,%edx
f01066f1:	f7 f5                	div    %ebp
f01066f3:	89 c8                	mov    %ecx,%eax
f01066f5:	f7 f5                	div    %ebp
f01066f7:	89 d0                	mov    %edx,%eax
f01066f9:	e9 44 ff ff ff       	jmp    f0106642 <__umoddi3+0x3e>
f01066fe:	66 90                	xchg   %ax,%ax
f0106700:	89 c8                	mov    %ecx,%eax
f0106702:	89 f2                	mov    %esi,%edx
f0106704:	83 c4 1c             	add    $0x1c,%esp
f0106707:	5b                   	pop    %ebx
f0106708:	5e                   	pop    %esi
f0106709:	5f                   	pop    %edi
f010670a:	5d                   	pop    %ebp
f010670b:	c3                   	ret    
f010670c:	3b 04 24             	cmp    (%esp),%eax
f010670f:	72 06                	jb     f0106717 <__umoddi3+0x113>
f0106711:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0106715:	77 0f                	ja     f0106726 <__umoddi3+0x122>
f0106717:	89 f2                	mov    %esi,%edx
f0106719:	29 f9                	sub    %edi,%ecx
f010671b:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010671f:	89 14 24             	mov    %edx,(%esp)
f0106722:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0106726:	8b 44 24 04          	mov    0x4(%esp),%eax
f010672a:	8b 14 24             	mov    (%esp),%edx
f010672d:	83 c4 1c             	add    $0x1c,%esp
f0106730:	5b                   	pop    %ebx
f0106731:	5e                   	pop    %esi
f0106732:	5f                   	pop    %edi
f0106733:	5d                   	pop    %ebp
f0106734:	c3                   	ret    
f0106735:	8d 76 00             	lea    0x0(%esi),%esi
f0106738:	2b 04 24             	sub    (%esp),%eax
f010673b:	19 fa                	sbb    %edi,%edx
f010673d:	89 d1                	mov    %edx,%ecx
f010673f:	89 c6                	mov    %eax,%esi
f0106741:	e9 71 ff ff ff       	jmp    f01066b7 <__umoddi3+0xb3>
f0106746:	66 90                	xchg   %ax,%ax
f0106748:	39 44 24 04          	cmp    %eax,0x4(%esp)
f010674c:	72 ea                	jb     f0106738 <__umoddi3+0x134>
f010674e:	89 d9                	mov    %ebx,%ecx
f0106750:	e9 62 ff ff ff       	jmp    f01066b7 <__umoddi3+0xb3>
