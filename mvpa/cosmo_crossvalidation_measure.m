function ds_sa = cosmo_crossvalidation_measure(ds, varargin)
% performs cross-validation using a classifier
%
% accuracy = cosmo_cross_validation_accuracy_measure(dataset, args)
%
% Inputs:
%   dataset             struct with fields .samples (PxQ for P samples and
%                       Q features) and .sa.targets (Px1 labels of samples)
%   args                struct containing classifier, partitions, and
%                       possibly other fields that are given to the
%                       classifier.
%   args.classifier     function handle to classifier, e.g.
%                       @classify_naive_baysian
%   args.partitions     Partition scheme, for example the output from
%                       cosmo_nfold_partition
%   args.output         'accuracy' (default), 'predictions', or
%                       'accuracy_by_chunk'
%   args.check_partitions  optional (default: true). If set to false then
%                          partitions are not checked for being set
%                          properly.
%   args.normalization  optional, one of '{zscore,demean,scale_unit}{1,2}'
%                       to normalize the data prior to classification using
%                       zscoring, demeaning or scaling to [-1,1] along the
%                       first or second dimension of ds. Normalization
%                       parameters are estimated using the training data
%                       and applied to the testing data.
%   args.average_train_X  average the samples in the train set using
%                       cosmo_average_samples. For X, use any parameter
%                       supported by cosmo_average_samples, i.e. either
%                       'count' or 'ratio', and optionally, 'resamplings'
%                       or 'repeats'.
%
% Output:
%    ds_sa        Struct with fields:
%      .samples   Scalar with classification accuracy.
%      .sa        Struct with field:
%                 - if args.output=='accuracy':
%                       .labels  =={'accuracy'}
%                 - if args.output=='predictions'
%                       .targets     } Px1 real and predicted labels of
%                       .predictions } each sample
%
% Examples:
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     %
%     % use take-1-chunk for testing crossvalidation
%     opt=struct();
%     opt.partitions=cosmo_nfold_partitioner(ds);
%     opt.classifier=@cosmo_classify_naive_bayes;
%     % run crossvalidation and return accuracy (the default)
%     acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp(acc_ds);
%     > .samples
%     >   [ 0.917 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % let the measure return predictions instead of accuracy,
%     % and use take-1-chunks out for testing crossvalidation;
%     % use LDA classifer and let targets be in range 7..9
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4,'target1',7);
%     opt=struct();
%     opt.partitions=cosmo_nchoosek_partitioner(ds,1);
%     opt.output='predictions';
%     opt.classifier=@cosmo_classify_lda;
%     pred_ds=cosmo_crossvalidation_measure(ds,opt);
%     %
%     % show results. Because each sample was predicted just once,
%     % .sa.chunks contains the chunks of the original input
%     cosmo_disp(pred_ds);
%     > .sa
%     >   .targets
%     >     [ 7
%     >       8
%     >       9
%     >       :
%     >       7
%     >       8
%     >       9 ]@12x1
%     >   .chunks
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       4
%     >       4
%     >       4 ]@12x1
%     > .samples
%     >   [ 9
%     >     8
%     >     9
%     >     :
%     >     7
%     >     9
%     >     7 ]@12x1
%     >
%     %
%     % return accuracy, but use z-scoring on each training set
%     % and apply the estimated mean and std to the test set.
%     % Use take-2-chunks out for corssvalidation
%     ds=cosmo_synthetic_dataset('ntargets',3,'nchunks',4);
%     opt=struct();
%     opt.output='accuracy';
%     opt.normalization='zscore';
%     opt.classifier=@cosmo_classify_lda;
%     opt.partitions=cosmo_nchoosek_partitioner(ds,2);
%     z_acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp(z_acc_ds);
%     > .samples
%     >   [ 0.833 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%     % illustrate accuracy for partial test set
%     ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',5);
%     %
%     % use take-1-chunk out for testing crossvalidation, but only test on
%     % chunks 2 and 4
%     opt=struct();
%     opt.partitions=cosmo_nchoosek_partitioner(ds,1,'chunks',[2 4]);
%     opt.classifier=@cosmo_classify_naive_bayes;
%     % run crossvalidation and return accuracy (the default)
%     acc_ds=cosmo_crossvalidation_measure(ds,opt);
%     % show accuracy
%     cosmo_disp(acc_ds.samples)
%     > 0.75
%     % show predictions
%     opt.output='predictions';
%     pred_ds=cosmo_crossvalidation_measure(ds,opt);
%     cosmo_disp([pred_ds.samples pred_ds.sa.targets pred_ds.sa.chunks]);
%     > [ NaN         1       NaN
%     >   NaN         2       NaN
%     >     1         1         2
%     >    :          :        :
%     >     1         2         4
%     >   NaN         1       NaN
%     >   NaN         2       NaN ]@10x3
%
% Notes:
%   - using this function, crossvalidation can be run using a searchlight
%
% See also: cosmo_searchlight, cosmo_average_samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% deal with input arguments
params=cosmo_structjoin('output','accuracy',... % default output
                        varargin); % use input arguments

% Run cross validation to get the accuracy (see the help of
% cosmo_crossvalidate)
% >@@>
classifier=params.classifier;
partitions=params.partitions;

params=rmfield(params,'classifier');
params=rmfield(params,'partitions');
[pred,accuracy,chunks]=cosmo_crossvalidate(ds,classifier,...
                                        partitions,params);
% <@@<
ds_sa=struct();

switch params.output
    case 'accuracy'
        ds_sa.samples=accuracy;
        ds_sa.sa.labels={'accuracy'};

    case {'predictions','raw'}
        ds_sa.sa=ds.sa;
        ds_sa.samples=pred(:);
        ds_sa.sa.chunks=chunks;

    case 'accuracy_by_chunk'
        [unused,orig_chunks]=cosmo_index_unique(ds.sa.chunks);
        norig_chunks=numel(orig_chunks);

        ds_sa.samples=NaN(norig_chunks,1);
        ds_sa.sa.chunks=NaN(norig_chunks,1);

        [chunk_idxs,unq_chunks]=cosmo_index_unique(chunks);
        for k=1:numel(unq_chunks)
            chunk_value=unq_chunks(k);
            if isnan(chunk_value)
                continue;
            end
            idx=chunk_idxs{k};
            ds_sa.samples(k)=mean(ds.sa.targets(idx)==pred(idx));
            ds_sa.sa.chunks(k)=chunk_value;
        end


    otherwise
        error('Illegal output parameter %s', params.output);
end

