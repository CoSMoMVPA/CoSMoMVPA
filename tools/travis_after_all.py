#!/usr/bin/env python
#
# travis_after_all.py
#
# Retrieved from https://github.com/dmakhno/travis_after_all
#
# Original code by Dmytro Makhno
# Changes by Nikolaas N. Oosterhof
#
# The main goal of this script to have a single publish when a build has
# several jobs.
#
#    The MIT License (MIT)
#
#    Copyright (c) 2014 Dmytro Makhno
#                  2016 Nikolaas N. Oosterhof
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy of
#    this software and associated documentation files (the "Software"), to deal in
#    the Software without restriction, including without limitation the rights to
#    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
#    the Software, and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in all
#    copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
#    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import os
import json
import time
import logging
import argparse

try:
    import urllib.request as urllib2
except ImportError:
    import urllib2



class JobStatus(object):
    def __init__(self, number, is_finished, result,
                 allow_failure, is_leader):
        self.is_finished = is_finished
        self.result = result
        self.number = number
        self.allow_failure = allow_failure
        self.is_leader = is_leader

    def __str__(self):
        return '%s(%s,N=%s,N=%s,A=%s,L=%s)' % (self.__class__.__name__,
                                               self.number,
                                               self.is_finished,
                                               self.result,
                                               self.allow_failure,
                                               self.is_leader)

    @property
    def needs_waiting(self):
        return not (self.is_leader or self.is_finished or self.allow_failure)

    @property
    def is_failure(self):
        if self.allow_failure or not self.is_finished:
            return False

        return self.result != 0

    @classmethod
    def from_matrix(cls, json_elem, leader_job_number):
        # log.info('Parsing %s' % json_elem)
        number = json_elem['number']
        is_finished = json_elem['finished_at'] is not None
        result = json_elem['result']
        allow_failure = json_elem['allow_failure']
        is_leader = number == leader_job_number

        return cls(number, is_finished, result,
                   allow_failure, is_leader)



class MatrixList(list):
    @classmethod
    def from_json(cls, raw_json, leader_job_number):
        matrix_elems = raw_json["matrix"]

        list_instance = cls()
        for matrix_elem in matrix_elems:
            # log.info('converting from: %s' % matrix_elem)

            job_status = JobStatus.from_matrix(matrix_elem, leader_job_number)
            # log.info('status: %s' % job_status)

            list_instance.append(job_status)

        return list_instance

    def __str__(self):
        elem_str = ','.join('%s' % job for job in self)
        return '%s(W=%s,F=%s,E=%s)' % (self.__class__.__name__,
                                       self.needs_waiting,
                                       self.is_failure,
                                       elem_str)

    @classmethod
    def snapshot(cls, travis_entry, travis_token, leader_job_number):
        log.info('Taking snapshot')
        headers = {'content-type': 'application/json'}
        if travis_token is None:
            log.info('No travis token')
        else:
            headers['Authorization'] = 'token {}'.format(travis_token)

        suffix = 'builds/%s' % build_id
        data = None

        raw_json = travis_get_json(travis_entry, suffix, data, headers)

        return cls.from_json(raw_json, leader_job_number)

    @property
    def needs_waiting(self):
        return any(job.needs_waiting for job in self)

    @property
    def is_failure(self):
        return any(job.is_failure for job in self)

    @property
    def status(self):
        if self.needs_waiting:
            s = "others_busy"
        else:
            if self.is_failure:
                s = "others_failed"
            else:
                s = "others_succeeded"

        return s



def wait_others_to_finish(travis_entry, travis_token, leader_job_number):
    while True:
        matrix_list = MatrixList.snapshot(travis_entry, travis_token,
                                          leader_job_number)
        if all(elem.is_finished or elem.is_leader
               for elem in matrix_list):
            break

        log.info("Leader waits for minions: %s..." % matrix_list)
        time.sleep(polling_interval)



