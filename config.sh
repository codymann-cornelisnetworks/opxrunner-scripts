export OPX_BUILD_SCRIPT="${OPX_BUILD_SCRIPT:=/home/cmann/code/libfabric-devel/build-scripts/build.sh}"
export LIBFABRIC_COMMIT="${LIBFABRIC_COMMIT:=}"
export LIBFABRIC_SRC="${LIBFABRIC_SRC:=/home/cmann/libfabric-internal-build-repo}"
export BUILD_TOP="${BUILD_TOP:=/home/cmann/builds}"
export OPXR_MIDDLEWARE_TOP_DIR=/home/cmann/builds


# OPXRUNNER builds
declare -A OPXRUNNER_SETUP_SCRIPTS=(
    ["cn-b2b-15"]="/home/cmann/code/opxrunner/build/setup-env.sh"
    ["OPX-JKR-GEN-MYR-2"]="/home/cmann/code/opxrunner/build/setup-env.sh"
)

export RESULTS_TOP="${RESULTS_TOP:=/home/cmann/test-results}"