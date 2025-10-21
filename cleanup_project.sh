#!/bin/bash

# This script cleans up the project directory by removing unnecessary files and directories

echo "Cleaning up project directory..."

# Define directories to remove
DIRS_TO_REMOVE=(
    "/Users/markkelly/Personal Projects/New Game"
    "/Users/markkelly/Personal Projects/SkyHopperNew"
)

# Define script files to remove (in the current project)
SCRIPTS_TO_REMOVE=(
    "/Users/markkelly/Personal Projects/SkyHopper Final/SkyHopper/add_audio_to_project.sh"
    "/Users/markkelly/Personal Projects/SkyHopper Final/SkyHopper/fix_audio_directories.sh"
    "/Users/markkelly/Personal Projects/SkyHopper Final/SkyHopper/remove_duplicate_audio.sh"
    "/Users/markkelly/Personal Projects/SkyHopper Final/SkyHopper/copy_audio_to_root.sh"
    "/Users/markkelly/Personal Projects/SkyHopper Final/SkyHopper/cleanup_audio_files.sh"
)

# Ask for confirmation before proceeding
echo "The following directories will be removed:"
for dir in "${DIRS_TO_REMOVE[@]}"; do
    echo "  - $dir"
done

echo ""
echo "The following script files will be removed:"
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    echo "  - $script"
done

echo ""
read -p "Do you want to proceed? (y/n): " confirm

if [[ $confirm != [yY] ]]; then
    echo "Cleanup canceled."
    exit 0
fi

# Remove directories
for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        echo "Removing directory: $dir"
        rm -rf "$dir"
    else
        echo "Directory not found: $dir"
    fi
done

# Remove script files
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    if [ -f "$script" ]; then
        echo "Removing script: $script"
        rm -f "$script"
    else
        echo "Script not found: $script"
    fi
done

echo ""
echo "Cleanup complete!"
echo "The project directory has been cleaned up."
