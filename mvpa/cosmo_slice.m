function ds=cosmo_slice(ds, elements_to_select, dim)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_slice(ds, elements_to_select[, dim])
%
% Inputs:
%   ds                    dataset struct to be sliced, with PxQ field 
%                         .samples
%   elements_to_select    either a binary mask, or a list of indices of 
%                         the samples (if dim==1) or features (if dim==2)
%                         to select.
%   dim                   Slicing dimension: along samples (dim==1) or 
%                         features (dim==2). (Default: 1)
%
% Output: 
%   sliced_ds             Sliced dataset with .samples NxQ (if dim==1) or
%                         PxN, if N elements were selected. Also each value
%                         in .fa (if dim==1) or .sa(dim==2) has N values
%                         along the dim-th dimension
%
% NNO Sep 2013

    if nargin<3 || isempty(dim), dim=1; end
    
    cosmo_check_dataset(ds);
    
    % slice the samples
    full_data=ds.samples;
    nfull=size(full_data,dim);
    ds.samples=slice_array(full_data,elements_to_select,dim);
    nsliced=size(ds.samples,dim);
    
    % now deal with either feature or sample attributes
    attr_fns={'sa','fa'};
    attr_fn=attr_fns{dim}; % fieldname of attribute to slice
    
    if ~isfield(ds, attr_fn)
        error('illegal dataset - no %s', attr_fn); 
    end 
    attrs=ds.(attr_fn); % get attribute
    
    fns=fieldnames(attrs); % fieldnames
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        
        v=attrs.(fn);
        
        if isempty(v)
            continue;
        end
        
        if iscell(v)
            v_sliced=slice_cell(v, elements_to_select,dim);
        else
            v_sliced=slice_array(v, elements_to_select,dim);
        end
        
        attrs.(fn)=v_sliced; % set the sliced values
    end
    ds.(attr_fn)=attrs;
    
    cosmo_check_dataset(ds);
    
    
    function y=slice_array(x, to_select, dim)
        % slices the array x along dim with indices, where dim in [1,2]
        if dim==1
            y=x(to_select,:);
        elseif dim==2
            y=x(:,to_select);
        else
            error('dim should be 1 or 2');
        end
        
    function y=slice_cell(x, to_select, dim)
        % slices the cell x along dim with indices, where dim in [1,2]
        if dim==1
            % cells are tricky - they become linear after slicing, and have
            % to be put back in shape
            n_other_dim=size(x,2);
            y=reshape({x{to_select,:}},[],n_other_dim);
        elseif dim==2
            n_other_dim=size(x,1);
            y=reshape({x{:, to_select}},n_other_dim,[]);
        else
            error('dim should be 1 or 2');
        end
    