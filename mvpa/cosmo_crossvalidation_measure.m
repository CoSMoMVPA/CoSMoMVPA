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
%                       @classify_naive_baysian
%   args.partitions     Partition scheme, for example the output from
%                       cosmo_nfold_partition
%   args.output         'accuracy' (default) or 'predictions'
%   args.check_partitions  optional (default: true). If set to false then
%                          partitions are not checked for being set
%                          properly.
%   args.normalization  optional, one of '{zscore,demean,scale_unit}{1,2}'
%                       to normalize the data prior to classification using
%                       zscoring, demeaning or scaling to [-1,1] along the
%                       first or second dimension of ds. Normalization
%                       parameters are estimated using the training data
%                       and applied to the testing data.
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
%     >   [ 0.583 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % let the measure return predictions instead of accuracy,
%     % and use take-1-chunks out for testing crossvalidation;
%     % use LDA classifer
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     opt=struct();
%     opt.partitions=cosmo_nchoosek_partitioner(ds,1);
%     opt.output='predictions';
%     opt.classifier=@cosmo_classify_lda;
%     pred_ds=cosmo_crossvalidation_measure(ds,opt);
%     %
%     % show results. Because each sample was predicted just once,
%     % .sa.chunks contains the chunks of the original input
%     cosmo_disp(pred_ds);
%     > .sa
%     >   .targets
%     >     [ 1
%     >       2
%     >       3
%     >       :
%     >       1
%     >       2
%     >       3 ]@12x1
%     >   .chunks
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       4
%     >       4
%     >       4 ]@12x1
%     > .samples
%     >   [ 1
%     >     3
%     >     1
%     >     :
%     >     1
%     >     1
%     >     2 ]@12x1
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
%     >   [ 0.75 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
% Notes:
%   - using this function, crossvalidation can be run using a searchlight
%
% See also: cosmo_searchlight
%
% ACC. Modified to conform to signature of generic datset 'measure'
% NNO Aug 2013 made this a wrapper function

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
[pred, accuracy,chunks]=cosmo_crossvalidate(ds,classifier,...
                                        partitions,params);
% <@@<

ds_sa=struct();

switch params.output
    case 'accuracy'
        ds_sa.samples=accuracy;
        ds_sa.sa.labels={'accuracy'};
    case {'predictions','raw'}
        ds_sa.sa.targets=ds.sa.targets;
        ds_sa.sa.chunks=chunks;
        ds_sa.samples=pred(:);
    otherwise
        error('Illegal output parameter %s', params.output);
end

