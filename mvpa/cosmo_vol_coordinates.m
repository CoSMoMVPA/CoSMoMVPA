function [transformed, outside]=cosmo_vol_coordinates(ds, coords)
% convert to and from spatial (x,y,z) coordinates
%
% [transformed, outside]=cosmo_vol_coordinates(ds[, coords])
%
% Inputs:
%   ds              dataset struct with fields .a.fdim.{labels,values}
%                   (with {'i','j','k'} a subset of .a.fdim.labels) and
%                   .a.vol.{mat,dim}
%   coords          (Optional) one of:
%                   - 1xP matrix of feature indices
%                   - 3xP matrix with spatial (x,y,z) coordinates
%                   If omitted then it is set to 1:nfeatures, with
%                   nfeatures=size(ds.samples,2);
%
% Returns:
%   transformed     - If coords is 1xP: 3xP spatial coordinates of the
%                     feature indices; columns have NaN for feature ids
%                     not in the dataset.
%                   - If coords is 3xP: 1xP feature indices of the
%                     coordinates; an entry is 0 for coordinates not
%                     matching a feature.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % if no coords, return coordinates of all features
    if nargin<2, coords=zeros(1,0); end

    check_input(ds);

    % convert either from or to coordinates
    one_or_three=size(coords,1);
    switch one_or_three
        case 1
            [transformed, outside]=lin2xyz(ds, coords);
        case 3
            [transformed, outside]=xyz2fa_indices(ds, coords);
        otherwise
            error('Input must be 1xP or 3xP ');
    end


function [xyz, outside]=lin2xyz(ds, coords)
    nfeatures=size(ds.samples,2);
    if isempty(coords)
        coords=1:nfeatures;
    end

    % exclude invalid indices
    outside=coords<1 | coords>nfeatures | round(coords)~=coords;
    inside=~outside;
    nfeatures=numel(outside);

    % deal with valid indices
    ds_inside=cosmo_slice(ds, coords(inside), 2);

    % get dataset fa indices
    [fa_ijk, unused, ndim]=get_fa_ijk_indices(ds_inside);

    % store indices in matrix with 4 rows
    ijk=zeros(ndim+1,nfeatures);
    for k=1:ndim
        ijk(k,:)=fa_ijk{k};
    end

    % set last row to 1
    ijk(ndim+1,:)=1;

    % convert to xyz
    xyz1=ds.a.vol.mat*ijk;

    % set elements inside & outside
    ncoords=numel(coords);
    xyz=NaN(ndim, ncoords);
    xyz(:,inside)=xyz1(1:ndim,:);


function [lin2fa, outside]=xyz2fa_indices(ds, coords)
    % ijk indices in dataset
    [fa_ijk, dim_sizes, ndim]=get_fa_ijk_indices(ds);

    % add row of ones to coordinates
    nfeatures=size(coords,2);
    coords1=[coords;ones(1,nfeatures)];

    % convert ijk indices to coordinates
    % TODO: check use of 'round'
    ijk1=round(ds.a.vol.mat\coords1);

    % store ijk indices in cell
    coords_ijk_cell=cell(1,ndim);
    outside=false(1,nfeatures);
    for k=1:ndim
        outside=outside | ijk1(k,:)<1 | ijk1(k,:)>dim_sizes(k);
    end

    for k=1:ndim
        coords_ijk_cell{k}=ijk1(k,~outside);
    end

    % convert to linear indices
    coords_lin=sub2ind(dim_sizes, coords_ijk_cell{:});
    fa_lin=sub2ind(dim_sizes, fa_ijk{:});

    if ~isequal(unique(fa_lin), sort(fa_lin))
        unq=unique(fa_lin);
        h=histc(fa_lin,unq);
        idx=find(h>1,1);
        pos=find(fa_lin==unq(idx),2);
        error('Duplicate feature index at %d and %d', pos);
    end

    % compute mapping from coords indices to fa indices
    nfull=prod(dim_sizes);
    all2fa_lin=zeros(1,nfull);
    all2fa_lin(fa_lin)=1:numel(fa_lin);

    % apply mapping
    lin2fa=zeros(1,nfeatures);
    lin2fa(~outside)=all2fa_lin(coords_lin);
    outside=outside | lin2fa==0;

function [fa_ijk, dim_sizes, ndim]=get_fa_ijk_indices(ds)
% helper: return a cell with i, j, k indices

    dim_labels={'i','j','k'};
    ndim=numel(dim_labels);

    fa_ijk=cell(1,ndim);
    dim_sizes=zeros(1,ndim);
    for k=1:ndim
        dim_label=dim_labels{k};
        [dim, dim_idx, attr_name, dim_name]=cosmo_dim_find(ds,...
                                                        dim_label,true);
        if dim~=2
            error('Unsupported label %s in sample dimension',dim_label);
        end
        dim_values=ds.a.(dim_name).values{dim_idx};
        fa_ijk{k}=dim_values(ds.(attr_name).(dim_label));
        dim_sizes(k)=numel(dim_values);
    end

    if ~isequal(dim_sizes, ds.a.vol.dim)
        error('size mismatch between .a.vol.dim and .a.fdim.values');
    end



function check_input(ds)
    % check input dataset
    cosmo_check_dataset(ds);
    if isstruct(ds) && isfield(ds,'a') && ...
            isfield(ds.a,'vol') && isfield(ds.a.vol,'mat')
        mat=ds.a.vol.mat;
    else
        error('missing fields .a.vol.mat');
    end

    % check matrix
    if ~isnumeric(mat) || ~isequal(size(mat),[4 4])
        error('matrix must be 4x4');
    end