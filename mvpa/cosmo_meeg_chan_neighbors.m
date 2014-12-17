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
%   'delauney', true    } or use Delauney triangulation to find direct
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
%     % get neighbors within radius of .1 for EEG dataset
%     ds=cosmo_synthetic_dataset('type','meeg','sens','eeg1010');
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
%     >            { 'P2'
%     >               :
%     >              'I2' }@18x1
%     %
%     % print labels
%     cosmo_disp(ds.a.fdim.values{1});
%     > { 'TP10'
%     >   'TP7'
%     >   'TP8'  }
%     %
%     % since the dataset has only 3 channels, using the dataset's
%     % labels only returns the labels of the dataset
%     nbrs=cosmo_meeg_chan_neighbors(ds,'radius',.1,'label','dataset');
%     cosmo_disp(nbrs,'edgeitems',1);
%     > <struct>@3x1
%     >    (1,1).label
%     >           'TP7'
%     >         .neighblabel
%     >           { 'TP7' }
%     >    (2,1).label
%     >           'TP8'
%     >         .neighblabel
%     >           { 'TP8'
%     >             'TP10' }
%     >    (3,1).label
%     >           'TP10'
%     >         .neighblabel
%     >           { 'TP8'
%     >             'TP10' }
%
%     % get neighbors at 4 neighboring sensor location for
%     % planar neuromag306 channels
%     ds=cosmo_synthetic_dataset('type','meeg');
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
%     ds=cosmo_synthetic_dataset('type','meeg');
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
%     ds=cosmo_synthetic_dataset('type','meeg');
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
%     ds=cosmo_synthetic_dataset('type','meeg');
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
%    * a center labels is neighbor of itself
%    * the neighbors are similar but not identical to FieldTrip's
%      ft_prepare_neighbors
%
% See also: cosmo_meeg_chantype, ft_prepare_neighbors
%
% NNO Dec 2014


    default.label='layout';
    opt=cosmo_structjoin(default,varargin);

    chan_types=get_chantypes(ds,opt);
    if isempty(chan_types)
        neighbors=get_chantype_neighbors(ds,opt);
    else
        n=numel(chan_types);
        neighbors_cell=cell(n,1);
        for k=1:n
            opt.chantype=chan_types{k};
            neighbors_cell{k}=get_chantype_neighbors(ds,opt);
        end

        neighbors=cat(1,neighbors_cell{:});
    end


function chan_types=get_chantypes(ds,opt)
    if ~isfield(opt,'chantype')
        chan_types=[];
        return;
    end

    chan_types={opt.chantype};

    switch opt.chantype
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



function neighbors=get_chantype_neighbors(ds,opt)
    [layout,label_keep]=get_layout(ds,opt);
    nbr_msk=pairwise_neighbors(layout.pos,opt);

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



function nbrs_msk=pairwise_neighbors(pos,opt)
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
    nbrs_msk=func(pos,opt.(metric));

function nbrs_msk=pairwise_euclidean_neighbors(pos,radius)
    d=pairwise_euclidean_distance(pos);
    nbrs_msk=d<=radius;

function nbrs_msk=pairwise_nearest_neighbors(pos,count)
    d=pairwise_euclidean_distance(pos);
    nbrs_msk=nearest_neighbors_from_distance(d,count);

function nbrs_msk=pairwise_delaunay_neighbors(pos,steps)
    % compute steps-th order neighbors
    if size(pos,2)~=3 && ~ismatrix(pos)
        error('positions must be in Mx2 matrix');
    end

    if islogical(steps)
        steps=0+steps;
    end

    n=size(pos,1);
    self_connectivity=eye(n);
    connectivity=self_connectivity;

    if steps>0
        % compute sum_{k=1:steps} direct_nbrs.^k
        direct_nbrs=0+pairwise_delaunay_direct_neighbors(pos);
        for k=1:steps
            connectivity=connectivity*(self_connectivity+direct_nbrs);

            % avoid large values
            connectivity(connectivity>0)=1;
        end
    end
    nbrs_msk=connectivity>0;




function nbrs_msk=pairwise_delaunay_direct_neighbors(pos)
    % avoid duplicate sensor positions
    [idxs,unq_pos]=cosmo_index_unique(pos);
    unq_nbrs_msk=pairwise_delaynay_direct_neighbors_unique(unq_pos);

    n=size(pos,1);
    nbrs_msk=false(n);

    nunq=numel(idxs);
    assert(isequal([1 1]*nunq,size(unq_nbrs_msk)));

    for k=1:nunq
        for j=1:nunq
            nbrs_msk(idxs{k},idxs{j})=unq_nbrs_msk(k,j);
        end
    end


function nbrs_msk=pairwise_delaynay_direct_neighbors_unique(pos)
    f=delaunay(pos);

    % act a bit like fieldtrip by stretching the coordinates (twice)
    f_x=delaunay(bsxfun(@times,pos,[1 2]));
    f_y=delaunay(bsxfun(@times,pos,[2 1]));

    f_all=[f; f_x; f_y];

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



function nbrs_msk=nearest_neighbors_from_distance(d,count)
    % d is an n x n matrix with distances
    n=size(d,1);
    nbrs_msk=false(n);

    if count>n
        error('Cannot select %d channels: only %d are present',...
                    count,n);
    end

    [sd,i]=sort(d);
    for k=1:n
        last_row=count;
        radius=sd(last_row,k);
        while last_row < n && sd(last_row+1,k)==radius
            last_row=last_row+1;
        end
        nbrs_msk(i(1:last_row,k),k)=true;
    end

    assert(all(diag(nbrs_msk)));

    not_sym=nbrs_msk~=nbrs_msk';
    max_asymetry=.1;

    assert(sum(not_sym(:))>max_asymetry,'unexpected assymetry');


function d=pairwise_euclidean_distance(pos)
    if size(pos,2)~=3 && ~ismatrix(pos)
        error('positions must be in Mx2 matrix');
    end
    dx=bsxfun(@minus,pos(:,1),pos(:,1)');
    dy=bsxfun(@minus,pos(:,2),pos(:,2)');
    d=sqrt(dx.^2+dy.^2);



function chan_labels=get_dataset_channel_label(ds)
    % helper function to get labels from dataset
    if iscellstr(ds)
        chan_labels=ds;
    else
        [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'chan',true);
        chan_labels=ds.a.(dim_name).values{index};
    end
