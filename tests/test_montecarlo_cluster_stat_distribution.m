function test_suite=test_montecarlo_cluster_stat_distribution
% probability uniformity tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_mccs_uniformity_slow()
    show_progress=true;

    if show_progress
        cleaner=onCleanup(@()progress_helper('-clear'));
        progress_helper(sprintf('Slow test in %s ',...
                                    mfilename()));
    end

    % test for uniformity of p-values of monte_carlo_cluster_stat
    %
    % this test aims to verify that there is not an excessive number of
    % false positives under the null hypothesis. It does so by running
    % monte_carlo_cluster_stat several times on random data, storing the p
    % values for each iteration, and comparing those to a uniform
    % distribution.
    %
    % because running this test is slow, it can perform the same test
    % multiple times, each time increasing the number of iterations. This
    % is repeated until enough evidence is gathered that p values are
    % uniform or not.

    max_attempts=8;
    grow_niter=1.2;

    % benchmark values obtained by runnning
    % helper_mccs_get_correlation_with_uniform multiple times with
    % 'correct' monte carlo custer stat function.
    uniform_c_mu=.985;
    uniform_c_sd=.05;

    % the null hypothesis is that p values are uniformly distributed;
    % earlier versions of monte_carlo_cluster_stat would fail this test,
    % with a lower correlation value as a result. The correlation value
    % is converted to a z-score
    %
    pass_min_z=-1;
    fail_max_z=-5;

    min_pass_or_fail_count=2;
    count_pass=0;
    count_fail=0;

    ps_cell=cell(1,max_attempts);

    niter=20;
    for attempt=1:max_attempts
        ps_cell{attempt}=helper_mccs_get_pvalues(niter,show_progress);
        ps=sort(cat(1,ps_cell{:}));

        % compute correlation with expected p-values
        n_ps=numel(ps);
        ps_uniform=(.5:n_ps)'/n_ps;
        c=cosmo_corr(ps,ps_uniform);

        z=sqrt(niter)*(c-uniform_c_mu)/uniform_c_sd;

        if z>pass_min_z
            count_pass=count_pass+1;
            count_fail=0;

        elseif z<fail_max_z
            count_fail=count_fail+1;
            count_pass=0;
        else
            count_fail=0;
            count_pass=0;
        end

        if count_pass>=min_pass_or_fail_count
            finalize_test_helper(show_progress);

            % test passes
            return;

        elseif count_fail>=min_pass_or_fail_count
            % enough evidence that p values are non-uniform, fail
            finalize_test_helper(show_progress);

            error(['Found z=%d, indicating that probability values '...
                        'are probably not uniform'],z);
        end

        % not enough evidence for either uniform or non-uniform, redo the
        % test with more iterations
        niter=ceil(niter*grow_niter);
        progress_helper('#');

    end

    finalize_test_helper(show_progress);
    error('Maximum number of attempts reached');

function finalize_test_helper(show_progress)
    if show_progress
        fprintf('\n');
    end

function ps=helper_mccs_get_pvalues(niter,show_progress)
    % output: correlation between expected uniform distribution of p values
    % and those obtained from monte_carl_cluster_stat

    niter_tfce=25;
    nsubj=10;

    ps=zeros(niter,1);

    % dataset with single features
    ds=struct();
    ds.samples=randn(nsubj,1);
    ds.sa.targets=ones(nsubj,1);
    ds.sa.chunks=(1:nsubj)';
    ds.fa=struct();
    ds.a=struct();

    % trivial (singleton) neighborhood
    nh=struct();
    nh.neighbors={1};
    nh.fa=struct();
    nh.fa.sizes=1;
    nh.a=struct();
    nh.origin.fa=ds.fa;
    nh.origin.a=ds.a;

    for iter=1:niter
        opt=struct();
        opt.niter=niter_tfce;
        opt.progress=false;
        opt.h0_mean=0;
        opt.dh=.1;

        ds.samples=randn(nsubj,1);

        z=cosmo_montecarlo_cluster_stat(ds,nh,opt);

        ps(iter)=normcdf(z.samples);

        if show_progress
            progress_helper(':');
        end
    end


function progress_helper(what)
    % helper to show progress during the test, which then flushes at the
    % end
    persistent delete_count;

    if isempty(delete_count)
        delete_count=0;
    end

    if strcmp(what,'-clear')
        to_print=repmat(sprintf('\b'),1,delete_count);
        delete_count=0;
    else
        to_print=what;
        delete_count=delete_count+numel(what);
    end

    fprintf(to_print);
