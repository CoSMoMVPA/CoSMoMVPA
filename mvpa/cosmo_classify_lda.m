function predicted = cosmo_classify_lda(samples_train, targets_train, samples_test, opt)
% linear discriminant analysis classifier - without prior
%
% predicted=cosmo_classify_lda(samples_train, targets_train, samples_test[,opt])
%
% Inputs:
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                Optional struct with optional field:
%    .regularization   Used to regularize covariance matrix. Default .01
%
% Output:
%   predicted          Qx1 predicted data classes for samples_test
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',15);
%     test_chunk=1;
%     te=cosmo_slice(ds,ds.sa.chunks==test_chunk);
%     tr=cosmo_slice(ds,ds.sa.chunks~=test_chunk);
%     pred=cosmo_classify_naive_bayes(tr.samples,tr.sa.targets,te.samples,struct);
%     % show targets and predicted labels
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     1
%     >      3     5
%     >      4     4
%     >      5     5
%
% Note:
% - this classifier does not support a prior, that is it assumes that all
%   classes have the same number of samples. If that is not the case an
%   error is thrown.
%
% Joern Diedrichsen, Tobias Wiestler, NNO Nov 2008; NNO updated Aug 2013

    if nargin<4 || isempty(opt) || ~isfield(opt, 'regularization')
        opt.regularization=.01;
    end

    persistent cached_targets_train;
    persistent cached_samples_train;
    persistent cached_opt;
    persistent cached_model;

    if isequal(cached_targets_train, targets_train) && ...
            isequal(cached_opt, opt) && ...
            isequal(cached_samples_train, samples_train)
        model=cached_model;
    else
        model=train(samples_train, targets_train, opt);
        cached_targets_train=targets_train;
        cached_samples_train=samples_train;
        cached_opt=opt;
        cached_model=model;
    end

    predicted=test(model, samples_test);

    function model=train(samples_train, targets_train, opt)
        [ntrain, nfeatures]=size(samples_train);
        ntrain_=numel(targets_train);

        if ntrain_~=ntrain
            error('size mismatch');
        end

        classes=unique(targets_train);
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
                    error('Need at least two samples per class in training');
                end
                nfirst=n; % keep track of number of samples
            elseif nfirst~=n
                error(['Different number of classes (%d and %d) - this is '...
                        'not supported'], n, nfirst);
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
    class_offset=model.class_offset;
    class_weight=model.class_weight;
    classes=model.classes;

    if size(samples_test,2)~=size(class_weight,2)
        error('size mismatch');
    end

    class_proj=bsxfun(@plus,-.5*class_offset,class_weight*samples_test');

    [unused,class_idxs]=max(class_proj);
    predicted=classes(class_idxs);
