function predicted=cosmo_classify_nn(samples_train, targets_train, samples_test, opt)
% nearest neighbor classifier
%
% predicted=cosmo_classify_nn(samples_train, targets_train, samples_test[, opt])
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

% allocate space for output
predicted=zeros(ntest,1);

% >>
for k=1:ntest
    delta=bsxfun(@minus, samples_train, samples_test(k,:));
    dst=sqrt(sum(delta.^2,2));
    if numel(dst)~=ntrain, error('wrng'); end
    [m, i]=min(dst);
    predicted(k)=targets_train(i);
end
% <<           
