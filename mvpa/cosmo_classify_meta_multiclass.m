function predicted=cosmo_classify_meta_multiclass(samples_train, targets_train, samples_test, opt)
% meta classifier that uses another (possibly only supporting 2-class 
% classification) to provide multi-class classification
%
% predicted=cosmo_classify_meta_multiclass(samples_train, targets_train, samples_test, opt)
%
% Inputs
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                struct with a field .base_classifier, which should 
%                      be a function handle to another classifier
%                      (for example opt.base_classifier=@cosmo_classify_svm)
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% NNO Aug 2013


if nargin<4 || ~isfield(opt, 'classifier')
    error('need opt.classifier=some_function')
end

classifier=opt.base_classifier;
opt=rmfield(opt,'base_classifier'); % do not allow recursion

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

% >>
pos=0;
for k=1:nclasses
    mask_k=targets_train==classes(k);
    for j=(k+1):nclasses
        mask_j=targets_train==classes(j);
        mask=mask_k | mask_j;
        pos=pos+1;
        
        all_predicted(:,pos)=classifier(samples_train(mask,:), targets_train(mask), samples_test, opt);
    end
end
% <<

% find the classes that were predicted most often
% XXX currently we always take the first one
counts=histc(all_predicted',classes);
[foo,idx]=max(counts);

predicted=classes(idx);
        

