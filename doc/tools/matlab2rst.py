#!/usr/bin/env python
#   For CoSMoMVPA's license terms and conditions, see   #
#   the COPYING file distributed with CoSMoMVPA         #
#
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
# Important: requires sphinx with recent
#            underscore.js (1.3.1 works, 0.4.4 does not)
#
# NNO Aug 2013

import os
import glob
import sys
from os.path import join, split, getmtime, isfile, abspath, basename
from os import pardir

def get_absolute_root_dir():
    parent_dir=lambda x:abspath(join(x,pardir))
    pth=parent_dir(__file__)

    cosmo_directories=['mvpa','doc','examples','tests']

    max_levels=30;

    for k in xrange(max_levels):
        pth_parent=parent_dir(pth)
        print pth, pth_parent

        contents=glob.glob(join(pth_parent,'*'))
        contents_rel=map(basename, contents)

        if set.issubset(set(cosmo_directories), set(contents_rel)):
            return pth

        pth=pth_parent

    raise ValueError('Could not find root directory')


doc_root_dir=get_absolute_root_dir()
root_sub_dir=lambda x: join(doc_root_dir,x)

matlab_dir=root_sub_dir('../mvpa')
example_dir=root_sub_dir('../examples')
test_dir=root_sub_dir('../tests')

output_root_abs=root_sub_dir('source')
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

def remove_trailing_percent(data):
    r=[]

    is_percent=True
    for d in data:
        if not d in ' %':
            is_percent=False

        r.append(' ' if is_percent else d)

    return ''.join(r)


def matlab2parts(data):
    '''Converts data to tuple (function sepc, first doc line, other doc lines, body)'''
    lines=data.split('\n')

    parts=[[] for i in xrange(4)]
    stage=0
    for i, line in enumerate(lines):
        line=line.strip()

        if i==0 and not 'function' in line:
            # no function, hence script
            stage+=1

        if stage==2 and not line.startswith('%'):
            stage+=1
        next_stage=False
        is_continuation=line.endswith('...')

        if stage==0:
            next_stage=True
        elif stage==1:
            line=remove_trailing_percent(line).strip()
            if not line:
                next_stage=True
                line=None
        elif stage==2:
            line=remove_trailing_percent(line)

        parts[stage].append(line)

        if next_stage and not is_continuation:
            stage+=1

    rs=[]
    for i,part in enumerate(parts):
        # first explanatory line is concatenated without newline
        sep=' ' if i==1 else '\n'
        rs.append(sep.join([p for p in part if p is not None]))

    return tuple(rs)





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
                    cosmo='CoSMoMVPA functions',
                    test='CoSMoMVPA unit tests')[self.prefix]

    def get_postfix(self):
        return '' if self.prefix == 'cosmo' else '_'+self.prefix


    def needs_full_include(self):
        return self.prefix=='demo'

    def needs_pb(self, output):
        return output is None and self.prefix in ('demo','run')


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

class RSTTable(object):
    def __init__(self):
        self.elements=[]

    def add(self, element):
        self.elements.append(element)

    def __len__(self):
        return len([e for e in self.elements if isinstance(e, RSTModRef)])

    def widths(self):
        widths=None
        for element in self.elements:
            if isinstance(element,RSTModRef):
                ws=element.widths()
                if widths is None:
                    widths=ws
                else:
                    assert(len(widths)==len(ws))
                    for i, w in enumerate(ws):
                        if w>widths[i]:
                            widths[i]=w
        return widths

    def names(self):
        return [e.name for e in self.elements if isinstance(e, RSTModRef)]

    def __str__(self):
        widths=self.widths()
        h=self.hline()
        lines=[h]+[element.to_lines(widths) for element in self.elements]+[h]
        return ''.join(lines)

    def hline(self):
        widths=self.widths()
        return ' '.join(['='*w for w in widths])+'\n'


class RSTHeader(object):
    def __init__(self,name):
        self.name=name
    def to_lines(self, widths):
        hline=' '.join(['-'*w for w in widths])+'\n'
        nm='**%s**' % self.name
        return hline+nm+'\n'+hline

class RSTModRef(object):
    def __init__(self,name,desc):
        self.name=name
        self.desc=desc

    def ref_name(self):
        return ':ref:`%s`' % self.name

    def widths(self):
        return map(len,(self.ref_name(),self.desc))

    def to_lines(self, widths):
        assert(len(widths)==2)
        line=''
        for i, (s, w) in enumerate(zip((self.name,self.desc),widths)):
            ss=self.ref_name() if i==0 else s
            n=w-len(ss)
            assert(n>=0)
            line+='%s%s '%(ss,' '*n)
        return line+'\n'


