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
%
% Output:
%      is_ok                true if nbrhood is kosher, false otherwise
%
%
% Examples:
%     ds=cosmo_synthetic_dataset();
%     nbrhood=cosmo_spherical_neighborhood(ds,1,'progress',false);
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
% NNO Dec 2014

    raise=true;
    is_ok=false;
    for k=1:numel(varargin)
        if islogical(varargin{k})
            raise=varargin{k};
        end
    end


    checkers={@check_basis,@check_neighbors};
    for j=1:numel(checkers)
        checker=checkers{j};
        msg=checker(nbrhood);
        if ~isempty(msg)
            if raise
                error(msg);
            end
            return
        end
    end

    % treat like dataset
    nfeatures=numel(nbrhood.neighbors);
    nbrhood=rmfield(nbrhood,'neighbors');
    nbrhood.samples=zeros(0,nfeatures);

    is_ok=cosmo_check_dataset(nbrhood,raise);


function msg=check_basis(nbrhood)
    msg='';
    if ~isstruct(nbrhood)
        msg='neighborhood is not a struct';
        return
    end

    keys={'neighbors','fa','a'};
    delta=setxor(fieldnames(nbrhood),keys);
    if ~isempty(delta)
        first=delta{1};
        if isfield(nbrhood,first)
            msg=sprintf('field ''%s'' not allowed in neighborhood',first);
        else
            msg=sprintf('field ''%s'' missing in neighborhood',first);
        end
        return
    end


function tf=is_positive_int_row_vector(x)
    tf=isempty(x) || ...
            (isrow(x) && min(x)>=1 && all(round(x)==x));


function msg=check_neighbors(nbrhood)
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

    m=cellfun(@is_positive_int_row_vector,nbrs);
    if any(~m)
        i=find(~m,1);
        msg=sprintf('.neighbors{%d} is not a row vector with integers',i);
        return;
    end


function msg=check_dataset_like(nbrhood)







