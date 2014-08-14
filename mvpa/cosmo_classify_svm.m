function predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
% classifier wrapper that uses either matlab's or libsvm's SVM.
%
% predicted=cosmo_classify_svm(samples_train, targets_train, samples_test, opt)
%
% Inputs:
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                (optional) struct with options for classification
%                      If a field 'svm' is present it should be either
%                      'libsvm' or 'matlabsvm' to use that SVM. If this
%                      field is absent it will be selected automatically.
%
% Output
%   predicted          Qx1 predicted data classes for samples_test
%
% Notes:
%  - cosmo_classify_svm can use either libsvm or matlab's svm, whichever is
%    present
%  - if both are present, then there is a conflict because 'svmtrain' is
%    implemented differently by libsvm or matlab's svm. The path setting
%    determines which svm implementation is used.
%  - when using libsvm it requires version 3.18 or later:
%    https://github.com/cjlin1/libsvm
%  - for a guide on svm classification, see
%      http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf
%    Note that cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling
%
% See also svmtrain, svmclassify, cosmo_classify_svm

persistent cached_classifier_func;
persistent cached_classifier_name;

if nargin>=4 && isfield(opt,'svm')
    svm_name=opt.svm;
    auto_select=false;
    opt=rmfield(opt,'svm');
else
    opt=struct();
    auto_select=true;
end

path_changed=cosmo_path_changed();

if ~path_changed && ~isnumeric(cached_classifier_func) && ...
                        (auto_select || strcmp(svm_name, ...
                                        cached_classifier_name))
    classifier_func=cached_classifier_func;
else
    if auto_select
        if any(cosmo_check_external({'@stats','@bioinfo'},false))
            svm_name='matlabsvm';
        else
            svm_name='libsvm';
        end

        if cosmo_check_external('libsvm',false)
            svm_name='libsvm';
        elseif cosmo_check_external('matlabsvm',false)
            svm_name='matlabsvm';
        end
    end

    % let it throw an error if there is a conflict (e.g. matlabsvm with
    % neuroelf)
    cosmo_check_external(svm_name);

    switch svm_name
        case 'libsvm'
            classifier_func=@cosmo_classify_libsvm;
        case 'matlabsvm';
            classifier_func=@cosmo_classify_matlabsvm;
        otherwise
            error('unsupported svm ''%s''', svm_name);
    end

    cached_classifier_func=classifier_func;
    cached_classifier_name=svm_name;
end

on_cleanup_=onCleanup(cosmo_path_changed('not_here'));

predicted=classifier_func(samples_train, targets_train, samples_test, opt);


