function ds=cosmo_fmri_dataset(filename, varargin)
% load an fmri volumetric dataset
%
% ds = cosmo_fmri_dataset(filename, [,'mask',mask],...
%                                   ['targets',targets],...
%                                   ['chunks',chunks])
%
% Inputs:
%   filename     One of:
%                * filename of fMRI dataset, it should end with one of:
%                   .nii, .nii.gz                   NIfTI
%                   .hdr, .img                      ANALYZE
%                   +{orig,tlrc}.{HEAD,BRIK[.gz]}   AFNI
%                   .vmr, .vmp, .vtc, .glm, .msk    BrainVoyager
%                   .mat                            SPM (SPM.mat)
%                   .mat:beta                       SPM beta
%                   .mat:con                        SPM contrast
%                   .mat:spm                        SPM stats
%                   .mat                            Matlab file with
%                                                   CoSMoMVPA dataset
%                * xff structure (from neuroelf's xff)
%                * nifti structure (from load_untouch_nii)
%                * FieldTrip source MEEG structure
%                * SPM structure
%                * CoSMoMVPA fMRI or MEEG source dataset structure
%   'mask', m    Any input as for filename (in which case the output must
%                contain a single volume), or one of:
%                   '-all'     exclude features where all values are
%                              zero or NaN
%                   '-any'     exclude features where any value is
%                              zero or NaN
%                   '-auto'    require that '-all' and '-any' exclude the
%                              same features, and exclude the
%                              corresponding features
%                   true       equivalent to '-auto'
%                   false      do not apply a mask
%                The mask must have voxels at the same coordinates as the
%                data indicated by filename, although it may
%                have a different orientation (e.g. RAI, LPI, AIR).
%                Only voxels that are non-zero and not NaN are selected
%                from the data indicated by filename.
%                If 'mask' is not given, then no mask is applied and a
%                warning message (suggesting to use a mask) is printed if
%                at least 5% of the values are non{zero,finite}.
%   'targets', t optional Tx1 numeric labels of experimental
%                conditions (where T is the number of samples (volumes)
%                in the dataset)
%   'chunks, c   optional Tx1 numeric labels of chunks, typically indices
%                of runs of data acquisition
%   'volumes', v optional vector with indices of volumes to load. If
%                empty or not provided, then all volumes are loaded.
%   'block_size', b  optional block size by which data is read (if
%                supported by the format; currently NIfTI, ANALYZE, AFNI
%                and SPM. If this option is provided *and* a mask is
%                provided, then data is loaded in chunks (subsets of
%                volumes) that contain at most block_size elements each;
%                only data that survives the mask is then selected before
%                the next block is loaded.
%                The default value is 20,000,000, corresponding to ~160
%                megabytes of memory required for a block (using
%                numbers with double (64 bit) precsision).
%                The rationale for this option is to reduce memory
%                requirements, at the expensive of a possible increase of
%                duration of disk reading operations.
%
%
% Returns:
%   ds           dataset struct with the following fields:
%     .samples   NxM matrix containing the data loaded from filename, for
%                N samples (observations, volumes) and M features (spatial
%                locations, voxels).
%                If the original nifti file contained data with X,Y,Z,T
%                elements in the three spatial and one temporal dimension
%                and no mask was applied, then .samples will have
%                dimensions N x M, where N = T and M = X*Y*Z. If a mask
%                was applied then M (M<=X*Y*Z) is the number of non-zero
%                voxels in the  mask input dataset.
%     .a         struct with dataset-relevent data.
%     .a.fdim.labels   dimension labels, set to {'i','j','k'}
%     .a.fdim.values   dimension values, set to {1:X, 1:Y, 1:Z}
%     .a.vol.dim 1x3 vector indicating the number of voxels in the 3
%                spatial dimensions.
%     .a.vol.mat 4x4 voxel-to-world transformation matrix (base-1).
%     .a.vol.dim 1x3 number of voxels in each spatial dimension
%     .sa        struct for holding sample attributes (e.g., sa.targets,
%                sa.chunks)
%     .fa        struct for holding feature attributes
%     .fa.{i,j,k} indices of voxels (in voxel space).
%
% Notes:
%  - Most MVPA applications require that .sa.targets (experimental
%    condition of each sample) and .sa.chunks (partitioning of the samples
%    in independent sets) are set, either by using this function or
%    manually afterwards.
%  - Data can be mapped to the volume using cosmo_map2fmri
%  - SPM data can also be specified as filename:format, where format
%    can be 'beta', 'con' or 'spm' (e.g. 'SPM.mat:beta', 'SPM.mat:con', or
%    'SPM.mat:spm') to load beta, contrast, or statistic images,
%    respectively. When using 'beta', estimates for motion parameters and
%    intercepts (which in most cases are estimates of no interest) are
%    not returned. If format is omitted it is set to 'beta'.
%  - If SPM data contains a field .Sess (session) then .sa.chunks are set
%    according to its contents
%  - If a mask is supplied, then all features that are in the mask are
%    returned, even if some voxels contain NaN. To remove such features,
%    consider applying cosmo_remove_useless_data to the output of this
%    function.
%
% Dependencies:
% -  for NIfTI, analyze (.hdr/.img) and SPM.mat files, it requires the
%    NIfTI toolbox by Jimmy Shen
%    (note that his toolbox is included in CoSMoMVPA in /externals)
% -  for Brainvoyager files (.vmp, .vtc, .msk, .glm), it requires the
%    NeuroElf toolbox, available from: http://neuroelf.net
% -  for AFNI files (+{orig,tlrc}.{HEAD,BRIK[.gz]}) it requires the AFNI
%    Matlab toolbox, available from: https://github.com/afni/AFNI
%
% Examples:
%     % load nifti file
%     ds=fmri_dataset('mydata.nii');
%
%     % load gzipped nifti file
%     ds=fmri_dataset('mydata.nii.gz');
%
%     % load ANALYZE file and apply brain mask
%     ds=fmri_dataset('mydata.hdr','mask','brain_mask.hdr');
%
%     % load AFNI file with 6 'bricks' (values per voxel, e.g. beta
%     % values); set chunks (e.g. runs) and targets (experimental
%     % conditions); use a mask
%     ds=fmri_dataset('mydata+tlrc', 'chunks', [1 1 1 2 2 2]', ...
%                                     'targets', [1 2 3 1 2 3]', ...
%                                     'mask', 'masks/brain_mask+tlrc);
%
%     % load BrainVoyager VMR file in directory 'mydata', and apply an
%     % automask that removes all features (voxels) that are zero or
%     % non-finite for all samples
%     ds=fmri_dataset('mydata/mydata.vmr', 'mask', true);
%
%     % load two datasets, one for odd runs, the other for even runs, and
%     % combine them into one dataset. Note that the chunks are set here,
%     % but the targets are not - for subsequent analyses this may have to
%     % be done manually
%     ds_even=fmri_dataset('data_even_runs.glm','chunks',1);
%     ds_odd=fmri_dataset('data_odd_runs.glm','chunks',2);
%     ds=cosmo_stack({ds_even,ds_odd});
%
%     % load beta values from SPM GLM analysis stored
%     % in a file SPM.mat.
%     % If SPM.mat contains a field .Sess (sessions) then .sa.chunks
%     % is set according to the contents of .Sess.
%     ds=cosmo_fmri_dataset('path/to/SPM.mat');
%
%     % as above, and apply an automask to remove voxels that
%     % are zero or non-finite in all samples.
%     ds=cosmo_fmri_dataset('path/to/SPM.mat','mask',true);
%
%     % load contrast beta values from SPM GLM file SPM.mat
%     ds=cosmo_fmri_dataset('path/to/SPM.mat:con');
%
%     % load contrast statistic values from SPM GLM file SPM.mat
%     ds=cosmo_fmri_dataset('path/to/SPM.mat:spm');
%
% See also: cosmo_map2fmri
%
% part of the NIfTI code is based on code by Robert W Cox, 2003,
% dedicated to the public domain.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % set defaults
    defaults.mask=[];
    defaults.targets=[];
    defaults.chunks=[];
    defaults.volumes=[];
    defaults.block_size=2e7;

    % set parameters
    params = cosmo_structjoin(defaults, varargin{:});


    % create dataset from filename
    ds=convert_to_dataset(filename, params);

    % set chunks and targets
    ds=set_sa_vec(ds,params,'targets');
    ds=set_sa_vec(ds,params,'chunks');

    if param_specifies_auto_mask(params)
        auto_mask=compute_auto_mask(ds.samples, params.mask);
        ds=cosmo_slice(ds,auto_mask,2);
    else
        warn_if_nan_present_in_dataset(ds)
    end




function ds_all=convert_to_dataset(fn, params)
    % main data reader function

    if string_endswith(fn,'.mat')
        data=fast_import_data(fn);
    else
        data=fn;
    end

    img_formats_collection=get_img_formats;
    label=find_img_format(data, img_formats_collection);
    img_format=img_formats_collection.(label);

    % make sure the required externals exists
    externals=img_format.externals;
    cosmo_check_external(externals);

    % get the helper functions for this format
    data_converter=img_format.data_converter;
    has_data_reader=isfield(img_format,'data_reader');

    % verify the input
    input_is_filename=~img_format.matcher(data);
    if input_is_filename && ~ischar(data)
        error('illegal input of type ''%s''', class(data));
    end

    if input_is_filename
        % read header from file
        raw_header=img_format.header_reader(data);
    elseif isfield(img_format, 'struct_header_reader')
        raw_header=img_format.struct_header_reader(fn,data);
    else
        % input is a struct or object, no reading required
        raw_header=data;
    end

    % get dataset header
    [ds_hdr_full,nsamples]=img_format.header_converter(raw_header,...
                                                                params);

    % now we have enough information about the dataset to load the mask
    % and compare its orientation and position of voxels. If there is
    % a mismatch, an error is raised
    mask_ds=get_user_ds_mask(params, ds_hdr_full);

    % only read in multiple blocks if it is supported for this format, and
    % if there is a mask; otherwise what is the point?
    has_mask=~isempty(mask_ds);
    load_multiple_blocks=has_data_reader && has_mask;
    nvoxels=prod(ds_hdr_full.a.vol.dim(1:3));
    volumes_cell=partition_volumes(nsamples, nvoxels,...
                                    load_multiple_blocks, params);
    n_blocks=numel(volumes_cell);

    % allocate space for output
    ds_cell=cell(n_blocks,1);

    % each block contains a subset of volumes; when they are combined
    % the contain all volumes that have to be loaded.
    % To reduce memory usage when a mask is supplied *and* the file
    % format reader allows selecting a subset of volumes:
    % - for each block, read all data from the corresponding volumes
    % - apply the mask to the data
    % - only store the result (which is much smaller)
    % After this has been done for each block, results are stacked to
    % form a single dataset
    for block=1:n_blocks
        volumes=volumes_cell{block};

        % if all volumes are read, call the data reader or converter
        % with empty input, so that it knows that all volumes can be read
        volumes_or_empty=volumes;
        is_all_volumes=isequal(volumes, 1:nsamples);
        if is_all_volumes
            volumes_or_empty=[];
        end

        if input_is_filename && has_data_reader
            % selecting subset of volumes is done by the data_reader,
            % so that only part of the whole file has to be read
            data_reader=img_format.data_reader;

            % make a copy of the filename or SPM struct
            is_first_block=block==1;
            if is_first_block
                original_data=data;
            end

            data=data_converter(data_reader(original_data, raw_header, ...
                                                volumes_or_empty), []);
        else
            % all data is probably already in memory, so select subset
            % of volumes through the converter
            data=data_converter(raw_header, volumes_or_empty);
        end

        if isfield(img_format,'convert_volume') && ...
                                ~img_format.convert_volume
            ds=data;
        else
            ds=flatten_data_array(data, ds_hdr_full.a.vol);
        end

        clear data; % reduce memory usage

        if has_mask
            if block==1
                % only get the mask once, as it is the same for all blocks
                ds_ids_mask=get_binary_dataset_mask(mask_ds,ds);
            end

            ds=cosmo_slice(ds, ds_ids_mask, 2);
        end

        ds_hdr=ds_hdr_full;

        % get sample attributes for these volumes from the header
        if isfield(ds_hdr,'sa')
            ds_hdr.sa=cosmo_slice(ds_hdr.sa, volumes,1,'struct');
        end

        % update from header
        ds=cosmo_structjoin(ds_hdr, ds);

        % store block
        ds_cell{block}=ds;
    end

    ds_all=cosmo_stack(ds_cell,[],[],false);
    cosmo_check_dataset(ds_all,'fmri');


function ids_mask=get_binary_dataset_mask(ds_mask, ds)
    % return a binary mask that can be used to slice ds
    % to contain only features indexed by ds_mask
    %
    % This function also works if ds_mask and ds do not have the same
    % features (voxels), and/or if the same location is indexed by multiple
    % features.

    % this should always be fine
    check_datasets_in_same_space(ds_mask, ds);
    assert(islogical(ds_mask.samples));


    [mask_lin_ids,dim]=get_linear_feature_ids(ds_mask);
    [lin_ids, dim_]=get_linear_feature_ids(ds);
    assert(isequal(dim,dim_));

    % allow duplicate feature ids in either ds_mask and/or ds
    n_ids_mask=prod(dim);
    mask=false(1,n_ids_mask);
    mask(mask_lin_ids)=samples_to_binary_mask(ds_mask.samples);

    ids_mask=mask(lin_ids);


function mask=samples_to_binary_mask(samples)
    mask=samples~=0 & ~isnan(samples);

function warn_if_nan_present_in_dataset(ds)
    nsamples=size(ds.samples,1);
    for k=1:nsamples
        if any(isnan(ds.samples(k,:)))
            cosmo_warning(['The input dataset has NaN (not a number) '...
                            'values, which may cause the output '...
                            'of subsequent analyses to contain NaNs as '...
                            'well. For many use cases, NaNs are not '...
                            'desirabe. To remove features (voxels) '...
                            'with NaN values, consider using:\n\n'...
                            '  ds_clean=cosmo_remove_useless_data(ds)'...
                            '\n\nwhere ds is the output from this '...
                            'function (%s)'],mfilename());
            return
        end
    end

function [lin_ids, vol_dim]=get_linear_feature_ids(ds)
    % get linear ids for each feature
    keys={'i','j','k'};
    n_keys=numel(keys);

    sub_ids=cell(1,n_keys);
    vol_dim=ds.a.vol.dim(1:3);

    for k=1:n_keys;
        key=keys{k};

        [dim, unused, unused, unused, values]=cosmo_dim_find(ds,key,true);
        if dim~=2
            error('Unexpected key ''%s'' in sample dimension',key);
        end
        assert(numel(values)==vol_dim(k));

        sub_ids{k}=values(ds.fa.(key));
    end


    lin_ids=sub2ind(vol_dim,sub_ids{:});


function tf=param_specifies_auto_mask(params)
    % return true if an auto mask is specified
    mask_param=params.mask;
    tf=(islogical(mask_param) && ...
                mask_param) || ...
        (ischar(mask_param) && ...
                 numel(mask_param)>0 && ...
                 mask_param(1)=='-');

function tf=param_specifies_user_mask(params)
    % return true if a user mask is specified
    mask_param=params.mask;
    tf=~(isempty(mask_param) || ...
                islogical(mask_param) || ...
                param_specifies_auto_mask(params));


function ds_mask=get_user_ds_mask(params, ds_hdr)
    % returns a dataset containing the user mask,
    % or [] if no user mask was supplied
    mask_param=params.mask;

    if ~param_specifies_user_mask(params);
        ds_mask=[];
        return;
    end

    % get the mask in dataset form
    opt=struct();
    opt.mask=false;
    ds_mask=convert_to_dataset(mask_param,opt);

     % only support single volume
    nsamples_mask=size(ds_mask.samples,1);
    if nsamples_mask~=1
        error('mask must have a single volume, found %d',...
                                        nsamples_mask);
    end

    % ensure they are in the same space
    ds_mask=align_mask_to_ds_space(ds_mask, ds_hdr);

    % set the samples to a boolean array
    ds_mask.samples=samples_to_binary_mask(ds_mask.samples);


function ds_mask=align_mask_to_ds_space(ds_mask, ds_hdr)
    % throw an error if the mask is in a different space as ds_hdr

    % based on the header, make a minimal dataset (with no samples)
    % so that its orientation can be obtained for ds_hdr
    vol=ds_hdr.a.vol;
    data=zeros([vol.dim(1:3) 0]);
    ds_hdr=flatten_data_array(data, vol);

    % if in another orientation, try to match to orientation of the mask
    ds_orient=cosmo_fmri_orientation(ds_hdr);
    if ~isequal(ds_orient, cosmo_fmri_orientation(ds_mask))
        ds_mask=cosmo_fmri_reorient(ds_mask, ds_orient);
    end

    check_datasets_in_same_space(ds_mask, ds_hdr);


function check_datasets_in_same_space(ds_mask, ds_hdr)
    % ensure the mask is compatible with the dataset
    if ~isequal(ds_mask.a.fdim,ds_hdr.a.fdim)
        error('.a.fdim mismatch between data and mask');
    end

    % check voxel-to-world mapping
    max_delta=1e-4; % allow for minor tolerance
    delta=max(abs(ds_mask.a.vol.mat(:)-ds_hdr.a.vol.mat(:)));
    if delta>max_delta
        error(['voxel dimension mismatch between data and mask:'...
                    'max difference is %.5f > %.5f'],...
                    delta,max_delta);
    end


function ds_data=flatten_data_array(data, vol)
    if all(cosmo_isfield(data,{'samples','a.vol.dim'}))
        ds_data=data;
        return;
    end

    % see how many dimensions there are, and their size
    data_size = size(data);
    ndim = numel(data_size);

    if ndim<4
        % simple reshape operation
        data=reshape(data,[1 data_size]);
    elseif ndim==4
        data=shiftdim(data,3);
    else
        error('need 3 or 4 dimensions, found %d', ndim);
    end

    % number of values in 3 spatial dimensions
    full_size=[size(data) 1 1];
    ni=full_size(2);
    nj=full_size(3);
    nk=full_size(4);

    % make a dataset
    ds_data=cosmo_flatten(data,{'i';'j';'k'},{1:ni;1:nj;1:nk});
    ds_data.a.vol=vol;


function volumes_cell=partition_volumes(n_volumes_total, n_voxels, ...
                                                do_partial, params)
    % return a cell with indices of volumes to load as specified
    % by params.volumes.
    % If params.volumes is empty, all volume indices are returned.
    % If do_partial=true then each element in volume_cell has a
    % limited number of indices so that the volumes in each cell
    % element correspond to at most params.block_size elements (number
    % of voxels times number of volumes).
    % If do_partial=false, a cell with a single element with all volumes
    % is returned.

    if ~isfield(params,'volumes') || isempty(params.volumes)
        volumes=1:n_volumes_total;
    else
        volumes=params.volumes;
    end


    if do_partial
        block_size=params.block_size;
        n_volumes_per_block=floor(block_size / n_voxels);

        if n_volumes_per_block<1
            n_volumes_per_block=1;
        end

        n_volumes_to_load=numel(volumes);
        n_blocks=ceil(n_volumes_to_load / n_volumes_per_block);

        if n_blocks<1
            n_blocks=n_volumes_to_load;
            n_volumes_per_block=1;
        end

        volumes_cell=cell(1, n_blocks);
        first_index=1;
        for block=1:n_blocks
            last_index=min(n_volumes_to_load, ...
                            first_index+n_volumes_per_block-1);

            volumes_cell{block}=volumes(first_index:last_index);

            first_index=last_index+1;
        end

        assert(all(cellfun(@numel,volumes_cell)>=1));
    else
        volumes_cell={volumes};
    end

function result=fast_import_data(fn)
    x=load(fn);
    keys=fieldnames(x);
    if numel(keys)~=1
        error('Cannot load .mat file %s with multiple variables: %s',...
                fn, cosmo_strjoin(keys,', '));
    end
    result=x.(keys{1});


function ds=set_sa_vec(ds,p,fieldname)
    % helper: sets a sample attribute as a vector
    % throws an error if it has the wrong size
    v=p.(fieldname);
    if isequal(size(v),[0 0])
        % ignore '[]', but not zeros(10,0)
        return;
    end
    nsamples=size(ds.samples,1);

    n=numel(v);
    if n==1
        % singleton element - repeat nsamples times.
        v=repmat(v,nsamples,1);
        n=nsamples;
    end
    if ~(n==0 || n==nsamples)
        error('size mismatch for %s: expected %d values, found %d', ...
                        fieldname, nsamples, n);
    end
    ds.sa.(fieldname)=v(:);

function tf=string_endswith(s, tail)
    tf=ischar(s) && ~isempty(s) && isempty(cosmo_strsplit(s, tail, -1));


function img_format=find_img_format(filename, img_formats)
    % helper: find image format of filename fn

    fns=fieldnames(img_formats);
    n=numel(fns);
    for k=1:n
        fn=fns{k};

        if ischar(filename)
            exts=img_formats.(fn).exts;
            m=numel(exts);
            for j=1:m
                ext=exts{j};
                if string_endswith(filename,ext)
                    img_format=fn;
                    return
                end
            end
        else
            % it could be a struct - try that
            matcher=img_formats.(fn).matcher;
            if matcher(filename)
                img_format=fn;
                return
            end
        end
    end

    if ischar(filename)
        desc=sprintf('file ''%s''',filename);
    else
        desc=sprintf('<%s> input',class(filename));
    end
    error('Could not find image format for %s',desc);


function auto_mask=compute_auto_mask(data, mask_type)
    % mask_type can be 'any', 'all', 'auto', or ''
    % When using 'auto', 'any' and 'all' should give the same mask
    % When using '', a warning is shown when the percentage of
    % non{zero,finite} features exceeds pct_thrshold

    if isequal(mask_type,true)
        mask_type='-auto';
    end


    pct_threshold=5;

    to_remove=~samples_to_binary_mask(data);


    % take as a mask anywhere where any feature is nonzero.
    if cosmo_match({mask_type},{'-any','-auto',''})
        to_remove_any=any(to_remove,1);
    end

    if cosmo_match({mask_type},{'-all','-auto',''})
        to_remove_all=all(to_remove,1);
    end

    switch mask_type
        case {'-auto',''}
            %
            any_equals_all=isequal(to_remove_any, to_remove_all);

            n=numel(to_remove_any);
            n_any=sum(to_remove_any(:));
            n_all=sum(to_remove_all(:));

            pct_any=100*n_any/n;
            pct_all=100*n_all/n;

            do_mask_suggestion=pct_all>pct_threshold && ...
                                strcmp(mask_type,'');

            if any_equals_all
                if do_mask_suggestion
                    me_name=mfilename();
                    msg=sprintf(['%d (%.1f%%) features are non'...
                                '{zero,finite} in all samples (and no '...
                                'features have non-{zero,finite} '...
                                'values in some samples and not '...
                                'in others)\n'...
                                'To use a mask excluding these '...
                                'features: %s(...,''mask'',-auto'')\n'],...
                                n_all,pct_all,me_name);
                    cosmo_warning(msg);

                    to_remove=[];
                else
                    to_remove=to_remove_any;
                end
            else
                % give error or warning
                me_name=mfilename();

                msg=sprintf(['%d (%.1f%%) features are non{zero,'...
                            'finite} in all samples\n'...
                            '%d (%.1f%%) features are non{zero,'...
                            'finite} in at least one sample\n'...
                            'To use a mask excluding '...
                            'features:\n'...
                            '- where *all* values are non{zero,finite}:'...
                            ' %s(...,''mask'',-all'')\n'...
                            '- where *any* value  is  non{zero,finite}:'...
                            ' %s(...,''mask'',-any'')\n'],...
                            n_all,pct_all,n_any,pct_any,me_name,me_name);

                if strcmp(mask_type,'-auto');
                    error('automatic mask failed:\n%s',msg);
                else
                    % give a warning
                    cosmo_warning(msg);
                    % set mask to empty; a mask will not be applied
                    to_remove=[];
                end
            end
        case '-any'
            to_remove=to_remove_any;
        case '-all'
            to_remove=to_remove_all;
        otherwise
            error('illegal mask specification ''-%s''', mask_type);
    end

    auto_mask=~to_remove(:)';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Definition of supported data formats
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function img_formats=get_img_formats()
    % define which formats are supported.
    %
    % The intention is to support a wide variety of formats through
    % different external toolboxes, yet support these in a uniform way. If
    % the toolbox supports loading a subset of the data
    % (NIfTI, AFNI, SPM), then a .data_reader can be defined which
    % only loads the requested data; otherwise (BrainVoyager, non-SPM
    % .mat files) all data is read and the requested data selected
    % afterwards
    %
    % In the definitions below:
    % - native header:    contains at least minimal header information in
    %                     the format's representation
    % - minimal dataset:  contains at least minimal header information in
    %                     dataset format (in .sa.samples, .a.vol.dim and
    %                     .a.vol.mat)
    % - nvolumes          number of volumes available in the input
    % - native header  }  native header information and data stored in
    %   and data:      }  native representation
    % - volumes           indices of volumes to read
    % - 4D data           volume data in X x Y x Z x T
    %
    % Each format is defined by these fields:
    % .exts               file name extensions
    % .externals          required externals
    % .header_reader      file name -> native header
    % [.struct_header_reader] (file name, native header) -> native header
    %                     (used for SPM.mat, to avoid re-loading the file)
    % .header_converter   (native header, params)  -> (minimal dataset,
    %                                                   nvolumes)
    % [.data_reader]      (file name,
    %                      native header, volumes) -> (native header and
    %                                                    data)
    % .data_converter     (native header and data,
    %                      volumes)                -> 4D data array
    % [.convert_volume]   if false, then the native header format must be
    %                     an fmri dataset
    %
    % Notes:
    % - if .data_reader is absent, then .header_reader must return a
    %   header that contains the data and which can be converter by
    %   .data_converter.
    % - if .convert_volume is not present, then the output frmo
    %   .data_converter is assumed to return a COSMoMVPA dataset struct
    %   (instead of 4D data)
    img_formats=struct();

    img_formats.nii.exts={'.nii.gz','.nii','.hdr','.img'};
    img_formats.nii.externals={'nifti'};
    img_formats.nii.matcher=@isa_nii;
    img_formats.nii.header_reader=@read_nii_header;
    img_formats.nii.header_converter=@convert_nii_header;
    img_formats.nii.data_reader=@read_nii_data;
    img_formats.nii.data_converter=@convert_nii_data;


    img_formats.bv_glm.exts={'.glm'};
    img_formats.bv_glm.externals={'neuroelf'};
    img_formats.bv_glm.matcher=@isa_bv_glm;
    img_formats.bv_glm.header_reader=@read_bv_glm_header;
    img_formats.bv_glm.header_converter=@convert_bv_glm_header;
    img_formats.bv_glm.data_converter=@convert_bv_glm_data;


    img_formats.bv_msk.exts={'.msk'};
    img_formats.bv_msk.externals={'neuroelf'};
    img_formats.bv_msk.matcher=@isa_bv_msk;
    img_formats.bv_msk.header_reader=@read_bv_msk_header;
    img_formats.bv_msk.header_converter=@convert_bv_msk_header;
    img_formats.bv_msk.data_converter=@convert_bv_msk_data;


    img_formats.bv_vtc.exts={'.vtc'};
    img_formats.bv_vtc.externals={'neuroelf'};
    img_formats.bv_vtc.matcher=@isa_bv_vtc;
    img_formats.bv_vtc.header_reader=@read_bv_vtc_header;
    img_formats.bv_vtc.header_converter=@convert_bv_vtc_header;
    img_formats.bv_vtc.data_converter=@convert_bv_vtc_data;


    img_formats.bv_vmp.exts={'.vmp'};
    img_formats.bv_vmp.externals={'neuroelf'};
    img_formats.bv_vmp.matcher=@isa_bv_vmp;
    img_formats.bv_vmp.header_reader=@read_bv_vmp_header;
    img_formats.bv_vmp.header_converter=@convert_bv_vmp_header;
    img_formats.bv_vmp.data_converter=@convert_bv_vmp_data;


    img_formats.bv_vmr.exts={'.vmr'};
    img_formats.bv_vmr.externals={'neuroelf'};
    img_formats.bv_vmr.matcher=@isa_bv_vmr;
    img_formats.bv_vmr.header_reader=@read_bv_vmr_header;
    img_formats.bv_vmr.header_converter=@convert_bv_vmr_header;
    img_formats.bv_vmr.data_converter=@convert_bv_vmr_data;


    img_formats.spm.exts={'mat:con','mat:beta','mat:spm'};
    img_formats.spm.externals=img_formats.nii.externals;
    img_formats.spm.matcher=@isa_spm;
    img_formats.spm.struct_header_reader=@read_spm_struct_header;
    img_formats.spm.header_reader=@read_spm_header;
    img_formats.spm.header_converter=@convert_spm_header;
    img_formats.spm.data_reader=@read_spm_data;
    img_formats.spm.data_converter=@convert_spm_data;


    img_formats.afni.exts={'+orig','+orig.HEAD','+orig.BRIK',...
                           '+orig.BRIK.gz','+tlrc','+tlrc.HEAD',...
                           '+tlrc.BRIK','+tlrc.BRIK.gz'};
    img_formats.afni.externals={'afni'};
    img_formats.afni.matcher=@isa_afni;
    img_formats.afni.header_reader=@read_afni_header;
    img_formats.afni.header_converter=@convert_afni_header;
    img_formats.afni.data_reader=@read_afni_data;
    img_formats.afni.data_converter=@convert_afni_data;


    img_formats.ft_source.exts=cell(0);
    img_formats.ft_source.externals=cell(0);
    img_formats.ft_source.matcher=@isa_ft_source;
    img_formats.ft_source.header_reader=@read_ft_source_header;
    img_formats.ft_source.header_converter=@convert_ft_source_header;
    img_formats.ft_source.data_converter=@convert_ft_source_data;
    img_formats.ft_source.convert_volume=false; % already dataset

    img_formats.cosmo_fmri_ds.exts=cell(0);
    img_formats.cosmo_fmri_ds.matcher=@isa_cosmo_fmri;
    img_formats.cosmo_fmri_ds.externals=cell(0);
    img_formats.cosmo_fmri_ds.header_reader=@read_cosmo_ds_header;
    img_formats.cosmo_fmri_ds.header_converter=@convert_cosmo_ds_header;
    img_formats.cosmo_fmri_ds.data_converter=@convert_cosmo_ds_data;
    img_formats.cosmo_fmri_ds.convert_volume=false; % already dataset


%%%%%%%%%%%%%%%%%%%%%%%%
% General

function data=slice_4d(data, volumes)
    data_size=size(data);
    ndim=numel(data_size);
    if ndim>4
        % Could be the AFNI NIFTI conversion syndrome, where the 4th
        % dimension is singleton and the fifth one contains the data.
        % Such data is accepted and treated as if the fifth dimension is
        % the fourth one.
        time_size=data_size(4:end);
        if sum(time_size>1)>1
            error(['More than one singleton dimension found in '...
                        'time dimension; this is currently not '...
                        'supported. If you want to be able '...
                        'to load such data, please get in touch '...
                        'with the CoSMoMVPA developers']);
        end

        ntime=prod(time_size);
        data=reshape(data,[data_size(1:3),ntime]);
    end

    if ~isempty(volumes)
        data=data(:,:,:,volumes);
    end

    if ~isa(data,'double')
        data=double(data);
    end


function ds=slice_dataset_volumes(ds, volumes)
    if ~isempty(volumes)
        ds=cosmo_slice(ds,volumes,1);
    end

function require_singleton_volume(volumes)
    if ~isequal(volumes,[]) && ~isequal(volumes,1)
        error('Only a single volume is supported for this data format');
    end

function hdr=get_and_check_data(hdr, loader_func, check_func, varargin)
    % is hdr is a char, load it using loader with optional arguments
    % from varargin
    % For other input, the input is returned.
    %
    % in any case the output is checked using check_func.
    if ischar(hdr)
        hdr=loader_func(hdr, varargin{:});
    end
    if ~check_func(hdr)
        error('Illegal input of type %s - failed to pass %s',...
                    class(hdr), func2str(check_func));
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% format-specific helper functions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%
% NIfTI
%%%%%%%%%%%%%%%%%%%%%%%%

% helpers
function [mx, xform]=get_nifti_transform(hdr, varargin)
    % Get LPI affine transformation from NIfTI file
    %
    % Input:
    %   fn          nifti filename
    %
    % Output:
    %   mx          4x4 affine transformation matrix from voxel to world
    %               coordinates. voxel indices as base0, not base1 as in
    %               CoSMoMVPA
    %   xform       string with xform based on sform or qform code
    %
    % Notes:
    %  - this function is experimental
    %  - initial testing suggests agreement with MRIcron (thanks to Chris
    %    Rorden for providing this software)
    %  - functionality in the subfunctions are based on nftii1_io.h in
    %    AFNI, written Robert W Cox (2003), public domain dedication;
    %    http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1_io.c
    %  - to convert voxel coordinates (i,j,k) to (x,y,z), compute
    %    lpi_mx*[x y z 1]'. For the reverse, compute inv(lpi_mx)*[i j k 1]'
    %
    % NNO Dec 2014

    defaults.nifti_form=[];
    opt=cosmo_structjoin(defaults,varargin);

    if isempty(opt.nifti_form)
        [mx, nifti_form]=nifti_matrix_from_auto(hdr);
    else
        [mx, nifti_form]=nifti_matrix_using_method(hdr,opt.nifti_form);
    end

    % prioritize sformch
    switch nifti_form
        case 'sform'
            key=hdr.hist.sform_code;
        case 'qform'
            key=hdr.hist.qform_code;
        otherwise
            key=0;
    end

    xform=cosmo_fmri_convert_xform('nii',key);


function [mx, nifti_form]=nifti_matrix_from_auto(hdr)
    % get matrix automatically, assumes that qform and sform (if present)
    % are identical
    max_delta_s_and_q=1e-3; % maximum allowed difference between s and q

    has_sform=hdr.hist.sform_code>0;
    has_qform=hdr.hist.qform_code>0;

    if has_sform;
        nifti_form='sform';
    elseif has_qform
        nifti_form='qform';
    else
        nifti_form='pixdim';
    end

    mx=nifti_matrix_using_method(hdr,nifti_form);

    if has_sform && has_qform
        mx_q=nifti_matrix_using_method(hdr,'qform');

        max_diff=max(abs(mx(:)-mx_q(:)));
        if max_diff>max_delta_s_and_q
            str_mx=matrix2string(mx);
            str_mx_s=matrix2string(mx_q);
            url=['http://nifti.nimh.nih.gov/nifti-1/documentation/'...
                    'nifti1fields/nifti1fields_pages/qsform.html'];
            error(['the affine matrices mapping voxel-to-world '...
                    'coordinates according to the sform and qform '...
                    'in the NIfTI header differ '...
                    'by %d, exceeding the treshold %d.\n\n'...
                    'The sform matrix is:\n\n%s\n\n',...
                    'The qform matrix is:\n\n%s\n\n'...
                    'To resolve this, set the ''nifti_form'' '...
                    'option to either:\n'...
                    '  ''pixdim'' (method 1), or\n'...
                    '  ''qform''  (method 2), or\n'...
                    '  ''sform''  (method 3).\n\n'...
                    'For more information, see:\n  %s\n\n',...
                    'If you have absolutely no idea what to use, '...
                    'try ''sform''\n\n'],...
                    max_diff, max_delta_s_and_q,...
                    str_mx_s, str_mx, url);
        end
    end

function s=matrix2string(mx)
    float_pat='%6.3f';
    line_pat=repmat([float_pat ' '],1,4);
    line_pat(end)=sprintf('\n');
    mx_pat=repmat(line_pat,1,3);
    mx_3x4=mx(1:3,1:4);
    s=sprintf(mx_pat,mx_3x4');



function [mx, method]=nifti_matrix_using_method(hdr, method)

    switch method
        case 'pixdim'
            mx=nifti_matrix_from_pixdim(hdr);
        case 'qform'
            mx=nifti_matrix_from_qform(hdr);
        case 'sform'
            mx=nifti_matrix_from_sform(hdr);
        otherwise
            error('illegal method %s', method);
    end

    assert(isequal(size(mx),[4 4]));

function mx=nifti_matrix_from_pixdim(hdr)
    mx=[[diag(hdr.dime.pixdim(2:4)); 0 0 0] [0;0;0;1]];


function mx=nifti_matrix_from_qform(hdr)
    % convert quaternion to affine matrix
    %
    % based on "quatern_to_mat44" in nifti1_io.c by Robert W. Cox, 2003,
    % which he dedicated to the public domain.
    %
    % http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1_io.c
    qfac=hdr.dime.pixdim(1);
    dx=hdr.dime.pixdim(2);
    dy=hdr.dime.pixdim(3);
    dz=hdr.dime.pixdim(4);
    qb=hdr.hist.quatern_b;
    qc=hdr.hist.quatern_c;
    qd=hdr.hist.quatern_d;
    qx=hdr.hist.qoffset_x;
    qy=hdr.hist.qoffset_y;
    qz=hdr.hist.qoffset_z;

    % ported from MRIcron
    b=qb;
    c=qc;
    d=qd;
    a=1-(b^2+c^2+d^2);

    if a<1e-7
        a=1/sqrt(b^2+c^2+d^2);
        b=b*a;
        c=c*a;
        d=d*a;
        a=0;
    else
        a=sqrt(a);
    end

    if dx>0
        xd=dx;
    else
        xd=1;
    end

    if dy>0
        yd=dy;
    else
        yd=1;
    end

    if dz>0
        zd=dz;
    else
        zd=1;
    end

    if qfac<0
        zd=-zd;
    end

    % construct affine matrix
    mx=zeros(4,4);
    mx(1,1)=     (a*a+b*b-c*c-d*d) * xd ;
    mx(1,2)= 2 * (b*c-a*d        ) * yd ;
    mx(1,3)= 2 * (b*d+a*c        ) * zd ;
    mx(2,1)= 2 * (b*c+a*d        ) * xd ;
    mx(2,2)=     (a*a+c*c-b*b-d*d) * yd ;
    mx(2,3)= 2 * (c*d-a*b        ) * zd ;
    mx(3,1)= 2 * (b*d-a*c        ) * xd ;
    mx(3,2)= 2 * (c*d+a*b        ) * yd ;
    mx(3,3)=     (a*a+d*d-c*c-b*b) * zd ;
    mx(1,4)=qx;
    mx(2,4)=qy;
    mx(3,4)=qz;
    mx(4,:)=[0 0 0 1];

function mx=nifti_matrix_from_sform(hdr)
    % set the srow values
    mx=[hdr.hist.srow_x;...
        hdr.hist.srow_y;...
        hdr.hist.srow_z;...
        [0 0 0 1]];

function scaling=nifti_get_scaling_factor(hdr)
    % get scaling factor, if present for this dataset
    % scaling=[intercept slope] if present, otherwise []
    is_datatype=any(hdr.dime.datatype==[2,4,8,16,64,256,512,768]);
    is_nonidentity=hdr.dime.scl_inter~=0 || hdr.dime.scl_slope~=1;
    is_nonzero=hdr.dime.scl_slope~=0;

    if is_datatype && is_nonidentity && is_nonzero
        scaling=[hdr.dime.scl_inter hdr.dime.scl_slope];
    else
        scaling=[];
    end



% NIfTI input
% -----------
function b=isa_nii(hdr)

    b=isstruct(hdr) && isfield(hdr,'img') && isnumeric(hdr.img) && ...
            isfield(hdr,'hdr') && isfield(hdr.hdr,'dime') && ...
            isfield(hdr.hdr.dime,'dim') && isnumeric(hdr.hdr.dime.dim);


function nii=read_nii_header(fn)
    nii.hdr=load_untouch_header_only(fn);


function [hdr_ds,nsamples]=convert_nii_header(nii, params)
    hdr=nii.hdr;
    dim=hdr.dime.dim(2:4);

    % get original affine matrix
    [mat, xform]=get_nifti_transform(hdr, params);

    % make matrix base1 friendly
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*[-1 -1 -1]';

    vol=struct();
    vol.mat=mat;
    vol.xform=xform;
    vol.dim=dim;
    sa=struct();
    nsamples=hdr.dime.dim(5);

    hdr_ds=struct();
    hdr_ds.a.vol=vol;
    hdr_ds.sa=sa;

function nii=read_nii_data(fn, hdr_from_nii, volumes)
    % get original header
    hdr=hdr_from_nii.hdr;

    % load the data
    nii=load_untouch_nii(fn, volumes);
    assert(isequal(hdr.dime.dim(1:4),nii.hdr.dime.dim(1:4)));

    hdr.dime.dim=nii.hdr.dime.dim;
    hdr.dime.glmax=nii.hdr.dime.glmax;
    hdr.dime.glmin=nii.hdr.dime.glmin;
    assert(isequal(hdr,nii.hdr));


function data=convert_nii_data(nii, volumes)
    % get scaling factor
    scaling=nifti_get_scaling_factor(nii.hdr);

    data=slice_4d(nii.img, volumes);

    % apply scaling
    if ~isempty(scaling)
        data(:)=scaling(1)+scaling(2)*data;
    end


%%%%%%%%%%%%%%%%%%%%%%%%
% AFNI
%%%%%%%%%%%%%%%%%%%%%%%%

% helpers
function vol=get_vol_afni(hdr)
    % afni volume info
    orient='LPI'; % always return LPI-based matrix

    % origin and basis vectors in world space
    k=[0 0 0;eye(3)];

    [unused,i]=AFNI_Index2XYZcontinuous(k,hdr,orient);

    % basis vectors in voxel space
    e1=i(2,:)-i(1,:);
    e2=i(3,:)-i(1,:);
    e3=i(4,:)-i(1,:);

    % change from base0 (afni) to base1 (SPM/Matlab)
    o=i(1,:)-(e1+e2+e3);

    % create matrix
    mat=[e1;e2;e3;o]';

    % set 4th row
    mat(4,:)=[0 0 0 1];

    vol=struct();
    vol.mat=mat;
    vol.dim=hdr.DATASET_DIMENSIONS(1:3);
    vol.xform=cosmo_fmri_convert_xform('afni',hdr.SCENE_DATA(1));


% AFNI HEAD & BRIK input
% ----------------------
function b=isa_afni(hdr)
    b=isstruct(hdr) && isfield(hdr,'DATASET_DIMENSIONS') && ...
            isfield(hdr,'DATASET_RANK');


function head=read_afni_header(fn)
    [err,head]=BrikInfo(fn);
    if err
        error('Could not read %s', fn);
    end


function [hdr_ds,nsamples]=convert_afni_header(head, params)
    if numel(head.DATASET_RANK)<2
        error('illegal AFNI header: DATASET_RANK');
    end
    nsamples=head.DATASET_RANK(2);

    % set sample attributes
    sa=struct();

    if isfield(head,'BRICK_LABS') && ~isempty(head.BRICK_LABS);
        % if present, get labels
        labels=cosmo_strsplit(head.BRICK_LABS,'~');
        if numel(labels)==nsamples+1 && isempty(labels{end})
            labels=labels(1:(end-1));
        end
        sa.labels=labels(:);
    end

    if isfield(head,'BRICK_STATAUX') && ~isempty(head.BRICK_STATAUX);
        % if present, get stat codes
        sa.stats=cosmo_statcode(head);
    end

    hdr_ds.sa=sa;

    % get volume info
    hdr_ds.a.vol=get_vol_afni(head);

function head=read_afni_data(fn, head, volumes)
    opt=struct();
    opt.Frames=volumes;

    [err,data,head_data,err_msg]=BrikLoad(fn,opt);
    if err
        error('Error reading afni file: %s', err_msg);
    end

    assert(isequal(head_data,head));

    head.img=data;


function data=convert_afni_data(head, volumes)
    data=slice_4d(head.img, volumes);





%%%%%%%%%%%%%%%%%%%%%%%%
% BrainVoyager
%%%%%%%%%%%%%%%%%%%%%%%%

% helpers
function z=xff_struct(x)
    % helper function: applies xff and returns a struct
    % this avoids clearing of the object (which xff seems like doing)
    y=xff(x);

    z=getcont(y);


    % BoundingBox is a method; copy its output to the struct
    z.BoundingBox=y.BoundingBox;

function vol=get_vol_bv(hdr)
    % bv vol info
    bbox=hdr.BoundingBox;
    mat=neuroelf_bvcoordconv_wrapper([],'bvx2tal',bbox);
    dim=bbox.DimXYZ;

    % deal with offset at (.5, .5, .5) [CHECKME]
    mat(1:3,4)=mat(1:3,4)+mat(1:3,1:3)*.5*[1 1 1]';

    vol=struct();
    vol.mat=mat;
    vol.dim=dim;
    vol.xform=cosmo_fmri_convert_xform('bv',NaN);

function mat=neuroelf_bvcoordconv_wrapper(varargin)
    % converts BV bounding box to affine transformation matrix
    % helper functions that deals with both new neuroelf (version 1.0)
    % and older versions.
    % the old version provides a 'bvcoordconv' .m file
    % the new version privides this function in the neuroelf class
    has_bvcoordconv=~isempty(which('bvcoordconv'));

    % set function handle
    if has_bvcoordconv
        f=@bvcoordconv;
    else
        n=neuroelf();
        f=@n.bvcoordconv;
    end

    mat=f(varargin{:});


% BV GLM input
% ------------
function b=isa_bv_glm(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr,'Predictor') &&  ...
            isfield(hdr,'GLMData') && isfield(hdr,'DesignMatrix');

function hdr=read_bv_glm_header(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_glm);


function [hdr_ds,nsamples]=convert_bv_glm_header(hdr, params)
    nsamples=hdr.NrOfPredictors;


    % get sample attributes
    name1=cell(nsamples,1);
    name2=cell(nsamples,1);
    rgb=zeros(nsamples,3);
    for k=1:nsamples
        p=hdr.Predictor(k);
        name1{k}=p.Name1;
        name2{k}=p.Name2;
        rgb(k,:)=p.RGB(1,:);
    end

    sa=struct();
    sa.Name1=name1;
    sa.Name2=name2;
    sa.RGB=rgb;

    vol=get_vol_bv(hdr);

    hdr_ds=struct();
    hdr_ds.sa=sa;
    hdr_ds.a.vol=vol;


function data=convert_bv_glm_data(hdr, volumes)
    % ignore filename, because all data is already in hdr
    data=slice_4d(hdr.GLMData.BetaMaps, volumes);



% BV volumetric map input
% -----------------------
function b=isa_bv_vmp(hdr)

    b=(isa(hdr,'xff') || isstruct(hdr)) && ...
            isfield(hdr,'Map') && isstruct(hdr.Map) && ...
            isfield(hdr,'VMRDimX') && isfield(hdr,'NrOfMaps');


function hdr=read_bv_vmp_header(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vmp);


function [hdr_ds,nsamples]=convert_bv_vmp_header(hdr, params)
    nsamples=hdr.NrOfMaps;

    sa=struct();
    labels=cell(nsamples,1);
    for k=1:nsamples
        map=hdr.Map(k);
        labels{k}=map.Name;
    end

    sa.labels=labels;
    sa.stats=cosmo_statcode(hdr);

    hdr_ds=struct();
    hdr_ds.sa=sa;
    hdr_ds.a.vol=get_vol_bv(hdr);


function data=convert_bv_vmp_data(hdr, volumes)
    nsamples=numel(hdr.Map);

    if isempty(volumes)
        volumes=1:nsamples;
    end

    nvolumes=numel(volumes);
    data_cell=cell(nvolumes,1);

    for k=1:nvolumes
        map=hdr.Map(volumes(k)).VMPData;
        data_cell{k}=map;
    end

    data=cat(4,data_cell{:});


% BV mask input
% -------------
function b=isa_bv_msk(hdr)
    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr, 'Mask');


function hdr=read_bv_msk_header(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_msk);


function [hdr_ds,nsamples]=convert_bv_msk_header(hdr, params)
    nsamples=1;

    hdr_ds=struct();
    hdr_ds.sa=struct();
    hdr_ds.a.vol=get_vol_bv(hdr);


function data=convert_bv_msk_data(hdr, volumes)
    require_singleton_volume(volumes);

    data=double(hdr.Mask);



% BV volume time course input
% ---------------------------
function b=isa_bv_vtc(hdr)
    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr, 'VTCData');


