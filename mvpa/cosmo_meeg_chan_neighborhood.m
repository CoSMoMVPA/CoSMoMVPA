function nbrhood=cosmo_meeg_chan_neighborhood(ds, varargin)


    [unused,unused,attr_name,dim_name,ds_label]=cosmo_dim_find(ds,...
                                                        'chan',true);
    nbrs=get_neighbors(ds,varargin{:});

    ds_chan=ds.(attr_name).chan;
    [nbrs_label,chan_idxs]=get_neighbor_indices(nbrs,ds_label,ds_chan);

    nbrhood=struct();
    nbrhood.neighbors=chan_idxs;
    nbrhood.(attr_name).chan=1:numel(nbrs);
    nbrhood.a.(dim_name).labels={'chan'};
    nbrhood.a.(dim_name).values={nbrs_label};

function [nbrs_label,chan_idxs]=get_neighbor_indices(nbrs,ds_label,ds_chan)
    nbrs_label={nbrs.label};
    ds_label_cell=cellfun(@(x){x},ds_label,'UniformOutput',false);

    ncenter=numel(nbrs_label);

    ow=cosmo_overlap({nbrs.neighblabel},ds_label_cell);
    [chan_pos,chan_cell]=cosmo_index_unique({ds_chan});
    chan=chan_cell{1};
    %
    chan_idxs=cell(ncenter,1);
    for k=1:ncenter
        % find the indices in ds where the neighbors match
        idx=find(ow(k,:));
        chan_pos_msk=cosmo_match(chan,idx);
        chan_idx=cat(1,chan_pos{chan_pos_msk});
        if isempty(chan_idx)
            chan_idx=zeros(0,1);
        end
        chan_idxs{k}=chan_idx;
    end


function nbrs=get_neighbors(ds, varargin)
    if numel(varargin)==1
        nbrs=varargin{1};
    else
        nbrs=cosmo_meeg_chan_neighbors(ds,varargin{:});
    end

    verify_neighbors(nbrs)

function verify_neighbors(nbrs)
    if ~isstruct(nbrs) || ...
                ~isfield(nbrs,'label') || ~isfield(nbrs,'neighblabel')
        error('neighbor struct must be neighborhood struct');
    end



function foo


return

ov=cosmo_overlap({nbrs.neighblabel},x);

keep_idxs=find(any(ov,2));

nkeep=numel(keep_idxs);

label=nbrs_label(keep_idxs);

ynbr=cell(1,nkeep);
for k=1:nkeep
    ynbr{k}=find(ov(keep_idxs(k),:));
end






return


nx=numel(x);
ny=numel(y);

ov=cosmo_overlap(y,x);

[row,col]=find(ov);

label=nbrs_label(row);

if numel(row)~=nx
    % if not all labels in ds, use all labels in neighborhood
    row=col;
end

n=numel(label);

ynbr=cell(n,1);

for k=1:n
    ynbr{k}=nbrs(row(k)).neighblabel;
end

y_ov=cosmo_overlap(ynbr,x);
