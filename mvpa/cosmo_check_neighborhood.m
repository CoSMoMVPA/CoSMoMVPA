function is_ok=cosmo_check_neighborhood(nbrhood,varargin)
% check that a neighborhood is kosher
%
% is_ok=cosmo_check_neighborhood(nbrhood,[raise])
%
% Inputs:
%     nbrhood               neighborhood struct, for example from
%                           cosmo_spherical_neighborhood,
%                           cosmo_surficial_neighborhood,
%                           surfing_interval_neighborhood, or
%                           cosmo_meeg_chan_neighborhood
%      raise                (optional) if set to true (the default), an
%                           error is thrown if nbrhood is not kosher
%      'show_warning',w   If true (the default), then a warning is shown
%                           if nbrhood has no origin
%
% Output:
%      is_ok                true if nbrhood is kosher, false otherwise
%
%
% Examples:
%     ds=cosmo_synthetic_dataset();
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     cosmo_check_neighborhood(nbrhood)
%     > true
%     %
%     cosmo_check_neighborhood(2)
%     > error('neighborhood is not a struct')
%     %
%     % error can be silenced
%     cosmo_check_neighborhood(2,false)
%     > false
%     %
%     fa=nbrhood.fa;
%     nbrhood=rmfield(nbrhood,'fa');
%     cosmo_check_neighborhood(nbrhood)
%     > error('field ''fa'' missing in neighborhood')
%     %
%     nbrhood.fa=fa;
%     nbrhood.neighbors{2}=-1;
%     cosmo_check_neighborhood(nbrhood)
%     > error('.neighbors{2} is not a row vector with integers')
%     %
%     nbrhood.neighbors{2}=[1];
%     nbrhood.fa.chan=[3 2 1];
%     cosmo_check_neighborhood(nbrhood)
%     > error('fa.chan has 3 values in dimension 2, expected 6')
%
% See also: cosmo_spherical_neighborhood, surfing_interval_neighborhood
%           cosmo_surficial_neighborhood, cosmo_meeg_chan_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    [raise, ds, show_warning]=process_input(varargin{:});

    is_ok=false;

    checkers={@check_basis,...
                @check_neighbors,...
                @check_origin_matches};


    for j=1:numel(checkers)
        checker=checkers{j};
        msg=checker(nbrhood, ds, show_warning);
        if ~isempty(msg)
            if raise
                error([func2str(checker) ': ' msg]);
            end
            return
        end
    end


    % treat like dataset
    nfeatures=numel(nbrhood.neighbors);
    nbrhood=rmfield(nbrhood,'neighbors');

    if isfield(nbrhood,'fa')
        nbrhood.samples=zeros(0,nfeatures);
    else
        nbrhood.samples=zeros(nfeatures,0);
    end

    if isfield(nbrhood,'origin')
        nbrhood=rmfield(nbrhood,'origin');
    end

    is_ok=cosmo_check_dataset(nbrhood,raise);


function [infix, absent_infix]=get_attr_infix(nbrhood)
    m=cosmo_match({'sa','fa'},fieldnames(nbrhood));
    if sum(m)~=1
        error('exactly one of .sa or .fa must be present');
    end

    if m(1)
        infix='s';
        absent_infix='f';
    else
        infix='f';
        absent_infix='s';
    end

function msg=check_basis(nbrhood, ds, show_warning)
    msg='';
    if ~isstruct(nbrhood)
        msg='neighborhood is not a struct';
        return
    end

    keys={'neighbors','a','fa','sa','origin'};
    delta=setdiff(fieldnames(nbrhood),keys);
    if ~isempty(delta)
        first=delta{1};
        msg=sprintf('field ''%s'' not allowed in neighborhood',first);
        return
    end

    if ~isfield(nbrhood,'neighbors')
        error('missing field .neighbors');
    end


function tf=is_positive_int_row_vector(x)
    tf=isempty(x) || ...
            (isrow(x) && min(x)>=1 && all(round(x)==x));


