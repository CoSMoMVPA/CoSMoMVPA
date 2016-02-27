function ds=cosmo_dim_insert(ds,dim,index,labels,values,attr,varargin)
% insert a dataset dimension
%
% ds_result=cosmo_dim_insert(ds,dim,index,labels,values,attr,...)
%
% Inputs:
%   ds                  dataset struct
%   dim                 dimension along which dimensions must be inserted,
%                       1=samples, 2=features
%   index               position at which dimension must be inserted,
%                       in .a.sdim (if dim==1) or .a.fdim (if dim==2)
%   labels              dimension labels
%   values              dimension values
%   attr                cell with values for .sa or .fa, or a struct with
%                       the fields that are in labels
%   'matrix_labels',m   (optional) any label for which the corresponding
%                       value is a matrix must be an element of the
%                       cellstring m. Currently this applies to the 'pos'
%                       field in MEEG source data
%
% Output:
%   ds_result           dataset struct with dim_labels removed from
%                       .a.{fdim,sdim} and .{fa,sa}.
%
% Example:
%     % generate tiny fmri dataset
%     ds=cosmo_synthetic_dataset();
%     %
%     % remove first two feature dimensions ('i' and 'j')
%     dim_labels=ds.a.fdim.labels(1:2);
%     dim_values=ds.a.fdim.values(1:2);
%     dsr=cosmo_dim_remove(ds,dim_labels);
%     %
%     % add them back in
%     ds_humpty=cosmo_dim_insert(dsr,2,1,dim_labels,dim_values,...
%                                             {ds.fa.i,ds.fa.j});
%     %
%     % the output is the same as the original dataset
%     isequal(ds,ds_humpty)
%
% Notes:
%   - this is a utility function, mostly intended for use by other
%     functions
%   - this function does not check for duplicate dimensions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    defaults.matrix_labels=cell(0);
    defaults.check_dataset=true;
    opt=cosmo_structjoin(defaults,varargin{:});

    prefixes='sf';
    prefix=prefixes(dim);
    attr_name=[prefix 'a'];
    dim_name=[prefix 'dim'];

    ds=ensure_has_xa_xdim(ds,dim,attr_name,dim_name);

    % get values in proper size
    attr_values=get_attr_values(labels,attr);
    dim_values=get_dim_values(labels,values,dim,opt);

    if ~iscellstr(labels)
        error('labels must be a cell with strings');
    end

    ds.a.(dim_name).labels=insert_elements(ds.a.(dim_name).labels, ...
                                                index, labels, dim);
    ds.a.(dim_name).values=insert_elements(ds.a.(dim_name).values, ...
                                                index, dim_values, dim);
    for j=1:numel(labels)
        label=labels{j};
        ds.(attr_name).(label)=attr_values{j};
    end

    if opt.check_dataset
        cosmo_check_dataset(ds);
    end

function ds=ensure_has_xa_xdim(ds,dim,attr_name,dim_name)
    if ~cosmo_isfield(ds,attr_name)
        ds.(attr_name)=struct();
    end

    if ~cosmo_isfield(ds,['a.' dim_name]);
        ds.a.(dim_name)=struct();
        empty_size=[0 0];
        empty_size(dim)=1;
        ds.a.(dim_name).labels=cell(empty_size);
        ds.a.(dim_name).values=cell(empty_size);
    end

function ys=insert_elements(xs,i,y,dim)
    % insets y in xs at position i
    n=numel(xs);

    if i<-n || i>(n+1)
        error('position index %d must be in range 1..%d, or -%d..-1',...
                        i,n+1,n+1);
    end

    if i<=0
        i=n+i+1;
    end

    xs_col=xs(:);
    ys=[xs_col(1:(i-1));y(:);xs_col(i:end)];
    if dim==1
        ys=ys';
    end

function dim_values=get_dim_values(labels,values,dim,opt)
    matrix_labels=opt.matrix_labels;

    n=numel(labels);

    if ~iscell(labels)
        error('labels argument must be a cell');
    end

    if ~iscell(values)
        error('values argument must be a cell');
    end


    if numel(values)~=n
        error('size mismatch between labels and values');
    end

    dim_values_shape=[1 1];
    dim_values_shape(3-dim)=n;

    dim_values=cell(dim_values_shape);
    for j=1:n
        label=labels{j};
        value=values{j};

        if ~cosmo_match({label},matrix_labels)
            if ~isvector(value)
                error(['dim value for %s must be a vector, because it '...
                            'is not set in the matrix_labels option'],...
                            label);
            end
            if xor(isrow(value),dim==2)
                value=value';
            end
        end
        dim_values{j}=value;
    end





function values=get_attr_values(labels,attr)
    % get elements for .sa or .fa. attr can either be a cell or a struct
    if isstruct(attr)
        values=cell(size(labels));
        for k=1:numel(labels)
            label=labels{k};
            if ~isfield(attr,label)
                error('missing field %s', label);
            end
            values{k}=attr.(label);
        end
    elseif iscell(attr)
        values=attr;
    else
        error('illegal attr value: must be struct or cell');
    end

    n=numel(labels);

    if numel(values)~=n
        error(['number of values (%d) does not match the number of '...
                    'labels'],numel(values),n);
    end
