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
%     pred=cosmo_classify_naive_bayes(tr.samples,tr.sa.targets,te.samples,struct);
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     2
%     >      3     5
%     >      4     4
%     >      5     4
%
% See also: cosmo_crossvalidate, cosmo_crossvalidation_measure
%
% NNO Aug 2013

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
    stds=model.stds;
    class_probs=model.class_probs;
    classes=model.classes;
    nclasses=numel(classes);

    [ntest,nfeatures]=size(samples_test);
    if nfeatures~=size(mus,2)
        error('size mismatch');
    end

    predicted=zeros(ntest,1);

    for k=1:ntest
        sample=samples_test(k,:);
        ps=fast_normcdf(sample, mus, stds);

        % make octave more compatible with matlab: convert nan to 1
        ps(isnan(ps))=1;

        % being 'naive' we assume independence - so take the product of the
        % p values. (for better precision we take the log of the probablities
        % and sum them)
        test_prob=sum(log(ps),2)+class_probs;

        % find the one with the highest probability
        [unused, mx_idx]=max(test_prob);

        predicted(k)=classes(mx_idx);
    end

function ps=fast_normcdf(xs, mus, stds)
    ps=.5*erfc(-bsxfun(@minus,xs,mus)./(stds*sqrt(2)));


function model=train(samples_train, targets_train)
    [ntrain,nfeatures]=size(samples_train);
    if ntrain~=numel(targets_train)
        error('size mismatch');
    end

    classes=unique(targets_train);
    nclasses=numel(classes);

    % allocate space for statistics of each class
    mus=zeros(nclasses,nfeatures);
    stds=zeros(nclasses,nfeatures);
    class_probs=zeros(nclasses,1);

    % compute means and standard deviations of each class
    for k=1:nclasses
        msk=targets_train==classes(k);
        n=sum(msk); % number of samples
        d=samples_train(msk,:); % samples in this class
        mu=mean(d); %mean
        mus(k,:)=mu;
        stds(k,:)=sqrt(1/(n-1) * sum(bsxfun(@minus,mu,d).^2,1)); % standard deviation - faster implementation than 'std'
        class_probs(k)=log(n/ntrain); % log of class probability
    end

    model.mus=mus;
    model.stds=stds;
    model.class_probs=class_probs;
    model.classes=classes;
