
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 00 1a 10 f0 	movl   $0xf0101a00,(%esp)
f0100055:	e8 94 09 00 00       	call   f01009ee <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 34 07 00 00       	call   f01007bb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 1c 1a 10 f0 	movl   $0xf0101a1c,(%esp)
f0100092:	e8 57 09 00 00       	call   f01009ee <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 92 14 00 00       	call   f0101557 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("444544 decimal is %o octal!\n", 444544);
f01000ca:	c7 44 24 04 80 c8 06 	movl   $0x6c880,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f01000d9:	e8 10 09 00 00       	call   f01009ee <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 7f 07 00 00       	call   f0100875 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 54 1a 10 f0 	movl   $0xf0101a54,(%esp)
f010012c:	e8 bd 08 00 00       	call   f01009ee <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 7e 08 00 00       	call   f01009bb <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100144:	e8 a5 08 00 00       	call   f01009ee <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 20 07 00 00       	call   f0100875 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 6c 1a 10 f0 	movl   $0xf0101a6c,(%esp)
f0100176:	e8 73 08 00 00       	call   f01009ee <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 31 08 00 00       	call   f01009bb <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100191:	e8 58 08 00 00       	call   f01009ee <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 f7 00 00 00    	je     f0100305 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f010020e:	a8 20                	test   $0x20,%al
f0100210:	0f 85 f5 00 00 00    	jne    f010030b <kbd_proc_data+0x10b>
f0100216:	b2 60                	mov    $0x60,%dl
f0100218:	ec                   	in     (%dx),%al
f0100219:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010021b:	3c e0                	cmp    $0xe0,%al
f010021d:	75 0d                	jne    f010022c <kbd_proc_data+0x2c>
		shift |= E0ESC;
