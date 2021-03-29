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
	$(CC) $(CFLAGS) $(OBJ) -o $@ $(LIBS)

# Prevent issues with make commands.
.PHONY: install
.PHONY: uninstall
.PHONY: clean

# Install to program to local directories.
install:
ifneq (,$(wildcard ./$(TARGET)))
ifeq ($(UNAME),Linux)
	-cp ./$(TARGET) /usr/local/bin/
endif
endif

# Remove the program from local directories.
uninstall:
ifeq ($(UNAME),Linux)
	-rm /usr/local/bin/$(TARGET)
endif

# Removes built files.
clean:
	-rm -f $(OBJ)
	-rm -f $(DEPS)
	-rm -f $(TARGET)
