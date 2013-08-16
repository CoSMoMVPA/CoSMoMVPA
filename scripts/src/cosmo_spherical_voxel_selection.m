function center2neighbors=cosmo_spherical_voxel_selection(dataset, radius, center_ids)
% computes neighbors for a spherical searchlight
%
% center2neighbors=cosmo_spherical_voxel_selection(dataset, radius[, center_ids])
%
% Inputs
%  - dataset       a dataset struct (from fmri_dataset)
%  - radius        sphere radius (in voxel units)
%  - center_ids    Px1 vector with feature ids to consider. If omitted it
%                  will consider all features in dataset
% 
% Output
%  - center2neighbors  Px1 cell so that center2neighbors{k}==nbrs contains
%                      the feature ids of the neighbors of feature k
%                      
% NNO Aug 2013

[nsamples, nfeatures]=size(dataset.samples);

if nargin<3
    center_ids=1:nfeatures;
end

% get size of original volume
orig_dim=dataset.a.imghdr.hdr.dime.dim(2:4);
orig_nvoxels=prod(orig_dim);

% mapping from all linear voxel indices to those in the dataset
map2full=zeros(orig_nvoxels,1);
map2full(dataset.a.mapper)=1:nfeatures;

% offsets in i,j,k direction for searchlight sphere
sphere_offsets=cosmo_sphere_offsets(radius);

% space for output
accs=zeros(1,nfeatures);

ncenters=numel(center_ids);
center2neighbors=cell(ncenters,1);

% go over all features
for k=1:ncenters
    center_id=center_ids(k);
    center_ijk=dataset.fa.voxel_indices(:,center_id);
    
    % add offsets to center
    around_ijk=bsxfun(@plus, center_ijk', sphere_offsets);
    
    % see which ones are outside the volume
    outside_msk=around_ijk<=0 | bsxfun(@minus,orig_dim,around_ijk)<0;
    
    % collapse over 3 dimensions
    feature_outside_msk=sum(outside_msk,2)>0;
    
    % get rid of those outside the volume
    around_ijk=around_ijk(~feature_outside_msk,:);
    
    % convert to linear indices
    around_lin=sub2ind(orig_dim,around_ijk(:,1), around_ijk(:,2), around_ijk(:,3));
    
    % convert linear to feature ids
    around_feature_ids=map2full(around_lin);
    
    % also exclude those that were not mapped (outside the mask)
    around_feature_ids=around_feature_ids(around_feature_ids>0);
    
    % store results
    center2neighbors{k}=around_feature_ids;
    
    if k==1 || k==ncenters || mod(k,100)==0
        fprintf('completed %d / %d centers\n', k, ncenters);
    end
end
