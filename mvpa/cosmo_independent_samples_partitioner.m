function partitions=cosmo_independent_samples_partitioner(ds,varargin)
% Compute partitioning scheme based on dataset with independent samples
%
% partitions=cosmo_independent_samples_partitioner(ds,...)
%
% Inputs:
%   ds                          dataset structure with fields .samples,
%                               .sa.targets and .sa.chunks. Since this
%                               function is intended for the case that all
%                               rows (patterns) in .samples are
%                               independent, it is required that all values
%                               in .sa.chunks are unique.
%   'fold_count',c              Return partitions with c folds.
%   'test_count', tc            } Return partitions so that in each test
%   'test_ratio', tr            } set there are tc samples (or (tr*100%)
%                               } per unique target. These two options are
%                               } mutually exclusive
%   'seed',s                    (optional) use seed s for pseudo-random
%                               number generator (default: s=1). If
%                               provided, then this function behaves
%                               pseudo-ranomly but deterministically, and
%                               different calls return the same output.
%                               If s=0, then repeated calls to this
%                               function gives different outputs.
%   'max_fold_count'            Safety limit to the maximum number of folds
%                               that can be returned (default: 10000). When
%                               this number is set to a larger value, this
%                               may result in too much memory being
%                               required and slowing down or crashing the
%                               machine.
% Output:
%   partitions                  Cell with fields .train_indices and
%                               .test_indices, both of size c x 1.
%                               Each element in .test_indices has tc (when
%                               using 'test_count') or tr * min_count
%                               (when using 'test_ratio'; min_count is the
%                               minimum number of samples over classes)
%                               elements; each element in .train_indices
%                               has min_count-tc elements.
%                               In other words, the resulting partitions
%                               are balanced for both training and test
%                               set.
%
% Examples:
%     % make simple dataset with 9 samples, 3 features
%     ds=struct();
%     ds.samples=randn(9,3);
%     ds.sa.targets=[1 1 1 1 1 2 2 2 2]';
%     ds.sa.chunks=(1:9)';
%     %
%     % Partition scheme with 5 folds, each in which 1 target in each chunk
%     % is used for testing
%     partitions=cosmo_independent_samples_partitioner(ds,...
%                                             'test_count',1,...
%                                             'fold_count',5);
%     cosmo_disp(partitions)
%     %|| .test_indices
%     %||   { [ 2    [ 4    [ 2    [ 5    [ 1
%     %||       6 ]    8 ]    7 ]    8 ]    7 ] }
%     %|| .train_indices
%     %||   { [ 1    [ 1    [ 1    [ 1    [ 3
%     %||       3      3      3      2      4
%     %||       5      5      5      4      5
%     %||       7      6      6      6      6
%     %||       8      7      8      7      8
%     %||       9 ]    9 ]    9 ]    9 ]    9 ] }
%     %
%     % As above, but now with 2 targets in each chunk used for testing
%     partitions=cosmo_independent_samples_partitioner(ds,...
%                                             'test_count',2,...
%                                             'fold_count',5);
%     cosmo_disp(partitions)
%     %|| .test_indices
%     %||   { [ 1    [ 4    [ 2    [ 1    [ 1
%     %||       2      5      3      5      5
%     %||       6      7      6      6      6
%     %||       7 ]    8 ]    7 ]    8 ]    7 ] }
%     %|| .train_indices
%     %||   { [ 3    [ 1    [ 1    [ 2    [ 3
%     %||       5      3      5      4      4
%     %||       8      6      8      7      8
%     %||       9 ]    9 ]    9 ]    9 ]    9 ] }
%     %
%     % Now use 30% of the targets in each chunk for testing,
%     % and return 20 chunks.
%     partitions=cosmo_independent_samples_partitioner(ds,...
%                                             'test_ratio',0.3,...
%                                             'fold_count',20);
%     cosmo_disp(partitions)
%     %|| .test_indices
%     %||   { [ 3    [ 4    [ 1   ... [ 5    [ 1    [ 4
%     %||       6 ]    7 ]    8 ]       6 ]    9 ]    7 ]   }@1x20
%     %|| .train_indices
%     %||   { [ 1    [ 2    [ 2   ... [ 1    [ 3    [ 1
%     %||       2      3      4         2      4      2
%     %||       4      5      5         3      5      5
%     %||       7      6      6         7      6      6
%     %||       8      8      7         8      7      8
%     %||       9 ]    9 ]    9 ]       9 ]    8 ]    9 ]   }@1x20
%
% Notes:
% - Unless the number of targets and chunks is very small, the number of
%   partitions returned by this function (=c) is less than the total number
%   of possible partitions. In these cases, a random subset of possible
%   partitions is chosen, with the constraint that no combination of train
%   and test indices is repeated in partitions. No attempt is made to
%   balance the number of times each sample is used for training and/or
%   testing.
% - This function behaves, by default, pseudo-randomly and
%   deterministically; different calls to this function, with the same
%   inputs, result in the same output. To get different outputs for
%   different calls, set the 'seed' option to 0.
%
% See also: cosmo_nfold_partitions, cosmo_nchoosek_partitioner
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % process input
    defaults=struct();
    defaults.max_fold_count=10000;
    defaults.seed=1;

    opt=cosmo_structjoin(defaults,varargin);
    check_input(ds,opt);

    % see which classes there are
    [class_idx,classes]=cosmo_index_unique(ds.sa.targets);
    class_counts=cellfun(@numel,class_idx);

    % see how many possible unique folds there are
    test_count=get_test_count(class_counts,classes,opt);
    train_count=min(class_counts)-test_count;

    test_combi_count=get_unique_fold_count(class_counts,...
                                                test_count);
    train_combi_count=get_unique_fold_count(class_counts-test_count,...
                                                train_count);

    unique_fold_count=test_combi_count*train_combi_count;

    fold_count=get_fold_count(unique_fold_count,opt);

    % Use case 1: single-subject analysis with single trial MEEG data,
    % hundreds of trials; require crossvalidation scheme with 10 or so
    % folds.
    % The total number of possible folds is 'large', generating all
    % possible folds would require too much memory. Instead we generate
    % folds randomly. Since it is almost always the case that there are
    % some duplicates, these have to be removed. We keep on generating new
    % random folds - and remove duplicates - until we have generated
    % the target count, opt.fold_count.
    %
    % Use case 2: between-subject analysis, trying to discriminate between
    % participants groups (such as patients versus healthy controls).
    % In this case, use a crossvalidation scheme with
    % take-one-participant-per-group-for-testing (i.e. test_count=1), and
    % the total number of folds may not be so large. For example, with 2
    % groups, N=20 in each group, there are F=N*(N-1)/2=190 possible folds.
    % If the target fold count is near this number F, then randomly
    % generating folds until enough folds are generated will take a long
    % time, because many folds will be duplicates of existing ones. In such
    % a scenerio it is more efficient to generate all possible folds first,
    % then select the required number of folds randomly

    fold_enumerate_ratio=.1;

    if fold_count>fold_enumerate_ratio*unique_fold_count;
        func=@enumerated_partitions;
    else
        func=@sampled_partitions;
    end

    if isfield(opt,'seed')
        seed=opt.seed;
    else
        seed=0;
    end

    partitions=func(class_idx,test_count,fold_count,seed);

