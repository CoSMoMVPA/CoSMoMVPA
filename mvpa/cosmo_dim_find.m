function [dim, index, attr_name, dim_name]=cosmo_dim_find(ds, dim_label, raise)
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
%
% Examples:
%     % fMRI dataset, find third voxel dimension
%     ds=cosmo_synthetic_dataset('type','fmri');
%     [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'k')
%     > dim = 2
%     > index = 3
%     > attr_name = fa
%     > dim_name = fdim
%
%     % MEEG time-frequency dataset, find 'time' dimension
%     ds=cosmo_synthetic_dataset('type','timefreq');
%     [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'time')
%     > dim = 2
%     > index = 3
%     > attr_name = fa
%     > dim_name = fdim
%     %
%     % move 'time' from feature to sample dimension
%     dst=cosmo_dim_transpose(ds,'time',1);
%     [dim, index, attr_name, dim_name]=cosmo_dim_find(dst,'time')
%     > dim = 1
%     > index = 1
%     > attr_name = sa
%     > dim_name = sdim
%
% NNO Aug 2014


if nargin<3, raise=false; end

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
            elseif ~cosmo_isfield(ds, {['a.' dim_name '.values'],...
                                        [attr_name '.' dim_label]}, raise)
                % not all fields present

            else
                % all good
                return
            end
        end
    end
end

dim=[];
index=[];
attr_name=[];
dim_name=[];

if raise
    error('Not found: dimension label %s', dim_label);
end



