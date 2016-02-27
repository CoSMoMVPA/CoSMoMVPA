function ds_sa=cosmo_correlation_measure(ds, varargin)
% Computes a split-half correlation measure
%
% d=cosmo_correlation_measure(ds[, args])
%
% Inputs:
%  ds             dataset structure with fields .samples, .sa.targets and
%                 .sa.chunks
%  args           optional struct with the following optional fields:
%    .partitions  struct with fields .train_indices and .test_indices.
%                 Both should be a Px1 cell for P partitions. If omitted,
%                 it is set to cosmo_nchoosek_partitioner(ds,'half').
%    .template    QxQ matrix for Q classes in each chunk. This matrix
%                 weights the correlations across the two halves.
%                 If ds.sa.targets has only one unique value, it must be
%                 set to the scalar value 1; otherwise it should
%                 have a mean of zero. If omitted, it has positive values
%                 of (1/Q) on the diagonal and (-1/(Q*(Q-1)) off the
%                 diagonal.
%                 (Note: this can be used to test for representational
%                 similarity matching)
%    .merge_func  A function handle used to merge data from matching
%                 targets in the same chunk. Default is @(x) mean(x,1),
%                 meaning that values are averaged over the same samples.
%                 It is assumed that isequal(args.merge_func(y),y) if y
%                 is a row vector.
%    .corr_type   Type of correlation: 'Pearson','Spearman','Kendall'.
%                 The default is 'Pearson'.
%    .post_corr_func  Operation performed after correlation. (default:
%                     @atanh)
%    .output      'mean' (default): correlations weighted by template
%                 'raw' or 'correlation': correlations between all classes
%                 'one_minus_correlation': 1 minus correlations
%                 'mean_by_fold': provide weighted correlations for each
%                                 fold in the partitions.
%
%
% Output:
%    ds_sa        Struct with fields:
%      .samples   Scalar indicating how well the template matrix
%                 correlates with the correlation matrix from the two
%                 halves (averaged over partitions). By default:
%                 - this value is based on Fisher-transformed correlation
%                   values, not raw correlation values
%                 - this is the average of the (Fisher-transformed)
%                   on-diagonal minus the average of the
%                   (Fisher-transformed) off-diagonal elements of the
%                   correlation matrix based on the two halves of the data.
%      .sa        Struct with field:
%        .labels  if output=='corr'
%        .half1   } if output=='raw': (N^2)x1 vectors with indices of data
%        .half2   } from two halves, with N the number of unique targets.
%
% Example:
%     ds=cosmo_synthetic_dataset();
%     %
%     % compute on-minus-off diagonal correlations
%     c=cosmo_correlation_measure(ds);
%     cosmo_disp(c)
%     > .samples
%     >   [ 1.23 ]
%     > .sa
%     >   .labels
%     >   { 'corr' }
%     %
%     % use Spearman correlations
%     c=cosmo_correlation_measure(ds,'corr_type','Spearman');
%     cosmo_disp(c)
%     > .samples
%     >   [ 1.28 ]
%     > .sa
%     >   .labels
%     >   { 'corr' }
%     %
%     % get raw output
%     c_raw=cosmo_correlation_measure(ds,'output','correlation');
%     cosmo_disp(c_raw)
%     > .samples
%     >   [  0.447
%     >     -0.538
%     >     -0.525
%     >      0.959 ]
%     > .sa
%     >   .half1
%     >     [ 1
%     >       2
%     >       1
%     >       2 ]
%     >   .half2
%     >     [ 1
%     >       1
%     >       2
%     >       2 ]
%     > .a
%     >   .sdim
%     >     .labels
%     >       { 'half1'  'half2' }
%     >     .values
%     >       { [ 1    [ 1
%     >           2 ]    2 ] }
%     %
%     % convert to matrix form (N x N x P, with N the number of classes and
%     % P=1)
%     matrices=cosmo_unflatten(c_raw,1);
%     cosmo_disp(matrices)
%     > [  0.447    -0.525
%     >   -0.538     0.959 ]
%
%     % compute for each fold separately, using a custom take-one-chunk
%     % out partitioning scheme. c.sa.chunks in the output
%     % reflects the test chunk in each partition
%     ds=cosmo_synthetic_dataset('type','fmri','nchunks',4);
%     partitions=cosmo_nfold_partitioner(ds);
%     c=cosmo_correlation_measure(ds,'output','mean_by_fold',...
%                         'partitions',partitions);
%     cosmo_disp(c.samples);
%     > [  1.72
%     >   0.728
%     >    1.25
%     >    2.02 ]
%     cosmo_disp(c.sa);
%     > .partition
%     >   [ 1
%     >     2
%     >     3
%     >     4 ]
%
%     % minimal searchlight example
%     ds=cosmo_synthetic_dataset('type','fmri');
%     % use searchlight with radius 1 voxel (radius=3 is more typical)
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     % run searchlight
%     res=cosmo_searchlight(ds,nbrhood,@cosmo_correlation_measure,...
%                               'progress',false);
%     cosmo_disp(res.samples)
%     > [ 1.87      1.25      1.51      1.68      1.71     0.879 ]
%     cosmo_disp(res.sa)
%     > .labels
%     >   { 'corr' }
%
% Notes:
%   - by default the post_corr_func is set to @atanh. This is equivalent to
%     a Fisher transformation from r (correlation) to z (standard z-score).
%     The underlying math is z=atanh(r)=.5*log((1+r)./log(1-r)).
%     The rationale is to make data more normally distributed under the
%     null hypothesis.
%     Fisher-transformed correlations can be transformed back to
%     their original correlation values using 'tanh', which is the inverse
%     of 'atanh'.
%   - To disable the (by default used) Fisher-transformation, set the
%     'post_corr_func' option to [].
%   - if multiple samples are present with the same chunk and target, they
%     are averaged *prior* to computing the correlations.
%   - if multiple partitions are present, then the correlations are
%     computed separately for each partition, and then averaged (unless
%     the 'output' option is set, and set to a different value than
%     'mean'.
%   - When more than two chunks are present in the input, partitions
%     consist of all possible half splits for which the number of unique
%     chunks in the train and test set differ by 1 at most.
%     For illustration, up to 6 chunks, the
%     partitions are:
%       - 2 chunks   -  partition #1
%         chunks first  half: {    1
%         chunks second half:  {   2
%
%       - 3 chunks   -  partition #1  #2  #3
%         chunks first  half: {    3   2   1
%                              {   1   1   2
%         chunks second half:  {   2   3   3
%
%       - 4 chunks   -  partition #1  #2  #3
%                             {    3   2   2
%         chunks first  half: {    4   4   3
%                              {   1   1   1
%         chunks second half:  {   2   3   4
%
%       - 5 chunks   -  partition #1  #2  #3  #4  #5  #6  #7  #8  #9  #10
%                             {    4   3   3   2   2   2   1   1   1   1
%         chunks first  half: {    5   5   4   5   4   3   5   4   3   2
%                              {   1   1   1   1   1   1   2   2   2   3
%         chunks second half:  {   2   2   2   3   3   4   3   3   4   4
%                              {   3   4   5   4   5   5   4   5   5   5
%
%       - 6 chunks   -  partition #1  #2  #3  #4  #5  #6  #7  #8  #9  #10
%                             {    4   3   3   3   2   2   2   2   2   2
%         chunks first  half: {    5   5   4   4   5   4   4   3   3   3
%                             {    6   6   6   5   6   6   5   6   5   4
%                              {   1   1   1   1   1   1   1   1   1   1
%         chunks second half:  {   2   2   2   2   3   3   3   4   4   5
%                              {   3   4   5   6   4   5   6   5   6   6
%     Thus, with an increasing number of chunks, the number of partitions
%     (and thus the time required to run this function) increases
%     quadratically. To use simpler partition schemes (e.g. odd-even, as
%     provided by cosmo_oddeven_partitioner), specify the 'partitions'
%     argument.
%
% References
%   - Haxby, J. V. et al (2001). Distributed and overlapping
%     representations of faces and objects in ventral temporal cortex.
%     Science 293, 2425?2430
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

persistent cached_partitions;
persistent cached_chunks;
persistent cached_params;
persistent cached_varargin;

% optimize parameters parsing: if same arguments were used in
% a previous call, do not use cosmo_structjoin (which is relative
% expensive)
if ~isempty(cached_params) && isequal(cached_varargin, varargin)
    params=cached_params;
else
    defaults=struct();
    defaults.partitions=[];
    defaults.template=[];
    defaults.merge_func=[];
    defaults.corr_type='Pearson';
    defaults.post_corr_func=@atanh;
    defaults.output='mean';
    defaults.check_partitions=true;

    params=cosmo_structjoin(defaults, varargin);

    cached_params=params;
    cached_varargin=varargin;
end

partitions=params.partitions;
template=params.template;
merge_func=params.merge_func;
post_corr_func=params.post_corr_func;
check_partitions=params.check_partitions;

chunks=ds.sa.chunks;

if isempty(partitions)
    if ~isempty(cached_chunks) && isequal(cached_chunks, chunks)
        partitions=cached_partitions;

        % assume that partitions were already checked
        check_partitions=false;
    else
        partitions=cosmo_nchoosek_partitioner(ds,'half');
        cached_chunks=chunks;
        cached_partitions=partitions;
    end
end

if check_partitions
    cosmo_check_partitions(partitions, ds, params);
end

targets=ds.sa.targets;
nsamples=size(targets,1);

[classes,unused,class_ids]=fast_unique(targets);
nclasses=numel(classes);

switch nclasses
    case 0
        error('No classes found - this is not supported');
    case 1
        if ~isequal(template,1)
            error([ 'Only one unique value for .sa.targets was found; '...
                    'this is only allowed when the ''template'' '...
                    'parameter is explicitly set to 1.\n'...
                    'Note that this option does not compute the '...
                    'correlation *difference* between matching and '...
                    'non-matching values in .sa.targets; instead it '...
                    'computes the direct correlation '...
                    'between two halves of the data. A typical use '...
                    'case is when .samples already contains a '...
                    'difference score  comparing two different '...
                    'conditions']);
        end
    otherwise
        if isempty(template)
            template=(eye(nclasses)-1/nclasses)/(nclasses-1);
        else
            max_tolerance=1e-8;
            if abs(sum(template(:)))>max_tolerance
                error('Template matrix does not have a sum of zero');
            end
        end
end


template_msk=isfinite(template);

npartitions=numel(partitions.train_indices);

% space for output
pdata=cell(npartitions,1);

% keep track of how often each chunk was used in test_indices,
% and which chunk was used last
test_chunks_last=NaN(nsamples,1);
test_chunks_count=zeros(nsamples,1);

for k=1:npartitions
    train_indices=partitions.train_indices{k};
    test_indices=partitions.test_indices{k};

    % get data in each half
    half1=get_data(ds, train_indices, class_ids, merge_func);
    half2=get_data(ds, test_indices, class_ids, merge_func);

    % compute raw correlations
    raw_c=cosmo_corr(half1', half2', params.corr_type);

    % apply post-processing (usually Fisher-transform, i.e. atanh)
    c=apply_post_corr_func(post_corr_func,raw_c);

    % aggregate results
    pdata{k}=aggregate_correlations(c,template,template_msk,params.output);
    test_chunks_last(test_indices)=chunks(test_indices);
    test_chunks_count(test_indices)=test_chunks_count(test_indices)+1;
end

ds_sa=struct();

switch params.output
    case 'mean'
        ds_sa.samples=mean(cat(2,pdata{:}),2);
        ds_sa.sa.labels={'corr'};
    case {'raw','correlation'}
        ds_sa.samples=mean(cat(2,pdata{:}),2);

        nclasses=numel(classes);
        ds_sa.sa.half1=reshape(repmat((1:nclasses)',nclasses,1),[],1);
        ds_sa.sa.half2=reshape(repmat((1:nclasses),nclasses,1),[],1);

        ds_sa.a.sdim=struct();
        ds_sa.a.sdim.labels={'half1','half2'};
        ds_sa.a.sdim.values={classes, classes};

    case 'mean_by_fold'
        ds_sa.sa.partition=(1:npartitions)';
        ds_sa.samples=[pdata{:}]';

    otherwise
        assert(false,'this should be caught by get_data');
end

function c=apply_post_corr_func(post_corr_func,c)
    if ~isempty(post_corr_func)
        c=post_corr_func(c);
    end


function agg_c=aggregate_correlations(c,template,template_msk,output)
    switch output
        case {'mean','mean_by_fold'}
            pcw=c(template_msk).*template(template_msk);
            agg_c=sum(pcw(:));
        case {'raw','correlation'}
            agg_c=c(:);
        case 'one_minus_correlation'
            error(['the ''output'' option ''one_minus_correlation'' '...
                        'has been removed. Please contact CoSMoMVPA''s '...
                        'authors if you really need this option']);
        otherwise
            error('Unsupported output %s',output);
    end

function [unq,pos,ids]=fast_unique(x)
    % optimized for vectors
    [y,i]=sort(x,1);
    msk=[true;diff(y)>0];
    j=find(msk);
    pos=i(j);
    unq=y(j);

    vs=cumsum(msk);
    ids=vs;
    ids(i)=vs;


function data=get_data(ds, sample_idxs, class_ids, merge_func)
    samples=ds.samples(sample_idxs,:);
    target_ids=class_ids(sample_idxs);

    nclasses=max(class_ids);

    merge_by_averaging=isempty(merge_func);
    if isequal(target_ids',1:nclasses) && merge_by_averaging
        % optimize standard case of one sample per class and normal
        % averaging over samples
        data=samples;
        return
    end

    nfeatures=size(samples,2);
    data=zeros(nclasses,nfeatures);

    for k=1:nclasses
        msk=target_ids==k;

        n=sum(msk);

        class_samples=samples(msk,:);

        if merge_by_averaging
            if n==1
                data(k,:)=class_samples;
            else
                data(k,:)=sum(class_samples,1)/n;
            end
        else
            data(k,:)=merge_func(class_samples);
        end

        if n==0
            error('missing target class %d', class_ids(k));
        end
    end


