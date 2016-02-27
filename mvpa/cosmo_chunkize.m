function chunks=cosmo_chunkize(ds,nchunks_out)
% assigns chunks that are as balanced as possible based on targets.
%
% chunks_out=cosmo_chunkize(ds_targets,nchunks_out)
%
% Inputs:
%   ds             A dataset struct with fields:
%    .sa.targets   Px1 targets with class labels for P samples
%    .sa.chunks    Px1 initial chunks for P samples; different values mean
%                  that the corresponding data can be assumed to be
%                  independent
%   nchunks_out    scalar indicating how many different chunks should be
%                  assigned.
%
% Output:
%   chunks_out     Px1 chunks assigned, in the range 1:nchunks. It is
%                  required that N=numel(unique(ds.sa.targets)) is greater
%                  than or equal to nchunks.
%
%
% Example:
%     % ds is an MEEG dataset with 48 samples
%     ds=cosmo_synthetic_dataset('type','timelock','nreps',8);
%     %
%     % with no chunks set, this function gives an error
%     ds.sa=rmfield(ds.sa,'chunks');
%     cosmo_chunkize(ds)
%     > error('dataset has no field .sa.chunks. ...');
%     %
%     % set chunks so that all samples are assumed to be independent
%     ds.sa.chunks=(1:size(ds.samples,1))';
%     %
%     % show initial dataset targets and chunks
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     > [ 1         1
%     >   2         2
%     >   1         3
%     >   :         :
%     >   2        46
%     >   1        47
%     >   2        48 ]@48x2
%     %
%     % Re-assign chunks pseudo-randomly in the range 1:4.
%     % samples (rows) with the same chunk original chunk value
%     % will still have the same chunk value (but the reverse is not
%     % necessarily true)
%     ds.sa.chunks=cosmo_chunkize(ds,4);
%     %
%     % sanity check
%     cosmo_check_dataset(ds);
%     % Show result
%     cosmo_disp([ds.sa.targets ds.sa.chunks])
%     > [ 1         1
%     >   2         1
%     >   1         2
%     >   :         :
%     >   2         3
%     >   1         4
%     >   2         4 ]@48x2
%
% Notes:
%  - This function is indended for MEEG datasets, or other datasets
%    where each trial can be assumed to be 'independant' of other trials.
%  - To indicate independence between all trials in a dataset ds, use:
%      ds.sa.chunks=(1:size(ds.samples,1))';
%    prior to using this function
%  - When this function is used prior to classification using partitioning
%    (with cosmo_nchoosek_partitioner or cosmo_nfold_paritioner),
%    it is recommended to apply cosmo_balance_partitions to
%    that partitioning
%  - Usage for fMRI datasets is not recommended, unless you really know
%    what you are doing. Rather, for fMRI datasets usually the chunks are
%    assigned manually so that each run has a different chunk value.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input(ds);

    [idxs_tc,unq_tc]=cosmo_index_unique([ds.sa.targets ds.sa.chunks]);
    nunq_ct=size(unq_tc,1);

    [c_idxs,c_unq]=cosmo_index_unique(ds.sa.chunks);
    nchunks_in=numel(c_unq);

    [t_unq,unused,t_mapping]=unique(ds.sa.targets);
    nt=numel(t_unq);

    if nunq_ct>nchunks_in*nt
        error(['Balance mismatch: there are %d unique chunks and '...
                '%d unique targets, but the number of unique '...
                'combinations is more than that: %d'],...
                nchunks_in,nt,nunq_ct);
    end

    if nchunks_out>nchunks_in
        error('Cannot make %d chunks, only %d are present',...
                    nchunks_out,nchunks_in);
    end

    % Count for each chunk how often each target appears
    %
    % In the resulting histogram h_in, h_in(k,j)=c means that the k-th chunk
    % contains the j-th target c times
    h_in=zeros(nchunks_in,nt);
    for k=1:nchunks_in
        sample_idxs=c_idxs{k};
        t_idxs=t_mapping(sample_idxs);
        for j=1:numel(t_idxs)
            t_idx=t_idxs(j);
            h_in(k,t_idx)=h_in(k,t_idx)+1;
        end
    end

    % find best way to partition the nchunks_in chunks into
    % nchunks_out sets
    c_out_idxs=find_best_chunkization(h_in,nchunks_out);

    nsamples=size(ds.samples,1);
    chunks=NaN(nsamples,1);
    for j=1:nchunks_out
        sample_idxs=cat(1,c_idxs{c_out_idxs{j}});
        chunks(sample_idxs)=j;
    end
    assert(~any(isnan(chunks)));

