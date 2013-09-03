function d=cosmo_splithalf_correlation_measure(ds, args)
if nargin<2
    args=struct();
end
if ~isfield(args,'opt') args.opt = struct(); end

if ~isfield(args,'partitions') 
    unq=unique(ds.sa.chunks);
    if numel(unq)==2
        partitions=struct();
        partitions.train_indices={find(ds.sa.chunks==unq(1))};
        partitions.test_indices={find(ds.sa.chunks==unq(2))};
    else
        error('Partitions not specified, and did not found two unique chunks');
    end
end

% TODO: support any number of partitions
if numel(partitions.train_indices)~=1 || ...
        numel(partitions.test_indices)~=1 || ...
        numel(partitions.train_indices{1})~=numel(partitions.test_indices{1})
    error('Need a single partitioning with equal number of values');
end

half1_idxs=partitions.train_indices{1};
half2_idxs=partitions.test_indices{1};
nclasses=numel(half1_idxs);

half1=cosmo_dataset_slice_samples(ds, half1_idxs);
half2=cosmo_dataset_slice_samples(ds, half2_idxs);

half1_targets=half1.sa.targets;
half2_targets=half2.sa.targets;

% TODO: allow arbitrary order
if ~isequal(half1_targets, half2_targets)
    error('non-matching targets')
end

if ~isfield(args, 'weighting')
    args.weighting=eye(nclasses)-1/nclasses;
end

w=args.weighting;

c=corr(half1.samples', half2.samples');
ct=atanh(c);
ctw=ct .* w;

d=mean(ctw(:));