function hdr=read_bv_vtc_header(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vtc);


function [hdr_ds,nsamples]=convert_bv_vtc_header(hdr, params)
    nsamples=size(hdr.VTCData,1);

    hdr_ds=struct();
    hdr_ds.sa=struct();
    hdr_ds.a.vol=get_vol_bv(hdr);


function data=convert_bv_vtc_data(hdr, volumes)
    data=slice_4d(shiftdim(hdr.VTCData,1), volumes);



% BV volumetric MR (anatomy) input
% --------------------------------
function b=isa_bv_vmr(hdr)
    b=(isa(hdr,'xff') || isstruct(hdr)) && isfield(hdr,'VMRData');


function hdr=read_bv_vmr_header(fn)
    hdr=get_and_check_data(fn, @xff_struct, @isa_bv_vmr);


function [hdr_ds,nsamples]=convert_bv_vmr_header(hdr, params)
    nsamples=1;

    hdr_ds=struct();
    hdr_ds.sa=struct();
    hdr_ds.a.vol=get_vol_bv(hdr);


function data=convert_bv_vmr_data(hdr, volumes)
    data=slice_4d(hdr.VMRData,volumes);



%%%%%%%%%%%%%%%%%%%%%%%%
% SPM structure
%%%%%%%%%%%%%%%%%%%%%%%%

