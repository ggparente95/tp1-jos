
obj/kern/kernel:     formato del fichero elf32-i386


Desensamblado de la sección .text:

f0100000 <_start+0xeffffff4>:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
_start = RELOC(entry)

.globl entry
.func entry
entry:
	movw	$0x1234,0x472			# warm boot
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f0100046:	b8 50 39 11 f0       	mov    $0xf0113950,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 33 11 f0       	push   $0xf0113300
f0100058:	e8 c4 15 00 00       	call   f0101621 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 94 06 00 00       	call   f01006f6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 1a 10 f0       	push   $0xf0101a60
f010006f:	e8 0f 0b 00 00       	call   f0100b83 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 ac 09 00 00       	call   f0100a25 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 c0 08 00 00       	call   f0100946 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 39 11 f0 00 	cmpl   $0x0,0xf0113940
f010009a:	74 0f                	je     f01000ab <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009c:	83 ec 0c             	sub    $0xc,%esp
f010009f:	6a 00                	push   $0x0
f01000a1:	e8 a0 08 00 00       	call   f0100946 <monitor>
f01000a6:	83 c4 10             	add    $0x10,%esp
f01000a9:	eb f1                	jmp    f010009c <_panic+0x11>
	panicstr = fmt;
f01000ab:	89 35 40 39 11 f0    	mov    %esi,0xf0113940
	asm volatile("cli; cld");
f01000b1:	fa                   	cli    
f01000b2:	fc                   	cld    
	va_start(ap, fmt);
f01000b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000b6:	83 ec 04             	sub    $0x4,%esp
f01000b9:	ff 75 0c             	pushl  0xc(%ebp)
f01000bc:	ff 75 08             	pushl  0x8(%ebp)
f01000bf:	68 9c 1a 10 f0       	push   $0xf0101a9c
f01000c4:	e8 ba 0a 00 00       	call   f0100b83 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	83 c4 08             	add    $0x8,%esp
f01000cc:	53                   	push   %ebx
f01000cd:	56                   	push   %esi
f01000ce:	e8 8a 0a 00 00       	call   f0100b5d <vcprintf>
	cprintf("\n>>>\n");
f01000d3:	c7 04 24 7b 1a 10 f0 	movl   $0xf0101a7b,(%esp)
f01000da:	e8 a4 0a 00 00       	call   f0100b83 <cprintf>
f01000df:	83 c4 10             	add    $0x10,%esp
f01000e2:	eb b8                	jmp    f010009c <_panic+0x11>

f01000e4 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000eb:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ee:	ff 75 0c             	pushl  0xc(%ebp)
f01000f1:	ff 75 08             	pushl  0x8(%ebp)
f01000f4:	68 81 1a 10 f0       	push   $0xf0101a81
f01000f9:	e8 85 0a 00 00       	call   f0100b83 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	53                   	push   %ebx
f0100102:	ff 75 10             	pushl  0x10(%ebp)
f0100105:	e8 53 0a 00 00       	call   f0100b5d <vcprintf>
	cprintf("\n");
f010010a:	c7 04 24 c6 1a 10 f0 	movl   $0xf0101ac6,(%esp)
f0100111:	e8 6d 0a 00 00       	call   f0100b83 <cprintf>
	va_end(ap);
}
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011c:	c9                   	leave  
f010011d:	c3                   	ret    

f010011e <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010011e:	55                   	push   %ebp
f010011f:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100121:	89 c2                	mov    %eax,%edx
f0100123:	ec                   	in     (%dx),%al
	return data;
}
f0100124:	5d                   	pop    %ebp
f0100125:	c3                   	ret    

f0100126 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100126:	55                   	push   %ebp
f0100127:	89 e5                	mov    %esp,%ebp
f0100129:	89 c1                	mov    %eax,%ecx
f010012b:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010012d:	89 ca                	mov    %ecx,%edx
f010012f:	ee                   	out    %al,(%dx)
}
f0100130:	5d                   	pop    %ebp
f0100131:	c3                   	ret    

f0100132 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100132:	55                   	push   %ebp
f0100133:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100135:	b8 84 00 00 00       	mov    $0x84,%eax
f010013a:	e8 df ff ff ff       	call   f010011e <inb>
	inb(0x84);
f010013f:	b8 84 00 00 00       	mov    $0x84,%eax
f0100144:	e8 d5 ff ff ff       	call   f010011e <inb>
	inb(0x84);
f0100149:	b8 84 00 00 00       	mov    $0x84,%eax
f010014e:	e8 cb ff ff ff       	call   f010011e <inb>
	inb(0x84);
f0100153:	b8 84 00 00 00       	mov    $0x84,%eax
f0100158:	e8 c1 ff ff ff       	call   f010011e <inb>
}
f010015d:	5d                   	pop    %ebp
f010015e:	c3                   	ret    

f010015f <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010015f:	55                   	push   %ebp
f0100160:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100162:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100167:	e8 b2 ff ff ff       	call   f010011e <inb>
f010016c:	a8 01                	test   $0x1,%al
f010016e:	74 0f                	je     f010017f <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f0100170:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100175:	e8 a4 ff ff ff       	call   f010011e <inb>
f010017a:	0f b6 c0             	movzbl %al,%eax
}
f010017d:	5d                   	pop    %ebp
f010017e:	c3                   	ret    
		return -1;
f010017f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100184:	eb f7                	jmp    f010017d <serial_proc_data+0x1e>

f0100186 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f0100186:	55                   	push   %ebp
f0100187:	89 e5                	mov    %esp,%ebp
f0100189:	56                   	push   %esi
f010018a:	53                   	push   %ebx
f010018b:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f010018d:	bb 00 00 00 00       	mov    $0x0,%ebx
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100192:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100197:	e8 82 ff ff ff       	call   f010011e <inb>
f010019c:	a8 20                	test   $0x20,%al
f010019e:	75 12                	jne    f01001b2 <serial_putc+0x2c>
f01001a0:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001a6:	7f 0a                	jg     f01001b2 <serial_putc+0x2c>
	     i++)
		delay();
f01001a8:	e8 85 ff ff ff       	call   f0100132 <delay>
	     i++)
f01001ad:	83 c3 01             	add    $0x1,%ebx
f01001b0:	eb e0                	jmp    f0100192 <serial_putc+0xc>

	outb(COM1 + COM_TX, c);
f01001b2:	89 f0                	mov    %esi,%eax
f01001b4:	0f b6 d0             	movzbl %al,%edx
f01001b7:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001bc:	e8 65 ff ff ff       	call   f0100126 <outb>
}
f01001c1:	5b                   	pop    %ebx
f01001c2:	5e                   	pop    %esi
f01001c3:	5d                   	pop    %ebp
f01001c4:	c3                   	ret    

f01001c5 <serial_init>:

static void
serial_init(void)
{
f01001c5:	55                   	push   %ebp
f01001c6:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001c8:	ba 00 00 00 00       	mov    $0x0,%edx
f01001cd:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001d2:	e8 4f ff ff ff       	call   f0100126 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001d7:	ba 80 00 00 00       	mov    $0x80,%edx
f01001dc:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001e1:	e8 40 ff ff ff       	call   f0100126 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f01001e6:	ba 0c 00 00 00       	mov    $0xc,%edx
f01001eb:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001f0:	e8 31 ff ff ff       	call   f0100126 <outb>
	outb(COM1+COM_DLM, 0);
f01001f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01001fa:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01001ff:	e8 22 ff ff ff       	call   f0100126 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100204:	ba 03 00 00 00       	mov    $0x3,%edx
f0100209:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010020e:	e8 13 ff ff ff       	call   f0100126 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f0100213:	ba 00 00 00 00       	mov    $0x0,%edx
f0100218:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f010021d:	e8 04 ff ff ff       	call   f0100126 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f0100222:	ba 01 00 00 00       	mov    $0x1,%edx
f0100227:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010022c:	e8 f5 fe ff ff       	call   f0100126 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100231:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100236:	e8 e3 fe ff ff       	call   f010011e <inb>
f010023b:	3c ff                	cmp    $0xff,%al
f010023d:	0f 95 05 34 35 11 f0 	setne  0xf0113534
	(void) inb(COM1+COM_IIR);
f0100244:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100249:	e8 d0 fe ff ff       	call   f010011e <inb>
	(void) inb(COM1+COM_RX);
f010024e:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100253:	e8 c6 fe ff ff       	call   f010011e <inb>

}
f0100258:	5d                   	pop    %ebp
f0100259:	c3                   	ret    

f010025a <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f010025a:	55                   	push   %ebp
f010025b:	89 e5                	mov    %esp,%ebp
f010025d:	56                   	push   %esi
f010025e:	53                   	push   %ebx
f010025f:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100261:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100266:	b8 79 03 00 00       	mov    $0x379,%eax
f010026b:	e8 ae fe ff ff       	call   f010011e <inb>
f0100270:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100276:	7f 0e                	jg     f0100286 <lpt_putc+0x2c>
f0100278:	84 c0                	test   %al,%al
f010027a:	78 0a                	js     f0100286 <lpt_putc+0x2c>
		delay();
f010027c:	e8 b1 fe ff ff       	call   f0100132 <delay>
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100281:	83 c3 01             	add    $0x1,%ebx
f0100284:	eb e0                	jmp    f0100266 <lpt_putc+0xc>
	outb(0x378+0, c);
f0100286:	89 f0                	mov    %esi,%eax
f0100288:	0f b6 d0             	movzbl %al,%edx
f010028b:	b8 78 03 00 00       	mov    $0x378,%eax
f0100290:	e8 91 fe ff ff       	call   f0100126 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f0100295:	ba 0d 00 00 00       	mov    $0xd,%edx
f010029a:	b8 7a 03 00 00       	mov    $0x37a,%eax
f010029f:	e8 82 fe ff ff       	call   f0100126 <outb>
	outb(0x378+2, 0x08);
f01002a4:	ba 08 00 00 00       	mov    $0x8,%edx
f01002a9:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ae:	e8 73 fe ff ff       	call   f0100126 <outb>
}
f01002b3:	5b                   	pop    %ebx
f01002b4:	5e                   	pop    %esi
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002c0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002c7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002ce:	5a a5 
	if (*cp != 0xA55A) {
f01002d0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002d7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002db:	74 63                	je     f0100340 <cga_init+0x89>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002dd:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
f01002e4:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e7:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01002ee:	8b 35 30 35 11 f0    	mov    0xf0113530,%esi
f01002f4:	ba 0e 00 00 00       	mov    $0xe,%edx
f01002f9:	89 f0                	mov    %esi,%eax
f01002fb:	e8 26 fe ff ff       	call   f0100126 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100300:	8d 7e 01             	lea    0x1(%esi),%edi
f0100303:	89 f8                	mov    %edi,%eax
f0100305:	e8 14 fe ff ff       	call   f010011e <inb>
f010030a:	0f b6 d8             	movzbl %al,%ebx
f010030d:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100310:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100315:	89 f0                	mov    %esi,%eax
f0100317:	e8 0a fe ff ff       	call   f0100126 <outb>
	pos |= inb(addr_6845 + 1);
f010031c:	89 f8                	mov    %edi,%eax
f010031e:	e8 fb fd ff ff       	call   f010011e <inb>

	crt_buf = (uint16_t*) cp;
f0100323:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100326:	89 0d 2c 35 11 f0    	mov    %ecx,0xf011352c
	pos |= inb(addr_6845 + 1);
f010032c:	0f b6 c0             	movzbl %al,%eax
f010032f:	09 c3                	or     %eax,%ebx
	crt_pos = pos;
f0100331:	66 89 1d 28 35 11 f0 	mov    %bx,0xf0113528
}
f0100338:	83 c4 04             	add    $0x4,%esp
f010033b:	5b                   	pop    %ebx
f010033c:	5e                   	pop    %esi
f010033d:	5f                   	pop    %edi
f010033e:	5d                   	pop    %ebp
f010033f:	c3                   	ret    
		*cp = was;
f0100340:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100347:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
f010034e:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100351:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
f0100358:	eb 94                	jmp    f01002ee <cga_init+0x37>

f010035a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010035a:	55                   	push   %ebp
f010035b:	89 e5                	mov    %esp,%ebp
f010035d:	53                   	push   %ebx
f010035e:	83 ec 04             	sub    $0x4,%esp
f0100361:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100363:	ff d3                	call   *%ebx
f0100365:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100368:	74 2d                	je     f0100397 <cons_intr+0x3d>
		if (c == 0)
f010036a:	85 c0                	test   %eax,%eax
f010036c:	74 f5                	je     f0100363 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f010036e:	8b 0d 24 35 11 f0    	mov    0xf0113524,%ecx
f0100374:	8d 51 01             	lea    0x1(%ecx),%edx
f0100377:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
f010037d:	88 81 20 33 11 f0    	mov    %al,-0xfeecce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100383:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100389:	75 d8                	jne    f0100363 <cons_intr+0x9>
			cons.wpos = 0;
f010038b:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
f0100392:	00 00 00 
f0100395:	eb cc                	jmp    f0100363 <cons_intr+0x9>
	}
}
f0100397:	83 c4 04             	add    $0x4,%esp
f010039a:	5b                   	pop    %ebx
f010039b:	5d                   	pop    %ebp
f010039c:	c3                   	ret    

