function joined_nbrhood=cosmo_neighborhood(ds, varargin)
% generate and join neighborhoods
%
% joined_nbrhood=cosmo_neighborhood(ds, [(label, arg)|nbrhood|'-progress',p]...)
%
% Inputs:
%   ds            dataset struct
%   label*, args* label must be a string, either:
%                 - 'sphere' (if ds is fmri-like); args is the radius
%                   for a spherical neighborhood (set to negative to select
%                   at least (-args) features per neighborhood).
%                 - otherwise a dimension label (in ds.a.fdim.labels);
%                   if 'chan' then args are the arguments for
%                   cosmo_meeg_chan_neighborhood, otherwise args is half of
%                   the size of the linear interval around each feature
%   nbrhood*      a neighborhood struct with fields .[f]a and .neighbors,
%                 for example from cosmo_spherical_neighborhood,
%                 cosmo_meeg_chan_neighborhood, or
%                 cosmo_interval_neighborhood.
%   '-progress',p if p is true, then progress is shown
%
% Returns:
%   joined_nbrhood  neighborhood struct with fields .[f]a and .neighbors,
%                   constructed by intersecting the neighborhoods from the
%                   input.
%
% Example:
%     % Illustrate neighborhood by crossing freq and time, with freq
%     % 5 bins wide and time 3 bins wide. Each neighborhood contains all
%     % the channels, repeated up to 5*3=15 times (fewer at the border)
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     freq_nbrhood=cosmo_interval_neighborhood(ds,'freq',3);
%     time_nbrhood=cosmo_interval_neighborhood(ds,'time',5);
%     nbrhood=cosmo_neighborhood(ds, freq_nbrhood, time_nbrhood,...
%                                                    '-progress',false);
%     cosmo_disp(nbrhood.a.fdim)
%     > .values
%     >   { [  2        [  -0.2
%     >        4          -0.15
%     >        6           -0.1
%     >        :          -0.05
%     >       10              0 ]
%     >       12
%     >       14 ]@7x1            }
%     > .labels
%     >   { 'freq'  'time' }
%     cosmo_disp(nbrhood.fa)
%     > .freq
%     >   [ 1         2         3  ...  5         6         7 ]@1x35
%     > .time
%     >   [ 1         1         1  ...  5         5         5 ]@1x35
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1         2         3  ...  9.79e+03  9.79e+03  9.79e+03 ]@1x6120
%     >   [ 1         2         3  ...  1.01e+04  1.01e+04  1.01e+04 ]@1x7650
%     >   [ 1         2         3  ...  1.04e+04  1.04e+04  1.04e+04 ]@1x9180
%     >                                    :
%     >   [ 307       308       309  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x9180
%     >   [ 613       614       615  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x7650
%     >   [ 919       920       921  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x6120 }@35x1
%
% See also: cosmo_spherical_neighborhood, cosmo_meeg_chan_neighborhood,
%           cosmo_interval_neighborhood
%
% NNO Feb 2014


    ndim_max=numel(varargin);

    dims=struct();
    dims.nbrs=cell(1,ndim_max);
    dims.labels=cell(1,ndim_max);
    dims.values=cell(1,ndim_max);
    dims.fa=cell(1,ndim_max);

    show_progress=true;

    % process input
    ndim=0;
    narg=numel(varargin);
    k=0;
    while k<narg
        k=k+1;
        arg=varargin{k};

        if isstruct(arg)
            nbrhood=arg;
            expected_dim_labels=nbrhood.a.fdim.labels;
            ndim=ndim+1;
        elseif ischar(arg)
            % string of dimension label
            dim_label=arg;
            k=k+1;

            nbrhood_args=varargin{k};

            if strcmp(dim_label,'-progress')
                show_progress=nbrhood_args;
                continue
            end

            if ~iscell(nbrhood_args)
                % convert to cell
                nbrhood_args={nbrhood_args};
            end

            % expected dimension label.
            % reset to 'i','j','k' for special case of spherical neighborhood
            expected_dim_labels={dim_label};

            % set neighborhood parameters
            switch dim_label
                case 'sphere'
                    nbrhood_fun=@cosmo_spherical_neighborhood;
                    expected_dim_labels={'i','j','k'};
                case 'chan'
                    nbrhood_fun=@cosmo_meeg_chan_neighborhood;
                otherwise
                    nbrhood_fun=@cosmo_interval_neighborhood;

                    % insert dimension label
                    nbrhood_args=[{dim_label}, nbrhood_args(:)];
            end

            % compute neighborhood
            nbrhood=nbrhood_fun(ds, nbrhood_args{:});
            ndim=ndim+1;
        else
            error('Argument #%d not understood - not string or struct', k);
        end

        if ~isequal(sort(expected_dim_labels(:)),sort(fieldnames(nbrhood.fa)))
            error('Neighborhood labels %s; expected %s',...
                    cosmo_strjoin(expected_dim_labels,', '),...
                    cosmo_strjoin(fieldnames(nbrhood.fa),', '));
        end

        % ensure everything is sorted, as the helper function
        % 'conj_indices' requires that
        for j=1:numel(nbrhood.neighbors)
            if ~issorted(nbrhood.neighbors{j})
                nbrhood.neighbors{j}=sort(nbrhood.neighbors{j});
            end
        end

        dims.nbrs{ndim}=nbrhood.neighbors;
        dims.values{ndim}=nbrhood.a.fdim.values(:);
        dims.labels{ndim}=nbrhood.a.fdim.labels(:);
        dims.fa{ndim}=nbrhood.fa;
    end

    % keep only values for used dimensions
    dims=cosmo_slice(dims,1:ndim,2,'struct');

    % merge labels and values
    dim_labels=[dims.labels{:}];
    dim_values=[dims.values{:}];

    % ensure no duplicate or missing labels
    if ~isequal(sort(dim_labels), unique(dim_labels)) && ...
                    ~(isempty(dim_labels))
        error('Duplicate dimension labels in %s', ...
                    cosmo_strjoin(dim_labels,','));
    elseif ~all(cosmo_match(dim_labels, ds.a.fdim.labels))
        delta=setdiff(dim_labels, ds.a.fdim.labels);
        error('dimension label unknown in dataset: %s', delta{1});
    end


    % optimization: compute conjunctions differently in Matlab and Octave
    is_matlab=cosmo_wtf('is_matlab');

    % compute conjunctions of neighborhoods
    [nbr_idxs, nbr_map_idxs]=conj_indices(dims.nbrs, ...
                                        show_progress, is_matlab);

    % slice feature attributes
    fa_nbrs=cell(ndim,1);
    for k=1:ndim
        fa=dims.fa{k};
        fa_nbrs{k}=cosmo_slice(fa,nbr_map_idxs(k,:),2,'struct');
    end

    joined_nbrhood=struct();
    joined_nbrhood.neighbors=nbr_idxs;
    joined_nbrhood.fa=cosmo_structjoin(fa_nbrs);
    joined_nbrhood.a=ds.a;
    joined_nbrhood.a.fdim=struct();
    joined_nbrhood.a.fdim.values=dim_values;
    joined_nbrhood.a.fdim.labels=dim_labels;



function [flat_idxs, map_idxs]=conj_indices(dim_idxs, show_progress, use_fast)
    % computes conjunction indices
    %
    % Input:
    %   dim_idxs     A NDIMx1 cell, each with X_v cells with indices
    %                As used in this function, dim_idxs{dim}{j} are the
    %                sorted indices with feature attribute for the
    %                dim-th value equal to j.
    %
    % Outputs:
    %   flat_idxs    Nx1 cell values where N=prod(X_*), each of which
    %                has the linear indices of the neighbors of an output
    %                feature.
    %   map_idxs     N*ndim matrix with values in the dim-th column
    %                in the range 1..X_dim. This can be used to index the
    %                values in flat_idxs through sub-indices.

    ndim=numel(dim_idxs);

    % consider first dimension ('head')
    head=dim_idxs{1};
    nhead=numel(head);
    head_map=1:nhead;

    if ndim==1
        % done
        flat_idxs=head;
        map_idxs=head_map;
        return
    end

    % compute indices for remaining dimensions ('tail'), using recursion
    [tail, tail_map]=conj_indices(dim_idxs(2:end), false, use_fast);
    ntail=numel(tail);

    % allocate space for output
    n=nhead*ntail;
    flat_idxs=cell(n,1);
    map_idxs=zeros(ndim,n);

    if show_progress
        prev_msg='';
        clock_start=clock();
    end

    % combine the dimensions
    pos=0;

    for j=1:ntail
        for k=1:nhead
            pos=pos+1;
            headk=head{k};

            if use_fast
                flat_idxs{pos}=fast_intersect(headk, tail{j});
            else
                flat_idxs{pos}=intersect(headk, tail{j});
            end

            map_idxs(1,pos)=head_map(k);
            map_idxs(2:end,pos)=tail_map(:,j);
        end
        if show_progress
            msg=sprintf('MEEG neighbors');
            prev_msg=cosmo_show_progress(clock_start,j/ntail,msg,prev_msg);
        end
    end


function xy=fast_intersect(x,y)
    % finds the intersection between two vectors
    %
    % xy=fast_intersect(x,y)
    %
    % Inputs:
    %   x     numeric vector with elements sorted.
    %   y     "                                  "
    %
    % Returns:
    %   xy    numeric vector containing elements present in both x and y,
    %         without duplicates and with elements sorted.
    %
    % Notes:
    %  - this function runs in O(n) compared to O(n*log(n)) with
    %    n=max(numel(x),numel(y)) for the built-in function 'intersect',
    %    as that function sorts the input data first.
    %  - in matlab it runs a factor 2 or 3 faster
    %  - in Octave it is very very slow for large inputs

    nx=numel(x);
    ny=numel(y);
    n=min(nx,ny); % maximum size possible for output

    xy=zeros(1,n); % allocate space for output

    pos=0; % last position where a value was stored in xy
    xi=1;  % position in x
    yi=1;  % position in y

    while xi<=nx && yi<=ny
        if x(xi)<y(yi)
            xi=xi+1;
        elseif x(xi)>y(yi)
            yi=yi+1;
        else % x(xi)==y(yi); keep the value
            pos=pos+1;
            xy(pos)=x(xi);

            xi=xi+1;
            yi=yi+1;
        end
    end

    xy=xy(1:pos); % only keep stored elements








