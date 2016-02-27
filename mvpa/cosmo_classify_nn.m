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
%     % show targets and predicted labels (100% accuracy)
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

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain, error('illegal input size'); end

    % allocate space for output
    predicted=zeros(ntest,1);

    for k=1:ntest
        % for each sample in the test set:
        %
        % - compute its squared euclidian distance to each sample in
        %   the train set, and store this in a vector
        %   squared_distances (which must have size ntrain x 1).
        %   For two vectors a=[a_1, a_2, ..., a_N] and b=[b_1, b_2, ..., b_N],
        %   the squared euclidean distance between a and b is:
        %       (a_1 - b_1)^2 + (a_2 - b_2)^2 + ... + (a_N - b_N)^2
        %
        % - assign the class label of the sample in the training set that has
        %   the smallest squared distance.
        %
        % >@@>
        % compute difference to each sample in the training set
        delta=bsxfun(@minus, samples_train, samples_test(k,:));

        % compute distance (sqrt is unnecessary because monotonic)
        squared_distances=sum(delta.^2,2);

        % the following code is equivalent to (but slower than) the code above:
        %   squared_distances=zeros(ntrain,1);
        %   for j=1:ntrain
        %       elementwise_delta=samples_train(j,:)-samples_test(j,:);
        %       squared_elementwise_delta=elementwise_delta.^2;
        %       squared_distance=sum(squared_elementwise_delta);
        %       squared_distances(j)=squared_distance;
        %   end

        [unused, i]=min(squared_distances);
        predicted(k)=targets_train(i);
        % <@@<
    end


