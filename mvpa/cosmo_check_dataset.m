function is_ok=cosmo_check_dataset(ds, ds_type, error_if_not_ok)
% Checks consistency of a dataset. By default throws an error when not.
%
%
% is_ok=cosmo_dataset_check(ds, [ds_type,][,error_if_not_present])
%
% Inputs:
%   ds                     dataset struct.
%   ds_type                string indicating the specific type of dataset.
%                          Currently  supports 'fmri' and 'meeg'.
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
%                          - if ds_type is provided, then some more tests
%                            (depending on ds_type) are performed.
%
% Note:
%  - if the second argument is a boolean then its value is used for
%    error_if_not_ok, and ds_type is not checked
%  - this function throws one error at most, even if it is inconsistent for
%    several reasons.
%  - it is good practice to use this function when a new dataset is created
%    to ensure consistency of the data
%
% NNO Sep 2013

    % deal with input arguments
    if nargin>=2
        if islogical(ds_type)
            error_if_not_ok=ds_type;
            ds_type=[];
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

    % use a for-loop with 'break' statements to simulate a GOTO statement
    % so that after the first error the loop is quit
    while true
        if ~isstruct(ds)
            msg='dataset not a struct'; break
        end

        if  ~isfield(ds,'samples')
            msg='dataset has no field .samples'; break
        end

        % has samples, so check the rest
        ds_size=size(ds.samples);
        if numel(ds_size) ~=2,
            msg='.samples should be 2D'; break
        end

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
                        break;
                    end
                    if attr_size(dim) ~= ds_size(dim)
                        msg=sprintf(['%s.%s has %d values in dimension %d, ',...
                                    'expected %d'], attrs_fn, fn,...
                                    attr_size(dim), dim, ds_size(dim));
                        break;
                    end
                end

                % break out of loop if msg is set
                if ~isempty(msg), break; end
            end
        end

        % break out of loop if msg is set
        if ~isempty(msg), break; end

        % if provided, check for this specific type
        if ~isempty(ds_type)
            msg=check_dim(ds);
            if ~isempty(msg), break; end

            switch ds_type
                case 'fmri'
                    names={'i','j','k'};
                case 'surface'
                    names={'node_indices'};
                case 'meeg'
                    names={};
                    if ~isfield(ds.a,'meeg')
                        msg='missing field .a.meeg';
                    end
                otherwise
                    error('Unsupported ds_type=%s', ds_type);
            end

            m=cosmo_match(names,ds.a.dim.labels);
            if ~all(m)
                i=find(~m,1);
                msg=sprintf('''%s''-dataset has not dim field %s',...
                                ds_type,names{i});
                break;
            end
        end

        % quit the while loop
        break;
    end

    % throw the error if neccessary
    is_ok=isempty(msg);
    if ~is_ok && error_if_not_ok
        error(msg);
    end


function msg=check_dim(ds)
% helper function

    msg='';
    if ~isfield(ds,'a') || ...
            ~isfield(ds.a,'dim') || ...
            ~isfield(ds.a.dim,'labels') || ...
            ~isfield(ds.a.dim,'values')
        msg='missing field .a.dim.{labels,values}';
        return
    end

    ndim=numel(ds.a.dim.labels);
    if numel(ds.a.dim.values)~=ndim
        msg='size mismatch between .a.dim.labels and .a.dim.values';
        return
    end

    if ~isfield(ds,'fa')
        msg='no field .fa';
        return
    end

    names=ds.a.dim.labels;
    for k=1:numel(names);
        name=names{k};
        if ~isfield(ds.fa,name)
            msg=sprintf('missing field .fa.%s',name);
            return
        end
        vs=ds.fa.(name);

        nv=numel(ds.a.dim.values{k});
        if min(vs)<1 || max(vs>nv) || ~isequal(round(vs),vs)
            msg=sprintf('.fa.%s must have integers in range 1..%d',...
                            name,nv);
            return
        end
    end




