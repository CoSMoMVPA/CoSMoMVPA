function ds=cosmo_dim_transpose(ds, dim_labels, target_dim, target_pos)
% move a dataset dimension from samples to features or vice versa
%
% ds_tr=cosmo_dim_transpose(ds, dim_labels[, target_dim, target_pos])
%
% Inputs:
%   ds              dataset struct
%   dim_labels      a single dimension label, or a cell with dimension
%                   labels. If target_dim is 1 [or 2], then all labels in
%                   dim_labels must be present in ds.a.fdim[sdim].values,
%                   and all labels in dim_labels must be a fieldname of
%                   ds.fa[sa].
%   target_dim      (optional) indicates that the dimensions in dim_labels
%                   must be moved from features to samples (if
%                   target_dim==1) or from samples to features (if
%                   target_dim==2). If omitted, it is deduced from
%                   dim_labels.
%   target_pos      (optional) the position which the first label in
%                   dim_labels must occupied after the transpose.
%
% Output:
%   ds_tr           dataset struct where all labels in dim_labels are
%                   in ds_tr.a.sdim[fdim] (if target_dim is 1 [or 2]), and
%                   where the fieldnames of ds_tr.sa[fa] is a superset of
%                   dim_labels.
%                   A field .fa.transpose_ids [.sa.transpose_ids] is added
%                   indicating the original feature [sample] id (column
%                   [row]) that the samples belonged too.
%
% Examples:
%     ds=cosmo_synthetic_dataset('type','timefreq');
%     % dataset attribute dimensions are
%     % (<empty> [samples]) x (chan x freq x time [features])
%     cosmo_disp(ds.a.fdim)
%     > .labels
%     >   { 'chan'
%     >     'freq'
%     >     'time' }
%     > .values
%     >   { { 'MEG0111'  'MEG0112'  'MEG0113' }
%     >     [ 2         4 ]
%     >     [ -0.2 ]                            }
%     % transpose 'time' from features to samples
%     ds_tr_time=cosmo_dim_transpose(ds,'time');
%     % dataset attribute dimensions are (time) x (chan x freq)
%     cosmo_disp({ds_tr_time.a.sdim,ds_tr_time.a.fdim})
%     > { .labels         .labels
%     >     { 'time' }      { 'chan'
%     >   .values             'freq' }
%     >     { [ -0.2 ] }  .values
%     >                     { { 'MEG0111'  'MEG0112'  'MEG0113' }
%     >                       [ 2         4 ]                     } }
%     % using the defaults, chan is moved from features to samples, and
%     % added at the end of .a.sdim.labels
%     ds_tr_time_chan=cosmo_dim_transpose(ds_tr_time,'chan');
%     % dataset attribute dimensions are (time x chan) x (freq)
%     cosmo_disp({ds_tr_time_chan.a.sdim,ds_tr_time_chan.a.fdim})
%     > { .labels                        .labels
%     >     { 'time'  'chan' }             { 'freq' }
%     >   .values                        .values
%     >     { [ -0.2 ]  { 'MEG0111'        { [ 2         4 ] }
%     >                   'MEG0112'
%     >                   'MEG0113' } }                        }
%     % when setting the position explicitly, chan is moved from features to
%     % samples, and inserted to the first position in .a.sdim.labels
%     ds_tr_chan_time=cosmo_dim_transpose(ds_tr_time,'chan',1,1);
%     % dataset attribute dimensions are (chan x time) x (freq)
%     cosmo_disp({ds_tr_chan_time.a.sdim,ds_tr_chan_time.a.fdim})
%     > { .labels                        .labels
%     >     { 'chan'  'time' }             { 'freq' }
%     >   .values                        .values
%     >     { { 'MEG0111'    [ -0.2 ]      { [ 2         4 ] }
%     >         'MEG0112'
%     >         'MEG0113' }           }                        }
%     %
%     % this moves the time dimension back to the feature dimension.
%     ds_orig=cosmo_dim_transpose(ds_tr_time,'time');
%     cosmo_disp(ds_orig.a.fdim)
%     > .labels
%     >   { 'chan'
%     >     'freq'
%     >     'time' }
%     > .values
%     >   { { 'MEG0111'  'MEG0112'  'MEG0113' }
%     >     [ 2         4 ]
%     >     [ -0.2 ]                            }
%
%
% Notes:
%   - This function is aimed at MEEG datasets (and for fMRI datasets with a
%     time dimension), so that time can be made a sample dimension
%
% NNO Feb 2015



    if ischar(dim_labels)
        dim_labels={dim_labels};
    elseif ~iscellstr(dim_labels)
        error('input must be string or cell of strings');
    end

    if nargin<4
        target_pos=0;
    end

    if nargin<3
        target_dim=find_target_dim(ds,dim_labels);
    end

    attr_name=dim2attr_name(target_dim);
    
    source_dim=3-target_dim;
    sp=cosmo_split(ds, dim_labels, source_dim);

    n=numel(sp);
    for k=1:n
        sp{k}=copy_attr(sp{k}, dim_labels, target_dim);
    end
    
    ds=cosmo_stack(sp, target_dim, 'unique');
    [ds,unused,values]=cosmo_dim_remove(ds,dim_labels);
    
    cell_transpose=@(c)cellfun(@(x)x',c,'UniformOutput',false)';
    values_tr=cell_transpose(values);
    attr_tr=ds.(attr_name);
    
    ds=cosmo_dim_insert(ds,target_dim,target_pos,dim_labels,values_tr,attr_tr);
    
    %ds=move_dim(ds, dim_labels, target_dim, target_pos);
    cosmo_check_dataset(ds);

function target_dim=find_target_dim(ds, dim_labels)
    for j=1:numel(dim_labels)
        source_dim_j=cosmo_dim_find(ds,dim_labels{j});

        if j==1
            source_dim=source_dim_j;
        elseif source_dim_j~=source_dim
            error('labels %s and %s do not share the same dimension',...
                        dim_labels{1}, dim_labels{j});
        end
    end

    target_dim=3-source_dim;




function prefix=dim2prefix(dim)
    prefixes='sf';
    prefix=prefixes(dim);

function attr_name=dim2attr_name(dim)
    % returns 'sa' or 'fa'
    attr_name=[dim2prefix(dim) 'a'];

function attr_name=dim2label(dim)
    % return 'sdim' or 'fdim'
    attr_name=[dim2prefix(dim) 'dim'];

function ds=copy_attr(ds, dim_labels, target_dim)
    % copy between .fa and .sa
    source_dim=3-target_dim;
    src_name=dim2attr_name(source_dim);
    trg_name=dim2attr_name(target_dim);

    trg_size=[1 1];
    trg_size(target_dim)=size(ds.samples,target_dim);

    for k=1:numel(dim_labels)
        dim_label=dim_labels{k};
        v=ds.(src_name).(dim_label);

        % must all have the same value (otherwise cosmo_split is broken)
        assert(~isempty(v))
        unq=v(1);
        assert(all(unq==v(:)));

        ds.(src_name)=rmfield(ds.(src_name),dim_label);
        ds.(trg_name).(dim_label)=repmat(unq,trg_size);
    end


    attr_label='transpose_ids';
    src_size=[1 1];
    src_size(source_dim)=size(ds.samples,source_dim);
    ds.(src_name).(attr_label)=reshape(1:max(src_size),src_size);

function ds=move_dim(ds, dim_labels, dim, trg_pos)
    expected_dim=cosmo_dim_find(ds, dim_labels);
    if ~isequal(expected_dim,dim)
        error('not all found in dimension %d: %s',...
                    dim,cosmo_strjoin(dim_labels,', '));
    end
    
    cell_transpose=@(c)cellfun(@(x)x',c,'UniformOutput',false)';
    
    [ds,attr,values]=cosmo_dim_remove(ds,dim_labels);
    attr_cell=cellfun(@(x)attr.(x),values,'UniformOutput',false);
    
    attr_tr=cell_transpose(attr_cell);
    values_tr=cell_transpose(values);
    
    ds=cosmo_dim_insert(ds,dim,-1,dim_labels,values_tr,attr_tr);
    return
    
    

    % move between .a.fdim and .a.sdim
    src_label=dim2label(3-dim);
    trg_label=dim2label(dim);

    src_attr=ds.a.(src_label);
    src_labels=src_attr.labels;

    dim_msk=cosmo_match(dim_labels, src_labels);
    if ~all(dim_msk)
        i=find(dim_msk,1);
        error('missing label %s in .a.%s.labels',dim_labels{i},src_label);
    end

    if ~cosmo_isfield(ds.a,trg_label)
        ds.a.(trg_label)=struct();
        ds.a.(trg_label).labels=cell(1,0);
        ds.a.(trg_label).values=cell(1,0);
    end

    trg_attr=ds.a.(trg_label);
    trg_labels=trg_attr.labels;

    % dim_labels cannot be present in target
    conflicting_msk=cosmo_match(dim_labels, trg_labels);
    if any(conflicting_msk)
        i=find(conflicting_msk,1);
        error('label %s already in .a.%s.labels',dim_labels{i},trg_label);
    end

    nlabels=numel(dim_labels);
    src_move_idx=zeros(nlabels,1);
    for k=1:nlabels
        src_move_idx(k)=find(cosmo_match(src_labels,dim_labels(k)));
    end

    src_keep_idx=setdiff(1:numel(src_labels),src_move_idx);
    move_values=src_attr.values(src_move_idx);

    if isempty(src_keep_idx)
        ds.a=rmfield(ds.a,src_label);
    else
        % keep labels and values in source that are not in dim_labels
        ds.a.(src_label).labels=ds.a.(src_label).labels(src_keep_idx);
        ds.a.(src_label).values=ds.a.(src_label).values(src_keep_idx);
    end

    % move labels and values to target that are in dim_labels

    ds.a.(trg_label).labels=insert_element(ds.a.(trg_label).labels,...
                                                trg_pos,dim,dim_labels);
    ds.a.(trg_label).values=insert_element(ds.a.(trg_label).values,...
                                                trg_pos,dim,move_values);

    ds.a.(trg_label).values=cellfun(@transpose,ds.a.(trg_label).values,...
                                    'UniformOutput',false);


function ys=insert_element(xs,i,dim,y)
    % insets y in xs at position i
    n=numel(xs);
    if i<0
        i=n-i;
    end

    if i<0 || i>(n+1)
        error('position index must be in range 1..%d, or -%d..-1',n+1,n+1);
    end

    xs_vec=xs(:);
    ys=cat(1,xs_vec((1:(i-1))'),y(:),xs_vec((i:end)'));

    if dim==1
        ys=ys';
    end