function fold_count=get_fold_count(unique_fold_count,opt)
    if ~isfield(opt,'fold_count')
        error(['the option ''fold_count'', indicating how many '...
                'cross-validation folds this function should '...
                'generate, is required. It should have a value '...
                'between 1 and %d.\n'...
                'If in doubt, a value between 10 '...
                'and 1000 may be quite adequate for most use cases; '...
                'with the lower value more appropriate for cases of '...
                'within-subject analysis with many trials in '...
                'different conditions of interest (e.g. different '...
                'stimuli, or seen versus unseen stimulus), and the '...
                'upper value more appropriate for classification ' ...
                'of participants in different groups (such as '...
                'patient versus control).'],...
                min(unique_fold_count,opt.max_fold_count));
    end


    fold_count=opt.fold_count;

    if fold_count>opt.max_fold_count
        error(['The number of requested folds, fold_count=%d, '...
                'exceeds the safety limit max_fold_count=%d. '...
                'You can either reduce fold_count, or '...
                'increase max_fold_count. In the latter case, note '...
                'that higher values of max_fold_count may result in '...
                'significant processor and memory usage; for very '...
                'large values, it may result in the computer becoming '...
                'unresponsive or crashing'],...
                fold_count,opt.max_fold_count);
    end

    if fold_count>unique_fold_count
        error(['Cannot generate fold_count=%d folds as there are only '...
                '%d possible folds'],...
                fold_count,unique_fold_count);
    end



function count=get_unique_fold_count(test_class_counts,test_count)
    % see how often each class occurs
    class_counts=arrayfun(@(c)nchoosek_lower_limit(c,test_count),...
                                    test_class_counts);
    count=prod(class_counts);

