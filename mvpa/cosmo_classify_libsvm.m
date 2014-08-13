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
%  - by default a linear kernel is used ('-t 0')
%  - this function uses LIBSVM's svmtrain function, which has the same
%    name as matlab's builtin version. Use of this function is not
%    supported when matlab's svmtrain precedes in the matlab path; in
%    that case, adjust the path or use cosmo_classify_matlabsvm instead.
%  - when using libsvm in the standard implementation, it prints output
%    for each classification step (and will report, incorrectly, zero
%    percent accuracy). To suppress this output one has to manually edit
%    the matlab/svmpredict.c function around line 225 which has a mexPrintf
%    statement. Comment out this statement (by preceding it with '/*' and
%    following it with '*/') and run make.m to recompile the mex functions.
%  - for a guide on svm classification, see
%      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
%    Note that cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling
%
% See also svmtrain, svmclassify, cosmo_classify_svm, cosmo_classify_matlabsvm
%
% NNO Feb 2014
    cosmo_check_external('libsvm');

    has_opt=nargin>4 && ~isempty(fieldnames(opt));

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

    % construct options string for svmtrain
    if has_opt
        default_opt=struct();
        default_opt.t=0; % linear
        opt_str=libsvm_opt2str(default_opt,opt);
    else
        % build string directly (for faster execution)
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
            end

            opt_cell{2*k}=v;
        end
    else
        opt_cell=cell(1);
    end

    opt_cell{end}='-q'; % quiet (no output to terminal window)
    opt_str=cosmo_strjoin(opt_cell,' ');


