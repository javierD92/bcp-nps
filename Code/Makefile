# Compiler and Flags
FC = gfortran
FFLAGS = -Ofast -Wall 

# Object files
OBJS = mod_core_types.o \
       mod_stats.o \
       mod_field.o \
       mod_coupling.o \
       mod_particles.o \
       mod_io.o \
       main.o

# Executable name
TARGET = simulation.exe

# Default target
all: $(TARGET)

# Link objects to create executable
$(TARGET): $(OBJS)
	$(FC) $(FFLAGS) -o $(TARGET) $(OBJS)

# Compile Fortran files into objects
%.o: %.f90
	$(FC) $(FFLAGS) -c $<

# Module Dependencies
# (Ensures .mod files exist before dependent files compile)
mod_field.o: mod_core_types.o
mod_coupling.o: mod_core_types.o
mod_particles.o: mod_core_types.o
mod_stats.o: mod_core_types.o
mod_io.o: mod_core_types.o mod_stats.o
main.o: mod_core_types.o mod_field.o mod_coupling.o mod_particles.o mod_io.o

# Utility to remove build files
equilibrated:
	rm -f *.txt *.dat *.out *.png  
	mv checkpoint.bin equilibrated.bin

clean:
	rm -f *.o *.mod $(TARGET)
	rm -f *.dat *.txt *.png output *.bin 

.PHONY: all clean