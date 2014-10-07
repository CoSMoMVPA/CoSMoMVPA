%% Cross validation measure example
% This example runs cross validation using a classifer and shows
% the confusion matrices using multiple classifiers

%% Define data
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

data_fn=fullfile(data_path,'glm_T_stats_perrun.nii');
mask_fn=fullfile(data_path,'vt_mask.nii');
ds=cosmo_fmri_dataset(data_fn,'mask',mask_fn,...
                        'targets',repmat(1:6,1,10),...
                        'chunks',floor(((1:60)-1)/6)+1);

% remove constant features (due to liberal masking)
ds=cosmo_remove_useless_data(ds);
%% Part 1: Use single classifier

% Use a function handle to the cosmo_crossvalidation_measure,
% and assign to the variable 'measure'
% >@@>
measure=@cosmo_crossvalidation_measure;
% <@@<

% Make a struct containing the arguments for the measure:
% - classifier: a function handle to cosmo_classify_lda
% - partitions: the output of cosmo_nfold_partitioner applied to the
%               dataset
% Assign the struct to the variable 'args'
% >@@>
args=struct();
args.classifier=@cosmo_classify_lda;
args.partitions=cosmo_nfold_partitioner(ds);
% <@@<

fprintf('Using the following measure:\n');
cosmo_disp(measure,'strlen',Inf); % avoid string truncation

fprintf('\nUsing the following measure arguments:\n');
cosmo_disp(args);

% Apply the measure to ds, with args as second argument
% >@@>
ds_accuracy=measure(ds,args);
fprintf('\nOutput dataset (with accuracy)\n');
cosmo_disp(ds_accuracy);
% <@@<

%% %% Part 2: Compare multiple classifiers

% Put function handles to cosmo_classify_nn, cosmo_classify_naive_bayes and
% cosmo_classify_lda in a cell, and assign to 'classifiers'
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

% set output of crossvalidation to predictions
args.output='predictions';

%% Run classifications
% Compute the accuracy and predictions for each classifier, and plot the
% confusion matrix
for k=1:nclassifiers
    % assign args.classifier to the k-th classifier
    % >@@>
    args.classifier=classifiers{k};
    % <@@<

    % compute predictions using the measure
    % >@@>
    predicted_ds=measure(ds,args);
    % <@@<

    % compute confusion matrix
    % >@@>
    confusion_matrix=cosmo_confusion_matrix(predicted_ds);
    % <@@<

    % compute accuracy
    % >@@>
    sum_diag=sum(diag(confusion_matrix));
    sum_total=sum(confusion_matrix(:));
    accuracy=sum_diag/sum_total;
    % <@@<

    % visualize confusion matrix
    figure();
    imagesc(confusion_matrix,[0 10])
    classifier_name=strrep(func2str(args.classifier),'_',' ');
    desc=sprintf('%s: accuracy %.1f%%', classifier_name, accuracy*100);
    title(desc)

    classes = {'monkey','lemur','mallard','warbler','ladybug','lunamoth'};
    set(gca,'XTickLabel',classes);
    set(gca,'YTickLabel',classes);
    ylabel('target');
    xlabel('predicted');
    colorbar
end

% Note: poor performance by some classifiers does not mean that they are
% useless, just that they were unable to capture the distinctions between
% the patterns of different conditions because these distinctions were not
% captured by the classifier's model.
