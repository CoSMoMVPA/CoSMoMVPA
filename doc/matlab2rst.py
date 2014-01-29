#!/usr/bin/env python
# converts matlab to rst files
#
# This code reads all matlab .m files and then generates multiple versions:
# 
# 1) the full file, but with lines '% >@@>' and '<<' removed
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

output_root_abs='source'
output_index_abs=output_root_abs
output_mat_rel='matlab'
output_mat_abs=join(output_root_abs, output_mat_rel)

publish_rel=join('_static/publish')

for d in (output_root_abs, output_index_abs, output_mat_abs):
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


class RSTType(object):
    def __init__(self, prefix, build_types):
        self.prefix=prefix
        self.build_types=build_types

    def matches(self, fn):
        short_fn=split(fn)[1]
        return short_fn.startswith(self.prefix+'_')

    def matching(self, tp, fns):
        if tp in self.build_types:
            return [fn for fn in fns if self.matches(fn)]
        else:
            return []


    def has_type(self, tp):
        return tp in self.build_types

    def type2name(self, tp):
        return {None:'complete files',
                'skl': 'skeleton files',
                'hdr': 'header signature files'}[tp]

    def get_name(self):
        return dict(demo='Demonstrations',
                    run='Runnable examples',
                    cosmo='CoSMoMVPA functions')[self.prefix]

    def get_postfix(self):
        return '' if self.prefix is 'cosmo' else '_'+self.prefix


    def needs_full_include(self):
        return self.prefix=='demo'

class RSTprop(object):
    def __init__(self):
        pass

    


def base_name(fn, ext=None):
    if ext is None:
        ext='.m'
    
    p, base_fn=split(fn)

    if not base_fn.endswith(ext):
        raise ValueError('%s does not end with %s', base_fn, ext)

    return p, base_fn[:-len(ext)]


def is_newer(fn, other_fn):
    return not isfile(other_fn) or getmtime(fn)>getmtime(other_fn) 
    # return True if fn is newer than other_fn
    # and other_fn exists
    return 

rst_types=(RSTType('demo',[None]),
           RSTType('run',[None,'skl']),
           RSTType('cosmo',[None,'hdr','skl']))

all_fns=sum([glob.glob(join(d,'*.m')) for d in [matlab_dir, example_dir]],[])
all_fns.sort()

for output in ('hdr','skl',None):
    infix='' if output is None else '_'+output
    for rst_type in rst_types:
        fns=rst_type.matching(output, all_fns)
        if not len(fns):
            continue

        base_names=[]
        rebuild_toc=False

        for fn in fns:
            [p,b]=base_name(fn)
        
            b+=infix

            # make a text file that can be 'included' in sphinx
            trg_fn=join(output_mat_abs,'%s.txt' % b)
            
            remake_rst=False
            if is_newer(fn, trg_fn):
                remake_rst=True
                with open(fn) as f:
                    mat=f.read()

                rst=matlab2rst(mat, output)
                
                with open(trg_fn,'w') as f:
                    f.write(rst)

            # make the rst file that includes it
            trg_fn=join(output_mat_abs,'%s.rst' % b)
            if remake_rst or is_newer(fn, trg_fn):
                label=b.replace('_',' ')
                header='.. _%s:\n\n%s\n%s\n\n' % (b,label,'='*len(b))
                body='.. include :: %s\n\n' % ('%s.txt' % b)

                with open(trg_fn,'w') as f:
                    f.write(header+body)

                rebuild_toc=True

            
            base_names.append(b)

        if rebuild_toc:
            toc_base_name='modindex%s%s' % (infix, rst_type.get_postfix())
            title='%s - %s' % (rst_type.get_name(), rst_type.type2name(output))
            header='.. _`%s`:\n\n%s\n%s\n\n.. toctree::\n    :maxdepth: 2\n\n' % (
                        toc_base_name, title, '='*len(title))

            
            trg_fn=join(output_root_abs,'%s.rst' % toc_base_name)
            with open(trg_fn,'w') as f:
                f.write(header)
                f.write('\n'.join('    %s/%s' % (output_mat_rel,b) for b in base_names))
                

            if rst_type.needs_full_include():
                include_base_name='contents%s.rst' % rst_type.get_postfix()
                trg_fn=join(output_root_abs,include_base_name)

                title='%s - full listings' % (rst_type.get_name())
                header=('.. _`%s`:\n\n%s\n%s\n\nContents\n\n.. '
                        'contents::\n    :local:\n    :depth: 1\n\n') % (
                        include_base_name, title, '='*len(title))

                body='\n'.join(['%s\n%s\n\n :demo:`%s`\n\n.. include:: %s\n\n\n' % (
                            b,'+'*len(b),b,join(output_mat_rel,b)+'.txt')
                                    for b in base_names])

                with open(trg_fn,'w') as f:
                    f.write(header+body+'\n\n')