f010039d <kbd_proc_data>:
{
f010039d:	55                   	push   %ebp
f010039e:	89 e5                	mov    %esp,%ebp
f01003a0:	53                   	push   %ebx
f01003a1:	83 ec 04             	sub    $0x4,%esp
	stat = inb(KBSTATP);
f01003a4:	b8 64 00 00 00       	mov    $0x64,%eax
f01003a9:	e8 70 fd ff ff       	call   f010011e <inb>
	if ((stat & KBS_DIB) == 0)
f01003ae:	a8 01                	test   $0x1,%al
f01003b0:	0f 84 06 01 00 00    	je     f01004bc <kbd_proc_data+0x11f>
	if (stat & KBS_TERR)
f01003b6:	a8 20                	test   $0x20,%al
f01003b8:	0f 85 05 01 00 00    	jne    f01004c3 <kbd_proc_data+0x126>
	data = inb(KBDATAP);
f01003be:	b8 60 00 00 00       	mov    $0x60,%eax
f01003c3:	e8 56 fd ff ff       	call   f010011e <inb>
	if (data == 0xE0) {
f01003c8:	3c e0                	cmp    $0xe0,%al
f01003ca:	0f 84 93 00 00 00    	je     f0100463 <kbd_proc_data+0xc6>
	} else if (data & 0x80) {
f01003d0:	84 c0                	test   %al,%al
f01003d2:	0f 88 9e 00 00 00    	js     f0100476 <kbd_proc_data+0xd9>
	} else if (shift & E0ESC) {
f01003d8:	8b 15 00 33 11 f0    	mov    0xf0113300,%edx
f01003de:	f6 c2 40             	test   $0x40,%dl
f01003e1:	74 0c                	je     f01003ef <kbd_proc_data+0x52>
		data |= 0x80;
f01003e3:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f01003e6:	83 e2 bf             	and    $0xffffffbf,%edx
f01003e9:	89 15 00 33 11 f0    	mov    %edx,0xf0113300
	shift |= shiftcode[data];
f01003ef:	0f b6 c0             	movzbl %al,%eax
f01003f2:	0f b6 90 20 1c 10 f0 	movzbl -0xfefe3e0(%eax),%edx
f01003f9:	0b 15 00 33 11 f0    	or     0xf0113300,%edx
	shift ^= togglecode[data];
f01003ff:	0f b6 88 20 1b 10 f0 	movzbl -0xfefe4e0(%eax),%ecx
f0100406:	31 ca                	xor    %ecx,%edx
f0100408:	89 15 00 33 11 f0    	mov    %edx,0xf0113300
	c = charcode[shift & (CTL | SHIFT)][data];
f010040e:	89 d1                	mov    %edx,%ecx
f0100410:	83 e1 03             	and    $0x3,%ecx
f0100413:	8b 0c 8d 00 1b 10 f0 	mov    -0xfefe500(,%ecx,4),%ecx
f010041a:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010041e:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100421:	f6 c2 08             	test   $0x8,%dl
f0100424:	74 0d                	je     f0100433 <kbd_proc_data+0x96>
		if ('a' <= c && c <= 'z')
f0100426:	89 d8                	mov    %ebx,%eax
f0100428:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010042b:	83 f9 19             	cmp    $0x19,%ecx
f010042e:	77 7b                	ja     f01004ab <kbd_proc_data+0x10e>
			c += 'A' - 'a';
f0100430:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100433:	f7 d2                	not    %edx
f0100435:	f6 c2 06             	test   $0x6,%dl
f0100438:	75 35                	jne    f010046f <kbd_proc_data+0xd2>
f010043a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100440:	75 2d                	jne    f010046f <kbd_proc_data+0xd2>
		cprintf("Rebooting!\n");
f0100442:	83 ec 0c             	sub    $0xc,%esp
f0100445:	68 bc 1a 10 f0       	push   $0xf0101abc
f010044a:	e8 34 07 00 00       	call   f0100b83 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f010044f:	ba 03 00 00 00       	mov    $0x3,%edx
f0100454:	b8 92 00 00 00       	mov    $0x92,%eax
f0100459:	e8 c8 fc ff ff       	call   f0100126 <outb>
f010045e:	83 c4 10             	add    $0x10,%esp
f0100461:	eb 0c                	jmp    f010046f <kbd_proc_data+0xd2>
		shift |= E0ESC;
f0100463:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
		return 0;
f010046a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010046f:	89 d8                	mov    %ebx,%eax
f0100471:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100474:	c9                   	leave  
f0100475:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100476:	8b 15 00 33 11 f0    	mov    0xf0113300,%edx
f010047c:	89 d3                	mov    %edx,%ebx
f010047e:	83 e3 40             	and    $0x40,%ebx
f0100481:	89 c1                	mov    %eax,%ecx
f0100483:	83 e1 7f             	and    $0x7f,%ecx
f0100486:	85 db                	test   %ebx,%ebx
f0100488:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f010048b:	0f b6 c0             	movzbl %al,%eax
f010048e:	0f b6 80 20 1c 10 f0 	movzbl -0xfefe3e0(%eax),%eax
f0100495:	83 c8 40             	or     $0x40,%eax
f0100498:	0f b6 c0             	movzbl %al,%eax
f010049b:	f7 d0                	not    %eax
f010049d:	21 d0                	and    %edx,%eax
f010049f:	a3 00 33 11 f0       	mov    %eax,0xf0113300
		return 0;
f01004a4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01004a9:	eb c4                	jmp    f010046f <kbd_proc_data+0xd2>
		else if ('A' <= c && c <= 'Z')
f01004ab:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01004ae:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004b1:	83 f8 1a             	cmp    $0x1a,%eax
f01004b4:	0f 42 d9             	cmovb  %ecx,%ebx
f01004b7:	e9 77 ff ff ff       	jmp    f0100433 <kbd_proc_data+0x96>
		return -1;
f01004bc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004c1:	eb ac                	jmp    f010046f <kbd_proc_data+0xd2>
		return -1;
f01004c3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004c8:	eb a5                	jmp    f010046f <kbd_proc_data+0xd2>

f01004ca <cga_putc>:
{
f01004ca:	55                   	push   %ebp
f01004cb:	89 e5                	mov    %esp,%ebp
f01004cd:	57                   	push   %edi
f01004ce:	56                   	push   %esi
f01004cf:	53                   	push   %ebx
f01004d0:	83 ec 0c             	sub    $0xc,%esp
	if (!(c & ~0xFF))
f01004d3:	89 c1                	mov    %eax,%ecx
f01004d5:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004db:	89 c2                	mov    %eax,%edx
f01004dd:	80 ce 07             	or     $0x7,%dh
f01004e0:	85 c9                	test   %ecx,%ecx
f01004e2:	0f 44 c2             	cmove  %edx,%eax
	switch (c & 0xff) {
f01004e5:	0f b6 d0             	movzbl %al,%edx
f01004e8:	83 fa 09             	cmp    $0x9,%edx
f01004eb:	0f 84 c9 00 00 00    	je     f01005ba <cga_putc+0xf0>
f01004f1:	83 fa 09             	cmp    $0x9,%edx
f01004f4:	0f 8e 81 00 00 00    	jle    f010057b <cga_putc+0xb1>
f01004fa:	83 fa 0a             	cmp    $0xa,%edx
f01004fd:	0f 84 aa 00 00 00    	je     f01005ad <cga_putc+0xe3>
f0100503:	83 fa 0d             	cmp    $0xd,%edx
f0100506:	0f 85 e5 00 00 00    	jne    f01005f1 <cga_putc+0x127>
		crt_pos -= (crt_pos % CRT_COLS);
f010050c:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100513:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100519:	c1 e8 16             	shr    $0x16,%eax
f010051c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010051f:	c1 e0 04             	shl    $0x4,%eax
f0100522:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	if (crt_pos >= CRT_SIZE) {
f0100528:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f010052f:	cf 07 
f0100531:	0f 87 dd 00 00 00    	ja     f0100614 <cga_putc+0x14a>
	outb(addr_6845, 14);
f0100537:	8b 3d 30 35 11 f0    	mov    0xf0113530,%edi
f010053d:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100542:	89 f8                	mov    %edi,%eax
f0100544:	e8 dd fb ff ff       	call   f0100126 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100549:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
f0100550:	8d 77 01             	lea    0x1(%edi),%esi
f0100553:	0f b6 d7             	movzbl %bh,%edx
f0100556:	89 f0                	mov    %esi,%eax
f0100558:	e8 c9 fb ff ff       	call   f0100126 <outb>
	outb(addr_6845, 15);
f010055d:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100562:	89 f8                	mov    %edi,%eax
f0100564:	e8 bd fb ff ff       	call   f0100126 <outb>
	outb(addr_6845 + 1, crt_pos);
f0100569:	0f b6 d3             	movzbl %bl,%edx
f010056c:	89 f0                	mov    %esi,%eax
f010056e:	e8 b3 fb ff ff       	call   f0100126 <outb>
}
f0100573:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100576:	5b                   	pop    %ebx
f0100577:	5e                   	pop    %esi
f0100578:	5f                   	pop    %edi
f0100579:	5d                   	pop    %ebp
f010057a:	c3                   	ret    
	switch (c & 0xff) {
f010057b:	83 fa 08             	cmp    $0x8,%edx
f010057e:	75 71                	jne    f01005f1 <cga_putc+0x127>
		if (crt_pos > 0) {
f0100580:	0f b7 15 28 35 11 f0 	movzwl 0xf0113528,%edx
f0100587:	66 85 d2             	test   %dx,%dx
f010058a:	74 ab                	je     f0100537 <cga_putc+0x6d>
			crt_pos--;
f010058c:	83 ea 01             	sub    $0x1,%edx
f010058f:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100596:	0f b7 d2             	movzwl %dx,%edx
f0100599:	b0 00                	mov    $0x0,%al
f010059b:	83 c8 20             	or     $0x20,%eax
f010059e:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f01005a4:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01005a8:	e9 7b ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		crt_pos += CRT_COLS;
f01005ad:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
f01005b4:	50 
f01005b5:	e9 52 ff ff ff       	jmp    f010050c <cga_putc+0x42>
		cons_putc(' ');
f01005ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01005bf:	e8 98 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01005c9:	e8 8e 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01005d3:	e8 84 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01005dd:	e8 7a 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01005e7:	e8 70 00 00 00       	call   f010065c <cons_putc>
		break;
f01005ec:	e9 37 ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		crt_buf[crt_pos++] = c;		/* write the character */
f01005f1:	0f b7 15 28 35 11 f0 	movzwl 0xf0113528,%edx
f01005f8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005fb:	66 89 0d 28 35 11 f0 	mov    %cx,0xf0113528
f0100602:	0f b7 d2             	movzwl %dx,%edx
f0100605:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f010060b:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
f010060f:	e9 14 ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100614:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f0100619:	83 ec 04             	sub    $0x4,%esp
f010061c:	68 00 0f 00 00       	push   $0xf00
f0100621:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100627:	52                   	push   %edx
f0100628:	50                   	push   %eax
f0100629:	e8 3f 10 00 00       	call   f010166d <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010062e:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100634:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010063a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100640:	83 c4 10             	add    $0x10,%esp
f0100643:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100648:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010064b:	39 d0                	cmp    %edx,%eax
f010064d:	75 f4                	jne    f0100643 <cga_putc+0x179>
		crt_pos -= CRT_COLS;
f010064f:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
f0100656:	50 
f0100657:	e9 db fe ff ff       	jmp    f0100537 <cga_putc+0x6d>

f010065c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	53                   	push   %ebx
f0100660:	83 ec 04             	sub    $0x4,%esp
f0100663:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100665:	e8 1c fb ff ff       	call   f0100186 <serial_putc>
	lpt_putc(c);
f010066a:	89 d8                	mov    %ebx,%eax
f010066c:	e8 e9 fb ff ff       	call   f010025a <lpt_putc>
	cga_putc(c);
f0100671:	89 d8                	mov    %ebx,%eax
f0100673:	e8 52 fe ff ff       	call   f01004ca <cga_putc>
}
f0100678:	83 c4 04             	add    $0x4,%esp
f010067b:	5b                   	pop    %ebx
f010067c:	5d                   	pop    %ebp
f010067d:	c3                   	ret    

f010067e <serial_intr>:
	if (serial_exists)
f010067e:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f0100685:	75 02                	jne    f0100689 <serial_intr+0xb>
f0100687:	f3 c3                	repz ret 
{
f0100689:	55                   	push   %ebp
f010068a:	89 e5                	mov    %esp,%ebp
f010068c:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010068f:	b8 5f 01 10 f0       	mov    $0xf010015f,%eax
f0100694:	e8 c1 fc ff ff       	call   f010035a <cons_intr>
}
f0100699:	c9                   	leave  
f010069a:	c3                   	ret    

f010069b <kbd_intr>:
{
f010069b:	55                   	push   %ebp
f010069c:	89 e5                	mov    %esp,%ebp
f010069e:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006a1:	b8 9d 03 10 f0       	mov    $0xf010039d,%eax
f01006a6:	e8 af fc ff ff       	call   f010035a <cons_intr>
}
f01006ab:	c9                   	leave  
f01006ac:	c3                   	ret    

f01006ad <cons_getc>:
{
f01006ad:	55                   	push   %ebp
f01006ae:	89 e5                	mov    %esp,%ebp
f01006b0:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01006b3:	e8 c6 ff ff ff       	call   f010067e <serial_intr>
	kbd_intr();
f01006b8:	e8 de ff ff ff       	call   f010069b <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01006bd:	8b 15 20 35 11 f0    	mov    0xf0113520,%edx
	return 0;
f01006c3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01006c8:	3b 15 24 35 11 f0    	cmp    0xf0113524,%edx
f01006ce:	74 18                	je     f01006e8 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01006d0:	8d 4a 01             	lea    0x1(%edx),%ecx
f01006d3:	89 0d 20 35 11 f0    	mov    %ecx,0xf0113520
f01006d9:	0f b6 82 20 33 11 f0 	movzbl -0xfeecce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01006e0:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01006e6:	74 02                	je     f01006ea <cons_getc+0x3d>
}
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    
			cons.rpos = 0;
f01006ea:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
f01006f1:	00 00 00 
f01006f4:	eb f2                	jmp    f01006e8 <cons_getc+0x3b>

f01006f6 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01006f6:	55                   	push   %ebp
f01006f7:	89 e5                	mov    %esp,%ebp
f01006f9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006fc:	e8 b6 fb ff ff       	call   f01002b7 <cga_init>
	kbd_init();
	serial_init();
f0100701:	e8 bf fa ff ff       	call   f01001c5 <serial_init>

	if (!serial_exists)
f0100706:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f010070d:	74 02                	je     f0100711 <cons_init+0x1b>
		cprintf("Serial port does not exist!\n");
}
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 c8 1a 10 f0       	push   $0xf0101ac8
f0100719:	e8 65 04 00 00       	call   f0100b83 <cprintf>
f010071e:	83 c4 10             	add    $0x10,%esp
}
f0100721:	eb ec                	jmp    f010070f <cons_init+0x19>

f0100723 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100723:	55                   	push   %ebp
f0100724:	89 e5                	mov    %esp,%ebp
f0100726:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100729:	8b 45 08             	mov    0x8(%ebp),%eax
f010072c:	e8 2b ff ff ff       	call   f010065c <cons_putc>
}
f0100731:	c9                   	leave  
f0100732:	c3                   	ret    

f0100733 <getchar>:

int
getchar(void)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100739:	e8 6f ff ff ff       	call   f01006ad <cons_getc>
f010073e:	85 c0                	test   %eax,%eax
f0100740:	74 f7                	je     f0100739 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100742:	c9                   	leave  
f0100743:	c3                   	ret    

f0100744 <iscons>:

int
iscons(int fdnum)
{
f0100744:	55                   	push   %ebp
f0100745:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100747:	b8 01 00 00 00       	mov    $0x1,%eax
f010074c:	5d                   	pop    %ebp
f010074d:	c3                   	ret    

f010074e <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
f0100751:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100754:	68 20 1d 10 f0       	push   $0xf0101d20
f0100759:	68 3e 1d 10 f0       	push   $0xf0101d3e
f010075e:	68 43 1d 10 f0       	push   $0xf0101d43
f0100763:	e8 1b 04 00 00       	call   f0100b83 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 ac 1d 10 f0       	push   $0xf0101dac
f0100770:	68 4c 1d 10 f0       	push   $0xf0101d4c
f0100775:	68 43 1d 10 f0       	push   $0xf0101d43
f010077a:	e8 04 04 00 00       	call   f0100b83 <cprintf>
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010078c:	68 55 1d 10 f0       	push   $0xf0101d55
f0100791:	e8 ed 03 00 00       	call   f0100b83 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100796:	83 c4 08             	add    $0x8,%esp
f0100799:	68 0c 00 10 00       	push   $0x10000c
f010079e:	68 d4 1d 10 f0       	push   $0xf0101dd4
f01007a3:	e8 db 03 00 00       	call   f0100b83 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	68 0c 00 10 00       	push   $0x10000c
f01007b0:	68 0c 00 10 f0       	push   $0xf010000c
f01007b5:	68 fc 1d 10 f0       	push   $0xf0101dfc
f01007ba:	e8 c4 03 00 00       	call   f0100b83 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 59 1a 10 00       	push   $0x101a59
f01007c7:	68 59 1a 10 f0       	push   $0xf0101a59
f01007cc:	68 20 1e 10 f0       	push   $0xf0101e20
f01007d1:	e8 ad 03 00 00       	call   f0100b83 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 00 33 11 00       	push   $0x113300
f01007de:	68 00 33 11 f0       	push   $0xf0113300
f01007e3:	68 44 1e 10 f0       	push   $0xf0101e44
f01007e8:	e8 96 03 00 00       	call   f0100b83 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 50 39 11 00       	push   $0x113950
f01007f5:	68 50 39 11 f0       	push   $0xf0113950
f01007fa:	68 68 1e 10 f0       	push   $0xf0101e68
f01007ff:	e8 7f 03 00 00       	call   f0100b83 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100804:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100807:	b8 4f 3d 11 f0       	mov    $0xf0113d4f,%eax
f010080c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100811:	c1 f8 0a             	sar    $0xa,%eax
f0100814:	50                   	push   %eax
f0100815:	68 8c 1e 10 f0       	push   $0xf0101e8c
f010081a:	e8 64 03 00 00       	call   f0100b83 <cprintf>
	return 0;
}
f010081f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100824:	c9                   	leave  
f0100825:	c3                   	ret    

f0100826 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100826:	55                   	push   %ebp
f0100827:	89 e5                	mov    %esp,%ebp
f0100829:	57                   	push   %edi
f010082a:	56                   	push   %esi
f010082b:	53                   	push   %ebx
f010082c:	83 ec 5c             	sub    $0x5c,%esp
f010082f:	89 c3                	mov    %eax,%ebx
f0100831:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100834:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010083b:	be 00 00 00 00       	mov    $0x0,%esi
f0100840:	eb 5d                	jmp    f010089f <runcmd+0x79>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100842:	83 ec 08             	sub    $0x8,%esp
f0100845:	0f be c0             	movsbl %al,%eax
f0100848:	50                   	push   %eax
f0100849:	68 6e 1d 10 f0       	push   $0xf0101d6e
f010084e:	e8 91 0d 00 00       	call   f01015e4 <strchr>
f0100853:	83 c4 10             	add    $0x10,%esp
f0100856:	85 c0                	test   %eax,%eax
f0100858:	74 0a                	je     f0100864 <runcmd+0x3e>
			*buf++ = 0;
f010085a:	c6 03 00             	movb   $0x0,(%ebx)
f010085d:	89 f7                	mov    %esi,%edi
f010085f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100862:	eb 39                	jmp    f010089d <runcmd+0x77>
		if (*buf == 0)
f0100864:	0f b6 03             	movzbl (%ebx),%eax
f0100867:	84 c0                	test   %al,%al
f0100869:	74 3b                	je     f01008a6 <runcmd+0x80>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010086b:	83 fe 0f             	cmp    $0xf,%esi
f010086e:	0f 84 86 00 00 00    	je     f01008fa <runcmd+0xd4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f0100874:	8d 7e 01             	lea    0x1(%esi),%edi
f0100877:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010087b:	83 ec 08             	sub    $0x8,%esp
f010087e:	0f be c0             	movsbl %al,%eax
f0100881:	50                   	push   %eax
f0100882:	68 6e 1d 10 f0       	push   $0xf0101d6e
f0100887:	e8 58 0d 00 00       	call   f01015e4 <strchr>
f010088c:	83 c4 10             	add    $0x10,%esp
f010088f:	85 c0                	test   %eax,%eax
f0100891:	75 0a                	jne    f010089d <runcmd+0x77>
			buf++;
f0100893:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100896:	0f b6 03             	movzbl (%ebx),%eax
f0100899:	84 c0                	test   %al,%al
f010089b:	75 de                	jne    f010087b <runcmd+0x55>
			*buf++ = 0;
f010089d:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f010089f:	0f b6 03             	movzbl (%ebx),%eax
f01008a2:	84 c0                	test   %al,%al
f01008a4:	75 9c                	jne    f0100842 <runcmd+0x1c>
	}
	argv[argc] = 0;
f01008a6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ad:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ae:	85 f6                	test   %esi,%esi
f01008b0:	74 5f                	je     f0100911 <runcmd+0xeb>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b2:	83 ec 08             	sub    $0x8,%esp
f01008b5:	68 3e 1d 10 f0       	push   $0xf0101d3e
f01008ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bd:	e8 c4 0c 00 00       	call   f0101586 <strcmp>
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 57                	je     f0100920 <runcmd+0xfa>
f01008c9:	83 ec 08             	sub    $0x8,%esp
f01008cc:	68 4c 1d 10 f0       	push   $0xf0101d4c
f01008d1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d4:	e8 ad 0c 00 00       	call   f0101586 <strcmp>
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	74 3b                	je     f010091b <runcmd+0xf5>
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e0:	83 ec 08             	sub    $0x8,%esp
f01008e3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e6:	68 90 1d 10 f0       	push   $0xf0101d90
f01008eb:	e8 93 02 00 00       	call   f0100b83 <cprintf>
	return 0;
f01008f0:	83 c4 10             	add    $0x10,%esp
f01008f3:	be 00 00 00 00       	mov    $0x0,%esi
f01008f8:	eb 17                	jmp    f0100911 <runcmd+0xeb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008fa:	83 ec 08             	sub    $0x8,%esp
f01008fd:	6a 10                	push   $0x10
f01008ff:	68 73 1d 10 f0       	push   $0xf0101d73
f0100904:	e8 7a 02 00 00       	call   f0100b83 <cprintf>
			return 0;
f0100909:	83 c4 10             	add    $0x10,%esp
f010090c:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100911:	89 f0                	mov    %esi,%eax
f0100913:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100916:	5b                   	pop    %ebx
f0100917:	5e                   	pop    %esi
f0100918:	5f                   	pop    %edi
f0100919:	5d                   	pop    %ebp
f010091a:	c3                   	ret    
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010091b:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100920:	83 ec 04             	sub    $0x4,%esp
f0100923:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100926:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100929:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092c:	52                   	push   %edx
f010092d:	56                   	push   %esi
f010092e:	ff 14 85 0c 1f 10 f0 	call   *-0xfefe0f4(,%eax,4)
f0100935:	89 c6                	mov    %eax,%esi
f0100937:	83 c4 10             	add    $0x10,%esp
f010093a:	eb d5                	jmp    f0100911 <runcmd+0xeb>

f010093c <mon_backtrace>:
{
f010093c:	55                   	push   %ebp
f010093d:	89 e5                	mov    %esp,%ebp
}
f010093f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100944:	5d                   	pop    %ebp
f0100945:	c3                   	ret    

f0100946 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100946:	55                   	push   %ebp
f0100947:	89 e5                	mov    %esp,%ebp
f0100949:	53                   	push   %ebx
f010094a:	83 ec 10             	sub    $0x10,%esp
f010094d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100950:	68 b8 1e 10 f0       	push   $0xf0101eb8
f0100955:	e8 29 02 00 00       	call   f0100b83 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010095a:	c7 04 24 dc 1e 10 f0 	movl   $0xf0101edc,(%esp)
f0100961:	e8 1d 02 00 00       	call   f0100b83 <cprintf>
f0100966:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100969:	83 ec 0c             	sub    $0xc,%esp
f010096c:	68 a6 1d 10 f0       	push   $0xf0101da6
f0100971:	e8 51 0a 00 00       	call   f01013c7 <readline>
		if (buf != NULL)
f0100976:	83 c4 10             	add    $0x10,%esp
f0100979:	85 c0                	test   %eax,%eax
f010097b:	74 ec                	je     f0100969 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f010097d:	89 da                	mov    %ebx,%edx
f010097f:	e8 a2 fe ff ff       	call   f0100826 <runcmd>
f0100984:	85 c0                	test   %eax,%eax
f0100986:	79 e1                	jns    f0100969 <monitor+0x23>
				break;
	}
}
f0100988:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010098b:	c9                   	leave  
f010098c:	c3                   	ret    

