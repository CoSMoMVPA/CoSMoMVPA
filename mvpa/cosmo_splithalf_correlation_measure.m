function ds_sa=cosmo_splithalf_correlation_measure(ds, args)
% Computes a split-half correlation measure
%
% d=cosmo_splithalf_correlation_measure(ds[, args])
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
%
% Output:
%    ds_sa        Struct with fields:
%      .samples   Scalar indicating how well the template matrix 
%                 correlates with the correlation matrix from the two
%                 halves (averaged over partitions).
%      .sa        Struct with field:
%        .labels  {'corr'}
%
% Example:
%   % assumes 5 classes per half, for example from GLM
%   half1=cosmo_fmri_dataset('glm1.nii','targets',1:5,'chunks',1);
%   half2=cosmo_fmri_dataset('glm2.nii','targets',1:5,'chunks',2);
%   ds=cosmo_stack({half1,half2});
%   measure=@cosmo_splithalf_correlation_measure;
%
%   % compute one measure for the whole brain
%   whole_brain_results=measure(ds); 
%
%   % run searchlight with this measure
%   searchlight_results=cosmo_searchlight(ds,measure,'radius',4); 
%
% NNO Sep 2013
    
     
    % process input arguments
    if nargin<2
        args=struct();
    end
    
    if ~isfield(args,'opt') args=struct(); end
    
    if ~isfield(args,'partitions') 
        args.partitions=cosmo_nchoosek_partitioner(ds,'half');
    end
    
    if ~isfield(args,'merge_func')
        args.merge_func=@featurewise_mean;
    end
    
    if ~isfield(args,'corr_type')
        args.corr_type='Pearson';
    end
    
    % check partitions
    partitions=args.partitions;
    npartitions=numel(partitions.train_indices);
    npartitions_=numel(partitions.test_indices);
    
    if npartitions~=npartitions_
        error('partition size mismatch for training (%d) and testing (%d)',...
                    npartitions,npartitions_);
    end
    
    % allocate space for each partition
    sh_corrs=zeros(npartitions,1);
    
    % compute the measure
    [nsamples,nfeatures]=size(ds.samples);
    
    for k=1:npartitions
        halves_indices={partitions.train_indices{k},...
                        partitions.test_indices{k}};
        % allocate space for data of two halves
        halves_data=cell(2,1);
        
        sample_use_count=zeros(1,nsamples); % keep track of how often each
                                         % sample was used
        
        % process each half seperately 
        for j=1:2
            sample_idxs=halves_indices{j};
            sample_use_count(sample_idxs)=sample_use_count(sample_idxs)+1;
            half_samples=ds.samples(sample_idxs,:);
            half_targets=ds.sa.targets(sample_idxs);
            if isequal(1:max(half_targets),half_targets')
                % common case: just take the data (this reduces the 
                % compution time by up to a third)
                nclasses=numel(half_targets);
                merged_half_data=half_samples;
                half1_classes=half_targets;
            else
                classes=unique(half_targets);
                
                if j==1
                    half1_classes=classes; % store for first half
                elseif ~isequal(half1_classes,classes) % compare with second half
                    error('class mismatch');
                end

                nclasses=numel(classes);
                merged_half_data=zeros(nclasses,nfeatures);
                for m=1:nclasses
                    half_data=half_samples(classes(m)==half_targets,:);
                    if size(half_data,1)==1
                        merged_half_data(m,:)=half_data;
                    else
                        merged_half_data(m,:)=args.merge_func(half_data);
                    end
                end
            
            end
            halves_data{j}=merged_half_data;
        end
        
        if any(sample_use_count>1)
            % prevent double dipping
            error('Same sample used in two halves - double dipping');
        end
              
        if k==1
            % set up template
            if isfield(args, 'template')
                template=args.template;
                if ~isequal(size(template),[nclasses,nclasses])
                    error('template size mismatch: expect %dx%d',...
                            nclasses, nclasses);
                end
                if abs(mean(template(:))) > 1e-8
                    error('template should have mean of zero');
                end
            else
                template=eye(nclasses)-1/nclasses;
            end
        end
        
        c=cosmo_corr(halves_data{1}', halves_data{2}', args.corr_type); 
        ct=atanh(c); % fisher transformation
        ctw=ct .* template; % weigh each correlation by the template values
    
        sh_corr=mean(ctw(:)); % compute mean
        sh_corrs(k)=sh_corr; % store results
    end
    
    delta=mean(sh_corrs);
    
    ds_sa=struct();
    ds_sa.samples=delta;
    ds_sa.sa.labels={'corr_diff'};
    
    
function y=featurewise_mean(x)
    y=mean(x,1);

        