function bpartitions=cosmo_balance_partitions(partitions, targets, varargin)
% balances a partition so that each target occurs equally often in each
% training chunk
%
% bpartitions=cosmo_balance_partitions(partitions, targets, nsets)
%
% Inputs:
%   partitions        struct with fields:
%     .train_indices  } Each is a 1xN cell (for N chunks) containing the
%     .test_indices   } sample indices for each partition
%   targets           Px1 vector, or dataset struct with field .sa.targets.
%   'nsets',nsets     Number of balanced sets (default: 1). The output will
%                     have nsets as many partitions as the input set.
%   'nmin',nmin       Ensure that each target occurs at least
%                     nmin times in each training set (and some may
%                     be repeated more often than than).
%
% Ouput:
%   bpartitions    similar struct as input partitions, except that
%                  - each field is a 1x(N*nsets) cell
%                  - each unique target is represented about equally often
%                  - each target in each training chunk occurs equally
%                    often
%
% Examples:
%     % generate a simple dataset with unbalanced partitions
%     ds=struct();
%     ds.samples=zeros(9,2);
%     ds.sa.targets=[1 1 2 2 2 3 3 3 3]';
%     ds.sa.chunks=[1 2 2 1 1 1 2 2 2]';
%     p=cosmo_nfold_partitioner(ds);
%     %
%     % show original (unbalanced) partitioning
%     cosmo_disp(p);
%     > .train_indices
%     >   { [ 2    [ 1
%     >       3      4
%     >       7      5
%     >       8      6 ]
%     >       9 ]        }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       4      3
%     >       5      7
%     >       6 ]    8
%     >              9 ] }
%     %
%     % make standard balancing (nsets=1); some targets are not used
%     q=cosmo_balance_partitions(p,ds);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 1
%     >       3      4
%     >       7 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 2
%     >       4      3
%     >       5      7
%     >       6 ]    8
%     >              9 ] }
%     %
%     % make balancing where each target in each training set is used at
%     % least once
%     q=cosmo_balance_partitions(p,ds,'nmin',1);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 8    [ 9    [ 1    [ 5
%     >       3      2      2      4      1
%     >       7 ]    3 ]    3 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 1    [ 1    [ 2    [ 2
%     >       4      4      4      3      3
%     >       5      5      5      7      7
%     >       6 ]    6 ]    6 ]    8      8
%     >                            9 ]    9 ] }
%     %
%     % triple the number of partitions and sample from training indices
%     q=cosmo_balance_partitions(p,ds,'nrep',3);
%     cosmo_disp(q);
%     > .train_indices
%     >   { [ 2    [ 8    [ 9    [ 1    [ 5    [ 4
%     >       3      2      2      4      1      1
%     >       7 ]    3 ]    3 ]    6 ]    6 ]    6 ] }
%     > .test_indices
%     >   { [ 1    [ 1    [ 1    [ 2    [ 2    [ 2
%     >       4      4      4      3      3      3
%     >       5      5      5      7      7      7
%     >       6 ]    6 ]    6 ]    8      8      8
%     >                            9 ]    9 ]    9 ] }
%
% Notes:
% - this function is intended for datasets where the number of
%   samples across targets is not equally distributed. A typical
%   application is MEEG datasets.
% - Using this function means that chance accuracy is equal to the inverse
%   of the number of unique targets.
% - This function balances the training indices only, not the test_indices.
%   Test_indices may be repeated
%
% See also: cosmo_nchoosek_partitioner, cosmo_nfold_partitioner
%
% NNO Dec 2013

defaults=struct();
defaults.nrep=1;
params=cosmo_structjoin(defaults,varargin);

use_nmin=isfield(params,'nmin');
if use_nmin
    if isfield(params,'nsets') && ~isequal(params.nsets,defaults.nsets)
        error('Options ''nmin'' and ''nsets'' are mutually exclusive');
    end
    nmin=params.nmin;
else
    nrep=params.nrep;
end

if isstruct(targets) && isfield(targets,'sa') && ...
                isfield(targets.sa,'targets')
    targets=targets.sa.targets;
end

[classes,unused,sample2class]=unique(targets);
nclasses=numel(classes);

train_indices=partitions.train_indices;
test_indices=partitions.test_indices;

% allocat space for output
npar=numel(partitions.train_indices);
bpar_train=cell(1,npar);
bpar_test=cell(1,npar);

for k=1:npar
    par_train=train_indices{k};
    par_test=test_indices{k};
    ts=sample2class(par_train);
    nts=numel(ts);

    h=histc(ts,1:nclasses);
    hmin=min(h);
    if hmin==0
        [unused,i]=min(h);
        error('target %d missing in .train_indices{%d}',...
                    classes(i), k);
    end

    if use_nmin
        nrep=nmin*ceil(max(h)/min(h));
    end

    keep_msk=false(nts*nrep,1);

    ts_rep=repmat(ts,nrep,1);
    par_train_rep=repmat(par_train,nrep,1);
    for c=1:nclasses
        c_idxs=find(ts_rep==c);
        c_pos=0;

        for j=1:nrep
            c_idx=c_pos+(1:hmin);
            keep_msk(c_idxs(c_idx),j)=true;
            c_pos=c_pos+hmin;
        end
    end

    bpar_train_k=cell(nrep,1);
    for j=1:nrep
        bpar_train_k{j}=par_train_rep(keep_msk(:,j));
    end

    bpar_train{k}=bpar_train_k';
    bpar_test{k}=repmat({par_test},nrep,1)';
end

bpartitions=struct();
bpartitions.train_indices=[bpar_train{:}];
bpartitions.test_indices=[bpar_test{:}];