f010021f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100226:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010022b:	c3                   	ret    
{
f010022c:	55                   	push   %ebp
f010022d:	89 e5                	mov    %esp,%ebp
f010022f:	53                   	push   %ebx
f0100230:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f0100233:	84 c0                	test   %al,%al
f0100235:	79 37                	jns    f010026e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f0100237:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010023d:	89 cb                	mov    %ecx,%ebx
f010023f:	83 e3 40             	and    $0x40,%ebx
f0100242:	83 e0 7f             	and    $0x7f,%eax
f0100245:	85 db                	test   %ebx,%ebx
f0100247:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 82 e0 1b 10 f0 	movzbl -0xfefe420(%edx),%eax
f0100254:	83 c8 40             	or     $0x40,%eax
f0100257:	0f b6 c0             	movzbl %al,%eax
f010025a:	f7 d0                	not    %eax
f010025c:	21 c1                	and    %eax,%ecx
f010025e:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f0100264:	b8 00 00 00 00       	mov    $0x0,%eax
f0100269:	e9 a3 00 00 00       	jmp    f0100311 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010026e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100274:	f6 c1 40             	test   $0x40,%cl
f0100277:	74 0e                	je     f0100287 <kbd_proc_data+0x87>
		data |= 0x80;
f0100279:	83 c8 80             	or     $0xffffff80,%eax
f010027c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010027e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100281:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	shift |= shiftcode[data];
f0100287:	0f b6 d2             	movzbl %dl,%edx
f010028a:	0f b6 82 e0 1b 10 f0 	movzbl -0xfefe420(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a e0 1a 10 f0 	movzbl -0xfefe520(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300
	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d c0 1a 10 f0 	mov    -0xfefe540(,%ecx,4),%ecx
f01002b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b8:	a8 08                	test   $0x8,%al
f01002ba:	74 1b                	je     f01002d7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01002bc:	89 da                	mov    %ebx,%edx
f01002be:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002c1:	83 f9 19             	cmp    $0x19,%ecx
f01002c4:	77 05                	ja     f01002cb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01002c6:	83 eb 20             	sub    $0x20,%ebx
f01002c9:	eb 0c                	jmp    f01002d7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01002cb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002ce:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002d1:	83 fa 19             	cmp    $0x19,%edx
f01002d4:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d7:	f7 d0                	not    %eax
f01002d9:	89 c2                	mov    %eax,%edx
	return c;
f01002db:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002dd:	f6 c2 06             	test   $0x6,%dl
f01002e0:	75 2f                	jne    f0100311 <kbd_proc_data+0x111>
f01002e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e8:	75 27                	jne    f0100311 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002ea:	c7 04 24 86 1a 10 f0 	movl   $0xf0101a86,(%esp)
f01002f1:	e8 f8 06 00 00       	call   f01009ee <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002fb:	b8 03 00 00 00       	mov    $0x3,%eax
f0100300:	ee                   	out    %al,(%dx)
	return c;
f0100301:	89 d8                	mov    %ebx,%eax
f0100303:	eb 0c                	jmp    f0100311 <kbd_proc_data+0x111>
		return -1;
f0100305:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010030a:	c3                   	ret    
		return -1;
f010030b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100310:	c3                   	ret    
}
f0100311:	83 c4 14             	add    $0x14,%esp
f0100314:	5b                   	pop    %ebx
f0100315:	5d                   	pop    %ebp
f0100316:	c3                   	ret    

f0100317 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100317:	55                   	push   %ebp
f0100318:	89 e5                	mov    %esp,%ebp
f010031a:	57                   	push   %edi
f010031b:	56                   	push   %esi
f010031c:	53                   	push   %ebx
f010031d:	83 ec 1c             	sub    $0x1c,%esp
f0100320:	89 c7                	mov    %eax,%edi
f0100322:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100327:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100331:	eb 06                	jmp    f0100339 <cons_putc+0x22>
f0100333:	89 ca                	mov    %ecx,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 f2                	mov    %esi,%edx
f010033b:	ec                   	in     (%dx),%al
	for (i = 0;
f010033c:	a8 20                	test   $0x20,%al
f010033e:	75 05                	jne    f0100345 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100340:	83 eb 01             	sub    $0x1,%ebx
f0100343:	75 ee                	jne    f0100333 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	0f b6 c0             	movzbl %al,%eax
f010034a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100352:	ee                   	out    %al,(%dx)
f0100353:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100358:	be 79 03 00 00       	mov    $0x379,%esi
f010035d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100362:	eb 06                	jmp    f010036a <cons_putc+0x53>
f0100364:	89 ca                	mov    %ecx,%edx
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	89 f2                	mov    %esi,%edx
f010036c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036d:	84 c0                	test   %al,%al
f010036f:	78 05                	js     f0100376 <cons_putc+0x5f>
f0100371:	83 eb 01             	sub    $0x1,%ebx
f0100374:	75 ee                	jne    f0100364 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100376:	ba 78 03 00 00       	mov    $0x378,%edx
f010037b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b2 7a                	mov    $0x7a,%dl
f0100382:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	b8 08 00 00 00       	mov    $0x8,%eax
f010038d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010038e:	89 fa                	mov    %edi,%edx
f0100390:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100396:	89 f8                	mov    %edi,%eax
f0100398:	80 cc 07             	or     $0x7,%ah
f010039b:	85 d2                	test   %edx,%edx
f010039d:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01003a0:	89 f8                	mov    %edi,%eax
f01003a2:	0f b6 c0             	movzbl %al,%eax
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	74 78                	je     f0100422 <cons_putc+0x10b>
f01003aa:	83 f8 09             	cmp    $0x9,%eax
f01003ad:	7f 0a                	jg     f01003b9 <cons_putc+0xa2>
f01003af:	83 f8 08             	cmp    $0x8,%eax
f01003b2:	74 18                	je     f01003cc <cons_putc+0xb5>
f01003b4:	e9 9d 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
f01003b9:	83 f8 0a             	cmp    $0xa,%eax
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xe5>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xed>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
		if (crt_pos > 0) {
f01003cc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1aa>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100403:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x15d>
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 eb fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 e1 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 d7 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 cd fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 c3 fe ff ff       	call   f0100317 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 06 11 00 00       	call   f01015a4 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c0:	50 
	outb(addr_6845, 14);
f01004c1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
	if (serial_exists)
f01004f7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100535:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010053a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010054b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100595:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010059c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005b4:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01005bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01005ec:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f0100654:	e8 95 03 00 00       	call   f01009ee <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 a8 fc ff ff       	call   f0100317 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 a9 fe ff ff       	call   f0100525 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 e0 1c 10 	movl   $0xf0101ce0,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 fe 1c 10 	movl   $0xf0101cfe,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 03 1d 10 f0 	movl   $0xf0101d03,(%esp)
f01006ad:	e8 3c 03 00 00       	call   f01009ee <cprintf>
f01006b2:	c7 44 24 08 b4 1d 10 	movl   $0xf0101db4,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 0c 1d 10 	movl   $0xf0101d0c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 03 1d 10 f0 	movl   $0xf0101d03,(%esp)
f01006c9:	e8 20 03 00 00       	call   f01009ee <cprintf>
f01006ce:	c7 44 24 08 dc 1d 10 	movl   $0xf0101ddc,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 15 1d 10 	movl   $0xf0101d15,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 03 1d 10 f0 	movl   $0xf0101d03,(%esp)
f01006e5:	e8 04 03 00 00       	call   f01009ee <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 1f 1d 10 f0 	movl   $0xf0101d1f,(%esp)
f01006fe:	e8 eb 02 00 00       	call   f01009ee <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100703:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010070a:	00 
f010070b:	c7 04 24 10 1e 10 f0 	movl   $0xf0101e10,(%esp)
f0100712:	e8 d7 02 00 00       	call   f01009ee <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100717:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 38 1e 10 f0 	movl   $0xf0101e38,(%esp)
f010072e:	e8 bb 02 00 00       	call   f01009ee <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100733:	c7 44 24 08 e7 19 10 	movl   $0x1019e7,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 e7 19 10 	movl   $0xf01019e7,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 5c 1e 10 f0 	movl   $0xf0101e5c,(%esp)
f010074a:	e8 9f 02 00 00       	call   f01009ee <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f0100766:	e8 83 02 00 00       	call   f01009ee <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010076b:	c7 44 24 08 40 29 11 	movl   $0x112940,0x8(%esp)
f0100772:	00 
f0100773:	c7 44 24 04 40 29 11 	movl   $0xf0112940,0x4(%esp)
f010077a:	f0 
f010077b:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f0100782:	e8 67 02 00 00       	call   f01009ee <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100787:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f010078c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100791:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100796:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010079c:	85 c0                	test   %eax,%eax
f010079e:	0f 48 c2             	cmovs  %edx,%eax
f01007a1:	c1 f8 0a             	sar    $0xa,%eax
f01007a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a8:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f01007af:	e8 3a 02 00 00       	call   f01009ee <cprintf>
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
f01007be:	57                   	push   %edi
f01007bf:	56                   	push   %esi
f01007c0:	53                   	push   %ebx
f01007c1:	83 ec 4c             	sub    $0x4c,%esp
	// LAB 1: Your code here.
    // HINT 1: use read_ebp().
    // HINT 2: print the current ebp on the first line (not current_ebp[0])

	// Here is the code implementation
	int *ebp = (int *)read_ebp();
f01007c4:	89 ee                	mov    %ebp,%esi
   cprintf("Stack backtrace:\n");
f01007c6:	c7 04 24 38 1d 10 f0 	movl   $0xf0101d38,(%esp)
f01007cd:	e8 1c 02 00 00       	call   f01009ee <cprintf>
		}
		cprintf("\n");													// Print a new line to separate things out

		// This is the part printing out the file name, line, etc...
		struct Eipdebuginfo fn_info;								// Create a struct to pass through the debuginfo fn
		debuginfo_eip(ebp[1], &fn_info);							// Call the funct. and print the statement
f01007d2:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while (ebp) {														// Create a while loop to loop through ebp content
f01007d5:	e9 86 00 00 00       	jmp    f0100860 <mon_backtrace+0xa5>
		cprintf("ebp %08x eip %08x args", ebp, ebp[1]);		// Print out the EBP & the EIP
f01007da:	8b 46 04             	mov    0x4(%esi),%eax
f01007dd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007e5:	c7 04 24 4a 1d 10 f0 	movl   $0xf0101d4a,(%esp)
f01007ec:	e8 fd 01 00 00       	call   f01009ee <cprintf>
		for (i = 2; i < 7; i++) {									// Create a for loop to print out the EBP[2]-[6]
f01007f1:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", ebp[i]);
f01007f6:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fd:	c7 04 24 61 1d 10 f0 	movl   $0xf0101d61,(%esp)
f0100804:	e8 e5 01 00 00       	call   f01009ee <cprintf>
		for (i = 2; i < 7; i++) {									// Create a for loop to print out the EBP[2]-[6]
f0100809:	83 c3 01             	add    $0x1,%ebx
f010080c:	83 fb 07             	cmp    $0x7,%ebx
f010080f:	75 e5                	jne    f01007f6 <mon_backtrace+0x3b>
		cprintf("\n");													// Print a new line to separate things out
f0100811:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100818:	e8 d1 01 00 00       	call   f01009ee <cprintf>
		debuginfo_eip(ebp[1], &fn_info);							// Call the funct. and print the statement
f010081d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100821:	8b 46 04             	mov    0x4(%esi),%eax
f0100824:	89 04 24             	mov    %eax,(%esp)
f0100827:	e8 b9 02 00 00       	call   f0100ae5 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", fn_info.eip_file, fn_info.eip_line, fn_info.eip_fn_namelen,
f010082c:	8b 46 04             	mov    0x4(%esi),%eax
f010082f:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100832:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100836:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100839:	89 44 24 10          	mov    %eax,0x10(%esp)
f010083d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100840:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100844:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100847:	89 44 24 08          	mov    %eax,0x8(%esp)
f010084b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010084e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100852:	c7 04 24 67 1d 10 f0 	movl   $0xf0101d67,(%esp)
f0100859:	e8 90 01 00 00       	call   f01009ee <cprintf>
												fn_info.eip_fn_name, (ebp[1] - fn_info.eip_fn_addr));
		ebp = (int *) *ebp;											// Reset the EBP to move back to the save EBP		
f010085e:	8b 36                	mov    (%esi),%esi
	while (ebp) {														// Create a while loop to loop through ebp content
f0100860:	85 f6                	test   %esi,%esi
f0100862:	0f 85 72 ff ff ff    	jne    f01007da <mon_backtrace+0x1f>
	}
	return 0;
}
f0100868:	b8 00 00 00 00       	mov    $0x0,%eax
f010086d:	83 c4 4c             	add    $0x4c,%esp
f0100870:	5b                   	pop    %ebx
f0100871:	5e                   	pop    %esi
f0100872:	5f                   	pop    %edi
f0100873:	5d                   	pop    %ebp
f0100874:	c3                   	ret    

f0100875 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100875:	55                   	push   %ebp
f0100876:	89 e5                	mov    %esp,%ebp
f0100878:	57                   	push   %edi
f0100879:	56                   	push   %esi
f010087a:	53                   	push   %ebx
f010087b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010087e:	c7 04 24 f4 1e 10 f0 	movl   $0xf0101ef4,(%esp)
f0100885:	e8 64 01 00 00       	call   f01009ee <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088a:	c7 04 24 18 1f 10 f0 	movl   $0xf0101f18,(%esp)
f0100891:	e8 58 01 00 00       	call   f01009ee <cprintf>


	while (1) {
		buf = readline("K> ");
f0100896:	c7 04 24 78 1d 10 f0 	movl   $0xf0101d78,(%esp)
f010089d:	e8 5e 0a 00 00       	call   f0101300 <readline>
f01008a2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008a4:	85 c0                	test   %eax,%eax
f01008a6:	74 ee                	je     f0100896 <monitor+0x21>
	argv[argc] = 0;
f01008a8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008af:	be 00 00 00 00       	mov    $0x0,%esi
f01008b4:	eb 0a                	jmp    f01008c0 <monitor+0x4b>
			*buf++ = 0;
f01008b6:	c6 03 00             	movb   $0x0,(%ebx)
f01008b9:	89 f7                	mov    %esi,%edi
f01008bb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008be:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01008c0:	0f b6 03             	movzbl (%ebx),%eax
f01008c3:	84 c0                	test   %al,%al
f01008c5:	74 63                	je     f010092a <monitor+0xb5>
f01008c7:	0f be c0             	movsbl %al,%eax
f01008ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ce:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f01008d5:	e8 40 0c 00 00       	call   f010151a <strchr>
f01008da:	85 c0                	test   %eax,%eax
f01008dc:	75 d8                	jne    f01008b6 <monitor+0x41>
		if (*buf == 0)
f01008de:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008e1:	74 47                	je     f010092a <monitor+0xb5>
		if (argc == MAXARGS-1) {
f01008e3:	83 fe 0f             	cmp    $0xf,%esi
f01008e6:	75 16                	jne    f01008fe <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008e8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ef:	00 
f01008f0:	c7 04 24 81 1d 10 f0 	movl   $0xf0101d81,(%esp)
f01008f7:	e8 f2 00 00 00       	call   f01009ee <cprintf>
f01008fc:	eb 98                	jmp    f0100896 <monitor+0x21>
		argv[argc++] = buf;
f01008fe:	8d 7e 01             	lea    0x1(%esi),%edi
f0100901:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100905:	eb 03                	jmp    f010090a <monitor+0x95>
			buf++;
f0100907:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f010090a:	0f b6 03             	movzbl (%ebx),%eax
f010090d:	84 c0                	test   %al,%al
f010090f:	74 ad                	je     f01008be <monitor+0x49>
f0100911:	0f be c0             	movsbl %al,%eax
f0100914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100918:	c7 04 24 7c 1d 10 f0 	movl   $0xf0101d7c,(%esp)
f010091f:	e8 f6 0b 00 00       	call   f010151a <strchr>
f0100924:	85 c0                	test   %eax,%eax
f0100926:	74 df                	je     f0100907 <monitor+0x92>
f0100928:	eb 94                	jmp    f01008be <monitor+0x49>
	argv[argc] = 0;
f010092a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100931:	00 
	if (argc == 0)
f0100932:	85 f6                	test   %esi,%esi
f0100934:	0f 84 5c ff ff ff    	je     f0100896 <monitor+0x21>
f010093a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010093f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f0100942:	8b 04 85 40 1f 10 f0 	mov    -0xfefe0c0(,%eax,4),%eax
f0100949:	89 44 24 04          	mov    %eax,0x4(%esp)
f010094d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100950:	89 04 24             	mov    %eax,(%esp)
f0100953:	e8 64 0b 00 00       	call   f01014bc <strcmp>
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 24                	jne    f0100980 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010095c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010095f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100962:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100966:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100969:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010096d:	89 34 24             	mov    %esi,(%esp)
f0100970:	ff 14 85 48 1f 10 f0 	call   *-0xfefe0b8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100977:	85 c0                	test   %eax,%eax
f0100979:	78 25                	js     f01009a0 <monitor+0x12b>
f010097b:	e9 16 ff ff ff       	jmp    f0100896 <monitor+0x21>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100980:	83 c3 01             	add    $0x1,%ebx
f0100983:	83 fb 03             	cmp    $0x3,%ebx
f0100986:	75 b7                	jne    f010093f <monitor+0xca>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100988:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010098b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010098f:	c7 04 24 9e 1d 10 f0 	movl   $0xf0101d9e,(%esp)
f0100996:	e8 53 00 00 00       	call   f01009ee <cprintf>
f010099b:	e9 f6 fe ff ff       	jmp    f0100896 <monitor+0x21>
				break;
	}
}
f01009a0:	83 c4 5c             	add    $0x5c,%esp
f01009a3:	5b                   	pop    %ebx
f01009a4:	5e                   	pop    %esi
f01009a5:	5f                   	pop    %edi
f01009a6:	5d                   	pop    %ebp
f01009a7:	c3                   	ret    

f01009a8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b1:	89 04 24             	mov    %eax,(%esp)
f01009b4:	e8 a8 fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f01009b9:	c9                   	leave  
f01009ba:	c3                   	ret    

f01009bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
f01009be:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009dd:	c7 04 24 a8 09 10 f0 	movl   $0xf01009a8,(%esp)
f01009e4:	e8 b5 04 00 00       	call   f0100e9e <vprintfmt>
	return cnt;
}
f01009e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009ec:	c9                   	leave  
f01009ed:	c3                   	ret    

f01009ee <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ee:	55                   	push   %ebp
f01009ef:	89 e5                	mov    %esp,%ebp
f01009f1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009f4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01009fe:	89 04 24             	mov    %eax,(%esp)
f0100a01:	e8 b5 ff ff ff       	call   f01009bb <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a06:	c9                   	leave  
f0100a07:	c3                   	ret    

f0100a08 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a08:	55                   	push   %ebp
f0100a09:	89 e5                	mov    %esp,%ebp
f0100a0b:	57                   	push   %edi
f0100a0c:	56                   	push   %esi
f0100a0d:	53                   	push   %ebx
f0100a0e:	83 ec 10             	sub    $0x10,%esp
f0100a11:	89 c6                	mov    %eax,%esi
f0100a13:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a16:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a19:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a1c:	8b 1a                	mov    (%edx),%ebx
f0100a1e:	8b 01                	mov    (%ecx),%eax
f0100a20:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a23:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a2a:	eb 77                	jmp    f0100aa3 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a2f:	01 d8                	add    %ebx,%eax
f0100a31:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a36:	99                   	cltd   
f0100a37:	f7 f9                	idiv   %ecx
f0100a39:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a3b:	eb 01                	jmp    f0100a3e <stab_binsearch+0x36>
			m--;
f0100a3d:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0100a3e:	39 d9                	cmp    %ebx,%ecx
f0100a40:	7c 1d                	jl     f0100a5f <stab_binsearch+0x57>
f0100a42:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a45:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a4a:	39 fa                	cmp    %edi,%edx
f0100a4c:	75 ef                	jne    f0100a3d <stab_binsearch+0x35>
f0100a4e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a51:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a54:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a58:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a5b:	73 18                	jae    f0100a75 <stab_binsearch+0x6d>
f0100a5d:	eb 05                	jmp    f0100a64 <stab_binsearch+0x5c>
			l = true_m + 1;
f0100a5f:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a62:	eb 3f                	jmp    f0100aa3 <stab_binsearch+0x9b>
			*region_left = m;
f0100a64:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a67:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a69:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0100a6c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a73:	eb 2e                	jmp    f0100aa3 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0100a75:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a78:	73 15                	jae    f0100a8f <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a7a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a7d:	48                   	dec    %eax
f0100a7e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a81:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a84:	89 01                	mov    %eax,(%ecx)
		any_matches = 1;
f0100a86:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a8d:	eb 14                	jmp    f0100aa3 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a8f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a92:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a95:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a97:	ff 45 0c             	incl   0xc(%ebp)
f0100a9a:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0100a9c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0100aa3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100aa6:	7e 84                	jle    f0100a2c <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0100aa8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100aac:	75 0d                	jne    f0100abb <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100aae:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ab1:	8b 00                	mov    (%eax),%eax
f0100ab3:	48                   	dec    %eax
f0100ab4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ab7:	89 07                	mov    %eax,(%edi)
f0100ab9:	eb 22                	jmp    f0100add <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100abb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100abe:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ac0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ac3:	8b 0b                	mov    (%ebx),%ecx
		for (l = *region_right;
f0100ac5:	eb 01                	jmp    f0100ac8 <stab_binsearch+0xc0>
		     l--)
f0100ac7:	48                   	dec    %eax
		for (l = *region_right;
f0100ac8:	39 c1                	cmp    %eax,%ecx
f0100aca:	7d 0c                	jge    f0100ad8 <stab_binsearch+0xd0>
f0100acc:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100acf:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100ad4:	39 fa                	cmp    %edi,%edx
f0100ad6:	75 ef                	jne    f0100ac7 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0100ad8:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100adb:	89 07                	mov    %eax,(%edi)
	}
}
f0100add:	83 c4 10             	add    $0x10,%esp
f0100ae0:	5b                   	pop    %ebx
f0100ae1:	5e                   	pop    %esi
f0100ae2:	5f                   	pop    %edi
f0100ae3:	5d                   	pop    %ebp
f0100ae4:	c3                   	ret    

f0100ae5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ae5:	55                   	push   %ebp
f0100ae6:	89 e5                	mov    %esp,%ebp
f0100ae8:	57                   	push   %edi
f0100ae9:	56                   	push   %esi
f0100aea:	53                   	push   %ebx
f0100aeb:	83 ec 3c             	sub    $0x3c,%esp
f0100aee:	8b 75 08             	mov    0x8(%ebp),%esi
f0100af1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100af4:	c7 03 64 1f 10 f0    	movl   $0xf0101f64,(%ebx)
	info->eip_line = 0;
f0100afa:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b01:	c7 43 08 64 1f 10 f0 	movl   $0xf0101f64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b08:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b0f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b12:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b19:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b1f:	76 12                	jbe    f0100b33 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b21:	b8 66 74 10 f0       	mov    $0xf0107466,%eax
f0100b26:	3d 51 5b 10 f0       	cmp    $0xf0105b51,%eax
f0100b2b:	0f 86 cd 01 00 00    	jbe    f0100cfe <debuginfo_eip+0x219>
f0100b31:	eb 1c                	jmp    f0100b4f <debuginfo_eip+0x6a>
  	        panic("User address");
f0100b33:	c7 44 24 08 6e 1f 10 	movl   $0xf0101f6e,0x8(%esp)
f0100b3a:	f0 
f0100b3b:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b42:	00 
f0100b43:	c7 04 24 7b 1f 10 f0 	movl   $0xf0101f7b,(%esp)
f0100b4a:	e8 a9 f5 ff ff       	call   f01000f8 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b4f:	80 3d 65 74 10 f0 00 	cmpb   $0x0,0xf0107465
f0100b56:	0f 85 a9 01 00 00    	jne    f0100d05 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b5c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b63:	b8 50 5b 10 f0       	mov    $0xf0105b50,%eax
f0100b68:	2d 9c 21 10 f0       	sub    $0xf010219c,%eax
f0100b6d:	c1 f8 02             	sar    $0x2,%eax
f0100b70:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b76:	83 e8 01             	sub    $0x1,%eax
f0100b79:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b7c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b80:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b87:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b8a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b8d:	b8 9c 21 10 f0       	mov    $0xf010219c,%eax
f0100b92:	e8 71 fe ff ff       	call   f0100a08 <stab_binsearch>
	if (lfile == 0)
f0100b97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b9a:	85 c0                	test   %eax,%eax
f0100b9c:	0f 84 6a 01 00 00    	je     f0100d0c <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ba2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ba5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bab:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100baf:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bb6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bb9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bbc:	b8 9c 21 10 f0       	mov    $0xf010219c,%eax
f0100bc1:	e8 42 fe ff ff       	call   f0100a08 <stab_binsearch>

	if (lfun <= rfun) {
f0100bc6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bc9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bcc:	39 d0                	cmp    %edx,%eax
f0100bce:	7f 3d                	jg     f0100c0d <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bd0:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bd3:	8d b9 9c 21 10 f0    	lea    -0xfefde64(%ecx),%edi
f0100bd9:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bdc:	8b 89 9c 21 10 f0    	mov    -0xfefde64(%ecx),%ecx
f0100be2:	bf 66 74 10 f0       	mov    $0xf0107466,%edi
f0100be7:	81 ef 51 5b 10 f0    	sub    $0xf0105b51,%edi
f0100bed:	39 f9                	cmp    %edi,%ecx
f0100bef:	73 09                	jae    f0100bfa <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bf1:	81 c1 51 5b 10 f0    	add    $0xf0105b51,%ecx
f0100bf7:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bfa:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bfd:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c00:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c03:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c05:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c08:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c0b:	eb 0f                	jmp    f0100c1c <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c0d:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c13:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c19:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c1c:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c23:	00 
f0100c24:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c27:	89 04 24             	mov    %eax,(%esp)
f0100c2a:	e8 0c 09 00 00       	call   f010153b <strfind>
f0100c2f:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c32:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c35:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c39:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c40:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c43:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c46:	b8 9c 21 10 f0       	mov    $0xf010219c,%eax
f0100c4b:	e8 b8 fd ff ff       	call   f0100a08 <stab_binsearch>
	if (lline <= rline) {		// If the lline stab less and equal to rline, we found the line numbers
f0100c50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c53:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c56:	0f 8f b7 00 00 00    	jg     f0100d13 <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0100c5c:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c5f:	0f b7 80 a2 21 10 f0 	movzwl -0xfefde5e(%eax),%eax
f0100c66:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c6c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c6f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c72:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c75:	81 c2 9c 21 10 f0    	add    $0xf010219c,%edx
f0100c7b:	eb 06                	jmp    f0100c83 <debuginfo_eip+0x19e>
f0100c7d:	83 e8 01             	sub    $0x1,%eax
f0100c80:	83 ea 0c             	sub    $0xc,%edx
f0100c83:	89 c6                	mov    %eax,%esi
f0100c85:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c88:	7f 33                	jg     f0100cbd <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100c8a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c8e:	80 f9 84             	cmp    $0x84,%cl
f0100c91:	74 0b                	je     f0100c9e <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c93:	80 f9 64             	cmp    $0x64,%cl
f0100c96:	75 e5                	jne    f0100c7d <debuginfo_eip+0x198>
f0100c98:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c9c:	74 df                	je     f0100c7d <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c9e:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100ca1:	8b 86 9c 21 10 f0    	mov    -0xfefde64(%esi),%eax
f0100ca7:	ba 66 74 10 f0       	mov    $0xf0107466,%edx
f0100cac:	81 ea 51 5b 10 f0    	sub    $0xf0105b51,%edx
f0100cb2:	39 d0                	cmp    %edx,%eax
f0100cb4:	73 07                	jae    f0100cbd <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cb6:	05 51 5b 10 f0       	add    $0xf0105b51,%eax
f0100cbb:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cbd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cc0:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cc3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100cc8:	39 ca                	cmp    %ecx,%edx
f0100cca:	7d 53                	jge    f0100d1f <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100ccc:	8d 42 01             	lea    0x1(%edx),%eax
f0100ccf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cd2:	89 c2                	mov    %eax,%edx
f0100cd4:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cd7:	05 9c 21 10 f0       	add    $0xf010219c,%eax
f0100cdc:	89 ce                	mov    %ecx,%esi
f0100cde:	eb 04                	jmp    f0100ce4 <debuginfo_eip+0x1ff>
			info->eip_fn_narg++;
f0100ce0:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0100ce4:	39 d6                	cmp    %edx,%esi
f0100ce6:	7e 32                	jle    f0100d1a <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ce8:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cec:	83 c2 01             	add    $0x1,%edx
f0100cef:	83 c0 0c             	add    $0xc,%eax
f0100cf2:	80 f9 a0             	cmp    $0xa0,%cl
f0100cf5:	74 e9                	je     f0100ce0 <debuginfo_eip+0x1fb>
	return 0;
f0100cf7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cfc:	eb 21                	jmp    f0100d1f <debuginfo_eip+0x23a>
		return -1;
f0100cfe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d03:	eb 1a                	jmp    f0100d1f <debuginfo_eip+0x23a>
f0100d05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d0a:	eb 13                	jmp    f0100d1f <debuginfo_eip+0x23a>
		return -1;
f0100d0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d11:	eb 0c                	jmp    f0100d1f <debuginfo_eip+0x23a>
		return -1;
f0100d13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d18:	eb 05                	jmp    f0100d1f <debuginfo_eip+0x23a>
	return 0;
f0100d1a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d1f:	83 c4 3c             	add    $0x3c,%esp
f0100d22:	5b                   	pop    %ebx
f0100d23:	5e                   	pop    %esi
f0100d24:	5f                   	pop    %edi
f0100d25:	5d                   	pop    %ebp
f0100d26:	c3                   	ret    
f0100d27:	66 90                	xchg   %ax,%ax
f0100d29:	66 90                	xchg   %ax,%ax
f0100d2b:	66 90                	xchg   %ax,%ax
f0100d2d:	66 90                	xchg   %ax,%ax
f0100d2f:	90                   	nop

f0100d30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
f0100d33:	57                   	push   %edi
f0100d34:	56                   	push   %esi
f0100d35:	53                   	push   %ebx
f0100d36:	83 ec 3c             	sub    $0x3c,%esp
f0100d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d3c:	89 d7                	mov    %edx,%edi
f0100d3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d47:	89 c3                	mov    %eax,%ebx
f0100d49:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d4c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d4f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d52:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d57:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d5a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d5d:	39 d9                	cmp    %ebx,%ecx
f0100d5f:	72 05                	jb     f0100d66 <printnum+0x36>
f0100d61:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d64:	77 69                	ja     f0100dcf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d66:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d69:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d6d:	83 ee 01             	sub    $0x1,%esi
f0100d70:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d74:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d78:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d7c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d80:	89 c3                	mov    %eax,%ebx
f0100d82:	89 d6                	mov    %edx,%esi
f0100d84:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d87:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d8a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d8e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d92:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d95:	89 04 24             	mov    %eax,(%esp)
f0100d98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d9b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d9f:	e8 bc 09 00 00       	call   f0101760 <__udivdi3>
f0100da4:	89 d9                	mov    %ebx,%ecx
f0100da6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100daa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dae:	89 04 24             	mov    %eax,(%esp)
f0100db1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100db5:	89 fa                	mov    %edi,%edx
f0100db7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dba:	e8 71 ff ff ff       	call   f0100d30 <printnum>
f0100dbf:	eb 1b                	jmp    f0100ddc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dc1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100dc8:	89 04 24             	mov    %eax,(%esp)
f0100dcb:	ff d3                	call   *%ebx
f0100dcd:	eb 03                	jmp    f0100dd2 <printnum+0xa2>
f0100dcf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f0100dd2:	83 ee 01             	sub    $0x1,%esi
f0100dd5:	85 f6                	test   %esi,%esi
f0100dd7:	7f e8                	jg     f0100dc1 <printnum+0x91>
f0100dd9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ddc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100de4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100de7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dea:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dee:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100df2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100df5:	89 04 24             	mov    %eax,(%esp)
f0100df8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dfb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dff:	e8 8c 0a 00 00       	call   f0101890 <__umoddi3>
f0100e04:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e08:	0f be 80 89 1f 10 f0 	movsbl -0xfefe077(%eax),%eax
f0100e0f:	89 04 24             	mov    %eax,(%esp)
f0100e12:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e15:	ff d0                	call   *%eax
}
f0100e17:	83 c4 3c             	add    $0x3c,%esp
f0100e1a:	5b                   	pop    %ebx
f0100e1b:	5e                   	pop    %esi
f0100e1c:	5f                   	pop    %edi
f0100e1d:	5d                   	pop    %ebp
f0100e1e:	c3                   	ret    

f0100e1f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e1f:	55                   	push   %ebp
f0100e20:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e22:	83 fa 01             	cmp    $0x1,%edx
f0100e25:	7e 0e                	jle    f0100e35 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e27:	8b 10                	mov    (%eax),%edx
f0100e29:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e2c:	89 08                	mov    %ecx,(%eax)
f0100e2e:	8b 02                	mov    (%edx),%eax
f0100e30:	8b 52 04             	mov    0x4(%edx),%edx
f0100e33:	eb 22                	jmp    f0100e57 <getuint+0x38>
	else if (lflag)
f0100e35:	85 d2                	test   %edx,%edx
f0100e37:	74 10                	je     f0100e49 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e39:	8b 10                	mov    (%eax),%edx
f0100e3b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e3e:	89 08                	mov    %ecx,(%eax)
f0100e40:	8b 02                	mov    (%edx),%eax
f0100e42:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e47:	eb 0e                	jmp    f0100e57 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e49:	8b 10                	mov    (%eax),%edx
f0100e4b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e4e:	89 08                	mov    %ecx,(%eax)
f0100e50:	8b 02                	mov    (%edx),%eax
f0100e52:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e57:	5d                   	pop    %ebp
f0100e58:	c3                   	ret    

f0100e59 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e59:	55                   	push   %ebp
f0100e5a:	89 e5                	mov    %esp,%ebp
f0100e5c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e5f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e63:	8b 10                	mov    (%eax),%edx
f0100e65:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e68:	73 0a                	jae    f0100e74 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e6a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e6d:	89 08                	mov    %ecx,(%eax)
f0100e6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e72:	88 02                	mov    %al,(%edx)
}
f0100e74:	5d                   	pop    %ebp
f0100e75:	c3                   	ret    

f0100e76 <printfmt>:
{
f0100e76:	55                   	push   %ebp
f0100e77:	89 e5                	mov    %esp,%ebp
f0100e79:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0100e7c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e83:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e86:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e8a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e8d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e91:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e94:	89 04 24             	mov    %eax,(%esp)
f0100e97:	e8 02 00 00 00       	call   f0100e9e <vprintfmt>
}
f0100e9c:	c9                   	leave  
f0100e9d:	c3                   	ret    

f0100e9e <vprintfmt>:
{
f0100e9e:	55                   	push   %ebp
f0100e9f:	89 e5                	mov    %esp,%ebp
f0100ea1:	57                   	push   %edi
f0100ea2:	56                   	push   %esi
f0100ea3:	53                   	push   %ebx
f0100ea4:	83 ec 3c             	sub    $0x3c,%esp
f0100ea7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100eaa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ead:	eb 14                	jmp    f0100ec3 <vprintfmt+0x25>
			if (ch == '\0')
f0100eaf:	85 c0                	test   %eax,%eax
f0100eb1:	0f 84 b3 03 00 00    	je     f010126a <vprintfmt+0x3cc>
			putch(ch, putdat);
f0100eb7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ebb:	89 04 24             	mov    %eax,(%esp)
f0100ebe:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ec1:	89 f3                	mov    %esi,%ebx
f0100ec3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ec6:	0f b6 03             	movzbl (%ebx),%eax
f0100ec9:	83 f8 25             	cmp    $0x25,%eax
f0100ecc:	75 e1                	jne    f0100eaf <vprintfmt+0x11>
f0100ece:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ed2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ed9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ee0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ee7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eec:	eb 1d                	jmp    f0100f0b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0100eee:	89 de                	mov    %ebx,%esi
			padc = '-';
f0100ef0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ef4:	eb 15                	jmp    f0100f0b <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f0100ef6:	89 de                	mov    %ebx,%esi
			padc = '0';
f0100ef8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100efc:	eb 0d                	jmp    f0100f0b <vprintfmt+0x6d>
				width = precision, precision = -1;
f0100efe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f01:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f04:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f0b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f0e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f11:	0f b6 c1             	movzbl %cl,%eax
f0100f14:	83 e9 23             	sub    $0x23,%ecx
f0100f17:	80 f9 55             	cmp    $0x55,%cl
f0100f1a:	0f 87 2a 03 00 00    	ja     f010124a <vprintfmt+0x3ac>
f0100f20:	0f b6 c9             	movzbl %cl,%ecx
f0100f23:	ff 24 8d 18 20 10 f0 	jmp    *-0xfefdfe8(,%ecx,4)
f0100f2a:	89 de                	mov    %ebx,%esi
f0100f2c:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f0100f31:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f34:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f38:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f3b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f3e:	83 fb 09             	cmp    $0x9,%ebx
f0100f41:	77 36                	ja     f0100f79 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0100f43:	83 c6 01             	add    $0x1,%esi
			}
f0100f46:	eb e9                	jmp    f0100f31 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0100f48:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f4e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f51:	8b 00                	mov    (%eax),%eax
f0100f53:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f56:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0100f58:	eb 22                	jmp    f0100f7c <vprintfmt+0xde>
f0100f5a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f5d:	85 c9                	test   %ecx,%ecx
f0100f5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f64:	0f 49 c1             	cmovns %ecx,%eax
f0100f67:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f6a:	89 de                	mov    %ebx,%esi
f0100f6c:	eb 9d                	jmp    f0100f0b <vprintfmt+0x6d>
f0100f6e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0100f70:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f77:	eb 92                	jmp    f0100f0b <vprintfmt+0x6d>
f0100f79:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f0100f7c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f80:	79 89                	jns    f0100f0b <vprintfmt+0x6d>
f0100f82:	e9 77 ff ff ff       	jmp    f0100efe <vprintfmt+0x60>
			lflag++;
f0100f87:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	89 de                	mov    %ebx,%esi
			goto reswitch;
f0100f8c:	e9 7a ff ff ff       	jmp    f0100f0b <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f0100f91:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f94:	8d 50 04             	lea    0x4(%eax),%edx
f0100f97:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f9a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f9e:	8b 00                	mov    (%eax),%eax
f0100fa0:	89 04 24             	mov    %eax,(%esp)
f0100fa3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fa6:	e9 18 ff ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
			err = va_arg(ap, int);
f0100fab:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fae:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fb4:	8b 00                	mov    (%eax),%eax
f0100fb6:	99                   	cltd   
f0100fb7:	31 d0                	xor    %edx,%eax
f0100fb9:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fbb:	83 f8 06             	cmp    $0x6,%eax
f0100fbe:	7f 0b                	jg     f0100fcb <vprintfmt+0x12d>
f0100fc0:	8b 14 85 70 21 10 f0 	mov    -0xfefde90(,%eax,4),%edx
f0100fc7:	85 d2                	test   %edx,%edx
f0100fc9:	75 20                	jne    f0100feb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100fcb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fcf:	c7 44 24 08 a1 1f 10 	movl   $0xf0101fa1,0x8(%esp)
f0100fd6:	f0 
f0100fd7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fde:	89 04 24             	mov    %eax,(%esp)
f0100fe1:	e8 90 fe ff ff       	call   f0100e76 <printfmt>
f0100fe6:	e9 d8 fe ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0100feb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fef:	c7 44 24 08 aa 1f 10 	movl   $0xf0101faa,0x8(%esp)
f0100ff6:	f0 
f0100ff7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ffb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ffe:	89 04 24             	mov    %eax,(%esp)
f0101001:	e8 70 fe ff ff       	call   f0100e76 <printfmt>
f0101006:	e9 b8 fe ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f010100b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010100e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101011:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0101014:	8b 45 14             	mov    0x14(%ebp),%eax
f0101017:	8d 50 04             	lea    0x4(%eax),%edx
f010101a:	89 55 14             	mov    %edx,0x14(%ebp)
f010101d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010101f:	85 f6                	test   %esi,%esi
f0101021:	b8 9a 1f 10 f0       	mov    $0xf0101f9a,%eax
f0101026:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101029:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010102d:	0f 84 97 00 00 00    	je     f01010ca <vprintfmt+0x22c>
f0101033:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101037:	0f 8e 9b 00 00 00    	jle    f01010d8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010103d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101041:	89 34 24             	mov    %esi,(%esp)
f0101044:	e8 9f 03 00 00       	call   f01013e8 <strnlen>
f0101049:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010104c:	29 c2                	sub    %eax,%edx
f010104e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101051:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101055:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101058:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010105b:	8b 75 08             	mov    0x8(%ebp),%esi
f010105e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101061:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0101063:	eb 0f                	jmp    f0101074 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101065:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101069:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010106c:	89 04 24             	mov    %eax,(%esp)
f010106f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101071:	83 eb 01             	sub    $0x1,%ebx
f0101074:	85 db                	test   %ebx,%ebx
f0101076:	7f ed                	jg     f0101065 <vprintfmt+0x1c7>
f0101078:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010107b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010107e:	85 d2                	test   %edx,%edx
f0101080:	b8 00 00 00 00       	mov    $0x0,%eax
f0101085:	0f 49 c2             	cmovns %edx,%eax
f0101088:	29 c2                	sub    %eax,%edx
f010108a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010108d:	89 d7                	mov    %edx,%edi
f010108f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101092:	eb 50                	jmp    f01010e4 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f0101094:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101098:	74 1e                	je     f01010b8 <vprintfmt+0x21a>
f010109a:	0f be d2             	movsbl %dl,%edx
f010109d:	83 ea 20             	sub    $0x20,%edx
f01010a0:	83 fa 5e             	cmp    $0x5e,%edx
f01010a3:	76 13                	jbe    f01010b8 <vprintfmt+0x21a>
					putch('?', putdat);
f01010a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010ac:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010b3:	ff 55 08             	call   *0x8(%ebp)
f01010b6:	eb 0d                	jmp    f01010c5 <vprintfmt+0x227>
					putch(ch, putdat);
f01010b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010bb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010bf:	89 04 24             	mov    %eax,(%esp)
f01010c2:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010c5:	83 ef 01             	sub    $0x1,%edi
f01010c8:	eb 1a                	jmp    f01010e4 <vprintfmt+0x246>
f01010ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010cd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010d0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010d6:	eb 0c                	jmp    f01010e4 <vprintfmt+0x246>
f01010d8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010db:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010de:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010e4:	83 c6 01             	add    $0x1,%esi
f01010e7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010eb:	0f be c2             	movsbl %dl,%eax
f01010ee:	85 c0                	test   %eax,%eax
f01010f0:	74 27                	je     f0101119 <vprintfmt+0x27b>
f01010f2:	85 db                	test   %ebx,%ebx
f01010f4:	78 9e                	js     f0101094 <vprintfmt+0x1f6>
f01010f6:	83 eb 01             	sub    $0x1,%ebx
f01010f9:	79 99                	jns    f0101094 <vprintfmt+0x1f6>
f01010fb:	89 f8                	mov    %edi,%eax
f01010fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101100:	8b 75 08             	mov    0x8(%ebp),%esi
f0101103:	89 c3                	mov    %eax,%ebx
f0101105:	eb 1a                	jmp    f0101121 <vprintfmt+0x283>
				putch(' ', putdat);
f0101107:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010110b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101112:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101114:	83 eb 01             	sub    $0x1,%ebx
f0101117:	eb 08                	jmp    f0101121 <vprintfmt+0x283>
f0101119:	89 fb                	mov    %edi,%ebx
f010111b:	8b 75 08             	mov    0x8(%ebp),%esi
f010111e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101121:	85 db                	test   %ebx,%ebx
f0101123:	7f e2                	jg     f0101107 <vprintfmt+0x269>
f0101125:	89 75 08             	mov    %esi,0x8(%ebp)
f0101128:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010112b:	e9 93 fd ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
	if (lflag >= 2)
f0101130:	83 fa 01             	cmp    $0x1,%edx
f0101133:	7e 16                	jle    f010114b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101135:	8b 45 14             	mov    0x14(%ebp),%eax
f0101138:	8d 50 08             	lea    0x8(%eax),%edx
f010113b:	89 55 14             	mov    %edx,0x14(%ebp)
f010113e:	8b 50 04             	mov    0x4(%eax),%edx
f0101141:	8b 00                	mov    (%eax),%eax
f0101143:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101146:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101149:	eb 32                	jmp    f010117d <vprintfmt+0x2df>
	else if (lflag)
f010114b:	85 d2                	test   %edx,%edx
f010114d:	74 18                	je     f0101167 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010114f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101152:	8d 50 04             	lea    0x4(%eax),%edx
f0101155:	89 55 14             	mov    %edx,0x14(%ebp)
f0101158:	8b 30                	mov    (%eax),%esi
f010115a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010115d:	89 f0                	mov    %esi,%eax
f010115f:	c1 f8 1f             	sar    $0x1f,%eax
f0101162:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101165:	eb 16                	jmp    f010117d <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0101167:	8b 45 14             	mov    0x14(%ebp),%eax
f010116a:	8d 50 04             	lea    0x4(%eax),%edx
f010116d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101170:	8b 30                	mov    (%eax),%esi
f0101172:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101175:	89 f0                	mov    %esi,%eax
f0101177:	c1 f8 1f             	sar    $0x1f,%eax
f010117a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f010117d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101180:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0101183:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0101188:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010118c:	0f 89 80 00 00 00    	jns    f0101212 <vprintfmt+0x374>
				putch('-', putdat);
f0101192:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101196:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010119d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011a3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011a6:	f7 d8                	neg    %eax
f01011a8:	83 d2 00             	adc    $0x0,%edx
f01011ab:	f7 da                	neg    %edx
			base = 10;
f01011ad:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011b2:	eb 5e                	jmp    f0101212 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01011b4:	8d 45 14             	lea    0x14(%ebp),%eax
f01011b7:	e8 63 fc ff ff       	call   f0100e1f <getuint>
			base = 10;
f01011bc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011c1:	eb 4f                	jmp    f0101212 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01011c3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011c6:	e8 54 fc ff ff       	call   f0100e1f <getuint>
			base = 8;
f01011cb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011d0:	eb 40                	jmp    f0101212 <vprintfmt+0x374>
			putch('0', putdat);
f01011d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011dd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011e0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011e4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011eb:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f01011ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f1:	8d 50 04             	lea    0x4(%eax),%edx
f01011f4:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01011f7:	8b 00                	mov    (%eax),%eax
f01011f9:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01011fe:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101203:	eb 0d                	jmp    f0101212 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0101205:	8d 45 14             	lea    0x14(%ebp),%eax
f0101208:	e8 12 fc ff ff       	call   f0100e1f <getuint>
			base = 16;
f010120d:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0101212:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101216:	89 74 24 10          	mov    %esi,0x10(%esp)
f010121a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010121d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101221:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101225:	89 04 24             	mov    %eax,(%esp)
f0101228:	89 54 24 04          	mov    %edx,0x4(%esp)
f010122c:	89 fa                	mov    %edi,%edx
f010122e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101231:	e8 fa fa ff ff       	call   f0100d30 <printnum>
			break;
f0101236:	e9 88 fc ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
			putch(ch, putdat);
f010123b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010123f:	89 04 24             	mov    %eax,(%esp)
f0101242:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101245:	e9 79 fc ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
			putch('%', putdat);
f010124a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010124e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101255:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101258:	89 f3                	mov    %esi,%ebx
f010125a:	eb 03                	jmp    f010125f <vprintfmt+0x3c1>
f010125c:	83 eb 01             	sub    $0x1,%ebx
f010125f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101263:	75 f7                	jne    f010125c <vprintfmt+0x3be>
f0101265:	e9 59 fc ff ff       	jmp    f0100ec3 <vprintfmt+0x25>
}
f010126a:	83 c4 3c             	add    $0x3c,%esp
f010126d:	5b                   	pop    %ebx
f010126e:	5e                   	pop    %esi
f010126f:	5f                   	pop    %edi
f0101270:	5d                   	pop    %ebp
f0101271:	c3                   	ret    

f0101272 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101272:	55                   	push   %ebp
f0101273:	89 e5                	mov    %esp,%ebp
f0101275:	83 ec 28             	sub    $0x28,%esp
f0101278:	8b 45 08             	mov    0x8(%ebp),%eax
f010127b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010127e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101281:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101285:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101288:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010128f:	85 c0                	test   %eax,%eax
f0101291:	74 30                	je     f01012c3 <vsnprintf+0x51>
f0101293:	85 d2                	test   %edx,%edx
f0101295:	7e 2c                	jle    f01012c3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101297:	8b 45 14             	mov    0x14(%ebp),%eax
f010129a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010129e:	8b 45 10             	mov    0x10(%ebp),%eax
f01012a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012a5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012ac:	c7 04 24 59 0e 10 f0 	movl   $0xf0100e59,(%esp)
f01012b3:	e8 e6 fb ff ff       	call   f0100e9e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012bb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012be:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012c1:	eb 05                	jmp    f01012c8 <vsnprintf+0x56>
		return -E_INVAL;
f01012c3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01012c8:	c9                   	leave  
f01012c9:	c3                   	ret    

f01012ca <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012ca:	55                   	push   %ebp
f01012cb:	89 e5                	mov    %esp,%ebp
f01012cd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012d0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012d7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e8:	89 04 24             	mov    %eax,(%esp)
f01012eb:	e8 82 ff ff ff       	call   f0101272 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012f0:	c9                   	leave  
f01012f1:	c3                   	ret    
f01012f2:	66 90                	xchg   %ax,%ax
f01012f4:	66 90                	xchg   %ax,%ax
f01012f6:	66 90                	xchg   %ax,%ax
f01012f8:	66 90                	xchg   %ax,%ax
f01012fa:	66 90                	xchg   %ax,%ax
f01012fc:	66 90                	xchg   %ax,%ax
f01012fe:	66 90                	xchg   %ax,%ax

f0101300 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101300:	55                   	push   %ebp
f0101301:	89 e5                	mov    %esp,%ebp
f0101303:	57                   	push   %edi
f0101304:	56                   	push   %esi
f0101305:	53                   	push   %ebx
f0101306:	83 ec 1c             	sub    $0x1c,%esp
f0101309:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010130c:	85 c0                	test   %eax,%eax
f010130e:	74 10                	je     f0101320 <readline+0x20>
		cprintf("%s", prompt);
f0101310:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101314:	c7 04 24 aa 1f 10 f0 	movl   $0xf0101faa,(%esp)
f010131b:	e8 ce f6 ff ff       	call   f01009ee <cprintf>

	i = 0;
	echoing = iscons(0);
f0101320:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101327:	e8 56 f3 ff ff       	call   f0100682 <iscons>
f010132c:	89 c7                	mov    %eax,%edi
	i = 0;
f010132e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101333:	e8 39 f3 ff ff       	call   f0100671 <getchar>
f0101338:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010133a:	85 c0                	test   %eax,%eax
f010133c:	79 17                	jns    f0101355 <readline+0x55>
			cprintf("read error: %e\n", c);
f010133e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101342:	c7 04 24 8c 21 10 f0 	movl   $0xf010218c,(%esp)
f0101349:	e8 a0 f6 ff ff       	call   f01009ee <cprintf>
			return NULL;
f010134e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101353:	eb 6d                	jmp    f01013c2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101355:	83 f8 7f             	cmp    $0x7f,%eax
f0101358:	74 05                	je     f010135f <readline+0x5f>
f010135a:	83 f8 08             	cmp    $0x8,%eax
f010135d:	75 19                	jne    f0101378 <readline+0x78>
f010135f:	85 f6                	test   %esi,%esi
f0101361:	7e 15                	jle    f0101378 <readline+0x78>
			if (echoing)
f0101363:	85 ff                	test   %edi,%edi
f0101365:	74 0c                	je     f0101373 <readline+0x73>
				cputchar('\b');
f0101367:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010136e:	e8 ee f2 ff ff       	call   f0100661 <cputchar>
			i--;
f0101373:	83 ee 01             	sub    $0x1,%esi
f0101376:	eb bb                	jmp    f0101333 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101378:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010137e:	7f 1c                	jg     f010139c <readline+0x9c>
f0101380:	83 fb 1f             	cmp    $0x1f,%ebx
f0101383:	7e 17                	jle    f010139c <readline+0x9c>
			if (echoing)
f0101385:	85 ff                	test   %edi,%edi
f0101387:	74 08                	je     f0101391 <readline+0x91>
				cputchar(c);
f0101389:	89 1c 24             	mov    %ebx,(%esp)
f010138c:	e8 d0 f2 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101391:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101397:	8d 76 01             	lea    0x1(%esi),%esi
f010139a:	eb 97                	jmp    f0101333 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010139c:	83 fb 0d             	cmp    $0xd,%ebx
f010139f:	74 05                	je     f01013a6 <readline+0xa6>
f01013a1:	83 fb 0a             	cmp    $0xa,%ebx
f01013a4:	75 8d                	jne    f0101333 <readline+0x33>
			if (echoing)
f01013a6:	85 ff                	test   %edi,%edi
f01013a8:	74 0c                	je     f01013b6 <readline+0xb6>
				cputchar('\n');
f01013aa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013b1:	e8 ab f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01013b6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013bd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013c2:	83 c4 1c             	add    $0x1c,%esp
f01013c5:	5b                   	pop    %ebx
f01013c6:	5e                   	pop    %esi
f01013c7:	5f                   	pop    %edi
f01013c8:	5d                   	pop    %ebp
f01013c9:	c3                   	ret    
f01013ca:	66 90                	xchg   %ax,%ax
f01013cc:	66 90                	xchg   %ax,%ax
f01013ce:	66 90                	xchg   %ax,%ax

f01013d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013db:	eb 03                	jmp    f01013e0 <strlen+0x10>
		n++;
f01013dd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01013e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013e4:	75 f7                	jne    f01013dd <strlen+0xd>
	return n;
}
f01013e6:	5d                   	pop    %ebp
f01013e7:	c3                   	ret    

