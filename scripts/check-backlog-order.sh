#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

awk '
function trim(value) {
  sub(/^[[:space:]]+/, "", value)
  sub(/[[:space:]]+$/, "", value)
  return value
}

function isBug(categories) {
  return (", " categories ", ") ~ /, bug, /
}

BEGIN {
  expectedRank = 1
  foundRows = 0
  foundNonBug = 0
  valid = 1
}

/^## Category views/ {
  inPlanningSurface = 0
}

/^## Top 10 priorities/ {
  inPlanningSurface = 1
}

inPlanningSurface && /^\| [0-9]+ \| \[AS-[0-9]+\]/ {
  split($0, fields, "|")
  rank = trim(fields[2]) + 0
  id = trim(fields[3])
  categories = trim(fields[5])

  sub(/^\[/, "", id)
  sub(/\].*$/, "", id)

  if (rank != expectedRank) {
    printf "Backlog rank error: expected %d, found %d for %s.\n", expectedRank, rank, id > "/dev/stderr"
    valid = 0
  }

  if (isBug(categories)) {
    if (foundNonBug) {
      printf "Backlog order error: bug %s ranks after a non-bug.\n", id > "/dev/stderr"
      valid = 0
    }
  } else {
    foundNonBug = 1
  }

  tablePresent[id] = 1
  tableBug[id] = isBug(categories)
  expectedRank++
  foundRows++
}

/^## AS-[0-9]+ / {
  currentId = $2
  detailPresent[currentId] = 1
}

currentId && /^\*\*Categories:\*\*/ {
  categories = $0
  sub(/^\*\*Categories:\*\*[[:space:]]*/, "", categories)
  sub(/<br>$/, "", categories)
  detailBug[currentId] = isBug(categories)
}

END {
  if (!foundRows) {
    print "Backlog order error: no planning rows found." > "/dev/stderr"
    valid = 0
  }

  if (foundRows != 10) {
    printf "Backlog order error: expected 10 planning rows, found %d.\n", foundRows > "/dev/stderr"
    valid = 0
  }

  for (id in tablePresent) {
    if (!detailPresent[id]) {
      printf "Backlog consistency error: planning item %s has no detailed entry.\n", id > "/dev/stderr"
      valid = 0
    } else if (tableBug[id] != detailBug[id]) {
      printf "Backlog consistency error: bug category for %s differs between its planning row and detailed entry.\n", id > "/dev/stderr"
      valid = 0
    }
  }

  if (!valid) {
    exit 1
  }
}
' docs/backlog.md

echo "BACKLOG_ORDER_OK: top-ten ranks are contiguous, bug categories agree, and all bugs precede non-bugs."
