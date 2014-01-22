function ds=cosmo_slice(ds, elements_to_select, dim, do_check_ds)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_slice(ds, elements_to_select[, dim][do_check])
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
%   do_check              Boolean that indicates that if ds is a dataset, 
%                         whether it should be checked for proper
%                         structure. (default: true). 
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
%
% Notes:
%   - do_check=false may be preferred for slice-intensive operations such
%     as when used in searchlights
%   - this function does not support arrays with more than two dimensions.
%
% NNO Sep 2013

    % deal with 2, 3, or 4 input arguments
    if nargin<3 || isempty(dim), dim=1; end
    if nargin<4 || isempty(do_check_ds), do_check_ds=true; end
    
    
    if iscell(ds) || isnumeric(ds) || islogical(ds)
        ds=slice_(ds, elements_to_select, dim);
    elseif isstruct(ds)
        
        if do_check_ds
            % check kosherness
            cosmo_check_dataset(ds);
        end

        % slice the samples
        ds.samples=slice_(ds.samples,elements_to_select,dim);

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
                attrs.(fn)=slice_(v, elements_to_select, dim);
            end
            ds.(attr_fn)=attrs;
        end
    else
        error('Illegal input: expected cell, array or struct');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % helper functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function y=slice_(x, to_select, dim)
        check_size(x, to_select, dim);
        
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
    