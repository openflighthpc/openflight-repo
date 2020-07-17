#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <package>"
  exit 1
fi

pushd "$(dirname "$1")"/.. >& /dev/null
porc="$(git status --porcelain .)"
rc=$?
if [ $rc -gt 0 ]; then
  echo $rc
  exit $rc
fi
changes=$(echo -n "$porc" | wc -l)
if [ "$changes" -gt 0 ]; then
  echo "Uncommitted changes detected:"
  echo ""
  git status --porcelain .
  exit 1
fi
popd >& /dev/null
