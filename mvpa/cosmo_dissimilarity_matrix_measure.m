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
%      .metric        a string with the name of the distance
%                     metric to be used by pdist (default: 'correlation')
%      .center_data   If true, then data is centered before the pair-wise
%                     distances are computed. The default is false; when
%                     used with the 'correlation' metric, it is recommended
%                     to use center_data, 'true'.
%
%   Returns
%
% Output:
%    ds_sa            Struct with fields:
%      .samples       Nx1 flattened lower triangle of a dissimilarity
%                     matrix as returned by [cosmo_]pdist, where
%                     N=P*(P-1)/2 is the number of pairwise distances
%                     between all samples in the dataset.
%      .a.sdim.labels Set to
%      .sa            Struct with field:
%        .targets1    } Nx1 vectors indicating the pairs of indices in the
%        .targets2    } lower part of the square form of the dissimilarity
%                       matrix. if .dsm_pairs(k,:)==[i,j] then .samples(k)
%                     the dissimlarity between the i-th and j-th sample
%                     target.
%
%
% Example:
%     % ds is a dataset struct with ds.sa.targets=(11:16)';
%     ds=struct();
%     ds.samples=[1 2 3; 1 2 3; 1 0 1; 1 1 2; 1 1 2];
%     ds.sa.targets=(11:15)';
%     %
%     % compute dissimilarity with centered data
%     dsm_ds=cosmo_dissimilarity_matrix_measure(ds,'center_data',true);
%     cosmo_disp(dsm_ds);
%     %|| .sa
%     %||   .targets1
%     %||     [ 2
%     %||       3
%     %||       4
%     %||       :
%     %||       4
%     %||       5
%     %||       5 ]@10x1
%     %||   .targets2
%     %||     [ 1
%     %||       1
%     %||       1
%     %||       :
%     %||       3
%     %||       3
%     %||       4 ]@10x1
%     %|| .a
%     %||   .sdim
%     %||     .labels
%     %||       { 'targets1'  'targets2' }
%     %||     .values
%     %||       { [ 11    [ 11
%     %||           12      12
%     %||           13      13
%     %||           14      14
%     %||           15 ]    15 ] }
%     %|| .samples
%     %||   [         0
%     %||             2
%     %||             2
%     %||         :
%     %||      1.11e-16
%     %||      1.11e-16
%     %||     -2.22e-16 ]@10x1
%     %
%     % map results to matrix. values of 0 mean perfect correlation
%     [samples, labels, values]=cosmo_unflatten(dsm_ds,1,...
%                                           'set_missing_to',NaN);
%     cosmo_disp(samples)
%     %|| [ NaN       NaN       NaN       NaN       NaN
%     %||     0       NaN       NaN       NaN       NaN
%     %||     2         2       NaN       NaN       NaN
%     %||     2         2  1.11e-16       NaN       NaN
%     %||     2         2  1.11e-16 -2.22e-16       NaN ]
%     %
%     cosmo_disp(labels)
%     %|| { 'targets1'  'targets2' }
%     %
%     cosmo_disp(values)
%     %|| { [ 11    [ 11
%     %||     12      12
%     %||     13      13
%     %||     14      14
%     %||     15 ]    15 ] }
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
%     %|| .a
%     %||   .fdim
%     %||     .labels
%     %||       { 'i'  'j'  'k' }
%     %||     .values
%     %||       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     %||   .vol
%     %||     .mat
%     %||       [ 2         0         0        -3
%     %||         0         2         0        -3
%     %||         0         0         2        -3
%     %||         0         0         0         1 ]
%     %||     .dim
%     %||       [ 3         2         1 ]
%     %||     .xform
%     %||       'scanner_anat'
%     %||   .sdim
%     %||     .labels
%     %||       { 'targets1'  'targets2' }
%     %||     .values
%     %||       { [ 1    [ 1
%     %||           2      2
%     %||           3      3
%     %||           4      4
%     %||           5      5
%     %||           6 ]    6 ] }
%     %|| .fa
%     %||   .nvoxels
%     %||     [ 3         4         3         3         4         3 ]
%     %||   .radius
%     %||     [ 1         1         1         1         1         1 ]
%     %||   .center_ids
%     %||     [ 1         2         3         4         5         6 ]
%     %||   .i
%     %||     [ 1         2         3         1         2         3 ]
%     %||   .j
%     %||     [ 1         1         1         2         2         2 ]
%     %||   .k
%     %||     [ 1         1         1         1         1         1 ]
%     %|| .samples
%     %||   [  3.1      3.68      3.56      1.47      2.96      2.27
%     %||     6.06      6.39      3.29      6.54      4.43       4.1
%     %||     5.85       4.2      2.11      6.47      6.18      3.47
%     %||       :         :        :          :         :         :
%     %||     4.62      3.18     0.829      5.53      5.53      3.14
%     %||      3.7      3.08      1.75      4.71      4.95      3.39
%     %||     1.23      0.83      1.48      1.03      1.75      1.31 ]@15x6
%     %|| .sa
%     %||   .targets1
%     %||     [ 2
%     %||       3
%     %||       4
%     %||       :
%     %||       5
%     %||       6
%     %||       6 ]@15x1
%     %||   .targets2
%     %||     [ 1
%     %||       1
%     %||       1
%     %||       :
%     %||       4
%     %||       4
%     %||       5 ]@15x1
%     %||
%
%     % limitation: cannot have repeated targets
%     ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
%     cosmo_dissimilarity_matrix_measure(ds);
%     %|| error('...')
%
%     % averaging the samples for each unique target resolves the issue of
%     % repeated targets
%     ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
%     ds_avg=cosmo_fx(ds,@(x)mean(x,1),'targets');
%     ds_dsm=cosmo_dissimilarity_matrix_measure(ds_avg);
%     cosmo_disp(ds_dsm);
%     ||.sa
%||  .targets1
%||    [ 2
%||      3
%||      3 ]
%||  .targets2
%||    [ 1
%||      1
%||      2 ]
%||.a
%||  .sdim
%||    .labels
%||      { 'targets1'  'targets2' }
%||    .values
%||      { [ 1    [ 1
%||          2      2
%||          3 ]    3 ] }
%||.samples
%||  [  1.68
%||     1.71
%||    0.711 ]
%
% Notes:
%   - it is recommended to set the 'center_data' to true when using
%     the default 'correlation' metric, as this removes a main effect
%     common to all samples; but note that this option is disabled by
%     default due to historical reasons.
%  -  [cosmo_]pdist defaults to 'euclidean' distance, but correlation
%     distance is preferable for neural dissimilarity matrices, hence it
%     is used as the default here
%  -  Results from this function, when used with the default 'correlation'
%     metric, should *not* be Fisher transformed (using atanh) because
%     the output ranges from 0 to 2 (=one minus Pearson correlation)
%     and the Fisher transform of a value >1 is complex (non-real). This is
%     generally a Bad Thing.
%
% See also: cosmo_pdist, pdist
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % check input
    check_input(ds);
    args=get_args(varargin);

    % make new dataset
    ds_dsm=struct();

    % if center_data, then subtract the mean first
    samples=ds.samples;
    if args.center_data
        samples=bsxfun(@minus,samples,mean(samples,1));
    end

    % compute pair-wise distances between all samples using cosmo_pdist,
    % then store them as samples in ds_dsm
    % >@@>
    dsm = cosmo_pdist(samples, args.metric)';

    % store dsm
    ds_dsm=get_sample_attributes(ds.sa.targets);
    ds_dsm.samples=dsm;
    % <@@<



