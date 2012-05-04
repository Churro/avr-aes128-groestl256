#----------------------------
# Makefile
#----------------------------

# Executable name
PROJECTNAME=groestl

# Distributable name
DISTNAME=groestl-8bit_asm-1.0a

# Source codes
PRJSRC=main.c ../../uart.c hash.S

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
	-ffunction-sections -fdata-sections     \
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
	-Wl,-static -Wl,-gc-sections

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

sim: 	all
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit

debug:	all
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -v

trace:	all
	@rm -f groestl.trace*.txt
	@touch groestl.trace_x.txt
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -t $(TRACEFILE)
	@cat groestl.trace_*.txt >> $(TRACEFILE)
	perl ../../simulavr_parser.pl < $(TRACEFILE)

stats:	all
	$(OBJDUMP) -S $(TRG) > $(DUMPTRG)
	@rm -f groestl.trace*.txt
	@touch groestl.trace_x.txt
	$(SIMULAVR) -d $(MCU) -f $(TRG) -T exit -t $(TRACEFILE)
	@cat groestl.trace_*.txt >> $(TRACEFILE) 2> /dev/null
	perl groestl_stats.pl

test:	
	perl groestl_test.pl

teststats:
	perl groestl_test.pl asdf

dist:	$(DISTNAME).tar.gz

help:
	@echo "Groestl Suite v0.1\n\
	Author: Johannes Feichtner\n"
	@echo "Available targets:\n\n\
	- debug: \tRuns the simulation with listings of every call and ret instruction\n\
	- disasm: \tCreates a disassembly using objdump and analyzes it\n\
	- dist: \tCreates a .tar.gz archive for eBASH\n\
	- sim: \t\tSimulates the executable\n\
	- stats: \tSimulates the executable, creates a disassembly and trace file and analyzes them\n\
	- test: \tSimulates all known testcases consecutively\n\
	- teststats: \tSimulates all testcases and fetches the clock cycles needed for execution\n\
	- trace: \tSimulates the executable with further tracing"

$(DUMPTRG): $(TRG) 
	$(OBJDUMP) -S $< > $@

$(TRG): $(OBJDEPS) 
	$(CC) $(LDFLAGS) -o $(TRG) $(OBJDEPS)

$(DISTNAME).tar.gz: api.h hash.S
	@mkdir -p crypto_hash/groestl256/8bit_asm/
	@cp api.h hash.S crypto_hash/groestl256/8bit_asm/
	tar -czf $@ crypto_hash
	@rm -R crypto_hash

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
