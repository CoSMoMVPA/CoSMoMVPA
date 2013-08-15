function accuracy = cosmo_cross_validation_measure(dataset, args)
% performs cross-validation using a classifier
%
% accuracy = cosmo_cross_validate(dataset, args)
% 
% Inputs
%   dataset             struct with fields .samples (PxQ for P samples and 
%                       Q features) and .sa.targets (Px1 labels of samples)
%   args                struct containing classifier, partitions, and opt (which
%                           is optional)
%   args.classifier     function handle to classifier, e.g.
%                       @classify_naive_baysian
%   args.partitions          For example the output from nfold_partition
%   
% ACC. Modified to conform to signature of generic datset 'measure'
% NNO made this a wrapper function

if ~isfield(args,'opt') args.opt = struct(); end
if ~isfield(args,'classifier') error('Missing input args.classifier'); end
if ~isfield(args,'partitions') error('Missing input args.partitions'); end

% Run cross validation to get the accuracy (see the help of
% cosmo_cross_validate)
% >>
[pred, accuracy]=cosmo_cross_validate(dataset, args.classifier, args.partitions, args.opt);
% <<
