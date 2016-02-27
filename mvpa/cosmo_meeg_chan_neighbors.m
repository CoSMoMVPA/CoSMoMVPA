function neighbors=cosmo_meeg_chan_neighbors(ds, varargin)
% find neighbors of MEEG channels
%
% neighbors=cosmo_meeg_chan_neighbors(ds, ...)
%
% Inputs:
%   ds                  MEEG dataset struct
%   'label', lab        Labels to return in output, one of:
%                       'layout'    : determine neighbors based on layout
%                                     associated with ds (default). All
%                                     labels in the layout are used as
%                                     center labels.
%                       'dataset'   : determine neighbors based on labels
%                                     present in ds. Only labels present in
%                                     ds are used as center labels
%                       {x1,...,xn} : use labels x1 ... xn
%   'chantype', tp      (optional) channel type of neighbors, can be one of
%                       'eeg', 'meg_planar', 'meg_axial', or
%                       'meg_combined_from_planar'.
%                       Use 'all' to use all channel types associated with
%                       lab, and 'all_combined' to use
%                       'meg_combined_from_planar' with all other channel
%                       types in ds except for 'meg_planar'.
%                       If there is only one channel type associated with
%                       lab, then this argument is not required.
%   'radius', r         } select neighbors either within radius r, grow
%   'count', c          } the radius to get neighbors are c locations,
%   'delaunay', true    } or use Delaunay triangulation to find direct
%                       } neighbors for each channel.
%                       } These three options are mutually exclusive
%
%
% Output:
%   neighbors           Kx1 struct for K center labels, with fields:
%     .label            center label
%     .neighblabel      cell with labels of neighbors
%
% Examples:
%     % get neighbors within radius of .3 for EEG dataset
%     ds=cosmo_synthetic_dataset('type','meeg',...
%                                        'sens','eeg1010','size','big');
%     % show all channel labels
%     cosmo_disp(ds.a.fdim.values{1});
%     > { 'TP10'  'TP7'  'TP8' ... 'A2'  'M1'  'M2'   }@1x94
%     %
%     % simulate the case where some channels are missing; here, every 7-th
%     % channels is removed
%     ds=cosmo_slice(ds,mod(ds.fa.chan,7)~=2,2);
%     ds=cosmo_dim_prune(ds);
%     %
%     % show remaining channel labels
%     cosmo_disp(ds.a.fdim.values{1});
%     > { 'TP10'  'TP8'  'TP9' ... 'A1'  'A2'  'M2'   }@1x80
%     %
%     % get neighbors for the channel layout associated with this
%     % dataset. This layout ('EEG1010.lay') has 88 channel positions,
%     % of which the last two are ignored because they are 'COMNT' and
%     % 'SCALE'
%     nbrs=cosmo_meeg_chan_neighbors(ds,'radius',.3);
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@86x1
%     >    (1,1) .label
%     >            'Fp1'
%     >          .neighblabel
%     >            { 'Fp1'
%     >               :
%     >              'FC1' }@21x1
%     >      :           :
%     >    (86,1).label
%     >            'I2'
%     >          .neighblabel
%     >            { 'P4'
%     >               :
%     >              'I2' }@16x1
%     %
%     % since the dataset has only 80 channels, 74 of which are in the
%     % layout, using the dataset's labels only (with the 'labels'
%     % argument) returns
%     % only neighbors for channels in the dataset
%     nbrs=cosmo_meeg_chan_neighbors(ds,'radius',.3,...
%                                         'label','dataset');
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@74x1
%     >    (1,1) .label
%     >            'Fp1'
%     >          .neighblabel
%     >            { 'Fp1'
%     >               :
%     >              'FC1' }@21x1
%     >      :           :
%     >    (74,1).label
%     >            'I2'
%     >          .neighblabel
%     >            { 'P4'
%     >               :
%     >              'I2' }@16x1
%
%     % get neighbors at 4 neighboring sensor location for
%     % planar neuromag306 channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrs=cosmo_meeg_chan_neighbors(ds,...
%                     'chantype','meg_planar','count',4);
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@204x1
%     >    (1,1)  .label
%     >             'MEG0113'
%     >           .neighblabel
%     >             { 'MEG0113'
%     >               'MEG0112'
%     >               'MEG0122'
%     >               'MEG0133' }
%     >      :            :
%     >    (204,1).label
%     >             'MEG2643'
%     >           .neighblabel
%     >             { 'MEG2423'
%     >               'MEG2422'
%     >               'MEG2642'
%     >               'MEG2643' }
%
%     % get neighbors at 4 neighboring sensor location for
%     % planar neuromag306 channels, but with the center labels
%     % the set of combined planar channels
%     % (there are 8 channels in the .neighblabel fields, because
%     %  there are two planar channels per combined channel)
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrs=cosmo_meeg_chan_neighbors(ds,...
%                     'chantype','meg_combined_from_planar','count',4);
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@102x1
%     >    (1,1)  .label
%     >             'MEG0112+0113'
%     >           .neighblabel
%     >             { 'MEG0112'
%     >                  :
%     >               'MEG0343' }@8x1
%     >      :              :
%     >    (102,1).label
%     >             'MEG2642+2643'
%     >           .neighblabel
%     >             { 'MEG2422'
%     >                  :
%     >               'MEG2643' }@8x1
%
%     % As above, but now use both the axial and planar channels.
%     % Here the axial channels only have axial neighbors, and the planar
%     % channels only have planar neighbors
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrs=cosmo_meeg_chan_neighbors(ds,...
%                            'chantype','all','count',4);
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@306x1
%     >    (1,1)  .label
%     >             'MEG0111'
%     >           .neighblabel
%     >             { 'MEG0111'
%     >               'MEG0121'
%     >               'MEG0131'
%     >               'MEG0341' }
%     >      :            :
%     >    (306,1).label
%     >             'MEG2643'
%     >           .neighblabel
%     >             { 'MEG2423'
%     >               'MEG2422'
%     >               'MEG2642'
%     >               'MEG2643' }
%
%     % As above, but now use both the axial and planar channels with
%     % center labels for the planar channels from the combined_planar set.
%     % Here the axial center channels have 4 axial neighbors each, while
%     % the planar_combined channels have 8 planar (uncombined) neigbors
%     % each.
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrs=cosmo_meeg_chan_neighbors(ds,...
%                            'chantype','all_combined','count',4);
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@204x1
%     >    (1,1)  .label
%     >             'MEG0111'
%     >           .neighblabel
%     >             { 'MEG0111'
%     >               'MEG0121'
%     >               'MEG0131'
%     >               'MEG0341' }
%     >      :              :
%     >    (204,1).label
%     >             'MEG2642+2643'
%     >           .neighblabel
%     >             { 'MEG2422'
%     >                  :
%     >               'MEG2643' }@8x1
%
%
% Notes:
%  - this function returns a struct similar to FieldTrip's
%    ft_prepare_neighbors, but not identical:
%    * a center labels can be a neighbor of itself
%    * the neighbors are similar but not identical to FieldTrip's
%      ft_prepare_neighbors
%  - for searchlight and clustering purposes, use
%    cosmo_meeg_chan_neighborhood
%
% See also: cosmo_meeg_chantype, ft_prepare_neighbours,
%           cosmo_meeg_chan_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    default.label='layout';
    opt=cosmo_structjoin(default,varargin);

    if isfield(opt,'chantype')
        chantype=opt.chantype;
        chantypes=get_chantypes(ds, chantype);
        n=numel(chantypes);
        neighbors_cell=cell(n,1);
        for k=1:n
            opt.chantype=chantypes{k};
            neighbors_cell{k}=get_neighbors_with_chantype(ds,opt);
        end

        neighbors=cat(1,neighbors_cell{:});

        if strcmp(chantype,'all')
            neighbors=add_missing_channels(ds,neighbors);
        end

    else
        neighbors=get_neighbors_with_chantype(ds,opt);
    end

    neighbors=reorder_neighbors(ds,neighbors);


