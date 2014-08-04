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
%   % assumes 5 classes per half, for example from GLM
%   half1=cosmo_fmri_dataset('glm1.nii','targets',1:5,'chunks',1);
%   half2=cosmo_fmri_dataset('glm2.nii','targets',1:5,'chunks',2);
%   ds=cosmo_stack({half1,half2});
%   measure=@cosmo_correlation_measure;
%
%   % compute one measure for the whole brain
%   whole_brain_results=measure(ds); 
%
%   % run searchlight with this measure
%   searchlight_results=cosmo_searchlight(ds,measure,'radius',4); 
%
% Notes:
%   - by default the post_corr_func is set to @atanh. This is equivalent to 
%     a Fisher transformation from r (correlation) to z (standard z-score).
%     The underlying math is z=atanh(r)=.5*log((1+r)./log(1-r))
%   - if multiple samples are present with the same chunk and target, they
%     are averaged *prior* to computing the correlations
%
% NNO May 2014

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

if isempty(partitions)
    partitions=cosmo_nchoosek_partitioner(ds,'half');
end

if params.check_partitions
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
    avg_halves_data=cell(1,2);
    
    % compute average over samples, for each target seperately
    for h=1:2
        idxs=halves{h}{k};
        half_data=cosmo_slice(ds.samples,idxs,1,false);
        
        if isequal(targets(idxs),(1:numel(idxs))')
            % optimization: no averaging necessary 
            avg_halves_data{h}=half_data;
        else
            res=cell(1,nclasses);
            for j=1:nclasses
                msk=targets(idxs)==classes(j);
                if ~any(msk)
                    error('missing target class %d', classes(j));
                end
                
                res{j}=merge_func(half_data(msk,:));
            end

            avg_halves_data{h}=cat(1,res{:});
        end
    end
    
    c=cosmo_corr(avg_halves_data{1}',avg_halves_data{2}',params.corr_type);
    
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

sa=struct();
switch params.output
    case 'mean'
        sa.labels='corr';
    case 'raw'
        sa.half1=reshape(repmat(classes',nclasses,1),[],1);
        sa.half2=reshape(repmat(classes,nclasses,1),[],1);
end
        
ds_sa.sa=sa;


function samples=mean_sample(samples)

nsamples=size(samples,1);
if nsamples>1
    samples=sum(samples,1)/nsamples;
end

        