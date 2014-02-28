function predicted=cosmo_classify_libsvm(samples_train, targets_train, samples_test, opt)
% libsvm-based SVM classifier
%
% predicted=cosmo_classify_libsvm(samples_train, targets_train, samples_test, opt)
%
% Inputs
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                (optional) struct with options for svmtrain
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% Notes:
%  - this function requires libsvm
%  - by default a linear kernel is used ('-t 2')
%
% See also svmtrain, svmclassify, cosmo_classify_svm_2class
%
% NNO Feb 2014
    
    if nargin<4, opt=struct(); end
    
    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);
    
    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

    opt=cosmo_structjoin('t',2,opt); % use linear kernel by default
    opt_str=libsvm_opt2str(opt);
    m=svmtrain(targets_train, samples_train, opt_str);
    
    predicted=svmpredict(NaN(ntest,1), samples_test, m);
    
    
function opt_str=libsvm_opt2str(opt)
    
    fns=intersect(fieldnames(opt),{'s','t','d','g','r','c','n','p',...
                                    'm','e','h','n','wi','v'});

    if ~isempty(fns)
        n=numel(fns);
        opt_cell=cell(1,2*n+1);
        for k=1:numel(fns)
            fn=fns{k};
            opt_cell{2*k-1}=['-' fn];
            
            v=opt.(fn);
            if isnumeric(v)
                v=sprintf('%d',v);
            end
            
            opt_cell{2*k}=v;
        end
    else
        opt_cell=cell(1);
    end
    
    opt_cell{end}='-q';
    opt_str=cosmo_strjoin(opt_cell,' ');
    
            