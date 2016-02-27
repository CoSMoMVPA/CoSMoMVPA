function partitions = cosmo_nchoosek_partitioner(chunks_or_ds, k, varargin)
% partitions for into nchoosek(n,k) parititions with optional grouping schemas.
%
% partitions=cosmo_nchoosek_partitioner(chunks, k, group_values1, test_group_by1,...)
%
% Input
%  - chunks          Px1 chunk indices for P samples. It can also be a
%                    dataset struct with field .sa.chunks
%  - k               When an integer, k chunks are in each test partition.
%                    When between 0 and 1, this is interpreted as
%                    round(k*nchunks) where nchunks is the number of unique
%                    chunks in chunks.
%                    A special case, mostly aimed at split-half
%                    correlations, is when k=='half'; this sets k to .5,
%                    and if k is even, it treats train_indices and
%                    test_indices as symmetrical, meaning it returns only
%                    half the number of partitions (avoiding duplicates).
%                    If k is odd then train and test indices have
%                    (k+1)/nchunks and (k-1)/nchunks elements,
%                    respectively, or vice versa.
%  - group_values*   } Intended for cross-participant or cross-condition
%  - test_group_by*  } generalizability analyses.
%                      Pairs of these determine a subsequent level group
%                      partition scheme. Each group_values can be
%                      a cell with the labels for a test group, or,
%                      if chunks is a string, the name of a sample
%                      attribute whose values are used as labels.
%                      Each test_group_by indicates which values in
%                      group_values are used as a test value in the
%                      cross-validation scheme (and all other ones are used
%                      as training value). If empty it is set to the unique
%                      values in group_values.
%
% Output:
%  - partitions      A struct with fields:
%     .train_indices } Each of these is an 1xQ cell for Q partitions, where
%     .test_indices  } Q=nchoosek(nchunks,k)). It contains all possible
%                      combinations with k test indices and (nchunks-k)
%                      training indices (except when k=='half', see above).
%                    If group_values* and test_group_by* are specified,
%                    then the number of output partitions is multiplied
%                    by the product of the number of values in
%                    test_group_by*.
%
%
% Examples:
%     % make a simple dataset with 4 chunks, 2 samples each
%     % assume two targets (i.e. conditions, say piano versus guitar)
%     ds=struct();
%     ds.samples=randn(8,99); % 8 samples, 99
%     ds.sa.targets=[1 1 1 1 2 2 2 2]';
%     ds.sa.chunks=2+[1 2 3 4 4 3 2 1]';
%     cosmo_check_dataset(ds); % sanity check
%     %
%     % take-one-chunk out partitioning
%     p=cosmo_nchoosek_partitioner(ds,1);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 2    [ 1    [ 1    [ 1
%     >       3      3      2      2
%     >       4      4      4      3
%     >       5      5      5      6
%     >       6      6      7      7
%     >       7 ]    8 ]    8 ]    8 ] }
%     > .test_indices
%     >   { [ 1    [ 2    [ 3    [ 4
%     >       8 ]    7 ]    6 ]    5 ] }
%     %
%     % take-two chunks out partitioning
%     p=cosmo_nchoosek_partitioner(ds,2);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 3    [ 2    [ 2    [ 1    [ 1    [ 1
%     >       4      4      3      4      3      2
%     >       5      5      6      5      6      7
%     >       6 ]    7 ]    7 ]    8 ]    8 ]    8 ] }
%     > .test_indices
%     >   { [ 1    [ 1    [ 1    [ 2    [ 2    [ 3
%     >       2      3      4      3      4      4
%     >       7      6      5      6      5      5
%     >       8 ]    8 ]    8 ]    7 ]    7 ]    6 ] }
%     %
%     % take-half-of-the-chunks out partitioning
%     % (this effectively gives same chunks as above)
%     p_alt=cosmo_nchoosek_partitioner(ds,.5);
%     isequal(p, p_alt)
%     > true
%     %
%     % do half split (for correlation measure); this leaves out
%     % mirror partitions of train and test indices
%     p=cosmo_nchoosek_partitioner(ds,'half');
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 1    [ 1    [ 1
%     >       2      3      4
%     >       7      6      5
%     >       8 ]    8 ]    8 ] }
%     > .test_indices
%     >   { [ 3    [ 2    [ 2
%     >       4      4      3
%     >       5      5      6
%     >       6 ]    7 ]    7 ] }
%     %
%     % test on samples with chunk=3 only using take-one-fold out
%     p=cosmo_nchoosek_partitioner(ds,1,'chunks',3);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 2
%     >       3
%     >       4
%     >       5
%     >       6
%     >       7 ] }
%     > .test_indices
%     >   { [ 1
%     >       8 ] }
%     % test on samples with chunk=[3 4] only using take-one-fold out;
%     % only samples with chunks=1 or 2 are used for training
%     p=cosmo_nchoosek_partitioner(ds,1,'chunks',{[3 4]});
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 3    [ 3
%     >       4      4
%     >       5      5
%     >       6 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       8 ]    7 ] }
%     % test separately on samples with chunk=3 and samples with chunk=4;
%     % in some folds, samples with chunks=1,2,4 are used for training, in
%     % other folds samples with chunks=1,2,3 are used for training
%     p=cosmo_nchoosek_partitioner(ds,1,'chunks',{[3],[4]});
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 2    [ 1
%     >       3      3
%     >       4      4
%     >       5      5
%     >       6      6
%     >       7 ]    8 ] }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       8 ]    7 ] }
%     >
%
%
%     % make a slightly more complicated dataset: with three chunks,
%     % suppose there are two modalities (e.g. (1) visual and (2)
%     % auditory stimulation) which are stored in an
%     % additional field 'modality'
%     ds=struct();
%     ds.samples=randn(12,99);
%     ds.sa.chunks  =[1 1 1 1 2 2 2 2 3 3 3 3]';
%     ds.sa.targets =[1 2 1 2 1 2 1 2 1 2 1 2]';
%     ds.sa.modality=[1 1 2 2 1 1 2 2 1 1 2 2]';
%     cosmo_check_dataset(ds);
%     %
%     % take-one-chunk out, test on samples with modality=1 (and train
%     % on samples with other modalities, i.e. modality=2)
%     p=cosmo_nchoosek_partitioner(ds,1,'modality',1);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [  7    [  3    [ 3
%     >        8       4      4
%     >       11      11      7
%     >       12 ]    12 ]    8 ] }
%     > .test_indices
%     >   { [ 1    [ 5    [  9
%     >       2 ]    6 ]    10 ] }
%     %
%     % take-one-chunk out, test on samples with modality=2
%     p=cosmo_nchoosek_partitioner(ds,1,'modality',2);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [  5    [  1    [ 1
%     >        6       2      2
%     >        9       9      5
%     >       10 ]    10 ]    6 ] }
%     > .test_indices
%     >   { [ 3    [ 7    [ 11
%     >       4 ]    8 ]    12 ] }
%     % take-one-chunk out, test on samples with modality=1 (and train on
%     % modality=2) and vice verse
%     p=cosmo_nchoosek_partitioner(ds,1,'modality',[]);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [  7    [  3    [ 3    [  5    [  1    [ 1
%     >        8       4      4       6       2      2
%     >       11      11      7       9       9      5
%     >       12 ]    12 ]    8 ]    10 ]    10 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 5    [  9    [ 3    [ 7    [ 11
%     >       2 ]    6 ]    10 ]    4 ]    8 ]    12 ] }
%
%     % between-subject classification: 3 chunks, 2 modalities, 5 subjects
%     ds=struct();
%     ds.samples=randn(60,99);
%     ds.sa.targets=repmat([1 2],1,30)';
%     ds.sa.chunks=repmat([1 1 1 1 2 2 2 2 3 3 3 3],1,5)';
%     ds.sa.modality=repmat([1 1 2 2],1,15)';
%     ds.sa.subject=kron(1:5,ones(1,12))';
%     cosmo_check_dataset(ds);
%     %
%     % test on subject 1, train on other subjects using take-one-chunk out
%     p=cosmo_nchoosek_partitioner(ds,1,'subject',1);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 17         [ 13         [ 13
%     >       18           14           14
%     >       19           15           15
%     >        :            :            :
%     >       58           58           54
%     >       59           59           55
%     >       60 ]@32x1    60 ]@32x1    56 ]@32x1 }
%     > .test_indices
%     >   { [ 1    [ 5    [  9
%     >       2      6      10
%     >       3      7      11
%     >       4 ]    8 ]    12 ] }
%     %
%     % test on each subject after training on each other subject
%     % in each fold, the test data is from one subject and one chunk,
%     % and the train data from all other subjects and all other chunks.
%     % since there are 5 subjects and 3 chunks, there are 15 folds.
%     p=cosmo_nchoosek_partitioner(ds,1,'subject',[]);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 17         [ 13         [ 13        ... [  5         [  1         [  1
%     >       18           14           14               6            2            2
%     >       19           15           15               7            3            3
%     >        :            :            :               :            :            :
%     >       58           58           54              46           46           42
%     >       59           59           55              47           47           43
%     >       60 ]@32x1    60 ]@32x1    56 ]@32x1       48 ]@32x1    48 ]@32x1    44 ]@32x1   }@1x15
%     > .test_indices
%     >   { [ 1    [ 5    [  9   ... [ 49    [ 53    [ 57
%     >       2      6      10         50      54      58
%     >       3      7      11         51      55      59
%     >       4 ]    8 ]    12 ]       52 ]    56 ]    60 ]   }@1x15
%     %
%     % as above, but test on modality=2 (and train on other values for
%     % modality, i.e. modality=1)
%     p=cosmo_nchoosek_partitioner(ds,1,'subject',[],'modality',2);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 17         [ 13         [ 13        ... [  5         [  1         [  1
%     >       18           14           14               6            2            2
%     >       21           21           17               9            9            5
%     >        :            :            :               :            :            :
%     >       54           50           50              42           38           38
%     >       57           57           53              45           45           41
%     >       58 ]@16x1    58 ]@16x1    54 ]@16x1       46 ]@16x1    46 ]@16x1    42 ]@16x1   }@1x15
%     > .test_indices
%     >   { [ 3    [ 7    [ 11   ... [ 51    [ 55    [ 59
%     >       4 ]    8 ]    12 ]       52 ]    56 ]    60 ]   }@1x15
%     %
%     % as above, but test on each modality after training on the other
%     % modality. There are 30 folds (5 subjects, 3 chunks, 2 modalities).
%     p=cosmo_nchoosek_partitioner(ds,1,'subject',[],'modality',[]);
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 19         [ 15         [ 15        ... [  5         [  1         [  1
%     >       20           16           16               6            2            2
%     >       23           23           19               9            9            5
%     >        :            :            :               :            :            :
%     >       56           52           52              42           38           38
%     >       59           59           55              45           45           41
%     >       60 ]@16x1    60 ]@16x1    56 ]@16x1       46 ]@16x1    46 ]@16x1    42 ]@16x1   }@1x30
%     > .test_indices
%     >   { [ 1    [ 5    [  9   ... [ 51    [ 55    [ 59
%     >       2 ]    6 ]    10 ]       52 ]    56 ]    60 ]   }@1x30
%
% Notes:
%    - When k=1 and two input arguments, this function behaves equivalently
%      to cosmo_nfold_partitioner. Thus, in the most simple case
%      (nfold-partitioning), cosmo_nfold_partitioner with k=1 can be used
%      as well as this function.
%    - This function does not consider any .sa.targets (trial condition)
%      or .samples information.
%    - As shown in the examples below, this function can be used for
%      cross-modal and/or cross-participant cross-validation.
%    - For cross-validation it is recommended to balance partitions using
%      cosmo_balance_partitions.
%   - this function can be used for cross-decoding analyses. Doing so may
%     require a re-assignment of .sa.targets, and adding another sample
%     attribute to specify which samples are used for training and testing.
%     For example, consider the following dataset with six unique
%     conditions as specified in the sample attribute field .sa:
%
%       .targets    .chunks     .labels
%       1           1           'vis_dog'
%       2           1           'vis_cat'
%       3           1           'vis_frog'
%       4           1           'aud_dog'
%       5           1           'aud_cat'
%       6           1           'aud_frog'
%       1           2           'vis_dog'
%       2           2           'vis_cat'
%       :           :               :
%       6           8           'aud_frog'
%
%    This dataset has 8 chunks, each with 6 conditions: three for visual
%    stimuli of dogs, cats, and frogs, and three for auditory stimuli for
%    the same animals. The field .labels is not required, but used for a
%    human-readable description of the condition of each sample.
%
%    Suppose that one wants to do cross-decoding to see
%    if discrimination of animals generalizes between the visual and
%    auditory modalities.
%    To do so, the user has to:
%       * change the .targets field, to indicate the anima species,
%       * add another field (here 'modality') indicating which samples are
%         used for the cross-decoding
%
%    In this example, the sample attribute field .sa can be set as follows:
%
%       .targets    .chunks     .labels     .modality
%       1           1           'vis_dog'   1
%       2           1           'vis_cat'   1
%       3           1           'vis_frog'  1
%       1           1           'aud_dog'   2
%       2           1           'aud_cat'   2
%       3           1           'aud_frog'  2
%       1           2           'vis_dog'   1
%       2           2           'vis_cat'   1
%       :           :               :
%       6           8           'aud_frog'  2
%
%    so that:
%     * .modality corresponds to the visual (=1) and auditory (=2)
%       modality.
%     * .targets corresponds to the dog (=1), cat (=2), and frog (=3)
%       species.
%
%    With this re-assignment of .targets, testing on the auditory modality
%    and training on the visual modality with take-one-chunk out
%    cross-validation can be done using:
%
%       test_modality=2; % train on all other modalities (here: only 1)
%       partitions=cosmo_nchoosek_partitioner(ds,1,...
%                                   'modality',test_modality);
%
%    If test_modality is set to empty ([]), then both modalities are used
%    for training and for testing (in separate folds).
%
% See also: cosmo_nfold_partitioner, cosmo_balance_partitions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % if the first input is a dataset, get the chunks from it
    is_ds=isstruct(chunks_or_ds);
    if is_ds
        if isfield(chunks_or_ds,'sa') && isfield(chunks_or_ds.sa,'chunks')
            % it is a dataset
            ds=chunks_or_ds;
            chunks=ds.sa.chunks;
        else
            error('illegal struct input');
        end
    else
        chunks=chunks_or_ds;
    end

    % use helper function defined below
    partitions=nchoosek_partitioner(chunks,k);

    if nargin<3
        return;
    elseif mod(nargin,2)~=0
        error('Need even number of arguments');
    else
        nsamples=numel(chunks);
        for k=1:2:(nargin-2);
            % loop over grouping values
            group_values=varargin{k};
            test_group_by=varargin{k+1};

            % get sample attribute, if input was dataset
            if ischar(group_values)
                if is_ds
                    group_values=ds.sa.(group_values);
                else
                    error('String for group value requires dataset input');
                end
            end

            % check number of values matches
            ngroup_by=numel(group_values);
            if ngroup_by ~= nsamples
                error('group_by has %d values, expected %d', ...
                                ngroup_by, nsamples);
            end

            if isempty(test_group_by)
                test_group_by=num2cell(unique(group_values));
            elseif isnumeric(test_group_by)
                test_group_by={test_group_by};
            end

            % update partitions using helper function below
            partitions=group_by(partitions, group_values, test_group_by);
        end
    end