function c_out_idxs=find_best_chunkization(h_in,nchunks_out)
    nsamples_per_chunk=sum(h_in,2);
    is_all_independent=all(nsamples_per_chunk==0) || ...
                all(nsamples_per_chunk==1);
    if is_all_independent
        % optimization in case of all independent chunks
        chunkizer=@get_independent_chunkization;
    else
        is_balanced=all(h_in(1)==h_in(:));
        if is_balanced
            % optimization in case of balanced chunks
            chunkizer=@get_balanced_chunkization;
        else
            % use slow function
            chunkizer=@get_good_nondependent_chunkization;
        end
    end
    c_out_idxs=chunkizer(h_in,nchunks_out);


function c_out_idxs=get_independent_chunkization(h_in,nchunks_out)
    assert(all(sum(h_in,2)==1));

    nt=size(h_in,2);
    c_out_idxs=cell(nchunks_out,1);
    chunk_id=0;
    for k=1:nt
        rows=find(h_in(:,k));

        for j=1:numel(rows)
            chunk_id=mod(chunk_id,nchunks_out)+1;
            c_out_idxs{chunk_id}=[c_out_idxs{chunk_id} rows(j)];
        end
    end

function c_out_idxs=get_balanced_chunkization(h_in,nchunks_out)
    assert(all(h_in(1)==h_in(:)));

    [nchunks_in,nt]=size(h_in);
    c_out_idxs=cell(nchunks_out,1);

    for k=1:nchunks_out
        chunk_ids=k:nchunks_out:nchunks_in;
        c_out_idxs{k}=chunk_ids;
    end


function c_out_idxs=get_good_nondependent_chunkization(h_in,nchunks_out)
% this function is used when h_in
%
% it involves trying to find a partiion of the rows in h_in so that
% for each target, the number of samples for each target is approximately
% equal across each partition element. The current algorithm is somewhat
% slow and may also not find the 'best' possible partition.

    [nchunks_in,nt]=size(h_in);

    % keep a histogram of number of targets in each output chunk
    h_out=zeros(nchunks_out,nt);

    % allocate space for output
    c_out_idxs=cell(nchunks_out,1);

    % use a big cost to get a nice histogram for the output
    big_cost=sum(h_in(:));

    % keep track of which chunks have been used
    visited=false(nchunks_in,1);

    % in every iteration, find a new source chunk to add to the target
    % indices. each chunk can have multiple targets.

    % there are many ways to merge different chunks into one. Here a cost
    % function is used that tries to spread samples from different chunks
    % as evenly as possible

    while ~all(visited)
        min_cost=Inf;
        for k=1:nchunks_in
            if visited(k)
                continue;
            end
            for j=1:nchunks_out
                % try to add each chunk, one by one, and use the one that
                % has the lowest cost
                h_out_candidate=h_out;
                h_out_candidate(j,:)=h_out_candidate(j,:)+h_in(k,:);

                % compute variance
                % (builtin 'var' function is much slower)
                mu=sum(h_out_candidate,1)/nchunks_out;
                cost=max(bsxfun(@minus,mu,h_out_candidate).^2)/...
                                            (big_cost*nchunks_out);

                % avoid empty rows or columns in h_in
                mx=max(h_out_candidate,[],2);
                mn=min(h_out_candidate,[],2);
                delta=max(mx)-min(mx)+max(mn)-min(mn);

                cost=cost+delta*big_cost;

                if cost<=min_cost
                    best_k=k;
                    best_j=j;
                    min_cost=cost;
                end
                if cost==0
                    break;
                end
            end
            if cost==0
                break;
            end
        end

        c_out_idxs{best_j}=[c_out_idxs{best_j} best_k];
        h_out(best_j,:)=h_out(best_j,:)+h_in(best_k,:);
        visited(best_k)=true;
    end

function check_input(ds)
    cosmo_check_dataset(ds);

    if ~cosmo_isfield(ds,'sa.chunks')
        error(['dataset has no field .sa.chunks. The chunks are '...
               'required for this function; they should indicate (in)'...
               '-dependence between trials, so that samples with '...
               'different chunk values can be assumed independent.\n'...
               'If you do not know how to set the .sa.chunks, consider '...
               'the following:\n'...
               '- for an fmri dataset, each samples'' '...
               '  chunk can be set to its run number\n'...
               '- for an meeg dataset, if each trial can be assumed '...
               'to be independent, the chunks can be set to (1:N),'...
               'where N is the number of samples'...
               '(i.e. N=size(ds.samples,1) for a dataset struct ds']);
    end

    if ~cosmo_isfield(ds,'sa.targets')
        error(['dataset has not fields .sa.targets; this is required '...
                'to balance it. Normally, .sa.targets should indicate '...
                'the condition of interest, so that samples with '...
                'different target values are in different conditions. '...
                'If all samples are in the same condition, then '...
                '.sa.targets can be a column vector with ones']);
    end


