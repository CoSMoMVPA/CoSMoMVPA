function predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
% SVM classifier that uses classify_svm_2class to provide 
% multi-class classification with SVM.
%
% predicted=cosmo_classify_meta_multiclass(samples_train, targets_train, samples_test, opt)
%
% Inputs
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                (optional) struct with options for svm_classify
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% See also svmtrain, svmclassify, cosmo_classify_svm_2class
%
% NNO Aug 2013

if nargin<4, opt=struct(); end

[ntrain, nfeatures]=size(samples_train);
[ntest, nfeatures_]=size(samples_test);
ntrain_=numel(targets_train);

if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

classes=unique(targets_train);
nclasses=numel(classes);

% number of pair-wise comparisons
ncombi=nclasses*(nclasses-1)/2;

% allocate space for all predictions
all_predicted=zeros(ntest, ncombi);

% Consider all pairwise comparisons (over classes)
% and store the predictions in all_predicted
pos=0;
for k=1:(nclasses-1)
    for j=(k+1):nclasses
        pos=pos+1;
        % classify between 2 classes only (from classes(k) and classes(j)).
        % >>
        mask_k=targets_train==classes(k);
        mask_j=targets_train==classes(j);
        mask=mask_k | mask_j;
        
        pred=cosmo_classify_svm_2class(samples_train(mask,:), targets_train(mask), samples_test, opt);
        % <<
        all_predicted(:,pos)=pred;
    end
end

% find the classes that were predicted most often
% the tricky part is to handle ties: there we take
% a winner randomly (rather than the first) to avoid
% any particular bias
% XXX this is not very efficient - no idea how to
% do this efficiently using matlab

[winners, test_classes]=cosmo_winner_indices(all_predicted);

predicted=test_classes(winners);
