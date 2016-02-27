function [ds,attr,values]=cosmo_dim_remove(ds,dim_labels)
% remove a dataset dimension
%
% [ds_result,attr,values]=cosmo_dim_remove(ds,dim_labels)
%
% Inputs:
%   ds                  dataset struct
%   dim_labels          cellstring with label(s) to remove. A single
%                       string s is interpreted as s{1}
%
% Output:
%   ds_result           dataset struct with dim_labels removed from
%                       .a.{fdim,sdim} and .{fa,sa}.
%   attr                struct based on .{fa,sa} but only with the fields in
%                       dim_labels
%   values              Nx1 cell based on .a.{fdim,sdim}.values, but only
%                       with the fields in dim_labels. If dim_labels is a
%                       string, then the output is values{1}.
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
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    has_char_label=ischar(dim_labels);
    if has_char_label
        dim_labels={dim_labels};
    end
    nlabels=numel(dim_labels);

    [dim,remove_idxs,attr_name,dim_name]=cosmo_dim_find(ds,dim_labels);

    % update .fa / .sa
    xa=ds.(attr_name);

    attr=struct();
    for k=1:nlabels
        label=dim_labels{k};
        if isfield(xa,label)
            attr.(label)=xa.(label);
            ds.(attr_name)=rmfield(ds.(attr_name),label);
        end
    end

    % update .a.fdim / .a.sdim
    xdim=ds.a.(dim_name);
    xdim_values=xdim.values;
    keep_msk=true(size(xdim_values));
    keep_msk(remove_idxs)=false;
    xdim.labels=xdim.labels(keep_msk);
    xdim.values=xdim.values(keep_msk);

    % remove from the input
    if any(keep_msk)
        % there are dimensions left
        ds.a.(dim_name)=xdim;
    else
        % no dimensions left, remove sdim or fdim
        ds.a=rmfield(ds.a,dim_name);
    end

    % set values to return
    values=xdim_values(remove_idxs);
    assert(isvector(values));

    if xor(dim==1,isrow(values))
        values=values';
    end

    if has_char_label
        % return singleton element
        assert(numel(values)==1);
        values=values{1};
    end













