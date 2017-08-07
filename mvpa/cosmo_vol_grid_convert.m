function ds_conv=cosmo_vol_grid_convert(ds,varargin)
% convert between volumetric (fmri) and grid-based (meeg source) dataset
%
% ds_conv=cosmo_vol_grid_convert(ds[,direction])
%
% Inputs:
%   ds              dataset struct, either in fmri or meeg source form
%   direction       (optional) conversion direction, either
%                   - 'tovol' : convert to a volumetric (fmri) dataset
%                   - 'togrid': convert to a source (meeg) dataset
%                   If this option is omitted, then 'tovol' is selected if
%                   ds is an meeg source dataset, and 'togrid' otherwise
%
% Output:
%   ds_conv         dataset in volumetric or source format
%
% Example:
%     ds=cosmo_synthetic_dataset('size','normal');
%     % feature attributes are i, j, k
%     cosmo_disp(ds.fa,'edgeitems',2);
%     > .i
%     >   [ 1         2  ...  2         3 ]@1x30
%     > .j
%     >   [ 1         1  ...  2         2 ]@1x30
%     > .k
%     >   [ 1         1  ...  5         5 ]@1x30
%     % fmri dataset has .a.vol
%     cosmo_disp(ds.a,'edgeitems',2);
%     > .fdim
%     >   .labels
%     >     { 'i'
%     >       'j'
%     >       'k' }
%     >   .values
%     >     { [ 1         2         3 ]
%     >       [ 1         2 ]
%     >       [ 1         2         3         4         5 ] }
%     > .vol
%     >   .mat
%     >     [ 2         0         0        -3
%     >       0         2         0        -3
%     >       0         0         2        -3
%     >       0         0         0         1 ]
%     >   .dim
%     >     [ 3         2         5 ]
%     >   .xform
%     >     'scanner_anat'
%     %
%     % convert to get grid representation
%     ds_grid=cosmo_vol_grid_convert(ds,'togrid');
%     % feature attribute is pos
%     cosmo_disp(ds_grid.fa,'edgeitems',2);
%     > .pos
%     >   [ 1        11  ...  20        30 ]@1x30
%     % meeg source dataset has no .a.vol
%     cosmo_disp(ds_grid.a,'edgeitems',2);
%     > .fdim
%     >   .labels
%     >     { 'pos' }
%     >   .values
%     >     { [ -1        -1  ...  3         3
%     >         -1        -1  ...  1         1
%     >         -1         1  ...  5         7 ]@3x30 }
%     %
%     % convert it back to a format identical to the input
%     ds_vol=cosmo_vol_grid_convert(ds_grid,'tovol');
%     %
%     isequal(ds.fa,ds_vol.fa)
%     > true
%     isequal(ds.a.vol.mat,ds_vol.a.vol.mat)
%     > true
%     isequal(ds.a.fdim,ds_vol.a.fdim)
%     > true
%
% Notes:
%   - when ds is an meeg source dataset, it is required that the positions
%     can be placed in a regular grid
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input(ds);
    direction=get_direction(ds,varargin{:});

    switch direction
        case 'tovol'
            ds_conv=convert_grid2vol(ds);

        case 'togrid'
            ds_conv=convert_vol2grid(ds);

        case 'none'
            ds_conv=ds;

        otherwise
            assert(false,'this should not happen');
    end

    cosmo_check_dataset(ds_conv);


