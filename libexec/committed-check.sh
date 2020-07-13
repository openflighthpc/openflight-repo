#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <package>"
  exit 1
fi

pushd "$(dirname "$1")"/.. >& /dev/null
changes=$(git status --porcelain . | wc -l)
if [ "$changes" -gt 0 ]; then
  echo "Uncommitted changes detected:"
  echo ""
  git status --porcelain .
  exit 1
fi
popd >& /dev/null