function partitions=group_by(partitions, group_values, test_group_by)
    % helper function to group partitions
    % the output has N times as many partitions as the input,
    % where N=numel(test_by).

    npartitions=numel(partitions.test_indices);

    assert(iscell(test_group_by));
    % see which values to split on
    ntest_group_by=numel(test_group_by);

    % allocate space for output
    train_indices=cell(1,ntest_group_by);
    test_indices=cell(1,ntest_group_by);

    % run for each unique value in group_by_values
    for m=1:ntest_group_by
        test_by=test_group_by{m};

        % allocate space for this iteration
        train_indices_cell=cell(1,npartitions);
        test_indices_cell=cell(1,npartitions);

        % some filtered partitions may be empty, so keep track of the
        % last position where a value was stored
        pos=0;
        for j=1:npartitions
            % get testing chunk indices
            p_test=partitions.test_indices{j};

            % see which ones match the group_by_value
            msk_test=cosmo_match(group_values(p_test),test_by);

            % keep just those indices
            p_test_masked=p_test(msk_test);

            % the same for training, but different from test_by
            p_train=partitions.train_indices{j};
            msk_train=~cosmo_match(group_values(p_train),test_by);
            p_train_masked=p_train(msk_train);

            if ~isempty(p_test_masked) && ~isempty(p_train_masked)
                % both training and test set are non-empty, so keep result
                pos=pos+1;
                test_indices_cell{pos}=p_test_masked;
                train_indices_cell{pos}=p_train_masked;
            end
        end

        % store the test-indices for m-th group_by_value
        test_indices{m}=test_indices_cell(1:pos);
        train_indices{m}=train_indices_cell(1:pos);
    end

    partitions=struct();

    % concatenate results for training and test indices
    partitions.train_indices=cat(2,train_indices{:});
    partitions.test_indices=cat(2,test_indices{:});





