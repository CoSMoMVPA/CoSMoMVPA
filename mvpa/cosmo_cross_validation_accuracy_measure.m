function ds_sa = cosmo_cross_validation_accuracy_measure(dataset, args)
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
%   
%
% Output
%    ds_sa        Struct with fields:
%      .samples   Scalar with classification accuracy.
%      .sa        Struct with field:
%        .labels  {'acc'}
%   
% ACC. Modified to conform to signature of generic datset 'measure'
% NNO Aug 2013 made this a wrapper function
    
if ~isfield(args,'classifier') error('Missing input args.classifier'); end
if ~isfield(args,'partitions') error('Missing input args.partitions'); end

% Run cross validation to get the accuracy (see the help of
% cosmo_cross_validate)
% >>
classifier=args.classifier;
partitions=args.partitions;

args=rmfield(args,'classifier');
args=rmfield(args,'partitions');
[pred, accuracy]=cosmo_cross_validate(dataset, classifier, partitions, args);
% <<

ds_sa=struct();
ds_sa.samples=accuracy;
ds_sa.sa.labels={'acc'};
    