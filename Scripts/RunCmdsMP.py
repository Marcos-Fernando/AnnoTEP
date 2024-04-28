#!/bin/env python
#coding utf-8
'''RUN system CoMmanDS in Multi-Processing'''
import sys
import os
import subprocess
import pp
from optparse import OptionParser

__version__ = '1.0'
def file2list(cmd_file, sep="\n"):
	if not os.path.exists(cmd_file) or not os.path.getsize(cmd_file):
		cmd_list = []
	else:
		f = open(cmd_file, 'r')
		cmd_list = f.read().split(sep)
	return [cmd for cmd in cmd_list if cmd]

#otimizado com log
def run_cmd(cmd, log=True):
    job = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output = job.communicate()
    status = job.poll()
    if log:
        return output + (status, cmd)
    else:
        return output + (status,)

#Otimizado
def submit_pp(cmd_file, processors=1, cmd_sep="\n", cont=True):
    if not '\n' in cmd_sep:
        cmd_sep += '\n'
    if not os.path.exists(cmd_file):
        raise IOError(f'Commands file {cmd_file} does NOT exist.')

    cmd_cpd_file = cmd_file + '.completed'
    cmd_list = file2list(cmd_file, cmd_sep)
    cmd_cpd_list = file2list(cmd_cpd_file, cmd_sep)
    if cont:
        cmd_uncpd_list = sorted(list(set(cmd_list) - set(cmd_cpd_list)), key=cmd_list.index)
    else:
        cmd_uncpd_list = sorted(list(set(cmd_list)), key=cmd_list.index)
        cmd_cpd_list = []

    print(f'total commands:\t{len(cmd_list)}\n'
          f'skipped commands:\t{len(cmd_list) - len(cmd_uncpd_list)}\n'
          f'retained commands:\t{len(cmd_uncpd_list)}\n')

    # start pp
    ppservers = ()
    job_server = pp.Server(processors, ppservers=ppservers)
    jobs = [(cmd, job_server.submit(run_cmd, (cmd,), (), ('subprocess',))) for cmd in cmd_uncpd_list]

    # recover stdout, stderr and exit status
    output_files = {
        'out': cmd_file + '.out',
        'err': cmd_file + '.err',
        'warning': cmd_file + '.warning'
    }

    with open(cmd_cpd_file, 'a') as f, \
         open(output_files['out'], 'a') as f_out, \
         open(output_files['err'], 'a') as f_err, \
         open(output_files['warning'], 'a') as f_warn:
        
        for i, (cmd, job) in enumerate(jobs, start=1):
            f.write(cmd + cmd_sep)
            out, err, status = job()
            f_out.write(f'CMD_{i}_STDOUT:\n{out}{cmd_sep}')
            f_err.write(f'CMD_{i}_STDERR:\n{err}{cmd_sep}')
            if not status == 0:
                f_warn.write(cmd + cmd_sep)

    job_server.print_stats()

def main():
	usage = __doc__ + "\npython %prog [options] <commands.list>"
	parser = OptionParser(usage, version="%prog " + __version__)
	parser.add_option("-p","--processors", action="store",type="int",\
					dest="processors", default=2, \
					help="number of processors [default=%default]")
	parser.add_option("-s","--separation", action="store", type="string",\
					dest="separation", default='\n', \
					help='separation between two commands [default="\\n"]')
	parser.add_option("-c","--continue", action="store", type="int",\
					dest="to_be_continue", default=1, \
					help="continue [1] or not [0] [default=%default]")
	(options,args)=parser.parse_args()
	if not args:
		parser.print_help()
		sys.exit()
	cmd_file = args[0]
	processors = options.processors
	separation = options.separation
	to_be_continue = options.to_be_continue
	submit_pp(cmd_file, processors=processors, \
				cmd_sep=separation, cont=to_be_continue)

if __name__ == '__main__':
	main()
