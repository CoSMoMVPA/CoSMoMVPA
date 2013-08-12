%% roi-based MVPA with group-analysis
%
% Load t-stat data from all subjects, apply 'ev' mask, compute difference
% of (fisher-transformed) between on- and off diagonal split-half
% correlation values, and perform a random effects analysis

subject_ids={'s01','s02','s03','s04'};
roi='ev'; % 'vt' or 'ev' or 'brain'
data_type='T_stats'; % 'T_stats' or 'betas'

nsubjects=numel(subject_ids);

% allocate space for output
mean_weighted_zs=zeros(nsubjects,1);

% do compututation for each subject 
for j=1:nsubjects
    subject_id=subject_ids{j};

    datadir=cosmo_get_data_path(subject_id);
    fn1=sprintf('%s/glm_%s_evens.nii.gz', datadir, data_type);
    fn2=sprintf('%s/glm_%s_odds.nii.gz', datadir, data_type);
    fn_mask=sprintf('%s/%s_mask.nii.gz', datadir, roi);

    ni_mask=load_nii(fn_mask);
    ni_samples1=load_nii(fn1);
    ni_samples2=load_nii(fn2);

    half1_samples_4D=ni_samples1.img;
    half2_samples_4D=ni_samples2.img;

    % define the feature (voxel) mask
    feature_mask=logical(ni_mask.img);
    nfeatures=sum(feature_mask(:));
    
    nsamples_per_half=size(half1_samples_4D,4);
    if nsamples_per_half~=size(half2_samples_4D,4)
        error('sample size mismatch');
    end
    
    % allocate space for data of the two halves in the ROI
    half1_samples_masked=zeros(nsamples_per_half, nfeatures);
    half2_samples_masked=zeros(nsamples_per_half, nfeatures);

    % store the values in the mask (use a 'for' loop to
    % go from 1 to nsamples_per_half, and use 'feature_mask')
    % [your code here] 
    
    % compute the average of the fisher-transformed correlation
    % values between the two halves, and store this result
    % in 'mean_weighted_z' [Use 'atanh' and '.*'].
    % [your code here]
    
    % store the result for this subject
    mean_weighted_zs(j)=mean_weighted_z;
end

% compute t statistic and print the result
[h,p,ci,stats]=ttest(mean_weighted_zs);
fprintf('ROI %s: t_%d=%.3f, p=%.4f\n', roi, stats.df, stats.tstat, p);
