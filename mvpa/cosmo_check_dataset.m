function is_ok=cosmo_check_dataset(ds, ds_type, error_if_not_ok)
% Check consistency of a dataset.
%
%
% is_ok=cosmo_dataset_check(ds, [ds_type,][,error_if_not_ok])
%
% Inputs:
%   ds                     dataset struct.
%   ds_type                string indicating the specific type of dataset.
%                          Currently  supports 'fmri' and 'meeg'.
%   error_if_not_ok        if true (the default) or a string, an error is
%                          raised if the dataset is not kosher (see below).
%                          If a string, then it is prefixed in the error
%                          message. If false, then no error is raised.
%
% Returns:
%   is_ok                  boolean indicating kosherness of ds.
%                          It is consider ok if:
%                          - it has a field .samples with a PxQ array.
%                          - if it has a field .features [.samples], then
%                            it should be a struct, and each field in it
%                            should have P [Q] elements along the first
%                            [second] dimension or be empty.
%                          - .sa.{targets,chunks} are numeric vectors with
%                            integers (if present)
%                          - if ds_type is provided, then some more tests
%                            (depending on ds_type) are performed.
%
% Examples:
%     cosmo_check_dataset([])
%     > error('dataset not a struct')
%
%     cosmo_check_dataset(struct())
%     > error('dataset has no field .samples')
%
%     % this (very minimal) dataset is kosher
%     cosmo_check_dataset(struct('samples',zeros(2)))
%     > true
%
%     % error can be silenced
%     cosmo_check_dataset('this is not ok',false)
%     > false
%
%     % run some more tests
%     ds=cosmo_synthetic_dataset('type','fmri');
%     cosmo_check_dataset(ds)
%     > true
%     ds.sa.chunks=[2;3]; % wrong size
%     cosmo_check_dataset(ds)
%     > error('sa.chunks has 2 values in dimension 1, expected 6')
%     ds.sa.chunks={'a','b','c','a','b','c'}';
%     cosmo_check_dataset(ds)
%     > error('.sa.chunks must be numeric vector with integers')
%
%     % set illegal dimension values
%     ds=cosmo_synthetic_dataset('type','fmri');
%     ds.a.fdim.values{1}=[1 2];
%     cosmo_check_dataset(ds)
%     > error('.fa.i must be vector with integers in range 1..2')
%
%     % check for specific type of dataset
%     ds=cosmo_synthetic_dataset('type','fmri');
%     cosmo_check_dataset(ds,'meeg')
%     > error('missing field .a.meeg for meeg-dataset');
%
%     % destroy crucial information in fmri dataset
%     % this error is only caught if explicit checking for fmri dataset is
%     % enabled, because the dataset remains valid when considered as a
%     % non-fmri dataset
%     ds=cosmo_synthetic_dataset('type','fmri');
%     % destroy volume information
%     ds.a=rmfield(ds.a,'vol');
%     cosmo_check_dataset(ds)
%     > true  % error not caught
%     cosmo_check_dataset(ds,'fmri')
%     > error('missing field .a.vol for fmri-dataset')
%
%     % check meeg dataset
%     ds=cosmo_synthetic_dataset('type','meeg');
%     cosmo_check_dataset(ds,'meeg')
%     > true
%     ds.fa.chan=ds.fa.chan+6; % outside range
%     cosmo_check_dataset(ds)
%     > error('.fa.chan must be vector with integers in range 1..3')
%
% Notes:
%  - if the second argument is a boolean then its value is used for
%    error_if_not_ok, and ds_type is not used
%  - this function throws one error at most, even if it is inconsistent for
%    several reasons.
%  - it is good practice to use this function when a new dataset is created
%    to ensure consistency of the data
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % deal with input arguments
    if nargin<3
        error_if_not_ok=true;
    end
    if nargin>=2
        if islogical(ds_type)
            error_if_not_ok=ds_type;
            ds_type=[];
        end
    else
        ds_type=[];
        error_if_not_ok=true;
    end

    if ischar(error_if_not_ok)
        error_prefix=error_if_not_ok;
        error_if_not_ok=true;
    else
        error_prefix='';
    end


    % list check functions
    checkers={@check_fields,...
              @check_samples,...
              @check_targets,...
              @check_chunks,...
              @check_attributes,...
              @check_dim_legacy,...
              @check_dim,...
              []}; % space for check_with_type

    if ~isempty(ds_type)
        % add checker for specific type (fmri, meeg, surface)
        checkers{end}=@(x) check_with_type(x,ds_type);
    end

    msg=run_checkers(checkers,ds);
    is_ok=isempty(msg);

    if ~is_ok && error_if_not_ok
        error('%s: %s', error_prefix, msg);
    end

function msg=run_checkers(checkers,ds)
    n=numel(checkers);
    msg='';
    for k=1:n
        checker=checkers{k};
        if isempty(checker)
            continue;
        end
        msg=checker(ds);
        if ~isempty(msg)
            return
        end
    end

function msg=check_with_type(ds, ds_type)
    % additional checks for fmri, surface or meeg dataset

    % note: check_dim should have already checked that
    % all fields are present in .fa

    msg='';
    switch ds_type
        case 'fmri'
            required_dim_labels={'i','j','k'};
            a_fields={'vol'};
        case 'surface'
            required_dim_labels={'node_indices'};
            a_fields={};
        case 'meeg'
            required_dim_labels={};
            a_fields={'meeg'};
        otherwise
            error('Unsupported ds_type=%s', ds_type);
    end

    % check present of field
    cosmo_isfield(ds, 'a.fdim', true);

    m=cosmo_match(required_dim_labels,ds.a.fdim.labels);
    if any(~m)
        i=find(~m,1);
        msg=sprintf('missing value %s in .a.fdim.values for %s-dataset',...
                    required_dim_labels{i}, ds_type);
        return
    end

    a_fns=fieldnames(ds.a);
    m=cosmo_match(a_fields,a_fns);
    if any(~m)
        i=find(~m,1);
        msg=sprintf('missing field .a.%s for %s-dataset',...
                    a_fields{i}, ds_type);
        return
    end

