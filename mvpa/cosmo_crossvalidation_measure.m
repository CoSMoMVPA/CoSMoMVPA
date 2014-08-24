function ds_sa = cosmo_crossvalidation_measure(ds, varargin)
% performs cross-validation using a classifier
%
% accuracy = cosmo_cross_validation_accuracy_measure(dataset, args)
%
% Inputs
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
% Output
%    ds_sa        Struct with fields:
%      .samples   Scalar with classification accuracy.
%      .sa        Struct with field:
%                 - if args.output=='accuracy':
%                       .labels  =={'accuracy'}
%                 - if args.output=='predictions'
%                       .targets     } Px1 real and predicted labels of
%                       .predictions } each sample
%
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
[pred, accuracy]=cosmo_crossvalidate(ds,classifier,partitions,params);
% <@@<

ds_sa=struct();

switch params.output
    case 'accuracy'
        ds_sa.samples=accuracy;
        ds_sa.sa.labels={'accuracy'};
    case {'predictions','raw'}
        ds_sa.sa.targets=ds.sa.targets;
        ds_sa.samples=pred(:);
    otherwise
        error('Illegal output parameter %s', params.output);
end

