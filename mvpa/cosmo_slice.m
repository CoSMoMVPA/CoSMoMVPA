function ds=cosmo_slice(ds, elements_to_select, dim, do_check)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_slice(ds, elements_to_select[, dim][do_check])
%
% Inputs:
%   ds                    One of:
%                         - dataset struct to be sliced, with PxQ field 
%                           .samples and optionally fields .fa, .sa and .a.
%                         - cell 
%                         - logical or numeric array 
%   elements_to_select    either a binary mask, or a list of indices of 
%                         the samples (if dim==1) or features (if dim==2)
%                         to select. If a binary mask then the number of
%                         elements should match those of ds in the dim-th
%                         dimension.
%   dim                   Slicing dimension: along samples (dim==1) or 
%                         features (dim==2). (Default: 1)
%   do_check              Boolean that indicates that if ds is a dataset, 
%                         whether it should be checked for proper
%                         structure (default: true). 
%
% Output: 
%   sliced_ds             - if ds is a dataset struct then sliced_ds is a
%                           .samples NxQ (if dim==1) or PxN (if dim==2), if 
%                           N elements were selected. 
%                           Each value in .fa (if dim==1) or .sa(dim==2) 
%                           has N values along the dim-th dimension.
%                         - if an array then sliced_ds is the array sliced
%                           along the dim-th dimension.
%
% Notes:
%   - do_check=false may be preferred for slice-intensive operations such
%     as searchlights
%
% NNO Sep 2013

    % deal with 2, 3, or 4 input arguments
    if nargin<3 || isempty(dim), dim=1; end
    if nargin<4 || isempty(do_check), do_check=true; end
    
    
    if iscell(ds)
        ds=slice_cell(ds, elements_to_select, dim);
    elseif isnumeric(ds) || islogical(ds)
        ds=slice_array(ds, elements_to_select, dim);
    elseif isstruct(ds)
        
        if do_check
            % check kosherness
            cosmo_check_dataset(ds);
        end

        % this function uses recursion; make it immune to renaming
        me=str2func(mfilename());
        
        % slice the samples
        ds.samples=slice_array(ds.samples,elements_to_select,dim);

        % now deal with either feature or sample attributes
        attr_fns={'sa','fa'};
        attr_fn=attr_fns{dim}; % fieldname of attribute to slice

        if isfield(ds, attr_fn)
            attrs=ds.(attr_fn); % get attribute

            fns=fieldnames(attrs); % fieldnames
            n=numel(fns);
            for k=1:n
                fn=fns{k};
                v=attrs.(fn);

                if isempty(v)
                    continue;
                end
                
                % slice cell or array using recursion
                attrs.(fn)=me(v, elements_to_select, dim);
            end
            ds.(attr_fn)=attrs;
        end
    else
        error('Illegal input: expected cell, array or struct');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function y=slice_array(x, to_select, dim)
        % slices the array x along dim with indices, where dim in [1,2]
        check_size(x, to_select, dim);
        if dim==1
            y=x(to_select,:);
        elseif dim==2
            y=x(:,to_select);
        else
            error('dim should be 1 or 2');
        end
        
        
    function y=slice_cell(x, to_select, dim)
        % slices the cell x along dim with indices, where dim in [1,2]
        check_size(x, to_select, dim);
        n_other_dim=size(x,3-dim); % size of other dimension
        
        if dim==1
            % cells are tricky - they become linear after slicing, and have
            % to be put back in shape
            y=reshape({x{to_select,:}},[],n_other_dim);
        elseif dim==2
            y=reshape({x{:, to_select}},n_other_dim,[]);
        else
            error('dim should be 1 or 2');
        end
        
    
    function check_size(x, to_select, dim)
        if islogical(to_select) && ...
                    size(x, dim)~=numel(to_select)
            % be a bit more strict than matlab - binary array must have
            % exactly the correct size
            error('Logical mask should have %d elements, found %d', ...
                    size(x, dim), numel(to_select));
        end
    