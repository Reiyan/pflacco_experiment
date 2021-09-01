import os

path = './templates/job_template.cmd'
out_path = './jobs/'

if not os.path.exists(out_path):
  os.makedirs(out_path)

fids = [x for x in range(1, 25)]
dims = [5]
iids = [1]

def _create_job_files():
    with open(path, 'r') as input_:
        exp_file = str(input_.read())
        for f in fids:
            for d in dims:
                for iid in iids:
                    suffix = 'f%s_d%s_i%s' %(str(f), str(d), str(iid))
                    output = exp_file.replace('PLACEHOLDER_JOB_NAME', 'rpr_' + suffix)\
                                     .replace('PLACEHOLDER_ARGS', '%s %s %s' % (str(f), str(d), str(iid)))
                    with open(os.path.join(out_path,suffix + '.cmd'), 'w') as out:
                        out.write(output)

def _submit_jobs():
    for f in fids:
        for d in dims:
            for iid in iids:
                suffix = 'f%s_d%s_i%s' % (str(f), str(d), str(iid))
                f_name = suffix + '.cmd'
                print(os.system('sbatch ' + os.path.join(out_path, f_name)))

if __name__ == '__main__':
    _create_job_files()
    _submit_jobs()
    