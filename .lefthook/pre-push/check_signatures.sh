#!/bin/bash

# Get the name of the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Check if non-pushed commits are signed
if git log origin/"$current_branch"..HEAD --pretty=format:'%G?' | grep -qv "G"; then
  echo "Error: One or more non-pushed commits are not signed."
  exit 1
else
  echo "All non-pushed commits are properly signed."
  exit 0
fi
