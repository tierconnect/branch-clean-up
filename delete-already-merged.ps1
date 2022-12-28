# Read the contents of the branch ignore file into a variable
$ignore_list = Get-Content -Path branch_ignore.txt

# List all remote branches that do not contain "canary" or "dev" in their names
$branches = git branch -r | Select-String -Pattern '^.*(canary|dev).*$' -NotMatch
# Trim the matched strings
$trimmed_branches = @()
foreach ($branch in $branches) {
  $trimmed_branches += $branch.Line.Trim()
}
# Get the commit hash of the latest active branch
$latest_active_branch = git rev-parse --abbrev-ref HEAD

$branches_merged_to_latest_active_branch = git for-each-ref --merged=$latest_active_branch refs/remotes/

$branches_to_check = @()

foreach ($branch in $branches_merged_to_latest_active_branch) {
  $result = $branch -split "refs/remotes/" | Select-Object -Index 1
  $branches_to_check += $result
}

# Compare the commit history of each branch with the latest active branch
# and add the branches to a list if they have no new commits and are not in the ignore list
$branches_to_review = @()
foreach ($branch in $trimmed_branches) {
  if (!($ignore_list -contains $branch) -and ($branches_to_check -contains $branch)) {
    $branches_to_review += $branch
  }
}

# Check if the -delete flag is present in the script arguments
if ($args -contains "-delete") {
  # Delete the branches (make sure to review the list and backup your repository before running this)
  foreach ($branch in $branches_to_review) {
    git push origin --delete $branch
  }
}
else {
  # Add the branches to a shared spreadsheet (you will need to modify this to fit your specific spreadsheet setup)
  $branches_to_review | Out-File branches_to_review.txt -Encoding utf8 -Append
}
