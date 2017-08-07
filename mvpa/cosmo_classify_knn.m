function predicted=cosmo_classify_knn(samples_train, targets_train, samples_test, opt)
% k-nearest neighbor classifier
%
% predicted=cosmo_classify_nn(samples_train, targets_train, samples_test[, opt])
%
% Inputs:
%   samples_train      PxR training data for P samples and R features
%   targets_train      Px1 training data classes
%   samples_test       QxR test data
%   opt                struct with field:
%     .knn             Number of nearest neighbors to be considered
%     .norm            distance norm (default: 2)
%
% Output:
%   predicted          Qx1 predicted data classes for samples_test. Each
%                      predicted sample is laballed as having the most
%                      samples in the training set within the nearest
%                      opt.knn samples.
%
% Example:
%     ds=cosmo_synthetic_dataset('ntargets',5,'nchunks',15);
%     test_chunk=1;
%     te=cosmo_slice(ds,ds.sa.chunks==test_chunk);
%     tr=cosmo_slice(ds,ds.sa.chunks~=test_chunk);
%     opt=struct();
%     opt.knn=2;
%     pred=cosmo_classify_knn(tr.samples,tr.sa.targets,te.samples,opt);
%     % show targets and predicted labels (40% accuracy)
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     3
%     >      3     3
%     >      4     4
%     >      5     5
%     %
%     opt.norm=1; % city-block distance
%     pred=cosmo_classify_knn(tr.samples,tr.sa.targets,te.samples,opt);
%     % show targets and predicted labels (40% accuracy)
%     disp([te.sa.targets pred])
%     >      1     1
%     >      2     3
%     >      3     3
%     >      4     4
%     >      5     5
%
% Notes:
%   - in the case of knn=1, this function is identical to cosmo_classify_nn
%
% See also: cosmo_crossvalidate, cosmo_crossvalidation_measure
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_isfield(opt,'knn',true);
    knn=opt.knn;

    if cosmo_isfield(opt,'norm')
        norm_=opt.norm;
    else
        norm_=2;
    end

    [ntrain, nfeatures]=size(samples_train);
    [ntest, nfeatures_]=size(samples_test);
    ntrain_=numel(targets_train);

    if nfeatures~=nfeatures_ || ntrain_~=ntrain
        error('illegal input size');
    end

    if knn>ntrain
        error(['Cannot find nearest %d neighbors: only %d samples '...
                    'in training set'],...
                    knn, ntrain);
    end

    % allocate space for output
    all_predicted=zeros(ntest, knn);

    % classify each test sample
    for k=1:ntest
        % for each sample in the test set:
        % - compute its  distance to each sample in the train set.
        % - assign the class label of the feature that is nearest
        % >@@>
        delta=bsxfun(@minus, samples_train, samples_test(k,:));

        pow_distance=sum(abs(delta).^norm_,2);

        [unused, i]=sort(pow_distance);
        all_predicted(k, 1:knn)=i(1:knn);
        % <@@<
    end

    % determine which targets are predicted most often
    [winners,classes]=cosmo_winner_indices(targets_train(all_predicted));
    predicted=classes(winners);





