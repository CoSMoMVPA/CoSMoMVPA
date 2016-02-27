function ds=cosmo_dim_prune(ds, varargin)
% prune dataset dimension values that are not used after slicing
%
% ds=cosmo_dim_prune(ds, labels, dims)
%
% Inputs:
%   ds                  dataset struct
%   'labels; l          labels of dimensions to be pruned. If not provided
%                       all labels are pruned.
%   'dim',d             dimension(s) along which pruning takes place,
%                       1=sample dimension, 2=feature dimension.
%                       Default: [1 2]
%   'matrix_labels',m   Names of feature dimensions that store dimension
%                       information in matrix form. (Currently the only use
%                       case is m={'pos'} for MEEG source datasets.)
%
% Output:
%   ds              dataset struct with pruned dimension values.
%
% Examples:
%     % For an MEEG dataset, get a selection of some channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','huge');
%     cosmo_disp(ds.a.fdim.values{1},'edgeitems',2);
%     > { 'MEG0111'  'MEG0112'  ...  'MEG2642'  'MEG2643'   }@1x306
%     cosmo_disp(ds.fa.chan)
%     > [ 1         2         3  ...  304       305       306 ]@1x5202
%     %
%     % select channels
%     msk=cosmo_dim_match(ds,'chan',{'MEG1843','MEG2441'});
%     ds_sel=cosmo_slice(ds,msk,2);
%     %
%     % apply pruning, so that the .fa.chan goes from 1:nf, with nf the
%     % number of channels that were selected
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{1}); % 'chan' is first dimension
%     > { 'MEG1843'
%     >   'MEG2441' }
%     cosmo_disp(ds_pruned.fa.chan)
%     > [ 1         2         1  ...  2         1         2 ]@1x34
%     %
%     % For the same MEEG dataset, get a selection of time points between 0
%     % and .3 seconds. A function handle is used to select the timepoints
%     selector=@(x) 0<=x & x<=.3; % use element-wise logical-and
%     msk=cosmo_dim_match(ds,'time',selector);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     cosmo_disp(ds_pruned.a.fdim.values{2}); % 'time' is second dimension
%     > [ 0      0.05       0.1  ...  0.2      0.25       0.3 ]@1x7
%     cosmo_disp(ds_pruned.fa.time)
%     > [ 1         1         1  ...  7         7         7 ]@1x2142
%     %
%     % For the same MEEG dataset, compute a conjunction mask of the
%     % channels and time points selected above
%     msk=cosmo_dim_match(ds,'chan',{'MEG1843','MEG2441'},'time',selector);
%     ds_sel=cosmo_slice(ds,msk,2);
%     ds_pruned=cosmo_dim_prune(ds_sel);
%     %
%     % show result
%     > { { 'MEG1843'    [    0
%     >     'MEG2441' }    0.05
%     >                     0.1
%     >                      :
%     >                     0.2
%     >                    0.25
%     >                     0.3 ]@7x1 }
%     cosmo_disp(ds_pruned.fa.chan)
%     > [ 1         2         1  ...  2         1         2 ]@1x14
%     cosmo_disp(ds_pruned.fa.time)
%     > [ 1         1         2  ...  6         7         7 ]@1x14
% Notes:
%  - Using this function makes sense for MEEG data, but not at all
%    for fMRI or surface data.
%  - When using this function for MEEG data after slicing (using
%    cosmo_dim_match and cosmo_slice), applying this function ensures that
%    removed values in a dimension are not mapped back to the original
%    input size when using cosmo_map2meeg.
%  - When using this function with MEEG source data that has a 'pos' field,
%    use
%           cosmo_dim_prune(ds,'matrix_labels',{'pos'})
%
%    to prune the 'pos' feature dimension (if it needs pruning)
%
% See also: cosmo_dim_match
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

opt=process_opt(varargin{:});

cosmo_check_dataset(ds);

dim=opt.dim;
ndim=numel(dim);
opt=rmfield(opt,'dim');
for k=1:ndim
    ds=prune_single_dim(ds, dim(k), opt);
end

function ds=prune_single_dim(ds, dim, opt)
    labels=opt.labels;

    infixes='sf';
    infix=infixes(dim);

    attr_name=[infix 'a'];
    dim_name=[infix 'dim'];

    if cosmo_isfield(ds, ['a.' dim_name '.labels'])
        use_dim_labels=isempty(labels);
        if use_dim_labels
            labels=ds.a.(dim_name).labels;
        end

        if ~iscellstr(labels)
            error('expected cell with labels, or single string');
        end


        % helper to ensure that slicing output has proper size
        nvalues=size(ds.samples,dim);
        shape_arg={[],[]};
        shape_arg{dim}=nvalues;

        in_shape=@(x) reshape(x, shape_arg{:});


        nlabels=numel(labels);
        for k=1:nlabels
            label=labels{k};

            [dim_, index]=cosmo_dim_find(ds,label,true);
            if use_dim_labels
                assert(dim_==dim);
            elseif dim~=dim_
                continue;
            end


            values=ds.a.(dim_name).values{index};
            attr=ds.(attr_name).(label);
            [unq_idxs,unused,map_idxs]=unique(attr);

            if isequal(unq_idxs(:),(1:numel(values))')
                % already pruned, no update necessary
                continue;
            end

            values=get_unique(label, dim, values, unq_idxs, opt);
            ds.a.(dim_name).values{index}=values;

            ds.(attr_name).(label)=in_shape(map_idxs);
        end
    end

function values=get_unique(label, dim, values, unq_idxs, opt)
    if sum(size(values)>1)>1
        if cosmo_match({label},opt.matrix_labels)
            if dim==1
                values=values(unq_idxs,:);
            else
                values=values(:,unq_idxs);
            end
        else
            msg=sprintf(['Values for dimension ''%s'' is a matrix, but '...
                        '''%s'' was not specified as a an element '...
                        'of the ''matrix_labels'' option.'],...
                        label,label);
            if strcmp(label,'pos')
                msg=sprintf(['%s\nIf this is an MEEG source dataset, '...
                             'consider using %s(...,'...
                             '''matrix_labels'',{''pos''})'],...
                             msg,mfilename());
            end
            error(msg);
        end
    else
        values=values(unq_idxs);
        values=values(:);
        if dim==2
            values=values';
        end
    end


function [opt]=process_opt(varargin)
    default=struct();
    default.labels={};
    default.dim=[1 2];
    default.matrix_labels={};

    opt=cosmo_structjoin(default,varargin{:});

    if any(~cosmo_match(opt.dim,[1 2]))
        error('''dims'' must be 1 or 2');
    end

    if ~iscellstr(opt.matrix_labels)
        error('''matrix_labels'' option must be a cellstring');
    end
