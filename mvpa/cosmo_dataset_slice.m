function ds=cosmo_dataset_slice(ds, elements_to_select, dim)
% Slice a dataset by samples (the default) or features
%
% sliced_ds=cosmo_dataset_slice(ds, elements_to_select[, dim])
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
    if ~any(dim==1:2), error('dim should be 1 or 2'); end
    
    shift=dim-1; % how much to shift
    
    % Deal tith .samples
    % Shift first so that slicing is done along the first dimension
    % irrespectective of value of dim, then shift back.
    full_data=shiftdim(ds.samples,shift); % shift forward
    nfull=size(full_data,1); % how many values along dim and other
    data=full_data(elements_to_select,:); % select data
    nsliced=size(data,1);
    ds.samples=shiftdim(data, shift); % shift back (data is 2D)
    
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
        v_shift=shiftdim(v,shift); % shift forward
        
        % check the size
        if size(v_shift,1)~=nfull
            error(['Expected %d values for field %s.%s in %-th ',...
                    'dimension, found %d'],...
                    nvalues, attr_fn, fn, dim, size(v_shift,1));
        end
        
        if iscell(v_shift)
            % cells are tricky - they become linear after slicing, and have
            % to be put back in shape
            v_shift=reshape({v_shift{elements_to_select,:}},nsliced,[]);
        else
            v_shift=v_shift(elements_to_select,:);
        end
        
        attrs.(fn)=shiftdim(v_shift,shift); % shift back
    end
    ds.(attr_fn)=attrs;
    