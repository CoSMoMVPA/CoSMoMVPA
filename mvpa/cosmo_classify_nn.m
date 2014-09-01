function predicted=cosmo_classify_nn(samples_train, targets_train, samples_test, unused)
% nearest neighbor classifier
%
% predicted=cosmo_classify_nn(samples_train, targets_train, samples_test[, opt])
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
%     pred=cosmo_classify_nn(tr.samples,tr.sa.targets,te.samples,struct);
%     % show targets and predicted labels (40% accuracy)
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     3
%     >      3     5
%     >      4     5
%     >      5     5
%
% See also: cosmo_crossvalidate, cosmo_crossvalidation_measure
%
% NNO Aug 2013

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

    % allocate space for output
    predicted=zeros(ntest,1);

    for k=1:ntest
        % for each sample in the test set:
        % - compute its euclidian distance to each sample in the train set.
        % - assign the class label of the feature that is nearest
        % >@@>
        delta=bsxfun(@minus, samples_train, samples_test(k,:));

        % (sqrt is unnecessary because it is monotonic)
        squared_distance=sum(delta.^2,2);
        [unused, i]=min(squared_distance);
        predicted(k)=targets_train(i);
        % <@@<
    end