f010098d <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f010098d:	55                   	push   %ebp
f010098e:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100990:	0f 01 38             	invlpg (%eax)
}
f0100993:	5d                   	pop    %ebp
f0100994:	c3                   	ret    

f0100995 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
f0100998:	56                   	push   %esi
f0100999:	53                   	push   %ebx
f010099a:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010099c:	83 ec 0c             	sub    $0xc,%esp
f010099f:	50                   	push   %eax
f01009a0:	e8 5a 01 00 00       	call   f0100aff <mc146818_read>
f01009a5:	89 c3                	mov    %eax,%ebx
f01009a7:	83 c6 01             	add    $0x1,%esi
f01009aa:	89 34 24             	mov    %esi,(%esp)
f01009ad:	e8 4d 01 00 00       	call   f0100aff <mc146818_read>
f01009b2:	c1 e0 08             	shl    $0x8,%eax
f01009b5:	09 d8                	or     %ebx,%eax
}
f01009b7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009ba:	5b                   	pop    %ebx
f01009bb:	5e                   	pop    %esi
f01009bc:	5d                   	pop    %ebp
f01009bd:	c3                   	ret    

f01009be <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f01009be:	55                   	push   %ebp
f01009bf:	89 e5                	mov    %esp,%ebp
f01009c1:	56                   	push   %esi
f01009c2:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01009c3:	b8 15 00 00 00       	mov    $0x15,%eax
f01009c8:	e8 c8 ff ff ff       	call   f0100995 <nvram_read>
f01009cd:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01009cf:	b8 17 00 00 00       	mov    $0x17,%eax
f01009d4:	e8 bc ff ff ff       	call   f0100995 <nvram_read>
f01009d9:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01009db:	b8 34 00 00 00       	mov    $0x34,%eax
f01009e0:	e8 b0 ff ff ff       	call   f0100995 <nvram_read>
f01009e5:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01009e8:	85 c0                	test   %eax,%eax
f01009ea:	75 0e                	jne    f01009fa <i386_detect_memory+0x3c>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;
f01009ec:	89 d8                	mov    %ebx,%eax
	else if (extmem)
f01009ee:	85 f6                	test   %esi,%esi
f01009f0:	74 0d                	je     f01009ff <i386_detect_memory+0x41>
		totalmem = 1 * 1024 + extmem;
f01009f2:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01009f8:	eb 05                	jmp    f01009ff <i386_detect_memory+0x41>
		totalmem = 16 * 1024 + ext16mem;
f01009fa:	05 00 40 00 00       	add    $0x4000,%eax

	npages = totalmem / (PGSIZE / 1024);
f01009ff:	89 c2                	mov    %eax,%edx
f0100a01:	c1 ea 02             	shr    $0x2,%edx
f0100a04:	89 15 44 39 11 f0    	mov    %edx,0xf0113944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a0a:	89 c2                	mov    %eax,%edx
f0100a0c:	29 da                	sub    %ebx,%edx
f0100a0e:	52                   	push   %edx
f0100a0f:	53                   	push   %ebx
f0100a10:	50                   	push   %eax
f0100a11:	68 1c 1f 10 f0       	push   $0xf0101f1c
f0100a16:	e8 68 01 00 00       	call   f0100b83 <cprintf>
	        totalmem,
	        basemem,
	        totalmem - basemem);
}
f0100a1b:	83 c4 10             	add    $0x10,%esp
f0100a1e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a21:	5b                   	pop    %ebx
f0100a22:	5e                   	pop    %esi
f0100a23:	5d                   	pop    %ebp
f0100a24:	c3                   	ret    

f0100a25 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
f0100a28:	83 ec 08             	sub    $0x8,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0100a2b:	e8 8e ff ff ff       	call   f01009be <i386_detect_memory>

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100a30:	83 ec 04             	sub    $0x4,%esp
f0100a33:	68 58 1f 10 f0       	push   $0xf0101f58
f0100a38:	68 83 00 00 00       	push   $0x83
f0100a3d:	68 84 1f 10 f0       	push   $0xf0101f84
f0100a42:	e8 44 f6 ff ff       	call   f010008b <_panic>

f0100a47 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a47:	55                   	push   %ebp
f0100a48:	89 e5                	mov    %esp,%ebp
f0100a4a:	56                   	push   %esi
f0100a4b:	53                   	push   %ebx
f0100a4c:	8b 1d 38 35 11 f0    	mov    0xf0113538,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100a52:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a57:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a5c:	be 01 00 00 00       	mov    $0x1,%esi
f0100a61:	eb 24                	jmp    f0100a87 <page_init+0x40>
f0100a63:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100a6a:	89 d1                	mov    %edx,%ecx
f0100a6c:	03 0d 4c 39 11 f0    	add    0xf011394c,%ecx
f0100a72:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100a78:	89 19                	mov    %ebx,(%ecx)
	for (i = 0; i < npages; i++) {
f0100a7a:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100a7d:	89 d3                	mov    %edx,%ebx
f0100a7f:	03 1d 4c 39 11 f0    	add    0xf011394c,%ebx
f0100a85:	89 f2                	mov    %esi,%edx
	for (i = 0; i < npages; i++) {
f0100a87:	39 05 44 39 11 f0    	cmp    %eax,0xf0113944
f0100a8d:	77 d4                	ja     f0100a63 <page_init+0x1c>
f0100a8f:	84 d2                	test   %dl,%dl
f0100a91:	75 04                	jne    f0100a97 <page_init+0x50>
	}
}
f0100a93:	5b                   	pop    %ebx
f0100a94:	5e                   	pop    %esi
f0100a95:	5d                   	pop    %ebp
f0100a96:	c3                   	ret    
f0100a97:	89 1d 38 35 11 f0    	mov    %ebx,0xf0113538
f0100a9d:	eb f4                	jmp    f0100a93 <page_init+0x4c>

f0100a9f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100a9f:	55                   	push   %ebp
f0100aa0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100aa2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aa7:	5d                   	pop    %ebp
f0100aa8:	c3                   	ret    

f0100aa9 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100aa9:	55                   	push   %ebp
f0100aaa:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100aac:	5d                   	pop    %ebp
f0100aad:	c3                   	ret    

f0100aae <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo *pp)
{
f0100aae:	55                   	push   %ebp
f0100aaf:	89 e5                	mov    %esp,%ebp
f0100ab1:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ab4:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100ab9:	5d                   	pop    %ebp
f0100aba:	c3                   	ret    

f0100abb <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100abb:	55                   	push   %ebp
f0100abc:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100abe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ac3:	5d                   	pop    %ebp
f0100ac4:	c3                   	ret    

f0100ac5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100ac5:	55                   	push   %ebp
f0100ac6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100ac8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100acd:	5d                   	pop    %ebp
f0100ace:	c3                   	ret    

f0100acf <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ad2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad7:	5d                   	pop    %ebp
f0100ad8:	c3                   	ret    

f0100ad9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ad9:	55                   	push   %ebp
f0100ada:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100adc:	5d                   	pop    %ebp
f0100add:	c3                   	ret    

f0100ade <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100ade:	55                   	push   %ebp
f0100adf:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0100ae1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ae4:	e8 a4 fe ff ff       	call   f010098d <invlpg>
}
f0100ae9:	5d                   	pop    %ebp
f0100aea:	c3                   	ret    

f0100aeb <inb>:
{
f0100aeb:	55                   	push   %ebp
f0100aec:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100aee:	89 c2                	mov    %eax,%edx
f0100af0:	ec                   	in     (%dx),%al
}
f0100af1:	5d                   	pop    %ebp
f0100af2:	c3                   	ret    

f0100af3 <outb>:
{
f0100af3:	55                   	push   %ebp
f0100af4:	89 e5                	mov    %esp,%ebp
f0100af6:	89 c1                	mov    %eax,%ecx
f0100af8:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100afa:	89 ca                	mov    %ecx,%edx
f0100afc:	ee                   	out    %al,(%dx)
}
f0100afd:	5d                   	pop    %ebp
f0100afe:	c3                   	ret    

f0100aff <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0100b02:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0100b06:	b8 70 00 00 00       	mov    $0x70,%eax
f0100b0b:	e8 e3 ff ff ff       	call   f0100af3 <outb>
	return inb(IO_RTC+1);
