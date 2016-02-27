function result=cosmo_naive_bayes_classifier_searchlight(ds, nbrhood, varargin)
% Run (fast) Naive Bayes classifier searchlight with crossvalidation
%
% result=cosmo_naive_bayes_classifier_searchlight(ds, nbrhood, ...)
%
% Inputs:
%   ds                   dataset struct
%   nbrhood              Neighborhood structure with fields:
%         .a               struct with dataset attributes
%         .fa              struct with feature attributes. Each field
%                            should have NF values in the second dimension
%         .neighbors       cell with NF mappings from center_ids in output
%                        dataset to feature ids in input dataset.
%                        Suitable neighborhood structs can be generated
%                        using:
%                        - cosmo_spherical_neighborhood (fmri volume)
%                        - cosmo_surficial_neighborhood (fmri surface)
%                        - cosmo_meeg_chan_neigborhood (MEEG channels)
%                        - cosmo_interval_neighborhood (MEEG time, freq)
%                        - cosmo_cross_neighborhood (to cross neighborhoods
%                                                    from the neighborhood
%                                                    functions above)
%   'partitions', par    Partition scheme to use. Typically this is the
%                        output from cosmo_nfold_partitioner or
%                        cosmo_oddeven_partitioner. Partitions schemes
%                        with more than one prediction for samples in the
%                        test set (such as the output from
%                        cosmo_nchoosek_partitioner(N) with N>1) are not
%                        supported
%   'output', out        One of:
%                        'accuracy'      return classification accuracy
%                        'predictions'   return prediction for each sample
%                                        in a test set in partitions
%   'progress', p        Show progress every p folds (default: 1)
%
% Output:
%   results_map          a dataset struct where the samples
%                        contain classification accuracies or class
%                        predictions
%
% Example:
%     % generate tiny dataset (6 voxels) and define a tiny spherical
%     % neighborhood with a radius of 1 voxel.
%     ds=cosmo_synthetic_dataset('nchunks',10,'ntargets',5);
%     nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     %
%     % set options
%     opt=struct();
%     opt.progress=false;
%     % define take-one-chunk-out crossvalidation scheme (10 folds)
%     opt.partitions=cosmo_nfold_partitioner(ds);
%     %
%     % run searchlight
%     result=cosmo_naive_bayes_classifier_searchlight(ds,nh,opt);
%     %
%     % show result
%     cosmo_disp(result);
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     >   .vol
%     >     .mat
%     >       [ 2         0         0        -3
%     >         0         2         0        -3
%     >         0         0         2        -3
%     >         0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     >     .xform
%     >       'scanner_anat'
%     > .fa
%     >   .nvoxels
%     >     [ 3         4         3         3         4         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]
%     >   .center_ids
%     >     [ 1         2         3         4         5         6 ]
%     >   .i
%     >     [ 1         2         3         1         2         3 ]
%     >   .j
%     >     [ 1         1         1         2         2         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]
%     > .samples
%     >   [ 0.6      0.74      0.44       0.6       0.7       0.4 ]
%     > .sa
%     >   .labels
%     >     { 'accuracy' }
%
%
% Notes:
%   - this function runs considerably faster than using a searchlight with
%     a classifier function and a crossvalidation scheme, because model
%     parameters during training are estimated only once for each feature.
%     Thus, speedups are most significant if elements in the neighborhood
%     have many overlapping features
%   - for other classifiers or other measures, use the more flexible
%     cosmo_searchlight function
%
% See also: cosmo_searchlight
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % check input
    cosmo_check_dataset(ds);

    % set defaults
    defaults=struct();
    defaults.output='accuracy';
    defaults.progress=1;
    opt=cosmo_structjoin(defaults,varargin{:});
    show_progress=isfield(opt,'progress') && opt.progress;

    % get neighborhood in matrix form for faster lookups
    nbrhood_mat=cosmo_convert_neighborhood(nbrhood,'matrix');

    ncenters=size(nbrhood_mat,2);
    nsamples=size(ds.samples,1);

    % get partitions for crossvalidation
    [train_idxs,test_idxs]=get_partitions(ds,opt);
    npartitions=numel(train_idxs);

    predictions=NaN(nsamples,ncenters);
    prediction_count=zeros(nsamples,1);

    if show_progress
        clock_start=clock();
        prev_progress_msg='';
    end

    % perform classification for each fold
    for fold=1:npartitions
        train_idx=train_idxs{fold};
        test_idx=test_idxs{fold};
        samples_train=ds.samples(train_idx,:);
        targets_train=ds.sa.targets(train_idx);

        % estimate parameters
        model=naive_bayes_train(samples_train, targets_train);

        % predict classes
        test_samples=ds.samples(test_idx,:);
        pred=naive_bayes_predict(model, nbrhood_mat, test_samples);

        % store predictions
        predictions(test_idx,:)=pred;
        prediction_count(test_idx)=prediction_count(test_idx)+1;

        if show_progress && (fold<10 || ~mod(fold,opt.progress) || ...
                                                fold==ncenters)
            msg='';
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                            fold/npartitions, msg, prev_progress_msg);
        end

    end

    has_prediction=prediction_count>0;

    result=struct();
    result.a=nbrhood.a;
    result.fa=nbrhood.fa;

    % set output
    switch opt.output
        case 'accuracy'
            is_correct=bsxfun(@eq,predictions(has_prediction,:),...
                                    ds.sa.targets(has_prediction));
            result.samples=mean(is_correct,1);
            result.sa.labels={'accuracy'};

        case 'predictions'
            result.samples=predictions;
            result.sa=ds.sa;
            result.sa.chunks(~has_prediction)=NaN;

        otherwise
            error(['illegal output ''%s'', must be '...
                    '''accuracy'' or ''predictions'''], opt.output);
    end

    cosmo_check_dataset(result);




