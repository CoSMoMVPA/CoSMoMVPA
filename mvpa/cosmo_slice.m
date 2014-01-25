function ds=cosmo_slice(ds, to_select, dim, type_or_check)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_slice(ds, elements_to_select[, dim][check|'struct'])
%
% Inputs:
%   ds                    One of:
%                         - dataset struct to be sliced, with PxQ field 
%                           .samples and optionally fields .fa, .sa and .a.
%                         - PxQ cell 
%                         - PxQ logical or numeric array 
%   elements_to_select    either a binary mask or a list of indices of 
%                         the samples (if dim==1) or features (if dim==2)
%                         to select. If a binary mask then the number of
%                         elements should match the size of ds in the 
%                         dim-th dimension.
%   dim                   Slicing dimension: along samples (dim==1) or 
%                         features (dim==2). (default: 1).
%   check                 Boolean that indicates that if ds is a dataset, 
%                         whether it should be checked for proper
%                         structure. (default: true). 
%   'struct'              If provided and ds is a struct, then 
%                         all fields of ds, which are assumed to be cell 
%                         or arrays,  are sliced.
%
% Output: 
%   sliced_ds             - If ds is a cell or array then sliced_ds is
%                           the result of slicing ds along the dim-th 
%                           dimension. The result is of size NxQ (if
%                           dim==1) or PxN (if dim==2), where N is the
%                           number of non-zero values in
%                           elements_to_select.
%                         - If ds is a dataset struct then 
%                           sliced_ds.samples is the result of slicing
%                           ds.samples. 
%                           If present, fields .sa (if dim==1) or 
%                           .fa (dim==2) are sliced as well.
%                         - when ds is a struct and the 'struct' option was
%                           given, then all fields in ds are sliced.
%
% Notes:
%   - do_check=false may be preferred for slice-intensive operations such
%     as when used in searchlights
%   - this function does not support arrays with more than two dimensions.
%
% NNO Sep 2013

    % deal with 2, 3, or 4 input arguments
    if nargin<3 || isempty(dim), dim=1; end
    if nargin<4 || isempty(type_or_check), type_or_check=true; end
    
    if iscell(ds) || isnumeric(ds) || islogical(ds)
        ds=slice_array(ds, to_select, dim, type_or_check);
    elseif isstruct(ds)
        if strcmp(type_or_check,'struct')
            ds=slice_struct(ds, to_select, dim, type_or_check);
        else
            if ~isfield(ds,'samples')
                error(['Expected dataset struct. To slice ordinary '...
                        'structs use "struct" as last argument']);
            end
                    
            if type_or_check
                % check kosherness
                cosmo_check_dataset(ds);
            end

            dim_size=size(ds.samples,dim);
            
            % slice the samples
            ds.samples=slice_array(ds.samples,to_select,dim,type_or_check);

            % now deal with either feature or sample attributes
            attr_fns={'sa','fa'};
            attr_fn=attr_fns{dim}; % fieldname of attribute to slice

            if isfield(ds, attr_fn)
                ds.(attr_fn)=slice_struct(ds.(attr_fn),to_select,...
                                               dim,type_or_check,dim_size);
            end
        end
    else
        error('Illegal input: expected cell, array or struct');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function y=slice_struct(x, to_select, dim, do_check, expected_size)
        if nargin<5, expected_size=NaN; end
        
        y=struct();
        fns=fieldnames(x);
        for k=1:numel(fns)
            fn=fns{k};
            v=x.(fn);
            
            v_size=size(v,dim);
            
            % ensure all input sizes are the same
            if isnan(expected_size)
                expected_size=v_size;
            elseif v_size~=expected_size
                error(['Size mismatch for %s: expected %d but found %d',...
                        ' elements in dimension %d'],...
                                v_size, expected_size, dim);
            end
            
            y.(fn)=slice_array(v, to_select, dim, do_check);
        end
           
    
    function y=slice_array(x, to_select, dim, do_check)
        if do_check
            check_size(x, to_select, dim);
        end
        
        if dim==1
            y=x(to_select,:);
        elseif dim==2
            y=x(:,to_select);
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
        
        if numel(size(x))~=2
            error('Only 2D arrays are allowed');
        end
        
        if sum(size(to_select)>1)>1
            error('elements to select should be in vector');
        end
    