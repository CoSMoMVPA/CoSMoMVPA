function [indices_cell, ds_intersect_cell]=cosmo_mask_dim_intersect(ds_cell,dim,varargin)
% find intersection mask across a set of datasets
%
% [indices, ds_intersect_cell]=cosmo_mask_dim_intersect(ds_cell[,dim])
%
% Inputs:
%   ds_cell                     Kx1 cell with datasets with feature
%                               [sample] dimensions (for dim==1 [dim==2]),
%                               with no feature [sample] location repeated
%   dim                         (optional) dimension along which to form
%                               the mask (default: 2)
%
% Output:
%   indices_cell                Kx1 cell containing maximal sets of indices
%                               of features [or samples] that can be
%                               (if dim==1) from ds_cell so that all
%                               features [or samples] of the  respective
%                               input datasets are shared
%                               across all input datasets.
%   ds_intersect_cell           The result of slicing each of the input
%                               dataset, i.e.
%                                   ds_intersect_cell{k}=
%                                           cosmo_slice(ds_cell{k},dim)
%
% Example:
%     %generate full (but tiny) fMRI dataset
%     ds_full=cosmo_synthetic_dataset('seed',1);
%     %
%     % make two datasets with different subsets of voxels
%     ds1=cosmo_slice(ds_full,[2 5 3 1],2);
%     ds2=cosmo_slice(ds_full,[5 1 4 6 2],2);
%     %
%     % trying to stack these along the sample dimension gives an error,
%     % because the feature attributes do not match
%     result=cosmo_stack({ds1,ds2},1);
%     %|| error('size mismatch along dimension 2 ...')
%     %
%     % find indices for common mask
%     [idx_cell,ds_int_cell]=cosmo_mask_dim_intersect({ds1,ds2});
%     %
%     % show slice-arg indices required for each of the two datasets
%     % to select features (voxels) common across the two datasets;
%     % in this case there are 3 voxels in common
%     cosmo_disp(idx_cell);
%     %|| { [ 4 1 2 ]
%     %||   [ 2 5 1 ] }
%     %
%     % when slicing using the indices, the dimension feature attributes
%     % (here: voxel coordinates) are identical
%     % note: ds_int_cell is equivalent to ds1_sel and ds2_cell
%     ds1_sel=cosmo_slice(ds1,idx_cell{1},2);
%     ds2_sel=cosmo_slice(ds2,idx_cell{2},2);
%     % show voxel coordinates for the two datasets
%     cosmo_disp({ds1_sel.fa,ds2_sel.fa});
%     %|| { .i               .i
%     %||     [ 1 2 2 ]        [ 1 2 2 ]
%     %||   .j               .j
%     %||     [ 1 1 2 ]        [ 1 1 2 ]
%     %||   .k               .k
%     %||     [ 1 1 1 ]        [ 1 1 1 ] }
%     %
%     % because the feature attribtues match, they can now be stacked
%     result=cosmo_stack(ds_int_cell,1);
%     disp(size(result.samples))
%     %|| [12,3]
%
%
% Notes:
%     - A typical use case is finding an intersection mask between
%       volumetric fMRI datasets that have most, but not all, voxels in
%       common - for example, through using individual brain masks.
%
% See also: cosmo_slice
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2
        dim=2;
    end

    check_inputs(ds_cell,dim);

    other_dim=3-dim;


    % record indices in each dataset
    ds_indices_cell=get_dataset_indices(ds_cell,dim,varargin{:});

    % see where each index occurs in each dataset
    each_index=cellfun(@(x)x.samples,ds_indices_cell,...
                            'UniformOutput',false);
    all2some=cat(other_dim,each_index{:});

    keep_msk=all(~isnan(all2some),other_dim);

    n_ds=size(all2some,other_dim);
    indices_cell=cell(n_ds,1);

    for k=1:n_ds
        idx=each_index{k};
        idx(~keep_msk)=NaN;

        idx=idx(isfinite(idx));

        indices_cell{k}=idx;
        assert(all(idx)>0);
        assert(all(round(idx)==idx));
        assert(all(isfinite(idx)));
    end

    assert(all(~isempty(indices_cell)));

    if nargout>1
        ds_intersect_cell=cell(n_ds,1);
        for k=1:n_ds
            ds_intersect_cell{k}=cosmo_slice(ds_cell{k}, ...
                                                indices_cell{k}, dim);
        end
    end


function ds_indices_cell=get_dataset_indices(ds_cell,dim,varargin)
    % for each of the inputs
    % .fa or .sa indices in ds_indices_cell are ordered
    n_ds=numel(ds_cell);
    other_dim=3-dim;

    ds_indices_cell=cell(n_ds,1);
    for k=1:n_ds
        ds1=cosmo_slice(ds_cell{k},1,other_dim);
        n_elem=size(ds1.samples,dim);
        ds1.samples(:)=1:n_elem;

        [arr,labels,values]=cosmo_unflatten(ds1,dim,varargin{:},'set_missing_to',NaN);
        if k==1
            first_labels=labels;
            first_values=values;
        else
            if ~isequal(first_labels,labels)
                error('dim label mismatch between dataset 1 and %d',k);
            end
            if ~isequal(first_values,values)
                error('dim value mismatch between dataset 1 and %d',k);
            end
        end
        ds_indices_cell{k}=cosmo_flatten(arr,labels,values,dim,varargin{:});
    end

function check_inputs(ds_cell,dim)
    if ~iscell(ds_cell)
        error('first argument must be a cell');
    end

    if ~(isequal(dim,1) || isequal(dim,2))
        error('second argument must be 1 or 2');
    end
