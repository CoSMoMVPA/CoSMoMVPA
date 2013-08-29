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
% Output
%   pred                Qx1 array with predicted class labels
%
% NNO Aug 2013 

if nargin<4
    opt=struct();
end

train_indices = partitions.train_indices;
test_indices = partitions.test_indices;

npartitions=numel(train_indices);

[nsamples,nfeatures]=size(dataset.samples);

all_pred=zeros(nsamples,npartitions); % space for output (one column per partition)
test_mask=false(nsamples,1); % indicates for which samples there has been a prediction
for k=1:npartitions
    % >>
    train_data = dataset.samples(train_indices{k},:);
    test_data = dataset.samples(test_indices{k},:);
    
    train_targets = dataset.sa.targets(train_indices{k});
    
    p = classifier(train_data, train_targets, test_data, opt);
    
    all_pred(test_indices{k},k) = p;
    test_mask(test_indices{k})=true;
    % <<
end

pred=cosmo_winner_indices(all_pred);
test_targets = dataset.sa.targets(test_indices{k});
ncorrect = sum(p(:) == test_targets(:));
ntotal = numel(test_targets);

accuracy = ncorrect/ntotal;