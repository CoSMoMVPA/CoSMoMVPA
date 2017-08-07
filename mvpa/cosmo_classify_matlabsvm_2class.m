function predicted=cosmo_classify_matlabsvm_2class(samples_train, targets_train, samples_test, opt)
% svm classifier wrapper (around svmtrain/svmclassify)
%
% predicted=cosmo_classify_matlabsvm_2class(samples_train, targets_train, samples_test, opt)
%
% Inputs:
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                struct with options. supports any option that
%                      svmtrain supports
%
% Output:
%   predicted          Qx1 predicted data classes for samples_test
%
% Notes:
%  - this function uses Matlab's builtin svmtrain function, which has
%    the same name as LIBSVM's version. Use of this function is not
%    supported when LIBSVM's svmtrain precedes in the matlab path; in
%    that case, adjust the path or use cosmo_classify_libsvm instead.
%  - Matlab's SVM classifier is rather slow, especially for multi-class
%    data (more than two classes). When classification takes a long time,
%    consider using libsvm.
%  - for a guide on svm classification, see
%      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
%    Note that cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling
%
% See also svmtrain, svmclassify, cosmo_classify_matlabsvm
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4, opt=struct(); end

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain
        error('illegal input size');
    end

    if nfeatures==0
        % matlab's svm cannot deal with empty data, so predict all
        % test samples as the class of the first sample
        predicted=targets_train(1) * ones(ntest,1);
        return
    end

    classes=unique(targets_train);
    nclasses=numel(classes);
    if nclasses~=2
        error(['%s requires 2 classes, found %d. Consider using '...
                'cosmo_classify_{matlab,lib}svm instead'],...
                    mfilename(),nclasses);
    end

    opt_cell=opt2cell(opt);

    % train & test; if it fails, see if this caused by non-functioning
    % matlabsvm

    try
        if ~cached_has_matlabsvm()
            cosmo_check_external('matlabsvm');
        end
        % Use svmtrain and svmclassify to get predictions for the testing set.
        % (Hint: 'opt_cell{:}' allows you to pass the options as varargin)
        % >@@>

        s = svmtrain(samples_train, targets_train, opt_cell{:});
        predicted=svmclassify(s, samples_test);
        % <@@<
    catch
        caught_exception=lasterror();
        cosmo_check_external('matlabsvm');

        if strcmp(caught_exception.identifier,...
                            'stats:svmtrain:NoConvergence');
            error(['SVM training did not converge. Your options are:\n'...
                   ' 1) increase ''boxconstraint''\n'...
                   ' 2) increase ''tolkkt''\n'...
                   ' 3) set ''kktviolationlevel'' to a positive value\n'...
                   ' 4) use a different classifier\n'...
                   'If you do not have a strong preference for '...
                   'either option, you are advised to try option (4) '...
                   'using cosmo_classify_lda'],'');
        else
            rethrow(caught_exception);
        end
    end

    % helper function to convert cell to struct
function opt_cell=opt2cell(opt)

    if isempty(opt)
        opt_cell=cell(0);
        return;
    end

    to_keep={'kernel_function',...
             'rbf_sigma',...
             'polyorder',...
             'mlp_params',...
             'method',...
             'options',...
             'tolkkt',...
             'kktviolationlevel',...
             'kernelcachelimit',...
             'boxconstraint',...
             'autoscale',...
             'showplot'};

    fns=fieldnames(opt);
    keep_msk=cosmo_match(fns, to_keep);
    keep_fns=fns(keep_msk);
    keep_id = find(keep_msk);

    n=numel(keep_fns);
    opt_cell=cell(1,2*n);
    for k=1:n
        fn=fns{keep_id(k)};
        opt_cell{k*2-1}=fn;
        opt_cell{k*2}=opt.(fn);
    end


function tf=cached_has_matlabsvm()
    persistent cached_tf;

    if isequal(cached_tf,true)
        tf=true;
        return
    end

    cached_tf=cosmo_check_external('matlabsvm');
    tf=cached_tf;

