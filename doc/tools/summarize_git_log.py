#!/usr/bin/env python
#
#   For CoSMoMVPA's license terms and conditions, see   #
#   the COPYING file distributed with CoSMoMVPA         #
#
# builds git summaries using tags used in CoSMoMVPA commits
import datetime
import subprocess
import os
import textwrap

log_fn='source/_static/git_log.txt'
summary_fn='source/_static/git_summary.txt'
git_since="last month"

tag2full=dict(RF='refactorings',
               BF='bug fixes',
               ENH='enhancements',
               CLN='clean-ups',
               BIG='major changes',
               SML='minor changes',
               DOC='code documentation changes',
               WEB='website documentation changes',
               TST='unit or doctest changes',
               BK='changes that break existing functionality',
               NF='new features',
               OPT='optimizations',
               OCTV='Octave-compatibility improvements',
               EXC='exercise-related changes',
               BLD='changes in build system')

show_tags=['BIG','BK','BF',None]

def build_git_log(log_fn=log_fn, since=git_since):
    '''rebuilds git log if it is out of date'''
    if git_log_out_of_date(log_fn=log_fn):
        cmd='git log --since="%s" --full-history --stat > %s' % (since, log_fn)

        print ('rebuilding git log file: commits were '
                        'made since last update . . .'),

        subprocess.check_call(cmd, shell=True)
        print ' done.'
    else:
        print 'git log file is up-to-date'


def git_log_out_of_date(log_fn=log_fn):
    '''helper function: determine whether git log is out of date'''
    if not os.path.isfile(log_fn):
        return True

    cmd='git log -1 --pretty=format:"%ad" --date=local'
    last_commit_str=subprocess.check_output(cmd,shell=True)
    last_commit=datetime.datetime.strptime(last_commit_str,'%c')

    log_changed=datetime.datetime.fromtimestamp(os.path.getmtime(log_fn))

    return log_changed < last_commit

def get_log_lines(fn=log_fn):
    '''read git log lines'''
    with open(fn) as f:
        return f.read().split('\n')

def line_has_tag(line, tag):
    '''check presence of tag'''
    return line.startswith('   ') and \
                tag in line.split(':')[0].strip().split('+')


def get_summary(lines, tag2full=tag2full):
    '''summarizes statistics of tags'''
    tag_counter=dict()

    for line in lines:
        for tag, full in tag2full.iteritems():
            if line_has_tag(line, tag):
                if not tag in tag_counter:
                    tag_counter[tag]=0
                tag_counter[tag]+=1

    summary=[]
    for tag in sorted(list(tag_counter)):
        full=tag2full[tag]
        desc='%07s % 4d %s' % ('[' + tag + ']', tag_counter[tag], full)
        summary.append(desc)

    return element('Summary', summary)

def get_ack(lines, tag='ACK'):
    '''summarizes acknowledgements'''
    acks=set()
    for line in lines:
        if line_has_tag(line, tag):
            parts=line.split('#')
            acks.update(set(parts[1:-1:2]))

    if not acks:
        return None

    sep='\n - '
    return element('Acknowledgements', acks, '\n  - ')

def as_title(header, rep='^'):
    return '%s\n%s\n' % (header, rep*len(header))


def element(header, body_parts, sep='\n'):
    '''formats a header with body parts'''
    parts=[as_title(header), '.. parsed-literal::\n\n']

    body=sep+(sep.join(body_parts) \
                    if isinstance(body_parts, (set, list)) \
                    else body_parts)

    parts.append(indent(body))
    return ''.join(parts) + '\n'

def indent(string, count=4):
    '''adds indent'''
    sep='\n'
    prefix=' '*count
    return prefix+sep.join(prefix + s for s in string.split(sep))

