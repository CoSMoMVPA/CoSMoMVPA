function test_suite=test_parallel_get_nproc_available()
% tests for cosmo_parallel_get_nproc_available
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_parallel_get_nproc_available_matlab_ge2013b()
    if ~cosmo_wtf('is_matlab') || ...
                version_lt2013b()
        cosmo_notify_test_skipped('Only for the Matlab platform >=2013b');
        return;
    end

    has_parallel_toolbox=cosmo_check_external('@distcomp',false) && ...
                                ~isempty(which('gcp'));

    aeq=@(expeced_output,varargin)assertEqual(expeced_output,...
                    cosmo_parallel_get_nproc_available(varargin{:}));

    warning_state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    if has_parallel_toolbox
        pool=gcp();

        has_no_pool=isempty(pool);

        if has_no_pool
            % start a new pool
            pool=parpool();
            pool_resetter=onCleanup(@()delete(gcp('nocreate')));
        end

        if isempty(pool)
            aeq(1);
            aeq(1,'nproc',2);
        else
            nproc=pool.NumWorkers();
            aeq(nproc,'nproc',nproc);
        end

    else
        aeq(1);
        aeq(1,'nproc',2);
    end

function tf=version_lt2013b()
    v_num=cosmo_wtf('version_number');
    tf=v_num(1)<8 || v_num(2)<2;

function test_parallel_get_nproc_available_matlab_lt2013b()
    if ~cosmo_wtf('is_matlab') || ...
                ~version_lt2013b()
        cosmo_notify_test_skipped('Only for the Matlab platform <2013b');
        return;
    end

    has_parallel_toolbox=cosmo_check_external('@distcomp',false) && ...
                                ~isempty(which('matlabpool'));


    aeq=@(expeced_output,varargin)assertEqual(expeced_output,...
                    cosmo_parallel_get_nproc_available(varargin{:}));

    warning_state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    if has_parallel_toolbox
        func=@matlabpool;
        query_func=@()func('size');
        nproc_available=query_func();

        if nproc_available==0
            func();
            nproc_available=query_func();
        end

        aeq(nproc_available,'nproc',nproc_available);
    else
        aeq(1);
        aeq(1,'nproc',2);
    end


function test_parallel_get_nproc_available_octave()
    if ~cosmo_wtf('is_octave')
        cosmo_notify_test_skipped('Only for the Octave platform');
        return;
    end


    has_parallel_toolbox=cosmo_check_external(...
                        'octave_pkg_parallel',false);

    aeq=@(expeced_output,varargin)assertEqual(expeced_output,...
                    cosmo_parallel_get_nproc_available(varargin{:}));

    warning_state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    if has_parallel_toolbox
        nproc_available=nproc('overridable');
        aeq(nproc_available,'nproc',nproc_available);
    else
        aeq(1);
        aeq(1,'nproc',2);
    end

function test_parallel_get_nproc_available_override_query_func
    for navailable=1:3
        opt=struct();
        opt.nproc_available_query_func=@()mock_query_func(navailable);

        result=cosmo_parallel_get_nproc_available(opt);
        assertEqual(navailable,result);

        for nproc=[1:6,inf]
            % save warning state
            warning_state=cosmo_warning();
            warning_resetter=onCleanup(@()cosmo_warning(warning_state));

            cosmo_warning('reset');
            cosmo_warning('off');

            % check number of processes
            opt.nproc=nproc;
            result=cosmo_parallel_get_nproc_available(opt);
            expected=min(nproc,navailable);

            assertEqual(expected,result);

            % check whether a warning was shown if expected
            should_show_warning=nproc>navailable && isfinite(nproc);

            s=cosmo_warning();
            did_show_warning=~isempty(s.shown_warnings);
            assertEqual(did_show_warning,should_show_warning);

            clear warning_resetter;
        end
    end

function test_parallel_get_nproc_available_error_with_bad_gcp
    if ~cosmo_wtf('is_matlab') || ...
                version_lt2013b()
        cosmo_notify_test_skipped('Only for the Matlab platform >=2013b');
        return;
    end

    helper_test_with_bad_function('gcp')


function test_parallel_get_nproc_available_error_with_bad_matlabpool
    if ~cosmo_wtf('is_matlab') || ...
                ~version_lt2013b()
        cosmo_notify_test_skipped('Only for the Matlab platform <2013b');
        return;
    end

    helper_test_with_bad_function('matlabpool')



function helper_test_with_bad_function(func_name)
    [pth,nm]=write_func(func_name,...
                            {sprintf('function pool=%s()',func_name),...
                            'error(''here'')'});
    cleaner=onCleanup(@()clean_func(pth,nm));
    addpath(pth);

    result=cosmo_parallel_get_nproc_available();
    assertEqual(result,1);




function [pth,nm]=write_func(func_name,lines)
    pth=tempname();

    mkdir(pth);
    nm=[func_name '.m'];

    fn=fullfile(pth,nm);
    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'%s\n',lines{:});


function clean_func(pth,nm)
    delete(fullfile(pth,nm));
    rmpath(pth);
    rmdir(pth);



function [output,msg]=throw_error()
    error('here');


function [output,msg]=mock_query_func(nproc)
    msg='';
    output=nproc;



function test_parallel_get_nproc_available_exceptiont()
    warning_state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_parallel_get_nproc_available(varargin{:}),'');
    illegal_args={{'foo'},...
                        {3},...
                        {'nproc',0},...
                        {'nproc',-1},...
                        {struct('nproc',1.6)}...
                        };
    for k=1:numel(illegal_args)
        args=illegal_args{k};
        aet(args{:});
    end