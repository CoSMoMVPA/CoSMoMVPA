function [randomized_targets,permutation]=cosmo_randomize_targets(ds,varargin)
% provides randomized target labels
%
% randomized_targets=cosmo_randmize_targets(ds[,'seed',seed)
%
% Inputs:
%   ds                    dataset struct with fields .sa.targets and
%                         .sa.chunks
%   'seed', seed          (optional) if provided, use this seed value for
%                         pseudo-random number generation
%
%
% Outputs:
%   randomized_targets    P x 1 with randomized targets
%                         If ds defines a repeated-measures design (which
%                         requires that each chunk has the same set of
%                         unique targets), then targets are randomized
%                         separately for each chunk.
%                         Otherwise (when each chunk is associated with
%                         exactly one sample, i.e. all samples are
%                         independent), the targets are randomized
%                         without considering the chunk values.
%   permutation           P x 1 with indices of permutation. It holds that
%                         randomized_targets == ds.sa.targets(permutation).
%
% Example:
%     % generate tiny dataset with 15 chunks, each with two targets
%     ds=cosmo_synthetic_dataset('nchunks',15);
%     % show number of samples with targets 1 or 2
%     histc(ds.sa.targets',1:2)
%     > [15 15]
%     % generate randomized targets
%     rand_targets=cosmo_randomize_targets(ds);
%     % the number of samples with targets 1 or 2 is the same ...
%     histc(rand_targets',1:2)
%     > [15 15]
%     % ... but the targets are re-ordered
%     all(ds.sa.targets==rand_targets)
%     > false
%     %
%     % when using the 'seed' option, the output is deterministic
%     % (multiple calls to this function always give the same output)
%     rand_targets_deterministic=cosmo_randomize_targets(ds,'seed',314);
%     rand_targets_deterministic'
%     > [ 2 1 1 2 2 1 2 1 2 1 2 1 1 2 2 1 1 2 2 1 1 2 2 1 2 1 2 1 2 1 ]
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    opt=cosmo_structjoin(varargin);

    [targets,chunks]=get_targets_and_chunks(ds);
    nsamples=numel(targets);

    [nunq_targets, unq_targets, target_idxs]=get_unique(targets);
    [nunq_chunks, unq_chunks]=get_unique(chunks);

    if nunq_chunks==nsamples;
        % between-subject design
        rps=randperms_with_size(nsamples,opt);
        permutation=rps{1};
    else
        % within-subject design
        chunk_partition=cosmo_index_unique(chunks);

        % count number of samples in each chunk, and ensure that no target
        % is missing
        nchunks=numel(chunk_partition);
        samples_per_chunk=zeros(1,nchunks);
        for k=1:nchunks
            sample_idxs=chunk_partition{k};
            h=histc(target_idxs(sample_idxs),1:nunq_targets);
            if any(h==0)
                i=find(h==0,1);
                error(['.sa.chunks and .sa.targets suggest a repeated '...
                        'measure design, but chunk %d has missing '...
                        'target %d'],...
                        unq_chunks(k), unq_targets(i));
            end

            samples_per_chunk(k)=numel(sample_idxs);
        end

        % do permutation in each chunk separately
        rps=randperms_with_size(samples_per_chunk,opt);
        permutation=zeros(nsamples,1);
        for k=1:nchunks
            rp=rps{k};
            sample_idxs=chunk_partition{k};
            permutation(sample_idxs)=sample_idxs(rp);
        end
    end

    randomized_targets=targets(permutation);

function rps=randperms_with_size(sizes,opt)
    % helper function
    % Input: sizes is 1xN vector
    % Output: rps is 1xN cell; rps{k} is a random permutation of 1:sizes(k)
    %

    cum_size=sum(sizes);

    % single call to cosmo_rand, because this call is computationally
    % expensive
    if isfield(opt,'seed')
        r=cosmo_rand(1,cum_size,'seed',opt.seed);
    else
        r=cosmo_rand(1,cum_size);
    end

    n=numel(sizes);
    rps=cell(1,n);
    first_pos=1;
    for k=1:n
        last_pos=first_pos+sizes(k)-1;

        % get sizes(k) random values
        r_part=r(first_pos:last_pos);

        % get sorting indices to get random permutation of 1:sizes(k)
        [unused,rps{k}]=sort(r_part);

        % for next iteration
        first_pos=last_pos+1;
    end


function [n, unq, idxs]=get_unique(xs)
    [unq, unused, idxs]=unique(xs);
    n=numel(unq);



function [targets,chunks]=get_targets_and_chunks(ds)
    if ~isfield(ds,'sa') || ...
             ~isfield(ds.sa,'chunks') || ~isfield(ds.sa,'targets')
        error('dataset must have .sa.chunks and .sa.targets');
    end
    targets=ds.sa.targets;
    chunks=ds.sa.chunks;