f0100b10:	b8 71 00 00 00       	mov    $0x71,%eax
f0100b15:	e8 d1 ff ff ff       	call   f0100aeb <inb>
f0100b1a:	0f b6 c0             	movzbl %al,%eax
}
f0100b1d:	5d                   	pop    %ebp
f0100b1e:	c3                   	ret    

f0100b1f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100b1f:	55                   	push   %ebp
f0100b20:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0100b22:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0100b26:	b8 70 00 00 00       	mov    $0x70,%eax
f0100b2b:	e8 c3 ff ff ff       	call   f0100af3 <outb>
	outb(IO_RTC+1, datum);
f0100b30:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0100b34:	b8 71 00 00 00       	mov    $0x71,%eax
f0100b39:	e8 b5 ff ff ff       	call   f0100af3 <outb>
}
f0100b3e:	5d                   	pop    %ebp
f0100b3f:	c3                   	ret    

f0100b40 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100b40:	55                   	push   %ebp
f0100b41:	89 e5                	mov    %esp,%ebp
f0100b43:	53                   	push   %ebx
f0100b44:	83 ec 10             	sub    $0x10,%esp
f0100b47:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0100b4a:	ff 75 08             	pushl  0x8(%ebp)
f0100b4d:	e8 d1 fb ff ff       	call   f0100723 <cputchar>
	(*cnt)++;
f0100b52:	83 03 01             	addl   $0x1,(%ebx)
}
f0100b55:	83 c4 10             	add    $0x10,%esp
f0100b58:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b5b:	c9                   	leave  
f0100b5c:	c3                   	ret    

f0100b5d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100b5d:	55                   	push   %ebp
f0100b5e:	89 e5                	mov    %esp,%ebp
f0100b60:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100b63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b6a:	ff 75 0c             	pushl  0xc(%ebp)
f0100b6d:	ff 75 08             	pushl  0x8(%ebp)
f0100b70:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b73:	50                   	push   %eax
f0100b74:	68 40 0b 10 f0       	push   $0xf0100b40
f0100b79:	e8 84 04 00 00       	call   f0101002 <vprintfmt>
	return cnt;
}
f0100b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b81:	c9                   	leave  
f0100b82:	c3                   	ret    

f0100b83 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b83:	55                   	push   %ebp
f0100b84:	89 e5                	mov    %esp,%ebp
f0100b86:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b89:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b8c:	50                   	push   %eax
f0100b8d:	ff 75 08             	pushl  0x8(%ebp)
f0100b90:	e8 c8 ff ff ff       	call   f0100b5d <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b95:	c9                   	leave  
f0100b96:	c3                   	ret    

f0100b97 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0100b97:	55                   	push   %ebp
f0100b98:	89 e5                	mov    %esp,%ebp
f0100b9a:	57                   	push   %edi
f0100b9b:	56                   	push   %esi
f0100b9c:	53                   	push   %ebx
f0100b9d:	83 ec 14             	sub    $0x14,%esp
f0100ba0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ba3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ba6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ba9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100bac:	8b 32                	mov    (%edx),%esi
f0100bae:	8b 01                	mov    (%ecx),%eax
f0100bb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bb3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100bba:	eb 2f                	jmp    f0100beb <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100bbc:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bbf:	39 c6                	cmp    %eax,%esi
f0100bc1:	7f 49                	jg     f0100c0c <stab_binsearch+0x75>
f0100bc3:	0f b6 0a             	movzbl (%edx),%ecx
f0100bc6:	83 ea 0c             	sub    $0xc,%edx
f0100bc9:	39 f9                	cmp    %edi,%ecx
f0100bcb:	75 ef                	jne    f0100bbc <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100bcd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bd0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bd3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100bd7:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bda:	73 35                	jae    f0100c11 <stab_binsearch+0x7a>
			*region_left = m;
f0100bdc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bdf:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100be1:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100be4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100beb:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100bee:	7f 4e                	jg     f0100c3e <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100bf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bf3:	01 f0                	add    %esi,%eax
f0100bf5:	89 c3                	mov    %eax,%ebx
f0100bf7:	c1 eb 1f             	shr    $0x1f,%ebx
f0100bfa:	01 c3                	add    %eax,%ebx
f0100bfc:	d1 fb                	sar    %ebx
f0100bfe:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c01:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100c04:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100c08:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100c0a:	eb b3                	jmp    f0100bbf <stab_binsearch+0x28>
			l = true_m + 1;
f0100c0c:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100c0f:	eb da                	jmp    f0100beb <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100c11:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100c14:	76 14                	jbe    f0100c2a <stab_binsearch+0x93>
			*region_right = m - 1;
f0100c16:	83 e8 01             	sub    $0x1,%eax
f0100c19:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c1c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100c1f:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100c21:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c28:	eb c1                	jmp    f0100beb <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100c2a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c2d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100c2f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100c33:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100c35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c3c:	eb ad                	jmp    f0100beb <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100c3e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100c42:	74 16                	je     f0100c5a <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c44:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c47:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c4c:	8b 0e                	mov    (%esi),%ecx
f0100c4e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c51:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100c54:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100c58:	eb 12                	jmp    f0100c6c <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100c5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c5d:	8b 00                	mov    (%eax),%eax
f0100c5f:	83 e8 01             	sub    $0x1,%eax
f0100c62:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100c65:	89 07                	mov    %eax,(%edi)
f0100c67:	eb 16                	jmp    f0100c7f <stab_binsearch+0xe8>
		     l--)
f0100c69:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100c6c:	39 c1                	cmp    %eax,%ecx
f0100c6e:	7d 0a                	jge    f0100c7a <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100c70:	0f b6 1a             	movzbl (%edx),%ebx
f0100c73:	83 ea 0c             	sub    $0xc,%edx
f0100c76:	39 fb                	cmp    %edi,%ebx
f0100c78:	75 ef                	jne    f0100c69 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100c7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c7d:	89 07                	mov    %eax,(%edi)
	}
}
f0100c7f:	83 c4 14             	add    $0x14,%esp
f0100c82:	5b                   	pop    %ebx
f0100c83:	5e                   	pop    %esi
f0100c84:	5f                   	pop    %edi
f0100c85:	5d                   	pop    %ebp
f0100c86:	c3                   	ret    

f0100c87 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c87:	55                   	push   %ebp
f0100c88:	89 e5                	mov    %esp,%ebp
f0100c8a:	57                   	push   %edi
f0100c8b:	56                   	push   %esi
f0100c8c:	53                   	push   %ebx
f0100c8d:	83 ec 3c             	sub    $0x3c,%esp
f0100c90:	8b 75 08             	mov    0x8(%ebp),%esi
f0100c93:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c96:	c7 03 90 1f 10 f0    	movl   $0xf0101f90,(%ebx)
	info->eip_line = 0;
f0100c9c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ca3:	c7 43 08 90 1f 10 f0 	movl   $0xf0101f90,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100caa:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100cb1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100cb4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100cbb:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100cc1:	0f 86 22 01 00 00    	jbe    f0100de9 <debuginfo_eip+0x162>
		// Can't search for user-level addresses yet!
		panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100cc7:	b8 80 84 10 f0       	mov    $0xf0108480,%eax
f0100ccc:	3d f9 66 10 f0       	cmp    $0xf01066f9,%eax
f0100cd1:	0f 86 b4 01 00 00    	jbe    f0100e8b <debuginfo_eip+0x204>
f0100cd7:	80 3d 7f 84 10 f0 00 	cmpb   $0x0,0xf010847f
f0100cde:	0f 85 ae 01 00 00    	jne    f0100e92 <debuginfo_eip+0x20b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ce4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ceb:	b8 f8 66 10 f0       	mov    $0xf01066f8,%eax
f0100cf0:	2d c8 21 10 f0       	sub    $0xf01021c8,%eax
f0100cf5:	c1 f8 02             	sar    $0x2,%eax
f0100cf8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100cfe:	83 e8 01             	sub    $0x1,%eax
f0100d01:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100d04:	83 ec 08             	sub    $0x8,%esp
f0100d07:	56                   	push   %esi
f0100d08:	6a 64                	push   $0x64
f0100d0a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100d0d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100d10:	b8 c8 21 10 f0       	mov    $0xf01021c8,%eax
f0100d15:	e8 7d fe ff ff       	call   f0100b97 <stab_binsearch>
	if (lfile == 0)
f0100d1a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d1d:	83 c4 10             	add    $0x10,%esp
f0100d20:	85 c0                	test   %eax,%eax
f0100d22:	0f 84 71 01 00 00    	je     f0100e99 <debuginfo_eip+0x212>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100d28:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100d2b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d2e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100d31:	83 ec 08             	sub    $0x8,%esp
f0100d34:	56                   	push   %esi
f0100d35:	6a 24                	push   $0x24
f0100d37:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100d3a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d3d:	b8 c8 21 10 f0       	mov    $0xf01021c8,%eax
f0100d42:	e8 50 fe ff ff       	call   f0100b97 <stab_binsearch>

	if (lfun <= rfun) {
f0100d47:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d4a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d4d:	83 c4 10             	add    $0x10,%esp
f0100d50:	39 d0                	cmp    %edx,%eax
f0100d52:	0f 8f a8 00 00 00    	jg     f0100e00 <debuginfo_eip+0x179>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d58:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100d5b:	c1 e1 02             	shl    $0x2,%ecx
f0100d5e:	8d b9 c8 21 10 f0    	lea    -0xfefde38(%ecx),%edi
f0100d64:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100d67:	8b b9 c8 21 10 f0    	mov    -0xfefde38(%ecx),%edi
f0100d6d:	b9 80 84 10 f0       	mov    $0xf0108480,%ecx
f0100d72:	81 e9 f9 66 10 f0    	sub    $0xf01066f9,%ecx
f0100d78:	39 cf                	cmp    %ecx,%edi
f0100d7a:	73 09                	jae    f0100d85 <debuginfo_eip+0xfe>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d7c:	81 c7 f9 66 10 f0    	add    $0xf01066f9,%edi
f0100d82:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d85:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100d88:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100d8b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100d8e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d90:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d93:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d96:	83 ec 08             	sub    $0x8,%esp
f0100d99:	6a 3a                	push   $0x3a
f0100d9b:	ff 73 08             	pushl  0x8(%ebx)
f0100d9e:	e8 62 08 00 00       	call   f0101605 <strfind>
f0100da3:	2b 43 08             	sub    0x8(%ebx),%eax
f0100da6:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100da9:	83 c4 08             	add    $0x8,%esp
f0100dac:	56                   	push   %esi
f0100dad:	6a 44                	push   $0x44
f0100daf:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100db2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100db5:	b8 c8 21 10 f0       	mov    $0xf01021c8,%eax
f0100dba:	e8 d8 fd ff ff       	call   f0100b97 <stab_binsearch>
	if (lline <= rline) {
f0100dbf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dc2:	83 c4 10             	add    $0x10,%esp
f0100dc5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100dc8:	7f 0e                	jg     f0100dd8 <debuginfo_eip+0x151>
		info->eip_line = stabs[lline].n_desc;
f0100dca:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100dcd:	0f b7 14 95 ce 21 10 	movzwl -0xfefde32(,%edx,4),%edx
f0100dd4:	f0 
f0100dd5:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0100dd8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ddb:	89 c2                	mov    %eax,%edx
f0100ddd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100de0:	8d 04 85 cc 21 10 f0 	lea    -0xfefde34(,%eax,4),%eax
f0100de7:	eb 2e                	jmp    f0100e17 <debuginfo_eip+0x190>
		panic("User address");
f0100de9:	83 ec 04             	sub    $0x4,%esp
f0100dec:	68 9a 1f 10 f0       	push   $0xf0101f9a
f0100df1:	68 82 00 00 00       	push   $0x82
f0100df6:	68 a7 1f 10 f0       	push   $0xf0101fa7
f0100dfb:	e8 8b f2 ff ff       	call   f010008b <_panic>
		info->eip_fn_addr = addr;
f0100e00:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100e03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e06:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100e09:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e0c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e0f:	eb 85                	jmp    f0100d96 <debuginfo_eip+0x10f>
f0100e11:	83 ea 01             	sub    $0x1,%edx
f0100e14:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0100e17:	39 d7                	cmp    %edx,%edi
f0100e19:	7f 33                	jg     f0100e4e <debuginfo_eip+0x1c7>
f0100e1b:	0f b6 08             	movzbl (%eax),%ecx
f0100e1e:	80 f9 84             	cmp    $0x84,%cl
f0100e21:	74 0b                	je     f0100e2e <debuginfo_eip+0x1a7>
f0100e23:	80 f9 64             	cmp    $0x64,%cl
f0100e26:	75 e9                	jne    f0100e11 <debuginfo_eip+0x18a>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e28:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100e2c:	74 e3                	je     f0100e11 <debuginfo_eip+0x18a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e2e:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100e31:	8b 14 85 c8 21 10 f0 	mov    -0xfefde38(,%eax,4),%edx
f0100e38:	b8 80 84 10 f0       	mov    $0xf0108480,%eax
f0100e3d:	2d f9 66 10 f0       	sub    $0xf01066f9,%eax
f0100e42:	39 c2                	cmp    %eax,%edx
f0100e44:	73 08                	jae    f0100e4e <debuginfo_eip+0x1c7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e46:	81 c2 f9 66 10 f0    	add    $0xf01066f9,%edx
f0100e4c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e4e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e51:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e54:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e59:	39 f2                	cmp    %esi,%edx
f0100e5b:	7d 48                	jge    f0100ea5 <debuginfo_eip+0x21e>
		for (lline = lfun + 1;
f0100e5d:	83 c2 01             	add    $0x1,%edx
f0100e60:	89 d0                	mov    %edx,%eax
f0100e62:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100e65:	8d 14 95 cc 21 10 f0 	lea    -0xfefde34(,%edx,4),%edx
f0100e6c:	eb 04                	jmp    f0100e72 <debuginfo_eip+0x1eb>
			info->eip_fn_narg++;
f0100e6e:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0100e72:	39 c6                	cmp    %eax,%esi
f0100e74:	7e 2a                	jle    f0100ea0 <debuginfo_eip+0x219>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e76:	0f b6 0a             	movzbl (%edx),%ecx
f0100e79:	83 c0 01             	add    $0x1,%eax
f0100e7c:	83 c2 0c             	add    $0xc,%edx
f0100e7f:	80 f9 a0             	cmp    $0xa0,%cl
f0100e82:	74 ea                	je     f0100e6e <debuginfo_eip+0x1e7>
	return 0;
f0100e84:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e89:	eb 1a                	jmp    f0100ea5 <debuginfo_eip+0x21e>
		return -1;
f0100e8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e90:	eb 13                	jmp    f0100ea5 <debuginfo_eip+0x21e>
f0100e92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e97:	eb 0c                	jmp    f0100ea5 <debuginfo_eip+0x21e>
		return -1;
f0100e99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e9e:	eb 05                	jmp    f0100ea5 <debuginfo_eip+0x21e>
	return 0;
f0100ea0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ea5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ea8:	5b                   	pop    %ebx
f0100ea9:	5e                   	pop    %esi
f0100eaa:	5f                   	pop    %edi
f0100eab:	5d                   	pop    %ebp
f0100eac:	c3                   	ret    

f0100ead <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ead:	55                   	push   %ebp
f0100eae:	89 e5                	mov    %esp,%ebp
f0100eb0:	57                   	push   %edi
f0100eb1:	56                   	push   %esi
f0100eb2:	53                   	push   %ebx
f0100eb3:	83 ec 1c             	sub    $0x1c,%esp
f0100eb6:	89 c7                	mov    %eax,%edi
f0100eb8:	89 d6                	mov    %edx,%esi
f0100eba:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ebd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ec0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ec3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ec6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100ec9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ece:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ed1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ed4:	39 d3                	cmp    %edx,%ebx
f0100ed6:	72 05                	jb     f0100edd <printnum+0x30>
f0100ed8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100edb:	77 7a                	ja     f0100f57 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100edd:	83 ec 0c             	sub    $0xc,%esp
f0100ee0:	ff 75 18             	pushl  0x18(%ebp)
f0100ee3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100ee9:	53                   	push   %ebx
f0100eea:	ff 75 10             	pushl  0x10(%ebp)
f0100eed:	83 ec 08             	sub    $0x8,%esp
f0100ef0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ef3:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ef6:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ef9:	ff 75 d8             	pushl  -0x28(%ebp)
f0100efc:	e8 1f 09 00 00       	call   f0101820 <__udivdi3>
f0100f01:	83 c4 18             	add    $0x18,%esp
f0100f04:	52                   	push   %edx
f0100f05:	50                   	push   %eax
f0100f06:	89 f2                	mov    %esi,%edx
f0100f08:	89 f8                	mov    %edi,%eax
f0100f0a:	e8 9e ff ff ff       	call   f0100ead <printnum>
f0100f0f:	83 c4 20             	add    $0x20,%esp
f0100f12:	eb 13                	jmp    f0100f27 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f14:	83 ec 08             	sub    $0x8,%esp
f0100f17:	56                   	push   %esi
f0100f18:	ff 75 18             	pushl  0x18(%ebp)
f0100f1b:	ff d7                	call   *%edi
f0100f1d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f20:	83 eb 01             	sub    $0x1,%ebx
f0100f23:	85 db                	test   %ebx,%ebx
f0100f25:	7f ed                	jg     f0100f14 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f27:	83 ec 08             	sub    $0x8,%esp
f0100f2a:	56                   	push   %esi
f0100f2b:	83 ec 04             	sub    $0x4,%esp
f0100f2e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f31:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f34:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f37:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f3a:	e8 01 0a 00 00       	call   f0101940 <__umoddi3>
f0100f3f:	83 c4 14             	add    $0x14,%esp
f0100f42:	0f be 80 b5 1f 10 f0 	movsbl -0xfefe04b(%eax),%eax
f0100f49:	50                   	push   %eax
f0100f4a:	ff d7                	call   *%edi
}
f0100f4c:	83 c4 10             	add    $0x10,%esp
f0100f4f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f52:	5b                   	pop    %ebx
f0100f53:	5e                   	pop    %esi
f0100f54:	5f                   	pop    %edi
f0100f55:	5d                   	pop    %ebp
f0100f56:	c3                   	ret    
f0100f57:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100f5a:	eb c4                	jmp    f0100f20 <printnum+0x73>

f0100f5c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100f5c:	55                   	push   %ebp
f0100f5d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100f5f:	83 fa 01             	cmp    $0x1,%edx
f0100f62:	7e 0e                	jle    f0100f72 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100f64:	8b 10                	mov    (%eax),%edx
f0100f66:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100f69:	89 08                	mov    %ecx,(%eax)
f0100f6b:	8b 02                	mov    (%edx),%eax
f0100f6d:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
}
f0100f70:	5d                   	pop    %ebp
f0100f71:	c3                   	ret    
	else if (lflag)
f0100f72:	85 d2                	test   %edx,%edx
f0100f74:	75 10                	jne    f0100f86 <getuint+0x2a>
		return va_arg(*ap, unsigned int);
f0100f76:	8b 10                	mov    (%eax),%edx
f0100f78:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f7b:	89 08                	mov    %ecx,(%eax)
f0100f7d:	8b 02                	mov    (%edx),%eax
f0100f7f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f84:	eb ea                	jmp    f0100f70 <getuint+0x14>
		return va_arg(*ap, unsigned long);
f0100f86:	8b 10                	mov    (%eax),%edx
f0100f88:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f8b:	89 08                	mov    %ecx,(%eax)
f0100f8d:	8b 02                	mov    (%edx),%eax
f0100f8f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f94:	eb da                	jmp    f0100f70 <getuint+0x14>

f0100f96 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0100f96:	55                   	push   %ebp
f0100f97:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100f99:	83 fa 01             	cmp    $0x1,%edx
f0100f9c:	7e 0e                	jle    f0100fac <getint+0x16>
		return va_arg(*ap, long long);
f0100f9e:	8b 10                	mov    (%eax),%edx
f0100fa0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100fa3:	89 08                	mov    %ecx,(%eax)
f0100fa5:	8b 02                	mov    (%edx),%eax
f0100fa7:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
}
f0100faa:	5d                   	pop    %ebp
f0100fab:	c3                   	ret    
	else if (lflag)
