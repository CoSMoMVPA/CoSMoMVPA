function ds_sa=cosmo_correlation_measure(ds, varargin)
% Computes a split-half correlation measure
%
% d=cosmo_correlation_measure(ds[, args])
%
% Inputs:
%  ds             dataset structure
%  args           optional struct with the following optional fields
%    .partitions  struct with fields .train_indices and .test_indices.
%                 Both should be a Px1 cell for P partitions. If omitted,
%                 it is set to cosmo_nchoosek_partitioner(ds,'half').
%    .template    QxQ matrix for Q classes in each chunk. This matrix
%                 weights the correlations across the two halves. It should
%                 have a mean of zero. If omitted, it has positive values
%                 of 1-1/Q on the diagonal and -1/Q off the diagonal.
%                 (Note: this can be used to test for representational
%                 similarity matching)
%    .merge_func  A function handle used to merge data from matching
%                 targets in the same chunk. Default is @(x) mean(x,1),
%                 meaning that values are averaged over the same samples.
%                 It is assumed that isequal(args.merge_func(y),y) if y
%                 is a row vector.
%    .corr_type   Type of correlation: 'Pearson','Spearman','Kendall'.
%                 The default is 'Pearson'.
%    .post_corr   Operation performed after correlation. (default: @atanh)
%    .output      'corr' (default): correlations weighted by template
%                 'raw': correlations between all classes
%
%
% Output:
%    ds_sa        Struct with fields:
%      .samples   Scalar indicating how well the template matrix
%                 correlates with the correlation matrix from the two
%                 halves (averaged over partitions).
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
%     >   [ 0.0631 ]
%     > .sa
%     >   .labels
%     >     'corr'
%     %
%     % use Spearman correlations
%     c=cosmo_correlation_measure(ds,'corr_type','Spearman');
%     cosmo_disp(c)
%     > .samples
%     >   [ 0.0573 ]
%     > .sa
%     >   .labels
%     >     'corr'
%     %
%     % get raw output
%     c_raw=cosmo_correlation_measure(ds,'output','raw');
%     cosmo_disp(c_raw)
%     > .samples
%     >   [ 0.386
%     >     0.239
%     >     0.238
%     >     0.596 ]
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
%
%     % minimal searchlight example
%     ds=cosmo_synthetic_dataset('type','fmri');
%     radius=1; % in voxel units (radius=3 is more typical)
%     res=cosmo_searchlight(ds,@cosmo_correlation_measure,'radius',radius,'progress',false);
%     cosmo_disp(res.samples)
%     > [ 0.314   -0.0537     0.261     0.248     0.129     0.449 ]
%     cosmo_disp(res.sa)
%     > .labels
%     >   'corr'
%
% Notes:
%   - by default the post_corr_func is set to @atanh. This is equivalent to
%     a Fisher transformation from r (correlation) to z (standard z-score).
%     The underlying math is z=atanh(r)=.5*log((1+r)./log(1-r))
%   - if multiple samples are present with the same chunk and target, they
%     are averaged *prior* to computing the correlations
%   - if multiple partitions are present, then the correlations are
%     computed separately for each partition, and then averaged
%
% NNO May 2014

persistent cached_partitions;
persistent cached_chunks;

defaults=struct();
defaults.partitions=[];
defaults.template=[];
defaults.merge_func=@mean_sample;
defaults.corr_type='Pearson';
defaults.post_corr_func=@atanh;
defaults.output='mean';
defaults.check_partitions=true;

params=cosmo_structjoin(defaults, varargin);

partitions=params.partitions;
template=params.template;
merge_func=params.merge_func;
post_corr_func=params.post_corr_func;
check_partitions=params.check_partitions;

chunks=ds.sa.chunks;

if isempty(partitions)
    if ~isempty(cached_chunks) && isequal(cached_chunks, chunks)
        partitions=cached_partitions;
        check_partitions=false;
    else
        partitions=cosmo_nchoosek_partitioner(ds,'half');
        cached_chunks=ds.sa.chunks;
        cached_partitions=partitions;
    end
end

if check_partitions
    cosmo_check_partitions(partitions, ds, params);
end

targets=ds.sa.targets;
classes=unique(targets);
nclasses=numel(classes);

if isempty(template)
    template=eye(nclasses)-1/nclasses;
end

template_msk=isfinite(template);

npartitions=numel(partitions.train_indices);
halves={partitions.train_indices, partitions.test_indices};

pdata=cell(npartitions,1);
for k=1:npartitions
    half1=get_data(ds, partitions.train_indices{k}, classes, merge_func);
    half2=get_data(ds, partitions.test_indices{k}, classes, merge_func);

    c=cosmo_corr(half1', half2', params.corr_type);


    if ~isempty(post_corr_func)
        c=post_corr_func(c);
    end

    switch params.output
        case 'mean'
            pcw=c(template_msk).*template(template_msk);
            pdatak=mean(pcw(:));
        case 'raw'
            pdatak=c(:);
        otherwise
            error('Unsupported output %s', params.output);
    end
    pdata{k}=pdatak;
end

ds_sa=struct();
ds_sa.samples=mean(cat(2,pdata{:}),2);

switch params.output
    case 'mean'
        ds_sa.sa.labels='corr';
    case 'raw'
        ds_sa.sa.half1=reshape(repmat((1:nclasses)',nclasses,1),[],1);
        ds_sa.sa.half2=reshape(repmat((1:nclasses),nclasses,1),[],1);

        ds_sa.a.sdim=struct();
        ds_sa.a.sdim.labels={'half1','half2'};
        ds_sa.a.sdim.values={classes, classes};

        %sa.half1=reshape(repmat(classes',nclasses,1),[],1);
        %sa.half2=reshape(repmat(classes,nclasses,1),[],1);
end


function data=get_data(ds, sample_idxs, classes, merge_func)
    samples=ds.samples(sample_idxs,:);
    targets=ds.sa.targets(sample_idxs,:);

    nclasses=numel(classes);
    nfeatures=size(samples,2);
    data=zeros(nclasses,nfeatures);

    for k=1:nclasses
        msk=classes(k)==targets;
        if ~any(msk)
            error('missing target class %d', classes(k));
        end

        data(k,:)=merge_func(samples(msk,:));
    end



function samples=mean_sample(samples)

    nsamples=size(samples,1);
    if nsamples>1
        samples=sum(samples,1)/nsamples;
    end


