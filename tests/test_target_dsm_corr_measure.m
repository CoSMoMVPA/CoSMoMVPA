function test_suite=test_target_dsm_corr_measure
% tests for cosmo_target_dsm_corr_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
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


function test_target_dsm_corr_measure_partial_vector_partialcorr
    if cosmo_skip_test_if_no_external('!partialcorr')
        return;
    end
    ntargets=ceil(rand()*6+6);

    ds=cosmo_synthetic_dataset('ntargets',ntargets,'nchunks',1);
    ds.samples(:,:)=randn(size(ds.samples));

    ncombi=ntargets*(ntargets-1)/2;
    vec1=randn(1,ncombi);
    vec2=randn(1,ncombi);

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

    dcm1_s=cosmo_target_dsm_corr_measure(ds,'target_dsm',vec1,...
                                                'regress_dsm',vec2,...
                                                'type','Spearman');
    pcorr_s=partialcorr(distance',vec1',vec2','type','Spearman');

    assertElementsAlmostEqual(dcm1_s.samples,pcorr_s);

    dcm2_s=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                                'regress_dsm',mat2,...
                                                'type','Spearman');
    assertElementsAlmostEqual(dcm1_s.samples,dcm2_s.samples);


function test_target_dsm_corr_measure_partial_cell_partialcorr
    if cosmo_skip_test_if_no_external('!partialcorr')
        return;
    end
    ntargets=ceil(rand()*6+6);
    ds=cosmo_synthetic_dataset('ntargets',ntargets,'nchunks',1);
    ds.samples(:,:)=randn(size(ds.samples));

    ncombi=ntargets*(ntargets-1)/2;
    vec1=randn(1,ncombi);

    % set up regression elements
    n_regress=ceil(rand()*5+3);
    regress_vec_cell=cell(1,n_regress);
    regress_mx=zeros(ncombi,n_regress);
    for k=1:n_regress
        v=randn(1,ncombi);
        regress_vec_cell{k}=v;
        regress_mx(:,k)=v;
    end

    dcm1=cosmo_target_dsm_corr_measure(ds,'target_dsm',vec1,...
                                           'regress_dsm',regress_vec_cell);
    distance=cosmo_pdist(ds.samples,'correlation');
    pcorr=partialcorr(distance',vec1',regress_mx);

    assertElementsAlmostEqual(dcm1.samples,pcorr);

    mat1=cosmo_squareform(vec1);

    regress_mx_cell=cell(size(regress_vec_cell));
    for k=1:n_regress
        regress_mx_cell{k}=squareform(regress_vec_cell{k});
    end

    dcm2=cosmo_target_dsm_corr_measure(ds,'target_dsm',mat1,...
                                            'regress_dsm',regress_mx_cell);
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
    ntargets=ceil(rand()*5+5);
    nfeatures=ceil(rand()*20+30);

    ds=struct();
    ds.sa.targets=(1:ntargets)';
    ds.sa.chunks=ceil(rand()*10+3);

    % assume working pdist (tested elsewhere)
    make_rand_dsm=@()cosmo_pdist(randn(ntargets,2*nfeatures));
    target_dsm=make_rand_dsm();
    glm_dsm={make_rand_dsm(),make_rand_dsm(),make_rand_dsm()};

    for num_glms=0:numel(glm_dsm)
        for center_data=[-1,0,1]
            for use_mask=[-1,0,1]
                ds.samples=randn(ntargets,nfeatures);
                samples=ds.samples;

                opt=struct();

                % optionally, center data
                if center_data>0
                    opt.center_data=logical(center_data);

                    if opt.center_data
                        samples=bsxfun(@minus,samples,mean(samples,1));
                    end
                end

                % compute pdist for samples
                c=cosmo_squareform(1-cosmo_corr(samples'));
                n_pairs=numel(c);
                if use_mask>0
                    while true
                        msk=rand(n_pairs,1)>.5;

                        if sum(msk)>3
                            break;
                        end
                    end
                else
                    msk=true(n_pairs,1);
                end

                if num_glms==0
                    opt.target_dsm=target_dsm;
                    opt.target_dsm(~msk)=NaN;
                    expected_samples=cosmo_corr(c(msk)',...
                                            opt.target_dsm(msk)');
                else
                    opt.glm_dsm=glm_dsm(1:num_glms);
                    for k=1:num_glms
                        opt.glm_dsm{k}(~msk)=NaN;
                    end

                    glm_mat=cat(1,opt.glm_dsm{:})';
                    glm_z=helper_quick_zscore(glm_mat(msk,:));
                    c_z=helper_quick_zscore(c(msk)');
                    expected_samples=glm_z \ c_z;
                end

                result=cosmo_target_dsm_corr_measure(ds,opt);
                assertElementsAlmostEqual(result.samples,expected_samples)
            end
        end
    end



function mat_z=helper_quick_zscore(mat)
    mat_c=bsxfun(@minus,mat,mean(mat,1));
    mat_z=bsxfun(@rdivide,mat_c,std(mat_c,[],1));


function test_target_dsm_corr_measure_mask_exceptions
    ntargets=6;
    ds=cosmo_synthetic_dataset('ntargets',ntargets,'nchunks',1);

    npairs=ntargets*(ntargets-1)/2;
    for num_non_nan=4:npairs
        nan_msk=true(npairs,1);
        rp=randperm(npairs);
        nan_msk(rp(1:num_non_nan))=false;

        for num_glms=-1:3
            opt=struct();

            if num_glms==-1
                opt.regress_dsm=randn(npairs,1);
                opt.regress_dsm(nan_msk)=NaN;
            end

            if num_glms<=0
                opt.target_dsm=randn(npairs,1);
                opt.target_dsm(nan_msk)=NaN;
            else
                opt.glm_dsm=cell(num_glms,1);
                for k=1:num_glms
                    opt.glm_dsm{k}=randn(npairs,1);
                    opt.glm_dsm{k}(nan_msk)=NaN;
                end
            end

            for set_inconsistent_non_nan_msk=[false,true]
                key_cell=intersect(fieldnames(opt),...
                                    {'glm_dsm','regress_dsm'});

                if set_inconsistent_non_nan_msk && ...
                            (isempty(key_cell) || any(num_glms==[0,1]))
                    % skip
                    continue;
                end

                if set_inconsistent_non_nan_msk
                    assert(numel(key_cell)==1);
                    key=key_cell{1};

                    % swap true and false value in one of the matrices

                    value=opt.(key);

                    value_is_cell=iscell(value);
                    if value_is_cell
                        glm_idx=num_glms;
                        value=value{glm_idx};
                    end

                    i=find(isnan(value),1);
                    j=find(~isnan(value),1);

                    value(i)=value(j);
                    value(j)=NaN;

                    if value_is_cell
                        opt.(key){glm_idx}=value;
                    else
                        opt.(key)=value;
                    end
                end

                func_handle=@()cosmo_target_dsm_corr_measure(ds,opt);

                expect_error=set_inconsistent_non_nan_msk;
                if expect_error
                    assertExceptionThrown(func_handle,'');
                else
                    % should be ok
                    func_handle();
                end
            end
        end
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

    % illegal correlation type
    aet(ds,'target_dsm',mat1,'type','foo');
    aet(ds,'target_dsm',mat1,'type',2);

    % Spearman or Kendall not allowed when using glm_dsm
    aet(ds,'glm_dsm',mat1,'type','Spearman');
    aet(ds,'glm_dsm',mat1,'type','Kendall');

    % Kendall not allowed with regress_dsm
    aet(ds,'target_dsm',mat1,'regress_dsm',{mat1},'type','Kendall');


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