f0100fac:	85 d2                	test   %edx,%edx
f0100fae:	75 0c                	jne    f0100fbc <getint+0x26>
		return va_arg(*ap, int);
f0100fb0:	8b 10                	mov    (%eax),%edx
f0100fb2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100fb5:	89 08                	mov    %ecx,(%eax)
f0100fb7:	8b 02                	mov    (%edx),%eax
f0100fb9:	99                   	cltd   
f0100fba:	eb ee                	jmp    f0100faa <getint+0x14>
		return va_arg(*ap, long);
f0100fbc:	8b 10                	mov    (%eax),%edx
f0100fbe:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100fc1:	89 08                	mov    %ecx,(%eax)
f0100fc3:	8b 02                	mov    (%edx),%eax
f0100fc5:	99                   	cltd   
f0100fc6:	eb e2                	jmp    f0100faa <getint+0x14>

f0100fc8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100fc8:	55                   	push   %ebp
f0100fc9:	89 e5                	mov    %esp,%ebp
f0100fcb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100fce:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100fd2:	8b 10                	mov    (%eax),%edx
f0100fd4:	3b 50 04             	cmp    0x4(%eax),%edx
f0100fd7:	73 0a                	jae    f0100fe3 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100fd9:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100fdc:	89 08                	mov    %ecx,(%eax)
f0100fde:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fe1:	88 02                	mov    %al,(%edx)
}
f0100fe3:	5d                   	pop    %ebp
f0100fe4:	c3                   	ret    

f0100fe5 <printfmt>:
{
f0100fe5:	55                   	push   %ebp
f0100fe6:	89 e5                	mov    %esp,%ebp
f0100fe8:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100feb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100fee:	50                   	push   %eax
f0100fef:	ff 75 10             	pushl  0x10(%ebp)
f0100ff2:	ff 75 0c             	pushl  0xc(%ebp)
f0100ff5:	ff 75 08             	pushl  0x8(%ebp)
f0100ff8:	e8 05 00 00 00       	call   f0101002 <vprintfmt>
}
f0100ffd:	83 c4 10             	add    $0x10,%esp
f0101000:	c9                   	leave  
f0101001:	c3                   	ret    

