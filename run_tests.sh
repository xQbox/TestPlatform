#!/bin/bash
# Прогон тестов + проверка качества.
#   tests/taskN/testM.txt -> stdin, сравнение с testM.out.
# По каждой задаче печатается:
#   taskN->сборка->Успех|Ошибка   компиляция тестового бинарника (под ASan)
#   taskN->nwi->Успех|Ошибка       make nwi (формат/длина функций/cppcheck/valgrind)
#   taskN->testM->Успех|Ошибка     сравнение вывода с эталоном
# Так видно разницу: сломалась СБОРКА или не прошёл NWI.
# ВНИМАНИЕ: make nwi через clang-format -i переформатирует src/*.c на месте.

cd "$(dirname "$0")" || exit 1

for cfile in src/*.c; do
  [ -f "$cfile" ] || continue
  prog=$(basename "$cfile" .c)          
  dir="tests/$prog/"                    
  [ -d "$dir" ] || continue             

  # 1) Сборка тестового бинарника (под ASan). Не собралось -> это проблема сборки.
  if make -s -C src TARGET="$prog" i="$prog.c" out "$prog" 2>/dev/null; then
    echo "$task->сборка->Успех"
  else
    echo "$task->сборка->Ошибка"
    make -s -C src clean TARGET="$prog" >/dev/null 2>&1
    continue
  fi

  # 2) Тесты
  for input in $(printf '%s\n' "$dir"test*.txt | sort -V); do
    [ -f "$input" ] || continue
    test=$(basename "$input" .txt)
    if [ "$(./src/"$prog" <"$input")" = "$(cat "${input%.txt}.out" 2>/dev/null)" ]; then
      echo "$task->$test->Успех"
    else
      echo "$task->$test->Ошибка"
    fi
  done
  make -s -C src clean TARGET="$prog" >/dev/null 2>&1

  # 3) Качество: make nwi (valgrind кормим ОБЯЗАТЕЛЬНО валидным входным тестом).
  if make -s -C src out nwi i="$prog.c" <"${dir}test1.txt" >/dev/null 2>&1; then
    echo "$task->nwi->Успех"
  else
    echo "$task->nwi->Ошибка"
  fi
  make -s -C src clean >/dev/null 2>&1
done
