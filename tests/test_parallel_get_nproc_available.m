function test_suite=test_parallel_get_nproc_available()
% tests for cosmo_parallel_get_nproc_available
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_parallel_get_nproc_available_matlab()
    if ~cosmo_wtf('is_matlab')
        cosmo_notify_test_skipped('Only for the Matlab platform');
        return;
    end

    has_parallel_toolbox=cosmo_check_external('@distcomp',false);

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






function test_parallel_get_nproc_available_exceptiont()
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