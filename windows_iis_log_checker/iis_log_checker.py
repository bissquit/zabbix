#=========================================================================
#         FILE: iis_log_checker.py
#
#        USAGE: iis_log_checker.py [ HTTP return code number ]
#		
#
#  DESCRIPTION: 
#
#        NOTES:
#       AUTHOR: E.S.Vasilyev - bq@bissquit.com; e.s.vasilyev@mail.ru
#      VERSION: 1.0.2
#      CREATED: 21.06.2018
#=========================================================================
import re
import os
from sys import argv
from pathlib import Path

script_name_stub, error_code = argv


def change_script_execution_location():
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    os.chdir(dname)


change_script_execution_location()

db_file_name = 'iis_log_checker_' + error_code + '.db'
directory = r'C:\inetpub\logs\LogFiles\W3SVC2'


def directory_path_in_correct_format(directory_path):
    return os.path.join(directory_path)


log_file_directory = directory_path_in_correct_format(directory)


def get_log_file_name(log_directory):
    return sorted(os.listdir(log_directory), reverse=True)


def get_full_file_path(directory_path, file_name):
    return directory_path + '\\' + file_name


def count_file_lines(file_name):
    i = 0
    with open(file_name, 'r') as f:
        for i, l in enumerate(f):
            pass
    return i


def define_search_pattern(input_error_code):
    case_input_error_code = {
        '200': '\s200\s',
        '400': '\s400\s',
        '401': '\s401\s',
        '402': '\s402\s',
        '403': '\s403\s',
        '404': '\s404\s'
    }
    return case_input_error_code[input_error_code]


def create_db_file_if_not_exist(file_name):
    # create file and fill with start data if file does not exist
    f = Path(file_name)
    if not f.is_file() or count_file_lines(file_name) < 1:
        log_file_names = get_log_file_name(log_file_directory)
        f = open(file_name, 'w+')
        f.write('log_file current_position\n')
        f.write(log_file_names[0] + ' 0\n')


def read_cell_from_db(db_file_name, column):
    # line_number and column starts from 0
    f = open(db_file_name, 'r')
    line = f.readlines()[1]
    current_position = re.split(r'\s', line)
    return current_position[column]


def replace_substring_in_file(db_file_name, replace_from, replace_to):
    # open file and read all old data
    f = open(db_file_name, 'r')
    f_data = f.read()
    f.close()
    # open file for write with flush current data
    f = open(db_file_name, 'w')
    f_data_lines = f_data.splitlines()

    string = f_data_lines[1]
    f_data_lines[1] = string.replace(replace_from, replace_to)

    n = ''
    for i in range(len(f_data_lines)):
        f.write(n + f_data_lines[i])
        i += 1
        n = '\n'
    f.close()


def count_certain_line_in_file(directory_path, file_name, start_line, total_line_in_file, search_pattern):

    file = get_full_file_path(directory_path, file_name)
    pattern_searchphrase = re.compile(search_pattern)

    # may be the better way is to use f.readlines()[n] for reading only needed line but not all at once.
    # but this approach will generate many small io requests (possible solution is to read a portion of data)
    # good ideas for future optimization for working with large log data
    with open(file, 'r') as f:
        n = 0
        file_data = f.read()
        file_data_lines = file_data.splitlines()
        for i in range(start_line, total_line_in_file):
            if pattern_searchphrase.search(file_data_lines[i]):
                n += 1
    return n


def main():

    create_db_file_if_not_exist(db_file_name)

    file_names_list = get_log_file_name(directory)
    current_log_file_name = read_cell_from_db(db_file_name, 0)
    file = get_full_file_path(directory, current_log_file_name)
    total_lines_in_file = count_file_lines(file)

    start_line = int(read_cell_from_db(db_file_name, 1))
    replace_from = start_line
    if start_line == 0:
        start_line = total_lines_in_file

    pattern_match = count_certain_line_in_file(directory,
                                               current_log_file_name,
                                               start_line,
                                               total_lines_in_file,
                                               define_search_pattern(error_code)
                                               )

    if current_log_file_name == file_names_list[0]:
        replace_substring_in_file(db_file_name, ' ' + str(replace_from), ' ' + str(total_lines_in_file))

    elif current_log_file_name == file_names_list[1]:
        file = get_full_file_path(directory, file_names_list[0])
        total_lines_in_file = count_file_lines(file)
        pattern_match += count_certain_line_in_file(directory,
                                                    file_names_list[0],
                                                    0,
                                                    total_lines_in_file,
                                                    define_search_pattern(error_code)
                                                    )

        replace_substring_in_file(db_file_name, current_log_file_name, file_names_list[0])
        replace_substring_in_file(db_file_name, ' ' + str(start_line), ' ' + str(total_lines_in_file))

    return pattern_match


print(main())