class CoSMoModules(object):
    _name2funcs=dict(
        classification=['classify_knn',
                     'classify_lda',
                     'classify_libsvm',
                     'classify_matlabsvm',
                     'classify_matlabsvm_2class',
                     'classify_naive_bayes',
                     'classify_nn',
                     'classify_selective_naive_bayes',
                     'classify_svm',
                     'crossvalidate',
                     'crossvalidation_measure',
                     'winner_indices',
                     'confusion_matrix',
                     'classify_meta_feature_selection',
                     ],

        operations=['slice',
                    'stack',
                    'split',
                    'dim_prune',
                    'dim_transpose',
                    'dim_rename',
                    'dim_insert',
                    'dim_remove',
                    ],

        processing=['randomize_targets',
                    'fx',
                    'normalize',
                    'average_samples',
                    'remove_useless_data',
                    'meeg_baseline_correct',
                    ],

        helpers=['dir',
                 'set_path',
                 'type',
                 'warning',
                 'config',
                 'show_progress',
                 'config',
                 'flatten',
                 'unflatten',
                 'check_external',
                 ],

        utils=[  'strsplit',
                 'strjoin',
                 'structjoin',
                 'match',
                 'dim_match',
                 'dim_find',
                 'isfield',
                 'cartprod',
                 'index_unique',
                 'rand',
                 'tail',
                 'overlap',
                 'align',
                 'sample_unique'
                 ],


        neighborhood=['spherical_neighborhood',
                      'interval_neighborhood',
                      'surficial_neighborhood',
                      'meeg_chan_neighborhood',
                      'neighborhood_split',
                      'cross_neighborhood',
                      'sphere_offsets',
                      'searchlight',
                      'naive_bayes_classifier_searchlight',
                    ],

        clustering=['cluster_neighborhood',
                      'convert_neighborhood',
                      'montecarlo_cluster_stat',
                      'check_neighborhood',
                      'measure_clusters',
                      'clusterize',
                      'find_local_extrema',
                      ],

        develop=['run_tests',
                 'publish_run_scripts',
                 'wtf',
                 'notify_test_skipped',
                 'skip_test_if_no_external',
                 'make_temp_filename',
                 ],

        visualization=['disp',
                       'plot_slices'
                       ],


        datasets=['fmri_dataset',
                  'map2fmri',
                  'meeg_dataset',
                  'map2meeg',
                  'surface_dataset',
                  'map2surface',
                  'synthetic_dataset',
                  'check_dataset'
                  ],

        stats=['statcode',
               'stat',
               'anova_feature_selector'
               ],

        correlations=['correlation_measure',
                      'corr'
                      ],

        rsa=        ['target_dsm_corr_measure',
                     'dissimilarity_matrix_measure',
                     'pdist',
                     'squareform',
                     'distatis',
                     'dim_generalization_measure'
                     ],

        partitions= ['balance_partitions',
                     'nchoosek_partitioner',
                     'nfold_partitioner',
                     'check_partitions',
                     'oddeven_partitioner',
                     'chunkize',
                     'check_partitions'
                     ],

        meeg=       ['meeg_chan_neighbors',
                    'meeg_senstype_collection',
                    'meeg_chantype',
                    'meeg_find_layout',
                    'meeg_layout_collection',
                    'meeg_chan_neighborhood',
                    'meeg_senstype2layout_mapping',
                    ],

        fmri=       ['fmri_reorient',
                    'fmri_orientation',
                    'fmri_convert_xform',
                    'fmri_deoblique',
                    'vol_grid_convert',
                    'vol_coordinates',
                    ],

        deprecated=['dataset_slice_fa',
                    'dataset_slice_sa',
                    'meta_feature_selection_classifier',
                    'dim_slice',
                   ],
        )



    _name2full= [('datasets','Dataset input/output'),
                ('operations','Dataset operations'),
                ('processing','Dataset processing'),
                ('meeg','MEEG related functions'),
                ('fmri','fMRI related functions'),
                ('visualization','Data visualuzation'),
                ('correlations','Correlations'),
                ('classification','Classification and cross-validation'),
                ('rsa','Representational similarity analysis'),
                ('partitions','Partitioning (for cross-validation)'),
                ('neighborhood','Neighborhoods and searchlight'),
                ('clustering','Feature-based clustering'),
                ('stats','Univariate statistics'),
                ('utils','Utility functions'),
                ('helpers','Misceleanous helper functions'),
                ('develop','Developer functions'),
                ('deprecated','Deprecated - to be removed in the future'),
                ]

    def __init__(self, source_dir='../mvpa',prefix='cosmo_',ext='.m'):
        self.source_dir=source_dir
        self.prefix=prefix
        self.ext=ext

    def as_table(self, data):
        # data is a list of tuples (name, description)
        name2desc=dict(data)
        visited_func_names=set()

        table=RSTTable()

        for cat, catfull in self._name2full:
            table.add(RSTHeader(catfull))
            for func_name in self._name2funcs[cat]:
                full_name=self.prefix+func_name
                if full_name in name2desc:
                    table.add(RSTModRef(full_name,name2desc[full_name]))
                #else:
                #    print func_name, name2desc

        if len(table):
            missed=set(name2desc)-set(table.names())
            if len(missed):
                table.add(RSTHeader('Other functions (possibly experimental)'))
                for name in missed:
                    table.add(RSTModRef(name, name2desc[name]))
        else:
            table=RSTTable()
            table.add(RSTHeader('All functions'))
            for name in sorted(name2desc):
                table.add(RSTModRef(name,name2desc[name]))


        return table.__str__()