f01013e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013e8:	55                   	push   %ebp
f01013e9:	89 e5                	mov    %esp,%ebp
f01013eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ee:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f6:	eb 03                	jmp    f01013fb <strnlen+0x13>
		n++;
f01013f8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013fb:	39 d0                	cmp    %edx,%eax
f01013fd:	74 06                	je     f0101405 <strnlen+0x1d>
f01013ff:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101403:	75 f3                	jne    f01013f8 <strnlen+0x10>
	return n;
}
f0101405:	5d                   	pop    %ebp
f0101406:	c3                   	ret    

f0101407 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	53                   	push   %ebx
f010140b:	8b 45 08             	mov    0x8(%ebp),%eax
f010140e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101411:	89 c2                	mov    %eax,%edx
f0101413:	83 c2 01             	add    $0x1,%edx
f0101416:	83 c1 01             	add    $0x1,%ecx
f0101419:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010141d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101420:	84 db                	test   %bl,%bl
f0101422:	75 ef                	jne    f0101413 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101424:	5b                   	pop    %ebx
f0101425:	5d                   	pop    %ebp
f0101426:	c3                   	ret    

f0101427 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101427:	55                   	push   %ebp
f0101428:	89 e5                	mov    %esp,%ebp
f010142a:	53                   	push   %ebx
f010142b:	83 ec 08             	sub    $0x8,%esp
f010142e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101431:	89 1c 24             	mov    %ebx,(%esp)
f0101434:	e8 97 ff ff ff       	call   f01013d0 <strlen>
	strcpy(dst + len, src);
