.. run_splithalf_correlations_skl

run splithalf correlations skl
==============================
.. code-block:: matlab

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
        ni_mask=load_nii(fn_mask);
        
        % load data from one half and store it in a 4D array.
        fn1=sprintf('%s/glm_%s_evens.nii', datadir, data_type);
        ni_samples1=load_nii(fn1);
        half1_samples_4D=ni_samples1.img;
        
        % do the same for data in the other half
        %%%% >>> YOUR CODE HERE <<< %%%%
    
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
        % go from 1 to nsamples_per_half, extract one volume
        % per iterations, then use 'feature_mask')
        %%%% >>> YOUR CODE HERE <<< %%%% 
        
        % compute all correlation values between the two halves, resulting
        % in a 6x6 matrix. Store this matrix in a variable 'rho'.
        %%%% >>> YOUR CODE HERE <<< %%%%
        
        % To make these correlations more 'normal', apply a Fisher
        % transformation and store this in a variable 'z' (use atanh).
        %%%% >>> YOUR CODE HERE <<< %%%%
    
        % define how correlations values are going to be weighted
        % mean zero, positive on diagonal, negative elsewhere
        contrast_matrix=eye(6)-1/6; 
    
        % Weigh the values in the matrix 'z' by those in the contrast_matrix
        % and then average them (hint: use the '.*' operator for element-wise 
        % multiplication). Store the results in a variable 'mean_weighted_z'.
        %%%% >>> YOUR CODE HERE <<< %%%%
        
        % store the result for this subject
        mean_weighted_zs(j)=mean_weighted_z;
    end
    
    %% compute t statistic and print the result
    [h,p,ci,stats]=ttest(mean_weighted_zs);
    fprintf('ROI %s: mean %.3f, t_%d=%.3f, p=%.4f\n', roi, mean(mean_weighted_zs), stats.df, stats.tstat, p);
    