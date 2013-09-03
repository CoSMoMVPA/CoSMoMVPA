function d=cosmo_splithalf_correlation_measure(ds, args)
% Computes a split-half correlation measure
%
% d=cosmo_splithalf_correlation_measure(ds[, args])
%
% Inputs:
%  ds             dataset structure
%  args           optional struct with the following optional fields
%    .partitions  struct with fields .train_indices and .test_indices.
%                 Both should be a Px1 cell for P partitions. If omitted,
%                 then it is required that ds has exacty two chunks and
%                 that each chunks has each target exactly once, and a
%                 single partition is used
%    .template    QxQ matrix for Q classes in each chunk. This matrix 
%                 weights the correlations across the two halves. It should
%                 have a mean of zero. If omitted, it has positive values
%                 of 1-1/Q on the diagonal and -1/Q off the diagonal.
%                 (Note: this can be used to test for representational
%                 similarity matching)
%
% Output:
%    d            Measure indicating how well the template matrix 
%                 correlates with the correlation matrix from the two
%                 halves (averaged over partitions).
%
% Notes: currently supports only cases 
%
% Example:
%   % assumes 5 classes per half, for example from GLM
%   half1=cosmo_fmri_dataset('glm1.nii','targets',1:5,'chunks',ones(1,5));
%   half2=cosmo_fmri_dataset('glm2.nii','targets',1:5,'chunks',2*ones(1,5));
%   ds=cosmo_dataset_stack({half1,half2});
%   measure=@cosmo_splithalf_correlation_measure;
%
%   % compute one measure for the whole brain
%   whole_brain_results=measure(ds); 
%
%   % run searchlight with this measur
%   searchlight_results=cosmo_searchlight(ds,measure,'radius',4); 
%
% NNO Sep 2013

 

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
        error('Partitions not specified, and did not find two unique chunks');
    end
end

npartitions=numel(partitions.train_indices);
npartitions_=numel(partitions.test_indices);

if npartitions~=npartitions_
    error('partition size mismatch for training (%d) and testing (%d)',...
                npartitions,npartitions_);
end

sh_corrs=zeros(npartitions,1); % allocate space for each partition

for k=1:npartitions
    half1_idxs=partitions.train_indices{1};
    half2_idxs=partitions.test_indices{1};

    half1=cosmo_dataset_slice_samples(ds, half1_idxs);
    half2=cosmo_dataset_slice_samples(ds, half2_idxs);
    
    nclasses=size(half1.samples,1); 
    
    half1_targets=half1.sa.targets;
    half2_targets=half2.sa.targets;
    
    % TODO: allow arbitrary order and possibly repeats of chunks
    if ~isequal(half1_targets, half2_targets) || ...
                ~isequal(half1_targets', 1:nclasses)
        error('non-matching targets or not 1..nclasses')
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
    
    c=corr(half1.samples', half2.samples'); % Pearson correlation
    ct=atanh(c); % fisher transformation
    ctw=ct .* template; % weigh each correlation by the template values

    sh_corr=mean(ctw(:)); % compute mean
    sh_corrs(k)=sh_corr; % store results
end

d=mean(sh_corrs);