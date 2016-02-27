function ds_dsm = cosmo_dissimilarity_matrix_measure(ds, varargin)
% Compute a dissimilarity matrix measure
%
% ds_dsm = cosmo_dissimilarity_matrix_measure(ds[, varargin])
%
% Inputs:
%  dataset            dataset struct with fields .samples (PxQ) and
%                     .sa.targets (Px1) for P samples and Q features.
%                     each target should occur exactly once
%  args               optional struct:
%      args.metric:   a string with the name of the distance
%                     metric to be used by pdist (default: 'correlation')
%
%   Returns
%
% Output:
%    ds_sa            Struct with fields:
%      .samples       Nx1 flattened upper triangle of a dissimilarity
%                     matrix as returned by [cosmo_]pdist, where
%                     N=P*(P-1)/2 is the number of pairwise distances
%                     between all samples in the dataset.
%      .a.sdim.labels Set to
%      .sa            Struct with field:
%        .targets1    } Nx1 vectors indicating the pairs of indices in the
%        .targets2    } upper part of the square form of the dissimilarity
%                       matrix. if .dsm_pairs(k,:)==[i,j] then .samples(k)
%                     the dissimlarity between the i-th and j-th sample
%                     target.
%
% Notes:
%  - [cosmo_]pdist defaults to 'euclidean' distance, but correlation
%    distance is preferable for neural dissimilarity matrices, hence it
%    is used as the default here
%
% Example:
%     % ds is a dataset struct with ds.sa.targets=(11:16)';
%     ds=struct();
%     ds.samples=[1 2 3; 1 2 3; 1 0 1; 1 1 2; 1 1 2];
%     ds.sa.targets=(11:15)';
%     %
%     % compute dissimilarity
%     dsm_ds=cosmo_dissimilarity_matrix_measure(ds);
%     cosmo_disp(dsm_ds);
%     > .samples
%     >   [     0
%     >         1
%     >     0.134
%     >       :
%     >       0.5
%     >       0.5
%     >         0 ]@10x1
%     > .sa
%     >   .targets1
%     >     [ 2
%     >       3
%     >       4
%     >       :
%     >       4
%     >       5
%     >       5 ]@10x1
%     >   .targets2
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       3
%     >       3
%     >       4 ]@10x1
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'targets1'  'targets2' }
%     >     .values
%     >       { [ 11    [ 11
%     >           12      12
%     >           13      13
%     >           14      14
%     >           15 ]    15 ] }
%     %
%     % map results to matrix. values of 0 mean perfect correlation
%     [samples, labels, values]=cosmo_unflatten(dsm_ds,1,...
%                                           'set_missing_to',NaN);
%     cosmo_disp(samples)
%     > [   NaN       NaN       NaN       NaN       NaN
%     >       0       NaN       NaN       NaN       NaN
%     >       1         1       NaN       NaN       NaN
%     >   0.134     0.134       0.5       NaN       NaN
%     >   0.134     0.134       0.5         0       NaN ]
%     %
%     cosmo_disp(labels)
%     > { 'targets1'  'targets2' }
%     %
%     cosmo_disp(values)
%     > { [ 11    [ 11
%     >     12      12
%     >     13      13
%     >     14      14
%     >     15 ]    15 ] }
%
%     % Searchlight using this measure
%     ds=cosmo_synthetic_dataset('ntargets',6,'nchunks',1);
%     % (in this toy example there are only 6 voxels, and the radius
%     %  of the searchlight is 1 voxel. Real-life examples use larger
%     %  datasets and a larger radius)
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     opt=struct();
%     opt.progress=false;          % do not show progress
%     opt.metric='euclidean'; % (instead of default 'correlation')
%     measure=@cosmo_dissimilarity_matrix_measure;
%     sl_ds=cosmo_searchlight(ds, nbrhood, measure, opt);
%     cosmo_disp(sl_ds);
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
%     >   .sdim
%     >     .labels
%     >       { 'targets1'  'targets2' }
%     >     .values
%     >       { [ 1    [ 1
%     >           2      2
%     >           3      3
%     >           4      4
%     >           5      5
%     >           6 ]    6 ] }
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
%     >   [  3.1      3.68      3.56      1.47      2.96      2.27
%     >     6.06      6.39      3.29      6.54      4.43       4.1
%     >     5.85       4.2      2.11      6.47      6.18      3.47
%     >       :         :        :          :         :         :
%     >     4.62      3.18     0.829      5.53      5.53      3.14
%     >      3.7      3.08      1.75      4.71      4.95      3.39
%     >     1.23      0.83      1.48      1.03      1.75      1.31 ]@15x6
%     > .sa
%     >   .targets1
%     >     [ 2
%     >       3
%     >       4
%     >       :
%     >       5
%     >       6
%     >       6 ]@15x1
%     >   .targets2
%     >     [ 1
%     >       1
%     >       1
%     >       :
%     >       4
%     >       4
%     >       5 ]@15x1
%     >
%
%     % limitation: cannot have repeated targets
%     ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
%     cosmo_dissimilarity_matrix_measure(ds);
%     > error('...')
%
%     % averaging the samples for each unique target resolves the issue of
%     % repeated targets
%     ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
%     ds_avg=cosmo_fx(ds,@(x)mean(x,1),'targets');
%     cosmo_dissimilarity_matrix_measure(ds_avg)
%     >     samples: [3x1 double]
%     >          sa: [1x1 struct]
%     >           a: [1x1 struct]
%
%
% See also: cosmo_pdist, pdist
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % check input
    cosmo_isfield(ds,{'sa.targets','samples'},true);

    args=cosmo_structjoin('metric','correlation',varargin);

    % ensure that targets occur exactly once.
    targets=ds.sa.targets;
    ntargets=numel(targets);

    % unique targets
    classes=unique(targets);
    nclasses=numel(classes);

    % each should occur exactly once
    if nclasses~=ntargets
        error(['.sa.targets should be permutation of unique targets; '...
                'to average samples with the same targets, consider '...
                'ds_mean=cosmo_fx(ds,@(x)mean(x,1),''targets'')'],...
                    nclasses);
    end

    % make new dataset
    ds_dsm=struct();

    % compute pair-wise distances between all samples using cosmo_pdist,
    % then store them as samples in ds_dsm
    % >@@>
    dsm = cosmo_pdist(ds.samples, args.metric)';

    % store dsm
    ds_dsm.samples=dsm;
    % <@@<

    % store single sample attribute: the pairs of sample attribute indices
    % used to compute the dsm.
    [i,j]=find(triu(repmat(1:nclasses,nclasses,1),1)');
    ds_dsm.sa.targets1=i;
    ds_dsm.sa.targets2=j;

    % set sample dimensions
    add_labels={'targets1','targets2'};
    add_values={targets, targets};
    ds_dsm.a.sdim.labels=add_labels;
    ds_dsm.a.sdim.values=add_values;