function partitions=nchoosek_partitioner(chunks,k)
% straightfoward partitioner




[unq,unused,chunk_indices]=unique(chunks);
nchunks=numel(unq);

if nchunks<2
    error(['at least two unique values for .sa.chunks are required, '...
                    'found %d.'], nchunks);
end

% deal with special 'half' case
is_symmetric=false;
if ischar(k)
    if strcmp(k,'half')
        k=.5;
        is_symmetric=true;
    else
        error('illegal string k');
    end
end
if isnumeric(k)
    if ~isscalar(k)
        error('k must be a scalar');
    end

    if k ~= round(k)
        k=round(nchunks*k);
    end

    if ~any(k==1:(nchunks-1))
        error('illegal k=%d: test class count should be between 1 and %d', ...
                    k, nchunks-1);
    end
else
    error('illegal parameter for k');
end

% little optimization: if just two chunks, the split is easy
if all(cosmo_match(chunks,[1 2]))
    chunk_msk1=chunks==1;
    chunk1_idxs=find(chunk_msk1);
    chunk2_idxs=find(~chunk_msk1);

    partitions=struct();
    if is_symmetric
        partitions.train_indices={chunk1_idxs};
        partitions.test_indices={chunk2_idxs};
    else
        partitions.train_indices={chunk1_idxs,chunk2_idxs};
        partitions.test_indices={chunk2_idxs,chunk1_idxs};
    end
    return