function c=nchoosek_lower_limit(n,k)
    % for many combinations return a lower limit of nchoosek. This avoids a
    % warning by nchoosek if n and k are large, and still properly
    % deals with cases of small n and k.
    if n-k>10 && k>10
        % it holds that nchoosek(n,k)<1e5 if n-k>10 and k>10
        c=1e5;
    else
        c=nchoosek(n,k);
    end


function test_count=get_test_count(class_counts,classes,opt)
    % get number of samples in each class for testing.

    [min_class_count,min_idx]=min(class_counts);

    if isfield(opt,'test_count')
        test_count=opt.test_count;
    else
        assert(isfield(opt,'test_ratio'))
        test_ratio=opt.test_ratio;
        test_count=round(test_ratio*min_class_count);
    end

    if test_count<1 || test_count>=min_class_count
            error(['here are not enough '...
                    'samples in class %d to have at least %d '...
                    'samples in the train and test set'],...
                    classes(min_idx),test_count);
    end

function partitions=sampled_partitions(class_idx,test_count,...
                                                fold_count,seed)


    class_counts=cellfun(@numel,class_idx);
    safety_max_repeats_limit=100;

    folds_cell=cell(safety_max_repeats_limit,1);

    iter_seeds=ceil(cosmo_rand(1,safety_max_repeats_limit,...
                                                'seed',seed)*1e8);
    has_enough_folds=false;
    for i_gen=1:safety_max_repeats_limit
        iter_seed=iter_seeds(i_gen);
        folds_cell{i_gen}=generate_random_folds(fold_count,...
                                        class_counts,test_count,iter_seed);
        folds_so_far=cat(3,folds_cell{1:i_gen});
        folds_no_dupl=remove_duplicate_fold_indices(folds_so_far);
        n_folds=size(folds_no_dupl,3);
        has_enough_folds=n_folds>=fold_count;

        if has_enough_folds
            break;
        end
    end

    if ~has_enough_folds
        error(['Unable to generate %d folds. This may be a bug. '...
                'Consider contacting the CoSMoMVPA developers'],...
                nfolds);
    end

    partitions=fold_indices2partitions(folds_no_dupl,class_idx);


function fold_indices=generate_random_folds(fold_count,...
                                        class_counts,test_count,seed)
    nclasses=numel(class_counts);
    min_class_count=min(class_counts);
    train_count=min_class_count-test_count;

    % do just a single call to cosmo_rand, so that different calls to this
    % function with different seeds will almost certainly result in
    % different folds
    rand_arr=cosmo_rand(nclasses,max(class_counts),fold_count,'seed',seed);

    % allocate space for output
    fold_indices=cell(nclasses,2,fold_count);


    for i_fold=1:fold_count
        for i_class=1:nclasses
            r=rand_arr(i_class,1:class_counts(i_class),i_fold);
            [unused,idx]=sort(r);
            te_idx=idx(1:test_count);
            tr_idx=idx(test_count+(1:train_count));

            fold_indices{i_class,1,i_fold}=te_idx;
            fold_indices{i_class,2,i_fold}=tr_idx;
        end
    end





function fold_indices=remove_duplicate_fold_indices(fold_indices)
    [nclasses,two,nfolds]=size(fold_indices);
    assert(two==2);

    for test_train_idx=1:2
        % assuming training and test sets same size, everywhere
        counts=cellfun(@numel,fold_indices(:,test_train_idx,:));
        assert(all(counts(1)==counts(:)));
    end

    test_count=numel(fold_indices{1,1,1});
    train_count=numel(fold_indices{1,2,1});
    total_count=train_count+test_count;

    max_index=max(cellfun(@max,fold_indices(:)));

    fold_mat=zeros(nfolds,total_count*nclasses);
    first_row=0;
    for f_i=1:nfolds
        for c_i=1:nclasses
            te=fold_indices{c_i,1,f_i};
            fold_mat(f_i,first_row+(1:test_count))=te;
            first_row=first_row+test_count;

            tr=fold_indices{c_i,2,f_i};
            % discriminate test and train indices by ensuring:
            % test_indices  <= max_index
            % train_indices >  max_index;
            tr_offset=tr+max_index;
            fold_mat(f_i,first_row+(1:train_count))=tr_offset;
            first_row=first_row+train_count;
        end
    end

    % find and remove duplicates
    [s,i]=sortrows(fold_mat);

    is_dupl=false(nfolds,1);
    for row=2:nfolds
        is_dupl(i(row))=isequal(s(row-1,:),s(row,:));
    end

    fold_indices=fold_indices(:,:,~is_dupl);


