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
%  - LIBSVM is required: http://www.csie.ntu.edu.tw/~cjlin/libsvm
%  - by default a linear kernel is used ('-t 2')
%  - this function uses LIBSVM's svmtrain function, which has the same 
%    name as matlab's builtin version. Use of this function is not
%    supported when matlab's svmtrain precedes in the matlab path; in 
%    that case, adjust the path or use cosmo_classify_svm instead.
%
% See also svmtrain, svmpredict, cosmo_classify_svm
%
% NNO Feb 2014
    
    has_opt=nargin>4 && ~isempty(fieldnames(opt));
    
    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);
    
    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

    % construct options string for svmtrain
    if has_opt
        default_opt=struct();
        default_opt.t=0; % linear
        default.opt.q=true; % no output
        opt_str=libsvm_opt2str(default_opt,opt);
    else
        opt_str='-t 0 -q';
    end 
    
    % train
    m=svmtrain(targets_train, samples_train, opt_str);
    
    % test
    predicted=svmpredict(NaN(ntest,1), samples_test, m);
    
    
function opt_str=libsvm_opt2str(opt)
    
    % options supported to libsvm
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
            else
                v='';
            end
            
            opt_cell{2*k}=v;
        end
    else
        opt_cell=cell(1);
    end
    
    opt_cell{end}='-q';
    opt_str=cosmo_strjoin(opt_cell,' ');
    
            