#! /usr/bin/env python3

import sys, os
import xlsxwriter
import argparse
import re
import pandas as pd
import ast

def read_perflogs(perflogs_file_path, parsed_data):
    first_line = True
    with open(perflogs_file_path, 'r') as fp:
        for line in fp.readlines():
            if first_line:
                first_line = False
            else:
                stripped_line = line.strip()
                m = LOG_ELEM_PATTERN.match(stripped_line)
                if m:
                    job_completion_time = m['job_completion_time']
                    rfm_test_name = m['rfm_test_name']
                    transport = m['transport']
                    num_nodes = m['num_nodes']
                    ppn = m['ppn']
                    num_tasks = m['num_tasks']
                    size = m['size']
                    perf_unit = m['perf_unit']
                    metric = m['metric']
                    value = m['value']
                    rfm_env_var = m['env_vars']

                    # print(f"job_completion_time = {job_completion_time}, size = {size}, perf_unit = {perf_unit}, value = {value} metric = {metric}")

                    parsed_data['job_completion_time'].append(job_completion_time)
                    parsed_data['rfm_test_name'].append(rfm_test_name)
                    parsed_data['transport'].append(transport)
                    parsed_data['num_nodes'].append(int(num_nodes))
                    parsed_data['ppn'].append(int(ppn))
                    parsed_data['num_tasks'].append(int(num_tasks))
                    parsed_data['size'].append(int(size))
                    parsed_data['perf_unit'].append(perf_unit)
                    parsed_data['metric'].append(metric)
                    parsed_data['value'].append(float(value))
                    parsed_data['rfm_env_vars'].append(rfm_env_var)

def group_job_data(df, metric):
    test_names = df['rfm_test_name'].value_counts()
    job_completion_times = df['job_completion_time'].value_counts()
    job_dfs = []
    for test_name, test_name_count in test_names.items():
        for job_time, job_time_count in job_completion_times.items():
            query_df = df[(df['job_completion_time'] == job_time) & (df['metric'] == metric) & (df['rfm_test_name'] == test_name)]
            if not query_df.empty:
                perf_unit = query_df['perf_unit'].iloc[0]
                env_vars = query_df['rfm_env_vars'].iloc[0]
                num_nodes = query_df['num_nodes'].iloc[0]
                transport = query_df['transport'].iloc[0]
                ppn = query_df['ppn'].iloc[0]
                mod_df = query_df.drop(columns=['job_completion_time', 'rfm_test_name', 'transport',  'num_nodes',  'ppn', 'num_tasks', 'perf_unit', 'metric', 'rfm_env_vars'])
                mod_df.set_index('size', inplace=True)
                job_dfs.append({'dataframe': mod_df, 'perf_unit': perf_unit, 'test_name': test_name, 'env_vars': env_vars, 'num_nodes': num_nodes, 'ppn': ppn, 'transport': transport, 'metric': metric})
            
    return job_dfs