f0101002 <vprintfmt>:
{
f0101002:	55                   	push   %ebp
f0101003:	89 e5                	mov    %esp,%ebp
f0101005:	57                   	push   %edi
f0101006:	56                   	push   %esi
f0101007:	53                   	push   %ebx
f0101008:	83 ec 2c             	sub    $0x2c,%esp
f010100b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010100e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101011:	89 f7                	mov    %esi,%edi
f0101013:	89 de                	mov    %ebx,%esi
f0101015:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101018:	e9 9e 02 00 00       	jmp    f01012bb <vprintfmt+0x2b9>
		padc = ' ';
f010101d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101021:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101028:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010102f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101036:	ba 00 00 00 00       	mov    $0x0,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010103b:	8d 43 01             	lea    0x1(%ebx),%eax
f010103e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101041:	0f b6 0b             	movzbl (%ebx),%ecx
f0101044:	8d 41 dd             	lea    -0x23(%ecx),%eax
f0101047:	3c 55                	cmp    $0x55,%al
f0101049:	0f 87 e8 02 00 00    	ja     f0101337 <vprintfmt+0x335>
f010104f:	0f b6 c0             	movzbl %al,%eax
f0101052:	ff 24 85 44 20 10 f0 	jmp    *-0xfefdfbc(,%eax,4)
f0101059:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f010105c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101060:	eb d9                	jmp    f010103b <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0101062:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0101065:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101069:	eb d0                	jmp    f010103b <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010106b:	0f b6 c9             	movzbl %cl,%ecx
f010106e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0101071:	b8 00 00 00 00       	mov    $0x0,%eax
f0101076:	89 55 e4             	mov    %edx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f0101079:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010107c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101080:	0f be 0b             	movsbl (%ebx),%ecx
				if (ch < '0' || ch > '9')
f0101083:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101086:	83 fa 09             	cmp    $0x9,%edx
f0101089:	77 52                	ja     f01010dd <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f010108b:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010108e:	eb e9                	jmp    f0101079 <vprintfmt+0x77>
			precision = va_arg(ap, int);
f0101090:	8b 45 14             	mov    0x14(%ebp),%eax
f0101093:	8d 48 04             	lea    0x4(%eax),%ecx
f0101096:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101099:	8b 00                	mov    (%eax),%eax
f010109b:	89 45 d0             	mov    %eax,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010109e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f01010a1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010a5:	79 94                	jns    f010103b <vprintfmt+0x39>
				width = precision, precision = -1;
f01010a7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010ad:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01010b4:	eb 85                	jmp    f010103b <vprintfmt+0x39>
f01010b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010b9:	85 c0                	test   %eax,%eax
f01010bb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010c0:	0f 49 c8             	cmovns %eax,%ecx
f01010c3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010c6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01010c9:	e9 6d ff ff ff       	jmp    f010103b <vprintfmt+0x39>
f01010ce:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01010d1:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01010d8:	e9 5e ff ff ff       	jmp    f010103b <vprintfmt+0x39>
f01010dd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010e3:	eb bc                	jmp    f01010a1 <vprintfmt+0x9f>
			lflag++;
f01010e5:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01010e8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01010eb:	e9 4b ff ff ff       	jmp    f010103b <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f01010f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f3:	8d 50 04             	lea    0x4(%eax),%edx
f01010f6:	89 55 14             	mov    %edx,0x14(%ebp)
f01010f9:	83 ec 08             	sub    $0x8,%esp
f01010fc:	57                   	push   %edi
f01010fd:	ff 30                	pushl  (%eax)
f01010ff:	ff d6                	call   *%esi
			break;
f0101101:	83 c4 10             	add    $0x10,%esp
f0101104:	e9 af 01 00 00       	jmp    f01012b8 <vprintfmt+0x2b6>
			err = va_arg(ap, int);
f0101109:	8b 45 14             	mov    0x14(%ebp),%eax
f010110c:	8d 50 04             	lea    0x4(%eax),%edx
f010110f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101112:	8b 00                	mov    (%eax),%eax
f0101114:	99                   	cltd   
f0101115:	31 d0                	xor    %edx,%eax
f0101117:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101119:	83 f8 06             	cmp    $0x6,%eax
f010111c:	7f 20                	jg     f010113e <vprintfmt+0x13c>
f010111e:	8b 14 85 9c 21 10 f0 	mov    -0xfefde64(,%eax,4),%edx
f0101125:	85 d2                	test   %edx,%edx
f0101127:	74 15                	je     f010113e <vprintfmt+0x13c>
				printfmt(putch, putdat, "%s", p);
f0101129:	52                   	push   %edx
f010112a:	68 d6 1f 10 f0       	push   $0xf0101fd6
f010112f:	57                   	push   %edi
f0101130:	56                   	push   %esi
f0101131:	e8 af fe ff ff       	call   f0100fe5 <printfmt>
f0101136:	83 c4 10             	add    $0x10,%esp
f0101139:	e9 7a 01 00 00       	jmp    f01012b8 <vprintfmt+0x2b6>
				printfmt(putch, putdat, "error %d", err);
f010113e:	50                   	push   %eax
f010113f:	68 cd 1f 10 f0       	push   $0xf0101fcd
f0101144:	57                   	push   %edi
f0101145:	56                   	push   %esi
f0101146:	e8 9a fe ff ff       	call   f0100fe5 <printfmt>
f010114b:	83 c4 10             	add    $0x10,%esp
f010114e:	e9 65 01 00 00       	jmp    f01012b8 <vprintfmt+0x2b6>
			if ((p = va_arg(ap, char *)) == NULL)
f0101153:	8b 45 14             	mov    0x14(%ebp),%eax
f0101156:	8d 50 04             	lea    0x4(%eax),%edx
f0101159:	89 55 14             	mov    %edx,0x14(%ebp)
f010115c:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f010115e:	85 db                	test   %ebx,%ebx
f0101160:	b8 c6 1f 10 f0       	mov    $0xf0101fc6,%eax
f0101165:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f0101168:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010116c:	0f 8e bd 00 00 00    	jle    f010122f <vprintfmt+0x22d>
f0101172:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101176:	75 0e                	jne    f0101186 <vprintfmt+0x184>
f0101178:	89 75 08             	mov    %esi,0x8(%ebp)
f010117b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010117e:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101181:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101184:	eb 6d                	jmp    f01011f3 <vprintfmt+0x1f1>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101186:	83 ec 08             	sub    $0x8,%esp
f0101189:	ff 75 d0             	pushl  -0x30(%ebp)
f010118c:	53                   	push   %ebx
f010118d:	e8 2f 03 00 00       	call   f01014c1 <strnlen>
f0101192:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101195:	29 c1                	sub    %eax,%ecx
f0101197:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010119a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010119d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01011a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011a4:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01011a7:	89 cb                	mov    %ecx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f01011a9:	eb 0f                	jmp    f01011ba <vprintfmt+0x1b8>
					putch(padc, putdat);
f01011ab:	83 ec 08             	sub    $0x8,%esp
f01011ae:	57                   	push   %edi
f01011af:	ff 75 e0             	pushl  -0x20(%ebp)
f01011b2:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01011b4:	83 eb 01             	sub    $0x1,%ebx
f01011b7:	83 c4 10             	add    $0x10,%esp
f01011ba:	85 db                	test   %ebx,%ebx
f01011bc:	7f ed                	jg     f01011ab <vprintfmt+0x1a9>
f01011be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01011c1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01011c4:	85 c9                	test   %ecx,%ecx
f01011c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cb:	0f 49 c1             	cmovns %ecx,%eax
f01011ce:	29 c1                	sub    %eax,%ecx
f01011d0:	89 75 08             	mov    %esi,0x8(%ebp)
f01011d3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01011d6:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01011d9:	89 cf                	mov    %ecx,%edi
f01011db:	eb 16                	jmp    f01011f3 <vprintfmt+0x1f1>
				if (altflag && (ch < ' ' || ch > '~'))
f01011dd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01011e1:	75 31                	jne    f0101214 <vprintfmt+0x212>
					putch(ch, putdat);
f01011e3:	83 ec 08             	sub    $0x8,%esp
f01011e6:	ff 75 0c             	pushl  0xc(%ebp)
f01011e9:	50                   	push   %eax
f01011ea:	ff 55 08             	call   *0x8(%ebp)
f01011ed:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011f0:	83 ef 01             	sub    $0x1,%edi
f01011f3:	83 c3 01             	add    $0x1,%ebx
f01011f6:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f01011fa:	0f be c2             	movsbl %dl,%eax
f01011fd:	85 c0                	test   %eax,%eax
f01011ff:	74 50                	je     f0101251 <vprintfmt+0x24f>
f0101201:	85 f6                	test   %esi,%esi
f0101203:	78 d8                	js     f01011dd <vprintfmt+0x1db>
f0101205:	83 ee 01             	sub    $0x1,%esi
f0101208:	79 d3                	jns    f01011dd <vprintfmt+0x1db>
f010120a:	89 fb                	mov    %edi,%ebx
f010120c:	8b 75 08             	mov    0x8(%ebp),%esi
f010120f:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101212:	eb 37                	jmp    f010124b <vprintfmt+0x249>
				if (altflag && (ch < ' ' || ch > '~'))
f0101214:	0f be d2             	movsbl %dl,%edx
f0101217:	83 ea 20             	sub    $0x20,%edx
f010121a:	83 fa 5e             	cmp    $0x5e,%edx
f010121d:	76 c4                	jbe    f01011e3 <vprintfmt+0x1e1>
					putch('?', putdat);
f010121f:	83 ec 08             	sub    $0x8,%esp
f0101222:	ff 75 0c             	pushl  0xc(%ebp)
f0101225:	6a 3f                	push   $0x3f
f0101227:	ff 55 08             	call   *0x8(%ebp)
f010122a:	83 c4 10             	add    $0x10,%esp
f010122d:	eb c1                	jmp    f01011f0 <vprintfmt+0x1ee>
f010122f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101232:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101235:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101238:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010123b:	eb b6                	jmp    f01011f3 <vprintfmt+0x1f1>
				putch(' ', putdat);
f010123d:	83 ec 08             	sub    $0x8,%esp
f0101240:	57                   	push   %edi
f0101241:	6a 20                	push   $0x20
f0101243:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101245:	83 eb 01             	sub    $0x1,%ebx
f0101248:	83 c4 10             	add    $0x10,%esp
f010124b:	85 db                	test   %ebx,%ebx
f010124d:	7f ee                	jg     f010123d <vprintfmt+0x23b>
f010124f:	eb 67                	jmp    f01012b8 <vprintfmt+0x2b6>
f0101251:	89 fb                	mov    %edi,%ebx
f0101253:	8b 75 08             	mov    0x8(%ebp),%esi
f0101256:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101259:	eb f0                	jmp    f010124b <vprintfmt+0x249>
			num = getint(&ap, lflag);
f010125b:	8d 45 14             	lea    0x14(%ebp),%eax
f010125e:	e8 33 fd ff ff       	call   f0100f96 <getint>
f0101263:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101266:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 10;
f0101269:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f010126e:	85 d2                	test   %edx,%edx
f0101270:	79 2c                	jns    f010129e <vprintfmt+0x29c>
				putch('-', putdat);
f0101272:	83 ec 08             	sub    $0x8,%esp
f0101275:	57                   	push   %edi
f0101276:	6a 2d                	push   $0x2d
f0101278:	ff d6                	call   *%esi
				num = -(long long) num;
f010127a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010127d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101280:	f7 d8                	neg    %eax
f0101282:	83 d2 00             	adc    $0x0,%edx
f0101285:	f7 da                	neg    %edx
f0101287:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010128a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010128f:	eb 0d                	jmp    f010129e <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f0101291:	8d 45 14             	lea    0x14(%ebp),%eax
f0101294:	e8 c3 fc ff ff       	call   f0100f5c <getuint>
			base = 10;
f0101299:	b9 0a 00 00 00       	mov    $0xa,%ecx
			printnum(putch, putdat, num, base, width, padc);
f010129e:	83 ec 0c             	sub    $0xc,%esp
f01012a1:	0f be 5d d4          	movsbl -0x2c(%ebp),%ebx
f01012a5:	53                   	push   %ebx
f01012a6:	ff 75 e0             	pushl  -0x20(%ebp)
f01012a9:	51                   	push   %ecx
f01012aa:	52                   	push   %edx
f01012ab:	50                   	push   %eax
f01012ac:	89 fa                	mov    %edi,%edx
f01012ae:	89 f0                	mov    %esi,%eax
f01012b0:	e8 f8 fb ff ff       	call   f0100ead <printnum>
			break;
f01012b5:	83 c4 20             	add    $0x20,%esp
{
f01012b8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012bb:	83 c3 01             	add    $0x1,%ebx
f01012be:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f01012c2:	83 f8 25             	cmp    $0x25,%eax
f01012c5:	0f 84 52 fd ff ff    	je     f010101d <vprintfmt+0x1b>
			if (ch == '\0')
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	0f 84 84 00 00 00    	je     f0101357 <vprintfmt+0x355>
			putch(ch, putdat);
f01012d3:	83 ec 08             	sub    $0x8,%esp
f01012d6:	57                   	push   %edi
f01012d7:	50                   	push   %eax
f01012d8:	ff d6                	call   *%esi
f01012da:	83 c4 10             	add    $0x10,%esp
f01012dd:	eb dc                	jmp    f01012bb <vprintfmt+0x2b9>
			num = getuint(&ap, lflag);
f01012df:	8d 45 14             	lea    0x14(%ebp),%eax
f01012e2:	e8 75 fc ff ff       	call   f0100f5c <getuint>
			base = 8;
f01012e7:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01012ec:	eb b0                	jmp    f010129e <vprintfmt+0x29c>
			putch('0', putdat);
f01012ee:	83 ec 08             	sub    $0x8,%esp
f01012f1:	57                   	push   %edi
f01012f2:	6a 30                	push   $0x30
f01012f4:	ff d6                	call   *%esi
			putch('x', putdat);
f01012f6:	83 c4 08             	add    $0x8,%esp
f01012f9:	57                   	push   %edi
f01012fa:	6a 78                	push   $0x78
f01012fc:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f01012fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101301:	8d 50 04             	lea    0x4(%eax),%edx
f0101304:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f0101307:	8b 00                	mov    (%eax),%eax
f0101309:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;
f010130e:	83 c4 10             	add    $0x10,%esp
			base = 16;
f0101311:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101316:	eb 86                	jmp    f010129e <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f0101318:	8d 45 14             	lea    0x14(%ebp),%eax
f010131b:	e8 3c fc ff ff       	call   f0100f5c <getuint>
			base = 16;
f0101320:	b9 10 00 00 00       	mov    $0x10,%ecx
f0101325:	e9 74 ff ff ff       	jmp    f010129e <vprintfmt+0x29c>
			putch(ch, putdat);
f010132a:	83 ec 08             	sub    $0x8,%esp
f010132d:	57                   	push   %edi
f010132e:	6a 25                	push   $0x25
f0101330:	ff d6                	call   *%esi
			break;
f0101332:	83 c4 10             	add    $0x10,%esp
f0101335:	eb 81                	jmp    f01012b8 <vprintfmt+0x2b6>
			putch('%', putdat);
f0101337:	83 ec 08             	sub    $0x8,%esp
f010133a:	57                   	push   %edi
f010133b:	6a 25                	push   $0x25
f010133d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010133f:	83 c4 10             	add    $0x10,%esp
f0101342:	89 d8                	mov    %ebx,%eax
f0101344:	eb 03                	jmp    f0101349 <vprintfmt+0x347>
f0101346:	83 e8 01             	sub    $0x1,%eax
f0101349:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010134d:	75 f7                	jne    f0101346 <vprintfmt+0x344>
f010134f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101352:	e9 61 ff ff ff       	jmp    f01012b8 <vprintfmt+0x2b6>
}
f0101357:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010135a:	5b                   	pop    %ebx
f010135b:	5e                   	pop    %esi
f010135c:	5f                   	pop    %edi
f010135d:	5d                   	pop    %ebp
f010135e:	c3                   	ret    

f010135f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010135f:	55                   	push   %ebp
f0101360:	89 e5                	mov    %esp,%ebp
f0101362:	83 ec 18             	sub    $0x18,%esp
f0101365:	8b 45 08             	mov    0x8(%ebp),%eax
f0101368:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010136b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010136e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101372:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101375:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 26                	je     f01013a6 <vsnprintf+0x47>
f0101380:	85 d2                	test   %edx,%edx
f0101382:	7e 22                	jle    f01013a6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101384:	ff 75 14             	pushl  0x14(%ebp)
f0101387:	ff 75 10             	pushl  0x10(%ebp)
f010138a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010138d:	50                   	push   %eax
f010138e:	68 c8 0f 10 f0       	push   $0xf0100fc8
f0101393:	e8 6a fc ff ff       	call   f0101002 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101398:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010139b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010139e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013a1:	83 c4 10             	add    $0x10,%esp
}
f01013a4:	c9                   	leave  
f01013a5:	c3                   	ret    
		return -E_INVAL;
f01013a6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01013ab:	eb f7                	jmp    f01013a4 <vsnprintf+0x45>

f01013ad <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013ad:	55                   	push   %ebp
f01013ae:	89 e5                	mov    %esp,%ebp
f01013b0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013b3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013b6:	50                   	push   %eax
f01013b7:	ff 75 10             	pushl  0x10(%ebp)
f01013ba:	ff 75 0c             	pushl  0xc(%ebp)
f01013bd:	ff 75 08             	pushl  0x8(%ebp)
f01013c0:	e8 9a ff ff ff       	call   f010135f <vsnprintf>
	va_end(ap);

	return rc;
}
f01013c5:	c9                   	leave  
f01013c6:	c3                   	ret    

f01013c7 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c7:	55                   	push   %ebp
f01013c8:	89 e5                	mov    %esp,%ebp
f01013ca:	57                   	push   %edi
f01013cb:	56                   	push   %esi
f01013cc:	53                   	push   %ebx
f01013cd:	83 ec 0c             	sub    $0xc,%esp
f01013d0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013d3:	85 c0                	test   %eax,%eax
f01013d5:	74 11                	je     f01013e8 <readline+0x21>
		cprintf("%s", prompt);
f01013d7:	83 ec 08             	sub    $0x8,%esp
f01013da:	50                   	push   %eax
f01013db:	68 d6 1f 10 f0       	push   $0xf0101fd6
f01013e0:	e8 9e f7 ff ff       	call   f0100b83 <cprintf>
f01013e5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013e8:	83 ec 0c             	sub    $0xc,%esp
f01013eb:	6a 00                	push   $0x0
f01013ed:	e8 52 f3 ff ff       	call   f0100744 <iscons>
f01013f2:	89 c7                	mov    %eax,%edi
f01013f4:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013f7:	be 00 00 00 00       	mov    $0x0,%esi
f01013fc:	eb 3f                	jmp    f010143d <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01013fe:	83 ec 08             	sub    $0x8,%esp
f0101401:	50                   	push   %eax
f0101402:	68 b8 21 10 f0       	push   $0xf01021b8
f0101407:	e8 77 f7 ff ff       	call   f0100b83 <cprintf>
			return NULL;
f010140c:	83 c4 10             	add    $0x10,%esp
f010140f:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101414:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101417:	5b                   	pop    %ebx
f0101418:	5e                   	pop    %esi
f0101419:	5f                   	pop    %edi
f010141a:	5d                   	pop    %ebp
f010141b:	c3                   	ret    
			if (echoing)
f010141c:	85 ff                	test   %edi,%edi
f010141e:	75 05                	jne    f0101425 <readline+0x5e>
			i--;
f0101420:	83 ee 01             	sub    $0x1,%esi
f0101423:	eb 18                	jmp    f010143d <readline+0x76>
				cputchar('\b');
f0101425:	83 ec 0c             	sub    $0xc,%esp
f0101428:	6a 08                	push   $0x8
f010142a:	e8 f4 f2 ff ff       	call   f0100723 <cputchar>
f010142f:	83 c4 10             	add    $0x10,%esp
f0101432:	eb ec                	jmp    f0101420 <readline+0x59>
			buf[i++] = c;
f0101434:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f010143a:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f010143d:	e8 f1 f2 ff ff       	call   f0100733 <getchar>
f0101442:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101444:	85 c0                	test   %eax,%eax
f0101446:	78 b6                	js     f01013fe <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101448:	83 f8 08             	cmp    $0x8,%eax
f010144b:	0f 94 c2             	sete   %dl
f010144e:	83 f8 7f             	cmp    $0x7f,%eax
f0101451:	0f 94 c0             	sete   %al
f0101454:	08 c2                	or     %al,%dl
f0101456:	74 04                	je     f010145c <readline+0x95>
f0101458:	85 f6                	test   %esi,%esi
f010145a:	7f c0                	jg     f010141c <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010145c:	83 fb 1f             	cmp    $0x1f,%ebx
f010145f:	7e 1a                	jle    f010147b <readline+0xb4>
f0101461:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101467:	7f 12                	jg     f010147b <readline+0xb4>
			if (echoing)
f0101469:	85 ff                	test   %edi,%edi
f010146b:	74 c7                	je     f0101434 <readline+0x6d>
				cputchar(c);
f010146d:	83 ec 0c             	sub    $0xc,%esp
f0101470:	53                   	push   %ebx
f0101471:	e8 ad f2 ff ff       	call   f0100723 <cputchar>
f0101476:	83 c4 10             	add    $0x10,%esp
f0101479:	eb b9                	jmp    f0101434 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f010147b:	83 fb 0a             	cmp    $0xa,%ebx
f010147e:	74 05                	je     f0101485 <readline+0xbe>
f0101480:	83 fb 0d             	cmp    $0xd,%ebx
f0101483:	75 b8                	jne    f010143d <readline+0x76>
			if (echoing)
f0101485:	85 ff                	test   %edi,%edi
f0101487:	75 11                	jne    f010149a <readline+0xd3>
			buf[i] = 0;
f0101489:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f0101490:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
f0101495:	e9 7a ff ff ff       	jmp    f0101414 <readline+0x4d>
				cputchar('\n');
f010149a:	83 ec 0c             	sub    $0xc,%esp
f010149d:	6a 0a                	push   $0xa
f010149f:	e8 7f f2 ff ff       	call   f0100723 <cputchar>
f01014a4:	83 c4 10             	add    $0x10,%esp
f01014a7:	eb e0                	jmp    f0101489 <readline+0xc2>

f01014a9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014a9:	55                   	push   %ebp
f01014aa:	89 e5                	mov    %esp,%ebp
f01014ac:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014af:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b4:	eb 03                	jmp    f01014b9 <strlen+0x10>
		n++;
f01014b6:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01014b9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014bd:	75 f7                	jne    f01014b6 <strlen+0xd>
	return n;
}
f01014bf:	5d                   	pop    %ebp
f01014c0:	c3                   	ret    

f01014c1 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014c1:	55                   	push   %ebp
f01014c2:	89 e5                	mov    %esp,%ebp
f01014c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014c7:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01014cf:	eb 03                	jmp    f01014d4 <strnlen+0x13>
		n++;
f01014d1:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014d4:	39 d0                	cmp    %edx,%eax
f01014d6:	74 06                	je     f01014de <strnlen+0x1d>
f01014d8:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01014dc:	75 f3                	jne    f01014d1 <strnlen+0x10>
	return n;
}
f01014de:	5d                   	pop    %ebp
f01014df:	c3                   	ret    

f01014e0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014e0:	55                   	push   %ebp
f01014e1:	89 e5                	mov    %esp,%ebp
f01014e3:	53                   	push   %ebx
f01014e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014ea:	89 c2                	mov    %eax,%edx
f01014ec:	83 c1 01             	add    $0x1,%ecx
f01014ef:	83 c2 01             	add    $0x1,%edx
f01014f2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014f6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014f9:	84 db                	test   %bl,%bl
f01014fb:	75 ef                	jne    f01014ec <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014fd:	5b                   	pop    %ebx
f01014fe:	5d                   	pop    %ebp
f01014ff:	c3                   	ret    