function [train_idxs,test_idxs]=get_partitions(ds,opt)
    if ~isfield(opt,'partitions')
        error('the ''partitions'' option is required');
    end
    partitions=opt.partitions;
    cosmo_check_partitions(partitions,ds);

    train_idxs=partitions.train_indices;
    test_idxs=partitions.test_indices;

    all_test_idxs=cat(1,test_idxs{:});
    unq_test_idxs=unique(all_test_idxs);
    pred_counts=histc(all_test_idxs,unq_test_idxs);
    more_than_one_prediction=find(pred_counts>1,1);
    if ~isempty(more_than_one_prediction)
        error(['this function does not support crossvalidation '...
                'schemes with more than one prediction per sample, but'...
                'sample %d has %d predictions. Consider using '...
                'cosmo_nfold_partitioner or cosmo_oddeven_partitioner '...
                'to define the partitions'],...
                unq_test_idxs(more_than_one_prediction(1)), ...
                pred_counts(more_than_one_prediction(1)));
    end



function pred=naive_bayes_predict(model,nbrhood_mat,samples_train)
    classes=model.classes;
    nclasses=numel(classes);

    [max_neighbors,ncenters]=size(nbrhood_mat);
    [nsamples,nfeatures]=size(samples_train);

    if nfeatures~=size(model.mus,2)
        error(['size mismatch in number of features between training '...
                'and test set']);
    end


    max_ps=-Inf(nsamples,ncenters);
    pred=NaN(nsamples,ncenters);


    for j=1:nclasses
        mu=model.mus(j,:);
        var_=model.vars(j,:);

        % nsamples x nfeatures
        xs_z=bsxfun(@rdivide,bsxfun(@minus,samples_train,mu).^2,var_);
        log_ps=-.5*(bsxfun(@plus,log(2*pi*var_),xs_z)) + ...
                model.log_class_probs(j);
        log_sum_ps=zeros(nsamples,ncenters);
        for k=1:max_neighbors
            row_msk=nbrhood_mat(k,:)>0;
            log_sum_ps(:,row_msk)=log_sum_ps(:,row_msk)+...
                                    log_ps(:,nbrhood_mat(k,row_msk));
        end

        greater_ps_mask=log_sum_ps>max_ps;
        max_ps(greater_ps_mask)=log_sum_ps(greater_ps_mask);
        pred(greater_ps_mask)=classes(j);
    end



function model=naive_bayes_train(samples_train, targets_train)
    [ntrain,nfeatures]=size(samples_train);
    if ntrain~=numel(targets_train)
        error('size mismatch between samples and targets');
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
