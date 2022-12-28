# Read the contents of the branch ignore file into a variable
ignore_list=$(cat branch_ignore.txt)

# List all remote branches that do not contain "canary" or "dev" in their names
branches=$(git branch -r | grep -vE '(canary|dev)')

# Trim the matched strings
trimmed_branches=()
while read -r branch; do
  trimmed_branches+=("$(echo "$branch" | xargs)")
done <<< "$branches"

# Get the commit hash of the latest active branch
latest_active_branch=$(git rev-parse --abbrev-ref HEAD)

branches_merged_to_latest_active_branch=$(git for-each-ref --merged="$latest_active_branch" refs/remotes/)

# Create an empty array to store the branches to check
branches_to_check=()

# Split the branches merged to the latest active branch by "refs/remotes/" and store the second part
while read -r branch; do
  result=$(echo "$branch" | cut -d '/' -f 3-)
  branches_to_check+=("$result")
done <<< "$branches_merged_to_latest_active_branch"

# Create an empty array to store the branches to review
branches_to_review=()

# Compare the commit history of each branch with the latest active branch
# and add the branches to a list if they have no new commits and are not in the ignore list
for branch in "${trimmed_branches[@]}"; do
  if [[ ! "$ignore_list" =~ "$branch" ]] && [[ "${branches_to_check[@]}" =~ "$branch" ]]; then
    branches_to_review+=("$branch")
  fi
done

# Check if the -delete flag is present in the script arguments
if [[ "$@" =~ "-delete" ]]; then
  # Delete the branches (make sure to review the list and backup your repository before running this)
  for branch in "${branches_to_review[@]}"; do
    git push origin --delete "$branch"
  done
else
  # Add the branches to a shared spreadsheet (you will need to modify this to fit your specific spreadsheet setup)
  printf "%s\n" "${branches_to_review[@]}" > branches_to_review.txt
fi
