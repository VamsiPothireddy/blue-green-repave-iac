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
  # Ensure blue.tfvars has active = true and remove green.tfvars if it exists
  sed -i '' 's/active = false/active = true/' terraform/environments/blue.tfvars || true
  rm -f terraform/environments/green.tfvars
  git add terraform/environments/blue.tfvars
  git add terraform/environments/green.tfvars || true
  git commit -m "Set blue environment as active and remove green config" || echo "No changes to commit"
  git push -u origin blue
  echo "Created and pushed blue branch with active = true"
fi

# Create green branch
if git show-ref --verify --quiet refs/heads/green; then
  echo "green branch already exists"
else
  git checkout -b green
  # Ensure green.tfvars has active = false and remove blue.tfvars if it exists
  sed -i '' 's/active = true/active = false/' terraform/environments/green.tfvars || true
  rm -f terraform/environments/blue.tfvars
  git add terraform/environments/green.tfvars
  git add terraform/environments/blue.tfvars || true
  git commit -m "Set green environment as inactive and remove blue config" || echo "No changes to commit"
  git push -u origin green
  echo "Created and pushed green branch with active = false"
fi

# Switch back to main
git checkout main

echo "Branch initialization complete!"
echo "You can now work with environments by switching branches:"
echo "  git checkout blue  # Work on blue environment (active)"
echo "  git checkout green # Work on green environment (inactive)"
echo ""
echo "State is managed via the 'active' variable in each branch's tfvars file"
echo "Each branch contains only its own tfvars file"