class CommitFileChanged(object):
    def __init__(self, filename, postfix):
        self.filename=filename
        self.postfix=postfix

    @staticmethod
    def from_line(s):
        i=s.index('|')
        return CommitFileChanged(s[1:(i-1)], s[(i+2):])

    def is_linkable(self):
        subdirs2prefix=dict(mvpa=['cosmo'],
                            tests=['test_'],
                            examples=None)
        fn=self.filename.strip()
        path_elements=fn.split(os.path.sep)

        in_linkable_dir=path_elements[0] in subdirs2prefix and \
                                len(path_elements)>1
        if not in_linkable_dir:
            return False

        subdir=path_elements[0]
        allowed_prefixes=subdirs2prefix[subdir]

        name=path_elements[-1]
        has_prefix=allowed_prefixes is None or \
                        any(name.startswith(ap) for ap in allowed_prefixes)
        has_mfile_extension=fn.endswith('.m')
        exists=os.path.isfile(os.path.join('..',fn))

        return has_prefix and has_mfile_extension and exists

    def rst_name(self):
        if not self.is_linkable():
            return None

        return self.filename.split(os.path.sep)[-1].rstrip()[:-2]

    def rst_str(self):
        if self.is_linkable():
            fn=self.filename
            padding_length=len(fn)-len(fn.rstrip())
            padding=' '*padding_length

            s=' :ref:`%s <%s>`%s | %s' % (self.filename,
                                          self.rst_name(),
                                          padding,
                                          self.postfix)
        else:
            s=' %s | %s' % (self.filename, self.postfix)

        return s

class CommitLogEntry(object):
    def __init__(self, preamble, message, files_changed, stats):
        self.preamble=preamble
        self.message=message
        self.files_changed=files_changed
        self.stats=stats

    @staticmethod
    def from_lines(lines, skip=0):
        preamble=[]
        message=[]
        files=[]
        stats=[]

        is_commit_line=lambda x:x.startswith('commit ') and len(x)==47

        empty_count=0
        outputs=(preamble, message, files)

        for line in lines:
            if skip>0:
                skip-=1
                continue
            if line=='':
                empty_count+=1
                if empty_count==len(outputs):
                    break
            elif empty_count>0 and is_commit_line(line):
                break
            else:
                outputs[empty_count].append(line)

        stats=[files.pop()] if len(files) else []

        files_changed=[CommitFileChanged.from_line(line)
                            for line in files]

        return CommitLogEntry(preamble, message, files_changed, stats)

    def rst_preamble(self):
        preamble='\n'.join(self.preamble)
        prefix='commit '
        if preamble.startswith(prefix):
            remainder=preamble[len(prefix):]
            hash_=remainder.split('\n')[0]

            url='https://github.com/CoSMoMVPA/CoSMoMVPA/commit/%s' % hash_
            ref='`%s <%s>`_' % (hash_, url)

            return prefix+ref+remainder[len(hash_):]
        else:
            return preamble

    def rst_message(self):
        m='\n'.join(self.message)
        indent_count=len(m)-len(m.lstrip())
        width=70
        return textwrap.fill(m, width=width,
                                subsequent_indent=' '*(indent_count+4))


    def rst_str(self):
        if self.has_stats():
            files_lines=[f.rst_str() for f in self.files_changed] + \
                        self.stats + ['']
        else:
            files_lines=[]

        lines=[self.rst_preamble(), '', self.rst_message(), ''] + \
                files_lines + ['']

        return '\n'.join(lines)

    def has_tag(self, tag):
        return tag is None or line_has_tag(self.message[0], tag)

    def has_stats(self):
        return len(self.files_changed)>0

    def __len__(self):
        npad=3 if self.has_stats() else 2
        return npad+len(self.preamble)+len(self.message)+\
                        len(self.files_changed)+len(self.stats)

class CommitLog(object):
    def __init__(self, entries):
        self.entries=entries

    @staticmethod
    def from_lines(lines):
        n=len(lines)
        pos=0
        entries=[]
        while pos<(n-1):
            entry=CommitLogEntry.from_lines(lines, pos)
            pos+=len(entry)
            entries.append(entry)

        return CommitLog(entries)

    def rst_str(self, tag=None):
        return ''.join(e.rst_str() for e in self.entries if e.has_tag(tag))


if __name__=='__main__':
    build_git_log()
    log_lines=get_log_lines()
    summary=get_summary(log_lines)
    ack=get_ack(log_lines)


    print "Building git log summary . . .",
    with open(summary_fn,'w') as f:
        f.write(as_title('Changes since %s' % git_since, '='))
        f.write('.. contents::\n    :local:\n    :depth: 1\n\n')

        f.write('\n%s\n' % summary)

        if ack is not None:
            f.write('%s\n' % ack)

        c=CommitLog.from_lines(log_lines)

        for tag in show_tags:
            header='all changes' if tag is None else tag2full[tag]
            c=CommitLog.from_lines(log_lines)
            f.write(element(header[0].upper() + header[1:], c.rst_str(tag)))

    print ' done.'



