function partitions = cosmo_nchoosek_partitioner(chunks_or_ds, k, varargin)
% partitiones generally for choose(n,k) with optional group schemes.
%
% partitions=cosmo_nchoosek_partitioner(chunks, k, group_values1, test_group_by1,...)
%
% Input
%  - chunks          Px1 chunk indices for P samples. It can also be a
%                    dataset with field .sa.chunks
%  - k               When an integer, k chunks are in each test partition.
%                    When between 0 and 1, this is interpreted as
%                    round(k*nchunks) where nchunks is the number of unique
%                    chunks in chunks. 
%                    A special case, mostly aimed at split-half 
%                    correlations, is when k=='half'; this sets k to .5,
%                    and if k is even, it treats train_indices and 
%                    test_indices as symmetrical, meaning it returns only 
%                    half the number of partitions (avoiding duplicates). 
%                    (If k is odd then train and test indices have 
%                    (k+1)/nchunks and (k-1)/nchunks elements, 
%                    respectively, or vice versa).
%  - group_values*   } Pairs of these determine a subsequent level group 
%  - test_group_by*  } partition scheme. Each group_values can be
%                      a Px1 vector with the labels for a test group, or,
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
% Notes:
%  - when k=1 and two input arguments, this function behaves equivalently 
%    to cosmo_nfold_partitioner.
%  - as shown in the examples below, this function can be used for
%    cross-modal and/or cross-participant cross-validation.
%  - for cross-validation it is recommended to balance partitions using 
%    cosmo_balance_partitions
%
% See also: cosmo_balance_partitions 
%
% Examples:
%   cosmo_nchoosek_partitioner([1 2 1 2 2],.5)
%     >  train_indices: {[2 4 5]  [1 3]}
%     >  test_indices: {[1 3]  [2 4 5]}
%
%   cosmo_nchoosek_partitioner(1:4,.5)
%     >     train_indices: {[3 4]  [2 4]  [2 3]  [1 4]  [1 3]  [1 2]}
%     >     test_indices: {[1 2]  [1 3]  [1 4]  [2 3]  [2 4]  [3 4]}
%
%   cosmo_nchoosek_partitioner(1:4,'half')
%     >     train_indices: {[3 4]  [2 4]  [2 3]}
%     >     test_indices: {[1 2]  [1 3]  [1 4]}
%   
%   % when using a dataset with sample attributes 'chunks','subject_id',
%   % 'modality', and 'targets'; modality assumed to have values in [1,2].
%   cosmo_nchoosek_partitioner(ds,1); 
%     > % standard nfold crossvalidation
%
%   cosmo_nchoosek_partitioner(ds,1,'subject',[])
%     > % cross-participant nfold cross validation over all subjects
%
%   cosmo_nchoosek_partitioner(ds,1,'subject', [3,5,7])
%     > % cross-participant nfold crossvalidation, tests on subject 3,5,7;
%       % in each fold training is done on all subject except one of 3,5,7.
%
%   cosmo_nchoosek_partitioner(ds,1,'modality',2)
%     > % nfold cross validation with training on samples with modality==2
%       % and testing on samples in the other modality
%
%   cosmo_nchoosek_partitioner(ds,1,'modality',[])  
%     > % full cross-modal nfold cross validation
%
%   cosmo_nchoosek_partitioner(ds,1,'modality',1,'subject,[])
%     > % full cross-subject nfold cross validation with testing on
%         samples with modality==1 and training on the other modality
%
%   cosmo_nchoosek_partitioner(ds,1,'modality',[],'subject,[])
%     > % full cross-subject cross-modal nfold cross validation
%
% See also: cosmo_nfold_partitioner, cosmo_balance_partitions
%
% NNO Sep 2013

    % if the first input is a dataset, get the chunks from it
    is_ds=isstruct(chunks_or_ds);
    if is_ds
        if isfield(chunks_or_ds,'sa') && isfield(chunks_or_ds.sa,'chunks')
            % it is a dataset
            ds=chunks_or_ds;
            chunks=ds.sa.chunks;
        else
            error('illegal struct input')
        end
    else
        chunks=chunks_or_ds;
        ds=[];
    end

    % use helper function defined below
    partitions=nchoosek_partitioner(chunks,k);
    
    if nargin<3
        return;
    elseif nargin==3
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
                test_group_by=unique(group_values);
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

    % see which values to split on
    ntest_group_by=numel(test_group_by);

    % allocate space for output
    train_indices=cell(1,ntest_group_by);
    test_indices=cell(1,ntest_group_by);

    % run for each unique value in group_by_values
    for m=1:ntest_group_by
        test_by=test_group_by(m);

        % allocate space for this iteration
        train_indices_cell=cell(1,npartitions);
        test_indices_cell=cell(1,npartitions);

        % some filtered partitions may be empty
        % so keep track of the last position where a value was stored
        pos=0;
        for j=1:npartitions
            % get testing chunk indices
            p_test=partitions.test_indices{j};

            % see which ones match the group_by_value
            msk_test=group_values(p_test)==test_by;

            % keep just those indices
            p_test_masked=p_test(msk_test);

            % the same for training 
            p_train=partitions.train_indices{j};
            msk_train=group_values(p_train)~=test_by; % must be different
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

% little optimization: if just two chunks, the split is easy
if all(sum(bsxfun(@eq,chunks(:),1:2),2))
    partitions=cosmo_oddeven_partitioner(chunks);
    return
end
    

[unq,unused,chunk_indices]=unique(chunks);
nclasses=numel(unq);

% deal with special 'half' case
is_symmetric=false;
if ischar(k)
    if strcmp(k,'half')
        k=.5;
        is_symmetric=true;
    else
        error('illegal string k')
    end
end

if k ~= round(k)
    k=round(nclasses*k);
end

if ~any(k==1:(nclasses-1))
    error('illegal k=%d: test class count should be between 1 and %d', ...
                k, nclasses-1);
end

npartitions=nchoosek(nclasses,k);
combis=nchoosek(1:nclasses,k); % make all combinations

if is_symmetric && mod(nclasses,2)==0
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
    
    %check_combis=[combis(1:nhalf,:) combis(npartitions:-1:(nhalf+1),:)];
    
    % each row, when sorted, should be 1:nchunks
    %matches=bsxfun(@eq,sort(check_combis,2),1:nclasses);
    %if ~all(matches(:))
    %    error('Unexpected result from nchoosek');
    %end
    
    % we're good - just take the first half and update npartitions
    combis=combis(1:nhalf,:);
    npartitions=nhalf;
end

% allocate space for output
train_indices=cell(1,npartitions);
test_indices=cell(1,npartitions);

% fancy helper function. Given a list of class indices in the range 
% 1:nclasses, it returns postive values where the class indices match 
% chunks.
%
% The following function is equivalent (assuming chunk_indices is given):
%   function any_matching_mat_column=alt(idx, chunk_indices)
%       nidx=numel(idx);
%       nchunk_indices=numel(chunk_indices);
%       idx_mat=repmat(idx',1,nchunk_indices);
%       chunk_indices_mat=repmat(chunk_indices',nidx,1);
%       matching_mat=idx_mat==chunk_indices_mat;
%       any_matching_mat_column=sum(matching_mat,1);
chunk_idx2count=@(idx) sum(bsxfun(@eq,idx',chunk_indices'),1);

% make all partitions
for j=1:npartitions
    combi=combis(j,:);
    sample_count=chunk_idx2count(combi);
    test_indices{j}=find(sample_count);
    train_indices{j}=find(~sample_count);
end

partitions=struct();
partitions.train_indices=train_indices;
partitions.test_indices=test_indices;
