function test_suite=test_target_dsm_corr_measure
    initTestSuite;

function test_target_dsm_corr_measure_pearson
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    mat1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1);
    assertElementsAlmostEqual(dcm1.samples,0.2507,'absolute',1e-4);
    assertEqual(dcm1.sa.labels,{'rho'});
    assertEqual(dcm1.sa.metric,{'correlation'});
    assertEqual(dcm1.sa.type,{'Pearson'});

    distance_ds=cosmo_pdist(ds.samples,'correlation');
    assertElementsAlmostEqual(cosmo_corr(distance_ds',mat1'),dcm1.samples);

    sq1=cosmo_squareform(mat1);
    dcm2=cosmo_target_dsm_corr_measure(ds,'target_dsm',sq1);
    assertEqual(dcm1,dcm2);

    dcm3=cosmo_target_dsm_corr_measure(ds,'target_dsm',sq1,...
                                                'metric','euclidean');
    assertElementsAlmostEqual(dcm3.samples,0.3037,'absolute',1e-4);


function test_target_dsm_corr_measure_partial
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    mat1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];
    mat2=mat1(end:-1:1);

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                                'regress_dsm',mat2);
    assertElementsAlmostEqual(dcm1.samples,0.3082,'absolute',1e-4);


function test_target_dsm_corr_measure_partial_matlab_correspondence
    if cosmo_skip_test_if_no_external('@stats')
        return;
    end
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    vec1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];
    vec2=vec1(end:-1:1);

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',vec1,...
                                                'regress_dsm',vec2);
    distance=cosmo_pdist(ds.samples,'correlation');
    pcorr=partialcorr(distance',vec1',vec2');

    assertElementsAlmostEqual(dcm1.samples,pcorr);

    mat1=cosmo_squareform(vec1);
    mat2=cosmo_squareform(vec2);

    dcm2=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                                'regress_dsm',mat2);
    assertElementsAlmostEqual(dcm1.samples,dcm2.samples);

function test_target_dsm_corr_measure_partial_regression
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    vec1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];
    vec2=vec1(end:-1:1);

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',vec1,...
                                                'regress_dsm',vec2);
    assertElementsAlmostEqual(dcm1.samples,0.3082,'absolute',1e-4);
    mat1=cosmo_squareform(vec1);
    mat2=cosmo_squareform(vec2);

    dcm2=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                                'regress_dsm',mat2);
    assertElementsAlmostEqual(dcm1.samples,dcm2.samples);


function test_target_dsm_corr_measure_partial_no_correlation
    t=[0 1 0 0;
       0 0 -1 0;
       0 0 0 0;
       0 0 0 0];
    r=[0 0 1 0;
       0 0 0 0;
       0 0 0 0;
       0 0 0 0];

    t=t+t';
    r=r+r';

    msk=triu(ones(size(t)),1)>0;
    c=cosmo_corr(t(msk),r(msk));
    assertElementsAlmostEqual(c,0); % uncorrelated

    ds=cosmo_synthetic_dataset('nchunks',1,'ntargets',4);

    t_base=cosmo_target_dsm_corr_measure(ds,'target_dsm',t);
    t_regress=cosmo_target_dsm_corr_measure(ds,'target_dsm',t,...
                            'regress_dsm',r);


    assertElementsAlmostEqual(t_base.samples,-0.6615,'absolute',1e-4);
    assertElementsAlmostEqual(t_regress.samples,-0.7410,'absolute',1e-4);





function test_target_dsm_corr_measure_non_pearson
    % test non-Pearson correlations
    if cosmo_skip_test_if_no_external('@stats')
        return;
    end

    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    mat1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                                'type','Spearman');

    assertElementsAlmostEqual(dcm1.samples,0.2558,'absolute',1e-4);



% test exceptions
function test_target_dsm_corr_measure_exceptions
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    mat1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];

    aet=@(varargin)assertExceptionThrown(...
                @()cosmo_target_dsm_corr_measure(varargin{:}),'');
    aet(struct,mat1);
    aet(ds);
    aet(ds,'target_dsm',[mat1 1]);
    aet(ds,'target_dsm',eye(6));
    aet(ds,'target_dsm',zeros(7));


