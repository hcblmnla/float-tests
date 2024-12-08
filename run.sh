#!/bin/bash

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: sh run.sh <round> <bits> <operation> [limit]"
  exit 1
fi

WORD=$1

case $WORD in
  tz)   ROUND=0 ;;
  base) ROUND=1 ;;
  up)   ROUND=2 ;;
  down) ROUND=3 ;;
  *) echo "Invalid rounding: $WORD" ; exit 1 ;;
esac

BITS=$2

case $BITS in
  16) PREC='h' ;;
  32) PREC='f' ;;
  *) echo "Invalid bits count: $BITS" ; exit 1 ;;
esac

OP=$3

case $OP in
  add) SIGN='+' ;;
  sub) SIGN='-' ;;
  mul) SIGN='m' ;;
  div) SIGN='/' ;;
  *) echo "Invalid operation: $OP" ; exit 1 ;;
esac

if [[ $# -eq 4 ]]; then
  LIMIT=$4
  OUTPUT=1
else
  LIMIT=46464
  OUTPUT=0
fi

FILE="${WORD}/${WORD}_f${BITS}_${OP}"

if [[ ! -f $FILE ]]; then
  echo "File $FILE does not exist"
  exit 1
fi

clang main.c -o a.out
if [[ $? -ne 0 ]]; then
  echo "Compilation failed"
  exit 1
fi

PASSED=0
ALL=1

while IFS= read -r line; do
  if [[ $ALL -gt $LIMIT ]]; then
    break
  fi

  IFS=' ' read -r A B C _ <<< "$line"

  EXPECTED=$(./a.out $PREC $ROUND "$C")
  FOUND=$(./a.out $PREC $ROUND "$A" $SIGN "$B")

  if [[ $((ALL % 100)) -eq 0 && $OUTPUT -eq 1 ]]; then
    echo "  Running on $ALL test"
  fi

  if [[ "$EXPECTED" == "$FOUND" ]]; then
    PASSED=$((PASSED + 1))
    # echo "Test $ALL. $A $SIGN $B = $FOUND correct"
  else
    echo "Test $ALL. Expected $EXPECTED, but found $FOUND, where $A $SIGN $B"
  fi

  ALL=$((ALL + 1))
done < "$FILE"

ALL=$((ALL - 1))
echo "Mode:   rounding $ROUND, bits count $BITS, operation $OP"
echo "Passed: $PASSED of $ALL tests"

rm -f a.out