function partitions=enumerated_partitions(class_idx,test_count,...
                                                fold_count,seed)
    nclasses=numel(class_idx);
    class_counts=cellfun(@numel,class_idx);

    train_count=min(class_counts)-test_count;

    test_idx=cell(1,nclasses);
    rem_train_idx=cell(1,nclasses);

    for c_i=1:nclasses
        test_idx{c_i}=nchoosek(1:class_counts(c_i),test_count);
        rem_train_idx{c_i}=nchoosek(1:class_counts(c_i)-test_count,...
                                                train_count);
    end

    % take all combinations, with first (nclasses*test_count) columns
    % for the test index positions, and the remaining
    % (nclasses*train_count) columns for indices of remaining test sets
    % Thus, possible test indices for class c are in all_idx{c,1},
    % and indices for remaining train indices are in all_idx{c,2}.

    all_idx=[test_idx; rem_train_idx];

    ref_all_idx=cellfun(@(x)1:size(x,1),all_idx,'UniformOutput',false);
    combis=cosmo_cartprod(ref_all_idx);

    nfolds=size(combis,1);

    % allocate space for fold indices.
    %
    %   fold_indices{c,i,f}=[x1,...xN]
    %
    % for fold f means that the x1-th, ... xN-th sample
    % in class c are used for testing (i=1) or training (i=2).
    %
    fold_indices=cell(nclasses,2,nfolds); % test and train

    for f_i=1:nfolds
        for c_i=1:nclasses
            % use linear indexing in all_idx
            te_pos=c_i*2-1;
            rem_tr_pos=te_pos+1;

            ref_te=combis(f_i,te_pos);
            ref_rem_tr=combis(f_i,rem_tr_pos);

            te=all_idx{te_pos}(ref_te,:);

            tr_rem=setdiff(1:class_counts(c_i),te);
            tr_rem_ref=all_idx{rem_tr_pos}(ref_rem_tr,:);
            tr=tr_rem(tr_rem_ref);

            fold_indices{c_i,1,f_i}=te;
            fold_indices{c_i,2,f_i}=tr;
        end
    end

    if fold_count<nfolds
        rp=cosmo_randperm(nfolds, fold_count, 'seed', seed);
        fold_indices=fold_indices(:,:,rp);
    end

    partitions=fold_indices2partitions(fold_indices,class_idx);



function partitions=fold_indices2partitions(fold_indices,class_idx)
    % For the inputs,
    %
    %   fold_indices{c,i,f}=[x1,...xN]
    %
    % for fold f means that the x1-th, ... xN-th sample
    % in class c are used for testing (i=1) or training (i=2).
    %
    %   class_idx{c_i}=p1,...,pN
    %
    % means that the p1-th,...,pN-th row in .samples are in class c_i.

    partitions=struct();
    [nclasses,two,nfolds]=size(fold_indices);
    assert(two==2);

    keys={'test_indices','train_indices'};
    for k=1:numel(keys)
        key=keys{k};

        all_idx=cell(1,nfolds);
        for f_i=1:nfolds

            fold_idx=cell(1,nclasses);

            for c_i=1:nclasses
                ref=fold_indices{c_i,k,f_i}(:);
                fold_idx{c_i}=class_idx{c_i}(ref);
            end

            all_idx{f_i}=sort(cat(1,fold_idx{:}));
        end

        partitions.(key)=all_idx;
    end


function check_input(ds,opt)
    cosmo_check_dataset(ds);

    raise=true;
    cosmo_isfield(ds,{'sa.targets','sa.chunks'},raise);

    chunks=ds.sa.chunks;
    unq_chunks=unique(chunks);
    if numel(unq_chunks)~=numel(chunks);
        h=histc(chunks,unq_chunks);
        i=find(h>=2,1);
        assert(numel(i)==1);
        error(['.sa.chunks==%d occurs %d times, whereas all values '...
                    'must be unique'],...
                    unq_chunks(i),h(i));
    end


    if isfield(opt,'test_count')
        if isfield(opt,'test_ratio')
            error(['the options ''test_count'' and ''test_ratio'''...
                    'are mutually exclusive']);
        end
    elseif ~isfield(opt,'test_ratio')
            error(['one of the options ''test_count'' and '...
                    '''test_ratio'' is required']);
    end


