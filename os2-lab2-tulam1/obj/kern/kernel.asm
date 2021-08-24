
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
	cprintf("leaving test_backtrace %d\n", x);
}*/

void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 60 79 11 f0       	mov    $0xf0117960,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 af 38 00 00       	call   f0103917 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("444544 decimal is %o octal!\n", 444544);
f010006d:	c7 44 24 04 80 c8 06 	movl   $0x6c880,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 3d 10 f0 	movl   $0xf0103dc0,(%esp)
f010007c:	e8 28 2d 00 00       	call   f0102da9 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	//test_backtrace(5);

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 81 11 00 00       	call   f0101207 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 83 07 00 00       	call   f0100815 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 64 79 11 f0 00 	cmpl   $0x0,0xf0117964
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 64 79 11 f0    	mov    %esi,0xf0117964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 dd 3d 10 f0 	movl   $0xf0103ddd,(%esp)
f01000c8:	e8 dc 2c 00 00       	call   f0102da9 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 9d 2c 00 00       	call   f0102d76 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 6d 4d 10 f0 	movl   $0xf0104d6d,(%esp)
f01000e0:	e8 c4 2c 00 00       	call   f0102da9 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 24 07 00 00       	call   f0100815 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 f5 3d 10 f0 	movl   $0xf0103df5,(%esp)
f0100112:	e8 92 2c 00 00       	call   f0102da9 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 50 2c 00 00       	call   f0102d76 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 6d 4d 10 f0 	movl   $0xf0104d6d,(%esp)
f010012d:	e8 77 2c 00 00       	call   f0102da9 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01001cb:	c3                   	ret    
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a 60 3e 10 f0 	movzbl -0xfefc1a0(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300
	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d 40 3e 10 f0 	mov    -0xfefc1c0(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
	return c;
f010027b:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 0f 3e 10 f0 	movl   $0xf0103e0f,(%esp)
f0100291:	e8 13 2b 00 00       	call   f0102da9 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 26 35 00 00       	call   f0103964 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 1b 3e 10 f0 	movl   $0xf0103e1b,(%esp)
f01005f4:	e8 b0 27 00 00       	call   f0102da9 <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 60 40 10 	movl   $0xf0104060,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 7e 40 10 	movl   $0xf010407e,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 83 40 10 f0 	movl   $0xf0104083,(%esp)
f010064d:	e8 57 27 00 00       	call   f0102da9 <cprintf>
f0100652:	c7 44 24 08 34 41 10 	movl   $0xf0104134,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 8c 40 10 	movl   $0xf010408c,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 83 40 10 f0 	movl   $0xf0104083,(%esp)
f0100669:	e8 3b 27 00 00       	call   f0102da9 <cprintf>
f010066e:	c7 44 24 08 5c 41 10 	movl   $0xf010415c,0x8(%esp)
f0100675:	f0 
f0100676:	c7 44 24 04 95 40 10 	movl   $0xf0104095,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 83 40 10 f0 	movl   $0xf0104083,(%esp)
f0100685:	e8 1f 27 00 00       	call   f0102da9 <cprintf>
	return 0;
}
f010068a:	b8 00 00 00 00       	mov    $0x0,%eax
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	c7 04 24 9f 40 10 f0 	movl   $0xf010409f,(%esp)
f010069e:	e8 06 27 00 00       	call   f0102da9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006aa:	00 
f01006ab:	c7 04 24 90 41 10 f0 	movl   $0xf0104190,(%esp)
f01006b2:	e8 f2 26 00 00       	call   f0102da9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 b8 41 10 f0 	movl   $0xf01041b8,(%esp)
f01006ce:	e8 d6 26 00 00       	call   f0102da9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d3:	c7 44 24 08 a7 3d 10 	movl   $0x103da7,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 a7 3d 10 	movl   $0xf0103da7,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 dc 41 10 f0 	movl   $0xf01041dc,(%esp)
f01006ea:	e8 ba 26 00 00       	call   f0102da9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 00 42 10 f0 	movl   $0xf0104200,(%esp)
f0100706:	e8 9e 26 00 00       	call   f0102da9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070b:	c7 44 24 08 60 79 11 	movl   $0x117960,0x8(%esp)
f0100712:	00 
f0100713:	c7 44 24 04 60 79 11 	movl   $0xf0117960,0x4(%esp)
f010071a:	f0 
f010071b:	c7 04 24 24 42 10 f0 	movl   $0xf0104224,(%esp)
f0100722:	e8 82 26 00 00       	call   f0102da9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 5f 7d 11 f0       	mov    $0xf0117d5f,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100731:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100736:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073c:	85 c0                	test   %eax,%eax
f010073e:	0f 48 c2             	cmovs  %edx,%eax
f0100741:	c1 f8 0a             	sar    $0xa,%eax
f0100744:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100748:	c7 04 24 48 42 10 f0 	movl   $0xf0104248,(%esp)
f010074f:	e8 55 26 00 00       	call   f0102da9 <cprintf>
	return 0;
}
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	57                   	push   %edi
f010075f:	56                   	push   %esi
f0100760:	53                   	push   %ebx
f0100761:	83 ec 4c             	sub    $0x4c,%esp
	// LAB 1: Your code here.
    // HINT 1: use read_ebp().
    // HINT 2: print the current ebp on the first line (not current_ebp[0])

	// Here is the code implementation
	int *ebp = (int *)read_ebp();
f0100764:	89 ee                	mov    %ebp,%esi
   cprintf("Stack backtrace:\n");
f0100766:	c7 04 24 b8 40 10 f0 	movl   $0xf01040b8,(%esp)
f010076d:	e8 37 26 00 00       	call   f0102da9 <cprintf>
		}
		cprintf("\n");													// Print a new line to separate things out

		// This is the part printing out the file name, line, etc...
		struct Eipdebuginfo fn_info;								// Create a struct to pass through the debuginfo fn
		debuginfo_eip(ebp[1], &fn_info);							// Call the funct. and print the statement
f0100772:	8d 7d d0             	lea    -0x30(%ebp),%edi
	while (ebp) {														// Create a while loop to loop through ebp content
f0100775:	e9 86 00 00 00       	jmp    f0100800 <mon_backtrace+0xa5>
		cprintf("ebp %08x eip %08x args", ebp, ebp[1]);		// Print out the EBP & the EIP
f010077a:	8b 46 04             	mov    0x4(%esi),%eax
f010077d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100781:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100785:	c7 04 24 ca 40 10 f0 	movl   $0xf01040ca,(%esp)
f010078c:	e8 18 26 00 00       	call   f0102da9 <cprintf>
		for (i = 2; i < 7; i++) {									// Create a for loop to print out the EBP[2]-[6]
f0100791:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", ebp[i]);
f0100796:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100799:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079d:	c7 04 24 e1 40 10 f0 	movl   $0xf01040e1,(%esp)
f01007a4:	e8 00 26 00 00       	call   f0102da9 <cprintf>
		for (i = 2; i < 7; i++) {									// Create a for loop to print out the EBP[2]-[6]
f01007a9:	83 c3 01             	add    $0x1,%ebx
f01007ac:	83 fb 07             	cmp    $0x7,%ebx
f01007af:	75 e5                	jne    f0100796 <mon_backtrace+0x3b>
		cprintf("\n");													// Print a new line to separate things out
f01007b1:	c7 04 24 6d 4d 10 f0 	movl   $0xf0104d6d,(%esp)
f01007b8:	e8 ec 25 00 00       	call   f0102da9 <cprintf>
		debuginfo_eip(ebp[1], &fn_info);							// Call the funct. and print the statement
f01007bd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007c1:	8b 46 04             	mov    0x4(%esi),%eax
f01007c4:	89 04 24             	mov    %eax,(%esp)
f01007c7:	e8 d4 26 00 00       	call   f0102ea0 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", fn_info.eip_file, fn_info.eip_line, fn_info.eip_fn_namelen,
f01007cc:	8b 46 04             	mov    0x4(%esi),%eax
f01007cf:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007d2:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007d6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007d9:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007dd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007e7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007eb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f2:	c7 04 24 e7 40 10 f0 	movl   $0xf01040e7,(%esp)
f01007f9:	e8 ab 25 00 00       	call   f0102da9 <cprintf>
												fn_info.eip_fn_name, (ebp[1] - fn_info.eip_fn_addr));
		ebp = (int *) *ebp;											// Reset the EBP to move back to the save EBP		
f01007fe:	8b 36                	mov    (%esi),%esi
	while (ebp) {														// Create a while loop to loop through ebp content
f0100800:	85 f6                	test   %esi,%esi
f0100802:	0f 85 72 ff ff ff    	jne    f010077a <mon_backtrace+0x1f>
	}
	return 0;
}
f0100808:	b8 00 00 00 00       	mov    $0x0,%eax
f010080d:	83 c4 4c             	add    $0x4c,%esp
f0100810:	5b                   	pop    %ebx
f0100811:	5e                   	pop    %esi
f0100812:	5f                   	pop    %edi
f0100813:	5d                   	pop    %ebp
f0100814:	c3                   	ret    

f0100815 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
f0100818:	57                   	push   %edi
f0100819:	56                   	push   %esi
f010081a:	53                   	push   %ebx
f010081b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010081e:	c7 04 24 74 42 10 f0 	movl   $0xf0104274,(%esp)
f0100825:	e8 7f 25 00 00       	call   f0102da9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010082a:	c7 04 24 98 42 10 f0 	movl   $0xf0104298,(%esp)
f0100831:	e8 73 25 00 00       	call   f0102da9 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100836:	c7 04 24 f8 40 10 f0 	movl   $0xf01040f8,(%esp)
f010083d:	e8 7e 2e 00 00       	call   f01036c0 <readline>
f0100842:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100844:	85 c0                	test   %eax,%eax
f0100846:	74 ee                	je     f0100836 <monitor+0x21>
	argv[argc] = 0;
f0100848:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010084f:	be 00 00 00 00       	mov    $0x0,%esi
f0100854:	eb 0a                	jmp    f0100860 <monitor+0x4b>
			*buf++ = 0;
f0100856:	c6 03 00             	movb   $0x0,(%ebx)
f0100859:	89 f7                	mov    %esi,%edi
f010085b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010085e:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100860:	0f b6 03             	movzbl (%ebx),%eax
f0100863:	84 c0                	test   %al,%al
f0100865:	74 63                	je     f01008ca <monitor+0xb5>
f0100867:	0f be c0             	movsbl %al,%eax
f010086a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086e:	c7 04 24 fc 40 10 f0 	movl   $0xf01040fc,(%esp)
f0100875:	e8 60 30 00 00       	call   f01038da <strchr>
f010087a:	85 c0                	test   %eax,%eax
f010087c:	75 d8                	jne    f0100856 <monitor+0x41>
		if (*buf == 0)
f010087e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100881:	74 47                	je     f01008ca <monitor+0xb5>
		if (argc == MAXARGS-1) {
f0100883:	83 fe 0f             	cmp    $0xf,%esi
f0100886:	75 16                	jne    f010089e <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100888:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010088f:	00 
f0100890:	c7 04 24 01 41 10 f0 	movl   $0xf0104101,(%esp)
f0100897:	e8 0d 25 00 00       	call   f0102da9 <cprintf>
f010089c:	eb 98                	jmp    f0100836 <monitor+0x21>
		argv[argc++] = buf;
f010089e:	8d 7e 01             	lea    0x1(%esi),%edi
f01008a1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a5:	eb 03                	jmp    f01008aa <monitor+0x95>
			buf++;
f01008a7:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008aa:	0f b6 03             	movzbl (%ebx),%eax
f01008ad:	84 c0                	test   %al,%al
f01008af:	74 ad                	je     f010085e <monitor+0x49>
f01008b1:	0f be c0             	movsbl %al,%eax
f01008b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b8:	c7 04 24 fc 40 10 f0 	movl   $0xf01040fc,(%esp)
f01008bf:	e8 16 30 00 00       	call   f01038da <strchr>
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	74 df                	je     f01008a7 <monitor+0x92>
f01008c8:	eb 94                	jmp    f010085e <monitor+0x49>
	argv[argc] = 0;
f01008ca:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008d1:	00 
	if (argc == 0)
f01008d2:	85 f6                	test   %esi,%esi
f01008d4:	0f 84 5c ff ff ff    	je     f0100836 <monitor+0x21>
f01008da:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008df:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f01008e2:	8b 04 85 c0 42 10 f0 	mov    -0xfefbd40(,%eax,4),%eax
f01008e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ed:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f0:	89 04 24             	mov    %eax,(%esp)
f01008f3:	e8 84 2f 00 00       	call   f010387c <strcmp>
f01008f8:	85 c0                	test   %eax,%eax
f01008fa:	75 24                	jne    f0100920 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008fc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ff:	8b 55 08             	mov    0x8(%ebp),%edx
f0100902:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100906:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100909:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010090d:	89 34 24             	mov    %esi,(%esp)
f0100910:	ff 14 85 c8 42 10 f0 	call   *-0xfefbd38(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100917:	85 c0                	test   %eax,%eax
f0100919:	78 25                	js     f0100940 <monitor+0x12b>
f010091b:	e9 16 ff ff ff       	jmp    f0100836 <monitor+0x21>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100920:	83 c3 01             	add    $0x1,%ebx
f0100923:	83 fb 03             	cmp    $0x3,%ebx
f0100926:	75 b7                	jne    f01008df <monitor+0xca>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100928:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010092b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092f:	c7 04 24 1e 41 10 f0 	movl   $0xf010411e,(%esp)
f0100936:	e8 6e 24 00 00       	call   f0102da9 <cprintf>
f010093b:	e9 f6 fe ff ff       	jmp    f0100836 <monitor+0x21>
				break;
	}
}
f0100940:	83 c4 5c             	add    $0x5c,%esp
f0100943:	5b                   	pop    %ebx
f0100944:	5e                   	pop    %esi
f0100945:	5f                   	pop    %edi
f0100946:	5d                   	pop    %ebp
f0100947:	c3                   	ret    
f0100948:	66 90                	xchg   %ax,%ax
f010094a:	66 90                	xchg   %ax,%ax
f010094c:	66 90                	xchg   %ax,%ax
f010094e:	66 90                	xchg   %ax,%ax

f0100950 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100953:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f010095a:	75 37                	jne    f0100993 <boot_alloc+0x43>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010095c:	ba 5f 89 11 f0       	mov    $0xf011895f,%edx
f0100961:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100967:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n > 0) {
f010096d:	85 c0                	test   %eax,%eax
f010096f:	74 1b                	je     f010098c <boot_alloc+0x3c>
		char *prev_nextfree;											// Create a char pointer that help update virtual addr

		prev_nextfree = nextfree;									// Assign the original position of nextfree to prev_nextfree
f0100971:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);	// Update nextfree with the new position in addr
f0100977:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f010097e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100983:	a3 38 75 11 f0       	mov    %eax,0xf0117538
		return prev_nextfree;										// Then return the previous nextfree
f0100988:	89 d0                	mov    %edx,%eax
f010098a:	eb 0d                	jmp    f0100999 <boot_alloc+0x49>
	}
	
	else if (n == 0) {												// If n == 0, then just return nextfree w/o allocating
		return nextfree;
f010098c:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100991:	eb 06                	jmp    f0100999 <boot_alloc+0x49>
	if (n > 0) {
f0100993:	85 c0                	test   %eax,%eax
f0100995:	74 f5                	je     f010098c <boot_alloc+0x3c>
f0100997:	eb d8                	jmp    f0100971 <boot_alloc+0x21>
	}

	return NULL;
}
f0100999:	5d                   	pop    %ebp
f010099a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01009a0:	c3                   	ret    

f01009a1 <nvram_read>:
{
f01009a1:	55                   	push   %ebp
f01009a2:	89 e5                	mov    %esp,%ebp
f01009a4:	56                   	push   %esi
f01009a5:	53                   	push   %ebx
f01009a6:	83 ec 10             	sub    $0x10,%esp
f01009a9:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009ab:	89 04 24             	mov    %eax,(%esp)
f01009ae:	e8 86 23 00 00       	call   f0102d39 <mc146818_read>
f01009b3:	89 c6                	mov    %eax,%esi
f01009b5:	83 c3 01             	add    $0x1,%ebx
f01009b8:	89 1c 24             	mov    %ebx,(%esp)
f01009bb:	e8 79 23 00 00       	call   f0102d39 <mc146818_read>
f01009c0:	c1 e0 08             	shl    $0x8,%eax
f01009c3:	09 f0                	or     %esi,%eax
}
f01009c5:	83 c4 10             	add    $0x10,%esp
f01009c8:	5b                   	pop    %ebx
f01009c9:	5e                   	pop    %esi
f01009ca:	5d                   	pop    %ebp
f01009cb:	c3                   	ret    

f01009cc <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009cc:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01009d2:	c1 f8 03             	sar    $0x3,%eax
f01009d5:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01009d8:	89 c2                	mov    %eax,%edx
f01009da:	c1 ea 0c             	shr    $0xc,%edx
f01009dd:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01009e3:	72 26                	jb     f0100a0b <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01009e5:	55                   	push   %ebp
f01009e6:	89 e5                	mov    %esp,%ebp
f01009e8:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009ef:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f01009f6:	f0 
f01009f7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009fe:	00 
f01009ff:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0100a06:	e8 89 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a0b:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100a10:	c3                   	ret    

