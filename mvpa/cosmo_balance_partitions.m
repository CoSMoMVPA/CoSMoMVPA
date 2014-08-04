function bal_partitions=cosmo_balance_partitions(partitions, targets, nsets)
% balances a partition so that each target occurs equally often in each
% chunk
%
% bal_partitions=cosmo_balance_partitions(partitions, targets, nsets)
%
% Inputs:
%   partitions        struct with fields:
%     .train_indices  } Each is a Nx1 cell (for N chunks) containing the
%     .test_indics    } feature indices for each chunk
%   targets           Px1 vector, or dataset struct with field .sa.targets.
%   nsets             Number of balanced sets (default: 1)
%
% Ouput:
%   bal_partitions    similar struct as input partitions, except that
%                     - each field is a (N*nsets)x1 cell
%                     - each unique target is represented equally often
%
% Example:
%  % ds is a dataset with chunks and targets
%  partitions=cosmo_nchoosek_partitioner(ds, 1); % take-1-fold-out
%  partitions=cosmo_balance_partitions(partitions, ds);
%
% Notes:
% - this function is intended for datasets where the number of
%   samples across targets is not equally distributed. A typical
%   application is MEEG datasets.
% - Using this function means that chance accuracy is equal to the inverse
%   of the number of unique targets.
%
% See also: cosmo_nchoosek_partitioner, cosmo_nfold_partitioner
%
% NNO Dec 2013

if nargin<3, nsets=1; end

if isstruct(targets) && isfield(targets,'sa') && ...
                isfield(targets.sa,'targets')
    targets=targets.sa.targets;
end


npar=numel(partitions.train_indices);

all_unq_targets=unique(targets);

% allocate space for output
bal_partitions=struct();

fns={'train_indices','test_indices'};

% balance train and test indices seperately
for m=1:numel(fns)
    fn=fns{m};
    pos=0;

    par=partitions.(fn); % train_indices or test_indices


    % allocate space for output
    bal_par=cell(nsets*npar,1);
    for k=1:nsets
        for j=1:npar
            pos=pos+1;

            parj=par{j};
            parj_targ=targets(parj,:);

            % ensure that the set of targets in this chunk is the
            % same as the set of targets in the input (not a subset)
            unq_targ=unique(parj_targ);
            if ~isequal(unq_targ, all_unq_targets)
                delta=setxor(unq_targ,all_unq_targets);
                error('target mismatch in .%s #%d, partition %d: %d',...
                            fn, k, j, delta(1));
            end

            % see how often each target is present in this chunk
            h=histc(parj_targ, unq_targ);

            % for balance take the minimal count
            mn=min(h);

            % number of unique targets
            nunq=numel(unq_targ);

            % allocate space for indices of this chunk
            balparj=zeros(nunq*mn,1);
            for u=1:nunq
                % find indices for u-th target
                unqidxs=find(parj_targ==unq_targ(u));

                % make random permutation
                rp=randperm(numel(unqidxs));

                % space for output
                pidxs=(u-1)*mn+(1:mn);

                % select 'mn' indices randomly
                balparj(pidxs)=parj(unqidxs(rp(1:mn)));
            end

            bal_par{pos}=balparj;
        end
    end
    bal_partitions.(fn)=bal_par;
end
