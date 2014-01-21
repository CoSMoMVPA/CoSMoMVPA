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
study_path=fullfile(config.data_path,'ak6');

%% Compututations for each subject 
for j=1:nsubjects
    subject_id=subject_ids{j};

    data_path=fullfile(study_path, subject_id);
    
    data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
    mask_fn=fullfile(data_path,sprintf('%s_mask.nii', roi));
    
    targets=repmat(1:6,1,10)';
    chunks=mod(floor(((1:60)-1)/6),2)+1; % odd and even runs
    ds_full = cosmo_fmri_dataset(data_fn, ...
                        'mask',mask_fn,...
                        'targets',targets,...
                        'chunks',chunks);      


    % The example data used here has no estimates for odd and even runs 
    % computed from the GLM. Instead we generate such data here.
    % If one were to use pre-computed files with even and odd runs, then
    % these can simply be loaded using:
    % >> ni_samples1=load_nii(fn1);
    % >> ni_samples2=load_nii(fn2);

    % use a helper function to average samples - for each unique combination of
    % targets and chunks. The resulting output has 12 features (6 targets times
    % 2 chunks). Don't worry if you find the next few lines difficult to
    % understand - they just show a quick way to generate even and odd run 
    % data.                             
                    
    ds_odd_even=cosmo_fx(ds_full,@(x)mean(x,1),{'targets','chunks'});                    

    odd_run_msk=mod(ds_odd_even.sa.chunks,2)==1;
    half1_ds=cosmo_slice(ds_odd_even,odd_run_msk);

    even_run_msk=~odd_run_msk;
    half2_ds=cosmo_slice(ds_odd_even,even_run_msk);

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
