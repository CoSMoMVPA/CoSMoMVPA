%% An example of using feature selection with a classifier
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% This example plots classification accuracy as a function of the number of
% features selected using an ANOVA on training set data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
mask_fn=fullfile(data_path,'vt_mask.nii');
ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                        'targets',repmat(1:6,1,10),...
                        'chunks',floor(((1:60)-1)/6)+1);


% remove constant features
ds=cosmo_remove_useless_data(ds);

opt=struct();
opt.child_classifier=@cosmo_classify_naive_bayes;
opt.feature_selector=@cosmo_anova_feature_selector;

partitions=cosmo_nfold_partitioner(ds);

ratios_to_keep=.05:.05:.95;
nratios=numel(ratios_to_keep);

accs=zeros(nratios,1);

for k=1:nratios
    opt.feature_selection_ratio_to_keep=ratios_to_keep(k);

    [pred, acc]=cosmo_crossvalidate(ds, ...
                                     @cosmo_meta_feature_selection_classifier, ...
                                     partitions, opt);
    accs(k)=acc;
end

plot(ratios_to_keep,accs);
xlabel('ratio of selected feaures');
ylabel('classification accuracy');
