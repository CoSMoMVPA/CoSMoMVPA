function test_suite=test_montecarlo_cluster_stat_distribution
% probability uniformity tests for cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_mccs_uniformity_slow()
    if cosmo_skip_test_if_no_external('!norminv');
        return;
    end

    % show progress when running travis - otherwise the test may stall
    % when no output is received for a long time
    show_progress=strcmp(getenv('CI'),'true');

    % test for uniformity of p-values of monte_carlo_cluster_stat
    %
    % because running this test is slow, it can perform the same test
    % multiple times, each time increasing the number of iterations. This
    % is repeated until enough evidence is gathered that p values are
    % uniform or not.

    max_attempts=8;
    grow_niter=1.5;

    % values obtained by runnning helper_mccs_get_correlation_with_uniform
    % multiple times with 'correct' monte carlo custer stat function and
    % with 50 iterations. Clearly with more iterations the sd is lower.
    uniform_c_mu=.99;
    uniform_c_sd=.005;

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

    niter=10;
    for attempt=1:max_attempts
        ps_cell{attempt}=helper_mccs_get_pvalues(niter,show_progress);
        if show_progress
            fprintf('\n');
        end
        ps=sort(cat(1,ps_cell{:}));

        % compute correlation with expected p-values
        n_ps=numel(ps);
        ps_uniform=(.5:n_ps)'/n_ps;
        c=cosmo_corr(ps,ps_uniform);

        z=(c-uniform_c_mu)/uniform_c_sd;

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
            return;

        elseif count_fail>=min_pass_or_fail_count
            % enough evidence that p values are non-uniform, fail
            error(['Found z=%d, indicating that probability values '...
                        'are probably not uniform'],z);
        end

        % not enough evidence for either uniform or non-uniform, redo the
        % test with more iterations
        niter=ceil(niter*grow_niter);

    end

    error('Maximum number of attempts reached');


function ps=helper_mccs_get_pvalues(niter, show_progress)
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
            fprintf(':');
        end
    end


