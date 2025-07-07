#! /usr/bin/env python3

import argparse
import glob
import os
import json

total_failures = 0
total_cases = 0
total_skipped = 0

parser = argparse.ArgumentParser()
parser.add_argument("filepath")
args = parser.parse_args()

files = glob.glob(f"{args.filepath}/*")
for file in files:
    if os.path.isfile(file) and file.endswith(".json"):
        # print(f"Processing {file}")
        with open(file, 'r') as fp:
            data = json.load(fp)
            total_failures = total_failures + data["session_info"]["num_failures"]
            total_cases = total_cases + data["session_info"]["num_cases"]
            total_skipped = total_skipped + data["session_info"]["num_skipped"]


print(f"Total cases = {total_cases}")
print(f"Total skipped = {total_skipped}")
print(f"Total failures = {total_failures}")