function tf=is_int_vector(x)
    tf=isnumeric(x) && isvector(x) && all(round(x)==x | isnan(x));


function msg=check_dim_legacy(ds)
    msg='';

    if cosmo_isfield(ds,'a.dim')
        msg=sprintf(['***CoSMoMVPA legacy***\n'...
                'Feature dimension information is now stored '...
                'in .a.fdim, whereas earlier versions used .a.dim. '...
                'To adapt a existing dataset struct ''ds'', run:\n'...
                '  ds.a.fdim=ds.a.dim;\n'...
                '  ds.a=rmfield(ds.a,''dim'')\n']);
        return;
    end


function msg=check_fields(ds)
    msg='';

    if ~isstruct(ds)
        msg='input must be a struct';
        return;
    end

    delta=setdiff(fieldnames(ds),{'samples','fa','sa','a'});
    if ~isempty(delta)
        msg=sprintf('illegal field .%s', delta{1});
        return
    end


function msg=check_targets(ds)
    msg='';

    if cosmo_isfield(ds,'sa.targets') && ~is_int_vector(ds.sa.targets)
        msg=['.sa.targets must be numeric vector with integers '...
                    '(.sa.labels can be used to store string labels)'];
    end

function msg=check_chunks(ds)
    msg='';

    if cosmo_isfield(ds,'sa.chunks') && ~isnumeric(ds.sa.chunks)
        msg='.sa.chunks must be numeric vector with integers';
    end

function msg=check_samples(ds)
    msg='';

    if  ~isfield(ds,'samples')
        msg='dataset has no field .samples';
        return
    end

    % has samples, so check the rest
    ds_size=size(ds.samples);
    if numel(ds_size) ~=2,
        msg=sprintf('.samples should be 2D, found %dD', numel(ds_size));
        return
    end

function msg=check_attributes(ds)
    msg='';
    attrs_fns={'sa','fa'};
    ds_size=size(ds.samples);

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
                    return
                end
                if attr_size(dim) ~= ds_size(dim)
                    msg=sprintf(['%s.%s has %d values in dimension '...
                                '%d, expected %d'], attrs_fn, fn,...
                                attr_size(dim), dim, ds_size(dim));
                    if attr_size(3-dim) == ds_size(dim)
                        msg=[msg ' (maybe the data was intended '...
                                'to be transposed?)'];
                    end
                    return
                end
            end
        end
    end



function msg=check_dim(ds)
    % helper function to check dataset with dimensions
    % (i.e., .a.{s,f}dim is present)
    msg='';

    suffixes='sf';

    for dim=1:2
        suffix=suffixes(dim);
        dim_attrs_str=sprintf('a.%sdim',suffix);

        if ~cosmo_isfield(ds,dim_attrs_str)
            continue;
        end

        attrs_str=[suffix 'a'];
        if ~isfield(ds, attrs_str)
            msg=sprintf('Missing field .%s',attrs_str);
            return
        end

        attrs=ds.(attrs_str);
        dim_attrs=ds.a.([suffix 'dim']);
        msg=check_dim_helper(attrs, dim_attrs, attrs_str, dim_attrs_str);

        if ~isempty(msg)
            return
        end
    end


function msg=check_dim_helper(attrs, dim_attrs, attrs_str, dim_attrs_str)
    msg='';
    % attrs is from .sa or .fa; dim_attrs from .a.sdim or .a.fdim
    % the *_str arguments contain a string representation
    if ~all(cosmo_isfield(dim_attrs,{'labels','values'}))
        msg=sprintf('Missing field .%s.{labels,values}',dim_attrs_str);
        return;
    end

    labels=dim_attrs.labels;
    values=dim_attrs.values;

    if ~iscellstr(labels)
        msg=sprintf('.%s.labels must be a cell', dim_attrs_str);
        return
    end

    if ~iscell(values)
        msg=sprintf('.%s.values must be a cell', dim_attrs_str);
        return
    end

    ndim=numel(labels);
    if numel(values)~=ndim
        msg=sprintf('size mismatch between .%s.labels and .%s.values',...
                  dim_attrs_str,dim_attrs_str);
        return
    end

    for dim=1:ndim
        label=labels{dim};
        if ~isfield(attrs, label)
            msg=sprintf('Missing field .%s.%s', attrs_str, label);
            return
        end
        v=attrs.(label);

        % empty vectors are allowed (in empty datasets)
        if isempty(v)
            continue
        end

        vmax=numel(values{dim});
        all_int=is_int_vector(v);
        if ~all_int || min(v)<1 || max(v)>vmax
            msg=sprintf(['.%s.%s must be vector with integers in '...
                            'range 1..%d'],attrs_str,label,vmax);
            if all_int && min(v)==0
                % could be mistaken base-0 indexing
                msg=sprintf(['%s\nThe lowest index is 0, which may '...
                            'indicate base-0 indexing (the first '...
                            'element is indexed by 0). Note that '...
                            'Matlab (and CoSMoMVPA) use base-1 '...
                            'indexing. Conversion from base-0 to '...
                            'base-1 can be achieved by increasing '...
                            'the values in .%s.%s by 1.'],...
                            msg,attrs_str,label);
            end

            return
        end
    end
