function ds=cosmo_dim_transpose(ds, dim_labels, target_dim)
% moves a dataset dimension from samples to features or vice versa

    if ischar(dim_labels)
        dim_labels={dim_labels};
    elseif ~iscellstr(dim_labels)
        error('input must be string or cell of strings');
    end

    source_dim=3-target_dim;
    sp=cosmo_split(ds, dim_labels, source_dim);
    ds=[]; % let GC do its job
    n=numel(sp);

    for k=1:n
        sp{k}=copy_attr(sp{k}, dim_labels, target_dim);
    end

    ds=cosmo_stack(sp, target_dim, 1);

    src_name=dim2attr_name(source_dim);
    for k=1:numel(dim_labels)
        dim_label=dim_labels{k};
        ds.(src_name)=rmfield(ds.(src_name), dim_label);
    end

    ds=move_dim(ds, dim_labels, target_dim);
    cosmo_check_dataset(ds);

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
    src_name=dim2attr_name(3-target_dim);
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

        %ds.(src_name)=rmfield(ds.(src_name),dim_label);
        ds.(trg_name).(dim_label)=repmat(unq,trg_size);
    end

function ds=move_dim(ds, dim_labels, dim)
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
        error('label %s already in .a.%s.labels', dim_labels{i}, trg_label);
    end

    src_keep_msk=~cosmo_match(src_labels, dim_labels);
    src_move_msk=~src_keep_msk;
    move_values=src_attr.values(src_move_msk);

    % keep labels and values in source that are not in dim_labels
    ds.a.(src_label).labels=ds.a.(src_label).labels(src_keep_msk);
    ds.a.(src_label).values=ds.a.(src_label).values(src_keep_msk);

    % move labels and values to target that are in dim_labels
    ds.a.(trg_label).labels=[ds.a.(trg_label).labels(:);dim_labels(:)];
    ds.a.(trg_label).values=[ds.a.(trg_label).values(:);move_values(:)];