f0101439:	8b 55 0c             	mov    0xc(%ebp),%edx
f010143c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101440:	01 d8                	add    %ebx,%eax
f0101442:	89 04 24             	mov    %eax,(%esp)
f0101445:	e8 bd ff ff ff       	call   f0101407 <strcpy>
	return dst;
}
f010144a:	89 d8                	mov    %ebx,%eax
f010144c:	83 c4 08             	add    $0x8,%esp
f010144f:	5b                   	pop    %ebx
f0101450:	5d                   	pop    %ebp
f0101451:	c3                   	ret    

f0101452 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101452:	55                   	push   %ebp
f0101453:	89 e5                	mov    %esp,%ebp
f0101455:	56                   	push   %esi
f0101456:	53                   	push   %ebx
f0101457:	8b 75 08             	mov    0x8(%ebp),%esi
f010145a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010145d:	89 f3                	mov    %esi,%ebx
f010145f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101462:	89 f2                	mov    %esi,%edx
f0101464:	eb 0f                	jmp    f0101475 <strncpy+0x23>
		*dst++ = *src;
f0101466:	83 c2 01             	add    $0x1,%edx
f0101469:	0f b6 01             	movzbl (%ecx),%eax
f010146c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010146f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101472:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101475:	39 da                	cmp    %ebx,%edx
f0101477:	75 ed                	jne    f0101466 <strncpy+0x14>
	}
	return ret;
}
f0101479:	89 f0                	mov    %esi,%eax
f010147b:	5b                   	pop    %ebx
f010147c:	5e                   	pop    %esi
f010147d:	5d                   	pop    %ebp
f010147e:	c3                   	ret    