% SPM input
% ---------
function b=isa_spm(hdr)
    b=isstruct(hdr) && isfield(hdr,'xX') && isfield(hdr.xX,'X') && ...
                isnumeric(hdr.xX.X) && isfield(hdr,'SPMid');


function hdr=read_spm_header(fn)
    hdr=read_spm_struct_header(fn, []);

function hdr=read_spm_struct_header(fn_with_input_type, spm_header)
    % input can be 'SPM.mat', 'SPM.mat:beta', 'SPM.mat:con', or
    % 'SPM.mat:spm'. Output is the SPM struct with extra fields 'path' and
    % 'input_type' added, so that convert_spm_header can get the correct
    % fields

    if isa_spm(fn_with_input_type)
        fn_with_input_type='SPM.mat';
    end

    [fn,input_type]=get_spm_input_type(fn_with_input_type);

    if isempty(spm_header)
        % .mat file must be loaded still
        spm_struct=load(fn);
        if ~isstruct(spm_struct) || ...
                ~isequal(fieldnames(spm_struct),{'SPM'})
            error('expected data with struct ''SPM'' in file ''%s''',fn);
        end
        spm_header=spm_struct.SPM;
    end

    hdr=spm_header;
    hdr.path=fileparts(fn);
    hdr.input_type=input_type;

    get_and_check_data(hdr, [], @isa_spm);