def travis_get_json(travis_entry, suffix, data, headers=None):
    if headers is None:
        headers = {'content-type': 'application/json',
                   'User-Agent': 'Travis/1.0'}

    url = "%s/%s" % (travis_entry, suffix)
    # log.info('Using URL %s' % url)

    req = urllib2.Request(url, data, headers)
    # log.info('Request: %s [%s, %s]' % (req,
    #                                   data,
    #                                   headers))
    response = urllib2.urlopen(req).read()
    # log.info('response: %s' % response)
    json_content = json.loads(response.decode('utf-8'))

    return json_content



def get_travis_token(travis_entry, gh_token):
    if gh_token is None or gh_token == "":
        log.info('GITHUB_TOKEN is not set, not using travis token')
        return None

    suffix = "/auth/github"
    data = {"github_token": gh_token}
    headers = {'content-type': 'application/json',
               'User-Agent': 'Travis/1.0'}

    json_content = travis_get_json(travis_entry, suffix, data, headers)
    travis_token = json_content.get('access_token')

    return travis_token



def get_argument_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('--travis_entry',
                        default='https://api.travis-ci.org')
    parser.add_argument('--is_master', action="store_true")
    parser.add_argument('--master_number', type=int, default=0)
    parser.add_argument('--poll', type=int, default=5,
                        description='polling interval in seconds')
    parser.add_argument('--export_file',
                        default='.to_export_back')
    return parser



def current_job_is_leader(master_index):
    job_number = os.getenv(TRAVIS_JOB_NUMBER)
    return is_leader(master_index, job_number)



def is_leader(master_index, job_number):
    result = job_number.endswith('.%s' % master_index)
    log.info('is_leader %s %s: %s' % (master_index, job_number, result))



def get_job_number():
    return os.getenv(TRAVIS_JOB_NUMBER)



def report(export_file, output_dict):
    content = ' '.join('%s=%s' % (k, v)
                       for k, v in output_dict.iteritems())
    log.info("variables: %s" % content)

    # since python is subprocess, env variables are exported back via file
    with open(export_file, 'w') as f:
        f.write(content)



if __name__ == '__main__':
    log = logging.getLogger("travis.leader")
    log.addHandler(logging.StreamHandler())
    log.setLevel(logging.INFO)

    parser = get_argument_parser()
    args = parser.parse_args()

    TRAVIS_JOB_NUMBER = 'TRAVIS_JOB_NUMBER'
    TRAVIS_BUILD_ID = 'TRAVIS_BUILD_ID'
    POLLING_INTERVAL = 'LEADER_POLLING_INTERVAL'
    GITHUB_TOKEN = 'GITHUB_TOKEN'
    BUILD_AGGREGATE_STATUS = 'BUILD_AGGREGATE_STATUS'

    build_id = os.getenv(TRAVIS_BUILD_ID)
    polling_interval = os.getenv(POLLING_INTERVAL) or args.poll
    gh_token = os.getenv(GITHUB_TOKEN)
    job_number = os.getenv(TRAVIS_JOB_NUMBER, '')

    is_master = args.is_master or \
                job_number.endswith('.%s' % parser.master_number)

    travis_entry = args.travis_entry

    if job_number is None or '.' not in job_number:
        # seems even for builds with only one job, this won't get here
        log.fatal("Don't use defining leader for build without matrix")
        exit(1)
    elif not is_master:
        log.info("This is a minion with job number %s" % job_number)
        exit(0)


    # If we get here, we are the leader
    log.info("This is a leader")
    travis_token = get_travis_token(travis_entry, gh_token)

    leader_job_number = get_job_number()
    wait_others_to_finish(travis_entry, travis_token, leader_job_number)

    final_snapshot = MatrixList.snapshot(travis_entry, travis_token,
                                         leader_job_number)
    log.info("Final Results: %s" % final_snapshot)

    output_dict = dict(BUILD_LEADER="YES",
                       BUILD_AGGREGATE_STATUS=final_snapshot.status)

    export_file = args.export_file
    report(export_file, output_dict)
