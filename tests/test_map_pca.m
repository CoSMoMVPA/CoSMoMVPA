function test_suite=test_map_pca
% tests for cosmo_map_pca
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_map_pca_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_map_pca(varargin{:}),'');

    ds=cosmo_synthetic_dataset();
    pca_params=struct();
    pca_params.mu=[0.0864 0.9248 -0.2001 1.2522 1.0349 0.0568];
    pca_params.coef=[ 0.0014    0.7569    0.3369   -0.0540    0.3234;...
                      0.4052   -0.5164    0.4105   -0.3355   -0.0290;...
                      0.3133    0.0275    0.6618    0.0901    0.1745;...
                     -0.4294   -0.2190   -0.0420   -0.5306    0.6797;...
                      0.7090    0.0436   -0.5070    0.0744    0.4815;...
                     -0.2251   -0.3313    0.1456    0.7677    0.4127];
    pca_params.retain=true(1,5);

    % test mutually exclusive parameters
    aet(ds,'pca_params',pca_params,'pca_explained_count',3);
    aet(ds,'pca_explained_ratio',.5,'pca_explained_count',3);
    aet(ds,'pca_explained_ratio',.5,'pca_params',pca_params);

    % wrong size for coef
    bad_pca_params=pca_params;
    bad_pca_params.coef=1;
    aet(ds,'pca_params',bad_pca_params);

    % missing field
    bad_pca_params=pca_params;
    bad_pca_params=rmfield(bad_pca_params,'mu');
    aet(ds,'pca_params',bad_pca_params);

    % bad explained_count
    aet(ds,'pca_explained_count',-1);
    aet(ds,'pca_explained_count',1.5);
    aet(ds,'pca_explained_count',7);

    % bad explained ratio
    aet(ds,'pca_explained_ratio',-1);
    aet(ds,'pca_explained_ratio',-.001);
    aet(ds,'pca_explained_ratio',1.001);

function test_map_pca_max_feature_count_exceptions()
    default_max_feature_count=1000;

    nsamples=20;
    for max_feature_count=[NaN, ...
                            round(rand()*10+10), ...
                            default_max_feature_count]
        for delta=(-1:1)
            opt=struct();

            if isnan(max_feature_count)
                nfeatures=default_max_feature_count+delta;
            else
                nfeatures=max_feature_count+delta;
                opt.max_feature_count=max_feature_count;
            end

            data=randn(nsamples,nfeatures);

            expect_exception=delta>0;

            for use_struct=[false,true]
                if use_struct
                    ds=struct();
                    ds.samples=data;
                else
                    ds=data;
                end

                func_handle=@()cosmo_map_pca(ds,opt);

                if expect_exception
                    assertExceptionThrown(func_handle);
                else
                    % should not raise an exception
                    func_handle();
                end
            end
        end
    end




function test_map_pca_basics
    nfeatures=ceil(rand()*10+10);
    nsamples_train=ceil(rand()*10+10)+nfeatures;
    nsamples_test=ceil(rand()*10+10)+nfeatures;

    train_samples=randn(nsamples_train,nfeatures);
    test_samples=randn(nsamples_test,nfeatures);

    for count=[1 ceil(nfeatures/2) nfeatures ceil(rand()*nfeatures)]
        helper_test_map_pca_with_count(train_samples,...
                                                test_samples,count);
    end

    for ratio=[.1 .5 1 rand()]
        helper_test_map_pca_with_ratio(train_samples,...
                                                test_samples,ratio);
    end

    helper_test_map_pca_with_no_arguments(train_samples,...
                                                test_samples);

function helper_test_map_pca_with_ratio(train_samples,...
                                                test_samples,ratio)
    ratio_opt=struct();
    ratio_opt.pca_explained_ratio=ratio;

    % check that ratio and count give the same output
    [unused,param]=cosmo_pca(train_samples);
    count=find(cumsum(param.explained)>=ratio*100,1);
    if isempty(count)
        count=numel(param.explained);
    end

    count_opt=struct();
    count_opt.pca_explained_count=count;

    did_throw=true;
    try
        [samples_ratio,params_ratio]=cosmo_map_pca(train_samples,ratio_opt);
        did_throw=false;
    end

    if did_throw
        cosmo_map_pca(train_samples,count_opt)
        assertExceptionThrown(@()...
                cosmo_map_pca(train_samples,count_opt));
        assertExceptionThrown(@()...
                helper_test_dataset_samples_correspondence(train_samples,...
                                            ratio_opt));

    else
        [samples_count,params_count]=cosmo_map_pca(train_samples,...
                                            count_opt);

        assert_almost_equal(samples_ratio,samples_count);
        assert_almost_equal(params_ratio,params_count);

        % verify that raw samples and dataset structures give the same
        % result
        helper_test_dataset_samples_correspondence(train_samples,...
                                                    ratio_opt);
        helper_test_dataset_samples_correspondence(test_samples,...
                                                'pca_params',params_ratio);
    end

    % verify correct result by delegating to count
    if ~did_throw
        helper_test_map_pca_with_count(train_samples,test_samples,count);
    else
        assertExceptionThrown(@()...
            helper_test_map_pca_with_count(train_samples,test_samples,...
                                            count));
    end