f0100a11 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a11:	89 d1                	mov    %edx,%ecx
f0100a13:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a16:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a19:	a8 01                	test   $0x1,%al
f0100a1b:	74 5d                	je     f0100a7a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a1d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100a22:	89 c1                	mov    %eax,%ecx
f0100a24:	c1 e9 0c             	shr    $0xc,%ecx
f0100a27:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0100a2d:	72 26                	jb     f0100a55 <check_va2pa+0x44>
{
f0100a2f:	55                   	push   %ebp
f0100a30:	89 e5                	mov    %esp,%ebp
f0100a32:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a35:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a39:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0100a40:	f0 
f0100a41:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0100a48:	00 
f0100a49:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100a50:	e8 3f f6 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a55:	c1 ea 0c             	shr    $0xc,%edx
f0100a58:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a5e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a65:	89 c2                	mov    %eax,%edx
f0100a67:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a6a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a6f:	85 d2                	test   %edx,%edx
f0100a71:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a76:	0f 44 c2             	cmove  %edx,%eax
f0100a79:	c3                   	ret    
		return ~0;
f0100a7a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100a7f:	c3                   	ret    

f0100a80 <check_page_free_list>:
{
f0100a80:	55                   	push   %ebp
f0100a81:	89 e5                	mov    %esp,%ebp
f0100a83:	57                   	push   %edi
f0100a84:	56                   	push   %esi
f0100a85:	53                   	push   %ebx
f0100a86:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a89:	84 c0                	test   %al,%al
f0100a8b:	0f 85 15 03 00 00    	jne    f0100da6 <check_page_free_list+0x326>
f0100a91:	e9 22 03 00 00       	jmp    f0100db8 <check_page_free_list+0x338>
		panic("'page_free_list' is a null pointer!");
f0100a96:	c7 44 24 08 08 43 10 	movl   $0xf0104308,0x8(%esp)
f0100a9d:	f0 
f0100a9e:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100aa5:	00 
f0100aa6:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100aad:	e8 e2 f5 ff ff       	call   f0100094 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ab2:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ab5:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ab8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100abb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100abe:	89 c2                	mov    %eax,%edx
f0100ac0:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ac6:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100acc:	0f 95 c2             	setne  %dl
f0100acf:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ad2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ad6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ad8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100adc:	8b 00                	mov    (%eax),%eax
f0100ade:	85 c0                	test   %eax,%eax
f0100ae0:	75 dc                	jne    f0100abe <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100ae2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aee:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100af1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100af3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100af6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100afb:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b00:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b06:	eb 63                	jmp    f0100b6b <check_page_free_list+0xeb>
f0100b08:	89 d8                	mov    %ebx,%eax
f0100b0a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100b10:	c1 f8 03             	sar    $0x3,%eax
f0100b13:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b16:	89 c2                	mov    %eax,%edx
f0100b18:	c1 ea 16             	shr    $0x16,%edx
f0100b1b:	39 f2                	cmp    %esi,%edx
f0100b1d:	73 4a                	jae    f0100b69 <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100b1f:	89 c2                	mov    %eax,%edx
f0100b21:	c1 ea 0c             	shr    $0xc,%edx
f0100b24:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100b2a:	72 20                	jb     f0100b4c <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b30:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0100b37:	f0 
f0100b38:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b3f:	00 
f0100b40:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0100b47:	e8 48 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b4c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b53:	00 
f0100b54:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b5b:	00 
	return (void *)(pa + KERNBASE);
f0100b5c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b61:	89 04 24             	mov    %eax,(%esp)
f0100b64:	e8 ae 2d 00 00       	call   f0103917 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b69:	8b 1b                	mov    (%ebx),%ebx
f0100b6b:	85 db                	test   %ebx,%ebx
f0100b6d:	75 99                	jne    f0100b08 <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b74:	e8 d7 fd ff ff       	call   f0100950 <boot_alloc>
f0100b79:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b7c:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		assert(pp >= pages);
f0100b82:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
		assert(pp < pages + npages);
f0100b88:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0100b8d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b90:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b96:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b99:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b9e:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba1:	e9 97 01 00 00       	jmp    f0100d3d <check_page_free_list+0x2bd>
		assert(pp >= pages);
f0100ba6:	39 ca                	cmp    %ecx,%edx
f0100ba8:	73 24                	jae    f0100bce <check_page_free_list+0x14e>
f0100baa:	c7 44 24 0c d6 4a 10 	movl   $0xf0104ad6,0xc(%esp)
f0100bb1:	f0 
f0100bb2:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100bb9:	f0 
f0100bba:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100bc1:	00 
f0100bc2:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100bc9:	e8 c6 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bce:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bd1:	72 24                	jb     f0100bf7 <check_page_free_list+0x177>
f0100bd3:	c7 44 24 0c f7 4a 10 	movl   $0xf0104af7,0xc(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100be2:	f0 
f0100be3:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100bea:	00 
f0100beb:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100bf2:	e8 9d f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bf7:	89 d0                	mov    %edx,%eax
f0100bf9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bfc:	a8 07                	test   $0x7,%al
f0100bfe:	74 24                	je     f0100c24 <check_page_free_list+0x1a4>
f0100c00:	c7 44 24 0c 2c 43 10 	movl   $0xf010432c,0xc(%esp)
f0100c07:	f0 
f0100c08:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100c0f:	f0 
f0100c10:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100c17:	00 
f0100c18:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100c1f:	e8 70 f4 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0100c24:	c1 f8 03             	sar    $0x3,%eax
f0100c27:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100c2a:	85 c0                	test   %eax,%eax
f0100c2c:	75 24                	jne    f0100c52 <check_page_free_list+0x1d2>
f0100c2e:	c7 44 24 0c 0b 4b 10 	movl   $0xf0104b0b,0xc(%esp)
f0100c35:	f0 
f0100c36:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100c3d:	f0 
f0100c3e:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100c45:	00 
f0100c46:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100c4d:	e8 42 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c52:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c57:	75 24                	jne    f0100c7d <check_page_free_list+0x1fd>
f0100c59:	c7 44 24 0c 1c 4b 10 	movl   $0xf0104b1c,0xc(%esp)
f0100c60:	f0 
f0100c61:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100c68:	f0 
f0100c69:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f0100c70:	00 
f0100c71:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100c78:	e8 17 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c7d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c82:	75 24                	jne    f0100ca8 <check_page_free_list+0x228>
f0100c84:	c7 44 24 0c 60 43 10 	movl   $0xf0104360,0xc(%esp)
f0100c8b:	f0 
f0100c8c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100c93:	f0 
f0100c94:	c7 44 24 04 59 02 00 	movl   $0x259,0x4(%esp)
f0100c9b:	00 
f0100c9c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100ca3:	e8 ec f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ca8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cad:	75 24                	jne    f0100cd3 <check_page_free_list+0x253>
f0100caf:	c7 44 24 0c 35 4b 10 	movl   $0xf0104b35,0xc(%esp)
f0100cb6:	f0 
f0100cb7:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100cbe:	f0 
f0100cbf:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f0100cc6:	00 
f0100cc7:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100cce:	e8 c1 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cd3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cd8:	76 58                	jbe    f0100d32 <check_page_free_list+0x2b2>
	if (PGNUM(pa) >= npages)
f0100cda:	89 c3                	mov    %eax,%ebx
f0100cdc:	c1 eb 0c             	shr    $0xc,%ebx
f0100cdf:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100ce2:	77 20                	ja     f0100d04 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce8:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0100cef:	f0 
f0100cf0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cf7:	00 
f0100cf8:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0100cff:	e8 90 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d09:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d0c:	76 2a                	jbe    f0100d38 <check_page_free_list+0x2b8>
f0100d0e:	c7 44 24 0c 84 43 10 	movl   $0xf0104384,0xc(%esp)
f0100d15:	f0 
f0100d16:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100d1d:	f0 
f0100d1e:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f0100d25:	00 
f0100d26:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100d2d:	e8 62 f3 ff ff       	call   f0100094 <_panic>
			++nfree_basemem;
f0100d32:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d36:	eb 03                	jmp    f0100d3b <check_page_free_list+0x2bb>
			++nfree_extmem;
f0100d38:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d3b:	8b 12                	mov    (%edx),%edx
f0100d3d:	85 d2                	test   %edx,%edx
f0100d3f:	0f 85 61 fe ff ff    	jne    f0100ba6 <check_page_free_list+0x126>
f0100d45:	8b 5d cc             	mov    -0x34(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100d48:	85 db                	test   %ebx,%ebx
f0100d4a:	7f 24                	jg     f0100d70 <check_page_free_list+0x2f0>
f0100d4c:	c7 44 24 0c 4f 4b 10 	movl   $0xf0104b4f,0xc(%esp)
f0100d53:	f0 
f0100d54:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100d5b:	f0 
f0100d5c:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0100d63:	00 
f0100d64:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100d6b:	e8 24 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d70:	85 ff                	test   %edi,%edi
f0100d72:	7f 24                	jg     f0100d98 <check_page_free_list+0x318>
f0100d74:	c7 44 24 0c 61 4b 10 	movl   $0xf0104b61,0xc(%esp)
f0100d7b:	f0 
f0100d7c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0100d83:	f0 
f0100d84:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0100d8b:	00 
f0100d8c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100d93:	e8 fc f2 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0100d98:	c7 04 24 cc 43 10 f0 	movl   $0xf01043cc,(%esp)
f0100d9f:	e8 05 20 00 00       	call   f0102da9 <cprintf>
f0100da4:	eb 29                	jmp    f0100dcf <check_page_free_list+0x34f>
	if (!page_free_list)
f0100da6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100dab:	85 c0                	test   %eax,%eax
f0100dad:	0f 85 ff fc ff ff    	jne    f0100ab2 <check_page_free_list+0x32>
f0100db3:	e9 de fc ff ff       	jmp    f0100a96 <check_page_free_list+0x16>
f0100db8:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100dbf:	0f 84 d1 fc ff ff    	je     f0100a96 <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dc5:	be 00 04 00 00       	mov    $0x400,%esi
f0100dca:	e9 31 fd ff ff       	jmp    f0100b00 <check_page_free_list+0x80>
}
f0100dcf:	83 c4 4c             	add    $0x4c,%esp
f0100dd2:	5b                   	pop    %ebx
f0100dd3:	5e                   	pop    %esi
f0100dd4:	5f                   	pop    %edi
f0100dd5:	5d                   	pop    %ebp
f0100dd6:	c3                   	ret    

f0100dd7 <page_init>:
{
f0100dd7:	55                   	push   %ebp
f0100dd8:	89 e5                	mov    %esp,%ebp
f0100dda:	56                   	push   %esi
f0100ddb:	53                   	push   %ebx
	for (i = 1; i < npages_basemem; i++) {
f0100ddc:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100de2:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100de8:	b8 01 00 00 00       	mov    $0x1,%eax
f0100ded:	eb 22                	jmp    f0100e11 <page_init+0x3a>
f0100def:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100df6:	89 d1                	mov    %edx,%ecx
f0100df8:	03 0d 70 79 11 f0    	add    0xf0117970,%ecx
f0100dfe:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e04:	89 19                	mov    %ebx,(%ecx)
	for (i = 1; i < npages_basemem; i++) {
f0100e06:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100e09:	03 15 70 79 11 f0    	add    0xf0117970,%edx
f0100e0f:	89 d3                	mov    %edx,%ebx
	for (i = 1; i < npages_basemem; i++) {
f0100e11:	39 f0                	cmp    %esi,%eax
f0100e13:	72 da                	jb     f0100def <page_init+0x18>
	middle = (int)ROUNDUP(((char *)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE) / PGSIZE;
f0100e15:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f0100e1a:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0100e20:	8d 84 d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%eax
f0100e27:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e2c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e32:	85 c0                	test   %eax,%eax
f0100e34:	0f 48 c2             	cmovs  %edx,%eax
f0100e37:	c1 f8 0c             	sar    $0xc,%eax
	for (i = middle; i < npages; i++) {
f0100e3a:	89 c2                	mov    %eax,%edx
f0100e3c:	c1 e0 03             	shl    $0x3,%eax
f0100e3f:	eb 1e                	jmp    f0100e5f <page_init+0x88>
		pages[i].pp_ref = 0;
f0100e41:	89 c1                	mov    %eax,%ecx
f0100e43:	03 0d 70 79 11 f0    	add    0xf0117970,%ecx
f0100e49:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e4f:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e51:	89 c3                	mov    %eax,%ebx
f0100e53:	03 1d 70 79 11 f0    	add    0xf0117970,%ebx
	for (i = middle; i < npages; i++) {
f0100e59:	83 c2 01             	add    $0x1,%edx
f0100e5c:	83 c0 08             	add    $0x8,%eax
f0100e5f:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100e65:	72 da                	jb     f0100e41 <page_init+0x6a>
f0100e67:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
}
f0100e6d:	5b                   	pop    %ebx
f0100e6e:	5e                   	pop    %esi
f0100e6f:	5d                   	pop    %ebp
f0100e70:	c3                   	ret    

f0100e71 <page_alloc>:
{
f0100e71:	55                   	push   %ebp
f0100e72:	89 e5                	mov    %esp,%ebp
f0100e74:	53                   	push   %ebx
f0100e75:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list) {
f0100e78:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e7e:	85 db                	test   %ebx,%ebx
f0100e80:	74 6f                	je     f0100ef1 <page_alloc+0x80>
		page_free_list = page_free_list->pp_link;	// Update the free_list to point at pp_link
f0100e82:	8b 03                	mov    (%ebx),%eax
f0100e84:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
		tmp->pp_link = NULL;								// Assign the tmp->link to point to NULL
f0100e89:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		return tmp;											// Return tmp;
f0100e8f:	89 d8                	mov    %ebx,%eax
		if (alloc_flags & ALLOC_ZERO) {				// Fill the entire page with \0 if true
f0100e91:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e95:	74 5f                	je     f0100ef6 <page_alloc+0x85>
	return (pp - pages) << PGSHIFT;
f0100e97:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100e9d:	c1 f8 03             	sar    $0x3,%eax
f0100ea0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100ea3:	89 c2                	mov    %eax,%edx
f0100ea5:	c1 ea 0c             	shr    $0xc,%edx
f0100ea8:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100eae:	72 20                	jb     f0100ed0 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eb0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb4:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0100ebb:	f0 
f0100ebc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ec3:	00 
f0100ec4:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0100ecb:	e8 c4 f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(tmp), 0, PGSIZE);
f0100ed0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ed7:	00 
f0100ed8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100edf:	00 
	return (void *)(pa + KERNBASE);
f0100ee0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee5:	89 04 24             	mov    %eax,(%esp)
f0100ee8:	e8 2a 2a 00 00       	call   f0103917 <memset>
		return tmp;											// Return tmp;
f0100eed:	89 d8                	mov    %ebx,%eax
f0100eef:	eb 05                	jmp    f0100ef6 <page_alloc+0x85>
	return NULL;											// Return NULL if out of memory
f0100ef1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ef6:	83 c4 14             	add    $0x14,%esp
f0100ef9:	5b                   	pop    %ebx
f0100efa:	5d                   	pop    %ebp
f0100efb:	c3                   	ret    

f0100efc <page_free>:
{
f0100efc:	55                   	push   %ebp
f0100efd:	89 e5                	mov    %esp,%ebp
f0100eff:	83 ec 18             	sub    $0x18,%esp
f0100f02:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_link != NULL || pp->pp_ref != 0) {	// Check if pp_ref is nonzero or pp_link != NULL
f0100f05:	83 38 00             	cmpl   $0x0,(%eax)
f0100f08:	75 07                	jne    f0100f11 <page_free+0x15>
f0100f0a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f0f:	74 1c                	je     f0100f2d <page_free+0x31>
		panic("page_free: Either the REF is nonzero OR LINK is not NULL\n");
f0100f11:	c7 44 24 08 f0 43 10 	movl   $0xf01043f0,0x8(%esp)
f0100f18:	f0 
f0100f19:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
f0100f20:	00 
f0100f21:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100f28:	e8 67 f1 ff ff       	call   f0100094 <_panic>
	pp->pp_link = page_free_list;							// pp_link will point to page_free_list
f0100f2d:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100f33:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;										// page_free_list now points to NULL
f0100f35:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100f3a:	c9                   	leave  
f0100f3b:	c3                   	ret    

f0100f3c <page_decref>:
{
f0100f3c:	55                   	push   %ebp
f0100f3d:	89 e5                	mov    %esp,%ebp
f0100f3f:	83 ec 18             	sub    $0x18,%esp
f0100f42:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f45:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f49:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f4c:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f50:	66 85 d2             	test   %dx,%dx
f0100f53:	75 08                	jne    f0100f5d <page_decref+0x21>
		page_free(pp);
f0100f55:	89 04 24             	mov    %eax,(%esp)
f0100f58:	e8 9f ff ff ff       	call   f0100efc <page_free>
}
f0100f5d:	c9                   	leave  
f0100f5e:	c3                   	ret    

f0100f5f <pgdir_walk>:
{
f0100f5f:	55                   	push   %ebp
f0100f60:	89 e5                	mov    %esp,%ebp
f0100f62:	56                   	push   %esi
f0100f63:	53                   	push   %ebx
f0100f64:	83 ec 10             	sub    $0x10,%esp
f0100f67:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pgdir_index = PDX(va);											// Fetch the index out from virtual address
f0100f6a:	89 de                	mov    %ebx,%esi
f0100f6c:	c1 ee 16             	shr    $0x16,%esi
	pde_t *pde = &pgdir[pgdir_index];
f0100f6f:	c1 e6 02             	shl    $0x2,%esi
f0100f72:	03 75 08             	add    0x8(%ebp),%esi
	if (!(*pde & PTE_P)) {														// If the entry does not exist in both, create one
f0100f75:	8b 06                	mov    (%esi),%eax
f0100f77:	a8 01                	test   $0x1,%al
f0100f79:	75 76                	jne    f0100ff1 <pgdir_walk+0x92>
		if (create == 1) {														// If create flag is 1, create a new page table
f0100f7b:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
f0100f7f:	0f 85 b0 00 00 00    	jne    f0101035 <pgdir_walk+0xd6>
			struct PageInfo *pp_page_table = page_alloc(ALLOC_ZERO); // Allocate a page table 
f0100f85:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f8c:	e8 e0 fe ff ff       	call   f0100e71 <page_alloc>
			if (!pp_page_table) {
f0100f91:	85 c0                	test   %eax,%eax
f0100f93:	0f 84 a3 00 00 00    	je     f010103c <pgdir_walk+0xdd>
			pp_page_table->pp_ref++;											// Increment the ref by 1
f0100f99:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0100f9e:	89 c2                	mov    %eax,%edx
f0100fa0:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0100fa6:	c1 fa 03             	sar    $0x3,%edx
f0100fa9:	c1 e2 0c             	shl    $0xc,%edx
			*pde = page2pa(pp_page_table) | PTE_P | PTE_U | PTE_W;	// Update page to hold new page table
f0100fac:	83 ca 07             	or     $0x7,%edx
f0100faf:	89 16                	mov    %edx,(%esi)
f0100fb1:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100fb7:	c1 f8 03             	sar    $0x3,%eax
f0100fba:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100fbd:	89 c2                	mov    %eax,%edx
f0100fbf:	c1 ea 0c             	shr    $0xc,%edx
f0100fc2:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100fc8:	72 20                	jb     f0100fea <pgdir_walk+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fce:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0100fd5:	f0 
f0100fd6:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0100fdd:	00 
f0100fde:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0100fe5:	e8 aa f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fef:	eb 37                	jmp    f0101028 <pgdir_walk+0xc9>
		page_table = KADDR(PTE_ADDR(*pde));
f0100ff1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100ff6:	89 c2                	mov    %eax,%edx
f0100ff8:	c1 ea 0c             	shr    $0xc,%edx
f0100ffb:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0101001:	72 20                	jb     f0101023 <pgdir_walk+0xc4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101003:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101007:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f010100e:	f0 
f010100f:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
f0101016:	00 
f0101017:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010101e:	e8 71 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101023:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return &page_table[PTX(va)];
f0101028:	c1 eb 0a             	shr    $0xa,%ebx
f010102b:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101031:	01 d8                	add    %ebx,%eax
f0101033:	eb 0c                	jmp    f0101041 <pgdir_walk+0xe2>
			return NULL;
f0101035:	b8 00 00 00 00       	mov    $0x0,%eax
f010103a:	eb 05                	jmp    f0101041 <pgdir_walk+0xe2>
				return NULL;
f010103c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101041:	83 c4 10             	add    $0x10,%esp
f0101044:	5b                   	pop    %ebx
f0101045:	5e                   	pop    %esi
f0101046:	5d                   	pop    %ebp
f0101047:	c3                   	ret    

f0101048 <boot_map_region>:
{
f0101048:	55                   	push   %ebp
f0101049:	89 e5                	mov    %esp,%ebp
f010104b:	57                   	push   %edi
f010104c:	56                   	push   %esi
f010104d:	53                   	push   %ebx
f010104e:	83 ec 2c             	sub    $0x2c,%esp
f0101051:	89 c7                	mov    %eax,%edi
f0101053:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101056:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (int i = 0; i < size; i += PGSIZE) {
f0101059:	bb 00 00 00 00       	mov    $0x0,%ebx
		*p_pte = (pa + i) | PTE_P | perm;
f010105e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101061:	83 c8 01             	or     $0x1,%eax
f0101064:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (int i = 0; i < size; i += PGSIZE) {
f0101067:	eb 47                	jmp    f01010b0 <boot_map_region+0x68>
		pte_t *p_pte = pgdir_walk(pgdir, (void *) (va + i), 1); 	// Create a page
f0101069:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101070:	00 
f0101071:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101074:	01 d8                	add    %ebx,%eax
f0101076:	89 44 24 04          	mov    %eax,0x4(%esp)
f010107a:	89 3c 24             	mov    %edi,(%esp)
f010107d:	e8 dd fe ff ff       	call   f0100f5f <pgdir_walk>
		if (!p_pte) {															// Panic if out of memory
f0101082:	85 c0                	test   %eax,%eax
f0101084:	75 1c                	jne    f01010a2 <boot_map_region+0x5a>
			panic("boot_map_region: Out of memory!\n");
f0101086:	c7 44 24 08 2c 44 10 	movl   $0xf010442c,0x8(%esp)
f010108d:	f0 
f010108e:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
f0101095:	00 
f0101096:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010109d:	e8 f2 ef ff ff       	call   f0100094 <_panic>
f01010a2:	03 75 08             	add    0x8(%ebp),%esi
		*p_pte = (pa + i) | PTE_P | perm;
f01010a5:	0b 75 dc             	or     -0x24(%ebp),%esi
f01010a8:	89 30                	mov    %esi,(%eax)
	for (int i = 0; i < size; i += PGSIZE) {
f01010aa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010b0:	89 de                	mov    %ebx,%esi
f01010b2:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010b5:	77 b2                	ja     f0101069 <boot_map_region+0x21>
}
f01010b7:	83 c4 2c             	add    $0x2c,%esp
f01010ba:	5b                   	pop    %ebx
f01010bb:	5e                   	pop    %esi
f01010bc:	5f                   	pop    %edi
f01010bd:	5d                   	pop    %ebp
f01010be:	c3                   	ret    

f01010bf <page_lookup>:
{
f01010bf:	55                   	push   %ebp
f01010c0:	89 e5                	mov    %esp,%ebp
f01010c2:	53                   	push   %ebx
f01010c3:	83 ec 14             	sub    $0x14,%esp
f01010c6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *p_pte = pgdir_walk(pgdir, va, 0);			// Lookup a page, not create a page
f01010c9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010d0:	00 
f01010d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01010db:	89 04 24             	mov    %eax,(%esp)
f01010de:	e8 7c fe ff ff       	call   f0100f5f <pgdir_walk>
	if (!p_pte) {												// If mapping does not exist, return NULL
f01010e3:	85 c0                	test   %eax,%eax
f01010e5:	74 3a                	je     f0101121 <page_lookup+0x62>
	if (pte_store) {											// If found, store p_pte into pte_store
f01010e7:	85 db                	test   %ebx,%ebx
f01010e9:	74 02                	je     f01010ed <page_lookup+0x2e>
		*pte_store = p_pte;
f01010eb:	89 03                	mov    %eax,(%ebx)
	return (struct PageInfo *) pa2page(PTE_ADDR(*p_pte));
f01010ed:	8b 00                	mov    (%eax),%eax
	if (PGNUM(pa) >= npages)
f01010ef:	c1 e8 0c             	shr    $0xc,%eax
f01010f2:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f01010f8:	72 1c                	jb     f0101116 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01010fa:	c7 44 24 08 50 44 10 	movl   $0xf0104450,0x8(%esp)
f0101101:	f0 
f0101102:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101109:	00 
f010110a:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0101111:	e8 7e ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101116:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
f010111c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010111f:	eb 05                	jmp    f0101126 <page_lookup+0x67>
		return NULL;
f0101121:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101126:	83 c4 14             	add    $0x14,%esp
f0101129:	5b                   	pop    %ebx
f010112a:	5d                   	pop    %ebp
f010112b:	c3                   	ret    

f010112c <page_remove>:
{
f010112c:	55                   	push   %ebp
f010112d:	89 e5                	mov    %esp,%ebp
f010112f:	53                   	push   %ebx
f0101130:	83 ec 24             	sub    $0x24,%esp
f0101133:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pg = page_lookup(pgdir, va, &p_pte);	// Lookup a page
f0101136:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101139:	89 44 24 08          	mov    %eax,0x8(%esp)
f010113d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101141:	8b 45 08             	mov    0x8(%ebp),%eax
f0101144:	89 04 24             	mov    %eax,(%esp)
f0101147:	e8 73 ff ff ff       	call   f01010bf <page_lookup>
	if (!pg || !(*p_pte & PTE_P)) {								// If page is not found or don't exist
f010114c:	85 c0                	test   %eax,%eax
f010114e:	74 1c                	je     f010116c <page_remove+0x40>
f0101150:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101153:	f6 02 01             	testb  $0x1,(%edx)
f0101156:	74 14                	je     f010116c <page_remove+0x40>
	page_decref(pg); 				// Ref count decrement on the physical page
f0101158:	89 04 24             	mov    %eax,(%esp)
f010115b:	e8 dc fd ff ff       	call   f0100f3c <page_decref>
	*p_pte = 0;
f0101160:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101163:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101169:	0f 01 3b             	invlpg (%ebx)
}
f010116c:	83 c4 24             	add    $0x24,%esp
f010116f:	5b                   	pop    %ebx
f0101170:	5d                   	pop    %ebp
f0101171:	c3                   	ret    

f0101172 <page_insert>:
{
f0101172:	55                   	push   %ebp
f0101173:	89 e5                	mov    %esp,%ebp
f0101175:	57                   	push   %edi
f0101176:	56                   	push   %esi
f0101177:	53                   	push   %ebx
f0101178:	83 ec 1c             	sub    $0x1c,%esp
f010117b:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *p_pte = pgdir_walk(pgdir, va, 1);		// Create the page
f010117e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101185:	00 
f0101186:	8b 45 10             	mov    0x10(%ebp),%eax
f0101189:	89 44 24 04          	mov    %eax,0x4(%esp)
f010118d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101190:	89 04 24             	mov    %eax,(%esp)
f0101193:	e8 c7 fd ff ff       	call   f0100f5f <pgdir_walk>
f0101198:	89 c3                	mov    %eax,%ebx
	if (!p_pte) {											// If page is not allocated
f010119a:	85 c0                	test   %eax,%eax
f010119c:	74 5c                	je     f01011fa <page_insert+0x88>
	return (pp - pages) << PGSHIFT;
f010119e:	89 f7                	mov    %esi,%edi
f01011a0:	2b 3d 70 79 11 f0    	sub    0xf0117970,%edi
f01011a6:	c1 ff 03             	sar    $0x3,%edi
f01011a9:	c1 e7 0c             	shl    $0xc,%edi
		if (*p_pte & PTE_P)	{							// If page valid, and collide, remove it
f01011ac:	8b 00                	mov    (%eax),%eax
f01011ae:	a8 01                	test   $0x1,%al
f01011b0:	74 32                	je     f01011e4 <page_insert+0x72>
			if (pa == PTE_ADDR(*p_pte)) {				// Check if same pp inserted at same va
f01011b2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01011b7:	39 f8                	cmp    %edi,%eax
f01011b9:	75 11                	jne    f01011cc <page_insert+0x5a>
				*p_pte = pa | perm | PTE_P;
f01011bb:	8b 55 14             	mov    0x14(%ebp),%edx
f01011be:	83 ca 01             	or     $0x1,%edx
f01011c1:	09 d0                	or     %edx,%eax
f01011c3:	89 03                	mov    %eax,(%ebx)
				return 0;
f01011c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ca:	eb 33                	jmp    f01011ff <page_insert+0x8d>
f01011cc:	8b 45 10             	mov    0x10(%ebp),%eax
f01011cf:	0f 01 38             	invlpg (%eax)
			page_remove(pgdir, va);
f01011d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01011d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01011dc:	89 04 24             	mov    %eax,(%esp)
f01011df:	e8 48 ff ff ff       	call   f010112c <page_remove>
		pp->pp_ref++;										// Avoid corner case
f01011e4:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		*p_pte = pa | perm | PTE_P;					// Set permission
f01011e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ec:	83 c8 01             	or     $0x1,%eax
f01011ef:	09 c7                	or     %eax,%edi
f01011f1:	89 3b                	mov    %edi,(%ebx)
		return 0;											// Return on success
f01011f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f8:	eb 05                	jmp    f01011ff <page_insert+0x8d>
		return -E_NO_MEM;
f01011fa:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01011ff:	83 c4 1c             	add    $0x1c,%esp
f0101202:	5b                   	pop    %ebx
f0101203:	5e                   	pop    %esi
f0101204:	5f                   	pop    %edi
f0101205:	5d                   	pop    %ebp
f0101206:	c3                   	ret    

f0101207 <mem_init>:
{
f0101207:	55                   	push   %ebp
f0101208:	89 e5                	mov    %esp,%ebp
f010120a:	57                   	push   %edi
f010120b:	56                   	push   %esi
f010120c:	53                   	push   %ebx
f010120d:	83 ec 4c             	sub    $0x4c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f0101210:	b8 15 00 00 00       	mov    $0x15,%eax
f0101215:	e8 87 f7 ff ff       	call   f01009a1 <nvram_read>
f010121a:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010121c:	b8 17 00 00 00       	mov    $0x17,%eax
f0101221:	e8 7b f7 ff ff       	call   f01009a1 <nvram_read>
f0101226:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101228:	b8 34 00 00 00       	mov    $0x34,%eax
f010122d:	e8 6f f7 ff ff       	call   f01009a1 <nvram_read>
f0101232:	c1 e0 06             	shl    $0x6,%eax
f0101235:	89 c2                	mov    %eax,%edx
		totalmem = 16 * 1024 + ext16mem;
f0101237:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	if (ext16mem)
f010123d:	85 d2                	test   %edx,%edx
f010123f:	75 0b                	jne    f010124c <mem_init+0x45>
		totalmem = 1 * 1024 + extmem;
f0101241:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101247:	85 f6                	test   %esi,%esi
f0101249:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f010124c:	89 c2                	mov    %eax,%edx
f010124e:	c1 ea 02             	shr    $0x2,%edx
f0101251:	89 15 68 79 11 f0    	mov    %edx,0xf0117968
	npages_basemem = basemem / (PGSIZE / 1024);
f0101257:	89 da                	mov    %ebx,%edx
f0101259:	c1 ea 02             	shr    $0x2,%edx
f010125c:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101262:	89 c2                	mov    %eax,%edx
f0101264:	29 da                	sub    %ebx,%edx
f0101266:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010126a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010126e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101272:	c7 04 24 70 44 10 f0 	movl   $0xf0104470,(%esp)
f0101279:	e8 2b 1b 00 00       	call   f0102da9 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010127e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101283:	e8 c8 f6 ff ff       	call   f0100950 <boot_alloc>
f0101288:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(kern_pgdir, 0, PGSIZE);
f010128d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101294:	00 
f0101295:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010129c:	00 
f010129d:	89 04 24             	mov    %eax,(%esp)
f01012a0:	e8 72 26 00 00       	call   f0103917 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012a5:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	if ((uint32_t)kva < KERNBASE)
f01012aa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012af:	77 20                	ja     f01012d1 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b5:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f01012bc:	f0 
f01012bd:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
f01012c4:	00 
f01012c5:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01012cc:	e8 c3 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012d1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012d7:	83 ca 05             	or     $0x5,%edx
f01012da:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));  // Allocate an array of npages
f01012e0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01012e5:	c1 e0 03             	shl    $0x3,%eax
f01012e8:	e8 63 f6 ff ff       	call   f0100950 <boot_alloc>
f01012ed:	a3 70 79 11 f0       	mov    %eax,0xf0117970
	memset(pages, 0, (sizeof(struct PageInfo) * npages));								// Set pages to 0
f01012f2:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01012f8:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012ff:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101303:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010130a:	00 
f010130b:	89 04 24             	mov    %eax,(%esp)
f010130e:	e8 04 26 00 00       	call   f0103917 <memset>
	page_init();
f0101313:	e8 bf fa ff ff       	call   f0100dd7 <page_init>
	check_page_free_list(1);
f0101318:	b8 01 00 00 00       	mov    $0x1,%eax
f010131d:	e8 5e f7 ff ff       	call   f0100a80 <check_page_free_list>
	if (!pages)
f0101322:	83 3d 70 79 11 f0 00 	cmpl   $0x0,0xf0117970
f0101329:	75 1c                	jne    f0101347 <mem_init+0x140>
		panic("'pages' is a null pointer!");
f010132b:	c7 44 24 08 72 4b 10 	movl   $0xf0104b72,0x8(%esp)
f0101332:	f0 
f0101333:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f010133a:	00 
f010133b:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101342:	e8 4d ed ff ff       	call   f0100094 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101347:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010134c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101351:	eb 05                	jmp    f0101358 <mem_init+0x151>
		++nfree;
f0101353:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101356:	8b 00                	mov    (%eax),%eax
f0101358:	85 c0                	test   %eax,%eax
f010135a:	75 f7                	jne    f0101353 <mem_init+0x14c>
	assert((pp0 = page_alloc(0)));
f010135c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101363:	e8 09 fb ff ff       	call   f0100e71 <page_alloc>
f0101368:	89 c7                	mov    %eax,%edi
f010136a:	85 c0                	test   %eax,%eax
f010136c:	75 24                	jne    f0101392 <mem_init+0x18b>
f010136e:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f0101375:	f0 
f0101376:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010137d:	f0 
f010137e:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101385:	00 
f0101386:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010138d:	e8 02 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101392:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101399:	e8 d3 fa ff ff       	call   f0100e71 <page_alloc>
f010139e:	89 c6                	mov    %eax,%esi
f01013a0:	85 c0                	test   %eax,%eax
f01013a2:	75 24                	jne    f01013c8 <mem_init+0x1c1>
f01013a4:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f01013ab:	f0 
f01013ac:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01013b3:	f0 
f01013b4:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01013bb:	00 
f01013bc:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01013c3:	e8 cc ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cf:	e8 9d fa ff ff       	call   f0100e71 <page_alloc>
f01013d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013d7:	85 c0                	test   %eax,%eax
f01013d9:	75 24                	jne    f01013ff <mem_init+0x1f8>
f01013db:	c7 44 24 0c b9 4b 10 	movl   $0xf0104bb9,0xc(%esp)
f01013e2:	f0 
f01013e3:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01013ea:	f0 
f01013eb:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f01013f2:	00 
f01013f3:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01013fa:	e8 95 ec ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f01013ff:	39 f7                	cmp    %esi,%edi
f0101401:	75 24                	jne    f0101427 <mem_init+0x220>
f0101403:	c7 44 24 0c cf 4b 10 	movl   $0xf0104bcf,0xc(%esp)
f010140a:	f0 
f010140b:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101412:	f0 
f0101413:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f010141a:	00 
f010141b:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101422:	e8 6d ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101427:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010142a:	39 c6                	cmp    %eax,%esi
f010142c:	74 04                	je     f0101432 <mem_init+0x22b>
f010142e:	39 c7                	cmp    %eax,%edi
f0101430:	75 24                	jne    f0101456 <mem_init+0x24f>
f0101432:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0101439:	f0 
f010143a:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101441:	f0 
f0101442:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f0101449:	00 
f010144a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101451:	e8 3e ec ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0101456:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010145c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101461:	c1 e0 0c             	shl    $0xc,%eax
f0101464:	89 f9                	mov    %edi,%ecx
f0101466:	29 d1                	sub    %edx,%ecx
f0101468:	c1 f9 03             	sar    $0x3,%ecx
f010146b:	c1 e1 0c             	shl    $0xc,%ecx
f010146e:	39 c1                	cmp    %eax,%ecx
f0101470:	72 24                	jb     f0101496 <mem_init+0x28f>
f0101472:	c7 44 24 0c e1 4b 10 	movl   $0xf0104be1,0xc(%esp)
f0101479:	f0 
f010147a:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101481:	f0 
f0101482:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0101489:	00 
f010148a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101491:	e8 fe eb ff ff       	call   f0100094 <_panic>
f0101496:	89 f1                	mov    %esi,%ecx
f0101498:	29 d1                	sub    %edx,%ecx
f010149a:	c1 f9 03             	sar    $0x3,%ecx
f010149d:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014a0:	39 c8                	cmp    %ecx,%eax
f01014a2:	77 24                	ja     f01014c8 <mem_init+0x2c1>
f01014a4:	c7 44 24 0c fe 4b 10 	movl   $0xf0104bfe,0xc(%esp)
f01014ab:	f0 
f01014ac:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f01014bb:	00 
f01014bc:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01014c3:	e8 cc eb ff ff       	call   f0100094 <_panic>
f01014c8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014cb:	29 d1                	sub    %edx,%ecx
f01014cd:	89 ca                	mov    %ecx,%edx
f01014cf:	c1 fa 03             	sar    $0x3,%edx
f01014d2:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014d5:	39 d0                	cmp    %edx,%eax
f01014d7:	77 24                	ja     f01014fd <mem_init+0x2f6>
f01014d9:	c7 44 24 0c 1b 4c 10 	movl   $0xf0104c1b,0xc(%esp)
f01014e0:	f0 
f01014e1:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01014e8:	f0 
f01014e9:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f01014f0:	00 
f01014f1:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01014f8:	e8 97 eb ff ff       	call   f0100094 <_panic>
	fl = page_free_list;
f01014fd:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101502:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101505:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010150c:	00 00 00 
	assert(!page_alloc(0));
f010150f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101516:	e8 56 f9 ff ff       	call   f0100e71 <page_alloc>
f010151b:	85 c0                	test   %eax,%eax
f010151d:	74 24                	je     f0101543 <mem_init+0x33c>
f010151f:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0101526:	f0 
f0101527:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010152e:	f0 
f010152f:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101536:	00 
f0101537:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010153e:	e8 51 eb ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0101543:	89 3c 24             	mov    %edi,(%esp)
f0101546:	e8 b1 f9 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f010154b:	89 34 24             	mov    %esi,(%esp)
f010154e:	e8 a9 f9 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f0101553:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101556:	89 04 24             	mov    %eax,(%esp)
f0101559:	e8 9e f9 ff ff       	call   f0100efc <page_free>
	assert((pp0 = page_alloc(0)));
f010155e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101565:	e8 07 f9 ff ff       	call   f0100e71 <page_alloc>
f010156a:	89 c6                	mov    %eax,%esi
f010156c:	85 c0                	test   %eax,%eax
f010156e:	75 24                	jne    f0101594 <mem_init+0x38d>
f0101570:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f0101577:	f0 
f0101578:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010157f:	f0 
f0101580:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101587:	00 
f0101588:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010158f:	e8 00 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101594:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159b:	e8 d1 f8 ff ff       	call   f0100e71 <page_alloc>
f01015a0:	89 c7                	mov    %eax,%edi
f01015a2:	85 c0                	test   %eax,%eax
f01015a4:	75 24                	jne    f01015ca <mem_init+0x3c3>
f01015a6:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f01015ad:	f0 
f01015ae:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01015b5:	f0 
f01015b6:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01015bd:	00 
f01015be:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01015c5:	e8 ca ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d1:	e8 9b f8 ff ff       	call   f0100e71 <page_alloc>
f01015d6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	75 24                	jne    f0101601 <mem_init+0x3fa>
f01015dd:	c7 44 24 0c b9 4b 10 	movl   $0xf0104bb9,0xc(%esp)
f01015e4:	f0 
f01015e5:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01015ec:	f0 
f01015ed:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01015f4:	00 
f01015f5:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01015fc:	e8 93 ea ff ff       	call   f0100094 <_panic>
	assert(pp1 && pp1 != pp0);
f0101601:	39 fe                	cmp    %edi,%esi
f0101603:	75 24                	jne    f0101629 <mem_init+0x422>
f0101605:	c7 44 24 0c cf 4b 10 	movl   $0xf0104bcf,0xc(%esp)
f010160c:	f0 
f010160d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101614:	f0 
f0101615:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f010161c:	00 
f010161d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101624:	e8 6b ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101629:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010162c:	39 c7                	cmp    %eax,%edi
f010162e:	74 04                	je     f0101634 <mem_init+0x42d>
f0101630:	39 c6                	cmp    %eax,%esi
f0101632:	75 24                	jne    f0101658 <mem_init+0x451>
f0101634:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f010163b:	f0 
f010163c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101643:	f0 
f0101644:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f010164b:	00 
f010164c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101653:	e8 3c ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101658:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010165f:	e8 0d f8 ff ff       	call   f0100e71 <page_alloc>
f0101664:	85 c0                	test   %eax,%eax
f0101666:	74 24                	je     f010168c <mem_init+0x485>
f0101668:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f010166f:	f0 
f0101670:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101677:	f0 
f0101678:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f010167f:	00 
f0101680:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101687:	e8 08 ea ff ff       	call   f0100094 <_panic>
f010168c:	89 f0                	mov    %esi,%eax
f010168e:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101694:	c1 f8 03             	sar    $0x3,%eax
f0101697:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010169a:	89 c2                	mov    %eax,%edx
f010169c:	c1 ea 0c             	shr    $0xc,%edx
f010169f:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01016a5:	72 20                	jb     f01016c7 <mem_init+0x4c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016ab:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f01016b2:	f0 
f01016b3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01016ba:	00 
f01016bb:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f01016c2:	e8 cd e9 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f01016c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016ce:	00 
f01016cf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016d6:	00 
	return (void *)(pa + KERNBASE);
f01016d7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016dc:	89 04 24             	mov    %eax,(%esp)
f01016df:	e8 33 22 00 00       	call   f0103917 <memset>
	page_free(pp0);
f01016e4:	89 34 24             	mov    %esi,(%esp)
f01016e7:	e8 10 f8 ff ff       	call   f0100efc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016ec:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016f3:	e8 79 f7 ff ff       	call   f0100e71 <page_alloc>
f01016f8:	85 c0                	test   %eax,%eax
f01016fa:	75 24                	jne    f0101720 <mem_init+0x519>
f01016fc:	c7 44 24 0c 47 4c 10 	movl   $0xf0104c47,0xc(%esp)
f0101703:	f0 
f0101704:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010170b:	f0 
f010170c:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0101713:	00 
f0101714:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010171b:	e8 74 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101720:	39 c6                	cmp    %eax,%esi
f0101722:	74 24                	je     f0101748 <mem_init+0x541>
f0101724:	c7 44 24 0c 65 4c 10 	movl   $0xf0104c65,0xc(%esp)
f010172b:	f0 
f010172c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101733:	f0 
f0101734:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f010173b:	00 
f010173c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101743:	e8 4c e9 ff ff       	call   f0100094 <_panic>
	return (pp - pages) << PGSHIFT;
f0101748:	89 f0                	mov    %esi,%eax
f010174a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101750:	c1 f8 03             	sar    $0x3,%eax
f0101753:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101756:	89 c2                	mov    %eax,%edx
f0101758:	c1 ea 0c             	shr    $0xc,%edx
f010175b:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0101761:	72 20                	jb     f0101783 <mem_init+0x57c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101763:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101767:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f010176e:	f0 
f010176f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101776:	00 
f0101777:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f010177e:	e8 11 e9 ff ff       	call   f0100094 <_panic>
f0101783:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101789:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
		assert(c[i] == 0);
f010178f:	80 38 00             	cmpb   $0x0,(%eax)
f0101792:	74 24                	je     f01017b8 <mem_init+0x5b1>
f0101794:	c7 44 24 0c 75 4c 10 	movl   $0xf0104c75,0xc(%esp)
f010179b:	f0 
f010179c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01017a3:	f0 
f01017a4:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f01017ab:	00 
f01017ac:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01017b3:	e8 dc e8 ff ff       	call   f0100094 <_panic>
f01017b8:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017bb:	39 d0                	cmp    %edx,%eax
f01017bd:	75 d0                	jne    f010178f <mem_init+0x588>
	page_free_list = fl;
f01017bf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017c2:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	page_free(pp0);
f01017c7:	89 34 24             	mov    %esi,(%esp)
f01017ca:	e8 2d f7 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f01017cf:	89 3c 24             	mov    %edi,(%esp)
f01017d2:	e8 25 f7 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f01017d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017da:	89 04 24             	mov    %eax,(%esp)
f01017dd:	e8 1a f7 ff ff       	call   f0100efc <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017e2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01017e7:	eb 05                	jmp    f01017ee <mem_init+0x5e7>
		--nfree;
f01017e9:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017ec:	8b 00                	mov    (%eax),%eax
f01017ee:	85 c0                	test   %eax,%eax
f01017f0:	75 f7                	jne    f01017e9 <mem_init+0x5e2>
	assert(nfree == 0);
f01017f2:	85 db                	test   %ebx,%ebx
f01017f4:	74 24                	je     f010181a <mem_init+0x613>
f01017f6:	c7 44 24 0c 7f 4c 10 	movl   $0xf0104c7f,0xc(%esp)
f01017fd:	f0 
f01017fe:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101805:	f0 
f0101806:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f010180d:	00 
f010180e:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101815:	e8 7a e8 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f010181a:	c7 04 24 f0 44 10 f0 	movl   $0xf01044f0,(%esp)
f0101821:	e8 83 15 00 00       	call   f0102da9 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101826:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010182d:	e8 3f f6 ff ff       	call   f0100e71 <page_alloc>
f0101832:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101835:	85 c0                	test   %eax,%eax
f0101837:	75 24                	jne    f010185d <mem_init+0x656>
f0101839:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f0101840:	f0 
f0101841:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101848:	f0 
f0101849:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101850:	00 
f0101851:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101858:	e8 37 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010185d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101864:	e8 08 f6 ff ff       	call   f0100e71 <page_alloc>
f0101869:	89 c3                	mov    %eax,%ebx
f010186b:	85 c0                	test   %eax,%eax
f010186d:	75 24                	jne    f0101893 <mem_init+0x68c>
f010186f:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f0101876:	f0 
f0101877:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010187e:	f0 
f010187f:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101886:	00 
f0101887:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010188e:	e8 01 e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101893:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010189a:	e8 d2 f5 ff ff       	call   f0100e71 <page_alloc>
f010189f:	89 c6                	mov    %eax,%esi
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	75 24                	jne    f01018c9 <mem_init+0x6c2>
f01018a5:	c7 44 24 0c b9 4b 10 	movl   $0xf0104bb9,0xc(%esp)
f01018ac:	f0 
f01018ad:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01018b4:	f0 
f01018b5:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f01018bc:	00 
f01018bd:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01018c4:	e8 cb e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018c9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018cc:	75 24                	jne    f01018f2 <mem_init+0x6eb>
f01018ce:	c7 44 24 0c cf 4b 10 	movl   $0xf0104bcf,0xc(%esp)
f01018d5:	f0 
f01018d6:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01018dd:	f0 
f01018de:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01018e5:	00 
f01018e6:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01018ed:	e8 a2 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f2:	39 c3                	cmp    %eax,%ebx
f01018f4:	74 05                	je     f01018fb <mem_init+0x6f4>
f01018f6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018f9:	75 24                	jne    f010191f <mem_init+0x718>
f01018fb:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0101902:	f0 
f0101903:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010190a:	f0 
f010190b:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101912:	00 
f0101913:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010191a:	e8 75 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010191f:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101924:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101927:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010192e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101931:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101938:	e8 34 f5 ff ff       	call   f0100e71 <page_alloc>
f010193d:	85 c0                	test   %eax,%eax
f010193f:	74 24                	je     f0101965 <mem_init+0x75e>
f0101941:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0101948:	f0 
f0101949:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101950:	f0 
f0101951:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0101958:	00 
f0101959:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101960:	e8 2f e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101965:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101968:	89 44 24 08          	mov    %eax,0x8(%esp)
f010196c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101973:	00 
f0101974:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101979:	89 04 24             	mov    %eax,(%esp)
f010197c:	e8 3e f7 ff ff       	call   f01010bf <page_lookup>
f0101981:	85 c0                	test   %eax,%eax
f0101983:	74 24                	je     f01019a9 <mem_init+0x7a2>
f0101985:	c7 44 24 0c 10 45 10 	movl   $0xf0104510,0xc(%esp)
f010198c:	f0 
f010198d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101994:	f0 
f0101995:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f010199c:	00 
f010199d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01019a4:	e8 eb e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019a9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019b0:	00 
f01019b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019b8:	00 
f01019b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019bd:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01019c2:	89 04 24             	mov    %eax,(%esp)
f01019c5:	e8 a8 f7 ff ff       	call   f0101172 <page_insert>
f01019ca:	85 c0                	test   %eax,%eax
f01019cc:	78 24                	js     f01019f2 <mem_init+0x7eb>
f01019ce:	c7 44 24 0c 48 45 10 	movl   $0xf0104548,0xc(%esp)
f01019d5:	f0 
f01019d6:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01019dd:	f0 
f01019de:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f01019e5:	00 
f01019e6:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01019ed:	e8 a2 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f5:	89 04 24             	mov    %eax,(%esp)
f01019f8:	e8 ff f4 ff ff       	call   f0100efc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019fd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a04:	00 
f0101a05:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a0c:	00 
f0101a0d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a11:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a16:	89 04 24             	mov    %eax,(%esp)
f0101a19:	e8 54 f7 ff ff       	call   f0101172 <page_insert>
f0101a1e:	85 c0                	test   %eax,%eax
f0101a20:	74 24                	je     f0101a46 <mem_init+0x83f>
f0101a22:	c7 44 24 0c 78 45 10 	movl   $0xf0104578,0xc(%esp)
f0101a29:	f0 
f0101a2a:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101a31:	f0 
f0101a32:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101a39:	00 
f0101a3a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101a41:	e8 4e e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a46:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
	return (pp - pages) << PGSHIFT;
f0101a4c:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f0101a51:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a54:	8b 17                	mov    (%edi),%edx
f0101a56:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a5c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a5f:	29 c1                	sub    %eax,%ecx
f0101a61:	89 c8                	mov    %ecx,%eax
f0101a63:	c1 f8 03             	sar    $0x3,%eax
f0101a66:	c1 e0 0c             	shl    $0xc,%eax
f0101a69:	39 c2                	cmp    %eax,%edx
f0101a6b:	74 24                	je     f0101a91 <mem_init+0x88a>
f0101a6d:	c7 44 24 0c a8 45 10 	movl   $0xf01045a8,0xc(%esp)
f0101a74:	f0 
f0101a75:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101a7c:	f0 
f0101a7d:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101a84:	00 
f0101a85:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101a8c:	e8 03 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a91:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a96:	89 f8                	mov    %edi,%eax
f0101a98:	e8 74 ef ff ff       	call   f0100a11 <check_va2pa>
f0101a9d:	89 da                	mov    %ebx,%edx
f0101a9f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101aa2:	c1 fa 03             	sar    $0x3,%edx
f0101aa5:	c1 e2 0c             	shl    $0xc,%edx
f0101aa8:	39 d0                	cmp    %edx,%eax
f0101aaa:	74 24                	je     f0101ad0 <mem_init+0x8c9>
f0101aac:	c7 44 24 0c d0 45 10 	movl   $0xf01045d0,0xc(%esp)
f0101ab3:	f0 
f0101ab4:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101abb:	f0 
f0101abc:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101ac3:	00 
f0101ac4:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101acb:	e8 c4 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101ad0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ad5:	74 24                	je     f0101afb <mem_init+0x8f4>
f0101ad7:	c7 44 24 0c 8a 4c 10 	movl   $0xf0104c8a,0xc(%esp)
f0101ade:	f0 
f0101adf:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101ae6:	f0 
f0101ae7:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101aee:	00 
f0101aef:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101af6:	e8 99 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101afb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101afe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b03:	74 24                	je     f0101b29 <mem_init+0x922>
f0101b05:	c7 44 24 0c 9b 4c 10 	movl   $0xf0104c9b,0xc(%esp)
f0101b0c:	f0 
f0101b0d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101b14:	f0 
f0101b15:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101b1c:	00 
f0101b1d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101b24:	e8 6b e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b29:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b30:	00 
f0101b31:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b38:	00 
f0101b39:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b3d:	89 3c 24             	mov    %edi,(%esp)
f0101b40:	e8 2d f6 ff ff       	call   f0101172 <page_insert>
f0101b45:	85 c0                	test   %eax,%eax
f0101b47:	74 24                	je     f0101b6d <mem_init+0x966>
f0101b49:	c7 44 24 0c 00 46 10 	movl   $0xf0104600,0xc(%esp)
f0101b50:	f0 
f0101b51:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101b58:	f0 
f0101b59:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101b60:	00 
f0101b61:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101b68:	e8 27 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b6d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b72:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101b77:	e8 95 ee ff ff       	call   f0100a11 <check_va2pa>
f0101b7c:	89 f2                	mov    %esi,%edx
f0101b7e:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101b84:	c1 fa 03             	sar    $0x3,%edx
f0101b87:	c1 e2 0c             	shl    $0xc,%edx
f0101b8a:	39 d0                	cmp    %edx,%eax
f0101b8c:	74 24                	je     f0101bb2 <mem_init+0x9ab>
f0101b8e:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f0101b95:	f0 
f0101b96:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101b9d:	f0 
f0101b9e:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101ba5:	00 
f0101ba6:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101bad:	e8 e2 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bb2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb7:	74 24                	je     f0101bdd <mem_init+0x9d6>
f0101bb9:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f0101bc0:	f0 
f0101bc1:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101bc8:	f0 
f0101bc9:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101bd0:	00 
f0101bd1:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101bd8:	e8 b7 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bdd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101be4:	e8 88 f2 ff ff       	call   f0100e71 <page_alloc>
f0101be9:	85 c0                	test   %eax,%eax
f0101beb:	74 24                	je     f0101c11 <mem_init+0xa0a>
f0101bed:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0101bf4:	f0 
f0101bf5:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101bfc:	f0 
f0101bfd:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101c04:	00 
f0101c05:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101c0c:	e8 83 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c11:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c18:	00 
f0101c19:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c20:	00 
f0101c21:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c25:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101c2a:	89 04 24             	mov    %eax,(%esp)
f0101c2d:	e8 40 f5 ff ff       	call   f0101172 <page_insert>
f0101c32:	85 c0                	test   %eax,%eax
f0101c34:	74 24                	je     f0101c5a <mem_init+0xa53>
f0101c36:	c7 44 24 0c 00 46 10 	movl   $0xf0104600,0xc(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101c4d:	00 
f0101c4e:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101c55:	e8 3a e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c5f:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101c64:	e8 a8 ed ff ff       	call   f0100a11 <check_va2pa>
f0101c69:	89 f2                	mov    %esi,%edx
f0101c6b:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101c71:	c1 fa 03             	sar    $0x3,%edx
f0101c74:	c1 e2 0c             	shl    $0xc,%edx
f0101c77:	39 d0                	cmp    %edx,%eax
f0101c79:	74 24                	je     f0101c9f <mem_init+0xa98>
f0101c7b:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f0101c82:	f0 
f0101c83:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101c8a:	f0 
f0101c8b:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101c92:	00 
f0101c93:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101c9a:	e8 f5 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c9f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ca4:	74 24                	je     f0101cca <mem_init+0xac3>
f0101ca6:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f0101cad:	f0 
f0101cae:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101cb5:	f0 
f0101cb6:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101cbd:	00 
f0101cbe:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101cc5:	e8 ca e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cd1:	e8 9b f1 ff ff       	call   f0100e71 <page_alloc>
f0101cd6:	85 c0                	test   %eax,%eax
f0101cd8:	74 24                	je     f0101cfe <mem_init+0xaf7>
f0101cda:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0101ce1:	f0 
f0101ce2:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101ce9:	f0 
f0101cea:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101cf1:	00 
f0101cf2:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101cf9:	e8 96 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cfe:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101d04:	8b 02                	mov    (%edx),%eax
f0101d06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d0b:	89 c1                	mov    %eax,%ecx
f0101d0d:	c1 e9 0c             	shr    $0xc,%ecx
f0101d10:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0101d16:	72 20                	jb     f0101d38 <mem_init+0xb31>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d18:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d1c:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0101d23:	f0 
f0101d24:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101d2b:	00 
f0101d2c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101d33:	e8 5c e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d38:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d3d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d40:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d47:	00 
f0101d48:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d4f:	00 
f0101d50:	89 14 24             	mov    %edx,(%esp)
f0101d53:	e8 07 f2 ff ff       	call   f0100f5f <pgdir_walk>
f0101d58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101d5b:	8d 57 04             	lea    0x4(%edi),%edx
f0101d5e:	39 d0                	cmp    %edx,%eax
f0101d60:	74 24                	je     f0101d86 <mem_init+0xb7f>
f0101d62:	c7 44 24 0c 6c 46 10 	movl   $0xf010466c,0xc(%esp)
f0101d69:	f0 
f0101d6a:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101d71:	f0 
f0101d72:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101d79:	00 
f0101d7a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101d81:	e8 0e e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d86:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d8d:	00 
f0101d8e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d95:	00 
f0101d96:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d9a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101d9f:	89 04 24             	mov    %eax,(%esp)
f0101da2:	e8 cb f3 ff ff       	call   f0101172 <page_insert>
f0101da7:	85 c0                	test   %eax,%eax
f0101da9:	74 24                	je     f0101dcf <mem_init+0xbc8>
f0101dab:	c7 44 24 0c ac 46 10 	movl   $0xf01046ac,0xc(%esp)
f0101db2:	f0 
f0101db3:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101dba:	f0 
f0101dbb:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101dc2:	00 
f0101dc3:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101dca:	e8 c5 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dcf:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0101dd5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dda:	89 f8                	mov    %edi,%eax
f0101ddc:	e8 30 ec ff ff       	call   f0100a11 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101de1:	89 f2                	mov    %esi,%edx
f0101de3:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101de9:	c1 fa 03             	sar    $0x3,%edx
f0101dec:	c1 e2 0c             	shl    $0xc,%edx
f0101def:	39 d0                	cmp    %edx,%eax
f0101df1:	74 24                	je     f0101e17 <mem_init+0xc10>
f0101df3:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f0101dfa:	f0 
f0101dfb:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101e02:	f0 
f0101e03:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101e0a:	00 
f0101e0b:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101e12:	e8 7d e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e17:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e1c:	74 24                	je     f0101e42 <mem_init+0xc3b>
f0101e1e:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101e2d:	f0 
f0101e2e:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101e35:	00 
f0101e36:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101e3d:	e8 52 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e42:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e49:	00 
f0101e4a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e51:	00 
f0101e52:	89 3c 24             	mov    %edi,(%esp)
f0101e55:	e8 05 f1 ff ff       	call   f0100f5f <pgdir_walk>
f0101e5a:	f6 00 04             	testb  $0x4,(%eax)
f0101e5d:	75 24                	jne    f0101e83 <mem_init+0xc7c>
f0101e5f:	c7 44 24 0c ec 46 10 	movl   $0xf01046ec,0xc(%esp)
f0101e66:	f0 
f0101e67:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101e6e:	f0 
f0101e6f:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101e76:	00 
f0101e77:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101e7e:	e8 11 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e83:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101e88:	f6 00 04             	testb  $0x4,(%eax)
f0101e8b:	75 24                	jne    f0101eb1 <mem_init+0xcaa>
f0101e8d:	c7 44 24 0c bd 4c 10 	movl   $0xf0104cbd,0xc(%esp)
f0101e94:	f0 
f0101e95:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101e9c:	f0 
f0101e9d:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101ea4:	00 
f0101ea5:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101eac:	e8 e3 e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101eb1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eb8:	00 
f0101eb9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ec0:	00 
f0101ec1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ec5:	89 04 24             	mov    %eax,(%esp)
f0101ec8:	e8 a5 f2 ff ff       	call   f0101172 <page_insert>
f0101ecd:	85 c0                	test   %eax,%eax
f0101ecf:	74 24                	je     f0101ef5 <mem_init+0xcee>
f0101ed1:	c7 44 24 0c 00 46 10 	movl   $0xf0104600,0xc(%esp)
f0101ed8:	f0 
f0101ed9:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101ee0:	f0 
f0101ee1:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101ee8:	00 
f0101ee9:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101ef0:	e8 9f e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ef5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101efc:	00 
f0101efd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f04:	00 
f0101f05:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101f0a:	89 04 24             	mov    %eax,(%esp)
f0101f0d:	e8 4d f0 ff ff       	call   f0100f5f <pgdir_walk>
f0101f12:	f6 00 02             	testb  $0x2,(%eax)
f0101f15:	75 24                	jne    f0101f3b <mem_init+0xd34>
f0101f17:	c7 44 24 0c 20 47 10 	movl   $0xf0104720,0xc(%esp)
f0101f1e:	f0 
f0101f1f:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101f26:	f0 
f0101f27:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101f2e:	00 
f0101f2f:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101f36:	e8 59 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f3b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f42:	00 
f0101f43:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f4a:	00 
f0101f4b:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101f50:	89 04 24             	mov    %eax,(%esp)
f0101f53:	e8 07 f0 ff ff       	call   f0100f5f <pgdir_walk>
f0101f58:	f6 00 04             	testb  $0x4,(%eax)
f0101f5b:	74 24                	je     f0101f81 <mem_init+0xd7a>
f0101f5d:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101f64:	f0 
f0101f65:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101f6c:	f0 
f0101f6d:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101f74:	00 
f0101f75:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101f7c:	e8 13 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f81:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f88:	00 
f0101f89:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f90:	00 
f0101f91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f98:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101f9d:	89 04 24             	mov    %eax,(%esp)
f0101fa0:	e8 cd f1 ff ff       	call   f0101172 <page_insert>
f0101fa5:	85 c0                	test   %eax,%eax
f0101fa7:	78 24                	js     f0101fcd <mem_init+0xdc6>
f0101fa9:	c7 44 24 0c 8c 47 10 	movl   $0xf010478c,0xc(%esp)
f0101fb0:	f0 
f0101fb1:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0101fb8:	f0 
f0101fb9:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101fc0:	00 
f0101fc1:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0101fc8:	e8 c7 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fcd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fd4:	00 
f0101fd5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fdc:	00 
f0101fdd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fe1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101fe6:	89 04 24             	mov    %eax,(%esp)
f0101fe9:	e8 84 f1 ff ff       	call   f0101172 <page_insert>
f0101fee:	85 c0                	test   %eax,%eax
f0101ff0:	74 24                	je     f0102016 <mem_init+0xe0f>
f0101ff2:	c7 44 24 0c c4 47 10 	movl   $0xf01047c4,0xc(%esp)
f0101ff9:	f0 
f0101ffa:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102001:	f0 
f0102002:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102009:	00 
f010200a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102011:	e8 7e e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102016:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010201d:	00 
f010201e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102025:	00 
f0102026:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010202b:	89 04 24             	mov    %eax,(%esp)
f010202e:	e8 2c ef ff ff       	call   f0100f5f <pgdir_walk>
f0102033:	f6 00 04             	testb  $0x4,(%eax)
f0102036:	74 24                	je     f010205c <mem_init+0xe55>
f0102038:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f010203f:	f0 
f0102040:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102047:	f0 
f0102048:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010204f:	00 
f0102050:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102057:	e8 38 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010205c:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0102062:	ba 00 00 00 00       	mov    $0x0,%edx
f0102067:	89 f8                	mov    %edi,%eax
f0102069:	e8 a3 e9 ff ff       	call   f0100a11 <check_va2pa>
f010206e:	89 c1                	mov    %eax,%ecx
f0102070:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102073:	89 d8                	mov    %ebx,%eax
f0102075:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010207b:	c1 f8 03             	sar    $0x3,%eax
f010207e:	c1 e0 0c             	shl    $0xc,%eax
f0102081:	39 c1                	cmp    %eax,%ecx
f0102083:	74 24                	je     f01020a9 <mem_init+0xea2>
f0102085:	c7 44 24 0c 00 48 10 	movl   $0xf0104800,0xc(%esp)
f010208c:	f0 
f010208d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102094:	f0 
f0102095:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f010209c:	00 
f010209d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01020a4:	e8 eb df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020a9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ae:	89 f8                	mov    %edi,%eax
f01020b0:	e8 5c e9 ff ff       	call   f0100a11 <check_va2pa>
f01020b5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020b8:	74 24                	je     f01020de <mem_init+0xed7>
f01020ba:	c7 44 24 0c 2c 48 10 	movl   $0xf010482c,0xc(%esp)
f01020c1:	f0 
f01020c2:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01020c9:	f0 
f01020ca:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01020d1:	00 
f01020d2:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01020d9:	e8 b6 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020de:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020e3:	74 24                	je     f0102109 <mem_init+0xf02>
f01020e5:	c7 44 24 0c d3 4c 10 	movl   $0xf0104cd3,0xc(%esp)
f01020ec:	f0 
f01020ed:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01020f4:	f0 
f01020f5:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01020fc:	00 
f01020fd:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102104:	e8 8b df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102109:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010210e:	74 24                	je     f0102134 <mem_init+0xf2d>
f0102110:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f0102117:	f0 
f0102118:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010211f:	f0 
f0102120:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102127:	00 
f0102128:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010212f:	e8 60 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102134:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010213b:	e8 31 ed ff ff       	call   f0100e71 <page_alloc>
f0102140:	85 c0                	test   %eax,%eax
f0102142:	74 04                	je     f0102148 <mem_init+0xf41>
f0102144:	39 c6                	cmp    %eax,%esi
f0102146:	74 24                	je     f010216c <mem_init+0xf65>
f0102148:	c7 44 24 0c 5c 48 10 	movl   $0xf010485c,0xc(%esp)
f010214f:	f0 
f0102150:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102157:	f0 
f0102158:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f010215f:	00 
f0102160:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102167:	e8 28 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010216c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102173:	00 
f0102174:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102179:	89 04 24             	mov    %eax,(%esp)
f010217c:	e8 ab ef ff ff       	call   f010112c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102181:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0102187:	ba 00 00 00 00       	mov    $0x0,%edx
f010218c:	89 f8                	mov    %edi,%eax
f010218e:	e8 7e e8 ff ff       	call   f0100a11 <check_va2pa>
f0102193:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102196:	74 24                	je     f01021bc <mem_init+0xfb5>
f0102198:	c7 44 24 0c 80 48 10 	movl   $0xf0104880,0xc(%esp)
f010219f:	f0 
f01021a0:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01021a7:	f0 
f01021a8:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01021af:	00 
f01021b0:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01021b7:	e8 d8 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021bc:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021c1:	89 f8                	mov    %edi,%eax
f01021c3:	e8 49 e8 ff ff       	call   f0100a11 <check_va2pa>
f01021c8:	89 da                	mov    %ebx,%edx
f01021ca:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01021d0:	c1 fa 03             	sar    $0x3,%edx
f01021d3:	c1 e2 0c             	shl    $0xc,%edx
f01021d6:	39 d0                	cmp    %edx,%eax
f01021d8:	74 24                	je     f01021fe <mem_init+0xff7>
f01021da:	c7 44 24 0c 2c 48 10 	movl   $0xf010482c,0xc(%esp)
f01021e1:	f0 
f01021e2:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01021e9:	f0 
f01021ea:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01021f1:	00 
f01021f2:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01021f9:	e8 96 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021fe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102203:	74 24                	je     f0102229 <mem_init+0x1022>
f0102205:	c7 44 24 0c 8a 4c 10 	movl   $0xf0104c8a,0xc(%esp)
f010220c:	f0 
f010220d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102214:	f0 
f0102215:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f010221c:	00 
f010221d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102224:	e8 6b de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102229:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010222e:	74 24                	je     f0102254 <mem_init+0x104d>
f0102230:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f0102237:	f0 
f0102238:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010223f:	f0 
f0102240:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102247:	00 
f0102248:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010224f:	e8 40 de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102254:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010225b:	00 
f010225c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102263:	00 
f0102264:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102268:	89 3c 24             	mov    %edi,(%esp)
f010226b:	e8 02 ef ff ff       	call   f0101172 <page_insert>
f0102270:	85 c0                	test   %eax,%eax
f0102272:	74 24                	je     f0102298 <mem_init+0x1091>
f0102274:	c7 44 24 0c a4 48 10 	movl   $0xf01048a4,0xc(%esp)
f010227b:	f0 
f010227c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102283:	f0 
f0102284:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f010228b:	00 
f010228c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102293:	e8 fc dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102298:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010229d:	75 24                	jne    f01022c3 <mem_init+0x10bc>
f010229f:	c7 44 24 0c f5 4c 10 	movl   $0xf0104cf5,0xc(%esp)
f01022a6:	f0 
f01022a7:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01022ae:	f0 
f01022af:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01022b6:	00 
f01022b7:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01022be:	e8 d1 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01022c3:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022c6:	74 24                	je     f01022ec <mem_init+0x10e5>
f01022c8:	c7 44 24 0c 01 4d 10 	movl   $0xf0104d01,0xc(%esp)
f01022cf:	f0 
f01022d0:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01022d7:	f0 
f01022d8:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01022df:	00 
f01022e0:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01022e7:	e8 a8 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022ec:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022f3:	00 
f01022f4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01022f9:	89 04 24             	mov    %eax,(%esp)
f01022fc:	e8 2b ee ff ff       	call   f010112c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102301:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
f0102307:	ba 00 00 00 00       	mov    $0x0,%edx
f010230c:	89 f8                	mov    %edi,%eax
f010230e:	e8 fe e6 ff ff       	call   f0100a11 <check_va2pa>
f0102313:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102316:	74 24                	je     f010233c <mem_init+0x1135>
f0102318:	c7 44 24 0c 80 48 10 	movl   $0xf0104880,0xc(%esp)
f010231f:	f0 
f0102320:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102327:	f0 
f0102328:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f010232f:	00 
f0102330:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102337:	e8 58 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010233c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102341:	89 f8                	mov    %edi,%eax
f0102343:	e8 c9 e6 ff ff       	call   f0100a11 <check_va2pa>
f0102348:	83 f8 ff             	cmp    $0xffffffff,%eax
f010234b:	74 24                	je     f0102371 <mem_init+0x116a>
f010234d:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f0102354:	f0 
f0102355:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010235c:	f0 
f010235d:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102364:	00 
f0102365:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010236c:	e8 23 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102371:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102376:	74 24                	je     f010239c <mem_init+0x1195>
f0102378:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f010237f:	f0 
f0102380:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102387:	f0 
f0102388:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010238f:	00 
f0102390:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102397:	e8 f8 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010239c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023a1:	74 24                	je     f01023c7 <mem_init+0x11c0>
f01023a3:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01023b2:	f0 
f01023b3:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f01023ba:	00 
f01023bb:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01023c2:	e8 cd dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023ce:	e8 9e ea ff ff       	call   f0100e71 <page_alloc>
f01023d3:	85 c0                	test   %eax,%eax
f01023d5:	74 04                	je     f01023db <mem_init+0x11d4>
f01023d7:	39 c3                	cmp    %eax,%ebx
f01023d9:	74 24                	je     f01023ff <mem_init+0x11f8>
f01023db:	c7 44 24 0c 04 49 10 	movl   $0xf0104904,0xc(%esp)
f01023e2:	f0 
f01023e3:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01023ea:	f0 
f01023eb:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f01023f2:	00 
f01023f3:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01023fa:	e8 95 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102406:	e8 66 ea ff ff       	call   f0100e71 <page_alloc>
f010240b:	85 c0                	test   %eax,%eax
f010240d:	74 24                	je     f0102433 <mem_init+0x122c>
f010240f:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f0102416:	f0 
f0102417:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010241e:	f0 
f010241f:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102426:	00 
f0102427:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010242e:	e8 61 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102433:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102438:	8b 08                	mov    (%eax),%ecx
f010243a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102440:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102443:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0102449:	c1 fa 03             	sar    $0x3,%edx
f010244c:	c1 e2 0c             	shl    $0xc,%edx
f010244f:	39 d1                	cmp    %edx,%ecx
f0102451:	74 24                	je     f0102477 <mem_init+0x1270>
f0102453:	c7 44 24 0c a8 45 10 	movl   $0xf01045a8,0xc(%esp)
f010245a:	f0 
f010245b:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102462:	f0 
f0102463:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010246a:	00 
f010246b:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102472:	e8 1d dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102477:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010247d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102480:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102485:	74 24                	je     f01024ab <mem_init+0x12a4>
f0102487:	c7 44 24 0c 9b 4c 10 	movl   $0xf0104c9b,0xc(%esp)
f010248e:	f0 
f010248f:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102496:	f0 
f0102497:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f010249e:	00 
f010249f:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01024a6:	e8 e9 db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01024ab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024ae:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024b4:	89 04 24             	mov    %eax,(%esp)
f01024b7:	e8 40 ea ff ff       	call   f0100efc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024bc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024c3:	00 
f01024c4:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024cb:	00 
f01024cc:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01024d1:	89 04 24             	mov    %eax,(%esp)
f01024d4:	e8 86 ea ff ff       	call   f0100f5f <pgdir_walk>
f01024d9:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024df:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f01024e5:	8b 7a 04             	mov    0x4(%edx),%edi
f01024e8:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f01024ee:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01024f4:	89 f8                	mov    %edi,%eax
f01024f6:	c1 e8 0c             	shr    $0xc,%eax
f01024f9:	39 c8                	cmp    %ecx,%eax
f01024fb:	72 20                	jb     f010251d <mem_init+0x1316>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024fd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102501:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f0102508:	f0 
f0102509:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0102510:	00 
f0102511:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102518:	e8 77 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010251d:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102523:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102526:	74 24                	je     f010254c <mem_init+0x1345>
f0102528:	c7 44 24 0c 27 4d 10 	movl   $0xf0104d27,0xc(%esp)
f010252f:	f0 
f0102530:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102537:	f0 
f0102538:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f010253f:	00 
f0102540:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102547:	e8 48 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010254c:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102553:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102556:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010255c:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0102562:	c1 f8 03             	sar    $0x3,%eax
f0102565:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102568:	89 c2                	mov    %eax,%edx
f010256a:	c1 ea 0c             	shr    $0xc,%edx
f010256d:	39 d1                	cmp    %edx,%ecx
f010256f:	77 20                	ja     f0102591 <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102571:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102575:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f010257c:	f0 
f010257d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102584:	00 
f0102585:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f010258c:	e8 03 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102591:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102598:	00 
f0102599:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025a0:	00 
	return (void *)(pa + KERNBASE);
f01025a1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025a6:	89 04 24             	mov    %eax,(%esp)
f01025a9:	e8 69 13 00 00       	call   f0103917 <memset>
	page_free(pp0);
f01025ae:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025b1:	89 3c 24             	mov    %edi,(%esp)
f01025b4:	e8 43 e9 ff ff       	call   f0100efc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025b9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025c0:	00 
f01025c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025c8:	00 
f01025c9:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01025ce:	89 04 24             	mov    %eax,(%esp)
f01025d1:	e8 89 e9 ff ff       	call   f0100f5f <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01025d6:	89 fa                	mov    %edi,%edx
f01025d8:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01025de:	c1 fa 03             	sar    $0x3,%edx
f01025e1:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01025e4:	89 d0                	mov    %edx,%eax
f01025e6:	c1 e8 0c             	shr    $0xc,%eax
f01025e9:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f01025ef:	72 20                	jb     f0102611 <mem_init+0x140a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025f5:	c7 44 24 08 e4 42 10 	movl   $0xf01042e4,0x8(%esp)
f01025fc:	f0 
f01025fd:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102604:	00 
f0102605:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f010260c:	e8 83 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102611:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102617:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010261a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102620:	f6 00 01             	testb  $0x1,(%eax)
f0102623:	74 24                	je     f0102649 <mem_init+0x1442>
f0102625:	c7 44 24 0c 3f 4d 10 	movl   $0xf0104d3f,0xc(%esp)
f010262c:	f0 
f010262d:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102634:	f0 
f0102635:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f010263c:	00 
f010263d:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102644:	e8 4b da ff ff       	call   f0100094 <_panic>
f0102649:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f010264c:	39 d0                	cmp    %edx,%eax
f010264e:	75 d0                	jne    f0102620 <mem_init+0x1419>
	kern_pgdir[0] = 0;
f0102650:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102655:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010265b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010265e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102664:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102667:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010266d:	89 04 24             	mov    %eax,(%esp)
f0102670:	e8 87 e8 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f0102675:	89 1c 24             	mov    %ebx,(%esp)
f0102678:	e8 7f e8 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f010267d:	89 34 24             	mov    %esi,(%esp)
f0102680:	e8 77 e8 ff ff       	call   f0100efc <page_free>

	cprintf("check_page() succeeded!\n");
f0102685:	c7 04 24 56 4d 10 f0 	movl   $0xf0104d56,(%esp)
f010268c:	e8 18 07 00 00       	call   f0102da9 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, sizeof(struct PageInfo) * npages, PADDR(pages), PTE_U | PTE_P);
f0102691:	a1 70 79 11 f0       	mov    0xf0117970,%eax
	if ((uint32_t)kva < KERNBASE)
f0102696:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010269b:	77 20                	ja     f01026bd <mem_init+0x14b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010269d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026a1:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f01026a8:	f0 
f01026a9:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
f01026b0:	00 
f01026b1:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01026b8:	e8 d7 d9 ff ff       	call   f0100094 <_panic>
f01026bd:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01026c3:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f01026ca:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01026d1:	00 
	return (physaddr_t)kva - KERNBASE;
f01026d2:	05 00 00 00 10       	add    $0x10000000,%eax
f01026d7:	89 04 24             	mov    %eax,(%esp)
f01026da:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026df:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01026e4:	e8 5f e9 ff ff       	call   f0101048 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01026e9:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f01026ee:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026f4:	77 20                	ja     f0102716 <mem_init+0x150f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026f6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01026fa:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f0102701:	f0 
f0102702:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0102709:	00 
f010270a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102711:	e8 7e d9 ff ff       	call   f0100094 <_panic>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102716:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010271d:	00 
f010271e:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102725:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010272a:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010272f:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102734:	e8 0f e9 ff ff       	call   f0101048 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102739:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102740:	00 
f0102741:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102748:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010274d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102752:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102757:	e8 ec e8 ff ff       	call   f0101048 <boot_map_region>
	pgdir = kern_pgdir;
f010275c:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102762:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102767:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010276a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102771:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102776:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102779:	a1 70 79 11 f0       	mov    0xf0117970,%eax
f010277e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102781:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102784:	05 00 00 00 10       	add    $0x10000000,%eax
f0102789:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f010278c:	be 00 00 00 00       	mov    $0x0,%esi
f0102791:	eb 6d                	jmp    f0102800 <mem_init+0x15f9>
f0102793:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102799:	89 f8                	mov    %edi,%eax
f010279b:	e8 71 e2 ff ff       	call   f0100a11 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01027a0:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f01027a7:	77 23                	ja     f01027cc <mem_init+0x15c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027a9:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027b0:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f01027b7:	f0 
f01027b8:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f01027bf:	00 
f01027c0:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01027c7:	e8 c8 d8 ff ff       	call   f0100094 <_panic>
f01027cc:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01027cf:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01027d2:	39 c2                	cmp    %eax,%edx
f01027d4:	74 24                	je     f01027fa <mem_init+0x15f3>
f01027d6:	c7 44 24 0c 28 49 10 	movl   $0xf0104928,0xc(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01027e5:	f0 
f01027e6:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f01027ed:	00 
f01027ee:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01027f5:	e8 9a d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f01027fa:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102800:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102803:	77 8e                	ja     f0102793 <mem_init+0x158c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102805:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102808:	c1 e0 0c             	shl    $0xc,%eax
f010280b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010280e:	be 00 00 00 00       	mov    $0x0,%esi
f0102813:	eb 3b                	jmp    f0102850 <mem_init+0x1649>
f0102815:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010281b:	89 f8                	mov    %edi,%eax
f010281d:	e8 ef e1 ff ff       	call   f0100a11 <check_va2pa>
f0102822:	39 c6                	cmp    %eax,%esi
f0102824:	74 24                	je     f010284a <mem_init+0x1643>
f0102826:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f010282d:	f0 
f010282e:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102835:	f0 
f0102836:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f010283d:	00 
f010283e:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102845:	e8 4a d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010284a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102850:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102853:	72 c0                	jb     f0102815 <mem_init+0x160e>
f0102855:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010285a:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102860:	89 f2                	mov    %esi,%edx
f0102862:	89 f8                	mov    %edi,%eax
f0102864:	e8 a8 e1 ff ff       	call   f0100a11 <check_va2pa>
f0102869:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f010286c:	39 d0                	cmp    %edx,%eax
f010286e:	74 24                	je     f0102894 <mem_init+0x168d>
f0102870:	c7 44 24 0c 84 49 10 	movl   $0xf0104984,0xc(%esp)
f0102877:	f0 
f0102878:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010287f:	f0 
f0102880:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0102887:	00 
f0102888:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010288f:	e8 00 d8 ff ff       	call   f0100094 <_panic>
f0102894:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010289a:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01028a0:	75 be                	jne    f0102860 <mem_init+0x1659>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028a2:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01028a7:	89 f8                	mov    %edi,%eax
f01028a9:	e8 63 e1 ff ff       	call   f0100a11 <check_va2pa>
f01028ae:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028b1:	75 0a                	jne    f01028bd <mem_init+0x16b6>
f01028b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01028b8:	e9 f0 00 00 00       	jmp    f01029ad <mem_init+0x17a6>
f01028bd:	c7 44 24 0c cc 49 10 	movl   $0xf01049cc,0xc(%esp)
f01028c4:	f0 
f01028c5:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f01028cc:	f0 
f01028cd:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f01028d4:	00 
f01028d5:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01028dc:	e8 b3 d7 ff ff       	call   f0100094 <_panic>
		switch (i) {
f01028e1:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01028e6:	72 3c                	jb     f0102924 <mem_init+0x171d>
f01028e8:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01028ed:	76 07                	jbe    f01028f6 <mem_init+0x16ef>
f01028ef:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028f4:	75 2e                	jne    f0102924 <mem_init+0x171d>
			assert(pgdir[i] & PTE_P);
f01028f6:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028fa:	0f 85 aa 00 00 00    	jne    f01029aa <mem_init+0x17a3>
f0102900:	c7 44 24 0c 6f 4d 10 	movl   $0xf0104d6f,0xc(%esp)
f0102907:	f0 
f0102908:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010290f:	f0 
f0102910:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0102917:	00 
f0102918:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010291f:	e8 70 d7 ff ff       	call   f0100094 <_panic>
			if (i >= PDX(KERNBASE)) {
f0102924:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102929:	76 55                	jbe    f0102980 <mem_init+0x1779>
				assert(pgdir[i] & PTE_P);
f010292b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010292e:	f6 c2 01             	test   $0x1,%dl
f0102931:	75 24                	jne    f0102957 <mem_init+0x1750>
f0102933:	c7 44 24 0c 6f 4d 10 	movl   $0xf0104d6f,0xc(%esp)
f010293a:	f0 
f010293b:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102942:	f0 
f0102943:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010294a:	00 
f010294b:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102952:	e8 3d d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102957:	f6 c2 02             	test   $0x2,%dl
f010295a:	75 4e                	jne    f01029aa <mem_init+0x17a3>
f010295c:	c7 44 24 0c 80 4d 10 	movl   $0xf0104d80,0xc(%esp)
f0102963:	f0 
f0102964:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f010296b:	f0 
f010296c:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0102973:	00 
f0102974:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f010297b:	e8 14 d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] == 0);
f0102980:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102984:	74 24                	je     f01029aa <mem_init+0x17a3>
f0102986:	c7 44 24 0c 91 4d 10 	movl   $0xf0104d91,0xc(%esp)
f010298d:	f0 
f010298e:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102995:	f0 
f0102996:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f010299d:	00 
f010299e:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01029a5:	e8 ea d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f01029aa:	83 c0 01             	add    $0x1,%eax
f01029ad:	3d 00 04 00 00       	cmp    $0x400,%eax
f01029b2:	0f 85 29 ff ff ff    	jne    f01028e1 <mem_init+0x16da>
	cprintf("check_kern_pgdir() succeeded!\n");
f01029b8:	c7 04 24 fc 49 10 f0 	movl   $0xf01049fc,(%esp)
f01029bf:	e8 e5 03 00 00       	call   f0102da9 <cprintf>
	lcr3(PADDR(kern_pgdir));
f01029c4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
	if ((uint32_t)kva < KERNBASE)
f01029c9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029ce:	77 20                	ja     f01029f0 <mem_init+0x17e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029d4:	c7 44 24 08 ac 44 10 	movl   $0xf01044ac,0x8(%esp)
f01029db:	f0 
f01029dc:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f01029e3:	00 
f01029e4:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f01029eb:	e8 a4 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01029f0:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029f5:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f01029f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029fd:	e8 7e e0 ff ff       	call   f0100a80 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102a02:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a05:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a08:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a0d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a10:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a17:	e8 55 e4 ff ff       	call   f0100e71 <page_alloc>
f0102a1c:	89 c3                	mov    %eax,%ebx
f0102a1e:	85 c0                	test   %eax,%eax
f0102a20:	75 24                	jne    f0102a46 <mem_init+0x183f>
f0102a22:	c7 44 24 0c 8d 4b 10 	movl   $0xf0104b8d,0xc(%esp)
f0102a29:	f0 
f0102a2a:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102a31:	f0 
f0102a32:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102a39:	00 
f0102a3a:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102a41:	e8 4e d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a46:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a4d:	e8 1f e4 ff ff       	call   f0100e71 <page_alloc>
f0102a52:	89 c7                	mov    %eax,%edi
f0102a54:	85 c0                	test   %eax,%eax
f0102a56:	75 24                	jne    f0102a7c <mem_init+0x1875>
f0102a58:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f0102a5f:	f0 
f0102a60:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102a67:	f0 
f0102a68:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0102a6f:	00 
f0102a70:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102a77:	e8 18 d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a7c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a83:	e8 e9 e3 ff ff       	call   f0100e71 <page_alloc>
f0102a88:	89 c6                	mov    %eax,%esi
f0102a8a:	85 c0                	test   %eax,%eax
f0102a8c:	75 24                	jne    f0102ab2 <mem_init+0x18ab>
f0102a8e:	c7 44 24 0c b9 4b 10 	movl   $0xf0104bb9,0xc(%esp)
f0102a95:	f0 
f0102a96:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102a9d:	f0 
f0102a9e:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102aa5:	00 
f0102aa6:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102aad:	e8 e2 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102ab2:	89 1c 24             	mov    %ebx,(%esp)
f0102ab5:	e8 42 e4 ff ff       	call   f0100efc <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102aba:	89 f8                	mov    %edi,%eax
f0102abc:	e8 0b df ff ff       	call   f01009cc <page2kva>
f0102ac1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ac8:	00 
f0102ac9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102ad0:	00 
f0102ad1:	89 04 24             	mov    %eax,(%esp)
f0102ad4:	e8 3e 0e 00 00       	call   f0103917 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ad9:	89 f0                	mov    %esi,%eax
f0102adb:	e8 ec de ff ff       	call   f01009cc <page2kva>
f0102ae0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ae7:	00 
f0102ae8:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102aef:	00 
f0102af0:	89 04 24             	mov    %eax,(%esp)
f0102af3:	e8 1f 0e 00 00       	call   f0103917 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102af8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102aff:	00 
f0102b00:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b07:	00 
f0102b08:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b0c:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102b11:	89 04 24             	mov    %eax,(%esp)
f0102b14:	e8 59 e6 ff ff       	call   f0101172 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b1e:	74 24                	je     f0102b44 <mem_init+0x193d>
f0102b20:	c7 44 24 0c 8a 4c 10 	movl   $0xf0104c8a,0xc(%esp)
f0102b27:	f0 
f0102b28:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102b2f:	f0 
f0102b30:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102b37:	00 
f0102b38:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102b3f:	e8 50 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b44:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b4b:	01 01 01 
f0102b4e:	74 24                	je     f0102b74 <mem_init+0x196d>
f0102b50:	c7 44 24 0c 1c 4a 10 	movl   $0xf0104a1c,0xc(%esp)
f0102b57:	f0 
f0102b58:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102b5f:	f0 
f0102b60:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102b67:	00 
f0102b68:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102b6f:	e8 20 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b74:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b7b:	00 
f0102b7c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b83:	00 
f0102b84:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b88:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102b8d:	89 04 24             	mov    %eax,(%esp)
f0102b90:	e8 dd e5 ff ff       	call   f0101172 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b95:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b9c:	02 02 02 
f0102b9f:	74 24                	je     f0102bc5 <mem_init+0x19be>
f0102ba1:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f0102ba8:	f0 
f0102ba9:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102bb0:	f0 
f0102bb1:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102bb8:	00 
f0102bb9:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102bc0:	e8 cf d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102bc5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bca:	74 24                	je     f0102bf0 <mem_init+0x19e9>
f0102bcc:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f0102bd3:	f0 
f0102bd4:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102bdb:	f0 
f0102bdc:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0102be3:	00 
f0102be4:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102beb:	e8 a4 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102bf0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bf5:	74 24                	je     f0102c1b <mem_init+0x1a14>
f0102bf7:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f0102bfe:	f0 
f0102bff:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102c06:	f0 
f0102c07:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102c0e:	00 
f0102c0f:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102c16:	e8 79 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c1b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c22:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c25:	89 f0                	mov    %esi,%eax
f0102c27:	e8 a0 dd ff ff       	call   f01009cc <page2kva>
f0102c2c:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102c32:	74 24                	je     f0102c58 <mem_init+0x1a51>
f0102c34:	c7 44 24 0c 64 4a 10 	movl   $0xf0104a64,0xc(%esp)
f0102c3b:	f0 
f0102c3c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102c43:	f0 
f0102c44:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102c4b:	00 
f0102c4c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102c53:	e8 3c d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c58:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c5f:	00 
f0102c60:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102c65:	89 04 24             	mov    %eax,(%esp)
f0102c68:	e8 bf e4 ff ff       	call   f010112c <page_remove>
	assert(pp2->pp_ref == 0);
f0102c6d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c72:	74 24                	je     f0102c98 <mem_init+0x1a91>
f0102c74:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f0102c7b:	f0 
f0102c7c:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102c8b:	00 
f0102c8c:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102c93:	e8 fc d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c98:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102c9d:	8b 08                	mov    (%eax),%ecx
f0102c9f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f0102ca5:	89 da                	mov    %ebx,%edx
f0102ca7:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0102cad:	c1 fa 03             	sar    $0x3,%edx
f0102cb0:	c1 e2 0c             	shl    $0xc,%edx
f0102cb3:	39 d1                	cmp    %edx,%ecx
f0102cb5:	74 24                	je     f0102cdb <mem_init+0x1ad4>
f0102cb7:	c7 44 24 0c a8 45 10 	movl   $0xf01045a8,0xc(%esp)
f0102cbe:	f0 
f0102cbf:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102cc6:	f0 
f0102cc7:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102cce:	00 
f0102ccf:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102cd6:	e8 b9 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102cdb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102ce1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ce6:	74 24                	je     f0102d0c <mem_init+0x1b05>
f0102ce8:	c7 44 24 0c 9b 4c 10 	movl   $0xf0104c9b,0xc(%esp)
f0102cef:	f0 
f0102cf0:	c7 44 24 08 e2 4a 10 	movl   $0xf0104ae2,0x8(%esp)
f0102cf7:	f0 
f0102cf8:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102cff:	00 
f0102d00:	c7 04 24 ca 4a 10 f0 	movl   $0xf0104aca,(%esp)
f0102d07:	e8 88 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d0c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102d12:	89 1c 24             	mov    %ebx,(%esp)
f0102d15:	e8 e2 e1 ff ff       	call   f0100efc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d1a:	c7 04 24 90 4a 10 f0 	movl   $0xf0104a90,(%esp)
f0102d21:	e8 83 00 00 00       	call   f0102da9 <cprintf>
}
f0102d26:	83 c4 4c             	add    $0x4c,%esp
f0102d29:	5b                   	pop    %ebx
f0102d2a:	5e                   	pop    %esi
f0102d2b:	5f                   	pop    %edi
f0102d2c:	5d                   	pop    %ebp
f0102d2d:	c3                   	ret    

f0102d2e <tlb_invalidate>:
{
f0102d2e:	55                   	push   %ebp
f0102d2f:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d31:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d34:	0f 01 38             	invlpg (%eax)
}
f0102d37:	5d                   	pop    %ebp
f0102d38:	c3                   	ret    

f0102d39 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d39:	55                   	push   %ebp
f0102d3a:	89 e5                	mov    %esp,%ebp
f0102d3c:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d40:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d45:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d46:	b2 71                	mov    $0x71,%dl
f0102d48:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d49:	0f b6 c0             	movzbl %al,%eax
}
f0102d4c:	5d                   	pop    %ebp
f0102d4d:	c3                   	ret    

f0102d4e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d4e:	55                   	push   %ebp
f0102d4f:	89 e5                	mov    %esp,%ebp
f0102d51:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d55:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d5a:	ee                   	out    %al,(%dx)
f0102d5b:	b2 71                	mov    $0x71,%dl
f0102d5d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d60:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d61:	5d                   	pop    %ebp
f0102d62:	c3                   	ret    

f0102d63 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d63:	55                   	push   %ebp
f0102d64:	89 e5                	mov    %esp,%ebp
f0102d66:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d69:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d6c:	89 04 24             	mov    %eax,(%esp)
f0102d6f:	e8 8d d8 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102d74:	c9                   	leave  
f0102d75:	c3                   	ret    

f0102d76 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d76:	55                   	push   %ebp
f0102d77:	89 e5                	mov    %esp,%ebp
f0102d79:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d7c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d83:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d86:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d8d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d91:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d98:	c7 04 24 63 2d 10 f0 	movl   $0xf0102d63,(%esp)
f0102d9f:	e8 ba 04 00 00       	call   f010325e <vprintfmt>
	return cnt;
}
f0102da4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102da7:	c9                   	leave  
f0102da8:	c3                   	ret    

f0102da9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102da9:	55                   	push   %ebp
f0102daa:	89 e5                	mov    %esp,%ebp
f0102dac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102daf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102db2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102db6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102db9:	89 04 24             	mov    %eax,(%esp)
f0102dbc:	e8 b5 ff ff ff       	call   f0102d76 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102dc1:	c9                   	leave  
f0102dc2:	c3                   	ret    

f0102dc3 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102dc3:	55                   	push   %ebp
f0102dc4:	89 e5                	mov    %esp,%ebp
f0102dc6:	57                   	push   %edi
f0102dc7:	56                   	push   %esi
f0102dc8:	53                   	push   %ebx
f0102dc9:	83 ec 10             	sub    $0x10,%esp
f0102dcc:	89 c6                	mov    %eax,%esi
f0102dce:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102dd1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102dd4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102dd7:	8b 1a                	mov    (%edx),%ebx
f0102dd9:	8b 01                	mov    (%ecx),%eax
f0102ddb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102dde:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102de5:	eb 77                	jmp    f0102e5e <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102de7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102dea:	01 d8                	add    %ebx,%eax
f0102dec:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102df1:	99                   	cltd   
f0102df2:	f7 f9                	idiv   %ecx
f0102df4:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102df6:	eb 01                	jmp    f0102df9 <stab_binsearch+0x36>
			m--;
f0102df8:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0102df9:	39 d9                	cmp    %ebx,%ecx
f0102dfb:	7c 1d                	jl     f0102e1a <stab_binsearch+0x57>
f0102dfd:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e00:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e05:	39 fa                	cmp    %edi,%edx
f0102e07:	75 ef                	jne    f0102df8 <stab_binsearch+0x35>
f0102e09:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e0c:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102e0f:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102e13:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102e16:	73 18                	jae    f0102e30 <stab_binsearch+0x6d>
f0102e18:	eb 05                	jmp    f0102e1f <stab_binsearch+0x5c>
			l = true_m + 1;
f0102e1a:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102e1d:	eb 3f                	jmp    f0102e5e <stab_binsearch+0x9b>
			*region_left = m;
f0102e1f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e22:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102e24:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0102e27:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e2e:	eb 2e                	jmp    f0102e5e <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0102e30:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e33:	73 15                	jae    f0102e4a <stab_binsearch+0x87>
			*region_right = m - 1;
f0102e35:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e38:	48                   	dec    %eax
f0102e39:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e3c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e3f:	89 01                	mov    %eax,(%ecx)
		any_matches = 1;
f0102e41:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e48:	eb 14                	jmp    f0102e5e <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e4a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e4d:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102e50:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102e52:	ff 45 0c             	incl   0xc(%ebp)
f0102e55:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0102e57:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0102e5e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102e61:	7e 84                	jle    f0102de7 <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0102e63:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e67:	75 0d                	jne    f0102e76 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e69:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e6c:	8b 00                	mov    (%eax),%eax
f0102e6e:	48                   	dec    %eax
f0102e6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e72:	89 07                	mov    %eax,(%edi)
f0102e74:	eb 22                	jmp    f0102e98 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e76:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e79:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e7b:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e7e:	8b 0b                	mov    (%ebx),%ecx
		for (l = *region_right;
f0102e80:	eb 01                	jmp    f0102e83 <stab_binsearch+0xc0>
		     l--)
f0102e82:	48                   	dec    %eax
		for (l = *region_right;
f0102e83:	39 c1                	cmp    %eax,%ecx
f0102e85:	7d 0c                	jge    f0102e93 <stab_binsearch+0xd0>
f0102e87:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102e8a:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e8f:	39 fa                	cmp    %edi,%edx
f0102e91:	75 ef                	jne    f0102e82 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0102e93:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102e96:	89 07                	mov    %eax,(%edi)
	}
}
f0102e98:	83 c4 10             	add    $0x10,%esp
f0102e9b:	5b                   	pop    %ebx
f0102e9c:	5e                   	pop    %esi
f0102e9d:	5f                   	pop    %edi
f0102e9e:	5d                   	pop    %ebp
f0102e9f:	c3                   	ret    

f0102ea0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ea0:	55                   	push   %ebp
f0102ea1:	89 e5                	mov    %esp,%ebp
f0102ea3:	57                   	push   %edi
f0102ea4:	56                   	push   %esi
f0102ea5:	53                   	push   %ebx
f0102ea6:	83 ec 3c             	sub    $0x3c,%esp
f0102ea9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102eac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102eaf:	c7 03 9f 4d 10 f0    	movl   $0xf0104d9f,(%ebx)
	info->eip_line = 0;
f0102eb5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102ebc:	c7 43 08 9f 4d 10 f0 	movl   $0xf0104d9f,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102ec3:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102eca:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102ecd:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102ed4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102eda:	76 12                	jbe    f0102eee <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102edc:	b8 6c cb 10 f0       	mov    $0xf010cb6c,%eax
f0102ee1:	3d 71 ad 10 f0       	cmp    $0xf010ad71,%eax
f0102ee6:	0f 86 cd 01 00 00    	jbe    f01030b9 <debuginfo_eip+0x219>
f0102eec:	eb 1c                	jmp    f0102f0a <debuginfo_eip+0x6a>
  	        panic("User address");
f0102eee:	c7 44 24 08 a9 4d 10 	movl   $0xf0104da9,0x8(%esp)
f0102ef5:	f0 
f0102ef6:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102efd:	00 
f0102efe:	c7 04 24 b6 4d 10 f0 	movl   $0xf0104db6,(%esp)
f0102f05:	e8 8a d1 ff ff       	call   f0100094 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f0a:	80 3d 6b cb 10 f0 00 	cmpb   $0x0,0xf010cb6b
f0102f11:	0f 85 a9 01 00 00    	jne    f01030c0 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f17:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f1e:	b8 70 ad 10 f0       	mov    $0xf010ad70,%eax
f0102f23:	2d d4 4f 10 f0       	sub    $0xf0104fd4,%eax
f0102f28:	c1 f8 02             	sar    $0x2,%eax
f0102f2b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f31:	83 e8 01             	sub    $0x1,%eax
f0102f34:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f37:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f3b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f42:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f45:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f48:	b8 d4 4f 10 f0       	mov    $0xf0104fd4,%eax
f0102f4d:	e8 71 fe ff ff       	call   f0102dc3 <stab_binsearch>
	if (lfile == 0)
f0102f52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f55:	85 c0                	test   %eax,%eax
f0102f57:	0f 84 6a 01 00 00    	je     f01030c7 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f5d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f60:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f63:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f66:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f6a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f71:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f74:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f77:	b8 d4 4f 10 f0       	mov    $0xf0104fd4,%eax
f0102f7c:	e8 42 fe ff ff       	call   f0102dc3 <stab_binsearch>

	if (lfun <= rfun) {
f0102f81:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f84:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f87:	39 d0                	cmp    %edx,%eax
f0102f89:	7f 3d                	jg     f0102fc8 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f8b:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102f8e:	8d b9 d4 4f 10 f0    	lea    -0xfefb02c(%ecx),%edi
f0102f94:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102f97:	8b 89 d4 4f 10 f0    	mov    -0xfefb02c(%ecx),%ecx
f0102f9d:	bf 6c cb 10 f0       	mov    $0xf010cb6c,%edi
f0102fa2:	81 ef 71 ad 10 f0    	sub    $0xf010ad71,%edi
f0102fa8:	39 f9                	cmp    %edi,%ecx
f0102faa:	73 09                	jae    f0102fb5 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102fac:	81 c1 71 ad 10 f0    	add    $0xf010ad71,%ecx
f0102fb2:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102fb5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102fb8:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102fbb:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102fbe:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102fc0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102fc3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102fc6:	eb 0f                	jmp    f0102fd7 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102fc8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102fcb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102fd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fd4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102fd7:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102fde:	00 
f0102fdf:	8b 43 08             	mov    0x8(%ebx),%eax
f0102fe2:	89 04 24             	mov    %eax,(%esp)
f0102fe5:	e8 11 09 00 00       	call   f01038fb <strfind>
f0102fea:	2b 43 08             	sub    0x8(%ebx),%eax
f0102fed:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102ff0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ff4:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0102ffb:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102ffe:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103001:	b8 d4 4f 10 f0       	mov    $0xf0104fd4,%eax
f0103006:	e8 b8 fd ff ff       	call   f0102dc3 <stab_binsearch>
	if (lline <= rline) {		// If the lline stab less and equal to rline, we found the line numbers
f010300b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010300e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103011:	0f 8f b7 00 00 00    	jg     f01030ce <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0103017:	6b c0 0c             	imul   $0xc,%eax,%eax
f010301a:	0f b7 80 da 4f 10 f0 	movzwl -0xfefb026(%eax),%eax
f0103021:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103024:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103027:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010302a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010302d:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103030:	81 c2 d4 4f 10 f0    	add    $0xf0104fd4,%edx
f0103036:	eb 06                	jmp    f010303e <debuginfo_eip+0x19e>
f0103038:	83 e8 01             	sub    $0x1,%eax
f010303b:	83 ea 0c             	sub    $0xc,%edx
f010303e:	89 c6                	mov    %eax,%esi
f0103040:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0103043:	7f 33                	jg     f0103078 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0103045:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103049:	80 f9 84             	cmp    $0x84,%cl
f010304c:	74 0b                	je     f0103059 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010304e:	80 f9 64             	cmp    $0x64,%cl
f0103051:	75 e5                	jne    f0103038 <debuginfo_eip+0x198>
f0103053:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103057:	74 df                	je     f0103038 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103059:	6b f6 0c             	imul   $0xc,%esi,%esi
f010305c:	8b 86 d4 4f 10 f0    	mov    -0xfefb02c(%esi),%eax
f0103062:	ba 6c cb 10 f0       	mov    $0xf010cb6c,%edx
f0103067:	81 ea 71 ad 10 f0    	sub    $0xf010ad71,%edx
f010306d:	39 d0                	cmp    %edx,%eax
f010306f:	73 07                	jae    f0103078 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103071:	05 71 ad 10 f0       	add    $0xf010ad71,%eax
f0103076:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103078:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010307b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010307e:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103083:	39 ca                	cmp    %ecx,%edx
f0103085:	7d 53                	jge    f01030da <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103087:	8d 42 01             	lea    0x1(%edx),%eax
f010308a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010308d:	89 c2                	mov    %eax,%edx
f010308f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103092:	05 d4 4f 10 f0       	add    $0xf0104fd4,%eax
f0103097:	89 ce                	mov    %ecx,%esi
f0103099:	eb 04                	jmp    f010309f <debuginfo_eip+0x1ff>
			info->eip_fn_narg++;
f010309b:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f010309f:	39 d6                	cmp    %edx,%esi
f01030a1:	7e 32                	jle    f01030d5 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030a3:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01030a7:	83 c2 01             	add    $0x1,%edx
f01030aa:	83 c0 0c             	add    $0xc,%eax
f01030ad:	80 f9 a0             	cmp    $0xa0,%cl
f01030b0:	74 e9                	je     f010309b <debuginfo_eip+0x1fb>
	return 0;
f01030b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01030b7:	eb 21                	jmp    f01030da <debuginfo_eip+0x23a>
		return -1;
f01030b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030be:	eb 1a                	jmp    f01030da <debuginfo_eip+0x23a>
f01030c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030c5:	eb 13                	jmp    f01030da <debuginfo_eip+0x23a>
		return -1;
f01030c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030cc:	eb 0c                	jmp    f01030da <debuginfo_eip+0x23a>
		return -1;
f01030ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030d3:	eb 05                	jmp    f01030da <debuginfo_eip+0x23a>
	return 0;
f01030d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030da:	83 c4 3c             	add    $0x3c,%esp
f01030dd:	5b                   	pop    %ebx
f01030de:	5e                   	pop    %esi
f01030df:	5f                   	pop    %edi
f01030e0:	5d                   	pop    %ebp
f01030e1:	c3                   	ret    
f01030e2:	66 90                	xchg   %ax,%ax
f01030e4:	66 90                	xchg   %ax,%ax
f01030e6:	66 90                	xchg   %ax,%ax
f01030e8:	66 90                	xchg   %ax,%ax
f01030ea:	66 90                	xchg   %ax,%ax
f01030ec:	66 90                	xchg   %ax,%ax
f01030ee:	66 90                	xchg   %ax,%ax

f01030f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01030f0:	55                   	push   %ebp
f01030f1:	89 e5                	mov    %esp,%ebp
f01030f3:	57                   	push   %edi
f01030f4:	56                   	push   %esi
f01030f5:	53                   	push   %ebx
f01030f6:	83 ec 3c             	sub    $0x3c,%esp
f01030f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030fc:	89 d7                	mov    %edx,%edi
f01030fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103101:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103104:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103107:	89 c3                	mov    %eax,%ebx
f0103109:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010310c:	8b 45 10             	mov    0x10(%ebp),%eax
f010310f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103112:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103117:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010311a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010311d:	39 d9                	cmp    %ebx,%ecx
f010311f:	72 05                	jb     f0103126 <printnum+0x36>
f0103121:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103124:	77 69                	ja     f010318f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103126:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103129:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010312d:	83 ee 01             	sub    $0x1,%esi
f0103130:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103134:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103138:	8b 44 24 08          	mov    0x8(%esp),%eax
f010313c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103140:	89 c3                	mov    %eax,%ebx
f0103142:	89 d6                	mov    %edx,%esi
f0103144:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103147:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010314a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010314e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103155:	89 04 24             	mov    %eax,(%esp)
f0103158:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010315b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010315f:	e8 bc 09 00 00       	call   f0103b20 <__udivdi3>
f0103164:	89 d9                	mov    %ebx,%ecx
f0103166:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010316a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010316e:	89 04 24             	mov    %eax,(%esp)
f0103171:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103175:	89 fa                	mov    %edi,%edx
f0103177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010317a:	e8 71 ff ff ff       	call   f01030f0 <printnum>
f010317f:	eb 1b                	jmp    f010319c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103181:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103185:	8b 45 18             	mov    0x18(%ebp),%eax
f0103188:	89 04 24             	mov    %eax,(%esp)
f010318b:	ff d3                	call   *%ebx
f010318d:	eb 03                	jmp    f0103192 <printnum+0xa2>
f010318f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f0103192:	83 ee 01             	sub    $0x1,%esi
f0103195:	85 f6                	test   %esi,%esi
f0103197:	7f e8                	jg     f0103181 <printnum+0x91>
f0103199:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010319c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031a0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01031a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01031a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031ae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01031b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031b5:	89 04 24             	mov    %eax,(%esp)
f01031b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031bf:	e8 8c 0a 00 00       	call   f0103c50 <__umoddi3>
f01031c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031c8:	0f be 80 c4 4d 10 f0 	movsbl -0xfefb23c(%eax),%eax
f01031cf:	89 04 24             	mov    %eax,(%esp)
f01031d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031d5:	ff d0                	call   *%eax
}
f01031d7:	83 c4 3c             	add    $0x3c,%esp
f01031da:	5b                   	pop    %ebx
f01031db:	5e                   	pop    %esi
f01031dc:	5f                   	pop    %edi
f01031dd:	5d                   	pop    %ebp
f01031de:	c3                   	ret    

f01031df <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01031df:	55                   	push   %ebp
f01031e0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01031e2:	83 fa 01             	cmp    $0x1,%edx
f01031e5:	7e 0e                	jle    f01031f5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01031e7:	8b 10                	mov    (%eax),%edx
f01031e9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01031ec:	89 08                	mov    %ecx,(%eax)
f01031ee:	8b 02                	mov    (%edx),%eax
f01031f0:	8b 52 04             	mov    0x4(%edx),%edx
f01031f3:	eb 22                	jmp    f0103217 <getuint+0x38>
	else if (lflag)
f01031f5:	85 d2                	test   %edx,%edx
f01031f7:	74 10                	je     f0103209 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01031f9:	8b 10                	mov    (%eax),%edx
f01031fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031fe:	89 08                	mov    %ecx,(%eax)
f0103200:	8b 02                	mov    (%edx),%eax
f0103202:	ba 00 00 00 00       	mov    $0x0,%edx
f0103207:	eb 0e                	jmp    f0103217 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103209:	8b 10                	mov    (%eax),%edx
f010320b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010320e:	89 08                	mov    %ecx,(%eax)
f0103210:	8b 02                	mov    (%edx),%eax
f0103212:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103217:	5d                   	pop    %ebp
f0103218:	c3                   	ret    

f0103219 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103219:	55                   	push   %ebp
f010321a:	89 e5                	mov    %esp,%ebp
f010321c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010321f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103223:	8b 10                	mov    (%eax),%edx
f0103225:	3b 50 04             	cmp    0x4(%eax),%edx
f0103228:	73 0a                	jae    f0103234 <sprintputch+0x1b>
		*b->buf++ = ch;
f010322a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010322d:	89 08                	mov    %ecx,(%eax)
f010322f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103232:	88 02                	mov    %al,(%edx)
}
f0103234:	5d                   	pop    %ebp
f0103235:	c3                   	ret    

f0103236 <printfmt>:
{
f0103236:	55                   	push   %ebp
f0103237:	89 e5                	mov    %esp,%ebp
f0103239:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f010323c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010323f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103243:	8b 45 10             	mov    0x10(%ebp),%eax
f0103246:	89 44 24 08          	mov    %eax,0x8(%esp)
f010324a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103251:	8b 45 08             	mov    0x8(%ebp),%eax
f0103254:	89 04 24             	mov    %eax,(%esp)
f0103257:	e8 02 00 00 00       	call   f010325e <vprintfmt>
}
f010325c:	c9                   	leave  
f010325d:	c3                   	ret    

f010325e <vprintfmt>:
{
f010325e:	55                   	push   %ebp
f010325f:	89 e5                	mov    %esp,%ebp
f0103261:	57                   	push   %edi
f0103262:	56                   	push   %esi
f0103263:	53                   	push   %ebx
f0103264:	83 ec 3c             	sub    $0x3c,%esp
f0103267:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010326a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010326d:	eb 14                	jmp    f0103283 <vprintfmt+0x25>
			if (ch == '\0')
f010326f:	85 c0                	test   %eax,%eax
f0103271:	0f 84 b3 03 00 00    	je     f010362a <vprintfmt+0x3cc>
			putch(ch, putdat);
f0103277:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010327b:	89 04 24             	mov    %eax,(%esp)
f010327e:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103281:	89 f3                	mov    %esi,%ebx
f0103283:	8d 73 01             	lea    0x1(%ebx),%esi
f0103286:	0f b6 03             	movzbl (%ebx),%eax
f0103289:	83 f8 25             	cmp    $0x25,%eax
f010328c:	75 e1                	jne    f010326f <vprintfmt+0x11>
f010328e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103292:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103299:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01032a0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01032a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032ac:	eb 1d                	jmp    f01032cb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f01032ae:	89 de                	mov    %ebx,%esi
			padc = '-';
f01032b0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01032b4:	eb 15                	jmp    f01032cb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f01032b6:	89 de                	mov    %ebx,%esi
			padc = '0';
f01032b8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01032bc:	eb 0d                	jmp    f01032cb <vprintfmt+0x6d>
				width = precision, precision = -1;
f01032be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032c4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01032cb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01032ce:	0f b6 0e             	movzbl (%esi),%ecx
f01032d1:	0f b6 c1             	movzbl %cl,%eax
f01032d4:	83 e9 23             	sub    $0x23,%ecx
f01032d7:	80 f9 55             	cmp    $0x55,%cl
f01032da:	0f 87 2a 03 00 00    	ja     f010360a <vprintfmt+0x3ac>
f01032e0:	0f b6 c9             	movzbl %cl,%ecx
f01032e3:	ff 24 8d 50 4e 10 f0 	jmp    *-0xfefb1b0(,%ecx,4)
f01032ea:	89 de                	mov    %ebx,%esi
f01032ec:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f01032f1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01032f4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01032f8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01032fb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01032fe:	83 fb 09             	cmp    $0x9,%ebx
f0103301:	77 36                	ja     f0103339 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f0103303:	83 c6 01             	add    $0x1,%esi
			}
f0103306:	eb e9                	jmp    f01032f1 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f0103308:	8b 45 14             	mov    0x14(%ebp),%eax
f010330b:	8d 48 04             	lea    0x4(%eax),%ecx
f010330e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103311:	8b 00                	mov    (%eax),%eax
f0103313:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103316:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0103318:	eb 22                	jmp    f010333c <vprintfmt+0xde>
f010331a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010331d:	85 c9                	test   %ecx,%ecx
f010331f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103324:	0f 49 c1             	cmovns %ecx,%eax
f0103327:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010332a:	89 de                	mov    %ebx,%esi
f010332c:	eb 9d                	jmp    f01032cb <vprintfmt+0x6d>
f010332e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0103330:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103337:	eb 92                	jmp    f01032cb <vprintfmt+0x6d>
f0103339:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f010333c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103340:	79 89                	jns    f01032cb <vprintfmt+0x6d>
f0103342:	e9 77 ff ff ff       	jmp    f01032be <vprintfmt+0x60>
			lflag++;
f0103347:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010334a:	89 de                	mov    %ebx,%esi
			goto reswitch;
f010334c:	e9 7a ff ff ff       	jmp    f01032cb <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f0103351:	8b 45 14             	mov    0x14(%ebp),%eax
f0103354:	8d 50 04             	lea    0x4(%eax),%edx
f0103357:	89 55 14             	mov    %edx,0x14(%ebp)
f010335a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010335e:	8b 00                	mov    (%eax),%eax
f0103360:	89 04 24             	mov    %eax,(%esp)
f0103363:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103366:	e9 18 ff ff ff       	jmp    f0103283 <vprintfmt+0x25>
			err = va_arg(ap, int);
f010336b:	8b 45 14             	mov    0x14(%ebp),%eax
f010336e:	8d 50 04             	lea    0x4(%eax),%edx
f0103371:	89 55 14             	mov    %edx,0x14(%ebp)
f0103374:	8b 00                	mov    (%eax),%eax
f0103376:	99                   	cltd   
f0103377:	31 d0                	xor    %edx,%eax
f0103379:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010337b:	83 f8 06             	cmp    $0x6,%eax
f010337e:	7f 0b                	jg     f010338b <vprintfmt+0x12d>
f0103380:	8b 14 85 a8 4f 10 f0 	mov    -0xfefb058(,%eax,4),%edx
f0103387:	85 d2                	test   %edx,%edx
f0103389:	75 20                	jne    f01033ab <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010338b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010338f:	c7 44 24 08 dc 4d 10 	movl   $0xf0104ddc,0x8(%esp)
f0103396:	f0 
f0103397:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010339b:	8b 45 08             	mov    0x8(%ebp),%eax
f010339e:	89 04 24             	mov    %eax,(%esp)
f01033a1:	e8 90 fe ff ff       	call   f0103236 <printfmt>
f01033a6:	e9 d8 fe ff ff       	jmp    f0103283 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f01033ab:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033af:	c7 44 24 08 f4 4a 10 	movl   $0xf0104af4,0x8(%esp)
f01033b6:	f0 
f01033b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033be:	89 04 24             	mov    %eax,(%esp)
f01033c1:	e8 70 fe ff ff       	call   f0103236 <printfmt>
f01033c6:	e9 b8 fe ff ff       	jmp    f0103283 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f01033cb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01033ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f01033d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01033d7:	8d 50 04             	lea    0x4(%eax),%edx
f01033da:	89 55 14             	mov    %edx,0x14(%ebp)
f01033dd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01033df:	85 f6                	test   %esi,%esi
f01033e1:	b8 d5 4d 10 f0       	mov    $0xf0104dd5,%eax
f01033e6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01033e9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01033ed:	0f 84 97 00 00 00    	je     f010348a <vprintfmt+0x22c>
f01033f3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01033f7:	0f 8e 9b 00 00 00    	jle    f0103498 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01033fd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103401:	89 34 24             	mov    %esi,(%esp)
f0103404:	e8 9f 03 00 00       	call   f01037a8 <strnlen>
f0103409:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010340c:	29 c2                	sub    %eax,%edx
f010340e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103411:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103415:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103418:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010341b:	8b 75 08             	mov    0x8(%ebp),%esi
f010341e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103421:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0103423:	eb 0f                	jmp    f0103434 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103425:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103429:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010342c:	89 04 24             	mov    %eax,(%esp)
f010342f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103431:	83 eb 01             	sub    $0x1,%ebx
f0103434:	85 db                	test   %ebx,%ebx
f0103436:	7f ed                	jg     f0103425 <vprintfmt+0x1c7>
f0103438:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010343b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010343e:	85 d2                	test   %edx,%edx
f0103440:	b8 00 00 00 00       	mov    $0x0,%eax
f0103445:	0f 49 c2             	cmovns %edx,%eax
f0103448:	29 c2                	sub    %eax,%edx
f010344a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010344d:	89 d7                	mov    %edx,%edi
f010344f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103452:	eb 50                	jmp    f01034a4 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f0103454:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103458:	74 1e                	je     f0103478 <vprintfmt+0x21a>
f010345a:	0f be d2             	movsbl %dl,%edx
f010345d:	83 ea 20             	sub    $0x20,%edx
f0103460:	83 fa 5e             	cmp    $0x5e,%edx
f0103463:	76 13                	jbe    f0103478 <vprintfmt+0x21a>
					putch('?', putdat);
f0103465:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103468:	89 44 24 04          	mov    %eax,0x4(%esp)
f010346c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103473:	ff 55 08             	call   *0x8(%ebp)
f0103476:	eb 0d                	jmp    f0103485 <vprintfmt+0x227>
					putch(ch, putdat);
f0103478:	8b 55 0c             	mov    0xc(%ebp),%edx
f010347b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010347f:	89 04 24             	mov    %eax,(%esp)
f0103482:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103485:	83 ef 01             	sub    $0x1,%edi
f0103488:	eb 1a                	jmp    f01034a4 <vprintfmt+0x246>
f010348a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010348d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103490:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103493:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103496:	eb 0c                	jmp    f01034a4 <vprintfmt+0x246>
f0103498:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010349b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010349e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01034a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034a4:	83 c6 01             	add    $0x1,%esi
f01034a7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01034ab:	0f be c2             	movsbl %dl,%eax
f01034ae:	85 c0                	test   %eax,%eax
f01034b0:	74 27                	je     f01034d9 <vprintfmt+0x27b>
f01034b2:	85 db                	test   %ebx,%ebx
f01034b4:	78 9e                	js     f0103454 <vprintfmt+0x1f6>
f01034b6:	83 eb 01             	sub    $0x1,%ebx
f01034b9:	79 99                	jns    f0103454 <vprintfmt+0x1f6>
f01034bb:	89 f8                	mov    %edi,%eax
f01034bd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01034c3:	89 c3                	mov    %eax,%ebx
f01034c5:	eb 1a                	jmp    f01034e1 <vprintfmt+0x283>
				putch(' ', putdat);
f01034c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034d2:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01034d4:	83 eb 01             	sub    $0x1,%ebx
f01034d7:	eb 08                	jmp    f01034e1 <vprintfmt+0x283>
f01034d9:	89 fb                	mov    %edi,%ebx
f01034db:	8b 75 08             	mov    0x8(%ebp),%esi
f01034de:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034e1:	85 db                	test   %ebx,%ebx
f01034e3:	7f e2                	jg     f01034c7 <vprintfmt+0x269>
f01034e5:	89 75 08             	mov    %esi,0x8(%ebp)
f01034e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01034eb:	e9 93 fd ff ff       	jmp    f0103283 <vprintfmt+0x25>
	if (lflag >= 2)
f01034f0:	83 fa 01             	cmp    $0x1,%edx
f01034f3:	7e 16                	jle    f010350b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01034f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f8:	8d 50 08             	lea    0x8(%eax),%edx
f01034fb:	89 55 14             	mov    %edx,0x14(%ebp)
f01034fe:	8b 50 04             	mov    0x4(%eax),%edx
f0103501:	8b 00                	mov    (%eax),%eax
f0103503:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103506:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103509:	eb 32                	jmp    f010353d <vprintfmt+0x2df>
	else if (lflag)
f010350b:	85 d2                	test   %edx,%edx
f010350d:	74 18                	je     f0103527 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010350f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103512:	8d 50 04             	lea    0x4(%eax),%edx
f0103515:	89 55 14             	mov    %edx,0x14(%ebp)
f0103518:	8b 30                	mov    (%eax),%esi
f010351a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010351d:	89 f0                	mov    %esi,%eax
f010351f:	c1 f8 1f             	sar    $0x1f,%eax
f0103522:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103525:	eb 16                	jmp    f010353d <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0103527:	8b 45 14             	mov    0x14(%ebp),%eax
f010352a:	8d 50 04             	lea    0x4(%eax),%edx
f010352d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103530:	8b 30                	mov    (%eax),%esi
f0103532:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103535:	89 f0                	mov    %esi,%eax
f0103537:	c1 f8 1f             	sar    $0x1f,%eax
f010353a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f010353d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103540:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0103543:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0103548:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010354c:	0f 89 80 00 00 00    	jns    f01035d2 <vprintfmt+0x374>
				putch('-', putdat);
f0103552:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103556:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010355d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103560:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103563:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103566:	f7 d8                	neg    %eax
f0103568:	83 d2 00             	adc    $0x0,%edx
f010356b:	f7 da                	neg    %edx
			base = 10;
f010356d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103572:	eb 5e                	jmp    f01035d2 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0103574:	8d 45 14             	lea    0x14(%ebp),%eax
f0103577:	e8 63 fc ff ff       	call   f01031df <getuint>
			base = 10;
f010357c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103581:	eb 4f                	jmp    f01035d2 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0103583:	8d 45 14             	lea    0x14(%ebp),%eax
f0103586:	e8 54 fc ff ff       	call   f01031df <getuint>
			base = 8;
f010358b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103590:	eb 40                	jmp    f01035d2 <vprintfmt+0x374>
			putch('0', putdat);
f0103592:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103596:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010359d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01035a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035a4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01035ab:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f01035ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01035b1:	8d 50 04             	lea    0x4(%eax),%edx
f01035b4:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01035b7:	8b 00                	mov    (%eax),%eax
f01035b9:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01035be:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01035c3:	eb 0d                	jmp    f01035d2 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01035c5:	8d 45 14             	lea    0x14(%ebp),%eax
f01035c8:	e8 12 fc ff ff       	call   f01031df <getuint>
			base = 16;
f01035cd:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01035d2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01035d6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01035da:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01035dd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01035e1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035e5:	89 04 24             	mov    %eax,(%esp)
f01035e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035ec:	89 fa                	mov    %edi,%edx
f01035ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01035f1:	e8 fa fa ff ff       	call   f01030f0 <printnum>
			break;
f01035f6:	e9 88 fc ff ff       	jmp    f0103283 <vprintfmt+0x25>
			putch(ch, putdat);
f01035fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035ff:	89 04 24             	mov    %eax,(%esp)
f0103602:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103605:	e9 79 fc ff ff       	jmp    f0103283 <vprintfmt+0x25>
			putch('%', putdat);
f010360a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010360e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103615:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103618:	89 f3                	mov    %esi,%ebx
f010361a:	eb 03                	jmp    f010361f <vprintfmt+0x3c1>
f010361c:	83 eb 01             	sub    $0x1,%ebx
f010361f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103623:	75 f7                	jne    f010361c <vprintfmt+0x3be>
f0103625:	e9 59 fc ff ff       	jmp    f0103283 <vprintfmt+0x25>
}
f010362a:	83 c4 3c             	add    $0x3c,%esp
f010362d:	5b                   	pop    %ebx
f010362e:	5e                   	pop    %esi
f010362f:	5f                   	pop    %edi
f0103630:	5d                   	pop    %ebp
f0103631:	c3                   	ret    

f0103632 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103632:	55                   	push   %ebp
f0103633:	89 e5                	mov    %esp,%ebp
f0103635:	83 ec 28             	sub    $0x28,%esp
f0103638:	8b 45 08             	mov    0x8(%ebp),%eax
f010363b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010363e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103641:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103645:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103648:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010364f:	85 c0                	test   %eax,%eax
f0103651:	74 30                	je     f0103683 <vsnprintf+0x51>
f0103653:	85 d2                	test   %edx,%edx
f0103655:	7e 2c                	jle    f0103683 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103657:	8b 45 14             	mov    0x14(%ebp),%eax
f010365a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010365e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103661:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103665:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103668:	89 44 24 04          	mov    %eax,0x4(%esp)
f010366c:	c7 04 24 19 32 10 f0 	movl   $0xf0103219,(%esp)
f0103673:	e8 e6 fb ff ff       	call   f010325e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103678:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010367b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010367e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103681:	eb 05                	jmp    f0103688 <vsnprintf+0x56>
		return -E_INVAL;
f0103683:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0103688:	c9                   	leave  
f0103689:	c3                   	ret    

f010368a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010368a:	55                   	push   %ebp
f010368b:	89 e5                	mov    %esp,%ebp
f010368d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103690:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103693:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103697:	8b 45 10             	mov    0x10(%ebp),%eax
f010369a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010369e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01036a8:	89 04 24             	mov    %eax,(%esp)
f01036ab:	e8 82 ff ff ff       	call   f0103632 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036b0:	c9                   	leave  
f01036b1:	c3                   	ret    
f01036b2:	66 90                	xchg   %ax,%ax
f01036b4:	66 90                	xchg   %ax,%ax
f01036b6:	66 90                	xchg   %ax,%ax
f01036b8:	66 90                	xchg   %ax,%ax
f01036ba:	66 90                	xchg   %ax,%ax
f01036bc:	66 90                	xchg   %ax,%ax
f01036be:	66 90                	xchg   %ax,%ax

f01036c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036c0:	55                   	push   %ebp
f01036c1:	89 e5                	mov    %esp,%ebp
f01036c3:	57                   	push   %edi
f01036c4:	56                   	push   %esi
f01036c5:	53                   	push   %ebx
f01036c6:	83 ec 1c             	sub    $0x1c,%esp
f01036c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036cc:	85 c0                	test   %eax,%eax
f01036ce:	74 10                	je     f01036e0 <readline+0x20>
		cprintf("%s", prompt);
f01036d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036d4:	c7 04 24 f4 4a 10 f0 	movl   $0xf0104af4,(%esp)
f01036db:	e8 c9 f6 ff ff       	call   f0102da9 <cprintf>

	i = 0;
	echoing = iscons(0);
f01036e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036e7:	e8 36 cf ff ff       	call   f0100622 <iscons>
f01036ec:	89 c7                	mov    %eax,%edi
	i = 0;
f01036ee:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01036f3:	e8 19 cf ff ff       	call   f0100611 <getchar>
f01036f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036fa:	85 c0                	test   %eax,%eax
f01036fc:	79 17                	jns    f0103715 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103702:	c7 04 24 c4 4f 10 f0 	movl   $0xf0104fc4,(%esp)
f0103709:	e8 9b f6 ff ff       	call   f0102da9 <cprintf>
			return NULL;
f010370e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103713:	eb 6d                	jmp    f0103782 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103715:	83 f8 7f             	cmp    $0x7f,%eax
f0103718:	74 05                	je     f010371f <readline+0x5f>
f010371a:	83 f8 08             	cmp    $0x8,%eax
f010371d:	75 19                	jne    f0103738 <readline+0x78>
f010371f:	85 f6                	test   %esi,%esi
f0103721:	7e 15                	jle    f0103738 <readline+0x78>
			if (echoing)
f0103723:	85 ff                	test   %edi,%edi
f0103725:	74 0c                	je     f0103733 <readline+0x73>
				cputchar('\b');
f0103727:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010372e:	e8 ce ce ff ff       	call   f0100601 <cputchar>
			i--;
f0103733:	83 ee 01             	sub    $0x1,%esi
f0103736:	eb bb                	jmp    f01036f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103738:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010373e:	7f 1c                	jg     f010375c <readline+0x9c>
f0103740:	83 fb 1f             	cmp    $0x1f,%ebx
f0103743:	7e 17                	jle    f010375c <readline+0x9c>
			if (echoing)
f0103745:	85 ff                	test   %edi,%edi
f0103747:	74 08                	je     f0103751 <readline+0x91>
				cputchar(c);
f0103749:	89 1c 24             	mov    %ebx,(%esp)
f010374c:	e8 b0 ce ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f0103751:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103757:	8d 76 01             	lea    0x1(%esi),%esi
f010375a:	eb 97                	jmp    f01036f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010375c:	83 fb 0d             	cmp    $0xd,%ebx
f010375f:	74 05                	je     f0103766 <readline+0xa6>
f0103761:	83 fb 0a             	cmp    $0xa,%ebx
f0103764:	75 8d                	jne    f01036f3 <readline+0x33>
			if (echoing)
f0103766:	85 ff                	test   %edi,%edi
f0103768:	74 0c                	je     f0103776 <readline+0xb6>
				cputchar('\n');
f010376a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103771:	e8 8b ce ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f0103776:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010377d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103782:	83 c4 1c             	add    $0x1c,%esp
f0103785:	5b                   	pop    %ebx
f0103786:	5e                   	pop    %esi
f0103787:	5f                   	pop    %edi
f0103788:	5d                   	pop    %ebp
f0103789:	c3                   	ret    
f010378a:	66 90                	xchg   %ax,%ax
f010378c:	66 90                	xchg   %ax,%ax
f010378e:	66 90                	xchg   %ax,%ax

f0103790 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103790:	55                   	push   %ebp
f0103791:	89 e5                	mov    %esp,%ebp
f0103793:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103796:	b8 00 00 00 00       	mov    $0x0,%eax
f010379b:	eb 03                	jmp    f01037a0 <strlen+0x10>
		n++;
f010379d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01037a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037a4:	75 f7                	jne    f010379d <strlen+0xd>
	return n;
}
f01037a6:	5d                   	pop    %ebp
f01037a7:	c3                   	ret    

f01037a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037a8:	55                   	push   %ebp
f01037a9:	89 e5                	mov    %esp,%ebp
f01037ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037b6:	eb 03                	jmp    f01037bb <strnlen+0x13>
		n++;
f01037b8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037bb:	39 d0                	cmp    %edx,%eax
f01037bd:	74 06                	je     f01037c5 <strnlen+0x1d>
f01037bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01037c3:	75 f3                	jne    f01037b8 <strnlen+0x10>
	return n;
}
f01037c5:	5d                   	pop    %ebp
f01037c6:	c3                   	ret    

f01037c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037c7:	55                   	push   %ebp
f01037c8:	89 e5                	mov    %esp,%ebp
f01037ca:	53                   	push   %ebx
f01037cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037d1:	89 c2                	mov    %eax,%edx
f01037d3:	83 c2 01             	add    $0x1,%edx
f01037d6:	83 c1 01             	add    $0x1,%ecx
f01037d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01037dd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01037e0:	84 db                	test   %bl,%bl
f01037e2:	75 ef                	jne    f01037d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01037e4:	5b                   	pop    %ebx
f01037e5:	5d                   	pop    %ebp
f01037e6:	c3                   	ret    

f01037e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01037e7:	55                   	push   %ebp
f01037e8:	89 e5                	mov    %esp,%ebp
f01037ea:	53                   	push   %ebx
f01037eb:	83 ec 08             	sub    $0x8,%esp
f01037ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01037f1:	89 1c 24             	mov    %ebx,(%esp)
f01037f4:	e8 97 ff ff ff       	call   f0103790 <strlen>
	strcpy(dst + len, src);
f01037f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103800:	01 d8                	add    %ebx,%eax
f0103802:	89 04 24             	mov    %eax,(%esp)
f0103805:	e8 bd ff ff ff       	call   f01037c7 <strcpy>
	return dst;
}
f010380a:	89 d8                	mov    %ebx,%eax
f010380c:	83 c4 08             	add    $0x8,%esp
f010380f:	5b                   	pop    %ebx
f0103810:	5d                   	pop    %ebp
f0103811:	c3                   	ret    

f0103812 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103812:	55                   	push   %ebp
f0103813:	89 e5                	mov    %esp,%ebp
f0103815:	56                   	push   %esi
f0103816:	53                   	push   %ebx
f0103817:	8b 75 08             	mov    0x8(%ebp),%esi
f010381a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010381d:	89 f3                	mov    %esi,%ebx
f010381f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103822:	89 f2                	mov    %esi,%edx
f0103824:	eb 0f                	jmp    f0103835 <strncpy+0x23>
		*dst++ = *src;
f0103826:	83 c2 01             	add    $0x1,%edx
f0103829:	0f b6 01             	movzbl (%ecx),%eax
f010382c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010382f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103832:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103835:	39 da                	cmp    %ebx,%edx
f0103837:	75 ed                	jne    f0103826 <strncpy+0x14>
	}
	return ret;
}
f0103839:	89 f0                	mov    %esi,%eax
f010383b:	5b                   	pop    %ebx
f010383c:	5e                   	pop    %esi
f010383d:	5d                   	pop    %ebp
f010383e:	c3                   	ret    

f010383f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010383f:	55                   	push   %ebp
f0103840:	89 e5                	mov    %esp,%ebp
f0103842:	56                   	push   %esi
f0103843:	53                   	push   %ebx
f0103844:	8b 75 08             	mov    0x8(%ebp),%esi
f0103847:	8b 55 0c             	mov    0xc(%ebp),%edx
f010384a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010384d:	89 f0                	mov    %esi,%eax
f010384f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103853:	85 c9                	test   %ecx,%ecx
f0103855:	75 0b                	jne    f0103862 <strlcpy+0x23>
f0103857:	eb 1d                	jmp    f0103876 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103859:	83 c0 01             	add    $0x1,%eax
f010385c:	83 c2 01             	add    $0x1,%edx
f010385f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103862:	39 d8                	cmp    %ebx,%eax
f0103864:	74 0b                	je     f0103871 <strlcpy+0x32>
f0103866:	0f b6 0a             	movzbl (%edx),%ecx
f0103869:	84 c9                	test   %cl,%cl
f010386b:	75 ec                	jne    f0103859 <strlcpy+0x1a>
f010386d:	89 c2                	mov    %eax,%edx
f010386f:	eb 02                	jmp    f0103873 <strlcpy+0x34>
f0103871:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0103873:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103876:	29 f0                	sub    %esi,%eax
}
f0103878:	5b                   	pop    %ebx
f0103879:	5e                   	pop    %esi
f010387a:	5d                   	pop    %ebp
f010387b:	c3                   	ret    

f010387c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010387c:	55                   	push   %ebp
f010387d:	89 e5                	mov    %esp,%ebp
f010387f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103882:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103885:	eb 06                	jmp    f010388d <strcmp+0x11>
		p++, q++;
f0103887:	83 c1 01             	add    $0x1,%ecx
f010388a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010388d:	0f b6 01             	movzbl (%ecx),%eax
f0103890:	84 c0                	test   %al,%al
f0103892:	74 04                	je     f0103898 <strcmp+0x1c>
f0103894:	3a 02                	cmp    (%edx),%al
f0103896:	74 ef                	je     f0103887 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103898:	0f b6 c0             	movzbl %al,%eax
f010389b:	0f b6 12             	movzbl (%edx),%edx
f010389e:	29 d0                	sub    %edx,%eax
}
f01038a0:	5d                   	pop    %ebp
f01038a1:	c3                   	ret    

f01038a2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038a2:	55                   	push   %ebp
f01038a3:	89 e5                	mov    %esp,%ebp
f01038a5:	53                   	push   %ebx
f01038a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01038a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038ac:	89 c3                	mov    %eax,%ebx
f01038ae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01038b1:	eb 06                	jmp    f01038b9 <strncmp+0x17>
		n--, p++, q++;
f01038b3:	83 c0 01             	add    $0x1,%eax
f01038b6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01038b9:	39 d8                	cmp    %ebx,%eax
f01038bb:	74 15                	je     f01038d2 <strncmp+0x30>
f01038bd:	0f b6 08             	movzbl (%eax),%ecx
f01038c0:	84 c9                	test   %cl,%cl
f01038c2:	74 04                	je     f01038c8 <strncmp+0x26>
f01038c4:	3a 0a                	cmp    (%edx),%cl
f01038c6:	74 eb                	je     f01038b3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038c8:	0f b6 00             	movzbl (%eax),%eax
f01038cb:	0f b6 12             	movzbl (%edx),%edx
f01038ce:	29 d0                	sub    %edx,%eax
f01038d0:	eb 05                	jmp    f01038d7 <strncmp+0x35>
		return 0;
f01038d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038d7:	5b                   	pop    %ebx
f01038d8:	5d                   	pop    %ebp
f01038d9:	c3                   	ret    

f01038da <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038da:	55                   	push   %ebp
f01038db:	89 e5                	mov    %esp,%ebp
f01038dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038e4:	eb 07                	jmp    f01038ed <strchr+0x13>
		if (*s == c)
f01038e6:	38 ca                	cmp    %cl,%dl
f01038e8:	74 0f                	je     f01038f9 <strchr+0x1f>
	for (; *s; s++)
f01038ea:	83 c0 01             	add    $0x1,%eax
f01038ed:	0f b6 10             	movzbl (%eax),%edx
f01038f0:	84 d2                	test   %dl,%dl
f01038f2:	75 f2                	jne    f01038e6 <strchr+0xc>
			return (char *) s;
	return 0;
f01038f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038f9:	5d                   	pop    %ebp
f01038fa:	c3                   	ret    

f01038fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01038fb:	55                   	push   %ebp
f01038fc:	89 e5                	mov    %esp,%ebp
f01038fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103901:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103905:	eb 07                	jmp    f010390e <strfind+0x13>
		if (*s == c)
f0103907:	38 ca                	cmp    %cl,%dl
f0103909:	74 0a                	je     f0103915 <strfind+0x1a>
	for (; *s; s++)
f010390b:	83 c0 01             	add    $0x1,%eax
f010390e:	0f b6 10             	movzbl (%eax),%edx
f0103911:	84 d2                	test   %dl,%dl
f0103913:	75 f2                	jne    f0103907 <strfind+0xc>
			break;
	return (char *) s;
}
f0103915:	5d                   	pop    %ebp
f0103916:	c3                   	ret    

f0103917 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103917:	55                   	push   %ebp
f0103918:	89 e5                	mov    %esp,%ebp
f010391a:	57                   	push   %edi
f010391b:	56                   	push   %esi
f010391c:	53                   	push   %ebx
f010391d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103920:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103923:	85 c9                	test   %ecx,%ecx
f0103925:	74 36                	je     f010395d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103927:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010392d:	75 28                	jne    f0103957 <memset+0x40>
f010392f:	f6 c1 03             	test   $0x3,%cl
f0103932:	75 23                	jne    f0103957 <memset+0x40>
		c &= 0xFF;
f0103934:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103938:	89 d3                	mov    %edx,%ebx
f010393a:	c1 e3 08             	shl    $0x8,%ebx
f010393d:	89 d6                	mov    %edx,%esi
f010393f:	c1 e6 18             	shl    $0x18,%esi
f0103942:	89 d0                	mov    %edx,%eax
f0103944:	c1 e0 10             	shl    $0x10,%eax
f0103947:	09 f0                	or     %esi,%eax
f0103949:	09 c2                	or     %eax,%edx
f010394b:	89 d0                	mov    %edx,%eax
f010394d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010394f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103952:	fc                   	cld    
f0103953:	f3 ab                	rep stos %eax,%es:(%edi)
f0103955:	eb 06                	jmp    f010395d <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103957:	8b 45 0c             	mov    0xc(%ebp),%eax
f010395a:	fc                   	cld    
f010395b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010395d:	89 f8                	mov    %edi,%eax
f010395f:	5b                   	pop    %ebx
f0103960:	5e                   	pop    %esi
f0103961:	5f                   	pop    %edi
f0103962:	5d                   	pop    %ebp
f0103963:	c3                   	ret    

f0103964 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103964:	55                   	push   %ebp
f0103965:	89 e5                	mov    %esp,%ebp
f0103967:	57                   	push   %edi
f0103968:	56                   	push   %esi
f0103969:	8b 45 08             	mov    0x8(%ebp),%eax
f010396c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010396f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103972:	39 c6                	cmp    %eax,%esi
f0103974:	73 35                	jae    f01039ab <memmove+0x47>
f0103976:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103979:	39 d0                	cmp    %edx,%eax
f010397b:	73 2e                	jae    f01039ab <memmove+0x47>
		s += n;
		d += n;
f010397d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103980:	89 d6                	mov    %edx,%esi
f0103982:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103984:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010398a:	75 13                	jne    f010399f <memmove+0x3b>
f010398c:	f6 c1 03             	test   $0x3,%cl
f010398f:	75 0e                	jne    f010399f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103991:	83 ef 04             	sub    $0x4,%edi
f0103994:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103997:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010399a:	fd                   	std    
f010399b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010399d:	eb 09                	jmp    f01039a8 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010399f:	83 ef 01             	sub    $0x1,%edi
f01039a2:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01039a5:	fd                   	std    
f01039a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039a8:	fc                   	cld    
f01039a9:	eb 1d                	jmp    f01039c8 <memmove+0x64>
f01039ab:	89 f2                	mov    %esi,%edx
f01039ad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039af:	f6 c2 03             	test   $0x3,%dl
f01039b2:	75 0f                	jne    f01039c3 <memmove+0x5f>
f01039b4:	f6 c1 03             	test   $0x3,%cl
f01039b7:	75 0a                	jne    f01039c3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039b9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01039bc:	89 c7                	mov    %eax,%edi
f01039be:	fc                   	cld    
f01039bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039c1:	eb 05                	jmp    f01039c8 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f01039c3:	89 c7                	mov    %eax,%edi
f01039c5:	fc                   	cld    
f01039c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039c8:	5e                   	pop    %esi
f01039c9:	5f                   	pop    %edi
f01039ca:	5d                   	pop    %ebp
f01039cb:	c3                   	ret    

f01039cc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01039cc:	55                   	push   %ebp
f01039cd:	89 e5                	mov    %esp,%ebp
f01039cf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01039d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01039d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039e3:	89 04 24             	mov    %eax,(%esp)
f01039e6:	e8 79 ff ff ff       	call   f0103964 <memmove>
}
f01039eb:	c9                   	leave  
f01039ec:	c3                   	ret    

f01039ed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01039ed:	55                   	push   %ebp
f01039ee:	89 e5                	mov    %esp,%ebp
f01039f0:	56                   	push   %esi
f01039f1:	53                   	push   %ebx
f01039f2:	8b 55 08             	mov    0x8(%ebp),%edx
f01039f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01039f8:	89 d6                	mov    %edx,%esi
f01039fa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039fd:	eb 1a                	jmp    f0103a19 <memcmp+0x2c>
		if (*s1 != *s2)
f01039ff:	0f b6 02             	movzbl (%edx),%eax
f0103a02:	0f b6 19             	movzbl (%ecx),%ebx
f0103a05:	38 d8                	cmp    %bl,%al
f0103a07:	74 0a                	je     f0103a13 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103a09:	0f b6 c0             	movzbl %al,%eax
f0103a0c:	0f b6 db             	movzbl %bl,%ebx
f0103a0f:	29 d8                	sub    %ebx,%eax
f0103a11:	eb 0f                	jmp    f0103a22 <memcmp+0x35>
		s1++, s2++;
f0103a13:	83 c2 01             	add    $0x1,%edx
f0103a16:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0103a19:	39 f2                	cmp    %esi,%edx
f0103a1b:	75 e2                	jne    f01039ff <memcmp+0x12>
	}

	return 0;
f0103a1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a22:	5b                   	pop    %ebx
f0103a23:	5e                   	pop    %esi
f0103a24:	5d                   	pop    %ebp
f0103a25:	c3                   	ret    

f0103a26 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a26:	55                   	push   %ebp
f0103a27:	89 e5                	mov    %esp,%ebp
f0103a29:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a2c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a2f:	89 c2                	mov    %eax,%edx
f0103a31:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a34:	eb 07                	jmp    f0103a3d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a36:	38 08                	cmp    %cl,(%eax)
f0103a38:	74 07                	je     f0103a41 <memfind+0x1b>
	for (; s < ends; s++)
f0103a3a:	83 c0 01             	add    $0x1,%eax
f0103a3d:	39 d0                	cmp    %edx,%eax
f0103a3f:	72 f5                	jb     f0103a36 <memfind+0x10>
			break;
	return (void *) s;
}
f0103a41:	5d                   	pop    %ebp
f0103a42:	c3                   	ret    

f0103a43 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a43:	55                   	push   %ebp
f0103a44:	89 e5                	mov    %esp,%ebp
f0103a46:	57                   	push   %edi
f0103a47:	56                   	push   %esi
f0103a48:	53                   	push   %ebx
f0103a49:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a4c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a4f:	eb 03                	jmp    f0103a54 <strtol+0x11>
		s++;
f0103a51:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103a54:	0f b6 0a             	movzbl (%edx),%ecx
f0103a57:	80 f9 09             	cmp    $0x9,%cl
f0103a5a:	74 f5                	je     f0103a51 <strtol+0xe>
f0103a5c:	80 f9 20             	cmp    $0x20,%cl
f0103a5f:	74 f0                	je     f0103a51 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103a61:	80 f9 2b             	cmp    $0x2b,%cl
f0103a64:	75 0a                	jne    f0103a70 <strtol+0x2d>
		s++;
f0103a66:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103a69:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a6e:	eb 11                	jmp    f0103a81 <strtol+0x3e>
f0103a70:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0103a75:	80 f9 2d             	cmp    $0x2d,%cl
f0103a78:	75 07                	jne    f0103a81 <strtol+0x3e>
		s++, neg = 1;
f0103a7a:	8d 52 01             	lea    0x1(%edx),%edx
f0103a7d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a81:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103a86:	75 15                	jne    f0103a9d <strtol+0x5a>
f0103a88:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a8b:	75 10                	jne    f0103a9d <strtol+0x5a>
f0103a8d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a91:	75 0a                	jne    f0103a9d <strtol+0x5a>
		s += 2, base = 16;
f0103a93:	83 c2 02             	add    $0x2,%edx
f0103a96:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a9b:	eb 10                	jmp    f0103aad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103a9d:	85 c0                	test   %eax,%eax
f0103a9f:	75 0c                	jne    f0103aad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103aa1:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f0103aa3:	80 3a 30             	cmpb   $0x30,(%edx)
f0103aa6:	75 05                	jne    f0103aad <strtol+0x6a>
		s++, base = 8;
f0103aa8:	83 c2 01             	add    $0x1,%edx
f0103aab:	b0 08                	mov    $0x8,%al
		base = 10;
f0103aad:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103ab2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103ab5:	0f b6 0a             	movzbl (%edx),%ecx
f0103ab8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103abb:	89 f0                	mov    %esi,%eax
f0103abd:	3c 09                	cmp    $0x9,%al
f0103abf:	77 08                	ja     f0103ac9 <strtol+0x86>
			dig = *s - '0';
f0103ac1:	0f be c9             	movsbl %cl,%ecx
f0103ac4:	83 e9 30             	sub    $0x30,%ecx
f0103ac7:	eb 20                	jmp    f0103ae9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103ac9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103acc:	89 f0                	mov    %esi,%eax
f0103ace:	3c 19                	cmp    $0x19,%al
f0103ad0:	77 08                	ja     f0103ada <strtol+0x97>
			dig = *s - 'a' + 10;
f0103ad2:	0f be c9             	movsbl %cl,%ecx
f0103ad5:	83 e9 57             	sub    $0x57,%ecx
f0103ad8:	eb 0f                	jmp    f0103ae9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103ada:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103add:	89 f0                	mov    %esi,%eax
f0103adf:	3c 19                	cmp    $0x19,%al
f0103ae1:	77 16                	ja     f0103af9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103ae3:	0f be c9             	movsbl %cl,%ecx
f0103ae6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103ae9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103aec:	7d 0f                	jge    f0103afd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103aee:	83 c2 01             	add    $0x1,%edx
f0103af1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103af5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103af7:	eb bc                	jmp    f0103ab5 <strtol+0x72>
f0103af9:	89 d8                	mov    %ebx,%eax
f0103afb:	eb 02                	jmp    f0103aff <strtol+0xbc>
f0103afd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103aff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b03:	74 05                	je     f0103b0a <strtol+0xc7>
		*endptr = (char *) s;
f0103b05:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b08:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103b0a:	f7 d8                	neg    %eax
f0103b0c:	85 ff                	test   %edi,%edi
f0103b0e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103b11:	5b                   	pop    %ebx
f0103b12:	5e                   	pop    %esi
f0103b13:	5f                   	pop    %edi
f0103b14:	5d                   	pop    %ebp
f0103b15:	c3                   	ret    
f0103b16:	66 90                	xchg   %ax,%ax
f0103b18:	66 90                	xchg   %ax,%ax
f0103b1a:	66 90                	xchg   %ax,%ax
f0103b1c:	66 90                	xchg   %ax,%ax
f0103b1e:	66 90                	xchg   %ax,%ax

f0103b20 <__udivdi3>:
f0103b20:	55                   	push   %ebp
f0103b21:	57                   	push   %edi
f0103b22:	56                   	push   %esi
f0103b23:	83 ec 0c             	sub    $0xc,%esp
f0103b26:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b2a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103b2e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103b32:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b36:	85 c0                	test   %eax,%eax
f0103b38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b3c:	89 ea                	mov    %ebp,%edx
f0103b3e:	89 0c 24             	mov    %ecx,(%esp)
f0103b41:	75 2d                	jne    f0103b70 <__udivdi3+0x50>
f0103b43:	39 e9                	cmp    %ebp,%ecx
f0103b45:	77 61                	ja     f0103ba8 <__udivdi3+0x88>
f0103b47:	85 c9                	test   %ecx,%ecx
f0103b49:	89 ce                	mov    %ecx,%esi
f0103b4b:	75 0b                	jne    f0103b58 <__udivdi3+0x38>
f0103b4d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b52:	31 d2                	xor    %edx,%edx
f0103b54:	f7 f1                	div    %ecx
f0103b56:	89 c6                	mov    %eax,%esi
f0103b58:	31 d2                	xor    %edx,%edx
f0103b5a:	89 e8                	mov    %ebp,%eax
f0103b5c:	f7 f6                	div    %esi
f0103b5e:	89 c5                	mov    %eax,%ebp
f0103b60:	89 f8                	mov    %edi,%eax
f0103b62:	f7 f6                	div    %esi
f0103b64:	89 ea                	mov    %ebp,%edx
f0103b66:	83 c4 0c             	add    $0xc,%esp
f0103b69:	5e                   	pop    %esi
f0103b6a:	5f                   	pop    %edi
f0103b6b:	5d                   	pop    %ebp
f0103b6c:	c3                   	ret    
f0103b6d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b70:	39 e8                	cmp    %ebp,%eax
f0103b72:	77 24                	ja     f0103b98 <__udivdi3+0x78>
f0103b74:	0f bd e8             	bsr    %eax,%ebp
f0103b77:	83 f5 1f             	xor    $0x1f,%ebp
f0103b7a:	75 3c                	jne    f0103bb8 <__udivdi3+0x98>
f0103b7c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103b80:	39 34 24             	cmp    %esi,(%esp)
f0103b83:	0f 86 9f 00 00 00    	jbe    f0103c28 <__udivdi3+0x108>
f0103b89:	39 d0                	cmp    %edx,%eax
f0103b8b:	0f 82 97 00 00 00    	jb     f0103c28 <__udivdi3+0x108>
f0103b91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b98:	31 d2                	xor    %edx,%edx
f0103b9a:	31 c0                	xor    %eax,%eax
f0103b9c:	83 c4 0c             	add    $0xc,%esp
f0103b9f:	5e                   	pop    %esi
f0103ba0:	5f                   	pop    %edi
f0103ba1:	5d                   	pop    %ebp
f0103ba2:	c3                   	ret    
f0103ba3:	90                   	nop
f0103ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ba8:	89 f8                	mov    %edi,%eax
f0103baa:	f7 f1                	div    %ecx
f0103bac:	31 d2                	xor    %edx,%edx
f0103bae:	83 c4 0c             	add    $0xc,%esp
f0103bb1:	5e                   	pop    %esi
f0103bb2:	5f                   	pop    %edi
f0103bb3:	5d                   	pop    %ebp
f0103bb4:	c3                   	ret    
f0103bb5:	8d 76 00             	lea    0x0(%esi),%esi
f0103bb8:	89 e9                	mov    %ebp,%ecx
f0103bba:	8b 3c 24             	mov    (%esp),%edi
f0103bbd:	d3 e0                	shl    %cl,%eax
f0103bbf:	89 c6                	mov    %eax,%esi
f0103bc1:	b8 20 00 00 00       	mov    $0x20,%eax
f0103bc6:	29 e8                	sub    %ebp,%eax
f0103bc8:	89 c1                	mov    %eax,%ecx
f0103bca:	d3 ef                	shr    %cl,%edi
f0103bcc:	89 e9                	mov    %ebp,%ecx
f0103bce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103bd2:	8b 3c 24             	mov    (%esp),%edi
f0103bd5:	09 74 24 08          	or     %esi,0x8(%esp)
f0103bd9:	89 d6                	mov    %edx,%esi
f0103bdb:	d3 e7                	shl    %cl,%edi
f0103bdd:	89 c1                	mov    %eax,%ecx
f0103bdf:	89 3c 24             	mov    %edi,(%esp)
f0103be2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103be6:	d3 ee                	shr    %cl,%esi
f0103be8:	89 e9                	mov    %ebp,%ecx
f0103bea:	d3 e2                	shl    %cl,%edx
f0103bec:	89 c1                	mov    %eax,%ecx
f0103bee:	d3 ef                	shr    %cl,%edi
f0103bf0:	09 d7                	or     %edx,%edi
f0103bf2:	89 f2                	mov    %esi,%edx
f0103bf4:	89 f8                	mov    %edi,%eax
f0103bf6:	f7 74 24 08          	divl   0x8(%esp)
f0103bfa:	89 d6                	mov    %edx,%esi
f0103bfc:	89 c7                	mov    %eax,%edi
f0103bfe:	f7 24 24             	mull   (%esp)
f0103c01:	39 d6                	cmp    %edx,%esi
f0103c03:	89 14 24             	mov    %edx,(%esp)
f0103c06:	72 30                	jb     f0103c38 <__udivdi3+0x118>
f0103c08:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c0c:	89 e9                	mov    %ebp,%ecx
f0103c0e:	d3 e2                	shl    %cl,%edx
f0103c10:	39 c2                	cmp    %eax,%edx
f0103c12:	73 05                	jae    f0103c19 <__udivdi3+0xf9>
f0103c14:	3b 34 24             	cmp    (%esp),%esi
f0103c17:	74 1f                	je     f0103c38 <__udivdi3+0x118>
f0103c19:	89 f8                	mov    %edi,%eax
f0103c1b:	31 d2                	xor    %edx,%edx
f0103c1d:	e9 7a ff ff ff       	jmp    f0103b9c <__udivdi3+0x7c>
f0103c22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c28:	31 d2                	xor    %edx,%edx
f0103c2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c2f:	e9 68 ff ff ff       	jmp    f0103b9c <__udivdi3+0x7c>
f0103c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c38:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103c3b:	31 d2                	xor    %edx,%edx
f0103c3d:	83 c4 0c             	add    $0xc,%esp
f0103c40:	5e                   	pop    %esi
f0103c41:	5f                   	pop    %edi
f0103c42:	5d                   	pop    %ebp
f0103c43:	c3                   	ret    
f0103c44:	66 90                	xchg   %ax,%ax
f0103c46:	66 90                	xchg   %ax,%ax
f0103c48:	66 90                	xchg   %ax,%ax
f0103c4a:	66 90                	xchg   %ax,%ax
f0103c4c:	66 90                	xchg   %ax,%ax
f0103c4e:	66 90                	xchg   %ax,%ax

f0103c50 <__umoddi3>:
f0103c50:	55                   	push   %ebp
f0103c51:	57                   	push   %edi
f0103c52:	56                   	push   %esi
f0103c53:	83 ec 14             	sub    $0x14,%esp
f0103c56:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c5a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c5e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c62:	89 c7                	mov    %eax,%edi
f0103c64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c68:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c6c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c70:	89 34 24             	mov    %esi,(%esp)
f0103c73:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c77:	85 c0                	test   %eax,%eax
f0103c79:	89 c2                	mov    %eax,%edx
f0103c7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c7f:	75 17                	jne    f0103c98 <__umoddi3+0x48>
f0103c81:	39 fe                	cmp    %edi,%esi
f0103c83:	76 4b                	jbe    f0103cd0 <__umoddi3+0x80>
f0103c85:	89 c8                	mov    %ecx,%eax
f0103c87:	89 fa                	mov    %edi,%edx
f0103c89:	f7 f6                	div    %esi
f0103c8b:	89 d0                	mov    %edx,%eax
f0103c8d:	31 d2                	xor    %edx,%edx
f0103c8f:	83 c4 14             	add    $0x14,%esp
f0103c92:	5e                   	pop    %esi
f0103c93:	5f                   	pop    %edi
f0103c94:	5d                   	pop    %ebp
f0103c95:	c3                   	ret    
f0103c96:	66 90                	xchg   %ax,%ax
f0103c98:	39 f8                	cmp    %edi,%eax
f0103c9a:	77 54                	ja     f0103cf0 <__umoddi3+0xa0>
f0103c9c:	0f bd e8             	bsr    %eax,%ebp
f0103c9f:	83 f5 1f             	xor    $0x1f,%ebp
f0103ca2:	75 5c                	jne    f0103d00 <__umoddi3+0xb0>
f0103ca4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103ca8:	39 3c 24             	cmp    %edi,(%esp)
f0103cab:	0f 87 e7 00 00 00    	ja     f0103d98 <__umoddi3+0x148>
f0103cb1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103cb5:	29 f1                	sub    %esi,%ecx
f0103cb7:	19 c7                	sbb    %eax,%edi
f0103cb9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103cbd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103cc1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103cc5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103cc9:	83 c4 14             	add    $0x14,%esp
f0103ccc:	5e                   	pop    %esi
f0103ccd:	5f                   	pop    %edi
f0103cce:	5d                   	pop    %ebp
f0103ccf:	c3                   	ret    
f0103cd0:	85 f6                	test   %esi,%esi
f0103cd2:	89 f5                	mov    %esi,%ebp
f0103cd4:	75 0b                	jne    f0103ce1 <__umoddi3+0x91>
f0103cd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cdb:	31 d2                	xor    %edx,%edx
f0103cdd:	f7 f6                	div    %esi
f0103cdf:	89 c5                	mov    %eax,%ebp
f0103ce1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103ce5:	31 d2                	xor    %edx,%edx
f0103ce7:	f7 f5                	div    %ebp
f0103ce9:	89 c8                	mov    %ecx,%eax
f0103ceb:	f7 f5                	div    %ebp
f0103ced:	eb 9c                	jmp    f0103c8b <__umoddi3+0x3b>
f0103cef:	90                   	nop
f0103cf0:	89 c8                	mov    %ecx,%eax
f0103cf2:	89 fa                	mov    %edi,%edx
f0103cf4:	83 c4 14             	add    $0x14,%esp
f0103cf7:	5e                   	pop    %esi
f0103cf8:	5f                   	pop    %edi
f0103cf9:	5d                   	pop    %ebp
f0103cfa:	c3                   	ret    
f0103cfb:	90                   	nop
f0103cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d00:	8b 04 24             	mov    (%esp),%eax
f0103d03:	be 20 00 00 00       	mov    $0x20,%esi
f0103d08:	89 e9                	mov    %ebp,%ecx
f0103d0a:	29 ee                	sub    %ebp,%esi
f0103d0c:	d3 e2                	shl    %cl,%edx
f0103d0e:	89 f1                	mov    %esi,%ecx
f0103d10:	d3 e8                	shr    %cl,%eax
f0103d12:	89 e9                	mov    %ebp,%ecx
f0103d14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d18:	8b 04 24             	mov    (%esp),%eax
f0103d1b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103d1f:	89 fa                	mov    %edi,%edx
f0103d21:	d3 e0                	shl    %cl,%eax
f0103d23:	89 f1                	mov    %esi,%ecx
f0103d25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d29:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103d2d:	d3 ea                	shr    %cl,%edx
f0103d2f:	89 e9                	mov    %ebp,%ecx
f0103d31:	d3 e7                	shl    %cl,%edi
f0103d33:	89 f1                	mov    %esi,%ecx
f0103d35:	d3 e8                	shr    %cl,%eax
f0103d37:	89 e9                	mov    %ebp,%ecx
f0103d39:	09 f8                	or     %edi,%eax
f0103d3b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103d3f:	f7 74 24 04          	divl   0x4(%esp)
f0103d43:	d3 e7                	shl    %cl,%edi
f0103d45:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d49:	89 d7                	mov    %edx,%edi
f0103d4b:	f7 64 24 08          	mull   0x8(%esp)
f0103d4f:	39 d7                	cmp    %edx,%edi
f0103d51:	89 c1                	mov    %eax,%ecx
f0103d53:	89 14 24             	mov    %edx,(%esp)
f0103d56:	72 2c                	jb     f0103d84 <__umoddi3+0x134>
f0103d58:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d5c:	72 22                	jb     f0103d80 <__umoddi3+0x130>
f0103d5e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d62:	29 c8                	sub    %ecx,%eax
f0103d64:	19 d7                	sbb    %edx,%edi
f0103d66:	89 e9                	mov    %ebp,%ecx
f0103d68:	89 fa                	mov    %edi,%edx
f0103d6a:	d3 e8                	shr    %cl,%eax
f0103d6c:	89 f1                	mov    %esi,%ecx
f0103d6e:	d3 e2                	shl    %cl,%edx
f0103d70:	89 e9                	mov    %ebp,%ecx
f0103d72:	d3 ef                	shr    %cl,%edi
f0103d74:	09 d0                	or     %edx,%eax
f0103d76:	89 fa                	mov    %edi,%edx
f0103d78:	83 c4 14             	add    $0x14,%esp
f0103d7b:	5e                   	pop    %esi
f0103d7c:	5f                   	pop    %edi
f0103d7d:	5d                   	pop    %ebp
f0103d7e:	c3                   	ret    
f0103d7f:	90                   	nop
f0103d80:	39 d7                	cmp    %edx,%edi
f0103d82:	75 da                	jne    f0103d5e <__umoddi3+0x10e>
f0103d84:	8b 14 24             	mov    (%esp),%edx
f0103d87:	89 c1                	mov    %eax,%ecx
f0103d89:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103d8d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103d91:	eb cb                	jmp    f0103d5e <__umoddi3+0x10e>
f0103d93:	90                   	nop
f0103d94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d98:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103d9c:	0f 82 0f ff ff ff    	jb     f0103cb1 <__umoddi3+0x61>
f0103da2:	e9 1a ff ff ff       	jmp    f0103cc1 <__umoddi3+0x71>
