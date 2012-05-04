#----------------------------
# Makefile
#----------------------------

# Executable name
PROJECTNAME=aes

# Source codes
PRJSRC=main.c ../../uart.c aes.S

# Target controller
MCU=atmega128

# Include path (currently not needed)
#INC=-I/path/to/include
INC=

# Linker libraries (currently not needed)
LIBS=

# Optimization level - s (size opt), 1, 2, 3, 0 (off)
OPTLEVEL=3

# Re-create the target with every make command
MAKEFLAGS=-B

#----------------------------

CC=avr-gcc
OBJCOPY=avr-objcopy
OBJDUMP=avr-objdump
SIZE=avr-size
REMOVE=rm -f
SIMULAVR=simulavr

TRG=$(PROJECTNAME).out
DUMPTRG=$(PROJECTNAME).s.disasm
TRACEFILE=$(PROJECTNAME).trace.txt
GDBINITFILE=gdbinit-$(PROJECTNAME)
CFILES=$(filter %.c, $(PRJSRC))
ASMFILES=$(filter %.S, $(PRJSRC))

# Compiler flags
# Tuning flags as proposed by avr-libc documentation
# -ahlms -> create asm listing
CFLAGS=-I. $(INC) -g -mmcu=$(MCU) -O$(OPTLEVEL) \
	-fpack-struct -fshort-enums             \
	-ffunction-sections -fdata-sections			\
	-funsigned-bitfields -funsigned-char    \
	-Wall -Wstrict-prototypes               \
	-Wa,-ahlms=$(firstword                  \
	$(filter %.lst, $(<:.c=.lst)))

# Assembler flags
# -gstabs -> line number information
ASMFLAGS =-I. $(INC) -mmcu=$(MCU) -Wa,-gstabs,-ahlms=$(firstword $(<:.S=.lst) $(<.s=.lst))
ASMFLAGS += -x assembler-with-cpp 

# Linker flags
LDFLAGS=-Wl,-Map,$(TRG).map -mmcu=$(MCU) \
	-Wl,-static -Wl,-gc-sections     \
	-lm $(LIBS)

OBJDEPS=$(CFILES:.c=.o) $(ASMFILES:.S=.o)
LST=$(filter %.lst, $(OBJDEPS:.o=.lst))

.SUFFIXES: .c .o .out .s .S .h
.PHONY: clean gdbinit stats sim disasm trace

# Targets
all: $(TRG)

disasm: $(DUMPTRG)
	$(OBJDUMP) -h $(TRG)
	$(SIZE) $(TRG)
	perl ../../objdump_parser.pl < $(DUMPTRG)

# The special outport (0x20) and inport (0x22) are needed cause otherwise
# -V wouldn't print hex values on the serial port. Strange anyway...
# Probably another bug in simulavr
sim: 	all
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit
	
debug:	all
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -v

trace:	all
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -t $(TRACEFILE)
	perl ../../simulavr_parser.pl < $(TRACEFILE)

stats:	all
	$(OBJDUMP) -S $(TRG) > $(DUMPTRG)
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -t $(TRACEFILE)
	perl aes_stats.pl

$(DUMPTRG): $(TRG) 
	$(OBJDUMP) -S $< > $@

$(TRG): $(OBJDEPS)
	$(CC) $(LDFLAGS) -o $(TRG) $(OBJDEPS)

# Generators

# asm from C
%.s: %.c
	$(CC) -S $(CFLAGS) $< -o $@
	
# asm from ASM (compiler ASM)
%.s: %.S
	$(CC) -S $(ASMFLAGS) $< > $@	
	
# object from C
.c.o: 
	$(CC) $(CFLAGS) -c $< -o $@
	
# object from asm
.S.o :
	$(CC) $(ASMFLAGS) -c $< -o $@
	
# GDB init file generation
# For launching simulavr and avr-gdb:
# avr-gdb -x gdbinit-project
gdbinit: $(GDBINITFILE)

$(GDBINITFILE): $(TRG)
	@echo "file $(TRG)" > $(GDBINITFILE)
	@echo "target remote localhost:4242" >> $(GDBINITFILE)
	@echo "load"        >> $(GDBINITFILE) 
	@echo "break main"  >> $(GDBINITFILE)
	@echo "continue"    >> $(GDBINITFILE)
	@echo ""
	@echo "Use 'avr-gdb -x $(GDBINITFILE)'"
	$(SIMULAVR) --gdbserver -p 4242 --device atmega128

# Cleanup procedure
clean:
	$(REMOVE) $(TRG) $(TRG).map $(DUMPTRG)
	$(REMOVE) $(OBJDEPS)
	$(REMOVE) $(LST) 
	$(REMOVE) $(PROJECTNAME).trace*.txt
#$(GDBINITFILE)
