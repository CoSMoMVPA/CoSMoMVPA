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
from os.path import join, split
matlab_dir='../mvpa'
example_dir='../examples'
rst_dir='source'

add_indent=lambda x:' '*4+x

def matlab2rst(data, output=None):
    '''where output in ('hdr','skl',None), None means full'''

    lines=data.split('\n')
    after_header=False
    in_skeleton=False

    res=[]
    for i, line in enumerate(lines):
        if in_skeleton and '% <<' in line.strip():
            in_skeleton=False
            continue

        if not in_skeleton and '% >>' in line.strip():
            if output=='skl':
                res.append(line.replace('% >>','%%%% >>> Your code here <<< %%%%'))
            in_skeleton=True
            continue

        if not after_header:
            if not ((i==0 and 'function' in line) or line.startswith('%')):
                after_header=True

        add_line=(output is None) or \
                 (output=='skl' and not in_skeleton)  or \
                 (output=='hdr' and not after_header)

        if add_line:
            res.append(line)

    if in_skeleton:
        raise ValueError('%s\n\n: no end of skeleton', data)

    header=['.. code-block:: matlab','']
    return '\n'.join(header + map(add_indent, res))


fns=sum([glob.glob(join(d,'*.m')) for d in [matlab_dir, example_dir]],[])
fns.sort()

for output in ('hdr','skl',None):
    print '@#$====> Converting matlab_%s.m files to *_%s.rst' % (output,output)
    labels=[]
    for fn in fns:
        with open(fn) as f:
            data=f.read()

        rst=matlab2rst(data, output=output)
        p,fn_short=split(fn)
        fn_short=fn_short[:-2] # get rid of '.m' extension
        label=fn_short # how we call it in .rst world

        if not output is None:
            label+='_'+output # add suffix

        fn_out=join(rst_dir, label)
        fn_out+='.rst'

        with open(fn_out,'w') as f:
            f.write('.. %s\n\n' % label)
            f.write('%s\n%s\n' % (label.replace('_',' '),'-'*len(label)))
            f.write(rst)
            #print ">>>", rst, "<<<"
            #print '%s -> %s' % (fn_short, fn_out)

        labels.append(label) # keep track of all rst files


    output2name={'hdr':'headers only','skl':'skeletons',None:'full solutions'}
    header='Cosmo matlab files - %s files' % output2name[output]
    header=[header, '='*len(header),'','Contents:', '',
            '.. toctree::','    :maxdepth: 2','','']
    toc_fn='matlab_%s_toc' % (output or 'full')

    appendix=['','']
    '''
              'Indices and tables',
              '==================',
              '',
              '* :ref:`genindex`',
              '* :ref:`modindex`',
              '* :ref:`search`']
    '''
    full_toc_fn=join(rst_dir,toc_fn+'.rst')
    with open(full_toc_fn,'w') as f:
        f.write('\n'.join(header))
        for label in labels:
            f.write(add_indent(label) + '\n')
        f.write('\n'.join(appendix))
        print "Written toc to %s" % full_toc_fn

