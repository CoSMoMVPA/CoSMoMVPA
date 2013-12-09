function nbrhood=cosmo_spherical_voxel_selection(ds, radius, opt)
% computes neighbors for a spherical searchlight
%
% nbrhood=cosmo_spherical_voxel_selection(ds, radius[, center_ids])
%
% Inputs
%   ds            a dataset struct (from fmri_dataset)
%   radius        if positive, it indicates sphere radius (in voxel
%                 units). If negative then (-radius) indicates the 
%                 (minimum) number of voxels that should be selected 
%                 in each searchlight. 'minimum' means that at least 
%                 (-radius) voxels are selected, and that the voxels that 
%                 are not selected are all further away from the center
%                 than those that are selected.
% 
% Outputs
%   nbrhood           dataset-like struct without .sa or .samples, with:
%     .a              dataset attributes, from dataset.a
%     .fa             feature attributes with fields:
%       .nvoxels      1xP number of voxels in each searchlight
%       .radius       1xP radius in voxel units
%       .center_ids   1xP feature center id
%     .neighbors      Px1 cell so that center2neighbors{k}==nbrs contains
%                     the feature ids of the neighbors of feature k
%                      
% NNO Aug 2013
    
    cosmo_check_dataset(ds,'fmri');
    [nsamples, nfeatures]=size(ds.samples);
    
    center_ids=1:nfeatures;
    
    if nargin<3 || isempty(opt);
        opt=struct;
    end
    
    if ~isfield(opt,'progress')
        opt.progress=1000;
    end
    
    show_progress=opt.progress>0;
    
    
    ndim=numel(ds.a.dim.values);
    orig_dim=zeros(1,ndim);
    for k=1:ndim
        orig_dim(k)=numel(ds.a.dim.values{k});
    end
    orig_nvoxels=prod(orig_dim);
    
    % mapping from all linear voxel indices to those in the dataset
    map2full=zeros(orig_nvoxels,1);
    lin=sub2ind(orig_dim, ds.fa.i, ds.fa.j, ds.fa.k);
    map2full(lin)=1:nfeatures;
    
    % offsets in i,j,k direction for searchlight sphere
    use_fixed_radius=radius>0;
    if ~use_fixed_radius
        fixed_voxel_count=-radius;
        radius=1; % as a starting point
    end
    
    % compute voxel offsets relative to origin
    [sphere_offsets, center_distances]=cosmo_sphere_offsets(radius);
    
    % allocate space for output
    ncenters=numel(center_ids);
    neighbors=cell(ncenters,1);
    nvoxels=zeros(1,ncenters);
    final_radius=zeros(1,ncenters);
    
    if show_progress
        if opt.progress<1
            opt.progress=ceil(ncenters/opt.progress);
        end
        clock_start=clock();
        prev_progress_msg='';
    end
    
    % get the indices for output
    ijk_indices=[ds.fa.i; ds.fa.j; ds.fa.k];
    
    % go over all features
    for k=1:ncenters
        center_id=center_ids(k);
        center_ijk=ijk_indices(:,center_id);
        
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
        neighbors{k}=around_feature_ids;
        nvoxels(k)=numel(around_feature_ids);
        if use_fixed_radius
            final_radius(k)=radius;
        else
            final_radius(k)=variable_radius;
        end
        
        if show_progress && (k==1 || k==ncenters || mod(k,opt.progress)==0)
            mean_size=mean(nvoxels(1:k));
            msg=sprintf('mean size %.1f', mean_size);
            prev_progress_msg=cosmo_show_progress(clock_start, k/ncenters, msg, prev_progress_msg);
        end
    end
    
    % set the dataset and feature attributes
    nbrhood=struct();
    nbrhood.a=ds.a;
    nbrhood.fa.nvoxels=nvoxels;
    nbrhood.fa.radius=final_radius;
    nbrhood.fa.center_ids=center_ids(:)';
    nbrhood.fa.i=ds.fa.i(center_ids);
    nbrhood.fa.j=ds.fa.j(center_ids);
    nbrhood.fa.k=ds.fa.k(center_ids);
    
    nbrhood.neighbors=neighbors;
