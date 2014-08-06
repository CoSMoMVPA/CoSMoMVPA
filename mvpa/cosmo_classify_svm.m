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
%
% See also svmtrain, svmclassify, cosmo_classify_svm

persistent cached_path;
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

n=numel(cached_path);
path_changed=true;
if n>0
    p=path();
    path_changed=n~=numel(p) || ~strncmp(p,cached_path,n);
end

if ~path_changed && (auto_select || strcmp(svm_name, ...
                                        cached_classifier_name))
    classifier_func=cached_classifier_func;
else
    if path_changed
        cached_path=path();
    end

    if auto_select
        if cosmo_check_external('libsvm',false)
            svm_name='libsvm';
        elseif cosmo_check_external('matlabsvm',false)
            svm_name='matlabsvm';
        end
    end

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

predicted=classifier_func(samples_train, targets_train, samples_test, opt);


