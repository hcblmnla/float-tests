#!/bin/bash

if [[ $# -lt 4 || $# -gt 5 ]]; then
  echo "Usage: sh tester.sh <round> <bits> <operation> <mode> [limit]"
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

MODE=$4

if [[ "$MODE" != "lite" && "$MODE" != "hard" ]]; then
  echo "Unknown mode: $MODE" ; exit 1
fi

if [[ $# -eq 5 ]]; then
  LIMIT=$5
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

sh compile.sh
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

  EXPECTED=$(sh print.sh $PREC $ROUND "$C")
  FOUND=$(sh eval.sh $PREC $ROUND "$A" $SIGN "$B")

  if [[ $((ALL % 100)) -eq 0 && $OUTPUT -eq 1 ]]; then
    echo "  Running on $ALL test"
  fi

  # NOTE: optimize
  if [[ "$MODE" == "lite" && "$EXPECTED" == "$FOUND" || "$MODE" == "hard" && "$EXPECTED $C" == "$FOUND" ]]; then
    PASSED=$((PASSED + 1))
  else
    echo "Test $ALL. Expected $EXPECTED, but found $FOUND, where $A $SIGN $B"
  fi

  ALL=$((ALL + 1))
done < "$FILE"

ALL=$((ALL - 1))
echo "Mode:   rounding $ROUND, bits count $BITS, operation $OP"
echo "Passed: $PASSED of $ALL tests"

sh clean.sh
