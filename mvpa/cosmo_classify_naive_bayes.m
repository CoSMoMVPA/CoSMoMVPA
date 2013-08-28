function predicted=cosmo_classify_naive_bayes(samples_train, targets_train, samples_test, opt)
% naive bayes classifier
%
% predicted=cosmo_classify_naive_bayes(samples_train, targets_train, samples_test[, opt])
%
% Inputs
% - samples_train      PxR training data for P samples and R features
% - targets_train      Px1 training data classes
% - samples_test       QxR test data
%-  opt                (currently ignored)
%
% Output
% - predicted          Qx1 predicted data classes for samples_test
%
% NNO Aug 2013


if nargin<4, opt=struct(); end

[ntrain, nfeatures]=size(samples_train);
[ntest, nfeatures_]=size(samples_test);
ntrain_=numel(targets_train);

if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

classes=unique(targets_train);
nclasses=numel(classes);

% allocate space for statistics of each class
mus=zeros(nclasses,nfeatures);
stds=zeros(nclasses,nfeatures);
class_probs=zeros(nclasses,1);

% compute means and standard deviations of each class
for k=1:nclasses
    msk=targets_train==classes(k);
    n=sum(msk); % number of samples
    d=samples_train(msk,:); % samples in this class
    mu=mean(d); %mean
    mus(k,:)=mu;
    stds(k,:)=sqrt(1/(n-1) * sum(bsxfun(@minus,mu,d).^2,1)); % standard deviation - faster implementation than 'std'
    class_probs(k)=log(n/ntrain); % log of class probability
end

predicted=zeros(ntest,1);

for k=1:ntest
    sample=samples_test(k,:);
    
    % compute feature-wise probality relative to stats of each class
    ps=normcdf(repmat(sample,nclasses,1), mus, stds);
    
    % being 'naive' we assume independence - so take the product of the
    % p values. (for better precision we take the log of the probablities
    % and sum them)
    test_prob=sum(log(ps),2)+class_probs;
    
    % find the one with the highest probability
    [foo, mx_idx]=max(test_prob);
    
    predicted(k)=classes(mx_idx);
end
           
    
