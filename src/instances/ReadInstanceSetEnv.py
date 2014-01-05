from os.path import sep
import csv
import os
import os.path
import sys
import shutil
import sys


def walk_instances(setenv_file, instance_name):
	csvFile = open(setenv_file, "rb")
	reader = csv.reader(csvFile)

	first = True
	found = False
	for row in reader:
		if first:
			first = False
			header = row
			continue
		
		found = False
		for i in range(len(row)):
			#print(i, len(row), found)
			if i == 0 and row[0] == instance_name:
				found = True		
			elif i > 0 and found:
				if row[i] is not None and row[i] != "" and not row[i].startswith("#"):
					print(header[i] + "=\"" + row[i] + "\"")
				#print('x',i, len(row), found)
				if (i == len(row) - 1):
					#print("exiting")
					exit(0)
			elif not found:
				break

	if not found:
		sys.stderr.write(instance_name + " missing in " + setenv_file)
		exit(42)


if __name__ == '__main__':
	#print dirname(sys.argv[0])
	args = sys.argv[1:]
	if len(args) == 2:
		walk_instances(args[0], args[1])
	else:
		sys.stderr.write("2 arguments required: setenv CSV file, instance name; this script must be present in 'instances' directory of TCC")
		exit(42)
