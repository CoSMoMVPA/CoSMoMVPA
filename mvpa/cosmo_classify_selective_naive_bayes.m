function predicted=cosmo_classify_selective_naive_bayes(samples_train, targets_train, samples_test, unused)
% naive bayes classifier with feature selection based on Langly & Sage
%
% predicted=cosmo_classify_selective_naive_bayes(samples_train, targets_train, samples_test[, opt])
%
% Inputs
% - samples_train      PxR training data for P samples and R features
% - targets_train      Px1 training data classes
% - samples_test       QxR test data
%-  opt                (currently ignored)
%
% Output
% - predicted          Qx1 predicted data classes for samples_test
%
% Notes:
% - Based on Langly & Sage, Induction of Selective Bayesian Classifiers
% - This function is much slower than the canonical naive bayes classifier
%
% See also: cosmo_classify_naive_bayes
%
% NNO Oct 2013, adopted from classify_naive_bayes Aug 2013

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % optimize based on Langly & Sage

    % precompute p-values for training set
    ps_train=zeros(nclasses, nfeatures, ntrain);
    for k=1:ntrain
        pk=normcdf(repmat(samples_train(k,:),nclasses,1), mus, stds);
        ps_train(:,:,k)=pk;
    end

    % convert to log(p) for better precision
    ps_train=log(ps_train);

    % which features to be used for training
    train_mask=false(nfeatures,1);

    % occurence of most common class
    best_acc=max(exp(class_probs));

    % Langly & Sage algorithm:
    % 1) start with an empty feature training set and set baseline accuracy
    % 2) add each feature seperately, and do classification on the training
    %    set.
    % 3) see which feature improved classification accuracy most
    % 4) if there is negative improvement for all features, goto 6
    % 5) add the feature from (3) and add it to the feature training set
    % 6) classify test data with the features in the feature training set
    cand_accs=zeros(ntrain,1);
    while true
        % find a candidate feature to add to the training set
        candidates=find(~train_mask);
        ncandidates=numel(candidates);

        % reset all accuracies to zero
        cand_accs(:)=0;

        % try all candidates
        for k=1:ncandidates
            c=candidates(k);

            % set candidate in training mask
            train_mask(c)=true;

            % naive bayes classification
            ps=bsxfun(@plus,sum(ps_train(:,train_mask,:),2),class_probs);
            [unused,pred_idxs]=max(squeeze(ps),[],1);

            % compute accuracy for this candidate
            cand_accs(c)=sum(classes(pred_idxs)==targets_train(:))/ntrain;

            % disable from training mask
            train_mask(c)=false;
        end

        % find the candidate with heighest accuracy
        [best_cand_acc, max_cand_acc_idx]=max(cand_accs);

        % if with that candidate accuracy got worse, stop adding more
        % candiates and proceed to classification of test data
        if best_cand_acc<best_acc
            break;
        end
        best_acc=best_cand_acc;
        train_mask(max_cand_acc_idx)=true;
    end

    % select the statistics from the selected features in train_mask
    mus=mus(:,train_mask);
    stds=stds(:,train_mask);

    %%%%%%%%%%%
    % standard naive bayse prediction

    % allocate space for output
    predicted=zeros(ntest,1);

    for k=1:ntest
        % apply train_mask to the set sample
        sample=samples_test(k,train_mask);

        % compute feature-wise probality relative to stats of each class
        ps=normcdf(repmat(sample,nclasses,1), mus, stds);

        % being 'naive' we assume independence - so take the product of the
        % p values. (for better precision we take the log of the probablities
        % and sum them)
        test_prob=sum(log(ps),2)+class_probs;

        % find the one with the highest probability
        [unused, mx_idx]=max(test_prob);

        predicted(k)=classes(mx_idx);
    end



