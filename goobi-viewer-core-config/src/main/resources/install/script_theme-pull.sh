#!/bin/bash
#
#
# This script attempts to call "git pull" on a path given as the first parameter
#
# The script expects one parameter: the path to the git repository of the theme
#
# The script should return one of two return values:
#
# 0 - if the repository was successfully pulled or if no changes where detected. In the latter case, the script should write "Git repository is already up to date." to the output stream
# 1 - if an error occured. In this case an error description should be passed to the error output stream
#

# Check if the repository path parameter is provided
if [ -z "$1" ]; then
    echo "Error: Repository path not provided." >&2
    exit 1
fi

repository_path="$1"

# Check if the repository path is non-empty and points to an existing directory
if [ -z "$repository_path" ] || [ ! -d "$repository_path" ]; then
    echo "Error: Invalid repository path or directory does not exist." >&2
    exit 1
fi

pull_output=$(git -C "$repository_path" pull);

# Check if the output indicates that everything is up-to-date
if [[ $pull_output == *"Already up to date."* ]]; then
    # Return 1 to indicate no changes
    echo "Git repository is already up to date."
    exit 0
elif [ $? -eq 0 ]; then
    # Exit status 0 indicates success (changes were pulled)
    echo "Git pull successful: Changes pulled"
    exit 0
else
    # exit status 2 indicates an error (e.g., conflicts or network issues)
    echo "Error: Git pull failed."
    echo "$pull_output" >&2
    exit 1
fi

