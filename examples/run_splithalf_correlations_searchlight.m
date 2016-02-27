%% Volumetric fMRI Searchlight
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Load data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% In this exercise, output (NIFTI files) will be written to this directory
output_data_path=config.output_data_path;

% file locations for both halves
half1_fn=fullfile(data_path,'glm_T_stats_odd.nii');
half2_fn=fullfile(data_path,'glm_T_stats_even.nii');
mask_fn=fullfile(data_path, 'brain_mask.nii');

% load two halves as CoSMoMVPA dataset structs.
half1_ds=cosmo_fmri_dataset(half1_fn,'mask',mask_fn,...
                                     'targets',(1:6)',...
                                     'chunks',repmat(1,6,1));
half2_ds=cosmo_fmri_dataset(half2_fn,'mask',mask_fn,...
                                     'targets',(1:6)',...
                                     'chunks',repmat(2,6,1));
ds=cosmo_stack({half1_ds,half2_ds});

% remove constant features (caused by liberal masking)
ds=cosmo_remove_useless_data(ds);

%% Define spherical neighborhood for each feature (voxel)

radius=3; % searchlight radius in voxels

% Using cosmo_spherical_neighborhood, define a neighborhood with
% a radius of 3 voxels for each voxel. Assign the result to
% a variable named 'nbrhood'
% >@@>
nbrhood=cosmo_spherical_neighborhood(ds,'radius',radius);
% <@@<

% Compute the number of elements in each element of nbrhood.neighbors,
% and assign the result to a variable 'roi_sizes'
% >@@>
roi_sizes=cellfun(@numel,nbrhood.neighbors);
% <@@<

% Plot a histogram of 'roi_sizes'
% >@@>
hist(roi_sizes,100)
% <@@<

%% Run a searchlight with the cosmo_correlation_measure

% Use cosmo_searchlight with 'ds' as the dataset input,
% a function handle of cosmo_correlation_measure as the measure,
% and the spherical neighborhood just defined to run a searchlight.
% Assign the result to a variable 'ds_corr'.
% >@@>
ds_corr=cosmo_searchlight(ds,nbrhood,@cosmo_correlation_measure);
% <@@<

%% Visualize and store the results in a NIFTI file

% Visualize the results using cosmo_plot_slices
% Hint: this function takes datasets with one sample directly as input
% >@@>
cosmo_plot_slices(ds_corr)
% <@@<

% Set output filename
output_fn=fullfile(output_data_path,...
            sprintf('splithalf_correlation_searchlight_r%.0f.nii',radius));

% Write output to a NIFTI file using cosmo_map2fmri
% >@@>
cosmo_map2fmri(ds_corr, output_fn);
% <@@<
