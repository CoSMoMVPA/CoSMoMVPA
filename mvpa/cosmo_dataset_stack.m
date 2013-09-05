function ds_stacked=cosmo_dataset_stack(datasets,dim)
% stacks multiple datasets to yield a single dataset
%
% ds_stacked=cosmo_dataset_stack(datasets[,dim])
%
% Inputs
%   datasets     Nx1 cell with input datasets
%   dim          dimension over which data is stacked. This should be
%                either 1 (stack samples) or 2 (stack features).
%                The default is 1.
%
% Ouput:
%   ds_stacked   Stacked dataset. If dim==1 [or dim==2] and the K-th 
%                dataset has size M_K x N_K, then it is requires that all 
%                N_* [M_*] are the same, and the output has size 
%                sum(M_*) x N_1 [M_1 x sum(N_*)]. It is also required that 
%                all input datasets have the same values across all
%                the feature [sample] attributes.
%                
% Example:
%  % Inputs have 5 samples each
%  half1=cosmo_fmri_dataset('glm1.nii','targets',1:5,'chunks',ones(1,5));
%  half2=cosmo_fmri_dataset('glm2.nii','targets',1:5,'chunks',2*ones(1,5));
%  ds=cosmo_dataset_stack({half1,half2}); % output has 10 samples
%
% NNO Sep 2013
    
    
    if nargin<2,
        dim=1;
    end
    
    if ~iscell(datasets)
        error('expected cell input');
    end
    
    n=numel(datasets);
    if n==0
        error('empty cell input')
    end
    
    ds_stacked=datasets{1}; % take first dataset as starting point for output
    
    % determine across which dimension data is stacked; it's merged on the
    % other one
    switch dim
        case 1
            stackfn='sa';
            mergefn='fa';
        case 2
            stackfn='fa';
            mergefn='sa';
        otherwise
            error('dim should be 1 or 2')
    end
            
    otherdim=3-dim; % the other dimension       
    
    % stack attributes over dim
    fns=fieldnames(ds_stacked.(stackfn));
    nfn=numel(fns);
    for k=1:nfn
        fn=fns{k};
        vs=cell(n,1);
        for j=1:n
            ds=datasets{j};
            if ~isfield(ds.(stackfn),fn)
                error('field name not found: %s', fn);
            end
            vs{j}=ds.(stackfn).(fn);
        end
        ds_stacked.(stackfn).(fn)=cat(dim,vs{:});
    end
    
    % for the otherdim, just make sure that the attributes are identical
    fns=fieldnames(ds_stacked.(mergefn));
    nfn=numel(fns);
    
    for k=1:nfn
        fn=fns{k};
        for j=1:n
            ds=datasets{j};
            if ~isfield(ds.(mergefn),fn)
                error('field name not found: %s', fn);
            end
            if ~isequal(ds.(mergefn).(fn), ds_stacked.(mergefn).(fn))
                error('value mismatch: %s', fn);
            end 
        end
    end
    
    % stack the sample data
    vs=cell(n,1);
    for k=1:n
        vs{k}=datasets{k}.samples;
    end
    ds_stacked.samples=cat(dim,vs{:});
    