f010147f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010147f:	55                   	push   %ebp
f0101480:	89 e5                	mov    %esp,%ebp
f0101482:	56                   	push   %esi
f0101483:	53                   	push   %ebx
f0101484:	8b 75 08             	mov    0x8(%ebp),%esi
f0101487:	8b 55 0c             	mov    0xc(%ebp),%edx
f010148a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010148d:	89 f0                	mov    %esi,%eax
f010148f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101493:	85 c9                	test   %ecx,%ecx
f0101495:	75 0b                	jne    f01014a2 <strlcpy+0x23>
f0101497:	eb 1d                	jmp    f01014b6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101499:	83 c0 01             	add    $0x1,%eax
f010149c:	83 c2 01             	add    $0x1,%edx
f010149f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01014a2:	39 d8                	cmp    %ebx,%eax
f01014a4:	74 0b                	je     f01014b1 <strlcpy+0x32>
f01014a6:	0f b6 0a             	movzbl (%edx),%ecx
f01014a9:	84 c9                	test   %cl,%cl
f01014ab:	75 ec                	jne    f0101499 <strlcpy+0x1a>
f01014ad:	89 c2                	mov    %eax,%edx
f01014af:	eb 02                	jmp    f01014b3 <strlcpy+0x34>
f01014b1:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f01014b3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01014b6:	29 f0                	sub    %esi,%eax
}
f01014b8:	5b                   	pop    %ebx
f01014b9:	5e                   	pop    %esi
f01014ba:	5d                   	pop    %ebp
f01014bb:	c3                   	ret    