def plot_job_data(workbook, job_data):
    final_df = None
    test_name = None
    perf_unit = None
    num_nodes = None
    ppn = None
    metric = None

    for job in job_data:
        if test_name is None:
            test_name = job['test_name'].split(" ")
        if perf_unit is None:
            perf_unit = job['perf_unit']
        if num_nodes is None:
            num_nodes = job['num_nodes']
        if ppn is None:
            ppn = job['ppn']
        if metric is None:
            metric = job['metric']

        env_vars = job['env_vars']
        actual_dict = ast.literal_eval(job['env_vars'])
        transport = job['transport']

        # Gather x-way context sharing
        sharing=0
        if 'FI_OPX_ENDPOINTS_PER_HFI_CONTEXT' in actual_dict:
            sharing=actual_dict['FI_OPX_ENDPOINTS_PER_HFI_CONTEXT']

        job_df = job['dataframe']
        new_df = job_df.rename(columns={"value": f"{transport}-{sharing}-way"})

        if final_df is None:
            final_df = pd.DataFrame(new_df)
        else:
            final_df = final_df.join(new_df)


    num_sizes = len(final_df.index)
    sheet_name = f"{test_name[0]} {metric}"
    worksheet = workbook.add_worksheet(sheet_name)

    # Write the message sizes to first column
    worksheet.write(0, 0, "Size")
    worksheet.write_column(1, 0, final_df.index)
    chart = workbook.add_chart({'type': 'column'})

    col = 1
    for col_label in final_df.columns:
        worksheet.write(0, col, col_label)
        worksheet.write_column(1, col, final_df[col_label])
        chart.add_series(
            {
                "categories": [sheet_name, 1, 0, 1 + num_sizes, 0],
                "values": [sheet_name, 1, col, 1 + num_sizes, col],
                "name": col_label,
            }
        )
        col = col + 1

    chart.set_title({"name": f"{test_name[0]} nodes={num_nodes} ppn={ppn}"})
    chart.set_x_axis({"name": "Size (bytes)"})
    chart.set_y_axis({"name": perf_unit})
    chart_sheet = workbook.add_chartsheet()
    chart_sheet.set_chart(chart)


parser = argparse.ArgumentParser()
parser.add_argument("input", nargs='+')
parser.add_argument("--output")
args = parser.parse_args()

LOG_ELEM_PATTERN=re.compile(r"^(?P<job_completion_time>\S+)\|rfm_system=(?P<rfm_system>\S+)\|rfm_partition=(?P<rfm_partition>\S+)\|rfm_test_name=(?P<rfm_test_name>.*)\|package=(?P<package>\S+)\|suite=(?P<suite>\S+)\|tags=(?P<tags>\S+)\|executable=(?P<executable>\S+)\|executable_opts=(?P<executable_opts>.*)\|libfabric_source=(?P<libfabric_source>\S+)\|libfabric_version=(?P<libfabric_version>\S+)\|mpi_library_name=(?P<mpi_library_name>\S+)\|mpi_library_version=(?P<mpi_library_version>\S+)\|compiler_name=(?P<compiler_name>\S+)\|compiler_version=(?P<compiler_version>\S+)\|transport=(?P<transport>\S+)\|mtl=(?P<mtl>\S+)\|num_nodes=(?P<num_nodes>\S+)\|ppn=(?P<ppn>\S+)\|num_tasks=(?P<num_tasks>\S+)\|rails=(?P<rails>\S+)\|rfm_env_vars=(?P<env_vars>.*)\|output_dir=(?P<outputdir>\S+)\|maintainers=(?P<maintainers>\S+)\|rfm_run_user=(?P<rfm_run_user>\S+)\|rfm_run_group=(?P<rfm_run_group>.*)\|osu_buffer_types=(?P<osu_buffer_types>.*)\|gpu_library_name=(?P<gpu_library_name>.*)\|gpu_library_version=(?P<gpu_library_version>.*)\|gpu_arch=(?P<gpu_arch>.*)\|node_list=(?P<node_list>\S+)\|(?P<perf_unit>\S+)\|size=(?P<size>\S+)\|metric=(?P<metric>.*)\|value=(?P<value>\S+).*$")

data_set = {
    'job_completion_time': [],
    'rfm_test_name': [],
    'transport': [],
    'num_nodes': [],
    'ppn': [], 
    'num_tasks': [], 
    'size': [],
    'perf_unit': [],
    'metric': [],
    'value': [],
    'rfm_env_vars': [],
}


for filepath in args.input:
    read_perflogs(filepath, data_set)

output_path = "results.xlsx"
if args.output:
    output_path = args.output

# Create a workbook and add a worksheet.
workbook = xlsxwriter.Workbook(output_path)

df = pd.DataFrame(data_set)
throughput_tests = group_job_data(df, 'Throughput')
plot_job_data(workbook, throughput_tests)

message_rate_tests = group_job_data(df, 'Message Rate')
plot_job_data(workbook, message_rate_tests)

workbook.close()