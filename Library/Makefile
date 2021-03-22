-include config.mk

OBJ = $(COBJ) $(ASMOBJ)

# Dependency files, to be generated from the objects the user specified.
DEPS = $(patsubst %.o,%.d,$(OBJ))

# Mandatory C flags added by the makefile.
override CFLAGS += -Wall -Wshadow -Wextra -Werror -Wuninitialized -pedantic $(addprefix -I,$(INC))

# Sets the default command to the target
default: $(TARGET)

# Builds an object file and an associated dependency file.
$(COBJ): %.o : %.c %.d
	$(CC) $(CFLAGS) -MMD -c $(patsubst %.o,%.c,$@) -MF $(patsubst %.o,%.d,$@) -o $@

$(ASMOBJ): %.o : %.S %.d
	$(CC) $(CFLAGS) -MMD -c $(patsubst %.o,%.S,$@) -MF $(patsubst %.o,%.d,$@) -o $@

# Ensures that an object will be rebuilt if its dependency list is missing.
$(DEPS):;

# Includes all built dependency files as they are created.
# This ensures that files will be rebuilt when the headers they depend on change.
-include $(DEPS)

# General format for building a main file.
$(TARGET): % : $(OBJ)
	$(AR) rcu $(OUTDIR)/$@ $(OBJ)

# Prevent issues with make commands.
.PHONY: clean

# Removes built files.
clean:
	-rm -f $(OBJ)
	-rm -f $(DEPS)
	-rm -f $(TARGET)