function [fn,input_type]=get_spm_input_type(fn_with_input_type)
    sep=':';
    input_type=cosmo_strsplit(fn_with_input_type,sep,-1);
    fn=fn_with_input_type;

    switch input_type
        case {'beta','con','spm'}
            fn=fn(1:(end-numel(input_type)-numel(sep)));
        otherwise
            input_type='beta'; % the default; function will crash
                               % if fn is not a proper filename
    end


function [hdr_ds,nsamples]=convert_spm_header(spm_struct, params)
    if isfield(spm_struct,'input_type')
        input_type=spm_struct.input_type;
    else
        input_type='beta';
    end

    if isfield(spm_struct,'path')
        path=spm_struct.path;
    else
        path='';
    end

    % get data of interest
    switch input_type
            case 'beta'
                input_vols=spm_struct.Vbeta;
                input_labels=spm_struct.xX.name';
            case 'con'
                input_vols=[spm_struct.xCon.Vcon];
                input_labels={spm_struct.xCon.name}';
            case 'spm'
                input_vols=[spm_struct.xCon.Vspm];
                input_labels={spm_struct.xCon.name}';
        otherwise
            error('illegal data type %s', input_type);
    end

    n_input=numel(input_vols);
    assert(numel(input_labels)==n_input);

    sa=struct();

    if isfield(spm_struct,'Sess') && strcmp(input_type,'beta')
        % single subject GLM with betas; will use only betas of interest
        % and set chunks based on runs
        nruns=numel(spm_struct.Sess);
        nbeta=numel(spm_struct.Vbeta);
        sessions=zeros(nbeta,1);
        beta_index=zeros(nbeta,1);
        for k=1:nruns
            sess=spm_struct.Sess(k);
            sess_idxs=[sess.Fc.i];
            row_idxs=sess.col(sess_idxs);

            sessions(row_idxs)=k;
            beta_index(row_idxs)=row_idxs;
        end

        keep_vol_msk=sessions>0;
        sa.chunks=sessions(keep_vol_msk);
        sa.beta_index=beta_index(keep_vol_msk);
    else
        % anything else: use all volumes
        keep_vol_msk=true(n_input,1);
    end

    sa.labels=input_labels(keep_vol_msk);
    sa.fname=cellfun(@(fn)fullfile(path,fn),...
                    {input_vols(keep_vol_msk).fname}',...
                                    'UniformOutput',false);


    nsamples=sum(keep_vol_msk);
    if nsamples==0
        error('Illegal: empty input');
    end

    % get volume info
    first_vol=input_vols(1);
    vol=struct();
    vol.dim=first_vol.dim;
    vol.mat=first_vol.mat;


    hdr_ds=struct();
    hdr_ds.a.vol=vol;
    hdr_ds.sa=sa;


