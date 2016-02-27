%% Cross validation example with multiple classifiers
% This example runs cross validation and shows confusion matrix using
% multiple classifiers
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Define data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
mask_fn=fullfile(data_path,'vt_mask.nii');
ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                        'targets',repmat(1:6,1,10),...
                        'chunks',floor(((1:60)-1)/6)+1);

% remove constant features
ds=cosmo_remove_useless_data(ds);

%% Define classifiers in a cell
% >@@>
classifiers={@cosmo_classify_nn,...
             @cosmo_classify_naive_bayes,...
             @cosmo_classify_lda};

% if svm classifier is present (either libsvm or matlab's svm), use that
% too
if cosmo_check_external('svm',false)
    classifiers{end+1}=@cosmo_classify_svm;
end
% <@@<
nclassifiers=numel(classifiers);

%% Define partitions
partitions=cosmo_nfold_partitioner(ds);

%% Run classifications
% Compute the accuracy and predictions for each classifier, and plot the
% confusion matrix
for k=1:nclassifiers
    classifier=classifiers{k};
    % >@@>
    [pred,accuracy]=cosmo_crossvalidate(ds, classifier, partitions);

    confusion_matrix=cosmo_confusion_matrix(ds.sa.targets, pred);
    % <@@<
    figure();
    imagesc(confusion_matrix,[0 10])
    title(sprintf('%s: %.3f', strrep(func2str(classifier),'_',' '), accuracy))

end

%% Consider effect or normalization
normalizations={'zscore',...
                'demean',...
                'scale_unit',...
                'none'};

for k=1:nclassifiers
    classifier=classifiers{k};
    classifier_name=strrep(func2str(classifier),'_',' ');
    for j=1:numel(normalizations)
        opt=struct();
        opt.normalization=normalizations{j};
        [pred,accuracy]=cosmo_crossvalidate(ds,classifier,partitions,opt);

        fprintf('%s with %s-normalization: %.3f\n', classifier_name,...
                opt.normalization, accuracy);
    end
end





