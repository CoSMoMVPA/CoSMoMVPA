function [pred, accuracy] = cosmo_cross_validate(dataset, classifier, partitions, opt)
% performs cross-validation using a classifier
%
% [pred, accuracy] = cosmo_cross_validate(dataset, args)
% 
% Inputs
%   dataset             struct with fields .samples (PxQ for P samples and 
%                       Q features) and .sa.targets (Px1 labels of samples)
%   classifier          function handle to classifier, e.g.
%                       @classify_naive_baysian
%   partitions          For example the output from nfold_partition
%   opt                 optional struct with options for classifier
%   
% 
%
% NNO Aug 2013 

if nargin<4
    opt=struct();
end

train_indices = partitions.train_indices;
test_indices = partitions.test_indices;

npartitions=numel(train_indices);

[nsamples,nfeatures]=size(dataset.samples);

pred=zeros(nsamples,1); % space for output
ncorrect=0; % how many samples were correctly classified
ntotal=0; % how many samples were classified (correctly or not)

for k=1:npartitions
    % >>
    train_data = dataset.samples(train_indices{k},:);
    test_data = dataset.samples(test_indices{k},:);
    
    train_targets = dataset.sa.targets(train_indices{k});
    
    p = classifier(train_data, train_targets, test_data, opt);
    pred(test_indices{k}) = p;
    
    test_targets = dataset.sa.targets(test_indices{k});
    ncorrect = ncorrect + sum(p(:) == test_targets(:));
    ntotal = ntotal + numel(test_targets);
    % <<
end


accuracy = ncorrect/ntotal;