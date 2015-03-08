function [ds,attr,values]=cosmo_dim_remove(ds,dim_labels)
% remove a dataset dimension
%
% [ds_result,attr,values]=cosmo_dim_remove(ds,dim_labels)
%
% Inputs:
%   ds                  dataset struct
%   dim_labels          string or cellstring with label(s) to remove
%
% Output:
%   ds_result           dataset struct with dim_labels removed from
%                       .a.{fdim,sdim} and .{fa,sa}.
%   attr                struct based on .{fa,sa} but only with the fields in
%                       dim_labels
%   values              cell based on .a.{fdim,sdim}.values, but only
%                       with the fields in dim_labels.
%
% Example:
%     % generate tiny fmri dataset
%     ds=cosmo_synthetic_dataset();
%     cosmo_disp(ds.a.fdim);
%     > .labels
%     >   { 'i'  'j'  'k' }
%     > .values
%     >   { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     cosmo_disp(ds.fa);
%     > .i
%     >   [ 1         2         3         1         2         3 ]
%     > .j
%     >   [ 1         1         1         2         2         2 ]
%     > .k
%     >   [ 1         1         1         1         1         1 ]
%     % remove 'j' and 'k' dimension label; only 'i' is left
%     [ds_without_jk,attr,values]=cosmo_dim_remove(ds,{'j','k'});
%     cosmo_disp(ds_without_jk.a.fdim);
%     > .labels
%     >   { 'i' }
%     > .values
%     >   { [ 1         2         3 ] }
%     cosmo_disp(ds_without_jk.fa);
%     > .i
%     >   [ 1         2         3         1         2         3 ]
%     cosmo_disp(attr)
%     > .j
%     >   [ 1         1         1         2         2         2 ]
%     > .k
%     >   [ 1         1         1         1         1         1 ]
%     cosmo_disp(values)
%     > { [ 1         2 ]  [ 1 ] }
%
% See also: cosmo_dim_transpose
%
% NNO Mar 2015




    has_char_label=ischar(dim_labels);
    if has_char_label
        dim_labels={dim_labels};
    end
    nlabels=numel(dim_labels);

    [unused,remove_idxs,attr_name,dim_name]=cosmo_dim_find(ds,dim_labels);

    % update .fa / .sa
    xa=ds.(attr_name);

    attr=struct();
    for k=1:nlabels
        label=dim_labels{k};
        attr.(label)=xa.(label);
    end

    ds.(attr_name)=rmfield(xa,dim_labels);

    % update .a.fdim / .a.sdim
    xdim=ds.a.(dim_name);
    xdim_values=xdim.values;
    keep_msk=true(size(xdim_values));
    keep_msk(remove_idxs)=false;
    xdim.labels=xdim.labels(keep_msk);
    xdim.values=xdim.values(keep_msk);

    if any(keep_msk)
        ds.a.(dim_name)=xdim;
    else
        ds.a=rmfield(ds.a,dim_name);
    end

    values=xdim_values(remove_idxs);

    if has_char_label
        assert(numel(values)==1);
        values=values{1};
    end