function check_input(ds)
    if ~(isstruct(ds) && ...
                isfield(ds,'samples') && ...
                isfield(ds,'sa') && ...
                isfield(ds.sa,'targets'))
        error(['require dataset structure with fields '...
                    '.samples and .sa.targets']);
    end

function args=get_args(varargin)
    persistent cached_varargin;
    persistent cached_args;

    if ~isequal(varargin, cached_varargin)
        cached_args=cosmo_structjoin('metric','correlation',...
                            'center_data',false,...
                            varargin);
        cached_varargin=varargin;
    end

    args=cached_args;


function ds_skeleton=get_sample_attributes(targets)
    persistent cached_targets;
    persistent cached_ds_skeleton;

    if ~isequal(targets, cached_targets)
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

        % store single sample attribute: the pairs of sample attribute indices
        % used to compute the dsm.
        [i,j]=find(triu(repmat(1:nclasses,nclasses,1),1)');
        cached_ds_skeleton.sa=struct();
        cached_ds_skeleton.sa.targets1=i;
        cached_ds_skeleton.sa.targets2=j;

        % set sample dimensions
        add_labels={'targets1','targets2'};
        add_values={targets, targets};

        cached_ds_skeleton.a.sdim=struct();
        cached_ds_skeleton.a.sdim.labels=add_labels;
        cached_ds_skeleton.a.sdim.values=add_values;

        cached_targets=targets;
    end

    ds_skeleton=cached_ds_skeleton;