function ds_sa = cosmo_crossvalidation_measure(ds, varargin)
% performs cross-validation using a classifier
%
% accuracy = cosmo_cross_validation_accuracy_measure(dataset, args)
%
% Inputs:
%   dataset             struct with fields .samples (PxQ for P samples and
%                       Q features) and .sa.targets (Px1 labels of samples)
%   args                struct containing classifier, partitions, and
%                       possibly other fields that are given to the
%                       classifier.
%   args.classifier     function handle to classifier, e.g.
%                       @cosmo_classify_lda
%   args.partitions     Partition scheme, for example the output from
%                       cosmo_nfold_partitioner
%   args.output         One of:
%                       - 'accuracy':           overall classificationa
%                                               accuracy (default)
%                       - 'balanced_accuracy'   classificationa accuracy is
%                                               computed for each class,
%                                               then averaged
%                       - 'fold_accuracy'       classificationa accuracy is
%                                               computed for each fold
%                       - 'winner_predictions'  class that was predicted
%                                               for each sample in the test
%                                               set; in the case of
%                                               multiple predictions, ties
%                                               are decided in
%                                               pseudo-random fashion by
%                                               cosmo_winner_indices
%                       - 'fold_predictions'   prediction for each sample
%                                               in each fold
%   args.check_partitions  optional (default: true). If set to false then
%                          partitions are not checked for being set
%                          properly.
%   args.normalization  optional, one of '{zscore,demean,scale_unit}{1,2}'
%                       to normalize the data prior to classification using
%                       zscoring, demeaning or scaling to [-1,1] along the
%                       first or second dimension of ds. Normalization
%                       parameters are estimated using the training data
%                       and applied to the testing data.
%     .pca_explained_count   optional, transform the data with PCA prior to
%                            classification, and retain this number of
%                            components
%     .pca_explained_ratio   optional, transform the data with PCA prior to
%                            classification, and retain the components that
%                            explain this percentage of the variance
%                            (value between 0-1)
%   args.average_train_X  average the samples in the train set using
%                       cosmo_average_samples. For X, use any parameter
%                       supported by cosmo_average_samples, i.e. either
%                       'count' or 'ratio', and optionally, 'resamplings'
%                       or 'repeats'.
%
% Output:
%    ds_sa        Struct with fields:
%      .samples   Scalar with classification accuracy.
%      .sa        Struct with field:
%                 - if args.output=='accuracy':
%                       .labels  =={'accuracy'}
%                 - if args.output=='predictions'
%                       .targets     } Px1 real and predicted labels of
%                       .predictions } each sample
%
% Examples:
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     %
%     % use take-1-chunk for testing crossvalidation
%     opt=struct();
%     opt.partitions=cosmo_nfold_partitioner(ds);
%     opt.classifier=@cosmo_classify_naive_bayes;
%     % run crossvalidation and return accuracy (the default)
%     acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp(acc_ds);
%     > .samples
%     >   [ 0.917 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % let the measure return predictions instead of accuracy,
%     % and use take-1-chunks out for testing crossvalidation;
%     % use LDA classifer and let targets be in range 7..9
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4,'target1',7);
%     opt=struct();
%     opt.partitions=cosmo_nchoosek_partitioner(ds,1);
%     opt.output='winner_predictions';
%     opt.classifier=@cosmo_classify_lda;
%     pred_ds=cosmo_crossvalidation_measure(ds,opt);
%     %
%     % show results. Because each sample was predicted just once,
%     % .sa.chunks contains the chunks of the original input
%     cosmo_disp(pred_ds);
%     > .sa
%     >   .targets
%     >     [ 7
%     >       8
%     >       9
%     >       :
%     >       7
%     >       8
%     >       9 ]@12x1
%     >   .chunks
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       4
%     >       4
%     >       4 ]@12x1
%     > .samples
%     >   [ 9
%     >     8
%     >     9
%     >     :
%     >     7
%     >     9
%     >     7 ]@12x1
%     >
%     %
%     % return accuracy, but use z-scoring on each training set
%     % and apply the estimated mean and std to the test set.
%     % Use take-2-chunks out for corssvalidation
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     opt=struct();
%     opt.output='accuracy';
%     opt.normalization='zscore';
%     opt.classifier=@cosmo_classify_lda;
%     opt.partitions=cosmo_nchoosek_partitioner(ds,2);
%     z_acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp(z_acc_ds);
%     > .samples
%     >   [ 0.833 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % illustrate accuracy for partial test set
%     ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',5);
%     %
%     % use take-1-chunk out for testing crossvalidation, but only test on
%     % chunks 2 and 4
%     opt=struct();
%     opt.partitions=cosmo_nchoosek_partitioner(ds,1,'chunks',[2 4]);
%     opt.classifier=@cosmo_classify_naive_bayes;
%     % run crossvalidation and return accuracy (the default)
%     acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     % show accuracy
%     cosmo_disp(acc_ds.samples)
%     > 0.75
%     % show predictions
%     opt.output='winner_predictions';
%     pred_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp([pred_ds.samples pred_ds.sa.targets pred_ds.sa.chunks]);
%     > [ NaN         1       NaN
%     >   NaN         2       NaN
%     >     1         1         2
%     >    :          :        :
%     >     1         2         4
%     >   NaN         1       NaN
%     >   NaN         2       NaN ]@10x3
%
% Notes:
%   - using this function, crossvalidation can be run using a searchlight
%
% See also: cosmo_searchlight, cosmo_average_samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % deal with input arguments
    params=cosmo_structjoin('output','accuracy',... % default output
                            varargin); % use input arguments

    % Run cross validation to get the accuracy (see the help of
    % cosmo_crossvalidate)
    % >@@>
    classifier=params.classifier;
    partitions=params.partitions;

    params=rmfield(params,'classifier');
    params=rmfield(params,'partitions');
    [pred,accuracy]=cosmo_crossvalidate(ds,classifier,...
                                            partitions,params);
    % <@@<
    ds_sa=struct();
    output=params.output;

    switch output
        case 'accuracy'
            ds_sa.samples=accuracy;
            ds_sa.sa.labels={'accuracy'};

        case 'balanced_accuracy'
            ds_sa.samples=compute_balanced_accuracy(pred,ds.sa.targets);
            ds_sa.sa.labels={'balanced_accuracy'};


        case {'predictions','raw','winner_predictions'}
            if cosmo_match({output},{'predictions','raw'})
                cosmo_warning('CoSMoMVPA:deprecated',...
                        sprintf(...
                        ['Output option ''%s'' is deprecated and will '...
                        'be removed from a future release. Please use '...
                        'output=''winner_predictions'' instead, or use '...
                        'output=''fold_predictions'' to get '...
                        'predictions for each fold'],...
                            output));
            end

            ds_sa.samples=compute_winner_predictions(pred);
            ds_sa.sa=rmfield(ds.sa,'chunks');

        case 'fold_accuracy'
            [ds_sa.samples,ds_sa.sa.folds]=compute_fold_accuracy(pred,...
                                                        ds.sa.targets);

        case 'fold_predictions'
            ds_sa=struct();
            [ds_sa.samples,...
                    ds_sa.sa.folds,...
                    ds_sa.sa.targets]=compute_fold_predictions(pred,...
                                                        ds.sa.targets);


        case 'accuracy_by_chunk'
            error(['Output ''%s'' is not supported anymore. Consider '...
                    'using ''fold_predictions'' whenever this is '...
                    'implemented'], output);

        otherwise
            error('Illegal output parameter %s', params.output);
    end

function [accs,folds]=compute_fold_accuracy(pred,targets)
    is_correct=bsxfun(@eq,pred,targets);
    has_pred=~isnan(pred);

    accs=(sum(is_correct,1) ./ sum(has_pred,1))';
    folds=(1:numel(accs))';


function [fold_pred,folds,fold_targets]=compute_fold_predictions(pred,...
                                                                targets)
    nfolds=size(pred,2);

    pred_cell=cell(nfolds,1);
    fold_cell=cell(nfolds,1);
    target_cell=cell(nfolds,1);

    has_pred=~isnan(pred);
    fold_pred_count=sum(has_pred,1);

    for i_fold=1:nfolds
        msk=has_pred(:,i_fold);
        pred_cell{i_fold}=pred(msk,i_fold);
        fold_cell{i_fold}=zeros(fold_pred_count(i_fold),1)+i_fold;
        target_cell{i_fold}=targets(msk);
    end

    fold_pred=cat(1,pred_cell{:});
    folds=cat(1,fold_cell{:});
    fold_targets=cat(1,target_cell{:});



function winner_pred=compute_winner_predictions(pred)
    [winner_pred,classes]=cosmo_winner_indices(pred);
    has_pred=~isnan(winner_pred);
    winner_pred(has_pred)=classes(winner_pred(has_pred));



function acc=compute_balanced_accuracy(pred,targets)
    [class_idx,classes]=cosmo_index_unique(targets);
    nclasses=numel(classes);

    each_class_acc=zeros(nclasses,1);

    % some samples may be without predictions (and are set to NaN
    % by cosmo_crossvalidate). Consider only the samples with
    % predictions, and compute for each class the classification
    % accuracy
    has_prediction = ~isnan(pred);
    has_any_prediction=any(has_prediction,2);

    for c=1:nclasses
        idx=class_idx{c};
        keep_idx=idx(has_any_prediction(idx));

        n_in_class=numel(keep_idx);
        class_accs=NaN(n_in_class,1);
        for j=1:n_in_class;
            row=keep_idx(j);
            has_row_prediction=has_prediction(row,:);
            if ~any(has_row_prediction)
                continue;
            end

            is_correct=pred(row,:)==targets(row);
            class_accs(j)=sum(is_correct) / sum(has_row_prediction);
        end

        non_nan=~isnan(class_accs);
        each_class_acc(c)=sum(class_accs(non_nan))/sum(non_nan);
    end

    acc=mean(each_class_acc,1);