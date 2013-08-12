function accuracy = cosmo_cross_validate(dataset, args)
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
% NNO Aug 2013, 
% modified by ACC. Modified to conform to signature of generic datset 'measure'