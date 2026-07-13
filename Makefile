TARGET 	?= app
i 		?= maxmin.c
a 		?= ""
b 		?= ""

MAXFUNCSIZE = 42


CC		=gcc
ASAN	= -fsanitize=address -g
FLAGS	= -Wall -Werror -Wextra -std=c11 -I $(INC)/ $(ASAN)
LDLIBS 	= -lm -lncursesw

OUT		=./out
SRC		=.
INC		=.

ALL_C = $(wildcard $(SRC)/$(i))
ALL_OBJ = $(ALL_C:$(SRC)/%.c=$(OUT)/%.o)

run: clean out $(TARGET) 
	@./$(TARGET) $(a) $(b)
	
out:
	mkdir -p $(OUT)

$(TARGET): $(ALL_OBJ)
	$(CC) $(ASAN) -o $(TARGET) $(ALL_OBJ) $(LDLIBS)
	
$(OUT)/%.o: $(SRC)/%.c
	$(CC) $(FLAGS) -o $@ -c $^

.PHONY: clean form check valgrind nwi info start ft test

# new_week_individual
nwi: form ft check valgrind 

start: 
	git checkout -b develop
	cp ./../materials/linters/.clang-format .
	git add ../.gitignore
	git commit -m "develop: .gitignore added"
	
check:
	@cppcheck --enable=all --suppress=missingIncludeSystem $(i)

form:
	@clang-format --style=file -i $(SRC)/*.c
	@clang-format -n $(SRC)/*.c

valgrind: ASAN :=
valgrind: $(TARGET)
	@valgrind --tool=memcheck --leak-check=yes ./$(TARGET) $(a) $(b)

# four_two
ft:
	for i in $(ALL_C); do \
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
