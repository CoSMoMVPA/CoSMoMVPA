#!/usr/bin/env python
# converts matlab to rst files
#
# This code reads all matlab .m files and then generates three versions:
# 1) the full file, but with lines '% >>' and '<<' removed
# 2) the file with code in between '% >>' and '<<' replaced by
#    a comment saying 'your code here' (postfix '_skl' for skeleton)
# 3) the file with only the header (first line plus all lines up to
#    the first line without comment (postfix '_hdr' for header)
# It also generates seperate toc files for each version
# 
# NNO Aug 2013
#
#



import os
import glob
from os.path import join, split, getmtime, isfile
matlab_dir='../mvpa'
example_dir='../examples'
trg_dir='source'
rst_sub_dir='matlab'
modindex_dir=trg_dir

for d in (trg_dir, join(trg_dir, rst_sub_dir), modindex_dir):
    if not os.path.isdir(d):
        os.makedirs(d)

add_indent=lambda x:' '*4+x

def matlab2rst(data, output=None):
    '''where output in ('hdr','sgn','skl',None)
    hdr: header excluding a link at the top (to allow .. include)
    skl: skeleton
    None: full
    (note: 'sgn' was once present but removed)'''

    lines=data.split('\n')
    after_header=False
    in_skeleton=False

    res=[]
    for i, line in enumerate(lines):
        if in_skeleton and '% <@@<' in line.strip():
            in_skeleton=False
            continue

        if not in_skeleton and '% >@@>' in line.strip():
            if output=='skl':
                res.append(line.replace('% >@@>','%%%% >>> Your code here <<< %%%%'))
            in_skeleton=True
            continue

        if not after_header:
            if not ((i==0 and 'function' in line) or line.startswith('%')):
                after_header=True

        add_line=(output is None) or \
                 (output=='skl' and not in_skeleton)  or \
                 (output in ('hdr','sgn') and not after_header)

        if add_line:
            res.append(line)

    if in_skeleton:
        raise ValueError('%s\n\n: no end of skeleton', data)

    header=['.. code-block:: matlab','']
    return '\n'.join(header + map(add_indent, res))


fns=sum([glob.glob(join(d,'*.m')) for d in [matlab_dir, example_dir]],[])
fns.sort()

# define filters + file name infix for toc
filters={'run': lambda x: x.startswith('run'),
         None: lambda x: x.startswith('cosmo'),
         'pb':lambda x: x.startswith('run')}

pf='Runnable examples - '
output2name={('skl','run'):pf + 'skeleton files',
             (None,'run'):pf + 'full solution files',
             (None,None): 'Module index',
             ('hdr',None): 'header files',
             ('skl',None): 'skeleton files',
             ('sgn',None): 'signature files',
             ('None','pb'): 'Matlab outputs'}

def is_newer(fn, other_fn):
    return not isfile(other_fn) or getmtime(fn)>getmtime(other_fn) 
    # return True if fn is newer than other_fn
    # and other_fn exists
    return 

for output in ('hdr','skl',None,'sgn'):
    print '@#$====> Converting matlab_%s.m files to *_%s.rst' % (output,output)
    labels=[]
    for fn in fns:
        if split(fn)[-1].startswith('run') and output=='hdr':
            continue
        with open(fn) as f:
            data=f.read()

        rst=matlab2rst(data, output=output)
        p,fn_short=split(fn)
        fn_short=fn_short[:-2] # get rid of '.m' extension
        label=fn_short # how we call it in .rst world

        if not output is None:
            label+='_'+output # add suffix

        fn_out=join(trg_dir, rst_sub_dir, label)

        #fn_out+='.rst'
        fn_out+='.txt' if output=='sgn' else '.rst'

        if is_newer(fn, fn_out):
            with open(fn_out,'w') as f:

                f.write('.. _%s:\n\n' % label)
                if output!='sgn':
                    f.write('%s\n%s\n\n' % (label.replace('_',' '),'-'*len(label)))
                f.write(rst)
                #print ">>>", rst, "<<<"
                #print '%s -> %s' % (fn_short, fn_out)

        labels.append(label) # keep track of all rst files


    for infix, filter_ in filters.iteritems():
        if not (output,infix) in output2name:
            continue

        if output=='sgn':
            continue

        toc_fn='modindex%s' % ('' if output is None else ('_' + output))
        fn=toc_fn
        if not infix is None:
            fn+='_'+infix

        headername=output2name.get((output, infix),None)
        if headername is None:
            continue

        header='%s' % headername
        header=['.. _`%s`: ' % fn, '', header, '='*len(header),'',
                'Contents:', '',
                '.. toctree::','    :maxdepth: 2','','']

        appendix=['','',
                  'Indices and tables',
                  '^^^^^^^^^^^^^^^^^^',
                  '',
                  '* :ref:`genindex`',
                  '* :ref:`modindex`',
                  '* :ref:`search`']
   
        full_toc_fn=join(modindex_dir,fn+'.rst')
        with open(full_toc_fn,'w') as f:
            f.write('\n'.join(header))
            for label in filter(filter_,labels):
                f.write(add_indent(rst_sub_dir+'/'+label) + '\n')
            f.write('\n'.join(appendix))
            print "Written toc to %s" % full_toc_fn

