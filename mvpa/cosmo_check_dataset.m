function is_ok=cosmo_check_dataset(ds, ds_type, error_if_not_ok)
% Checks consistency of a dataset. By default throws an error when not.
%
%
% is_ok=cosmo_dataset_check(ds, [ds_type,][,error_if_not_present])
%
% Inputs:
%   ds                     dataset struct.
%   ds_type                string indicating the specific type of dataset. 
%                          Currently  only supports 'fmri'.
%   error_if_not_present   if true (the default), an error is raised if the
%                          dataset is not kosher (see below).
%
% Returns:
%   is_ok                  boolean indicating kosherness of ds.
%                          It is consider ok if:
%                          - it has a field .samples with a PxQ array.
%                          - if it has a field .features [.samples], then
%                            it should be a struct, and each field in it
%                            should have P [Q] elements along the first
%                            [second] dimension or be empty.
%
% Note:
%  - if the second argument is a boolean then its value is used for
%    error_if_not_ok, and ds_type is not checked
%  - this function throws one error at most, even if it is inconsistent for
%    several reasons.
%
% NNO Sep 2013

% deal with input arguments
if nargin>=2
    if islogical(ds_type)
        ds_type=[];
        error_if_not_ok=ds_type;
    else
        if nargin<3 || isempty(error_if_not_ok)
            error_if_not_ok=true;
        end
    end
else
    ds_type=[];
    error_if_not_ok=true;
end

% error message. If empty at the end of this function, then ds is ok.
msg=''; 
if ~isstruct(ds), msg='dataset is not a struct'; end
if ~isfield(ds,'samples'), msg='no samples'; end

ds_size=size(ds.samples);
if numel(ds_size) ~=2, msg='.samples should be 2D'; end

attrs_fns={'sa','fa'};

% check sample and feature attributes
for dim=1:2
    attrs_fn=attrs_fns{dim};
    if isfield(ds, attrs_fn);
        
        % get feature/sample attributes
        attrs=ds.(attrs_fn);
        fns=fieldnames(attrs);
        n=numel(fns);
        
        % check each one
        for j=1:n
            fn=fns{j};
            attr=attrs.(fn);
            if isempty(attr)
                continue;
            end
            attr_size=size(attr);
            if numel(attr_size) ~= 2
                msg=sprintf('%s.%s should be 2D', attrs_fn, fn);
            end
            if attr_size(dim) ~= ds_size(dim)
                msg=sprintf(['%s.%s has %d values in %-th dimension, ',...
                            'expected %d'], attrs_fn, fn,... 
                            attr_size(dim), dim, ds_size(dim));
            end
        end
    end
end

% if provided, check for this specific type
if ~isempty(ds_type)
    switch ds_type
        case 'fmri'
            if ~isfield(ds,'a') || ...
                    ~isfield(ds.a,'vol') || ~isfield(ds.a.vol,'dim')
                msg='missing field .a.vol.dim';
            end
            
            if ~isfield(ds,'fa') || ~isfield(ds.fa,'voxel_indices')
                msg='missing field ds.fa.voxel_indices';
            end
               
        otherwise
            error('unsupported ds_type: %s', ds_type);
    end
end

% throw the error if neccessary
is_ok=isempty(msg);
if ~is_ok && error_if_not_ok
    error(msg);
end