function ds_conv=convert_vol2grid(ds)
    % ensure required fields are there
    pos=cosmo_vol_coordinates(ds);
    nfeatures=size(ds.samples,2);


    [idxs,unq_pos_tr]=cosmo_index_unique(pos');
    pos_values=unq_pos_tr';
    pos_fa=zeros(1,nfeatures);
    for k=1:numel(idxs)
        pos_fa(idxs{k})=k;
    end
    assert(all(pos_fa~=0));
    % remove i, j, k fields
    ds_conv=cosmo_dim_remove(ds,{'i','j','k'});

    % remove volumetric field
    ds_conv.a=rmfield(ds_conv.a,'vol');

    % insert position field
    ds_conv=cosmo_dim_insert(ds_conv,2,0,{'pos'},...
                    {pos_values},{pos_fa},'matrix_labels',{'pos'});


function ds_conv=convert_grid2vol(ds)
    pos_label='pos';
    ijk_labels={'i';'j';'k'};

    [dim, index]=cosmo_dim_find(ds,pos_label,true);
    assert(dim==2);
    values=ds.a.fdim.values{index};

    ndim=size(values,1);
    if ndim~=3
        error('''pos'' in .a.fdim.values{%d} must be 3xN',index);
    end

    tolerance=1e-6;
    min_deltas=zeros(ndim,1);
    min_values=zeros(ndim,1);
    dim_sizes=zeros(ndim,1);
    dim_values=cell(ndim,1);

    fa=struct();
    for dim=1:ndim
        % attempt to convert grid to linear space
        vs=values(dim,:);
        unq_vs=unique(vs);

        min_value=min(unq_vs);

        deltas=unique(diff(unq_vs));
        deltas=deltas(deltas>tolerance);

        if numel(deltas)==0
            min_delta=1;
            max_ratio=0;
        else
            min_delta=min(deltas);

            ratios=(unq_vs-min_value)/min_delta;

            max_ratio=round(max(ratios));

            if numel(ratios)~=(1+max_ratio) || ...
                            max(abs(ratios-(0:max_ratio)))>tolerance
                error(['''pos'' in .a.fdim.values{%d}(%d,:) do not '...
                        'follow grid-like structure'],index,dim);
            end
        end
        % store data
        min_deltas(dim)=min_delta;
        min_values(dim)=min_value;
        dim_sizes(dim)=max_ratio+1;

        % convert position to integer in range 1:dim_sizes(dim)
        vs_idxs=1+round((vs-min_value)/min_delta);
        dim_values{dim}=1:dim_sizes(dim);

        % set feature attribute
        ijk_label=ijk_labels{dim};
        fa.(ijk_label)=(vs_idxs(ds.fa.(pos_label)));
    end

    mat=diag([min_deltas;1]);
    mat(1:3,4)=min_values-min_deltas;

    ds_conv=cosmo_dim_remove(ds,'pos');
    ds_conv=cosmo_dim_insert(ds_conv,2,0,ijk_labels,dim_values,fa);
    ds_conv.a.vol.mat=mat;
    ds_conv.a.vol.dim=dim_sizes(:)';

    if cosmo_isfield(ds_conv,'a.meeg.dim')
        ds_conv.a.meeg=rmfield(ds_conv.a.meeg,'dim');
    end



function check_input(ds)
    cosmo_check_dataset(ds);


function tf=ds_has_vol(ds)
    tf=all(cosmo_isfield(ds,{'fa.i','fa.j','fa.k','a.vol.mat'}));

function tf=ds_has_pos(ds)
    tf=cosmo_isfield(ds,'fa.pos');


function direction=get_direction(ds,varargin)
    narg=numel(varargin);

    if narg>1
        error('More than two input arguments are not supported');
    end

    has_direction=narg==1;

    if ds_has_vol(ds)
        guessed_direction='togrid';
    elseif ds_has_pos(ds)
        guessed_direction='tovol';
    else
        error(['Input dataset must either have .fa.pos '...
                    '(for MEEG source), or '...
                    'both fa.{i,j,k} and .a.vol.mat (for fMRI volume)']);
    end

    if has_direction
        direction=varargin{1};

        if ~cosmo_match({direction},{'togrid','tovol'})
            error('direction must be ''togrid'' or ''tovol''');
        end

        if ~strcmp(direction,guessed_direction)
            direction='none';
        end
    else
        direction=guessed_direction;
    end

