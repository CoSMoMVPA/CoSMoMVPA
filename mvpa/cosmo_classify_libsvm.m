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
%     .autoscale       If true (default), z-scoring is done on the training
%                      set; the test set is z-scored using the mean and std
%                      estimates from the training set.
%     ?                any option supported by either libsvm's svmtrain.
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% Notes:
%  - this function requires libsvm version 3.18 or later:
%    https://github.com/cjlin1/libsvm
%  - by default a linear kernel is used ('-t 0')
%  - this function uses LIBSVM's svmtrain function, which has the same
%    name as matlab's builtin version. Use of this function is not
%    supported when matlab's svmtrain precedes in the matlab path; in
%    that case, adjust the path or use cosmo_classify_matlabsvm instead.
%  - for a guide on svm classification, see
%      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
%  - By default this function performs z-scoring of the data. To switch
%    this off, set 'autoscale' to false
%  - cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling
%
%
% See also svmtrain, svmclassify, cosmo_classify_svm, cosmo_classify_matlabsvm
%
% NNO Feb 2014

    if nargin<4
        opt=[];
    end

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain
        error('illegal input size');
    end

    % construct options string for svmtrain
    opt_str=libsvm_opt2str(opt);

    % auto-scale is the default
    autoscale=~isstruct(opt)||(isfield(opt,'autoscale') && opt.autoscale);

    % perform autoscale if necessary
    if autoscale
        [samples_train, params]=cosmo_normalize(samples_train, ...
                                                    'zscore', 1);
        samples_test=cosmo_normalize(samples_test, params);
    end

    % train; if it fails, see if this caused by non-functioning libsvm
    try
        model=svmtrain(targets_train, samples_train, opt_str);
        predicted=svmpredict(NaN(ntest,1), samples_test, model, '-q');
    catch
        cosmo_check_external('libsvm');
        rethrow(lasterror());
    end


function opt_str=libsvm_opt2str(opt)
    % always be quiet (no output to terminal window)
    default_postfix='-q';
    if isempty(opt)
        opt_str=default_postfix;
        return
    end

    % this function may be called many times. cache the loast opt
    % that was used so that it can be returned
    persistent cached_opt
    persistent cached_opt_str

    if isequal(opt, cached_opt)
        opt_str=cached_opt_str;
        return;
    end


    % options supported to libsvm
    fns=intersect(fieldnames(opt),{'s','t','d','g','r','c','n','p',...
                                    'm','e','h','n','wi','v'});

    if isempty(fns)
        opt_cell=cell(1);
    else
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
    end

    opt_cell{end}=default_postfix;
    opt_str=cosmo_strjoin(opt_cell,' ');

    cached_opt=opt;
    cached_opt_str=opt_str;

