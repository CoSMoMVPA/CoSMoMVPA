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

if ~isfield(args,'opt') args.opt = struct(); end
if ~isfield(args,'classifier') error('Missing input args.classifier'); end
if ~isfield(args,'partitions') error('Missing input args.partitions'); end


train_indices = args.p
artitions.train_indices;
test_indices = args.partitions.test_indices;

npartitions=numel(train_indices);

[nsamples,nfeatures]=size(dataset.samples);

pred=zeros(nsamples,1); % space for output
ncorrect=0; % how many samples were correctly classified
ntotal=0; % how many samples were classified (correctly or not)

% [your code here]

accuracy = ncorrect/ntotal;
