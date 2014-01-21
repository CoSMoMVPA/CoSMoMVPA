%% Cross validation example with multiple classifiers
% This example runs cross validation and shows confusion matrix using
% multiple 

%% Define data
config=cosmo_config();
data_path=fullfile(config.data_path,'ak6','s01');

data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
mask_fn=fullfile(data_path,'vt_mask.nii');
ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                        'targets',repmat(1:6,1,10),...
                        'chunks',floor(((1:60)-1)/6)+1);

%% Define classifiers in a cell
% >> 
classifiers={@cosmo_classify_nn,...
             @cosmo_classify_naive_bayes,...
             @cosmo_classify_svm};
% <<         
nclassifiers=numel(classifiers);

%% Define partitions
partitions=cosmo_nfold_partitioner(ds);

%% Run classifications
% Compute the accuracy and predictions for each classifier, and plot the
% confusion matrix
for k=1:nclassifiers
    classifier=classifiers{k};
    % >>
    [pred,accuracy]=cosmo_cross_validate(ds, classifier, partitions);
    
    confusion_matrix=cosmo_confusion_matrix(ds, pred);
    % <<
    figure
    imagesc(confusion_matrix,[0 10])
    title(sprintf('%s: %.3f', strrep(func2str(classifier),'_',' '), accuracy))
    
end
