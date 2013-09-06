%% roi-based MVPA with group-analysis
%
% Load t-stat data from all subjects, apply 'vt' mask, compute difference
% of (fisher-transformed) between on- and off diagonal split-half
% correlation values, and perform a random effects analysis.

%% Set analysis parameters 
subject_ids={'s01','s02','s03','s04','s05','s06','s07','s08'};
roi='vt'; % 'vt' or 'ev' or 'brain'
data_type='T_stats'; % 'T_stats' or 'betas'

nsubjects=numel(subject_ids);

% allocate space for output
mean_weighted_zs=zeros(nsubjects,1);

%% Compututations for each subject 
for j=1:nsubjects
    subject_id=subject_ids{j};

    datadir=cosmo_get_data_path(subject_id);
    
    % load the mask
    fn_mask=sprintf('%s/%s_mask.nii', datadir, roi);
    
    % load data from the halves
    fn1=sprintf('%s/glm_%s_evens.nii', datadir, data_type);
    fn2=sprintf('%s/glm_%s_odds.nii', datadir, data_type);
    half1_ds=cosmo_fmri_dataset(fn1,'mask',fn_mask);
    half2_ds=cosmo_fmri_dataset(fn2,'mask',fn_mask);
    
    half1_samples=half1_ds.samples;
    half2_samples=half2_ds.samples;
    
    
    % compute all correlation values between the two halves, resulting
    % in a 6x6 matrix. Store this matrix in a variable 'rho'.
    % >>
    rho=corr(half1_samples',half2_samples');
    % <<
    
    % To make these correlations more 'normal', apply a Fisher
    % transformation and store this in a variable 'z' (use atanh).
    % >>
    z=atanh(rho);
    % <<
    
    % visualize the matrix
    subplot(3,3,j);
    % >>
    imagesc(z);
    colorbar()
    % <<
    title(subject_id)
    
    
    % <<

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
    % >>
    weighted_z=z .* contrast_matrix;

    mean_weighted_z=mean(weighted_z(:));
    % <<
    
    % store the result for this subject
    mean_weighted_zs(j)=mean_weighted_z;
end

%% compute t statistic and print the result
[h,p,ci,stats]=ttest(mean_weighted_zs);
fprintf('ROI %s: mean %.3f, t_%d=%.3f, p=%.4f\n', roi, mean(mean_weighted_zs), stats.df, stats.tstat, p);