function helper_test_map_pca_with_count(train_samples,test_samples,count)
    assert(numel(count)==1);
    opt=struct();
    opt.pca_explained_count=count;

    % do PCA in two ways; we assume that cosmo_pca works correctly, and
    % compare its result to cosmo_map_pca
    [ys,params]=cosmo_map_pca(train_samples,opt);
    [pca_samples,pca_params]=cosmo_pca(train_samples,count);

    assert_almost_equal(ys,pca_samples);

    % verify when using samples
    helper_test_dataset_samples_correspondence(train_samples, ...
                                    'pca_explained_count',count);

    % verify params
    expected_params=struct();
    expected_params.mu=pca_params.mu;
    expected_params.coef=pca_params.coef;
    nfeatures=size(train_samples,2);
    expected_params.retain=(1:nfeatures)<=count;
    assert_almost_equal(expected_params,params);


    [zs,params2]=cosmo_map_pca(test_samples,'pca_params',params);
    assertEqual(params2,params);

    expected_samples=bsxfun(@minus,test_samples,params.mu)*params.coef;
    assert_almost_equal(zs,expected_samples);

    helper_test_dataset_samples_correspondence(test_samples,...
                                'pca_params',params);


function helper_test_map_pca_with_no_arguments(train_samples,test_samples)
    [ys,params]=cosmo_map_pca(train_samples);

    count=size(train_samples,2);
    [ys_count,params_count]=cosmo_map_pca(train_samples,...
                                    'pca_explained_count',count);
    assert_almost_equal(ys,ys_count);
    assert_almost_equal(params,params_count);

    helper_test_dataset_samples_correspondence(train_samples);
    helper_test_dataset_samples_correspondence(test_samples,...
                                            'pca_params',params);



function helper_test_dataset_samples_correspondence(samples, varargin)
    ds=struct();
    ds.samples=samples;

    [result_ds,param_ds]=cosmo_map_pca(ds,varargin{:});
    [result,param]=cosmo_map_pca(samples,varargin{:});

    % verify that output is the same
    expected_ds=struct();
    expected_ds.samples=result;

    expected_ds.fa.comp=1:size(result,2);
    expected_ds.a.fdim.labels={'comp'};
    expected_ds.a.fdim.values={1:size(samples,2)};

    assert_almost_equal(expected_ds,result_ds);

    % parameters must be identical
    assert_almost_equal(param_ds,param);


function assert_almost_equal(x,y,msg,tol)
    % helper that supports structs recursively
    if nargin<4
        tol=1e-5;
    end
    if nargin<3
        msg='';
    end

    if isstruct(x)
        assertTrue(isstruct(y),[msg ' - x is a struct but y is not']);

        fns=fieldnames(x);
        assertEqual(sort(fns),sort(fieldnames(y)),...
                                    [msg ' - fieldname mismatch'])

        n=numel(fns);
        for k=1:n
            fn=fns{k};

            assert_almost_equal(x.(fn),y.(fn),...
                            sprintf('%s - mismatch for field %s',msg,fn))
        end

    elseif iscell(x) && iscell(y)
        assertEqual(size(x),size(y),[msg ' - cell size mismatch']);
        for k=1:numel(x)
            assert_almost_equal(x{k},y{k},...
                        sprintf(' - cell element %d different',k));
        end
    elseif ischar(x) && ischar(y)
        assertEqual(x,y,sprintf('%s - %s ~= %s',msg,x,y));
    elseif islogical(x) && islogical(y)
        assertEqual(x,y,sprintf('%s - boolean array mismatch',msg));
    elseif isnumeric(x) && isnumeric(y)
        if isempty(x) && isempty(y)
            return;
        end
        assertElementsAlmostEqual(x,y,'absolute',tol,[msg ' - different']);
    else
        error('unsupported data type');
    end


function test_pca_map_ratio_unity()
    sizes=[4,10;...
           10,4;...
           4,4];

    for k=size(sizes,1);
        sz=sizes(k,:);
        samples=randn(sz);
        [xs,params]=cosmo_map_pca(samples,'pca_explained_ratio',1);

        assertEqual(params.retain,true(1,sz(end)-1));
    end
