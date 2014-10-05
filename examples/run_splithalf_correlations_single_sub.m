% roi-based MVPA for single subject (run_split_half_correlations_single_sub)
%
% Load t-stat data from one subject, apply 'vt' mask, compute difference
% of (fisher-transformed) between on- and off diagonal split-half
% correlation values..

%% Set analysis parameters
subject_id='s01';
roi='vt'; % 'vt' or 'ev' or 'brain'

config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');

%% Computations
data_path=fullfile(study_path, subject_id);

% file locations for both halves
half1_fn=fullfile(data_path,'glm_T_stats_odd.nii');
half2_fn=fullfile(data_path,'glm_T_stats_even.nii');
mask_fn=fullfile(data_path,'brain_mask.nii');

% load two halves as CoSMoMVPA dataset structs.
half1_ds=cosmo_fmri_dataset(half1_fn,'mask',mask_fn);
half2_ds=cosmo_fmri_dataset(half2_fn,'mask',mask_fn);

half1_ds.sa.labels = {'monkey'; 'lemur'; 'mallard'; 'warbler'; 'ladybug'; 'lunamoth'};
cosmo_check_dataset(half1_ds);
nClasses = numel(half1_ds.sa.labels);

% get the sample data
% each half has six samples:
% monkey, lemur, mallard, warbler, ladybug, lunamoth.
half1_samples=half1_ds.samples;
half2_samples=half2_ds.samples;

% compute all correlation values between the two halves, resulting
% in a 6x6 matrix. Store this matrix in a variable 'rho'.
% Hint: use cosmo_corr
% >@@>
rho=cosmo_corr(half1_samples',half2_samples');
% <@@<

% Correlations are limited between -1 and +1, thus they cannot be normally
% distributed. To make these correlations more 'normal', apply a Fisher
% transformation and store this in a variable 'z' (use atanh).
% >@@>
z=atanh(rho);
% <@@<

% visualize the normalized correlation matrix
figure
% >@@>
imagesc(z);
colorbar()
set(gca, 'xtick', 1:numel(half1_ds.sa.labels), 'xticklabel', half1_ds.sa.labels)
set(gca, 'ytick', 1:numel(half1_ds.sa.labels), 'yticklabel', half1_ds.sa.labels)
title(subject_id)
% <@@<

% Set up a contrast matrix to test whether the element in the diagonal
% (i.e. a within category correlation) is higher than the average of all
% other elements in the same row (i.e. the average between-category
% correlations). For testing the split half correlation of n classes one has
% an n x n matrix. Set the diagonals to n, and the off diagonals to 1/n.
% H0 is that within class correlations are equal to the average
% between-class correlations.
% Results in:
% row mean zero, positive on diagonal, negative elsewhere.
% The matrix should have a mean of zero
contrast_matrix=eye(nClasses)-1/nClasses;

if abs(mean(contrast_matrix(:)))>1e-14
    error('illegal contrast matrix');
end

%visualize the contrast matrix
figure
imagesc(contrast_matrix)
colorbar
title('Contrast Matrix')

% Weigh the values in the matrix 'z' by those in the contrast_matrix
% and then average them (hint: use the '.*' operator for element-wise
% multiplication). Store the results in a variable 'mean_weighted_z'.
% >@@>
weighted_z=z .* contrast_matrix;
mean_weighted_z=mean(weighted_z(:)); %Expected value under H0 is 0
% <@@<

%visualize weighted normalized correlation matrix
figure
imagesc(weighted_z)
colorbar
title(sprintf('Weighted Contrast Matrix m = %5.3f', mean_weighted_z))

