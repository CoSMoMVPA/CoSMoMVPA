function test_suite=test_pca
% tests for cosmo_pca
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function [pca_samples,coef,mu,expl]=helper_cosmo_pca_wrapper(samples,...
                                                            keep_count)
    if isnan(keep_count)
        args={};
    else
        args={keep_count};
    end

    [pca_samples,params]=cosmo_pca(samples,args{:});
    coef=params.coef;
    mu=params.mu;
    expl=params.explained;

function [pca_samples,coef,mu,expl]=helper_matlab_pca_wrapper(samples,...
                                                            keep_count)
    % PCA implementation using Matlab statistics toolbox
    cosmo_check_external('!pca',true);

    if isnan(keep_count)
        args={};
    else
        args={'NumComponents',keep_count};
    end

    [coef,pca_samples,unused,unused,expl,mu]=pca(samples,args{:});
    expl=expl';



function test_pca_more_samples_than_features
    nsamples=ceil(rand()*10)+10;
    nfeatures=nsamples+10;

    nfeatures=5;
    nsamples=2;

    helper_test_pca_correspondence(nsamples,nfeatures)

function test_pca_more_features_than_samples
    nfeatures=ceil(rand()*10)+10;
    nsamples=nfeatures+10;

    helper_test_pca_correspondence(nsamples,nfeatures)

function test_pca_col_vector
    nfeatures=1;
    nsamples=ceil(rand()*10)+10;

    helper_test_pca_correspondence(nsamples,nfeatures)

function test_pca_row_vector
    nfeatures=ceil(rand()*10)+10;
    nsamples=1;

    helper_test_pca_correspondence(nsamples,nfeatures)


function test_pca_near_square_samples
    nfeatures=ceil(rand()*10)+10;
    for nsamples=nfeatures+(-1:1);
        helper_test_pca_correspondence(nsamples,nfeatures)
    end



function test_pca_too_many_components
    nsamples=ceil(rand()*10)+10;
    nfeatures=nsamples;
    for nkeep=nfeatures+(-1:1)
        handle=@()cosmo_pca(rand(nsamples,nfeatures),nkeep);
        if nkeep>nfeatures
            assertExceptionThrown(handle,'');
        else
            handle(); % should be ok
        end
    end

function test_pca_regression
    xs=[   2.032   -0.8918  -0.8258    1.163    1.157   -1.291   ;...
           0.5838   1.844    1.166    -0.8484   3.493   -0.1991  ;...
          -1.444   -0.2617  -1.921     3.085   -1.372    1.727   ;...
          -0.5177   2.339    0.4412    1.856    0.4794   0.08323 ;...
           1.191   -0.204   -0.2088    1.755   -0.9548   0.5012  ;...
          -1.326    2.724    0.1476    0.5024   3.407   -0.4803  ];

    s=[  -0.5008    2.8648   -0.7589   -0.5301    0.0144  ;...
          3.5030    0.5915    0.2537    0.8888    0.0226  ;...
         -3.8914   -1.6525   -0.7549    0.4558    0.0157  ;...
          0.1140   -1.3350    1.0615   -0.7253    0.0293  ;...
         -2.1851    1.0744    0.9553    0.2445   -0.0444  ;...
          2.9603   -1.5432   -0.7566   -0.3338   -0.0376];

    coef=[  0.0014    0.7569    0.3369   -0.0540    0.3234  ;...
            0.4052   -0.5164    0.4105   -0.3355   -0.0290  ;...
            0.3133    0.0275    0.6618    0.0901    0.1745  ;...
           -0.4294   -0.2190   -0.0420   -0.5306    0.6797  ;...
            0.7090    0.0436   -0.5070    0.0744    0.4815  ;...
           -0.2251   -0.3313    0.1456    0.7677    0.4127];

    mu=[0.0864    0.9248   -0.2001    1.2522    1.0349    0.0568];

    explained=[64.7794   26.0994    6.0071    3.1059    0.0082];

    for nkeep=[NaN,1:7]
        if isnan(nkeep)
            args={};
            ncomp=5;
        else
            args={nkeep};
            ncomp=min(nkeep,5);
        end


        if nkeep>6
            assertExceptionThrown(@()cosmo_pca(xs,args{:}),'');
        else
            [xs_pca,param]=cosmo_pca(xs,args{:});

            tolerance_arg={'absolute',5e-3};
            assertElementsAlmostEqual(xs_pca,s(:,1:ncomp),...
                                        tolerance_arg{:});

            expected_fieldnames={'coef','explained','mu'};
            assertEqual(sort(fieldnames(param)),...
                            sort(expected_fieldnames(:)));
            assertElementsAlmostEqual(param.coef,coef(:,1:ncomp),...
                                                tolerance_arg{:});
            assertElementsAlmostEqual(param.mu,mu,...
                                                tolerance_arg{:});
            assertElementsAlmostEqual(param.explained,explained,...
                                                tolerance_arg{:});

        end
    end


function test_pca_basic_properties
    nfeatures=ceil(rand()*10+10);
    nsamples=ceil(rand()*10+10)+nfeatures;

    x=randn(nsamples,nfeatures);
    [y,param]=cosmo_pca(x);

    % explained variance is on diagonal
    d=y'*y;
    assertElementsAlmostEqual(100*diag(d)/trace(d),param.explained');

    % components are orthogonal
    d_zero_diag=d-diag(diag(d));
    assertElementsAlmostEqual(d_zero_diag,zeros(nfeatures));

    % average is computed correctly
    assertElementsAlmostEqual(mean(x,1),param.mu);

    % x can be reconstructed
    assertElementsAlmostEqual(x,bsxfun(@plus,param.mu,y*param.coef'));

function test_pca_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_pca(varargin{:}),'');
    aet(struct);
    aet({1});
    aet(randn([2 2 2 ]));

function helper_test_pca_correspondence(nsamples,nfeatures)
    if cosmo_skip_test_if_no_external('!pca')
        return;
    end

    for nkeep=[NaN,-1,0,1,...
                ceil(nsamples/2),ceil(nfeatures/2),...
                nsamples-1,nfeatures-1,...
                nsamples,nfeatures,nsamples+1,nfeatures+1]
        helper_test_pca_correspondence_nkeep(nsamples,nfeatures,nkeep);
    end

function helper_test_pca_correspondence_nkeep(nsamples,nfeatures,nkeep)
    x=rand(nsamples,nfeatures);
    try
        % if the following statement throws an exception, then
        % matlab's pca must also throw an exception
        [p1,c1,m1,e1]=helper_matlab_pca_wrapper(x,nkeep);
    catch
        % cosmo pca should also throw error
        assertExceptionThrown(@()helper_cosmo_pca_wrapper(x,nkeep),'');
        return
    end

    % no error, verify that output match
    [p2,c2,m2,e2]=helper_cosmo_pca_wrapper(x,nkeep);

    tolerance_arg={'relative',1e-5};
    assertElementsAlmostEqual(p1,p2,tolerance_arg{:});
    assertElementsAlmostEqual(c1,c2,tolerance_arg{:});
    assertElementsAlmostEqual(m1,m2,tolerance_arg{:});
    assertElementsAlmostEqual(e1,e2,tolerance_arg{:});


function test_pca_retain_is_row_vector()
    nsamples=ceil(10+rand()*10);
    x=randn(nsamples);
    [y,params]=cosmo_pca(x);
    assertEqual(size(params.explained),[1 nsamples-1]);