function test_suite=test_mask_dim_intersect
% tests for test_mask_dim_intersect
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_mask_dim_intersect_feature_dim()
    helper_test_mask_dim_intersect(2)

function test_mask_dim_intersect_sample_dim()
    helper_test_mask_dim_intersect(1)


function helper_test_mask_dim_intersect(dim)
    other_dim=3-dim;

    n_ds=ceil(rand()*2+2);
    keep_ratio=.8;

    ds_cell=cell(n_ds,1);
    for k=1:n_ds
        if dim==1
            % optimalization due to somewhat slow dim_transpose
            sz='small';
        else
            sz='big';
        end

        ds=cosmo_synthetic_dataset('size',sz,'seed',0,...
                                    'nchunks',1,'ntargets',1);
        n_features=size(ds.samples,2);
        ds.samples=1:n_features;

        rp=randperm(n_features);
        keep_indices=round(1:(keep_ratio*n_features));

        ds_keep=cosmo_slice(ds,rp(keep_indices),2);

        if dim==1
            ds_keep=cosmo_dim_transpose(ds_keep,ds.a.fdim.labels,1);
        end

        ds_indices=ds_keep;

        % fill with random data so that the function to test cannot
        % use the indices
        ds_data=ds_keep;
        ds_data.samples=randn(size(ds_keep.samples));

        % the first row has random data, and is used as input for %
        % cosmo_mask_dim_intersect; the second row has indices, and is
        % used to verify the proper contents of the datasets
        ds_cell{k}=cosmo_stack({ds_data,ds_indices},other_dim);
    end


    ds_data_cell=cellfun(@(x)cosmo_slice(x,1,other_dim),ds_cell,...
                            'UniformOutput',false);

    [indices,ds_intersect_cell]=cosmo_mask_dim_intersect(ds_data_cell,dim);

    if dim==2
        % must have same output using default second argument
        [indices2,ds_intersect_cell2]=cosmo_mask_dim_intersect(...
                                            ds_data_cell);

        assertEqual(indices,indices2);
        assertEqual(ds_intersect_cell,ds_intersect_cell2);
    end

    % verify ds_intersect_cell based on indices
    assert(iscell(ds_intersect_cell));
    assertEqual(size(ds_intersect_cell),size(ds_data_cell));
    for k=1:n_ds
        idx=indices{k};
        assert(all(idx>0));
        assert(all(isfinite(idx)));
        assertEqual(cosmo_slice(ds_data_cell{k},idx,dim),...
                                ds_intersect_cell{k})
    end


    ds_indices_cell=cellfun(@(x)cosmo_slice(x,2,other_dim),ds_cell,...
                            'UniformOutput',false);

    % see which indices are common across all datasets
    ds_keep_indices=1:n_features;
    for k=1:n_ds
        ds_idx=ds_indices_cell{k}.samples;
        assertEqual(sort(ds_idx),unique(ds_idx));
        ds_keep_indices=intersect(ds_keep_indices, ds_idx);
    end

    % verify that indices match across all datasets
    for k=1:n_ds
        % select indices
        idx=ds_indices_cell{k}.samples(indices{k});

        % indices must be unique
        if isempty(idx)
            assert(isempty(ds_keep_indices));
        else
            assertEqual(sort(idx(:)),sort(ds_keep_indices(:)));
        end

        % must return indices in the same order
        ds_sel=cosmo_slice(ds_indices_cell{k},indices{k},dim);
        if k==1
            first_ds_sel=ds_sel;
        else
            assertEqual(first_ds_sel,ds_sel)
        end
    end

function test_mask_dim_intersect_identity
    % after permuting the features, dataset should be identical following
    % unpermuting them

    types={'fmri','surface','source','timelock','timefreq'};

    for k=1:numel(types)
        type=types{k};
        ds=cosmo_synthetic_dataset('size','big','type',type,...
                                        'ntargets',1,'nchunks',1);

        switch type
            case 'source'
                args={'matrix_labels',{'pos'}};
            otherwise
                args={};
        end
        n_features=size(ds.samples,2);
        ds.samples(1,:)=1:n_features;

        rp=randperm(n_features);
        ds=cosmo_slice(ds,rp,2);

        [indices_cell,ds_cell]=cosmo_mask_dim_intersect({ds},2,args{:});
        assert(numel(indices_cell)==1);
        assert(numel(ds_cell)==1);

        idx=indices_cell{1};
        ds_perm=ds_cell{1};

        assertEqual(sort(idx),1:n_features);
        ds_reordered=cosmo_slice(ds,idx,2);
        assertEqual(ds_perm,ds_reordered);

        % indices must be sorted
        assertEqual(ds_perm.samples,1:n_features);

    end


function test_mask_dim_intersect_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_mask_dim_intersect(varargin{:}),'');
    % cannot deal with empty
    aet(cosmo_synthetic_dataset());

    % input must be a cell with datasets
    aet(struct);
    aet('foo');
    aet({struct,struct});

    % repeated features not supported
    ds=cosmo_synthetic_dataset('size','big');
    ds2=cosmo_stack({ds,ds},2);
    aet({ds2});

    % not even a single feature duplicated is allowed
    col_index=ceil(rand()*size(ds.samples,2));
    ds_extra_col=cosmo_stack({ds,cosmo_slice(ds,col_index,2)},2);
    aet(ds_extra_col);

    % dim must be 1 or 2
    aet({ds},3);
    aet({ds},struct);
    aet({ds},[1 2]);

function test_mask_dim_intersect_missing_dim()
    ds1=cosmo_synthetic_dataset();
    ds2=ds1;
    ds2.fa=rmfield(ds2.fa,'k');

    assertEqual(ds1.samples,ds2.samples);
    assertExceptionThrown(@()cosmo_mask_dim_intersect({ds1,ds2}),'');

function test_mask_dim_intersect_nonmatching_dim()
    ds1=cosmo_synthetic_dataset();
    ds2=ds1;
    ds2=cosmo_dim_remove(ds2,'k');

    assertEqual(ds1.samples,ds2.samples);
    assertExceptionThrown(@()cosmo_mask_dim_intersect({ds1,ds2}),'');

function test_mask_dim_intersect_renamed_dim()
    ds1=cosmo_synthetic_dataset();
    ds2=ds1;
    ds2=cosmo_dim_rename(ds2,'k','kk');

    assertEqual(ds1.samples,ds2.samples);
    assertExceptionThrown(@()cosmo_mask_dim_intersect({ds1,ds2}),'');
