function crossed_nbrhood=cosmo_cross_neighborhood(ds, nbrhoods, varargin)
% cross neighborhoods along dataset dimensions
%
% crossed_nbrhood=cosmo_cross_neighborhood(ds,nbrhoods,...)
%
% Inputs:
%   ds            dataset struct
%   nbrhoods      1xK cell with neighborhood structs. Each element can be
%                 the output from cosmo_spherical_neighborhood,
%                 cosmo_meeg_chan_neighborhood,
%                 cosmo_surficial_neighborhood, or
%                 cosmo_interval_neighborhood.
%   'progress',p  if p is true, then progress is shown
%
% Returns:
%   crossed_nbrhood neighborhood struct with fields .[f]a and .neighbors,
%                   constructed by intersecting the neighborhoods from the
%                   input.
%
% Example:
%     % Illustrate neighborhood by crossing freq and time, with freq
%     % 5 bins wide and time 3 bins wide. Each neighborhood contains all
%     % the channels, repeated up to 5*3=15 times (fewer at the border)
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     freq_nbrhood=cosmo_interval_neighborhood(ds,'freq','radius',3);
%     time_nbrhood=cosmo_interval_neighborhood(ds,'time','radius',5);
%     nbrhood=cosmo_cross_neighborhood(ds, {freq_nbrhood, time_nbrhood},...
%                                                    'progress',false);
%     cosmo_disp(nbrhood.a.fdim)
%     > .values
%     >   { [ 2         4         6  ...  10        12        14 ]@1x7
%     >     [ -0.2     -0.15      -0.1     -0.05         0 ]           }
%     > .labels
%     >   { 'freq'
%     >     'time' }
%     cosmo_disp(nbrhood.fa)
%     > .freq
%     >   [ 1         2         3  ...  5         6         7 ]@1x35
%     > .time
%     >   [ 1         1         1  ...  5         5         5 ]@1x35
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1   2   3  ...  9.79e+03  9.79e+03  9.79e+03 ]@1x6120
%     >   [ 1   2   3  ...  1.01e+04  1.01e+04  1.01e+04 ]@1x7650
%     >   [ 1   2   3  ...  1.04e+04  1.04e+04  1.04e+04 ]@1x9180
%     >                                    :
%     >   [ 307 308 309  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x9180
%     >   [ 613 614 615  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x7650
%     >   [ 919 920 921  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x6120 }@35x1
%
% See also: cosmo_spherical_neighborhood, cosmo_meeg_chan_neighborhood,
%           cosmo_interval_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_check_dataset(ds);
    check_nbrhoods(nbrhoods,ds);

    default.progress=1000;
    opt=cosmo_structjoin(default, varargin{:});

    ndim=numel(nbrhoods);

    dims=struct();
    dims.nbrs=cell(1,ndim);
    dims.labels=cell(1,ndim);
    dims.values=cell(1,ndim);
    dims.fa=cell(1,ndim);

    for k=1:ndim
        nbrhood=ensure_sorted(nbrhoods{k});

        dims.nbrs{k}=nbrhood.neighbors;
        dims.values{k}=nbrhood.a.fdim.values(:);
        dims.labels{k}=nbrhood.a.fdim.labels(:);
        dims.fa{k}=nbrhood.fa;
    end

    % merge labels and values
    dim_labels=cat(1,dims.labels{:});
    dim_values=cat(1,dims.values{:});

    ds_labels=ds.a.fdim.labels;

    % check labels
    check_labels(dim_labels,ds_labels);

    % optimization: compute conjunctions differently in Matlab and Octave
    is_matlab=cosmo_wtf('is_matlab');

    % compute conjunctions of neighborhoods
    [nbr_idxs, nbr_map_idxs]=conj_indices(dims.nbrs, ...
                                        opt.progress, is_matlab);

    % slice feature attributes
    fa_nbrs=cell(ndim,1);
    for k=1:ndim
        fa=dims.fa{k};
        fa_nbrs{k}=cosmo_slice(fa,nbr_map_idxs(k,:),2,'struct');
    end

    crossed_nbrhood=struct();
    crossed_nbrhood.neighbors=nbr_idxs;
    crossed_nbrhood.fa=cosmo_structjoin(fa_nbrs);
    crossed_nbrhood.a=ds.a;
    crossed_nbrhood.a.fdim=struct();
    crossed_nbrhood.a.fdim.values=dim_values;
    crossed_nbrhood.a.fdim.labels=dim_labels;

    origin=struct();
    origin.a=ds.a;
    origin.fa=ds.fa;
    crossed_nbrhood.origin=origin;


function check_nbrhoods(nbrhoods,ds)
    if ~iscell(nbrhoods)
        error(['second argument must a be cell of the form '...
                '{nbrhood1, nbrhood2, ...}, where each nbrhood* '...
                'is a neighborhood structure']);
    end

    for k=1:numel(nbrhoods)
        nbrhood=nbrhoods{k};
        cosmo_check_neighborhood(nbrhood,ds);
    end




function nbrhood=ensure_sorted(nbrhood)
    % ensure everything is sorted, as the helper function
    % 'conj_indices' requires that
    for j=1:numel(nbrhood.neighbors)
        if ~issorted(nbrhood.neighbors{j})
            nbrhood.neighbors{j}=sort(nbrhood.neighbors{j});
        end
    end

function check_labels(dim_labels,ds_labels)
    % ensure no duplicate or missing labels
    if ~isequal(sort(dim_labels), unique(dim_labels)) && ...
                    ~(isempty(dim_labels))
        error('Duplicate dimension labels in %s', ...
                    cosmo_strjoin(dim_labels,','));
    elseif ~all(cosmo_match(dim_labels, ds_labels))
        delta=setdiff(dim_labels, ds_labels);
        error('dimension label unknown in dataset: %s', delta{1});
    end

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
            msg=sprintf('crossing neighborhoods');
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
