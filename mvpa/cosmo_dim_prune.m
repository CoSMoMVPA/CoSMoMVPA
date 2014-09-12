function ds=cosmo_dim_prune(ds, labels, dims)
% prune dataset dimension values that are not used after slicing
%
% ds=cosmo_dim_prune(ds, labels, dims)
%
% Inputs:
%   ds              dataset struct
%   labels          labels of dimensions to be pruned. If not provided all
%                   labels are pruned.
%   dims            dimension(s) along which pruning takes place,
%                   1=sample dimension, 2=feature dimension. Default: [1 2]
% Output:
%   ds              dataset struct with pruned dimension values.
%
% Examples:
%     % For an MEEG dataset, get a selection of some channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','huge');
%     cosmo_disp(ds.a.fdim.values{1});
%     > { 'MEG0111'
%     >   'MEG0112'
%     >   'MEG0113'
%     >      :
%     >   'MEG2641'
%     >   'MEG2642'
%     >   'MEG2643' }@306x1
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
%     > [    0
%     >   0.05
%     >    0.1
%     >     :
%     >    0.2
%     >   0.25
%     >    0.3 ]@7x1
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
%
% See also: cosmo_dim_match
%
% NNO Aug 2014

if nargin<=3 || isempty(dims), dims=[1 2]; end
if nargin<=2, labels=[]; end

cosmo_check_dataset(ds);

ndim=numel(dims);
for k=1:ndim
    ds=prune_single_dim(ds, labels, dims(k));
end

function ds=prune_single_dim(ds, labels, dim)
    infixes='sf';
    infix=infixes(dim);

    attr_name=[infix 'a'];
    dim_name=[infix 'dim'];

    if cosmo_isfield(ds, ['a.' dim_name '.labels'])
        if isempty(labels)
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
            assert(dim_==dim);

            values=ds.a.(dim_name).values{index};
            attr=ds.(attr_name).(label);
            [unq_idxs,unused,map_idxs]=unique(attr);


            ds.(attr_name).(label)=in_shape(map_idxs);
            values=values(unq_idxs);
            ds.a.fdim.values{index}=values;
        end
    end
