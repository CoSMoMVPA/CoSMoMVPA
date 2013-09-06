%% Spherical searchlight
% this example implements a spherical searchlight using
% cosmo_spherical_voxel_selection and performs crossvalidation
% with a nearest neighbor classifier

datadir=cosmo_get_data_path('s01');
fn=[datadir 'glm_T_stats_perrun.nii'];
maskfn=[datadir 'brain_mask.nii'];
radius=3;
targets=repmat(1:6,1,10);
chunks=floor(((1:60)-1)/6)+1;
classifier=@cosmo_classify_nn;
classifier_opt=struct();

% load data and set sample attributes
ds=cosmo_fmri_dataset(fn, 'mask', maskfn, 'targets', targets, 'chunks', chunks);
nfeatures=size(ds.samples,2);
center_ids=1:nfeatures; % for now, consider all voxels

% use voxel selection function
center2neighbors=cosmo_spherical_voxel_selection(ds, radius, center_ids);
%% set up cross validation
% 
partitions=cosmo_nfold_partitioner(ds.sa.chunks);

%% Allocate space for output
ncenters=numel(center_ids);
accs=zeros(1,ncenters);

%% Run the searchlight
% go over all features, run cross-validation and store the classiifcation
% accuracies.
% >>
for k=1:ncenters
    center_id=center_ids(k);
    sphere_feature_ids=center2neighbors{center_id};
    
    sphere_ds=cosmo_dataset_slice_features(ds, sphere_feature_ids);
    
    % run cross validation
    [pred_cv,acc]=cosmo_cross_validate(sphere_ds, classifier, partitions, classifier_opt);
    
    % for now, just store the accuracy (not the predictions)
    accs(k)=acc;
    
    % show progress every 100 steps
    if k==1 || mod(k,100)==0 || k==nfeatures
        fprintf('%d / %d features: average accuracy %.3f\n', k, nfeatures, mean(accs(1:k)));
    end
end
% <<

%% store the output
res_map=ds;
res_map.samples=accs;

cosmo_map2fmri(res_map,[datadir  'voxel_selection_searchlight.nii']);