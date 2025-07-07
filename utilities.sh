#! /usr/bin/env bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Log functions
log_info() {
    date_string=$(date +%F-%H-%M-%S-%N)
    echo -e "${BLUE}[${date_string}][INFO]${RESET} $1"
}

log_success() {
    date_string=$(date +%F-%H-%M-%S-%N)
    echo -e "${GREEN}[${date_string}][SUCCESS]${RESET} $1"
}

log_warning() {
    date_string=$(date +%F-%H-%M-%S-%N)
    echo -e "${YELLOW}[${date_string}][WARNING]${RESET} $1"
}

log_error() {
    date_string=$(date +%F-%H-%M-%S-%N)
    echo -e "${RED}[${date_string}][ERROR]${RESET} $1"
}

die() {
    log_error "$1"; exit 1; 
}

build-opx() {
    local compiler=$1
    local type=$2
    local build_dir=$3
    shift 3
    local flags=$*

    # Change to libfabric source directory and checkout commit to build
    cd $LIBFABRIC_SRC || die "Failed to change to $LIBFABRIC_SRC"
    git fetch || die "Failed to fetch from $LIBFABRIC_SRC"
    git checkout $LIBFABRIC_COMMIT || die "Failed to checkout $LIBFABRIC_COMMIT"

    if [[ $type == "debug" ]]
    then
        export LIBFABRIC_DEBUG_INSTALL=$build_dir
    else
        export LIBFABRIC_OPTIMIZED_INSTALL=$build_dir
    fi

    # Create a clean build directory
    mkdir -p $build_dir
    rm -rf $build_dir/*

    $OPX_BUILD_SCRIPT -c $compiler -t $type $flags 2>&1 | tee -a $build_dir/build.log
    if [[ $? -ne 0 ]]
    then
        die "Failed $type build. Build directory: $build_dir"
    fi

    cp config.log $build_dir/

    log_success "Successfully built libfabric commit $LIBFABRIC_COMMIT and installed to $build_dir"
}