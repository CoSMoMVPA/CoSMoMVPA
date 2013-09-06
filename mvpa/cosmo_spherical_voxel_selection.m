function [center2neighbors,neighborhood_size]=cosmo_spherical_voxel_selection(dataset, radius, center_ids)
% computes neighbors for a spherical searchlight
%
% center2neighbors=cosmo_spherical_voxel_selection(dataset, radius[, center_ids])
%
% Inputs
%  - dataset       a dataset struct (from fmri_dataset)
%  - radius        if positive, it indicates sphere radius (in voxel
%                  units). If negative then (-radius) indicates the 
%                  (minimum) number of voxels in each searchlight
%  - center_ids    Px1 vector with feature ids to consider. If omitted it
%                  will consider all features in dataset
% 
% Outputs
%  - center2neighbors  Px1 cell so that center2neighbors{k}==nbrs contains
%                      the feature ids of the neighbors of feature k
%  - neighborhood_size Px1 size of each searchlight. If radius>0 then it
%                      contains the number of voxels in each searchlight. 
%                      If radius<0 then it contains the sphere radius 
%                      in voxel units.
%                      
% NNO Aug 2013
    
    [nsamples, nfeatures]=size(dataset.samples);
    
    if nargin<3 || isempty(center_ids)
        center_ids=1:nfeatures;
    end
    
    % get size of original volume
    orig_dim=dataset.a.vol.dim;
    orig_nvoxels=prod(orig_dim);
    
    % mapping from all linear voxel indices to those in the dataset
    map2full=zeros(orig_nvoxels,1);
    sub=dataset.fa.voxel_indices;
    lin=sub2ind(orig_dim, sub(1,:), sub(2,:), sub(3,:));
    map2full(lin)=1:nfeatures;
    
    % offsets in i,j,k direction for searchlight sphere
    use_fixed_radius=radius>0;
    if ~use_fixed_radius
        fixed_voxel_count=-radius;
        radius=1; % as a starting point
    end
    
    [sphere_offsets, center_distances]=cosmo_sphere_offsets(radius);
    
    ncenters=numel(center_ids);
    center2neighbors=cell(ncenters,1);
    neighborhood_size=zeros(ncenters,1);
    
    % go over all features
    for k=1:ncenters
        center_id=center_ids(k);
        center_ijk=dataset.fa.voxel_indices(:,center_id);
        
        % in case of a variable radius, keep growing sphere_offsets until
        % there are enough voxels selected. This new radius is kept
        % for every subsequent iteration
        % when a fixed radius is used then this loop is left after 
        % the first iteration.
        while true
            % add offsets to center
            around_ijk=bsxfun(@plus, center_ijk', sphere_offsets);

            % see which ones are outside the volume
            outside_msk=around_ijk<=0 | bsxfun(@minus,orig_dim,around_ijk)<0;

            % collapse over 3 dimensions
            feature_outside_msk=sum(outside_msk,2)>0;

            % get rid of those outside the volume
            around_ijk=around_ijk(~feature_outside_msk,:);
            
            % if using variable radius, keep track of those 
            if ~use_fixed_radius
                distances=center_distances(~feature_outside_msk);
            end

            % convert to linear indices
            around_lin=sub2ind(orig_dim,around_ijk(:,1), around_ijk(:,2), around_ijk(:,3));

            % convert linear to feature ids
            around_feature_ids=map2full(around_lin);

            % also exclude those that were not mapped (outside the mask)
            feature_mask=around_feature_ids>0;
            around_feature_ids=around_feature_ids(feature_mask);
            
            if use_fixed_radius
                break; % we're done selecting voxels
            elseif numel(around_feature_ids)<fixed_voxel_count
                % the current radius is too small.
                % increase the radius by half a voxel and recompute new
                % offsets, then try again in the next iteration.
                radius=radius+.5;   
                [sphere_offsets, center_distances]=cosmo_sphere_offsets(radius);
                continue; 
            end
            
            % coming here, the radius is variable and enough features
            % were selected. Now decide which voxels to keep,
            % and also compute the metric radius, then leave the while
            % loop.
            
            % apply the feature_id mask to distances
            distances=distances(feature_mask);
            
            % see how big the searchlight is (in metric distance)
            variable_radius=distances(fixed_voxel_count);

            % keep all voxels with exactly the same distance
            % (and those of smaller distances as well)
            last_index=fixed_voxel_count-1+find(...
                    variable_radius==distances(fixed_voxel_count:end),1);
            around_feature_ids=around_feature_ids(1:last_index,:);
            break; % we're done
        end

        
        % store results
        center2neighbors{k}=around_feature_ids;
        if use_fixed_radius
            neighborhood_size(k)=numel(around_feature_ids);
        else
            neighborhood_size(k)=variable_radius;
        end
        
        if k==1 || k==ncenters || mod(k,100)==0
            mean_size=mean(neighborhood_size(1:k));
            fprintf('completed %d / %d centers (mean size %.1f)\n', k, ncenters, mean_size);
        end
    end
    