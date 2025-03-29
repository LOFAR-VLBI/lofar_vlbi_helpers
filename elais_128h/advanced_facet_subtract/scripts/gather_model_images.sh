#!/bin/bash

# Ensure a model image folder is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <model_image_folder>"
    exit 1
fi

MODEL_IMAGE_FOLDER=$1

# Patterns to check with model images
PATTERNS=(
    "*-model-fpb.fits"
    "*-model-pb.fits"
    "*-model.fits"
)

# Function to copy files if more than one match exists
copy_files() {
    local pattern="$1"
    local files=()

    # Filter files matching the pattern but excluding those with "MFS"
    for file in "$MODEL_IMAGE_FOLDER"/$pattern; do
        [[ "$file" == *"MFS"* ]] && continue  # Skip files with "MFS"
        files+=("$file")
    done

    mkdir -p output_images

    if [ "${#files[@]}" -gt 1 ]; then
        cp "${files[@]}" output_images/
        return 0
    fi
    return 1  # No valid files were copied
}

# Iterate through patterns and copy the first match
for pattern in "${PATTERNS[@]}"; do
    copy_files "$pattern" && exit 0
done

# If no files were copied, exit with error
echo "ERROR: missing model images in folder $MODEL_IMAGE_FOLDER"
exit 1
