#!/usr/bin/env bash
# Initialize blue and green branches for the branch-based environment management
# Usage: ./scripts/init-branches.sh

set -euo pipefail

echo "Initializing blue and green branches..."

# Create blue branch
if git show-ref --verify --quiet refs/heads/blue; then
  echo "blue branch already exists"
else
  git checkout -b blue
  git push -u origin blue
  echo "Created and pushed blue branch"
fi

# Create green branch
if git show-ref --verify --quiet refs/heads/green; then
  echo "green branch already exists"
else
  git checkout -b green
  git push -u origin green
  echo "Created and pushed green branch"
fi

# Switch back to main
git checkout main

echo "Branch initialization complete!"
echo "You can now work with environments by switching branches:"
echo "  git checkout blue  # Work on blue environment"
echo "  git checkout green # Work on green environment"
