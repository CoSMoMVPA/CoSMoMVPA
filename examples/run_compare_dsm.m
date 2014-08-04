% RSA Tutorial
% Compare DSMs


subjects = {'s01','s02','s03','s04','s05','s06','s07','s08'};
masks = {'ev_mask.nii','vt_mask.nii'};


dsms = [];

config=cosmo_config();
study_path=fullfile(config.tutorial_data_path,'ak6');

%%
% In a nested loop over masks then subjects:
%       load each dataset
%       demean it, get DSM, save it in dsms

% >@@>
for m = 1:length(masks)
    msk = masks{m};
    for s = 1:length(subjects)
        sub = subjects{s};
        sub_path=fullfile(study_path,sub);

        % load dataset
        ds_fn=fullfile(sub_path,'glm_T_stats_perrun.nii');
        mask_fn=fullfile(sub_path,msk);
        ds_full = cosmo_fmri_dataset(ds_fn,...
                                    'mask',mask_fn,...
                                    'targets',repmat(1:6,1,10)');

        % compute average for each unique target
        ds=cosmo_fx(ds_full, @(x)mean(x,1), 'targets', 1);



        % demean
        % Comment this out to see the effects of demeaning vs. not
        ds.samples = bsxfun(@minus, ds.samples, mean(ds.samples, 1));

        % add to stack
        dsm=cosmo_pdist(ds.samples, 'correlation');
        if isempty(dsms)
            dsms=dsm;
        else
            dsms = [dsms; dsm];
        end
    end
end
% <@@<

%%
% Then add the v1 model and behavioral DSMs
models_path=fullfile(study_path,'models');
load(fullfile(models_path,'v1_model.mat'));
load(fullfile(models_path,'behav_sim.mat'));
% add to dsms (hint: use squareform)
% >@@>
v1_model_sf=squareform(v1_model);
behav_model_sf=squareform(behav);
% ensure row vector because Matlab and Octave return
% row and column vectors, respectively
dsms = [dsms; v1_model_sf(:)'; behav_model_sf(:)'];
% <@@<

%%
% Now visualize the cross-correlation matrix. Remember that corrcoef calculates
% correlation coefficients between columns and we want between rows.

% >@@>
cc = corrcoef(dsms');
figure(); imagesc(cc);
% <@@<

%%
% Now use the values in the last to rows of the cross correlation matrix to
% visualize the distributions in correlations between the neural similarities
% and the v1 model/behavioral ratings.

% >@@>
cc_models = [cc(1:8,17) cc(9:16,17) cc(1:8,18) cc(9:16,18)];
labs = {'v1 model~EV','v1 model~VT','behav~EV','behav~VT'};
figure(); boxplot(cc_models); set(gca,'XTick',[1:4],'XTickLabel',labs);
% <@@<




