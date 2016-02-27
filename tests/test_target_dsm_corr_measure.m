function test_suite=test_target_dsm_corr_measure
% tests for cosmo_target_dsm_corr_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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
    assertElementsAlmostEqual(dcm1.samples,dcm2.samples);
    dcm2.samples=dcm1.samples;
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


function test_target_dsm_corr_measure_glm_dsm
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    ds_vec_row=cosmo_pdist(ds.samples,'correlation');
    ds_vec=cosmo_normalize(ds_vec_row(:),'zscore');

    mat1=[1 2 3 4 2 3 2 1 2 3 1 2 3 2 2];
    mat2=mat1;
    mat2(1:10)=mat2(10:-1:1);

    nrows=numel(mat1);
    design_matrix=[cosmo_normalize([mat1',mat2'],'zscore'),ones(nrows,1)];

    betas=design_matrix \ ds_vec;

    dcm1=cosmo_target_dsm_corr_measure(ds,'glm_dsm',{mat1,mat2});

    assertElementsAlmostEqual(dcm1.samples,betas(1:2));
    assertElementsAlmostEqual(dcm1.samples,[0.3505;0.3994],...
                                    'absolute',1e-4);
    sa=cosmo_structjoin('labels',{'beta1';'beta2'},...
                            'metric',{'correlation';'correlation'});
    assertEqual(dcm1.sa,sa);

    mat2=cosmo_squareform(mat2);
    dcm2=cosmo_target_dsm_corr_measure(ds,'glm_dsm',{1+3*mat1,2*mat2});
    assertElementsAlmostEqual(dcm1.samples,dcm2.samples);
    assertEqual(dcm1.sa,dcm2.sa);

    dcm3=cosmo_target_dsm_corr_measure(ds,'glm_dsm',{mat2,mat1});
    assertElementsAlmostEqual(dcm1.samples([2 1],:), dcm3.samples);
    assertEqual(dcm1.sa,dcm3.sa);


function test_target_dsm_corr_measure_glm_dsm_matlab_correspondence
    if cosmo_skip_test_if_no_external('@stats')
        return;
    end
    ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
    ds.samples=randn(size(ds.samples));
    ds_vec_row=cosmo_pdist(ds.samples,'correlation');
    ds_vec=cosmo_normalize(ds_vec_row(:),'zscore');

    mat1=rand(1,15);
    mat2=rand(1,15);

    design_matrix=cosmo_normalize([mat1',mat2'],'zscore');

    beta=regress(ds_vec, design_matrix);
    ds_beta=cosmo_target_dsm_corr_measure(ds,'glm_dsm',{mat1,mat2});
    assertElementsAlmostEqual(beta, ds_beta.samples);

function test_target_dsm_random_data_with_cosmo_functions
    ntargets=ceil(rand()*5+3);
    nfeatures=ceil(rand()*20+30);

    ds=struct();
    ds.sa.targets=(1:ntargets)';
    ds.sa.chunks=ceil(rand()*10+3);

    % assume working pdist (tested elsewhere)
    target_dsm=cosmo_pdist(randn(ntargets,2*nfeatures));

    for center_data=[-1,0,1]

        ds.samples=randn(ntargets,nfeatures);
        samples=ds.samples;

        opt=struct();
        opt.target_dsm=target_dsm;
        if center_data>0
            opt.center_data=logical(center_data);

            if opt.center_data
                samples=bsxfun(@minus,samples,mean(samples,1));
            end
        end

        result=cosmo_target_dsm_corr_measure(ds,opt);

        c=1-cosmo_corr(samples');
        expected_samples=cosmo_corr(cosmo_squareform(c)',target_dsm');
        assertElementsAlmostEqual(result.samples,expected_samples)
    end






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

    aet(ds,'target_dsm',mat1,'glm_dsm',{mat1});
    aet(ds,'regress_dsm',mat1,'glm_dsm',{mat1});
    aet(ds,'target_dsm',mat1,'glm_dsm',repmat({mat1},15,1));
    aet(ds,'regress_dsm',mat1,'glm_dsm',repmat({mat1},15,1));
    aet(ds,'glm_dsm',struct());
    aet(ds,'glm_dsm',{[mat1 1]});

    mat2_ds=struct();
    mat2_ds.samples=mat1;

    % requires numeric input
    mat2_ds_rep=repmat({mat2_ds},1,15);
    mat2_ds_stacked=cat(1,mat2_ds_rep{:});
    aet(ds,'target_dsm',mat2_ds_stacked);




function test_target_dsm_corr_measure_warnings_zero()
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',1);

    ds_zero=ds;
    ds_zero.samples(:)=0;

    helper_target_dsm_corr_measure_with_warning(ds_zero,...
                                        'target_dsm',[1 2 3]);

function test_target_dsm_corr_measure_warnings_nan()
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',1);

    ds_zero=ds;
    ds_zero.samples(1)=NaN;

    helper_target_dsm_corr_measure_with_warning(ds_zero,...
                                        'target_dsm',[1 2 3]);

function test_target_dsm_corr_measure_warnings_constant()
    ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',1);

    ds_zero=ds;

    helper_target_dsm_corr_measure_with_warning(ds_zero,...
                                        'target_dsm',[0 0 0]);

function result=helper_target_dsm_corr_measure_with_warning(varargin)
    % ensure to reset to original state when leaving this function
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));

    % clear all warnings
    empty_state=warning_state;
    empty_state.shown_warnings={};
    cosmo_warning(empty_state);
    cosmo_warning('off');

    result=cosmo_target_dsm_corr_measure(varargin{:});
    w=cosmo_warning();
    assert(numel(w.shown_warnings)>0)
    assert(iscellstr(w.shown_warnings));






