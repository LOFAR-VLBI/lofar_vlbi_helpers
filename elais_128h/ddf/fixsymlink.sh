#!/bin/bash

# Define the old and new base paths
old_base="/tmp/ddf"
re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

# Loop over all symlinks in the current directory
for symlink in SOLSDIR/L*.ms/*.npz; do
    if [ -L "$symlink" ]; then
        target=$(readlink "$symlink")
        if [[ "$target" == $old_base* ]]; then
            LNUM=$OBSERVATION
            new_base="/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/${LNUM}/ddf/"
            new_target="${target/$old_base/$new_base}"
            echo "Updating symlink: $symlink"
            rm "$symlink"
            ln -s "$new_target" "$symlink"
            echo "Symlink updated: $symlink -> $new_target"
        fi
    else
        echo "Skipping $symlink: Not a valid symlink"
    fi
done