modules=CoSMoModules()



rst_types=(RSTType('demo',[None]),
           RSTType('run',[None,'skl']),
           RSTType('cosmo',[None,'hdr','skl']),
           RSTType('test',[None]))


all_input_dirs=[matlab_dir, example_dir, test_dir]

all_fns=sum([glob.glob(join(d,'*.m')) for d in all_input_dirs],[])
all_fns.sort()

for output in ('hdr','skl',None):
    infix='' if output is None else '_'+output
    for rst_type in rst_types:
        fns=rst_type.matching(output, all_fns)
        if not len(fns):
            continue

        base_names=[]
        rebuild_toc=False

        print ("matlab2rst %s %s: " % (rst_type.prefix, output or '')),
        for fn in fns:
            [p,b]=base_name(fn)

            b+=infix

            # make a text file that can be 'included' in sphinx
            trg_fn=join(output_mat_abs,'%s.txt' % b)

            with open(fn) as f:
                mat=f.read()

            parts=matlab2parts(mat)

            remake_rst=False
            if is_newer(fn, trg_fn):
                remake_rst=True
                rst=matlab2rst(mat, output)

                with open(trg_fn,'w') as f:
                    f.write(rst)

            if rst_type.needs_pb(output):
                pb_path=join(output_root_abs, publish_rel)
                pb_fn=join(pb_path,b+'.html')
                if is_newer(fn, pb_fn):
                    remake_rst=True
                include_pb=':%s_up:`%s`\n\n' % (rst_type.prefix,b)
            else:
                include_pb=''

            # print progress
            sys.stdout.write("." if remake_rst else 's')
            # make the rst file that includes it
            trg_fn=join(output_mat_abs,'%s.rst' % b)
            if remake_rst or is_newer(fn, trg_fn):
                label=b.replace('_',' ')
                header='.. _%s:\n\n%s\n%s\n\n%s' % (b,label,'='*len(b),include_pb)
                body='.. include :: %s\n\n' % ('%s.txt' % b)

                with open(trg_fn,'w') as f:
                    f.write(header+body)

                rebuild_toc=True

            base_names.append((b,parts[1]))
        if rebuild_toc:
            toc_base_name='modindex%s%s' % (infix, rst_type.get_postfix())
            title='%s - %s' % (rst_type.get_name(), rst_type.type2name(output))
            header='.. _`%s`:\n\n.. toctree::\n    :maxdepth: 2\n    :hidden:\n\n' % (
                        toc_base_name)


            trg_fn=join(output_root_abs,'%s.rst' % toc_base_name)
            with open(trg_fn,'w') as f:
                f.write(header)
                f.write('\n'.join('    %s/%s' % (output_mat_rel,b) for b,_ in base_names))
                f.write('\n\n%s\n%s\n\n' % (title, '+' * len(title)))

                f.write(modules.as_table(base_names))


            if rst_type.needs_full_include():
                include_base_name='contents%s.rst' % rst_type.get_postfix()
                trg_fn=join(output_root_abs,include_base_name)

                title='%s - full listings' % (rst_type.get_name())
                header=('.. _`%s`:\n\n%s\n%s\n\nContents\n\n.. '
                        'contents::\n    :local:\n    :depth: 1\n\n') % (
                        include_base_name, title, '='*len(title))

                body='\n'.join(['%s\n%s\n\n :demo:`%s`\n\n.. include:: %s\n\n\n' % (
                            b,'+'*len(b),b,join(output_mat_rel,b)+'.txt')
                                    for b,_ in base_names])

                with open(trg_fn,'w') as f:
                    f.write(header+body+'\n\n')

            sys.stdout.write('<TOC>')

        print




