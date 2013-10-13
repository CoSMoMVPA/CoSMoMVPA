function ds_stacked=cosmo_stack(datasets,dim)
% stacks multiple datasets to yield a single dataset
%
% ds_stacked=cosmo_stack(datasets[,dim])
%
% Inputs
%   datasets     Nx1 cell with input datasets
%   dim          dimension over which data is stacked. This should be
%                either 1 (stack samples) or 2 (stack features).
%                The default is 1.
%
% Ouput:
%   ds_stacked   Stacked dataset. If dim==1 [or dim==2] and the K-th 
%                dataset has size M_K x N_K, then it is required that all 
%                N_* [M_*] are the same, and the output has size 
%                sum(M_*) x N_1 [M_1 x sum(N_*)]. It is also required that 
%                all input datasets have the same values across all
%                the feature [sample] attributes.
%                
% Example:
%  % Inputs have 5 samples each; combine them for split-half analysis
%  half1=cosmo_fmri_dataset('glm1.nii','targets',1:5,'chunks',ones(1,5));
%  half2=cosmo_fmri_dataset('glm2.nii','targets',1:5,'chunks',2*ones(1,5));
%  ds=cosmo_stack({half1,half2}); % output has 10 samples
%
% Note:
%   this function is like the inverse of cosmo_split, in the sense that if
%       ds_splits=cosmo_split(ds, split_by, dim),
%   produces output (i.e., does not throw an error), then using
%       ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%   means that ds and ds_humpty_dumpty contain the same data, except that 
%   the order of the data (in the rows [or columns] of .samples, and values
%   in .sa [.fa]) may be in different order if dim==1 [dim==2].
%
% See also: cosmo_split
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
    
    if all(dim~=[1 2])
        error('dim should be 1 or 2');
    end
    
    % set the field names for the dimension to be stacked, and the other
    % one
    attrs_fns={'sa','fa'};
    stack_fn=attrs_fns{dim};
    
    other_dim=3-dim; % the other dimension
    merge_fn=attrs_fns{other_dim};
    
    % stack attributes over dim
    if isfield(ds_stacked, stack_fn)
        fns=fieldnames(ds_stacked.(stack_fn));
        nfn=numel(fns);

        for k=1:nfn
            % check k-th fieldname
            fn=fns{k};
            vs=cell(n,1);
            for j=1:n
                ds=datasets{j};

                % check this dataset is kosher
                cosmo_check_dataset(ds);

                % check presence of fieldname
                if ~isfield(ds.(stack_fn),fn)
                    error('field name not found for %d-th input: .%s.%s', ...
                                        j, stack_fn, fn);
                end
                vs{j}=ds.(stack_fn).(fn);
            end
            ds_stacked.(stack_fn).(fn)=cat(dim,vs{:});
        end
    end
    
    % for the other dim, just make sure that the attributes are identical
    if isfield(ds_stacked, merge_fn)
        fns=fieldnames(ds_stacked.(merge_fn));
        nfn=numel(fns);

        for k=1:nfn
            % check k-th fieldname
            fn=fns{k};
            for j=1:n
                ds=datasets{j};
                % require that the fieldname is present
                if ~isfield(ds.(merge_fn),fn)
                    error('field name not found for %d-th input: .%s.%s', ...
                                        j, merge_fn, fn);
                end
                % if different throw an error
                if ~isequal(ds.(merge_fn).(fn), ds_stacked.(merge_fn).(fn))
                    error('value mismatch: .%s.%s', merge_fn, fn);
                end 
            end
        end
    end
    
    % we're good for the attributes - let's stack the sample data
    vs=cell(n,1);
    
    for k=1:n
        samples=datasets{k}.samples;
        if k==1
            size_first = size(samples,other_dim); % store size of first dataset
        elseif size(samples,other_dim)~=size_first
            error('sample size mismatch: %d x %d ~= %d x %d',...
                        size(samples), size_first)
        end
        vs{k}=datasets{k}.samples;
    end
    ds_stacked.samples=cat(dim,vs{:});
    