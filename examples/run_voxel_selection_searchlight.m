%% Spherical searchlight
% this example implements a spherical searchlight using
% cosmo_spherical_voxel_selection and performs crossvalidation
% with a nearest neigh classifier


%% Set up parameters
config=cosmo_config();
data_path=fullfile(config.data_path,'ak6','s01');

fn=fullfile(data_path,'glm_T_stats_perrun.nii');
maskfn=fullfile(data_path,'brain_mask.nii');
radius=3;
targets=repmat(1:6,1,10);
chunks=floor(((1:60)-1)/6)+1;
classifier=@cosmo_classify_nn;
classifier_opt=struct();

%% load data and set sample attributes
ds=cosmo_fmri_dataset(fn, 'mask', maskfn, 'targets', targets, 'chunks', chunks); 

%% define centers of searchlight
nfeatures=size(ds.samples,2);
center_ids=1:nfeatures;

%% use voxel selection function
nbrhood=cosmo_spherical_voxel_selection(ds, radius);
center2neighbors=nbrhood.neighbors;
ncenters=numel(center2neighbors); % should be equal to 'nfeatures'

%% set up cross validation
% (here we use cosmo_oddeven_partitioner; cosmo_nfold_partitioner would be
% another possiblity, with the advantage of using a larger training set, 
% but the disadvantage that it takes longer to run)
partitions=cosmo_oddeven_partitioner(ds.sa.chunks);

%% Allocate space for output
ncenters=numel(center_ids);
accs=zeros(1,ncenters);

%% Run the searchlight
% go over all features: in each iteration, slice the dataset to get the 
% desired features using center2neighbors, then use cosmo_cross_validate
% to get classification accuracies (it's its second output argument),
% and store the classiifcation accuracies.
for k=1:ncenters
    % >>
    center_id=center_ids(k);
    sphere_feature_ids=center2neighbors{center_id};
    
    sphere_ds=cosmo_slice(ds, sphere_feature_ids, 2);
    
    % run cross validation
    [pred_cv,acc]=cosmo_cross_validate(sphere_ds, classifier, partitions, classifier_opt);
    
    % for now, just store the accuracy (not the predictions)
    accs(center_id)=acc;
    
    % show progress every 1000 steps, and a the beginning and end.
    if k==1 || mod(k,1000)==0 || k==nfeatures
        fprintf('%d / %d features: average accuracy %.3f\n', k, nfeatures, mean(accs(1:k)));
    end
    % <<
end

%% store the output
% this uses the neighborhood from spherical voxel selection
res_map=nbrhood;
res_map.samples=accs;

% use the following command to store the output map
% >> cosmo_map2fmri(res_map,[data_path  '/voxel_selection_searchlight.nii']);

%% Plot a few slices
cosmo_plot_slices(res_map);
