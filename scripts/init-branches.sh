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
  # Create blue-specific config.tfvars
  cat > terraform/environments/config.tfvars << EOF
environment_name = "blue"
resource_prefix = "blue"
aws_region = "us-east-1"
event_source_mapping_enabled = true
active = true
EOF
  git add terraform/environments/config.tfvars
  git commit -m "Initialize blue branch with config.tfvars" || echo "No changes to commit"
  git push -u origin blue
  echo "Created and pushed blue branch with blue config"
fi

# Create green branch
if git show-ref --verify --quiet refs/heads/green; then
  echo "green branch already exists"
else
  git checkout -b green
  # Create green-specific config.tfvars
  cat > terraform/environments/config.tfvars << EOF
environment_name = "green"
resource_prefix = "green"
aws_region = "us-east-1"
event_source_mapping_enabled = true
active = false
EOF
  git add terraform/environments/config.tfvars
  git commit -m "Initialize green branch with config.tfvars" || echo "No changes to commit"
  git push -u origin green
  echo "Created and pushed green branch with green config"
fi

# Switch back to main
git checkout main

echo "Branch initialization complete!"
echo "You can now work with environments by switching branches:"
echo "  git checkout blue  # Work on blue environment (active)"
echo "  git checkout green # Work on green environment (inactive)"
echo ""
echo "Each branch has its own config.tfvars file with environment-specific values"
