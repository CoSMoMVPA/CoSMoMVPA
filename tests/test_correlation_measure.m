function test_suite=test_correlation_measure
% tests for cosmo_correlation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_correlation_measure_basis()
    ds3=cosmo_synthetic_dataset('nchunks',3,'ntargets',4);
    ds=cosmo_slice(ds3,ds3.sa.chunks<=2);

    ds.sa.chunks=ds.sa.chunks+10;
    ds.sa.targets=ds.sa.targets+20;
    x=ds.samples(ds.sa.chunks==11,:);
    y=ds.samples(ds.sa.chunks==12,:);

    cxy=atanh(corr(x',y'));

    diag_msk=eye(4)>0;
    c_diag=mean(cxy(diag_msk));
    c_off_diag=mean(cxy(~diag_msk));

    delta=c_diag-c_off_diag;

    c1=cosmo_correlation_measure(ds);
    assertElementsAlmostEqual(delta,c1.samples,'relative',1e-5);
    assertEqual(c1.sa.labels,{'corr'});

    c2=cosmo_correlation_measure(ds,'output','correlation');
    assertElementsAlmostEqual(reshape(cxy,[],1),c2.samples);
    assertEqual(kron((1:4)',ones(4,1)),c2.sa.half2);
    assertEqual(repmat((1:4)',4,1),c2.sa.half1);

    i=7;
    assertElementsAlmostEqual(cxy(c2.sa.half1(i),c2.sa.half2(i)),...
                                        c2.samples(i));

    assertEqual({'half1','half2'},c2.a.sdim.labels);
    assertEqual({20+(1:4)',20+(1:4)'},c2.a.sdim.values);

    c4=cosmo_correlation_measure(ds3,'output','mean_by_fold');
    %
    for j=1:3
        train_idxs=(3-j)*4+(1:4);
        test_idxs=setdiff(1:12,train_idxs);

        ds_sel=ds3;
        ds_sel.sa.chunks(train_idxs)=2;
        ds_sel.sa.chunks(test_idxs)=1;

        c5=cosmo_correlation_measure(ds_sel,'output','mean');
        assertElementsAlmostEqual(c5.samples, c4.samples(j));
    end

    % test permutations
    ds4=cosmo_synthetic_dataset('nchunks',2,'ntargets',10);
    rp=randperm(20);

    ds4_perm=cosmo_slice(ds4,rp);
    assertEqual(cosmo_correlation_measure(ds4),...
                    cosmo_correlation_measure(ds4_perm));
    opt=struct();
    opt.output='correlation';
    assertEqual(cosmo_correlation_measure(ds4,opt),...
                    cosmo_correlation_measure(ds4_perm,opt));

function test_correlation_measure_single_target
    for ntargets=2:6
        ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',ntargets);
        ds.samples=randn(size(ds.samples));
        ds.sa.targets(:)=1;

        idxs=cosmo_index_unique(mod(ds.sa.chunks,2));
        assert(numel(idxs)==2);

        x=mean(ds.samples(idxs{1},:));
        y=mean(ds.samples(idxs{2},:));
        r_xy=atanh(corr(x',y'));

        r_ds=cosmo_correlation_measure(ds,'template',1);

        assertElementsAlmostEqual(r_xy, r_ds.samples);
    end




function test_correlation_measure_regression()
    helper_test_correlation_measure_regression(false);

function test_correlation_measure_regression_spearman()
    if cosmo_skip_test_if_no_external('@stats')
        return;
    end
    helper_test_correlation_measure_regression(true);

function helper_test_correlation_measure_regression(test_spearman)
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',5,'sigma',.5);
    params=get_regression_test_params(test_spearman);

    n_params=numel(params);
    for k=1:n_params
        param=params{k};

        args=param{1};
        samples=param{2};
        sa=param{3};
        sdim=param{4};
        res=cosmo_correlation_measure(ds,args{:});

        % test samples
        assertElementsAlmostEqual(res.samples,samples','absolute',5e-3);

        % test sa
        keys=fieldnames(res.sa);
        assertEqual(sort(keys(:)), sort(sa(1:2:end))');
        for j=1:2:numel(sa)
            key=sa{j};
            value=sa{j+1};
            assertEqual(res.sa.(key),value(:));
        end

        % test sa
        if isempty(sdim)
            assertFalse(isfield(res,'a'))
        else
            keys=fieldnames(res.a.sdim);
            assertEqual(sort(keys(:)), sort(sdim(1:2:end))');
            for j=1:2:numel(sa)
                key=sdim{j};
                value=sdim{j+1};
                sdim_value=res.a.sdim.(key);
                assertEqual(sdim_value(:),value(:));
            end
        end
    end

function params=get_regression_test_params(test_spearman)
    % contents
    % 1) input arguments
    % 2) samples
    % 3) sample attributes
    % 4) sdim
    if test_spearman
        params={{{ 'corr_type' 'Spearman' },...
                -0.228,...
                { 'labels' { 'corr' } },...
                []}};
    else
        params={{{ },...
                    -0.24,...
                    { 'labels' { 'corr' } },...
                    []},...
                {{ 'template' [ -2 2 -1 1 ] },...
                    1.21,...
                    { 'labels' { 'corr' } },...
                    []},...
                {{ 'merge_func' @(x)sum(abs(x),1) },...
                    0.567,...
                    { 'labels' { 'corr' } },...
                    []},...
                {{ 'post_corr_func' @(x)x+1 },...
                    -0.204,...
                    { 'labels' { 'corr' } },...
                    []},...
                {{ 'output' 'mean_by_fold' },...
                    [ -0.289 -0.274 -0.532 -0.112 -0.269 ...
                                -0.0535 -0.203 -0.3 -0.198 -0.173 ],...
                    { 'partition' [ 1 2 3 4 5 6 7 8 9 10 ] },...
                    []},...
                {{ 'output' 'correlation' },...
                    [ -0.649 0.0675 0.345 0.126 0.643 ...
                                 0.413 0.266 0.399 0.0933 ],...
                    { 'half1', [ 1 2 3 1 2 3 1 2 3 ],...
                                'half2' [ 1 1 1 2 2 2 3 3 3 ] },...
                    { 'labels' { 'half1' 'half2' },...
                                'values' { [ 1 2 3 ]' [ 1 2 3 ]' } }
                }};

    end



function test_correlation_measure_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_correlation_measure(varargin{:}),'');

    ds=cosmo_synthetic_dataset('nchunks',2);
    aet(ds,'template',eye(4));
    aet(ds,'output','foo');
    aet(ds,'output','one_minus_correlation');

    % single target throws exception
    ds.sa.targets(:)=1;
    aet(ds);
    aet(ds,'template',2);
    aet(ds,'template',eye(2));


    ds.sa.targets(1)=2;
    aet(ds);
