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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

    % split dataset by dim_labels
    source_dim=3-target_dim;
    sp=cosmo_split(ds, dim_labels, source_dim);

    % move attribute for each split
    n=numel(sp);
    for k=1:n
        sp{k}=copy_attr(sp{k}, dim_labels, target_dim);
    end

    % join splits
    ds=cosmo_stack(sp, target_dim, 'unique');

    % remove dimension from source_dim
    [ds,unused,values]=cosmo_dim_remove(ds,dim_labels);

    cell_transpose=@(c)cellfun(@(x)x',c,'UniformOutput',false)';
    values_tr=cell_transpose(values);
    attr_tr=ds.(attr_name);

    % insert dimension in target_dim
    ds=cosmo_dim_insert(ds,target_dim,target_pos,...
                            dim_labels,values_tr,attr_tr);

    % ensure all kosher
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

        ds.(trg_name).(dim_label)=repmat(unq,trg_size);
    end

    ds.(src_name)=rmfield(ds.(src_name),dim_labels);

    % add transpose_ids, so that the input can be reconstructed
    % even after permutations of rows or columns
    attr_label='transpose_ids';
    src_size=[1 1];
    src_size(source_dim)=size(ds.samples,source_dim);
    ds.(src_name).(attr_label)=reshape(1:max(src_size),src_size);

