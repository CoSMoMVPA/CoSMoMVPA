%% roi-based MVPA with group-analysis
%
% Load t-stat data from all subjects, apply 'vt' mask, compute difference
% of (fisher-transformed) between on- and off diagonal split-half
% correlation values, and perform a random effects analysis.

%% Set analysis parameters 
subject_ids={'s01','s02','s03','s04','s05','s06','s07','s08'};
roi='vt'; % 'vt' or 'ev' or 'brain'

nsubjects=numel(subject_ids);

% allocate space for output
mean_weighted_zs=zeros(nsubjects,1);

config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');

%% Compututations for each subject 
for j=1:nsubjects
    subject_id=subject_ids{j};

    data_path=fullfile(study_path, subject_id);
    
    % file locations for both halves
    half1_fn=fullfile(data_path,'glm_T_stats_odd.nii');
    half2_fn=fullfile(data_path,'glm_T_stats_even.nii');
    mask_fn=fullfile(data_path,'brain_mask.nii');

    % load two halves as CoSMoMVPA dataset structs.
    half1_ds=cosmo_fmri_dataset(half1_fn,'mask',mask_fn);
    half2_ds=cosmo_fmri_dataset(half2_fn,'mask',mask_fn);
    
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
    
    % To make these correlations more 'normal', apply a Fisher
    % transformation and store this in a variable 'z' (use atanh).
    % >@@>
    z=atanh(rho);
    % <@@<
    
    % visualize the matrix
    subplot(3,3,j);
    % >@@>
    imagesc(z);
    colorbar()
    title(subject_id)
    % <@@<

    % define how correlations values are going to be weighted
    % mean zero, positive on diagonal, negative elsewhere.
    % The matrix should have a mean of zero
    contrast_matrix=eye(6)-1/6; 

    if abs(mean(contrast_matrix(:)))>1e-14
        error('illegal contrast matrix');
    end
    
    % Weigh the values in the matrix 'z' by those in the contrast_matrix
    % and then average them (hint: use the '.*' operator for element-wise 
    % multiplication). Store the results in a variable 'mean_weighted_z'.
    % >@@>
    weighted_z=z .* contrast_matrix;

    mean_weighted_z=mean(weighted_z(:));
    % <@@<
    
    % store the result for this subject
    mean_weighted_zs(j)=mean_weighted_z;
end

%% compute t statistic and print the result
[h,p,ci,stats]=ttest(mean_weighted_zs);
fprintf('ROI %s: mean %.3f, t_%d=%.3f, p=%.4f\n', roi, mean(mean_weighted_zs), stats.df, stats.tstat, p);