f01014bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014bc:	55                   	push   %ebp
f01014bd:	89 e5                	mov    %esp,%ebp
f01014bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014c2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014c5:	eb 06                	jmp    f01014cd <strcmp+0x11>
		p++, q++;
f01014c7:	83 c1 01             	add    $0x1,%ecx
f01014ca:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01014cd:	0f b6 01             	movzbl (%ecx),%eax
f01014d0:	84 c0                	test   %al,%al
f01014d2:	74 04                	je     f01014d8 <strcmp+0x1c>
f01014d4:	3a 02                	cmp    (%edx),%al
f01014d6:	74 ef                	je     f01014c7 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d8:	0f b6 c0             	movzbl %al,%eax
f01014db:	0f b6 12             	movzbl (%edx),%edx
f01014de:	29 d0                	sub    %edx,%eax
}
f01014e0:	5d                   	pop    %ebp
f01014e1:	c3                   	ret    

f01014e2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014e2:	55                   	push   %ebp
f01014e3:	89 e5                	mov    %esp,%ebp
f01014e5:	53                   	push   %ebx
f01014e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ec:	89 c3                	mov    %eax,%ebx
f01014ee:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014f1:	eb 06                	jmp    f01014f9 <strncmp+0x17>
		n--, p++, q++;
f01014f3:	83 c0 01             	add    $0x1,%eax
f01014f6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01014f9:	39 d8                	cmp    %ebx,%eax
f01014fb:	74 15                	je     f0101512 <strncmp+0x30>
f01014fd:	0f b6 08             	movzbl (%eax),%ecx
f0101500:	84 c9                	test   %cl,%cl
f0101502:	74 04                	je     f0101508 <strncmp+0x26>
f0101504:	3a 0a                	cmp    (%edx),%cl
f0101506:	74 eb                	je     f01014f3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101508:	0f b6 00             	movzbl (%eax),%eax
f010150b:	0f b6 12             	movzbl (%edx),%edx
f010150e:	29 d0                	sub    %edx,%eax
f0101510:	eb 05                	jmp    f0101517 <strncmp+0x35>
		return 0;
f0101512:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101517:	5b                   	pop    %ebx
f0101518:	5d                   	pop    %ebp
f0101519:	c3                   	ret    

f010151a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010151a:	55                   	push   %ebp
f010151b:	89 e5                	mov    %esp,%ebp
f010151d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101520:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101524:	eb 07                	jmp    f010152d <strchr+0x13>
		if (*s == c)
f0101526:	38 ca                	cmp    %cl,%dl
f0101528:	74 0f                	je     f0101539 <strchr+0x1f>
	for (; *s; s++)
f010152a:	83 c0 01             	add    $0x1,%eax
f010152d:	0f b6 10             	movzbl (%eax),%edx
f0101530:	84 d2                	test   %dl,%dl
f0101532:	75 f2                	jne    f0101526 <strchr+0xc>
			return (char *) s;
	return 0;
f0101534:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101539:	5d                   	pop    %ebp
f010153a:	c3                   	ret    

f010153b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010153b:	55                   	push   %ebp
f010153c:	89 e5                	mov    %esp,%ebp
f010153e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101541:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101545:	eb 07                	jmp    f010154e <strfind+0x13>
		if (*s == c)
f0101547:	38 ca                	cmp    %cl,%dl
f0101549:	74 0a                	je     f0101555 <strfind+0x1a>
	for (; *s; s++)
f010154b:	83 c0 01             	add    $0x1,%eax
f010154e:	0f b6 10             	movzbl (%eax),%edx
f0101551:	84 d2                	test   %dl,%dl
f0101553:	75 f2                	jne    f0101547 <strfind+0xc>
			break;
	return (char *) s;
}
f0101555:	5d                   	pop    %ebp
f0101556:	c3                   	ret    

f0101557 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101557:	55                   	push   %ebp
f0101558:	89 e5                	mov    %esp,%ebp
f010155a:	57                   	push   %edi
f010155b:	56                   	push   %esi
f010155c:	53                   	push   %ebx
f010155d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101560:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101563:	85 c9                	test   %ecx,%ecx
f0101565:	74 36                	je     f010159d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101567:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010156d:	75 28                	jne    f0101597 <memset+0x40>
f010156f:	f6 c1 03             	test   $0x3,%cl
f0101572:	75 23                	jne    f0101597 <memset+0x40>
		c &= 0xFF;
f0101574:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101578:	89 d3                	mov    %edx,%ebx
f010157a:	c1 e3 08             	shl    $0x8,%ebx
f010157d:	89 d6                	mov    %edx,%esi
f010157f:	c1 e6 18             	shl    $0x18,%esi
f0101582:	89 d0                	mov    %edx,%eax
f0101584:	c1 e0 10             	shl    $0x10,%eax
f0101587:	09 f0                	or     %esi,%eax
f0101589:	09 c2                	or     %eax,%edx
f010158b:	89 d0                	mov    %edx,%eax
f010158d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010158f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101592:	fc                   	cld    
f0101593:	f3 ab                	rep stos %eax,%es:(%edi)
f0101595:	eb 06                	jmp    f010159d <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101597:	8b 45 0c             	mov    0xc(%ebp),%eax
f010159a:	fc                   	cld    
f010159b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010159d:	89 f8                	mov    %edi,%eax
f010159f:	5b                   	pop    %ebx
f01015a0:	5e                   	pop    %esi
f01015a1:	5f                   	pop    %edi
f01015a2:	5d                   	pop    %ebp
f01015a3:	c3                   	ret    

f01015a4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015a4:	55                   	push   %ebp
f01015a5:	89 e5                	mov    %esp,%ebp
f01015a7:	57                   	push   %edi
f01015a8:	56                   	push   %esi
f01015a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015af:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015b2:	39 c6                	cmp    %eax,%esi
f01015b4:	73 35                	jae    f01015eb <memmove+0x47>
f01015b6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015b9:	39 d0                	cmp    %edx,%eax
f01015bb:	73 2e                	jae    f01015eb <memmove+0x47>
		s += n;
		d += n;
