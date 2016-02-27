function predicted = cosmo_classify_lda(samples_train, targets_train, samples_test, opt)
% linear discriminant analysis classifier - without prior
%
% predicted=cosmo_classify_lda(samples_train, targets_train, samples_test[,opt])
%
% Inputs:
%   samples_train       PxR training data for P samples and R features
%   targets_train       Px1 training data classes
%   samples_test        QxR test data
%   opt                 Optional struct with optional field:
%    .regularization    Used to regularize covariance matrix. Default .01
%    .max_feature_count Used to set the maximum number of features,
%                       defaults to 5000. If R is larger than this
%                       value, an error is raised. This is a (conservative)
%                       safety limit to avoid huge memory consumption
%                       for large values of R, because training the
%                       classifier typically requires in the order of 8*R^2
%                       bytes of memory
%
% Output:
%   predicted          Qx1 predicted data classes for samples_test
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',15);
%     test_chunk=1;
%     te=cosmo_slice(ds,ds.sa.chunks==test_chunk);
%     tr=cosmo_slice(ds,ds.sa.chunks~=test_chunk);
%     pred=cosmo_classify_lda(tr.samples,tr.sa.targets,te.samples,struct);
%     % show targets and predicted labels
%     disp([te.sa.targets pred])
%     >       1     1
%     >       2     2
%     >       3     3
%     >       4     4
%     >       5     5
%
% Notes:
% - this classifier does not support a prior, that is it assumes that all
%   classes have the same number of samples. If that is not the case an
%   error is thrown.
% - a safety limit of opt.max_feature_count is implemented because a large
%   number of features can crash Matlab / Octave, and/or make it very slow.
%
% (Contributions by Joern Diedrichsen, Tobias Wiestler, Nikolaas Oosterhof)
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4 || isempty(opt)
        opt=struct();
    end
    if ~isfield(opt, 'regularization'), opt.regularization=.01; end
    if ~isfield(opt, 'max_feature_count'), opt.max_feature_count=5000; end

    % support repeated testing on different data after training every time
    % on the same data. This is achieved by caching the training data
    % and associated model
    persistent cached_targets_train;
    persistent cached_samples_train;
    persistent cached_opt;
    persistent cached_model;

    if isequal(cached_targets_train, targets_train) && ...
            isequal(cached_opt, opt) && ...
            isequal(cached_samples_train, samples_train)
        % use cache
        model=cached_model;
    else
        % train classifier
        model=train(samples_train, targets_train, opt);

        % store model
        cached_targets_train=targets_train;
        cached_samples_train=samples_train;
        cached_opt=opt;
        cached_model=model;
    end

    % test classifier
    predicted=test(model, samples_test);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function model=train(samples_train, targets_train, opt)
        % train LDA classifier

        [ntrain, nfeatures]=size(samples_train);
        ntrain_=numel(targets_train);

        if ntrain_~=ntrain
            error(['size mismatch: samples_train has %d rows, '...
                    'targets_train has %d values'],ntrain,ntrain_);
        end

        if nfeatures>opt.max_feature_count
            % compute size requirements for numbers.
            % tyically this is 8 bytes per number, unless single precision
            % is used.
            w=whos('samples_train');
            size_per_number=w.bytes/numel(samples_train);

            % the covariance matrix is nfeatures x nfeatures
            mem_required=nfeatures^2*size_per_number;
            mem_required_mb=round(mem_required)/1e6; % in megabytes

            error(['A large number of features (%d) was found, '...
                    'exceeding the safety limit max_feature_count=%d '...
                    'for the %s function.\n'...
                    'This limit is imposed because computing the '...
                    'covariance matrix will require in the order of '...
                    '%.0f MB of memory, and inverting it may take '...
                    'a long time.\n'...
                    'The safety limit can be changed by setting '...
                    'the ''max_feature_count'' option to another '...
                    'value, but large values ***may freeze or crash '...
                    'the machine***.'],...
                    nfeatures,opt.max_feature_count,...
                    mfilename(),mem_required_mb);
        end

        classes=fast_vector_unique(targets_train);
        nclasses=numel(classes);

        class_mean=zeros(nclasses,nfeatures);   % class means
        class_cov=zeros(nfeatures);              % within-class variability

        % compute mean and (co)variance
        for k=1:nclasses;
            % select data in this class
            msk=targets_train==classes(k);

            % number of samples in k-th class
            n=sum(msk);

            if k==1
                if n<2
                    error(['Need at least two samples per class '...
                                'in training']);
                end
                nfirst=n; % keep track of number of samples
            elseif nfirst~=n
                error(['Different number of classes (%d and %d) - this '...
                        'is not supported. When using partitions, '...
                        'consider using cosmo_balance_partitions'], ...
                         n, nfirst);
            end

            class_samples=samples_train(msk,:);

            class_mean(k,:) = sum(class_samples,1)/n; % class mean
            res = bsxfun(@minus,class_samples,class_mean(k,:)); % residuals
            class_cov = class_cov+res'*res; % estimate common covariance matrix
        end;
        % apply regularization
        regularization=opt.regularization;
        class_cov=class_cov/ntrain;
        reg=eye(nfeatures)*trace(class_cov)/max(1,nfeatures);
        class_cov_reg=class_cov+reg*regularization;

        % linear discriminant
        class_weight=class_mean/class_cov_reg;
        class_offset=sum(class_weight .* class_mean,2);

        model=struct();
        model.class_offset=class_offset;
        model.class_weight=class_weight;
        model.classes=classes;

function predicted=test(model, samples_test)
    % test LDA classifier

    class_offset=model.class_offset;
    class_weight=model.class_weight;
    classes=model.classes;

    if size(samples_test,2)~=size(class_weight,2)
        error('test set has %d features, train set has %d',...
                size(class_weight,2),size(samples_test,2));
    end

    class_proj=bsxfun(@plus,-.5*class_offset,class_weight*samples_test');

    [unused,class_idxs]=max(class_proj);
    predicted=classes(class_idxs);

function unq_xs=fast_vector_unique(xs)
    xs_sorted=sort(xs(:));
    idxs=([true;diff(xs_sorted)>0]);
    unq_xs=xs_sorted(idxs);