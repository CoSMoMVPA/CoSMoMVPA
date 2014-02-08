function nbrhood=cosmo_cluster_neighborhood(ds, nbrhood_size)
% Returns a neighborhood for a dataset suitable for cluster-based analysis.
%
% nbrhood=cosmo_cluster_neighborhood(ds, nbrhood_size, parent_type)
%
% Inputs:
%   ds              One of the following
%                   - if a Nx1 vector, then ds is interpreted as the
%                     size of an NDIM-dimensional array with size ds(1) x
%                     ds(2) x ... x ds(N). 
%                   - if a struct, it should be an fmri or meeg dataset
%   nbrhood_size    One of the following:
%                   - if a single number then ds should be a vector or
%                     an fmri dataset. nbrhood_size indicates along how 
%                     many dimensions distances of neighbors can differ
%                     by one. For example, in an fmri dataset, or if 
%                     ds is a vector with 3 elements, then 1=sharing side; 
%                     2=sharing edge; and 3=sharing corner. In other words,
%                     two elements are neighbors if all their coordinates
%                     differ by at most 1 and their manhattan distance is
%                     not greater than nbrhood_size. 
%                   - if multiple numbers then ds should be a vector or
%                     an meeg dataset with NDIM the number of dimensions. 
%                     nbrhood_size(K) should be either 0 (no clustering 
%                     along K-th dimension) or 1 (do clustering along K-th
%                     dimension), except when ds is an meeg dataset with 
%                     channels in the J-th dimension, in which case 
%                     nbrhood_size(J) defines neighborhood through 
%                     cosmo_meeg_chan_nbrs (NaN for Delauney, negative
%                     values to indicate the number of channels; positive
%                     numbers to indicate the maximum euclidian distance).
%
% Output:
%   nbrhood         One of the following:
%                   - if ds is a vector, then nbrhood is a prod(ds)x1 cell
%                     with ds(k) containing the linear indices of the
%                     neighbors of the k-th value in an array of size ds.
%                   - otherwise (ds is an fmri or meeg dataset) it is a 
%                     struct with fields .neighbors, .a. and .fa
%                     as returned by cosmo_spherical_voxel_selection
%                     or cosmo_meeg_neighborhood
%
% Notes:
%   - MEEG datasets cannot have mixed sensor types
%
% See also cosmo_meeg_neighborhood, cosmo_spherical_voxel_selection, 
%          cosmo_meeg_chan_nbrs.
%
% NNO Oct 2013

% handle numeric case
if isnumeric(ds)
    sz=ds; % number of values along each dimension
    ndim=numel(sz);
    
    if sum(size(ds)>1)>1
        % not a vector
        error('Numeric array must be size vector');
    end
    
    % position of neighbors of origin
    dim_pos=cosmo_cartprod(repmat({-1:1},1,ndim));
    
    % see if nbrhood was specified as diagonal distance
    diag_nbrhood=numel(nbrhood_size)==1;
    
    % set the mask for dim_pos
    if diag_nbrhood
        if ~any(nbrhood_size==1:ndim)
            error('singleton nbrhood size should be in 1:%d',ndim)
        end
        
        msk=sum(dim_pos.^2,2)<=nbrhood_size;
    else
        if ~all(cosmo_match(nbrhood_size,[0,1])) || ...
                        ndim~=numel(nbrhood_size)
            error('nbrhood should be 1x%d with values 0 or 1',ndim);
        end
        
        msk=sum(bsxfun(@le, abs(dim_pos), nbrhood_size),2)==ndim;
    end
    
    % trim dim_pos to contain only indices in desired neighborhood
    dim_pos=dim_pos(msk,:);
    
    % generate a matrix with the sub-indices of all features
    sz_cell=num2cell(sz);
    indices_cell=cellfun(@(x) {1:x}, sz_cell);
    feature_pos=cosmo_cartprod(indices_cell);
    
    % allocate space for output
    nfeatures=prod(sz);
    nbrhood=cell(nfeatures,1);
    
    for k=1:nfeatures
        fpos=feature_pos(k,:);
        
        % get position of neighbors expressed in sub-indices
        sub_pos=bsxfun(@plus,fpos,dim_pos);
        
        % mask out neighbors out of bounds
        in_bounds=sum(sub_pos>0 & bsxfun(@le, sub_pos, sz),2)==ndim;
        sub_pos=sub_pos(in_bounds,:);
        
        if ndim==1
            % no conversion to linear indices necessary
            ind_pos=sub_pos;
        else            
            % prepare of sub2ind: put all subindices in a cell, seperately
            sub_pos_cell=cell(1,ndim);
            for dim=1:ndim
                sub_pos_cell{dim}=sub_pos(:,dim);
            end
            
            % convert neighbor sub to linear indices
            ind_pos=sub2ind(sz,sub_pos_cell{:});
        end

        nbrhood{k}=ind_pos;
    end
    
% fmri dataset case    
elseif cosmo_check_dataset(ds,'fmri',false);
    if ~any(nbrhood_size==1:3)
        error('fmri dataset: clustdef should be 1, 2 or 3'); 
    end

    if nargin>=3
        error('Cannot have parent_type with fmri dataset');
    end

    radius=sqrt(nbrhood_size)+.01;

    nbrhood=cosmo_spherical_voxel_selection(ds, radius);

% meeg dataset case
elseif cosmo_check_dataset(ds,'meeg',false);
    labels=ds.a.dim.labels;
    ndim=numel(labels);

    if numel(nbrhood_size)~=ndim
        error('require clustdef with %d values', ndim);
    end

    chandim=find(cosmo_match(ds.a.dim.labels,'chan'));
    otherdims=setdiff(1:ndim,chandim);
    illegal_other=find(~cosmo_match(nbrhood_size(otherdims),[0,1]));
    if any(illegal_other)
        error('illegal clustering value: %d (should be 0 or 1)', ...
                    nbrhood_size(otherdims(illegal_other(1))));
    end

    nbrhood_size(otherdims)=nbrhood_size(otherdims)+1;
    
    nbrhood=cosmo_meeg_neighborhood(ds,nbrhood_size);

else
    error('Cannot input type: no array, or fmri or meeg dataset');
end