f01015bd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015c0:	89 d6                	mov    %edx,%esi
f01015c2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015c4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015ca:	75 13                	jne    f01015df <memmove+0x3b>
f01015cc:	f6 c1 03             	test   $0x3,%cl
f01015cf:	75 0e                	jne    f01015df <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015d1:	83 ef 04             	sub    $0x4,%edi
f01015d4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015d7:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01015da:	fd                   	std    
f01015db:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015dd:	eb 09                	jmp    f01015e8 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015df:	83 ef 01             	sub    $0x1,%edi
f01015e2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01015e5:	fd                   	std    
f01015e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015e8:	fc                   	cld    
f01015e9:	eb 1d                	jmp    f0101608 <memmove+0x64>
f01015eb:	89 f2                	mov    %esi,%edx
f01015ed:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015ef:	f6 c2 03             	test   $0x3,%dl
f01015f2:	75 0f                	jne    f0101603 <memmove+0x5f>
f01015f4:	f6 c1 03             	test   $0x3,%cl
f01015f7:	75 0a                	jne    f0101603 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015f9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01015fc:	89 c7                	mov    %eax,%edi
f01015fe:	fc                   	cld    
f01015ff:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101601:	eb 05                	jmp    f0101608 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f0101603:	89 c7                	mov    %eax,%edi
f0101605:	fc                   	cld    
f0101606:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101608:	5e                   	pop    %esi
f0101609:	5f                   	pop    %edi
f010160a:	5d                   	pop    %ebp
f010160b:	c3                   	ret    

f010160c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010160c:	55                   	push   %ebp
f010160d:	89 e5                	mov    %esp,%ebp
f010160f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101612:	8b 45 10             	mov    0x10(%ebp),%eax
f0101615:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101619:	8b 45 0c             	mov    0xc(%ebp),%eax
f010161c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101620:	8b 45 08             	mov    0x8(%ebp),%eax
f0101623:	89 04 24             	mov    %eax,(%esp)
f0101626:	e8 79 ff ff ff       	call   f01015a4 <memmove>
}
f010162b:	c9                   	leave  
f010162c:	c3                   	ret    

f010162d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010162d:	55                   	push   %ebp
f010162e:	89 e5                	mov    %esp,%ebp
f0101630:	56                   	push   %esi
f0101631:	53                   	push   %ebx
f0101632:	8b 55 08             	mov    0x8(%ebp),%edx
f0101635:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101638:	89 d6                	mov    %edx,%esi
f010163a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010163d:	eb 1a                	jmp    f0101659 <memcmp+0x2c>
		if (*s1 != *s2)
f010163f:	0f b6 02             	movzbl (%edx),%eax
f0101642:	0f b6 19             	movzbl (%ecx),%ebx
f0101645:	38 d8                	cmp    %bl,%al
f0101647:	74 0a                	je     f0101653 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101649:	0f b6 c0             	movzbl %al,%eax
f010164c:	0f b6 db             	movzbl %bl,%ebx
f010164f:	29 d8                	sub    %ebx,%eax
f0101651:	eb 0f                	jmp    f0101662 <memcmp+0x35>
		s1++, s2++;
f0101653:	83 c2 01             	add    $0x1,%edx
f0101656:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0101659:	39 f2                	cmp    %esi,%edx
f010165b:	75 e2                	jne    f010163f <memcmp+0x12>
	}

	return 0;
f010165d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101662:	5b                   	pop    %ebx
f0101663:	5e                   	pop    %esi
f0101664:	5d                   	pop    %ebp
f0101665:	c3                   	ret    

f0101666 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101666:	55                   	push   %ebp
f0101667:	89 e5                	mov    %esp,%ebp
f0101669:	8b 45 08             	mov    0x8(%ebp),%eax
f010166c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010166f:	89 c2                	mov    %eax,%edx
f0101671:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101674:	eb 07                	jmp    f010167d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101676:	38 08                	cmp    %cl,(%eax)
f0101678:	74 07                	je     f0101681 <memfind+0x1b>
	for (; s < ends; s++)
f010167a:	83 c0 01             	add    $0x1,%eax
f010167d:	39 d0                	cmp    %edx,%eax
f010167f:	72 f5                	jb     f0101676 <memfind+0x10>
			break;
	return (void *) s;
}
f0101681:	5d                   	pop    %ebp
f0101682:	c3                   	ret    

f0101683 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101683:	55                   	push   %ebp
f0101684:	89 e5                	mov    %esp,%ebp
f0101686:	57                   	push   %edi
f0101687:	56                   	push   %esi
f0101688:	53                   	push   %ebx
f0101689:	8b 55 08             	mov    0x8(%ebp),%edx
f010168c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010168f:	eb 03                	jmp    f0101694 <strtol+0x11>
		s++;
f0101691:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101694:	0f b6 0a             	movzbl (%edx),%ecx
f0101697:	80 f9 09             	cmp    $0x9,%cl
f010169a:	74 f5                	je     f0101691 <strtol+0xe>
f010169c:	80 f9 20             	cmp    $0x20,%cl
f010169f:	74 f0                	je     f0101691 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01016a1:	80 f9 2b             	cmp    $0x2b,%cl
f01016a4:	75 0a                	jne    f01016b0 <strtol+0x2d>
		s++;
f01016a6:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f01016a9:	bf 00 00 00 00       	mov    $0x0,%edi
f01016ae:	eb 11                	jmp    f01016c1 <strtol+0x3e>
f01016b0:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f01016b5:	80 f9 2d             	cmp    $0x2d,%cl
f01016b8:	75 07                	jne    f01016c1 <strtol+0x3e>
		s++, neg = 1;
f01016ba:	8d 52 01             	lea    0x1(%edx),%edx
f01016bd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016c1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016c6:	75 15                	jne    f01016dd <strtol+0x5a>
f01016c8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016cb:	75 10                	jne    f01016dd <strtol+0x5a>
f01016cd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016d1:	75 0a                	jne    f01016dd <strtol+0x5a>
		s += 2, base = 16;
f01016d3:	83 c2 02             	add    $0x2,%edx
f01016d6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016db:	eb 10                	jmp    f01016ed <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016dd:	85 c0                	test   %eax,%eax
f01016df:	75 0c                	jne    f01016ed <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016e1:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f01016e3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016e6:	75 05                	jne    f01016ed <strtol+0x6a>
		s++, base = 8;
f01016e8:	83 c2 01             	add    $0x1,%edx
f01016eb:	b0 08                	mov    $0x8,%al
		base = 10;
f01016ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016f2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016f5:	0f b6 0a             	movzbl (%edx),%ecx
f01016f8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016fb:	89 f0                	mov    %esi,%eax
f01016fd:	3c 09                	cmp    $0x9,%al
f01016ff:	77 08                	ja     f0101709 <strtol+0x86>
			dig = *s - '0';
f0101701:	0f be c9             	movsbl %cl,%ecx
f0101704:	83 e9 30             	sub    $0x30,%ecx
f0101707:	eb 20                	jmp    f0101729 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101709:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010170c:	89 f0                	mov    %esi,%eax
f010170e:	3c 19                	cmp    $0x19,%al
f0101710:	77 08                	ja     f010171a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101712:	0f be c9             	movsbl %cl,%ecx
f0101715:	83 e9 57             	sub    $0x57,%ecx
f0101718:	eb 0f                	jmp    f0101729 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010171a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010171d:	89 f0                	mov    %esi,%eax
f010171f:	3c 19                	cmp    $0x19,%al
f0101721:	77 16                	ja     f0101739 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101723:	0f be c9             	movsbl %cl,%ecx
f0101726:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101729:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010172c:	7d 0f                	jge    f010173d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010172e:	83 c2 01             	add    $0x1,%edx
f0101731:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101735:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101737:	eb bc                	jmp    f01016f5 <strtol+0x72>
f0101739:	89 d8                	mov    %ebx,%eax
f010173b:	eb 02                	jmp    f010173f <strtol+0xbc>
f010173d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010173f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101743:	74 05                	je     f010174a <strtol+0xc7>
		*endptr = (char *) s;
f0101745:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101748:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010174a:	f7 d8                	neg    %eax
f010174c:	85 ff                	test   %edi,%edi
f010174e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101751:	5b                   	pop    %ebx
f0101752:	5e                   	pop    %esi
f0101753:	5f                   	pop    %edi
f0101754:	5d                   	pop    %ebp
f0101755:	c3                   	ret    
f0101756:	66 90                	xchg   %ax,%ax
f0101758:	66 90                	xchg   %ax,%ax
f010175a:	66 90                	xchg   %ax,%ax
f010175c:	66 90                	xchg   %ax,%ax
f010175e:	66 90                	xchg   %ax,%ax

