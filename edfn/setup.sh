#!/bin/bash

# UPDATE THESE HERE OR ADD TO ~/.bashrc
export SOFTWAREDIR="/project/lofarvwf/Software"
export SING_BIND="/project/lofarvwf/"
export MASTERDIR="/project/lofarvwf/Share/jdejong/output/EUCLID/edfn"
SINGULARITY=https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v6.0.0_znver2_znver2.sif

# OPTIONS
DO_GIT=1
DO_SINGULARITY=1


while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-git)
            DO_GIT=0
            shift
            ;;
        --no-sing)
            DO_SINGULARITY=0
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--no-git] [--no-sing]"
            echo
            echo "  --no-git    Skip git clone/pull of repositories"
            echo "  --no-sing   Skip downloading/copying the Singularity image"
            return 0 2>/dev/null || exit 0
            ;;
        *)
            echo "Unknown option: $1"
            return 1 2>/dev/null || exit 1
            ;;
    esac
done

# DOWNLOAD SOFTWARE
STARTDIR=$PWD
cd $SOFTWAREDIR
if [[ "$DO_GIT" -eq 1 ]]; then
    echo ">>> Cloning/updating git repos..."
    repos=(
        "lofar_stager_api|https://git.astron.nl/astron-sdc/lofar_stager_api"
        "flocs-lta|https://github.com/FLOCSoft/flocs-lta"
        "lotss-hba-survey|https://github.com/LOFAR-VLBI/lotss-hba-survey"
        "lofar_facet_selfcal|https://github.com/rvweeren/lofar_facet_selfcal"
        "lofar_helpers|https://github.com/jurjen93/lofar_helpers"
        "pilot|https://github.com/LOFAR-VLBI/pilot"
        "flocs_runners|https://github.com/FLOCSoft/flocs-runners"
        "LINC|https://git.astron.nl/RD/LINC"
    )

    for entry in "${repos[@]}"; do
        name="${entry%%|*}"
        url="${entry##*|}"

        if [ -d "$name" ]; then
            (
                echo "Updating $name..."
                cd "$name" && git pull
            )
        else
            echo "Cloning $name..."
            git clone "$url"
        fi
    done
else
    echo ">>> Skipping git clone/pull (per --no-git)."
fi

SIMG_CACHE_DIR=$SOFTWAREDIR/singularity_cache
SIMG=vlbi-cwl.sif

if [[ $DO_SINGULARITY -eq 1 ]]; then
    echo ">>> Handling Singularity image..."

    # DOWNLOAD SINGULARITY
    mkdir -p $SIMG_CACHE_DIR/pull

    # Download singularity only if not already present in cache
    if [ -f $SIMG_CACHE_DIR/$SIMG ]; then
        echo "$SIMG already exists in cache, skipping download."
    else
        echo "Downloading $SIMG..."
        wget $SINGULARITY -O $SIMG_CACHE_DIR/$SIMG
    fi

    # Copy singularity into pull directory only if missing
    if [ -f $SIMG_CACHE_DIR/pull/$SIMG ]; then
        echo "$SIMG already exists in pull directory, skipping copy."
    else
        echo "Copying $SIMG into pull directory..."
        cp $SIMG_CACHE_DIR/$SIMG" "$SIMG_CACHE_DIR/pull/$SIMG
    fi
else
    echo ">>> Skipping Singularity download/copy (per --no-sing)."
fi

# SETUP VARIABLES
export APPTAINERENV_PYTHONPATH=$PWD/lofar_stager_api:$PWD/lotss-hba-survey:\$PYTHONPATH
export APPTAINER_BIND=$SING_BIND
export SING_IMG=$SIMG_CACHE_DIR/$SIMG
export CWL_SINGULARITY_CACHE=$SIMG_CACHE_DIR
export LINC_DATA_ROOT=$(realpath LINC)
export VLBI_DATA_ROOT=$(realpath pilot)
export TOIL_CHECK_ENV=True

cd $STARTDIR