function full_neighbors=add_missing_channels(ds,neighbors)
    ds_label=get_dataset_channel_label(ds);
    nbr_label={neighbors.label};

    missing=setdiff(ds_label,nbr_label);
    n=numel(missing);
    if n==0
        full_neighbors=neighbors;
        return;
    end


    label=missing(:);
    neighblabel=cell(n,1);
    for k=1:n
        neighblabel{k}=cell(1,0);
    end

    missing_neighbors=struct('label',label,'neighblabel',neighblabel);
    full_neighbors=cat(1,neighbors,missing_neighbors);


function neighbors=reorder_neighbors(ds,neighbors)
    ds_label=get_dataset_channel_label(ds);
    nbr_label={neighbors.label};

    if numel(ds_label)~=numel(nbr_label)
        return;
    end

    ds_cell=cellfun(@(x){x},ds_label,'UniformOutput',false);
    nbr_cell=cellfun(@(x){x},nbr_label,'UniformOutput',false);

    overlap=cosmo_overlap(ds_cell,nbr_cell);
    assert(all(sum(overlap,1)) &&all(sum(overlap,2)));

    [i,j]=find(overlap);
    n=numel(i);
    assert(all(j'==1:n));

    % invert mapping
    ii=i;
    ii(i)=1:n;

    neighbors=neighbors(ii);
    assert(isequal({neighbors.label}',ds_label(:)))



function chan_types=get_chantypes(ds, chantype)
    chan_types={chantype};

    switch chantype
        case 'all'
            chan_types=unique(cosmo_meeg_chantype(ds));
        case 'all_combined'
            % replace meg_planar by meg_planar_combined
            chan_types=unique(cosmo_meeg_chantype(ds));
            i=find(cosmo_match(chan_types,'meg_planar'));
            if numel(i)~=1
                error(['dataset has no planar channels, therefore '...
                        '''%s'' is an invalid chantype'],...
                            opt,chan_type);
            end
            chan_types{i}='meg_combined_from_planar';
    end



function neighbors=get_neighbors_with_chantype(ds,opt)
    [layout,label_keep]=get_layout(ds,opt);

    ds_label=get_dataset_channel_label(ds);
    if isempty(label_keep)
        pos_msk=cosmo_match(layout.label, ds_label);
    else
        pos_msk=cosmo_overlap({ds_label},layout.child_label)>0;
    end

    nbr_msk=pairwise_neighbors(layout.pos,pos_msk,opt);

    has_child=isfield(layout,'child_label');

    label=layout.label;
    n=numel(label);

    neighblabel=cell(n,1);
    for k=1:n
        msk=nbr_msk(:,k);
        if has_child
            child_label=layout.child_label(msk);
            neighblabel{k}=intersect(label_keep,cat(1,child_label{:}));
        else
            neighblabel{k}=layout.label(msk);
        end
    end

    neighbors=struct('label',label,'neighblabel',neighblabel);


function [lay,label]=get_layout(ds, opt)
    ignore_label={'COMNT','SCALE'};

    base_lay=cosmo_meeg_find_layout(ds,opt);

    if ischar(opt.label)
        switch opt.label
            case 'layout'
                use_label=base_lay.label;
            case 'dataset'
                use_label=get_dataset_channel_label(ds);
            otherwise
                error('illegal label %s, use one of: layout, dataset');
        end
    elseif iscellstr(opt.label)
        use_label=opt.label;
    else
        error('illegal label, a string or cellstring is required');
    end

    in_label=cosmo_match(base_lay.label, use_label);
    not_in_ignore=~cosmo_match(base_lay.label,ignore_label);
    keep_msk=in_label & not_in_ignore;

    if isfield(base_lay,'parent')
        child_label=base_lay.parent.child_label;
        overlap=cosmo_overlap(child_label,{use_label});
        keep_parent_msk=overlap>0;
        lay=slice_layout(base_lay.parent,keep_parent_msk);
        label=base_lay.label(keep_msk);
    else
        lay=slice_layout(base_lay,keep_msk);
        label=[];
    end


function lay=slice_layout(lay, to_keep)
    nlabel=size(lay.label,1);

    keys=fieldnames(lay);
    for k=1:numel(keys)
        key=keys{k};
        value=lay.(key);

        nvalue=size(value,1);
        switch nvalue
            case nlabel
                lay.(key)=value(to_keep,:);
            case {0,1}
                % ok
            otherwise
                error('layout field %s has %d values, must be 1 or %d',...
                    key,nvalue, nlabel);
        end

    end



function nbrs_msk=pairwise_neighbors(pos,msk,opt)
    assert(size(pos,1)==numel(msk));

    metric2func=struct();
    metric2func.radius=@pairwise_euclidean_neighbors;
    metric2func.count=@pairwise_nearest_neighbors;
    metric2func.delaunay=@pairwise_delaunay_neighbors;

    metrics=fieldnames(metric2func);
    metric_msk=cosmo_isfield(opt,metrics);
    if sum(metric_msk)~=1
        error('Use one of these arguments to define neighbors: %s',...
                cosmo_strjoin(metrics, ', '));
    end

    metric=metrics{metric_msk};
    func=metric2func.(metric);
    nbrs_msk=func(pos,msk,opt.(metric));


function nbrs_msk=pairwise_euclidean_neighbors(pos,msk,radius)
    d=pairwise_euclidean_distance(pos);
    nbrs_msk=d<=radius;
    nbrs_msk(~msk,:)=false;

function nbrs_msk=pairwise_nearest_neighbors(pos,msk,count)
    d=pairwise_euclidean_distance(pos);
    nbrs_msk=nearest_neighbors_from_distance(d,msk,count);

function nbrs_msk=pairwise_delaunay_neighbors(pos,msk,steps)
    % compute steps-th order neighbors
    raise_error_if_not_two_column_matrix(pos);

    if islogical(steps)
        steps=0+steps;
    end

    self_connectivity=0+diag(msk>0);
    connectivity=self_connectivity;

    if steps>0
        % compute sum_{k=1:steps} direct_nbrs.^k
        direct_nbrs=0+pairwise_delaunay_direct_neighbors(pos,msk);
        for k=1:steps
            connectivity=connectivity*(self_connectivity+direct_nbrs);

            % avoid large values
            connectivity(connectivity>0)=1;

            connectivity(~msk,:)=0;
        end
    end
    nbrs_msk=connectivity>0;




function nbrs_msk=pairwise_delaunay_direct_neighbors(pos,msk)
    % avoid duplicate sensor positions
    [idxs,unq_pos]=cosmo_index_unique(pos);
    unq_nbrs_msk=pairwise_delaunay_direct_neighbors_unique(unq_pos,msk);

    n=size(pos,1);
    nbrs_msk=false(n);

    nunq=numel(idxs);
    assert(isequal([1 1]*nunq,size(unq_nbrs_msk)));

    for k=1:nunq
        for j=1:nunq
            nbrs_msk(idxs{k},idxs{j})=unq_nbrs_msk(k,j);
        end
    end



function nbrs_msk=pairwise_delaunay_direct_neighbors_unique(pos,msk)
    % act a bit like fieldtrip by stretching the coordinates (twice)
    stretch=[1 .5 2];

    % delaunay without applying the mask
    f_pos=delaunay_with_stretch(pos,stretch);

    % delaunay with applying the mask
    idx=find(msk(:)');
    pos_msk=pos(idx,:);
    f_msk=delaunay_with_stretch(pos_msk,stretch);
    f_msk_pos=idx(f_msk);

    % combine them
    f_all=[f_pos; f_msk_pos];

    n=size(pos,1);
    nbrs_msk=diag(1:n)>0;

    [nrow,ncol]=size(f_all);
    assert(ncol==3);
    for col=1:ncol
        i=f_all(:,col);
        j=f_all(:,mod(col,3)+1);
        for row=1:nrow
            nbrs_msk(i(row),j(row))=true;
        end
    end

    % make symmetric
    nbrs_msk=nbrs_msk | nbrs_msk';


function d=delaunay_with_stretch(pos, stretches)
    nrows=size(pos,1);
    if nrows<3
        % minimal surface, cannot do Delaunay
        d=ones(1,3);
        d(1:nrows)=1:nrows;
    else
        n=numel(stretches);
        ds=cell(n,1);

        for k=1:n
            stretch_pos=bsxfun(@times,pos,[1 stretches(k)]);
            ds{k}=delaunay(stretch_pos(:,1),stretch_pos(:,2));
        end
        d=cat(1,ds{:});
    end


function nbrs_msk=nearest_neighbors_from_distance(d,msk,count)
    % d is an n x n matrix with distances
    n=size(d,1);
    nbrs_msk=false(n);

    d_msk=d;
    d_msk(~msk,:)=Inf;

    [sd,i]=sort(d_msk);
    for k=1:n
        last_row=min(n,count);

        radius=sd(last_row,k);
        while last_row < n && sd(last_row+1,k)==radius
            last_row=last_row+1;
        end

        if last_row<count || isinf(sd(last_row,k))
            error('Cannot select %d channels: only %d are present',...
                    count,sum(msk));
        end

        nbrs_msk(i(1:last_row,k),k)=true;
    end

    assert(all(diag(nbrs_msk)==msk(:)));
    assert(all(sum(nbrs_msk,1)>=count));


function d=pairwise_euclidean_distance(pos)
    raise_error_if_not_two_column_matrix(pos);

    px=pos(:,1);
    py=pos(:,2);
    dx=bsxfun(@minus,px,px');
    dy=bsxfun(@minus,py,py');

    d=sqrt(dx.^2+dy.^2);

function raise_error_if_not_two_column_matrix(pos)
    is_ok=size(pos,2)==2 && numel(size(pos))==2;
    if ~is_ok
        error('positions must be in Mx2 matrix');
    end

function chan_labels=get_dataset_channel_label(ds)
    % helper function to get labels from dataset
    if iscellstr(ds)
        chan_labels=ds;
    else
        [unused, index, unused, dim_name]=cosmo_dim_find(ds,'chan',true);
        chan_labels=ds.a.(dim_name).values{index};
    end