function msg=check_neighbors(nbrhood, ds, show_warning)
    msg='';

    nbrs=nbrhood.neighbors;

    if ~iscell(nbrs)
        msg='.neighbors is not a cell';
        return;
    end

    if size(nbrs,2)~=1
        msg='.neighbors is not of size Kx1';
        return;
    end


    has_dataset=~isempty(ds);
    if has_dataset
        infix=get_attr_infix(nbrhood);
        switch infix
            case 's'
                dim=1;
            case 'f'
                dim=2;
        end

        max_feature=size(ds.samples,dim);
    else
        max_feature=Inf;
    end

    for j=1:numel(nbrs)
        nbr=nbrs{j};

        if any(nbr>max_feature)
            msg=sprintf(['.neighbors{%d} exceeds the number '...
                            'of features (%d) in the dataset']',...
                                j, max_feature);
            return
        end

        if ~is_positive_int_row_vector(nbr)
            msg=sprintf('.neighbors{%d} is not an integer row vector',j);
            return;
        end
    end


function msg=check_origin_matches(nbrhood, ds, show_warning)
    msg='';

    % legacy neighborhood, do not throw an exception
    if show_warning && ~isfield(nbrhood,'origin')
        cosmo_warning(['Legacy warning: newer versions of CoSMoMVPA '...
                        'require a field .origin in the neighborhood '...
                        'struct']);
        return;
    end

    if isempty(ds)
        % no dataset, so no further checks
        return;
    end

    origin=nbrhood.origin;


    [infix, absent_infix]=get_attr_infix(nbrhood);


    dim_name=[infix 'dim'];

    if isfield(origin, 'a')
        origin_a=origin.a;
        if isfield(ds,'a')
            ds_a=ds.a;

            if isfield(ds_a,dim_name)
                if isfield(origin_a,dim_name)
                    msg=check_xdim_matches(origin_a.(dim_name), ...
                                            ds_a.(dim_name), ...
                                            dim_name);
                    if ~isempty(msg)
                        return;
                    end

                    msg=check_xa_matches(origin,ds,infix);
                    if ~isempty(msg)
                        return;
                    end

                    origin_a=rmfield(origin_a,dim_name);
                end
                ds_a=rmfield(ds_a,dim_name);
            end

            if ~isequaln(origin_a, ds_a)
                error('.a mismatch between dataset and neighborhood');
            end
        end
    end

function msg=check_xa_matches(origin,ds,infix)
    msg='';
    attr_name=[infix 'a'];
    dim_name=[infix 'dim'];
    keys=origin.a.(dim_name).labels;

    for k=1:numel(keys)
        key=keys{k};

        if ~cosmo_isfield(origin,[attr_name '.' key]) || ...
                ~isequaln(ds.(attr_name).(key),...
                        origin.(attr_name).(key))
            msg=sprintf(['.%sa.%s mismatch between dataset and '...
                    'neighborhood'],infix,key);
            return
        end
    end


function msg=check_xdim_matches(origin_xdim, ds_xdim, dim_name)
    msg='';
    keys=fieldnames(ds_xdim);
    if ~isequal(sort(keys),sort(fieldnames(origin_xdim)))
        msg=sprintf(['.a.%s key mismatch between dataset '...
                    'and neighborhood'], dim_name);
                return;
    end

    for k=1:numel(keys)
        key=keys{k};

        origin_v=origin_xdim.(key);
        ds_v=ds_xdim.(key);

        if ~(iscell(origin_v) && iscell(ds_v))
            msg=sprintf('.a.%s ''%s'' must be a cell',...
                                    dim_name, key);
            return
        end

        if numel(origin_v)~=numel(ds_v)
            msg=sprintf(['.a.%s size mismatch between ',...
                            'dataset and neighborhood'],...
                                    dim_name, key);
            return
        end

        for j=1:numel(origin_v)
            if ~(isequaln(origin_v{j},ds_v{j}) || ...
                            isequaln(origin_v{j},ds_v{j}'))
                msg=sprintf(['.a.%s ''%s'' value mismatch '...
                            'between dataset and neighborhood'], ...
                                    dim_name, key);
                return
            end
        end
    end


function [raise, ds, show_warning]=process_input(varargin)
    raise=true;
    ds=[];
    show_warning=true;

    narg=numel(varargin);
    k=0;
    while k<narg
        k=k+1;
        arg=varargin{k};

        if islogical(arg)
            raise=arg;
        elseif isstruct(arg)
            ds=arg;
            cosmo_check_dataset(ds);
        elseif ischar(arg)
            if k==narg
                error('missing argument after ''show_warning''');
            end
            switch arg
                case 'show_warning'
                    k=k+1;
                    show_warning=varargin{k};
                otherwise
                    error('illegal argument at position %d', k);
            end
        end
    end


