TARGET 	?= app
i 		?= *.c
d 		?= data_module
a 		?= ""
b 		?= ""
libs 	?= data_libs

OUT		= $(d)/out
SRC		= $(d)
INC		= $(d)/

OUT_LIB		= $(libs)/out
SRC_LIB		= $(libs)
INC_LIBS	= $(libs)


MAXFUNCSIZE = 42

CC		= gcc
ASAN	= -fsanitize=address -g
FLAGS	= -Wall -Werror -Wextra -std=c11 -I $(INC) -I $(INC_LIBS)
LDLIBS 	= -lm 

ALL_C = $(wildcard $(SRC)/$(i)) 
LIBS_C = $(wildcard $(SRC_LIB)/$(i))

ALL_OBJ = $(ALL_C:$(SRC)/%.c=$(OUT)/%.o)
ALL_OBJ_LIBS = $(LIBS_C:$(SRC_LIB)/%.c=$(OUT_LIB)/%.o)


run: clean out $(TARGET)  
	@./$(TARGET) $(a) $(b) 
	
out:
	@mkdir -p $(OUT) $(OUT_LIB)
	
$(TARGET): $(ALL_OBJ) $(ALL_OBJ_LIBS)
	$(CC) $(ASAN) -o $(TARGET) $(ALL_OBJ) $(ALL_OBJ_LIBS) $(LDLIBS)
	
$(OUT)/%.o: $(SRC)/%.c
	$(CC) $(FLAGS) -o $@ -c $^

$(OUT_LIB)/%.o: $(SRC_LIB)/%.c
	$(CC) $(FLAGS) -o $@ -c $^


.PHONY: clean form check valgrind nwi info start ft test

# new_week_individual
nwi: form ft check valgrind test

start: 
	git checkout -b develop  || continue
	cp ./../materials/linters/.clang-format . || continue
	git add ../.gitignore || continue
	git commit -m "develop: .gitignore added"
	
check:
	@cppcheck --enable=all --suppress=missingIncludeSystem -I $(INC) $(INC_LIBS) $(SRC)/$(i) $(SRC_LIB)/$(i)

form:
	@clang-format --style=file -i $(SRC)/*.c $(SRC_LIB)/*.c
	@clang-format -n $(SRC)/*.c $(SRC_LIB)/*.c

valgrind: ASAN :=
valgrind: out $(TARGET)
	@valgrind --tool=memcheck --leak-check=yes ./$(TARGET) $(a) $(b)

# four_two
ft:
	for i in $(ALL_C) $(LIBS_C); do \
		awk '{ \
			for (j = 1; j <= length($$0); j++) { \
				char = substr($$0, j, 1); \
				if (char == "{") { \
					level++; \
					if (level == 1) { \
						block_start = NR ":" j; \
						count = 0; \
					} \
				} else if (char == "}") { \
					if (level == 1 && count > 42) { \
						printf "\033[31mБлок от %s до %d:%d содержит %d символов \\n\033[0m\n", block_start, NR, j, count; \
					} \
					level--; \
				} \
			} \
			if (level > 0) { \
				count++; \
			} \
		}' $$i; \
	done

test:
	@chmod u+x ./../run_tests.sh
	@./../run_tests.sh
	
clean:
	rm -rf $(OUT) $(TARGET)