f0101760 <__udivdi3>:
f0101760:	55                   	push   %ebp
f0101761:	57                   	push   %edi
f0101762:	56                   	push   %esi
f0101763:	83 ec 0c             	sub    $0xc,%esp
f0101766:	8b 44 24 28          	mov    0x28(%esp),%eax
f010176a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010176e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101772:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101776:	85 c0                	test   %eax,%eax
f0101778:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010177c:	89 ea                	mov    %ebp,%edx
f010177e:	89 0c 24             	mov    %ecx,(%esp)
f0101781:	75 2d                	jne    f01017b0 <__udivdi3+0x50>
f0101783:	39 e9                	cmp    %ebp,%ecx
f0101785:	77 61                	ja     f01017e8 <__udivdi3+0x88>
f0101787:	85 c9                	test   %ecx,%ecx
f0101789:	89 ce                	mov    %ecx,%esi
f010178b:	75 0b                	jne    f0101798 <__udivdi3+0x38>
f010178d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101792:	31 d2                	xor    %edx,%edx
f0101794:	f7 f1                	div    %ecx
f0101796:	89 c6                	mov    %eax,%esi
f0101798:	31 d2                	xor    %edx,%edx
f010179a:	89 e8                	mov    %ebp,%eax
f010179c:	f7 f6                	div    %esi
f010179e:	89 c5                	mov    %eax,%ebp
f01017a0:	89 f8                	mov    %edi,%eax
f01017a2:	f7 f6                	div    %esi
f01017a4:	89 ea                	mov    %ebp,%edx
f01017a6:	83 c4 0c             	add    $0xc,%esp
f01017a9:	5e                   	pop    %esi
f01017aa:	5f                   	pop    %edi
f01017ab:	5d                   	pop    %ebp
f01017ac:	c3                   	ret    
f01017ad:	8d 76 00             	lea    0x0(%esi),%esi
f01017b0:	39 e8                	cmp    %ebp,%eax
f01017b2:	77 24                	ja     f01017d8 <__udivdi3+0x78>
f01017b4:	0f bd e8             	bsr    %eax,%ebp
f01017b7:	83 f5 1f             	xor    $0x1f,%ebp
f01017ba:	75 3c                	jne    f01017f8 <__udivdi3+0x98>
f01017bc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017c0:	39 34 24             	cmp    %esi,(%esp)
f01017c3:	0f 86 9f 00 00 00    	jbe    f0101868 <__udivdi3+0x108>
f01017c9:	39 d0                	cmp    %edx,%eax
f01017cb:	0f 82 97 00 00 00    	jb     f0101868 <__udivdi3+0x108>
f01017d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	31 c0                	xor    %eax,%eax
f01017dc:	83 c4 0c             	add    $0xc,%esp
f01017df:	5e                   	pop    %esi
f01017e0:	5f                   	pop    %edi
f01017e1:	5d                   	pop    %ebp
f01017e2:	c3                   	ret    
f01017e3:	90                   	nop
f01017e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017e8:	89 f8                	mov    %edi,%eax
f01017ea:	f7 f1                	div    %ecx
f01017ec:	31 d2                	xor    %edx,%edx
f01017ee:	83 c4 0c             	add    $0xc,%esp
f01017f1:	5e                   	pop    %esi
f01017f2:	5f                   	pop    %edi
f01017f3:	5d                   	pop    %ebp
f01017f4:	c3                   	ret    
f01017f5:	8d 76 00             	lea    0x0(%esi),%esi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	8b 3c 24             	mov    (%esp),%edi
f01017fd:	d3 e0                	shl    %cl,%eax
f01017ff:	89 c6                	mov    %eax,%esi
f0101801:	b8 20 00 00 00       	mov    $0x20,%eax
f0101806:	29 e8                	sub    %ebp,%eax
f0101808:	89 c1                	mov    %eax,%ecx
f010180a:	d3 ef                	shr    %cl,%edi
f010180c:	89 e9                	mov    %ebp,%ecx
f010180e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101812:	8b 3c 24             	mov    (%esp),%edi
f0101815:	09 74 24 08          	or     %esi,0x8(%esp)
f0101819:	89 d6                	mov    %edx,%esi
f010181b:	d3 e7                	shl    %cl,%edi
f010181d:	89 c1                	mov    %eax,%ecx
f010181f:	89 3c 24             	mov    %edi,(%esp)
f0101822:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101826:	d3 ee                	shr    %cl,%esi
f0101828:	89 e9                	mov    %ebp,%ecx
f010182a:	d3 e2                	shl    %cl,%edx
f010182c:	89 c1                	mov    %eax,%ecx
f010182e:	d3 ef                	shr    %cl,%edi
f0101830:	09 d7                	or     %edx,%edi
f0101832:	89 f2                	mov    %esi,%edx
f0101834:	89 f8                	mov    %edi,%eax
f0101836:	f7 74 24 08          	divl   0x8(%esp)
f010183a:	89 d6                	mov    %edx,%esi
f010183c:	89 c7                	mov    %eax,%edi
f010183e:	f7 24 24             	mull   (%esp)
f0101841:	39 d6                	cmp    %edx,%esi
f0101843:	89 14 24             	mov    %edx,(%esp)
f0101846:	72 30                	jb     f0101878 <__udivdi3+0x118>
f0101848:	8b 54 24 04          	mov    0x4(%esp),%edx
f010184c:	89 e9                	mov    %ebp,%ecx
f010184e:	d3 e2                	shl    %cl,%edx
f0101850:	39 c2                	cmp    %eax,%edx
f0101852:	73 05                	jae    f0101859 <__udivdi3+0xf9>
f0101854:	3b 34 24             	cmp    (%esp),%esi
f0101857:	74 1f                	je     f0101878 <__udivdi3+0x118>
f0101859:	89 f8                	mov    %edi,%eax
f010185b:	31 d2                	xor    %edx,%edx
f010185d:	e9 7a ff ff ff       	jmp    f01017dc <__udivdi3+0x7c>
f0101862:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101868:	31 d2                	xor    %edx,%edx
f010186a:	b8 01 00 00 00       	mov    $0x1,%eax
f010186f:	e9 68 ff ff ff       	jmp    f01017dc <__udivdi3+0x7c>
f0101874:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101878:	8d 47 ff             	lea    -0x1(%edi),%eax
f010187b:	31 d2                	xor    %edx,%edx
f010187d:	83 c4 0c             	add    $0xc,%esp
f0101880:	5e                   	pop    %esi
f0101881:	5f                   	pop    %edi
f0101882:	5d                   	pop    %ebp
f0101883:	c3                   	ret    
f0101884:	66 90                	xchg   %ax,%ax
f0101886:	66 90                	xchg   %ax,%ax
f0101888:	66 90                	xchg   %ax,%ax
f010188a:	66 90                	xchg   %ax,%ax
f010188c:	66 90                	xchg   %ax,%ax
f010188e:	66 90                	xchg   %ax,%ax

f0101890 <__umoddi3>:
f0101890:	55                   	push   %ebp
f0101891:	57                   	push   %edi
f0101892:	56                   	push   %esi
f0101893:	83 ec 14             	sub    $0x14,%esp
f0101896:	8b 44 24 28          	mov    0x28(%esp),%eax
f010189a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010189e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01018a2:	89 c7                	mov    %eax,%edi
f01018a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01018ac:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01018b0:	89 34 24             	mov    %esi,(%esp)
f01018b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	89 c2                	mov    %eax,%edx
f01018bb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018bf:	75 17                	jne    f01018d8 <__umoddi3+0x48>
f01018c1:	39 fe                	cmp    %edi,%esi
f01018c3:	76 4b                	jbe    f0101910 <__umoddi3+0x80>
f01018c5:	89 c8                	mov    %ecx,%eax
f01018c7:	89 fa                	mov    %edi,%edx
f01018c9:	f7 f6                	div    %esi
f01018cb:	89 d0                	mov    %edx,%eax
f01018cd:	31 d2                	xor    %edx,%edx
f01018cf:	83 c4 14             	add    $0x14,%esp
f01018d2:	5e                   	pop    %esi
f01018d3:	5f                   	pop    %edi
f01018d4:	5d                   	pop    %ebp
f01018d5:	c3                   	ret    
f01018d6:	66 90                	xchg   %ax,%ax
f01018d8:	39 f8                	cmp    %edi,%eax
f01018da:	77 54                	ja     f0101930 <__umoddi3+0xa0>
f01018dc:	0f bd e8             	bsr    %eax,%ebp
f01018df:	83 f5 1f             	xor    $0x1f,%ebp
f01018e2:	75 5c                	jne    f0101940 <__umoddi3+0xb0>
f01018e4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018e8:	39 3c 24             	cmp    %edi,(%esp)
f01018eb:	0f 87 e7 00 00 00    	ja     f01019d8 <__umoddi3+0x148>
f01018f1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018f5:	29 f1                	sub    %esi,%ecx
f01018f7:	19 c7                	sbb    %eax,%edi
f01018f9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018fd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101901:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101905:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101909:	83 c4 14             	add    $0x14,%esp
f010190c:	5e                   	pop    %esi
f010190d:	5f                   	pop    %edi
f010190e:	5d                   	pop    %ebp
f010190f:	c3                   	ret    
f0101910:	85 f6                	test   %esi,%esi
f0101912:	89 f5                	mov    %esi,%ebp
f0101914:	75 0b                	jne    f0101921 <__umoddi3+0x91>
f0101916:	b8 01 00 00 00       	mov    $0x1,%eax
f010191b:	31 d2                	xor    %edx,%edx
f010191d:	f7 f6                	div    %esi
f010191f:	89 c5                	mov    %eax,%ebp
f0101921:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101925:	31 d2                	xor    %edx,%edx
f0101927:	f7 f5                	div    %ebp
f0101929:	89 c8                	mov    %ecx,%eax
f010192b:	f7 f5                	div    %ebp
f010192d:	eb 9c                	jmp    f01018cb <__umoddi3+0x3b>
f010192f:	90                   	nop
f0101930:	89 c8                	mov    %ecx,%eax
f0101932:	89 fa                	mov    %edi,%edx
f0101934:	83 c4 14             	add    $0x14,%esp
f0101937:	5e                   	pop    %esi
f0101938:	5f                   	pop    %edi
f0101939:	5d                   	pop    %ebp
f010193a:	c3                   	ret    
f010193b:	90                   	nop
f010193c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101940:	8b 04 24             	mov    (%esp),%eax
f0101943:	be 20 00 00 00       	mov    $0x20,%esi
f0101948:	89 e9                	mov    %ebp,%ecx
f010194a:	29 ee                	sub    %ebp,%esi
f010194c:	d3 e2                	shl    %cl,%edx
f010194e:	89 f1                	mov    %esi,%ecx
f0101950:	d3 e8                	shr    %cl,%eax
f0101952:	89 e9                	mov    %ebp,%ecx
f0101954:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101958:	8b 04 24             	mov    (%esp),%eax
f010195b:	09 54 24 04          	or     %edx,0x4(%esp)
f010195f:	89 fa                	mov    %edi,%edx
f0101961:	d3 e0                	shl    %cl,%eax
f0101963:	89 f1                	mov    %esi,%ecx
f0101965:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101969:	8b 44 24 10          	mov    0x10(%esp),%eax
f010196d:	d3 ea                	shr    %cl,%edx
f010196f:	89 e9                	mov    %ebp,%ecx
f0101971:	d3 e7                	shl    %cl,%edi
f0101973:	89 f1                	mov    %esi,%ecx
f0101975:	d3 e8                	shr    %cl,%eax
f0101977:	89 e9                	mov    %ebp,%ecx
f0101979:	09 f8                	or     %edi,%eax
f010197b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010197f:	f7 74 24 04          	divl   0x4(%esp)
f0101983:	d3 e7                	shl    %cl,%edi
f0101985:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101989:	89 d7                	mov    %edx,%edi
f010198b:	f7 64 24 08          	mull   0x8(%esp)
f010198f:	39 d7                	cmp    %edx,%edi
f0101991:	89 c1                	mov    %eax,%ecx
f0101993:	89 14 24             	mov    %edx,(%esp)
f0101996:	72 2c                	jb     f01019c4 <__umoddi3+0x134>
f0101998:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010199c:	72 22                	jb     f01019c0 <__umoddi3+0x130>
f010199e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01019a2:	29 c8                	sub    %ecx,%eax
f01019a4:	19 d7                	sbb    %edx,%edi
f01019a6:	89 e9                	mov    %ebp,%ecx
f01019a8:	89 fa                	mov    %edi,%edx
f01019aa:	d3 e8                	shr    %cl,%eax
f01019ac:	89 f1                	mov    %esi,%ecx
f01019ae:	d3 e2                	shl    %cl,%edx
f01019b0:	89 e9                	mov    %ebp,%ecx
f01019b2:	d3 ef                	shr    %cl,%edi
f01019b4:	09 d0                	or     %edx,%eax
f01019b6:	89 fa                	mov    %edi,%edx
f01019b8:	83 c4 14             	add    $0x14,%esp
f01019bb:	5e                   	pop    %esi
f01019bc:	5f                   	pop    %edi
f01019bd:	5d                   	pop    %ebp
f01019be:	c3                   	ret    
f01019bf:	90                   	nop
f01019c0:	39 d7                	cmp    %edx,%edi
f01019c2:	75 da                	jne    f010199e <__umoddi3+0x10e>
f01019c4:	8b 14 24             	mov    (%esp),%edx
f01019c7:	89 c1                	mov    %eax,%ecx
f01019c9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019cd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019d1:	eb cb                	jmp    f010199e <__umoddi3+0x10e>
f01019d3:	90                   	nop
f01019d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019dc:	0f 82 0f ff ff ff    	jb     f01018f1 <__umoddi3+0x61>
f01019e2:	e9 1a ff ff ff       	jmp    f0101901 <__umoddi3+0x71>
