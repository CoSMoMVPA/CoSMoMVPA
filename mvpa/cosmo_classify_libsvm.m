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
%     ?                any option supported by libsvm's svmtrain.
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
% See also svmtrain, svmclassify, cosmo_classify_svm,
%          cosmo_classify_matlabsvm
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4
        opt=struct();
    end

    % support repeated testing on different data after training every time
    % on the same data. This is achieved by caching the training data
    % and associated model
    persistent cached_targets_train;
    persistent cached_samples_train;
    persistent cached_opt;
    persistent cached_model;

    cache_limit=1e5; % avoid caching huge training sets

    if isequal(cached_targets_train, targets_train) && ...
            isequal(cached_opt, opt) && ...
            numel(samples_train) < cache_limit && ...
            isequal(cached_samples_train, samples_train)
        % use cache
        model=cached_model;
    else
        model=train(samples_train,targets_train,opt);

                % store model
        cached_targets_train=targets_train;
        cached_samples_train=samples_train;
        cached_opt=opt;
        cached_model=model;
    end

    predicted=test(model, samples_test);

function model=train(samples_train,targets_train,opt)
    [ntrain, nfeatures]=size(samples_train);

    model=struct();
    model.nfeatures=nfeatures;
    model.normalize=[]; % off by default

    % check input size
    ntrain_=numel(targets_train);
    if ntrain_~=ntrain
        error('illegal input size');
    end

    % construct options string for svmtrain
    opt_str=libsvm_opt2str(opt);

    % auto-scale is the default
    autoscale= ~isstruct(opt) || ...
                ~isfield(opt,'autoscale') || ...
                isempty(opt.autoscale) || ...
                opt.autoscale;

    % perform autoscale if necessary
    if autoscale
        [samples_train, params]=cosmo_normalize(samples_train, ...
                                                    'zscore', 1);
        model.normalize=params;
    end
    train_func=@()svmtrain(targets_train(:), ...
                            samples_train, ...
                            opt_str);

    model.libsvm_model=eval_with_check_external(train_func);


function output=eval_with_check_external(func)
% Evaluates func() in try-catch block. If it fails, this may be due
% to missing libsvm and/or libsvm conflicting with Matlab's svm.
% Therefore first cosmo_check_external is called, which will give an
% informative error message if that is the case. Otherwise the original
% message is shown.

    try
        output=func();
    catch
        cosmo_check_external('libsvm');
        rethrow(lasterror());
    end


function predicted=test(model, samples_test)
    [ntest, nfeatures]=size(samples_test);
    if nfeatures~=model.nfeatures
        error(['Number of features in train set (%d) and '...
                    'test set (%d) do not match'],...
                    model.nfeatures,nfeatures);
    end

    if ~isempty(model.normalize)
        samples_test=cosmo_normalize(samples_test, model.normalize);
    end

    test_opt_str='-q'; % quiet (no output)
    test_func=@()svmpredict(NaN(ntest,1), samples_test, ...
                            model.libsvm_model, test_opt_str);
    predicted=eval_with_check_external(test_func);




function opt_str=libsvm_opt2str(opt)
    persistent cached_opt
    persistent cached_opt_str

    if ~isequal(opt, cached_opt)
        default_opt={'t','q';...
                        '0',''};
        n_default=size(default_opt,2);

        libsvm_opt_keys={'s','t','d','g','r','c','n','p',...
                         'm','e','h','n','wi','v'};
        opt_struct=cosmo_structjoin(opt);

        keys=intersect(fieldnames(opt_struct),libsvm_opt_keys);
        n_keys=numel(keys);

        use_defaults=true(1,n_default);

        libsvm_opt=cell(2,n_keys);
        for k=1:n_keys
            key=keys{k};
            default_pos=find(cosmo_match(default_opt(1,:),(key)),1);

            if ~isempty(default_pos)
                use_defaults(default_pos)=false;
            end

            value=opt_struct.(key);
            if isnumeric(value)
                value=sprintf('%d',value);
            end

            libsvm_opt(:,k)={key;value};
        end

        all_opt=[libsvm_opt default_opt(:, use_defaults)];

        cached_opt_str=sprintf('-%s %s ', all_opt{:});
        cached_opt=opt;
    end

    opt_str=cached_opt_str;