f0101500 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101500:	55                   	push   %ebp
f0101501:	89 e5                	mov    %esp,%ebp
f0101503:	53                   	push   %ebx
f0101504:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101507:	53                   	push   %ebx
f0101508:	e8 9c ff ff ff       	call   f01014a9 <strlen>
f010150d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101510:	ff 75 0c             	pushl  0xc(%ebp)
f0101513:	01 d8                	add    %ebx,%eax
f0101515:	50                   	push   %eax
f0101516:	e8 c5 ff ff ff       	call   f01014e0 <strcpy>
	return dst;
}
f010151b:	89 d8                	mov    %ebx,%eax
f010151d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101520:	c9                   	leave  
f0101521:	c3                   	ret    

f0101522 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101522:	55                   	push   %ebp
f0101523:	89 e5                	mov    %esp,%ebp
f0101525:	56                   	push   %esi
f0101526:	53                   	push   %ebx
f0101527:	8b 75 08             	mov    0x8(%ebp),%esi
f010152a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010152d:	89 f3                	mov    %esi,%ebx
f010152f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101532:	89 f2                	mov    %esi,%edx
f0101534:	eb 0f                	jmp    f0101545 <strncpy+0x23>
		*dst++ = *src;
f0101536:	83 c2 01             	add    $0x1,%edx
f0101539:	0f b6 01             	movzbl (%ecx),%eax
f010153c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010153f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101542:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101545:	39 da                	cmp    %ebx,%edx
f0101547:	75 ed                	jne    f0101536 <strncpy+0x14>
	}
	return ret;
}
f0101549:	89 f0                	mov    %esi,%eax
f010154b:	5b                   	pop    %ebx
f010154c:	5e                   	pop    %esi
f010154d:	5d                   	pop    %ebp
f010154e:	c3                   	ret    

f010154f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010154f:	55                   	push   %ebp
f0101550:	89 e5                	mov    %esp,%ebp
f0101552:	56                   	push   %esi
f0101553:	53                   	push   %ebx
f0101554:	8b 75 08             	mov    0x8(%ebp),%esi
f0101557:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010155d:	89 f0                	mov    %esi,%eax
f010155f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101563:	85 c9                	test   %ecx,%ecx
f0101565:	75 0b                	jne    f0101572 <strlcpy+0x23>
f0101567:	eb 17                	jmp    f0101580 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101569:	83 c2 01             	add    $0x1,%edx
f010156c:	83 c0 01             	add    $0x1,%eax
f010156f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101572:	39 d8                	cmp    %ebx,%eax
f0101574:	74 07                	je     f010157d <strlcpy+0x2e>
f0101576:	0f b6 0a             	movzbl (%edx),%ecx
f0101579:	84 c9                	test   %cl,%cl
f010157b:	75 ec                	jne    f0101569 <strlcpy+0x1a>
		*dst = '\0';
f010157d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101580:	29 f0                	sub    %esi,%eax
}
f0101582:	5b                   	pop    %ebx
f0101583:	5e                   	pop    %esi
f0101584:	5d                   	pop    %ebp
f0101585:	c3                   	ret    

f0101586 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101586:	55                   	push   %ebp
f0101587:	89 e5                	mov    %esp,%ebp
f0101589:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010158c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010158f:	eb 06                	jmp    f0101597 <strcmp+0x11>
		p++, q++;
f0101591:	83 c1 01             	add    $0x1,%ecx
f0101594:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101597:	0f b6 01             	movzbl (%ecx),%eax
f010159a:	84 c0                	test   %al,%al
f010159c:	74 04                	je     f01015a2 <strcmp+0x1c>
f010159e:	3a 02                	cmp    (%edx),%al
f01015a0:	74 ef                	je     f0101591 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a2:	0f b6 c0             	movzbl %al,%eax
f01015a5:	0f b6 12             	movzbl (%edx),%edx
f01015a8:	29 d0                	sub    %edx,%eax
}
f01015aa:	5d                   	pop    %ebp
f01015ab:	c3                   	ret    

f01015ac <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015ac:	55                   	push   %ebp
f01015ad:	89 e5                	mov    %esp,%ebp
f01015af:	53                   	push   %ebx
f01015b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015b6:	89 c3                	mov    %eax,%ebx
f01015b8:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015bb:	eb 06                	jmp    f01015c3 <strncmp+0x17>
		n--, p++, q++;
f01015bd:	83 c0 01             	add    $0x1,%eax
f01015c0:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01015c3:	39 d8                	cmp    %ebx,%eax
f01015c5:	74 16                	je     f01015dd <strncmp+0x31>
f01015c7:	0f b6 08             	movzbl (%eax),%ecx
f01015ca:	84 c9                	test   %cl,%cl
f01015cc:	74 04                	je     f01015d2 <strncmp+0x26>
f01015ce:	3a 0a                	cmp    (%edx),%cl
f01015d0:	74 eb                	je     f01015bd <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d2:	0f b6 00             	movzbl (%eax),%eax
f01015d5:	0f b6 12             	movzbl (%edx),%edx
f01015d8:	29 d0                	sub    %edx,%eax
}
f01015da:	5b                   	pop    %ebx
f01015db:	5d                   	pop    %ebp
f01015dc:	c3                   	ret    
		return 0;
f01015dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01015e2:	eb f6                	jmp    f01015da <strncmp+0x2e>

f01015e4 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015e4:	55                   	push   %ebp
f01015e5:	89 e5                	mov    %esp,%ebp
f01015e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ea:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015ee:	0f b6 10             	movzbl (%eax),%edx
f01015f1:	84 d2                	test   %dl,%dl
f01015f3:	74 09                	je     f01015fe <strchr+0x1a>
		if (*s == c)
f01015f5:	38 ca                	cmp    %cl,%dl
f01015f7:	74 0a                	je     f0101603 <strchr+0x1f>
	for (; *s; s++)
f01015f9:	83 c0 01             	add    $0x1,%eax
f01015fc:	eb f0                	jmp    f01015ee <strchr+0xa>
			return (char *) s;
	return 0;
f01015fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101603:	5d                   	pop    %ebp
f0101604:	c3                   	ret    

f0101605 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101605:	55                   	push   %ebp
f0101606:	89 e5                	mov    %esp,%ebp
f0101608:	8b 45 08             	mov    0x8(%ebp),%eax
f010160b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010160f:	eb 03                	jmp    f0101614 <strfind+0xf>
f0101611:	83 c0 01             	add    $0x1,%eax
f0101614:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101617:	38 ca                	cmp    %cl,%dl
f0101619:	74 04                	je     f010161f <strfind+0x1a>
f010161b:	84 d2                	test   %dl,%dl
f010161d:	75 f2                	jne    f0101611 <strfind+0xc>
			break;
	return (char *) s;
}
f010161f:	5d                   	pop    %ebp
f0101620:	c3                   	ret    

f0101621 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101621:	55                   	push   %ebp
f0101622:	89 e5                	mov    %esp,%ebp
f0101624:	57                   	push   %edi
f0101625:	56                   	push   %esi
f0101626:	53                   	push   %ebx
f0101627:	8b 55 08             	mov    0x8(%ebp),%edx
f010162a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f010162d:	85 c9                	test   %ecx,%ecx
f010162f:	74 12                	je     f0101643 <memset+0x22>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101631:	f6 c2 03             	test   $0x3,%dl
f0101634:	75 05                	jne    f010163b <memset+0x1a>
f0101636:	f6 c1 03             	test   $0x3,%cl
f0101639:	74 0f                	je     f010164a <memset+0x29>
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010163b:	89 d7                	mov    %edx,%edi
f010163d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101640:	fc                   	cld    
f0101641:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0101643:	89 d0                	mov    %edx,%eax
f0101645:	5b                   	pop    %ebx
f0101646:	5e                   	pop    %esi
f0101647:	5f                   	pop    %edi
f0101648:	5d                   	pop    %ebp
f0101649:	c3                   	ret    
		c &= 0xFF;
f010164a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010164e:	89 d8                	mov    %ebx,%eax
f0101650:	c1 e0 08             	shl    $0x8,%eax
f0101653:	89 df                	mov    %ebx,%edi
f0101655:	c1 e7 18             	shl    $0x18,%edi
f0101658:	89 de                	mov    %ebx,%esi
f010165a:	c1 e6 10             	shl    $0x10,%esi
f010165d:	09 f7                	or     %esi,%edi
f010165f:	09 fb                	or     %edi,%ebx
			: "D" (p), "a" (c), "c" (n/4)
f0101661:	c1 e9 02             	shr    $0x2,%ecx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101664:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f0101666:	89 d7                	mov    %edx,%edi
f0101668:	fc                   	cld    
f0101669:	f3 ab                	rep stos %eax,%es:(%edi)
f010166b:	eb d6                	jmp    f0101643 <memset+0x22>

f010166d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010166d:	55                   	push   %ebp
f010166e:	89 e5                	mov    %esp,%ebp
f0101670:	57                   	push   %edi
f0101671:	56                   	push   %esi
f0101672:	8b 45 08             	mov    0x8(%ebp),%eax
f0101675:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101678:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010167b:	39 c6                	cmp    %eax,%esi
f010167d:	73 35                	jae    f01016b4 <memmove+0x47>
f010167f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101682:	39 c2                	cmp    %eax,%edx
f0101684:	76 2e                	jbe    f01016b4 <memmove+0x47>
		s += n;
		d += n;
f0101686:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101689:	89 d6                	mov    %edx,%esi
f010168b:	09 fe                	or     %edi,%esi
f010168d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101693:	74 0c                	je     f01016a1 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101695:	83 ef 01             	sub    $0x1,%edi
f0101698:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010169b:	fd                   	std    
f010169c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010169e:	fc                   	cld    
f010169f:	eb 21                	jmp    f01016c2 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016a1:	f6 c1 03             	test   $0x3,%cl
f01016a4:	75 ef                	jne    f0101695 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016a6:	83 ef 04             	sub    $0x4,%edi
f01016a9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016ac:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01016af:	fd                   	std    
f01016b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016b2:	eb ea                	jmp    f010169e <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016b4:	89 f2                	mov    %esi,%edx
f01016b6:	09 c2                	or     %eax,%edx
f01016b8:	f6 c2 03             	test   $0x3,%dl
f01016bb:	74 09                	je     f01016c6 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016bd:	89 c7                	mov    %eax,%edi
f01016bf:	fc                   	cld    
f01016c0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016c2:	5e                   	pop    %esi
f01016c3:	5f                   	pop    %edi
f01016c4:	5d                   	pop    %ebp
f01016c5:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016c6:	f6 c1 03             	test   $0x3,%cl
f01016c9:	75 f2                	jne    f01016bd <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016cb:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01016ce:	89 c7                	mov    %eax,%edi
f01016d0:	fc                   	cld    
f01016d1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016d3:	eb ed                	jmp    f01016c2 <memmove+0x55>

f01016d5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016d5:	55                   	push   %ebp
f01016d6:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016d8:	ff 75 10             	pushl  0x10(%ebp)
f01016db:	ff 75 0c             	pushl  0xc(%ebp)
f01016de:	ff 75 08             	pushl  0x8(%ebp)
f01016e1:	e8 87 ff ff ff       	call   f010166d <memmove>
}
f01016e6:	c9                   	leave  
f01016e7:	c3                   	ret    

f01016e8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016e8:	55                   	push   %ebp
f01016e9:	89 e5                	mov    %esp,%ebp
f01016eb:	56                   	push   %esi
f01016ec:	53                   	push   %ebx
f01016ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016f3:	89 c6                	mov    %eax,%esi
f01016f5:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016f8:	39 f0                	cmp    %esi,%eax
f01016fa:	74 1c                	je     f0101718 <memcmp+0x30>
		if (*s1 != *s2)
f01016fc:	0f b6 08             	movzbl (%eax),%ecx
f01016ff:	0f b6 1a             	movzbl (%edx),%ebx
f0101702:	38 d9                	cmp    %bl,%cl
f0101704:	75 08                	jne    f010170e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101706:	83 c0 01             	add    $0x1,%eax
f0101709:	83 c2 01             	add    $0x1,%edx
f010170c:	eb ea                	jmp    f01016f8 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010170e:	0f b6 c1             	movzbl %cl,%eax
f0101711:	0f b6 db             	movzbl %bl,%ebx
f0101714:	29 d8                	sub    %ebx,%eax
f0101716:	eb 05                	jmp    f010171d <memcmp+0x35>
	}

	return 0;
f0101718:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010171d:	5b                   	pop    %ebx
f010171e:	5e                   	pop    %esi
f010171f:	5d                   	pop    %ebp
f0101720:	c3                   	ret    

f0101721 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101721:	55                   	push   %ebp
f0101722:	89 e5                	mov    %esp,%ebp
f0101724:	8b 45 08             	mov    0x8(%ebp),%eax
f0101727:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010172a:	89 c2                	mov    %eax,%edx
f010172c:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010172f:	39 d0                	cmp    %edx,%eax
f0101731:	73 09                	jae    f010173c <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101733:	38 08                	cmp    %cl,(%eax)
f0101735:	74 05                	je     f010173c <memfind+0x1b>
	for (; s < ends; s++)
f0101737:	83 c0 01             	add    $0x1,%eax
f010173a:	eb f3                	jmp    f010172f <memfind+0xe>
			break;
	return (void *) s;
}
f010173c:	5d                   	pop    %ebp
f010173d:	c3                   	ret    

f010173e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010173e:	55                   	push   %ebp
f010173f:	89 e5                	mov    %esp,%ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	53                   	push   %ebx
f0101744:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101747:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010174a:	eb 03                	jmp    f010174f <strtol+0x11>
		s++;
f010174c:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010174f:	0f b6 01             	movzbl (%ecx),%eax
f0101752:	3c 20                	cmp    $0x20,%al
f0101754:	74 f6                	je     f010174c <strtol+0xe>
f0101756:	3c 09                	cmp    $0x9,%al
f0101758:	74 f2                	je     f010174c <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010175a:	3c 2b                	cmp    $0x2b,%al
f010175c:	74 2e                	je     f010178c <strtol+0x4e>
	int neg = 0;
f010175e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101763:	3c 2d                	cmp    $0x2d,%al
f0101765:	74 2f                	je     f0101796 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101767:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010176d:	75 05                	jne    f0101774 <strtol+0x36>
f010176f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101772:	74 2c                	je     f01017a0 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101774:	85 db                	test   %ebx,%ebx
f0101776:	75 0a                	jne    f0101782 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101778:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010177d:	80 39 30             	cmpb   $0x30,(%ecx)
f0101780:	74 28                	je     f01017aa <strtol+0x6c>
		base = 10;
f0101782:	b8 00 00 00 00       	mov    $0x0,%eax
f0101787:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010178a:	eb 50                	jmp    f01017dc <strtol+0x9e>
		s++;
f010178c:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010178f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101794:	eb d1                	jmp    f0101767 <strtol+0x29>
		s++, neg = 1;
f0101796:	83 c1 01             	add    $0x1,%ecx
f0101799:	bf 01 00 00 00       	mov    $0x1,%edi
f010179e:	eb c7                	jmp    f0101767 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017a0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01017a4:	74 0e                	je     f01017b4 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01017a6:	85 db                	test   %ebx,%ebx
f01017a8:	75 d8                	jne    f0101782 <strtol+0x44>
		s++, base = 8;
