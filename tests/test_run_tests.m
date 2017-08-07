function test_suite = test_run_tests
% tests for cosmo_run_tests
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_run_tests_passing
    test_content='assert(true);';
    [result,output]=helper_test_make_and_run(test_content);
    assertTrue(result);
    assert(~isempty(findstr('OK',output)));


function test_run_tests_failing
    test_content='assert(false);';
    [result,output]=helper_test_make_and_run(test_content);
    assertFalse(result);
    assert(~isempty(findstr('FAILED',output)));

function test_run_tests_no_file_found_absolute_path()
    if skip_test_if_octave_package_io_2_4_2_or_later()
        return;
    end

    cosmo_test_dir=fileparts(mfilename('fullpath'));
    fn=cosmo_make_temp_filename(fullfile(cosmo_test_dir,'test_'),'.m');
    assertExceptionThrown(@()helper_run_tests({fn}),'');


function test_run_tests_no_file_found_relative_path()
    if skip_test_if_octave_package_io_2_4_2_or_later()
        return;
    end

    fn=cosmo_make_temp_filename('test_','.m');
    assertExceptionThrown(@()helper_run_tests({fn}),'');


function test_run_tests_missing_logfile_argument()
    if skip_test_if_octave_package_io_2_4_2_or_later()
        return;
    end

    assertExceptionThrown(@()helper_run_tests({'-logfile'}),'');


function [result,output]=helper_test_make_and_run(test_content)
    cosmo_test_dir=fileparts(mfilename('fullpath'));

    fn=cosmo_make_temp_filename(fullfile(cosmo_test_dir,'test_'),'.m');

    [unused,test_name]=fileparts(fn);

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()delete(fn));
    fprintf(fid,...
            ['function test_suite=%s\n'...
             'try \n'...
             '    test_functions=localfunctions();\n'...
             'catch\n'...
             'end\n'...
             'initTestSuite;\n'...
             'function %s_generated\n'...
             '%s'],...
             test_name,test_name,test_content);
    fclose(fid);


    args={fn};
    [result,output]=helper_run_tests(args);



function [result,output]=helper_run_tests(args)
    warning_state=cosmo_warning();
    orig_path=path();
    orig_pwd=pwd();
    log_fn=tempname();

    path_cleaner=onCleanup(@()path(orig_path));
    warning_cleaner=onCleanup(@()cosmo_warning(warning_state));
    pwd_cleaner=onCleanup(@()cd(orig_pwd));
    log_fn_cleaner=onCleanup(@()delete_if_exists(log_fn));

    % ensure path is set; disable warnings by cosmo_set_path
    cosmo_warning('off');

    more_args={'-verbose','-logfile',log_fn,'-no_doc_test'};
    result=cosmo_run_tests(more_args{:},args{:});
    fid=fopen(log_fn);
    file_closer=onCleanup(@()fclose(fid));

    output=fread(fid,Inf,'char=>char')';


function delete_if_exists(fn)
    if exist(fn,'file')
        delete(fn);
    end


function is_2_4_2_or_later=skip_test_if_octave_package_io_2_4_2_or_later()
% July 2016:
% Octave package 'io' version 2.4.2 gave the following error with
% three tests:
% - test_run_tests_no_file_found_absolute_path
% - test_run_tests_no_file_found_relative_path
% - test_run_tests_missing_logfile_argument
%
%         failure: '__octave_config_info__' undefined near line 1 column 1
%   __init_io__:30 (/Users/nick/octave/io-2.4.2/__init_io__.m)
%   /Users/nick/octave/io-2.4.2/PKG_ADD:2 (/Users/nick/octave/io-2.4.2/PKG_ADD)
%
% These tests are disabled for now when using Octave and io 2.4.2.
% (Version 2.4.0 seems to work fine)
%
% Update Sept 2016: same issue with io 2.4.3. Updated code to take any
% version from 2.4.2 or later

    is_2_4_2_or_later=false;

    if ~cosmo_wtf('is_octave')
        return;
    end

    pkgs=pkg('list','io');
    if numel(pkgs)~=1
        return;
    end

    version=pkgs{1}.version;
    elem_str=regexp(version,'(\d+)\.(\d+)\.(\d+)','tokens','once');
    elem=cellfun(@str2num,elem_str);

    is_2_4_2_or_later=elem(1)>=2 || ...
                        (elem(1)==2 && elem(2)>=4) || ...
                        (elem(1)==2 && elem(2)==4 && elem(3)>=2);

    if ~is_2_4_2_or_later
        return;
    end

    reason=['Octave io package 2.4.2 gives unexpected error '...
            '"''__octave_config_info__'' undefined" in '...
            '__init_io__.m:30; therefore '...
            'the tests causing this error are temporarily disabled'];
    cosmo_notify_test_skipped(reason);
