#!/bin/bash

formatter_cmd="flutter format"
formatter_args=""

# Grab root directory to help with creating an absolute path for changed files.
root_dir="$(git rev-parse --show-toplevel)"
[ -d "${root_dir}" ] || exit 1

# To avoid any unexpected behavior, we need to "stash" any unstaged changes.
# We could use "git stash" but the situation gets complicated because we
# need to make additional changes with the formatter.
# Here's how we could do this if we didn't need to make additional changes:
#   http://stackoverflow.com/a/20480591
# But since we do, we follow the same general pattern as the "pre-commit" lib:
#   https://github.com/pre-commit/pre-commit/blob/master/pre_commit/staged_files_only.py#L15
# Basically we just diff the unstaged changes, store the patch, and apply it later.
# In the future, we should consider migrating to using that library.
staged_changes_diff=$(mktemp -t format_patch_XXXXXXXXXX)
git diff --ignore-submodules --binary --exit-code --no-color > $staged_changes_diff
if [ $? -eq 1 ]; then 
    echo "Found unstaged changes, storing in ${staged_changes_diff}"
    echo "Clearing unstaged changes for formatting, will restore after formatting."
    git checkout -- ${root_dir}
    stored_staged_changes=true
else
    stored_staged_changes=false
fi

# filter=ACMR shows only added, changed, modified, or renamed files.
# Get only java files and prepend the root directory to make the paths absolute.
changed_dart_files=($(git diff --cached --name-only --diff-filter=ACMR \
    | grep ".*dart$" \
    | sed "s:^:${root_dir}/:"))

# If we have changed java files, format them!
if [ ${#changed_dart_files[@]} -gt 0 ]; then
    # Do the formatting, stage the changes, and print out which files were changed.
    eval ${formatter_cmd} ${formatter_args} "${changed_dart_files[@]}"
    git add "${changed_dart_files[@]}"
    echo "${changed_dart_files[@]}" | xargs basename | sed "s/^/        Formatting: /"
fi

echo "Finished formatting."

if $stored_staged_changes ; then
    echo "Restoring unstaged changes"
    git apply "${staged_changes_diff}"

    if [ $? -eq 1 ]; then
        echo "Shoot! We failed to re-apply your unstaged changes."
        echo "The patch for these changes is preserved at ${staged_changes_diff}"
    fi
fi


flutter format .
