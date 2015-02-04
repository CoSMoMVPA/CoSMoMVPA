function nbrhood=cosmo_meeg_chan_neighborhood(ds, varargin)
% determine neighborhood of channels in MEEG dataset
%
% nbrhood=cosmo_meeg_chan_neighborhood(ds, ...)
%
% Inputs:
%   ds                  MEEG dataset struct
%   'label', lab        Optional labels to return in output, one of:
%                       'layout'    : determine neighbors based on layout
%                                     associated with ds (default). All
%                                     labels in the layout are used as
%                                     center labels.
%                       'dataset'   : determine neighbors based on labels
%                                     present in ds. Only labels present in
%                                     ds are used as center labels
%                       {x1,...,xn} : use labels x1 ... xn
%   'chantype', tp      (optional) channel type of neighbors, can be one of
%                       'eeg', 'meg_planar', 'meg_axial', or
%                       'meg_combined_from_planar'.
%                       Use 'all' to use all channel types associated with
%                       lab, and 'all_combined' to use
%                       'meg_combined_from_planar' with all other channel
%                       types in ds except for 'meg_planar'.
%                       If there is only one channel type associated with
%                       lab, then this argument is not required.
%   'radius', r         } select neighbors either within radius r, grow
%   'count', c          } the radius to get neighbors at c locations,
%   'delaunay', true    } or use Delaunay triangulation to find direct
%                       } neighbors for each channel.
%                       } These three options are mutually exclusive
%
% Output:
%   nbrhood             struct with fields:
%     .neighbors        Kx1 cell with feature indices of neighbors of
%                       k-th channel
%     .fa.chan          channel indices, equal to 1:K
%     .a.fdim.values    set to a cell with as only element a cell with
%                       center channel labels
%     .a.fdim.labels    set to {'chan'}
%
% Examples:
%     % get neighbors at 4 neighboring sensor location for
%     % planar neuromag306 channels
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrhood=cosmo_meeg_chan_neighborhood(ds,...
%                            'chantype','meg_planar','count',4);
%     cosmo_disp(nbrhood,'edgeitems',1);
%     > .neighbors
%     >   { [ 2  ...  2e+03 ]@1x28
%     >                 :
%     >     [ 149  ...  2.14e+03 ]@1x28 }@204x1
%     > .fa
%     >   .chan
%     >     [ 1  ...  204 ]@1x204
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'chan' }
%     >     .values
%     >       { { 'MEG0113'
%     >              :
%     >           'MEG2643' }@204x1 }
%     >   .meeg
%     >     .samples_type
%     >       'timelock'
%     >     .samples_field
%     >       'trial'
%     >     .samples_label
%     >       'rpt'
%
%     % get neighbors with radius of .1 for
%     % planar neuromag306 channels, but with the center labels
%     % the set of combined planar channels
%     % (there are 8 channels in the .neighblabel fields, because
%     %  there are two planar channels per combined channel)
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrhood=cosmo_meeg_chan_neighborhood(ds,...
%                       'chantype','meg_combined_from_planar','radius',.1);
%     cosmo_disp(nbrhood,'edgeitems',1);
%     > .neighbors
%     >   { [ 2  ...  2e+03 ]@1x42
%     >                 :
%     >     [ 149  ...  2.14e+03 ]@1x56 }@102x1
%     > .fa
%     >   .chan
%     >     [ 1  ...  102 ]@1x102
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'chan' }
%     >     .values
%     >       { { 'MEG0112+0113'
%     >                 :
%     >           'MEG2642+2643' }@102x1 }
%     >   .meeg
%     >     .samples_type
%     >       'timelock'
%     >     .samples_field
%     >       'trial'
%     >     .samples_label
%     >       'rpt'
%     >
%
%     % As above, but combine the two types of channels
%     % Here the axial channels only have axial neighbors, and the planar
%     % channels only have planar neighbors. With 7 timepoints and 10
%     % neighboring channels, the meg_axial channels all have 70 axial
%     % neighbors while the meg_planar_combined channels all have
%     % 140 neighbors based on the planar channel pairs in the original
%     % dataset
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     nbrhood=cosmo_meeg_chan_neighborhood(ds,...
%                            'chantype','all_combined','count',10);
%     cosmo_disp(nbrhood,'edgeitems',1);
%     > .neighbors
%     >   { [ 1  ...  2.07e+03 ]@1x70
%     >                 :
%     >     [ 71  ...  2.14e+03 ]@1x140 }@204x1
%     > .fa
%     >   .chan
%     >     [ 1  ...  204 ]@1x204
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'chan' }
%     >     .values
%     >       { { 'MEG0111'
%     >                 :
%     >           'MEG2642+2643' }@204x1 }
%     >   .meeg
%     >     .samples_type
%     >       'timelock'
%     >     .samples_field
%     >       'trial'
%     >     .samples_label
%     >       'rpt'
%
%
% See also: cosmo_meeg_chan_neighbors
%
% NNO Dec 2014


    [dim,unused,attr_name,dim_name,ds_label]=cosmo_dim_find(ds,...
                                                        'chan',true);
    nbrs=get_neighbors(ds,varargin{:});

    ds_chan=ds.(attr_name).chan;
    [nbrs_label,chan_idxs]=get_neighbor_indices(nbrs,ds_label,ds_chan);

    nbrhood=struct();
    nbrhood.neighbors=chan_idxs;
    nbrhood.(attr_name).chan=1:numel(nbrs);
    nbrhood.a=ds.a;
    nbrhood.a.(dim_name)=struct();
    nbrhood.a.(dim_name).labels={'chan'};
    nbrhood.a.(dim_name).values={nbrs_label(:)};

    if dim==2
        other_dim_name='sdim';
    else
        other_dim_name='fdim';
    end

    if isfield(nbrhood.a,other_dim_name)
        nbrhood.a=rmfield(nbrhood.a,other_dim_name);
    end


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
        chan_idxs{k}=chan_idx';
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
