#! /usr/bin/env bash
source ./config.sh
source ./utilities.sh

DATE_STRING=$(date +%F-%H-%M-%S-%N)
SYSTEM="${SYSTEM:=B2B}"
PARTITION="${PARTITION:=cn-b2b-15}"
SKIP_BUILD="${SKIP_BUILD=0}"
RESULTS_DIR=${RESULTS_TOP}/${DATE_STRING}
OPXRUNNER_SETUP_SCRIPT=${OPXRUNNER_SETUP_SCRIPTS["$PARTITION"]}

# Create a clean results directory
mkdir -p $RESULTS_DIR
rm -rf $RESULTS_DIR/*

log_info "Results will be placed in $RESULTS_DIR"
log_info "Using $PARTITION for testing"

if [[ $SKIP_BUILD -eq 0 ]]
then
    # Create debug build for testing
    log_info "Beginning builds......."
    build-opx gnu optimized ${BUILD_TOP}/${PARTITION}/libfabric-internal-development-builds/${LIBFABRIC_COMMIT}
else
    log_info "Skipping build for libfabric commit: $LIBFABRIC_COMMIT"
fi

# Initialize the environment for running opxrunner 
source $OPXRUNNER_SETUP_SCRIPT

export RFM_REPORT_FILE=$RESULTS_DIR/run-report-{sessionid}.json
export NUM_NODES=2
export NUM_RAILS=1
export PPN=12
export MPI_LIBRARY=intel-oneapi-mpi@2021.15.0.495
export RFM_SYSTEM="${SYSTEM}:${PARTITION}"
export LIBFABRIC_SOURCE=libfabric-internal/${LIBFABRIC_COMMIT}
export FI_OPX_CONTEXT_SHARING=true

############## IMB 
export RFM_OUTPUT_DIR=$RESULTS_DIR/imb-no-sharing/output
export RFM_STAGE_DIR=$RESULTS_DIR/imb-no-sharing/stage
export RFM_PERFLOG_DIR=$RESULTS_DIR/imb-no-sharing/perflogs
export FI_OPX_CONTEXT_SHARING=false
reframe --name='IMB_MPI1_Biband' --exec-policy=serial --run

export FI_OPX_CONTEXT_SHARING=true
export FI_OPX_ENDPOINTS_PER_HFI_CONTEXT=2,3,4
export RFM_OUTPUT_DIR=$RESULTS_DIR/imb-sharing/output
export RFM_STAGE_DIR=$RESULTS_DIR/imb-sharing/stage
export RFM_PERFLOG_DIR=$RESULTS_DIR/imb-sharing/perflogs
reframe --name='IMB_MPI1_Biband' --exec-policy=serial --run

# Process report files
./check-failures.py $RESULTS_DIR > $RESULTS_DIR/summary.txt

# plot results
python3 ./plot_results.py --output ${RESULTS_DIR}/resutls.xlsx ${RESULTS_DIR}/imb-no-sharing/perflogs/${SYSTEM}/${PARTITION}/IMB_MPI1_Biband.log ${RESULTS_DIR}/imb-sharing/perflogs/${SYSTEM}/${PARTITION}/IMB_MPI1_Biband.log