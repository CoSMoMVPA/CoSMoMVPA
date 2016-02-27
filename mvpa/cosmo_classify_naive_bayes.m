function predicted=cosmo_classify_naive_bayes(samples_train, targets_train, samples_test, unused)
% naive bayes classifier
%
% predicted=cosmo_classify_naive_bayes(samples_train, targets_train, samples_test[, opt])
%
% Inputs:
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                (currently ignored)
%
% Output:
%   predicted          Qx1 predicted data classes for samples_test
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',15);
%     test_chunk=1;
%     te=cosmo_slice(ds,ds.sa.chunks==test_chunk);
%     tr=cosmo_slice(ds,ds.sa.chunks~=test_chunk);
%     unused=struct();
%     pred=cosmo_classify_naive_bayes(tr.samples,tr.sa.targets,...
%                                        te.samples,unused);
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     2
%     >      3     3
%     >      4     4
%     >      5     5
%
% See also: cosmo_crossvalidate, cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    persistent cached_targets_train;
    persistent cached_samples_train;
    persistent cached_model;

    if isequal(cached_targets_train, targets_train) && ...
            isequal(cached_samples_train, samples_train)
        model=cached_model;
    else
        model=train(samples_train, targets_train);
        cached_targets_train=targets_train;
        cached_samples_train=samples_train;
        cached_model=model;
    end

    predicted=test(model, samples_test);

function predicted=test(model, samples_test)
    mus=model.mus;
    vars=model.vars;
    log_class_probs=model.log_class_probs;
    classes=model.classes;

    [ntest,nfeatures]=size(samples_test);
    if nfeatures~=size(mus,2)
        error('size mismatch');
    end

    predicted=zeros(ntest,1);

    for k=1:ntest
        sample=samples_test(k,:);
        log_ps=log_normal_pdf(sample, mus, vars);

        % make octave more compatible with matlab: convert nan to 1
        log_ps(isnan(log_ps))=1;

        % being 'naive' we assume independence - so take the product of the
        % p values. (for better precision we take the log of the
        % probablities and sum them)
        log_test_prob=sum(log_ps,2)+log_class_probs;

        % find the one with the highest probability
        [unused, mx_idx]=max(log_test_prob);

        predicted(k)=classes(mx_idx);
    end

function ps=log_normal_pdf(xs, mus, vars)
    ps=-.5*(log(2*pi*vars) + bsxfun(@minus,xs,mus).^2./vars);


function model=train(samples_train, targets_train)
    [ntrain,nfeatures]=size(samples_train);
    if ntrain~=numel(targets_train)
        error('size mismatch');
    end

    [class_idxs,classes_cell]=cosmo_index_unique({targets_train});
    classes=classes_cell{1};
    nclasses=numel(classes);

    % allocate space for statistics of each class
    mus=zeros(nclasses,nfeatures);
    vars=zeros(nclasses,nfeatures);
    log_class_probs=zeros(nclasses,1);

    % compute means and standard deviations of each class
    for k=1:nclasses
        idx=class_idxs{k};
        nsamples_in_class=numel(idx); % number of samples
        if nsamples_in_class<2
            error(['Cannot train: class %d has only %d samples, %d '...
                    'are required'],nsamples_in_class,classes(k));
        end

        d=samples_train(idx,:); % samples in this class
        mu=mean(d); %mean
        mus(k,:)=mu;

        % variance - faster than 'var'
        vars(k,:)=sum(bsxfun(@minus,mu,d).^2,1)/nsamples_in_class;

        % log of class probability
        log_class_probs(k)=log(nsamples_in_class/ntrain);
    end

    model.mus=mus;
    model.vars=vars;
    model.log_class_probs=log_class_probs;
    model.classes=classes;
