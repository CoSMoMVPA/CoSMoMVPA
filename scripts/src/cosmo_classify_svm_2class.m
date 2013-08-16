function predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
% svm classifier wrapper (around svmtrain/svmclassify)
%
% predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
%
% Inputs
% - samples_train      PxR training data for P samples and R features
% - targets_train      Px1 training data classes
% - samples_test       QxR test data
%-  opt                struct with options. supports any option that
%                      svmtrain supports 
%
% Output
% - predicted          Qx1 predicted data classes for samples_test
%
% See also svmtrain, svmclassify
%
% NNO Aug 2013

if nargin<4, opt=struct(); end
    
[ntrain, nfeatures]=size(samples_train);
[ntest, nfeatures_]=size(samples_test);
ntrain_=numel(targets_train);

if nfeatures~=nfeatures || ntrain_~=ntrain, error('illegal input size'); end

classes=unique(targets_train);
if numel(classes)~=2
    me=mfilename();
    error('%s requires 2 classes. Use cosmo_classify_meta_multiclass with opt.classifier=@%s', me, me);
end

opt_cell=opt2cell(opt);

% Use svmtrain and svmclassify to get predictions for the testing set.
% (Hint: 'opt_cell{:}' allows you to pass the options as varargin)
% >>
s = svmtrain(samples_train, targets_train, opt_cell{:});
predicted=svmclassify(s, samples_test);
% <<

% helper function to convert cell to struct
function opt_cell=opt2cell(opt)

fns=fieldnames(opt);
n=numel(fns);
opt_cell=cell(1,2*n);
for k=1:n
    fn=fns{k};
    opt_cell{k*2-1}=fn;
    opt_cell{k*2}=opt.(fn);
end