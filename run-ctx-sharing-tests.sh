#! /usr/bin/env bash
source ./config.sh
source ./utilities.sh

DATE_STRING=$(date +%F-%H-%M-%S-%N)
SYSTEM="${SYSTEM:=B2B}"
PARTITION="${PARTITION:=cn-b2b-15}"
RESULTS_DIR=${RESULTS_TOP}/${DATE_STRING}
OPXRUNNER_SETUP_SCRIPT=${OPXRUNNER_SETUP_SCRIPTS["$PARTITION"]}
export OPERATING_SYSTEM="${OPERATING_SYSTEM:=}"

# Create a clean results directory
mkdir -p $RESULTS_DIR
rm -rf $RESULTS_DIR/*

log_info "Results will be placed in $RESULTS_DIR"
log_info "Using ${SYSTEM}:${PARTITION} for testing"

# Initialize the environment for running opxrunner 
source $OPXRUNNER_SETUP_SCRIPT

# OPX environment runtime environment variables

# OPXRunner environment variables
export OPXR_NUM_NODES=2
export OPXR_PPN=1
export OPXR_MPI_LIBRARY=mpich@custom
export OPXR_LIBFABRIC_SOURCE=libfabric-internal/${LIBFABRIC_COMMIT}

# Reframe specific environment variables
export RFM_SYSTEM="${SYSTEM}:${PARTITION}"
export RFM_OUTPUT_DIR=$RESULTS_DIR/imb-dv/output
export RFM_STAGE_DIR=$RESULTS_DIR/imb-dv/stage
export RFM_PERFLOG_DIR=$RESULTS_DIR/imb-dv/perflogs
export RFM_REPORT_FILE=$RESULTS_DIR/run-report-{sessionid}.json
reframe --name 'OPX_Alignment' --exec-policy=serial --run

# Process report files
python3 ./check-failures.py $RESULTS_DIR > $RESULTS_DIR/summary.txt
