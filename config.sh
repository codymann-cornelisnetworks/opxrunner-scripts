export LIBFABRIC_COMMIT="${LIBFABRIC_COMMIT:=}"
export BUILD_TOP="${BUILD_TOP:=/home/cmann/builds}"
export OPXR_MIDDLEWARE_TOP_DIR=${BUILD_TOP}
export RESULTS_TOP="${RESULTS_TOP:=/home/cmann/test-results}"

# OPXRUNNER builds
declare -A OPXRUNNER_SETUP_SCRIPTS=(
    ["cn-b2b-15"]="/home/cmann/code/opxrunner-builds/opxrunner-b2b-rhel9.5/build/setup-env.sh"
    ["OPX-JKR-GEN-MYR-2"]="/home/cmann/code/opxrunner/build/setup-env.sh"
    ["emr6548Y-CN5K"]="/home/cmann/code/opxrunner-builds/opxrunner-dtc-rhel8.8/build/setup-env.sh"
    ["bdx2699_2r"]="/home/cmann/code/opxrunner-builds/opxrunner-ptc-rhel9.2/build/setup-env.sh"
)