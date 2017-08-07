function [dim, index, attr_name, dim_name, values]=cosmo_dim_find(ds, dim_label, raise)
% find dimension attribute in dataset
%
% [dim, index, attr_name, dim_name]=cosmo_dim_find(ds, dim_label[, raise])
%
% Inputs:
%   ds              dataset struct
%   dim_label       dimension label
%   raise           if true, raise an error if the dimension is not found.
%                   Default: false
%
% Outputs:
%   dim             dimension where dim_label was found, 1=sample
%                   dimension, 2=feature dimension
%   index           position where dim_label was found, so that:
%                     ds.a.(dim_name).values{index}==dim_label
%   attr_name       'sa' if dim==1, 'fa' if dim==2
%   dim_name        'sdim' if dim==1, 'fdim' if dim==2
%   values          the values associated with the dimension
%
% Examples:
%     % fMRI dataset, find first voxel dimension
%     ds=cosmo_synthetic_dataset('type','fmri');
%     [dim, index, attr_name, dim_name, values]=cosmo_dim_find(ds,'i')
%     > dim = 2
%     > index = 1
%     > attr_name = fa
%     > dim_name = fdim
%     > values = 1 2 3
%
%     % MEEG time-frequency dataset, find 'time' dimension
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     [dim, index, attr_name, dim_name, values]=cosmo_dim_find(ds,'time')
%     > dim = 2
%     > index = 3
%     > attr_name = fa
%     > dim_name = fdim
%     > values = -0.2000 -0.1500 -0.1000 -0.0500 0
%     %
%     % move 'time' from feature to sample dimension
%     dst=cosmo_dim_transpose(ds,'time',1);
%     [dim, index, attr_name, dim_name, values]=cosmo_dim_find(dst,'time')
%     > dim = 1
%     > index = 1
%     > attr_name = sa
%     > dim_name = sdim
%     > values = -0.2000 -0.1500 -0.1000 -0.0500 0
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    if nargin<3, raise=true; end

    is_singleton=ischar(dim_label);
    if is_singleton
        dim_label={dim_label};
    elseif ~iscellstr(dim_label)
        error('Second input must be string or cell with strings');
    end

    nlabel=numel(dim_label);

    dim=[];
    index=zeros(nlabel,1);
    values=cell(nlabel,1);
    for k=1:nlabel
        [d,i,an,dn,vs]=find_singleton(ds,dim_label{k},raise);

        if k==1
            dim=d;
            attr_name=an;
            dim_name=dn;
        end

        if isempty(d) || dim~=d || ~isequal(attr_name,an) || ...
                                    ~isequal(dim_name,dn)
            dim=[];
            break;
        end

        index(k)=i;
        values{k}=vs;
    end

    if isempty(dim)
        index=[];
        attr_name=[];
        dim_name=[];
        values=[];

        if raise
            error('Unable to find all labels in the same dimension: %s',...
                        cosmo_strjoin(dim_label,', '));
        end
    else
        if dim==1
            index=index';
            values=values';
        end
        if is_singleton
            values=values{1};
        end
    end



function [dim, index, attr_name, dim_name, values]=find_singleton(ds,...
                                                        dim_label,raise)
    infixes='sf';
    for dim=1:numel(infixes)
        infix=infixes(dim);

        attr_name=[infix 'a'];
        dim_name=[infix 'dim'];

        if cosmo_isfield(ds, ['a.' dim_name '.labels'])
            labels=ds.a.(dim_name).labels;
            m=cosmo_match(labels, dim_label);
            if any(m)
                index=find(m);
                if numel(index)>1 && raise
                    error('Duplicate label %s in .a.%s.labels', ...
                                    dim_label, dim_name);
                elseif ~cosmo_isfield(ds, ['a.' dim_name '.values'],...
                                                        raise)
                    % not all fields present

                else
                    values=ds.a.(dim_name).values{index};
                    return
                end
            end
        end
    end

    dim=[];
    index=[];
    attr_name=[];
    dim_name=[];
    values=[];

    if raise
        error('Not found: dimension label %s', dim_label);
    end



