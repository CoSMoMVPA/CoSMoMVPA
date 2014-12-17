function neighbors=cosmo_meeg_chan_neighbors(ds, varargin)
    default.label='layout';
    opt=cosmo_structjoin(default,varargin);

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
        overlap=cosmo_overlap(child_label,{base_lay.label});
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