function hdr=read_spm_data(fn, hdr, volumes)
    % store volumes, so that when convert_spm_data is called, this
    % information is used
    hdr.volumes=volumes;


function data=convert_spm_data(hdr, volumes)
    % get SPM info
    hdr_ds=convert_spm_header(hdr);

    % see which files to load
    file_names=hdr_ds.sa.fname;
    n_files=numel(file_names);

    if isfield(hdr, 'volumes')
        % call after read_spm_data; volumes are already selected
        % this must be done by the calling function
        assert(isempty(volumes));
        volumes=hdr.volumes;
    end

    if isempty(volumes)
        volumes=1:n_files;
    end

    n_volumes=numel(volumes);

    % allocate space for output
    dim=hdr_ds.a.vol.dim;
    data=zeros([dim n_volumes]);

    %
    for k=1:n_volumes
        file_name=file_names{volumes(k)};

        nii=load_untouch_nii(file_name);

        data(:,:,:,k)=nii.img;
    end


%%%%%%%%%%%%%%%%%%%%%%%%
% FieldTrip source

% FieldTrip source input
% ----------------------
function  b=isa_ft_source(hdr)
    b=isstruct(hdr) && ((isfield(hdr,'inside') && ...
                                    isfield(hdr,'pos'))        || ...
                        (cosmo_check_dataset(hdr,false) && ...
                                    cosmo_isfield(hdr,'fa.pos')));


