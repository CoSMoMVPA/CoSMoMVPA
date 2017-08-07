function test_suite=test_normalize
% tests for cosmo_normalize
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_normalize_basics()

    aoe=@(x,y)assertElementsAlmostEqual(x,y,'absolute',1e-3);

    ds=struct();
    ds.samples=reshape(1:15,5,3)*2;

    % demean along first dimension
    dsn=cosmo_normalize(ds,'demean',1);
    aoe(dsn.samples,   [ -4        -4        -4;...
                         -2        -2        -2;...
                          0         0         0;...
                          2         2         2;...
                          4         4         4 ]);

    dsn2=cosmo_normalize(ds,'demean');
    aoe(dsn.samples,dsn2.samples);

    % demean along second dimension
    dsn=cosmo_normalize(ds,'demean',2);
    aoe(dsn.samples, [ -10         0        10;...
                        -10         0        10;...
                        -10         0        10;...
                        -10         0        10;...
                        -10         0        10 ]);

    %
    % scale to range [-1,1] alnog first dimension
    dsn=cosmo_normalize(ds,'scale_unit',1);
    aoe(dsn.samples, [   -1        -1        -1;...
                        -0.5      -0.5      -0.5;...
                           0         0         0;...
                         0.5      0.5       0.5;...
                           1         1         1 ]);
    dsn2=cosmo_normalize(ds,'scale_unit');
    aoe(dsn.samples,dsn2.samples);

    % z-score along first dimension
    dsn=cosmo_normalize(ds,'zscore',1);
    aoe(dsn.samples, [  -1.2649     -1.2649     -1.2649;...
                        -0.6325    -0.6325    -0.632;...
                             0         0         0;...
                         0.6325     0.6325     0.6325;...
                          1.2649      1.2649      1.2649 ]);
    dsn2=cosmo_normalize(ds,'zscore');
    aoe(dsn.samples,dsn2.samples);

    % z-score along second dimension
    dsn=cosmo_normalize(ds,'zscore',2);
    aoe(dsn.samples, [ -1         0         1;...
                        -1         0         1;...
                        -1         0         1;...
                        -1         0         1;...
                        -1         0         1 ])
    %
    % use samples 1, 3, and 4 to estimate parameters ('training set'),
    % and apply these to samples 2 and 5
    ds_train=cosmo_slice(ds,[1 3 4]);
    ds_test=cosmo_slice(ds,[2 5]);
    [dsn_train,params]=cosmo_normalize(ds_train,'scale_unit', 1);
    aoe(dsn_train.samples, [    -1        -1        -1;...
                                    0.3333     0.3333     0.3333;...
                                        1         1         1 ])
    p.method='scale_unit';
    p.dim=1;
    p.min=[ 2        12        22 ];
    p.max=[ 8        18        28 ];
    assertEqual(params,p);
    %
    % apply parameters to test dataset
    dsn_test=cosmo_normalize(ds_test,params);
    aoe(dsn_test.samples,[ -0.3333    -0.33333    -0.33333;...
                            1.6667      1.6667    1.6667 ]);



    [tr,params]=cosmo_normalize(zeros(4,0),'zscore');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    [tr,params]=cosmo_normalize(zeros(4,0),'demean');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    [tr,params]=cosmo_normalize(zeros(4,0),'scale_unit');
    te=cosmo_normalize(zeros(2,0),params);
    assertEqual(tr,zeros(4,0));
    assertEqual(te,zeros(2,0));

    dsn=cosmo_normalize(ds,'');
    assertEqual(dsn,ds);

    warning_state=cosmo_warning();
    warning_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    ds.samples(1,1)=NaN;
    dsn=cosmo_normalize(ds,'zscore');
    assert(all(isnan(dsn.samples(:,1))));
    assert(all(all(~isnan(dsn.samples(:,2:3)))));


function test_normalize_random_data_train

    dim_opt=struct();
    dim_opt.dim={[],1,2};
    dim_opt.method={'zscore','demean','scale_unit'};

    combis=cosmo_cartprod(dim_opt);
    for k=1:numel(combis)
        opt=combis{k};

        method=opt.method;
        args={method};
        if isempty(opt.dim)
            dim=1;
        else
            dim=opt.dim;
            args{end+1}=dim;
        end

        nsamples=ceil(rand()*10+10);
        nfeatures=ceil(rand()*10+10)+nsamples;

        samples=randn(nsamples,nfeatures);

        ds=struct();
        ds.samples=samples;
        ds.sa.targets=1+mod(cosmo_randperm(nsamples),3)';

        [res_ds,res_param]=cosmo_normalize(ds,args{:});

        mu=mean(samples,dim);
        sd=std(samples,[],dim);

        expected_param=struct();
        expected_param.dim=dim;
        expected_param.method=method;

        switch method
            case 'demean'
                expected_samples=bsxfun(@minus,samples,mu);
                expected_param.mu=mu;


            case 'zscore'
                expected_samples=bsxfun(@rdivide,...
                                bsxfun(@minus,samples,mu),sd);
                expected_param.mu=mu;
                expected_param.sigma=sd;

            case 'scale_unit'
                mn=min(samples,[],dim);
                mx=max(samples,[],dim);
                delta=mx-mn;

                expected_samples=bsxfun(@rdivide,...
                                bsxfun(@minus,samples,mn),delta)*2-1;

                expected_param.min=mn;
                expected_param.max=mx;

            otherwise
                assert(false);

        end

        assertElementsAlmostEqual(res_ds.samples,expected_samples);
        assert_struct_almost_equal(res_param,expected_param);

        % new dataset, apply parameters
        samples=randn(size(samples));
        ds.samples=samples;
        ds.sa.targets=1+mod(cosmo_randperm(nsamples),3)';

        [res2_ds,res2_param]=cosmo_normalize(ds,res_param);

        switch method
            case 'demean'
                expected_samples=bsxfun(@minus,samples,mu);

            case 'zscore'
                expected_samples=bsxfun(@rdivide,...
                                bsxfun(@minus,samples,mu),sd);

            case 'scale_unit'
                expected_samples=bsxfun(@rdivide,...
                                bsxfun(@minus,samples,mn),delta)*2-1;

            otherwise
                assert(false);
        end

        assertElementsAlmostEqual(res2_ds.samples,expected_samples);
        assert_struct_almost_equal(res2_param,res_param);
    end


function assert_struct_almost_equal(x,y)
    keys=fieldnames(x);
    assertEqual(sort(keys),sort(fieldnames(y)))

    for k=1:numel(keys)
        key=keys{k};
        v=x.(key);
        w=y.(key);

        if isnumeric(v)
            func=@assertElementsAlmostEqual;
        else
            func=@assertEqual;
        end

        func(v,w);
    end


function test_normalize_exceptions()
    ds=cosmo_synthetic_dataset();
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_normalize(ds,varargin{:}),'');

    aet('zscore3');
    aet('zscore2');
    aet('zscore1');
    aet('foo');
    aet('zscore1',1);
    aet('zscore1',2);

    % bad dimension
    [unused,params]=cosmo_normalize(ds,'zscore',1);
    aet(params,2);

    aet(params,2);
    bad_params=params;
    bad_params.dim=2;
    aet(bad_params,1);

    % illegal second input
    aet({'foo'});



