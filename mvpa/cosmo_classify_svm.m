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
%  - Matlab's SVM classifier is rather slow, especially for multi-class
%    data (more than two classes). When classification takes a long time,
%    consider using libsvm.
%  - In both implemenations, by default the data is scaled.
%    Note that cosmo_crossvalidate and cosmo_crossvalidation_measure
%    provide an option 'normalization' to perform data scaling.
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',10);
%     test_chunk=2;
%     te=cosmo_slice(ds,ds.sa.chunks==test_chunk);
%     tr=cosmo_slice(ds,ds.sa.chunks~=test_chunk);
%     pred=cosmo_classify_svm(tr.samples,tr.sa.targets,te.samples,struct);
%     disp(pred)
%     >      3
%     >      2
%     >      3
%     >      4
%     >      5
%
% See also: svmtrain, svmclassify, cosmo_classify_svm,
%           cosmo_classify_libsvm, cosmo_crossvalidate,
%           cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

persistent cached_classifier_func;
persistent cached_classifier_name;

auto_select=true;

if nargin>=4
    if isfield(opt,'svm')
        svm_name=opt.svm;
        auto_select=false;
        opt=rmfield(opt,'svm');
    end
else
    opt=struct();
end

if ~isnumeric(cached_classifier_func) && ...
                        (auto_select || strcmp(svm_name, ...
                                        cached_classifier_name))
    classifier_func=cached_classifier_func;
else
    if auto_select
        svm_name='libsvm';

        if ~cosmo_check_external(svm_name, false) && ...
                        cosmo_check_external('matlabsvm',false)
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
            error(['unsupported svm ''%s'': must be one of: '...
                        'matlabsvm, libsvm'], svm_name);
    end

    cached_classifier_name=svm_name;
end

% ensure that the classifer func is not stored in this function if an error
% occurs. After sucessful classifcation the classifier_func is restored.
cached_classifier_func=[];

predicted=classifier_func(samples_train, targets_train, samples_test, opt);

cached_classifier_func=classifier_func;