f01017aa:	83 c1 01             	add    $0x1,%ecx
f01017ad:	bb 08 00 00 00       	mov    $0x8,%ebx
f01017b2:	eb ce                	jmp    f0101782 <strtol+0x44>
		s += 2, base = 16;
f01017b4:	83 c1 02             	add    $0x2,%ecx
f01017b7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017bc:	eb c4                	jmp    f0101782 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01017be:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017c1:	89 f3                	mov    %esi,%ebx
f01017c3:	80 fb 19             	cmp    $0x19,%bl
f01017c6:	77 29                	ja     f01017f1 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01017c8:	0f be d2             	movsbl %dl,%edx
f01017cb:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01017ce:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017d1:	7d 30                	jge    f0101803 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017d3:	83 c1 01             	add    $0x1,%ecx
f01017d6:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017da:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01017dc:	0f b6 11             	movzbl (%ecx),%edx
f01017df:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017e2:	89 f3                	mov    %esi,%ebx
f01017e4:	80 fb 09             	cmp    $0x9,%bl
f01017e7:	77 d5                	ja     f01017be <strtol+0x80>
			dig = *s - '0';
f01017e9:	0f be d2             	movsbl %dl,%edx
f01017ec:	83 ea 30             	sub    $0x30,%edx
f01017ef:	eb dd                	jmp    f01017ce <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01017f1:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017f4:	89 f3                	mov    %esi,%ebx
f01017f6:	80 fb 19             	cmp    $0x19,%bl
f01017f9:	77 08                	ja     f0101803 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017fb:	0f be d2             	movsbl %dl,%edx
f01017fe:	83 ea 37             	sub    $0x37,%edx
f0101801:	eb cb                	jmp    f01017ce <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101803:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101807:	74 05                	je     f010180e <strtol+0xd0>
		*endptr = (char *) s;
f0101809:	8b 75 0c             	mov    0xc(%ebp),%esi
f010180c:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010180e:	89 c2                	mov    %eax,%edx
f0101810:	f7 da                	neg    %edx
f0101812:	85 ff                	test   %edi,%edi
f0101814:	0f 45 c2             	cmovne %edx,%eax
}
f0101817:	5b                   	pop    %ebx
f0101818:	5e                   	pop    %esi
f0101819:	5f                   	pop    %edi
f010181a:	5d                   	pop    %ebp
f010181b:	c3                   	ret    
f010181c:	66 90                	xchg   %ax,%ax
f010181e:	66 90                	xchg   %ax,%ax

f0101820 <__udivdi3>:
f0101820:	55                   	push   %ebp
f0101821:	57                   	push   %edi
f0101822:	56                   	push   %esi
f0101823:	53                   	push   %ebx
f0101824:	83 ec 1c             	sub    $0x1c,%esp
f0101827:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010182b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010182f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101833:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101837:	85 d2                	test   %edx,%edx
f0101839:	75 35                	jne    f0101870 <__udivdi3+0x50>
f010183b:	39 f3                	cmp    %esi,%ebx
f010183d:	0f 87 bd 00 00 00    	ja     f0101900 <__udivdi3+0xe0>
f0101843:	85 db                	test   %ebx,%ebx
f0101845:	89 d9                	mov    %ebx,%ecx
f0101847:	75 0b                	jne    f0101854 <__udivdi3+0x34>
f0101849:	b8 01 00 00 00       	mov    $0x1,%eax
f010184e:	31 d2                	xor    %edx,%edx
f0101850:	f7 f3                	div    %ebx
f0101852:	89 c1                	mov    %eax,%ecx
f0101854:	31 d2                	xor    %edx,%edx
f0101856:	89 f0                	mov    %esi,%eax
f0101858:	f7 f1                	div    %ecx
f010185a:	89 c6                	mov    %eax,%esi
f010185c:	89 e8                	mov    %ebp,%eax
f010185e:	89 f7                	mov    %esi,%edi
f0101860:	f7 f1                	div    %ecx
f0101862:	89 fa                	mov    %edi,%edx
f0101864:	83 c4 1c             	add    $0x1c,%esp
f0101867:	5b                   	pop    %ebx
f0101868:	5e                   	pop    %esi
f0101869:	5f                   	pop    %edi
f010186a:	5d                   	pop    %ebp
f010186b:	c3                   	ret    
f010186c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101870:	39 f2                	cmp    %esi,%edx
f0101872:	77 7c                	ja     f01018f0 <__udivdi3+0xd0>
f0101874:	0f bd fa             	bsr    %edx,%edi
f0101877:	83 f7 1f             	xor    $0x1f,%edi
f010187a:	0f 84 98 00 00 00    	je     f0101918 <__udivdi3+0xf8>
f0101880:	89 f9                	mov    %edi,%ecx
f0101882:	b8 20 00 00 00       	mov    $0x20,%eax
f0101887:	29 f8                	sub    %edi,%eax
f0101889:	d3 e2                	shl    %cl,%edx
f010188b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010188f:	89 c1                	mov    %eax,%ecx
f0101891:	89 da                	mov    %ebx,%edx
f0101893:	d3 ea                	shr    %cl,%edx
f0101895:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101899:	09 d1                	or     %edx,%ecx
f010189b:	89 f2                	mov    %esi,%edx
f010189d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018a1:	89 f9                	mov    %edi,%ecx
f01018a3:	d3 e3                	shl    %cl,%ebx
f01018a5:	89 c1                	mov    %eax,%ecx
f01018a7:	d3 ea                	shr    %cl,%edx
f01018a9:	89 f9                	mov    %edi,%ecx
f01018ab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01018af:	d3 e6                	shl    %cl,%esi
f01018b1:	89 eb                	mov    %ebp,%ebx
f01018b3:	89 c1                	mov    %eax,%ecx
f01018b5:	d3 eb                	shr    %cl,%ebx
f01018b7:	09 de                	or     %ebx,%esi
f01018b9:	89 f0                	mov    %esi,%eax
f01018bb:	f7 74 24 08          	divl   0x8(%esp)
f01018bf:	89 d6                	mov    %edx,%esi
f01018c1:	89 c3                	mov    %eax,%ebx
f01018c3:	f7 64 24 0c          	mull   0xc(%esp)
f01018c7:	39 d6                	cmp    %edx,%esi
f01018c9:	72 0c                	jb     f01018d7 <__udivdi3+0xb7>
f01018cb:	89 f9                	mov    %edi,%ecx
f01018cd:	d3 e5                	shl    %cl,%ebp
f01018cf:	39 c5                	cmp    %eax,%ebp
f01018d1:	73 5d                	jae    f0101930 <__udivdi3+0x110>
f01018d3:	39 d6                	cmp    %edx,%esi
f01018d5:	75 59                	jne    f0101930 <__udivdi3+0x110>
f01018d7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01018da:	31 ff                	xor    %edi,%edi
f01018dc:	89 fa                	mov    %edi,%edx
f01018de:	83 c4 1c             	add    $0x1c,%esp
f01018e1:	5b                   	pop    %ebx
f01018e2:	5e                   	pop    %esi
f01018e3:	5f                   	pop    %edi
f01018e4:	5d                   	pop    %ebp
f01018e5:	c3                   	ret    
f01018e6:	8d 76 00             	lea    0x0(%esi),%esi
f01018e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018f0:	31 ff                	xor    %edi,%edi
f01018f2:	31 c0                	xor    %eax,%eax
f01018f4:	89 fa                	mov    %edi,%edx
f01018f6:	83 c4 1c             	add    $0x1c,%esp
f01018f9:	5b                   	pop    %ebx
f01018fa:	5e                   	pop    %esi
f01018fb:	5f                   	pop    %edi
f01018fc:	5d                   	pop    %ebp
f01018fd:	c3                   	ret    
f01018fe:	66 90                	xchg   %ax,%ax
f0101900:	31 ff                	xor    %edi,%edi
f0101902:	89 e8                	mov    %ebp,%eax
f0101904:	89 f2                	mov    %esi,%edx
f0101906:	f7 f3                	div    %ebx
f0101908:	89 fa                	mov    %edi,%edx
f010190a:	83 c4 1c             	add    $0x1c,%esp
f010190d:	5b                   	pop    %ebx
f010190e:	5e                   	pop    %esi
f010190f:	5f                   	pop    %edi
f0101910:	5d                   	pop    %ebp
f0101911:	c3                   	ret    
f0101912:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101918:	39 f2                	cmp    %esi,%edx
f010191a:	72 06                	jb     f0101922 <__udivdi3+0x102>
f010191c:	31 c0                	xor    %eax,%eax
f010191e:	39 eb                	cmp    %ebp,%ebx
f0101920:	77 d2                	ja     f01018f4 <__udivdi3+0xd4>
f0101922:	b8 01 00 00 00       	mov    $0x1,%eax
f0101927:	eb cb                	jmp    f01018f4 <__udivdi3+0xd4>
f0101929:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101930:	89 d8                	mov    %ebx,%eax
f0101932:	31 ff                	xor    %edi,%edi
f0101934:	eb be                	jmp    f01018f4 <__udivdi3+0xd4>
f0101936:	66 90                	xchg   %ax,%ax
f0101938:	66 90                	xchg   %ax,%ax
f010193a:	66 90                	xchg   %ax,%ax
f010193c:	66 90                	xchg   %ax,%ax
f010193e:	66 90                	xchg   %ax,%ax

f0101940 <__umoddi3>:
f0101940:	55                   	push   %ebp
f0101941:	57                   	push   %edi
f0101942:	56                   	push   %esi
f0101943:	53                   	push   %ebx
f0101944:	83 ec 1c             	sub    $0x1c,%esp
f0101947:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010194b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010194f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101953:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101957:	85 ed                	test   %ebp,%ebp
f0101959:	89 f0                	mov    %esi,%eax
f010195b:	89 da                	mov    %ebx,%edx
f010195d:	75 19                	jne    f0101978 <__umoddi3+0x38>
f010195f:	39 df                	cmp    %ebx,%edi
f0101961:	0f 86 b1 00 00 00    	jbe    f0101a18 <__umoddi3+0xd8>
f0101967:	f7 f7                	div    %edi
f0101969:	89 d0                	mov    %edx,%eax
f010196b:	31 d2                	xor    %edx,%edx
f010196d:	83 c4 1c             	add    $0x1c,%esp
f0101970:	5b                   	pop    %ebx
f0101971:	5e                   	pop    %esi
f0101972:	5f                   	pop    %edi
f0101973:	5d                   	pop    %ebp
f0101974:	c3                   	ret    
f0101975:	8d 76 00             	lea    0x0(%esi),%esi
f0101978:	39 dd                	cmp    %ebx,%ebp
f010197a:	77 f1                	ja     f010196d <__umoddi3+0x2d>
f010197c:	0f bd cd             	bsr    %ebp,%ecx
f010197f:	83 f1 1f             	xor    $0x1f,%ecx
f0101982:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101986:	0f 84 b4 00 00 00    	je     f0101a40 <__umoddi3+0x100>
f010198c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101991:	89 c2                	mov    %eax,%edx
f0101993:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101997:	29 c2                	sub    %eax,%edx
f0101999:	89 c1                	mov    %eax,%ecx
f010199b:	89 f8                	mov    %edi,%eax
f010199d:	d3 e5                	shl    %cl,%ebp
f010199f:	89 d1                	mov    %edx,%ecx
f01019a1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01019a5:	d3 e8                	shr    %cl,%eax
f01019a7:	09 c5                	or     %eax,%ebp
f01019a9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019ad:	89 c1                	mov    %eax,%ecx
f01019af:	d3 e7                	shl    %cl,%edi
f01019b1:	89 d1                	mov    %edx,%ecx
f01019b3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01019b7:	89 df                	mov    %ebx,%edi
f01019b9:	d3 ef                	shr    %cl,%edi
f01019bb:	89 c1                	mov    %eax,%ecx
f01019bd:	89 f0                	mov    %esi,%eax
f01019bf:	d3 e3                	shl    %cl,%ebx
f01019c1:	89 d1                	mov    %edx,%ecx
f01019c3:	89 fa                	mov    %edi,%edx
f01019c5:	d3 e8                	shr    %cl,%eax
f01019c7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019cc:	09 d8                	or     %ebx,%eax
f01019ce:	f7 f5                	div    %ebp
f01019d0:	d3 e6                	shl    %cl,%esi
f01019d2:	89 d1                	mov    %edx,%ecx
f01019d4:	f7 64 24 08          	mull   0x8(%esp)
f01019d8:	39 d1                	cmp    %edx,%ecx
f01019da:	89 c3                	mov    %eax,%ebx
f01019dc:	89 d7                	mov    %edx,%edi
f01019de:	72 06                	jb     f01019e6 <__umoddi3+0xa6>
f01019e0:	75 0e                	jne    f01019f0 <__umoddi3+0xb0>
f01019e2:	39 c6                	cmp    %eax,%esi
f01019e4:	73 0a                	jae    f01019f0 <__umoddi3+0xb0>
f01019e6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01019ea:	19 ea                	sbb    %ebp,%edx
f01019ec:	89 d7                	mov    %edx,%edi
f01019ee:	89 c3                	mov    %eax,%ebx
f01019f0:	89 ca                	mov    %ecx,%edx
f01019f2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01019f7:	29 de                	sub    %ebx,%esi
f01019f9:	19 fa                	sbb    %edi,%edx
f01019fb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01019ff:	89 d0                	mov    %edx,%eax
f0101a01:	d3 e0                	shl    %cl,%eax
f0101a03:	89 d9                	mov    %ebx,%ecx
f0101a05:	d3 ee                	shr    %cl,%esi
f0101a07:	d3 ea                	shr    %cl,%edx
f0101a09:	09 f0                	or     %esi,%eax
f0101a0b:	83 c4 1c             	add    $0x1c,%esp
f0101a0e:	5b                   	pop    %ebx
f0101a0f:	5e                   	pop    %esi
f0101a10:	5f                   	pop    %edi
f0101a11:	5d                   	pop    %ebp
f0101a12:	c3                   	ret    
f0101a13:	90                   	nop
f0101a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	85 ff                	test   %edi,%edi
f0101a1a:	89 f9                	mov    %edi,%ecx
f0101a1c:	75 0b                	jne    f0101a29 <__umoddi3+0xe9>
f0101a1e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a23:	31 d2                	xor    %edx,%edx
f0101a25:	f7 f7                	div    %edi
f0101a27:	89 c1                	mov    %eax,%ecx
f0101a29:	89 d8                	mov    %ebx,%eax
f0101a2b:	31 d2                	xor    %edx,%edx
f0101a2d:	f7 f1                	div    %ecx
f0101a2f:	89 f0                	mov    %esi,%eax
f0101a31:	f7 f1                	div    %ecx
f0101a33:	e9 31 ff ff ff       	jmp    f0101969 <__umoddi3+0x29>
f0101a38:	90                   	nop
f0101a39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a40:	39 dd                	cmp    %ebx,%ebp
f0101a42:	72 08                	jb     f0101a4c <__umoddi3+0x10c>
f0101a44:	39 f7                	cmp    %esi,%edi
f0101a46:	0f 87 21 ff ff ff    	ja     f010196d <__umoddi3+0x2d>
f0101a4c:	89 da                	mov    %ebx,%edx
f0101a4e:	89 f0                	mov    %esi,%eax
f0101a50:	29 f8                	sub    %edi,%eax
f0101a52:	19 ea                	sbb    %ebp,%edx
f0101a54:	e9 14 ff ff ff       	jmp    f010196d <__umoddi3+0x2d>
