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