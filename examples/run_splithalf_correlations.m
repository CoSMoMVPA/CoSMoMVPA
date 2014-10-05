%% roi-based MVPA with group-analysis
%
% Load t-stat data from all subjects, apply 'vt' mask, compute difference
% of (fisher-transformed) between on- and off diagonal split-half
% correlation values, and perform a random effects analysis.

%% Set analysis parameters
subject_ids={'s01','s02','s03','s04','s05','s06','s07','s08'};
rois={'ev'; 'vt'; 'brain'};
labels = {'monkey'; 'lemur'; 'mallard'; 'warbler'; 'ladybug'; 'lunamoth'};

nsubjects=numel(subject_ids);

% allocate space for output
mean_weighted_zs=zeros(nsubjects,1);

config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');


%% Loop over rois
for iRoi = 1:numel(rois)
    %% Computations for each subject
    for j=1:nsubjects
        subject_id=subject_ids{j};
        
        data_path=fullfile(study_path, subject_id);
        
        % file locations for both halves
        half1_fn=fullfile(data_path,'glm_T_stats_odd.nii');
        half2_fn=fullfile(data_path,'glm_T_stats_even.nii');
        
        %mask name for given subject and roi
        mask_fn=fullfile(data_path,[rois{iRoi},'_mask.nii']);
        
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
        if j == 1
            rho_sum(:, :, iRoi)=rho;
        else
            rho_sum(:, :, iRoi)=rho_sum(:, :, iRoi)+rho;%for the advanced exercise: sum up all individual correlation matrices
        end
        % <@@<
        
        % To make these correlations more 'normal', apply a Fisher
        % transformation and store this in a variable 'z' (use atanh).
        % >@@>
        z=atanh(rho);
        % <@@<
        
        % visualize the matrix 'z'
        subplot(3,3,j);
        % >@@>
        imagesc(z);
        colorbar()
        title(subject_id)
        % <@@<
        
        % define in a variable 'contrast_matrix' how correlations values
        % are going to be weighted.
        % The matrix must have a mean of zero, positive values on diagonal,
        % negative elsewhere.
        contrast_matrix=eye(6)-1/6;
        
        if abs(mean(contrast_matrix(:)))>1e-14
            error('illegal contrast matrix');
        end
        
        % Weigh the values in the matrix 'z' by those in the contrast_matrix
        % and then average them (hint: use the '.*' operator for element-wise
        % multiplication). Store the results in a variable 'mean_weighted_z'.
        % >@@>
        weighted_z=z.*contrast_matrix;
        
        mean_weighted_z=mean(weighted_z(:));
        % <@@<
        
        % store the result for this subject
        mean_weighted_zs(j)=mean_weighted_z;
    end
    
    %% compute t statistic and print the result
    % run one-sample t-test again zero
    
    % Using cosmo_stats - convert to dataset struct.
    % The targets are chunks are set to indicate that all samples are from the
    % same class (condition), and each observation is independent from the
    % others
    mean_weighted_zs_ds=struct();
    mean_weighted_zs_ds.samples=mean_weighted_zs;
    mean_weighted_zs_ds.sa.targets=ones(nsubjects,1);
    mean_weighted_zs_ds.sa.chunks=(1:nsubjects)';
    
    
    ds_t=cosmo_stat(mean_weighted_zs_ds,'t');     % t-test against zero
    ds_p=cosmo_stat(mean_weighted_zs_ds,'t','p'); % convert to p-value
    
    fprintf(['correlation difference in %s at group level: '...
        '%.3f +/- %.3f, %s=%.3f, p=%.5f (using cosmo_stat)\n'],...
        rois{iRoi},mean(mean_weighted_zs),std(mean_weighted_zs),...
        ds_t.sa.stats{1},ds_t.samples,ds_p.samples);
    
    % Using matlab's stat toolbox (if present)
    if cosmo_check_external('@stats',false)
        [h,p,ci,stats]=ttest(mean_weighted_zs);
        fprintf(['Correlation difference in %s at group level: '...
            '%.3f +/- %.3f, t_%d=%.3f, p=%.5f (using matlab stats '...
            'toolbox)\n'],...
            rois{iRoi},mean(mean_weighted_zs),std(mean_weighted_zs),...
            stats.df,stats.tstat,p);
    else
        fprintf('Matlab stats toolbox not available\n');
    end
    
end

%advanced exercise: plot an image of the correlation matrix averaged over
%participants (one for each roi)


for iRoi = 1:numel(rois)
    figure
    axh(iRoi) = gca;
    % >@@>
    
    imagesc(rho_sum(:, :, iRoi)/nsubjects)
    set(gca, 'xtick', 1:numel(labels), 'xticklabel', labels)
    set(gca, 'ytick', 1:numel(labels), 'yticklabel', labels)
    
    colorbar
    title(sprintf('Average splithalf correlation across subjects in mask ''%s''', rois{iRoi}))
    % <@@<
    
    colorLims(:, :, iRoi) = get(gca, 'clim');
end
%give all figures the same color limits such that correlations can be
%compared visually
set(axh, 'clim', [min(colorLims(:)), max(colorLims(:))])