function hdr=read_ft_source_header(fn)
    hdr=get_and_check_data(fn, @fast_import_data, @isa_ft_source);


function [ds,nsamples]=convert_ft_source_header(hdr, params)
    if isfield(hdr,'inside') && isfield(hdr,'pos')
        % fieldtrip struct
        ds_meeg=cosmo_meeg_dataset(hdr);
    else
        % must be dataset struct with field .fa.pos
        cosmo_isfield(hdr,'fa.pos',true);
        ds_meeg=hdr;
    end

    cosmo_check_dataset(ds_meeg,'meeg');

    ds=cosmo_vol_grid_convert(ds_meeg,'tovol');
    nsamples=size(ds.samples,1);


function ds=convert_ft_source_data(ds_meeg, volumes)
    ds=convert_ft_source_header(ds_meeg, struct());
    ds=slice_dataset_volumes(ds, volumes);


%%%%%%%%%%%%%%%%%%%%%%%%
% CoSMoMVPA datasset

% CoSMoMVPA dataset input
% -----------------------

function tf=isa_cosmo_fmri(ds)
    tf=cosmo_check_dataset(ds,'fmri',false);

function ds=read_cosmo_ds_header(ds)
    ds=get_and_check_data(ds, [], @isa_cosmo_fmri);

function [ds, nsamples]=convert_cosmo_ds_header(ds, params)
    ds=get_and_check_data(ds, [], @isa_cosmo_fmri);
    nsamples=size(ds.samples,1);

function ds=convert_cosmo_ds_data(ds, volumes)
    ds=slice_dataset_volumes(ds,volumes);