end

npartitions=nchoosek(nchunks,k);
combis=nchoosek(1:nchunks,k); % make all combinations

if is_symmetric && mod(nchunks,2)==0
    % when nclasses is even, return the first half of the permutations:
    % the current implementation of nchoosek results is that
    % combis(k,:) and combis(npartitions+1-k) are complementary
    % (i.e. together they make up 1:nchunks). In principle this could
    % change in the future leading to wrong results (if Mathworks, in its
    % infinite wisdom, decides to change the implementation of nchoosek),
    % so to be sure we check that the output matches what is expected.
    % The rationale is that this reduces computation time of subsequent
    % analyses by half, in particular for commonly used split half
    % correlations.
    nhalf=npartitions/2;

    check_combis=[combis(1:nhalf,:) combis(npartitions:-1:(nhalf+1),:)];

    % each row, when sorted, should be 1:nchunks
    matches=bsxfun(@eq,sort(check_combis,2),1:nchunks);
    assert(all(matches(:)),'nchoosek behaves weirdly');

    % we're good - just take the second half and update npartitions
    combis=combis(npartitions:-1:(nhalf+1),:);
    npartitions=nhalf;
end

% allocate space for output
train_indices=cell(1,npartitions);
test_indices=cell(1,npartitions);

% make all partitions
for j=1:npartitions
    combi=combis(j,:);
    sample_count=cosmo_match(chunk_indices,combi);
    test_indices{j}=find(sample_count);
    train_indices{j}=find(~sample_count);
end

partitions=struct();
partitions.train_indices=train_indices;
partitions.test_indices=test_indices;
