%% Example of de-meaning
%

%% Generate random dataset
ds=cosmo_synthetic_dataset('nchunks',4,'ntargets',3);

%% Split the dataset by chunks
% >@@>
splits=cosmo_split(ds,{'chunks'},1);
% >@@>
nsplits=numel(splits);

% allocate space for output
outputs=cell(nsplits,1);

% treat each element in splits seperately, and subtract the mean for each
% feature seperately
for k=1:nsplits
    d=splits{k};
    % >@@>

    % mean over samples, for each feature
    mu=mean(d.samples,1);

    % subtract the mean.
    % equivalent, but less efficient, is:
    %     nsamples=size(d.samples,1);
    %     d.samples=d.samples-repmat(mu,nsamples,1);
    %
    d.samples=bsxfun(@minus,d.samples,mu);
    % >@@>

    % store output
    outputs{k}=d;
end

ds_demeaned=cosmo_stack(outputs);

%% Alternative approach to demeaning

demeaner=@(x)bsxfun(@minus,x,mean(x,1)); % function handle as helper
ds_demeaned_alt=cosmo_fx(ds,demeaner,'chunks');
