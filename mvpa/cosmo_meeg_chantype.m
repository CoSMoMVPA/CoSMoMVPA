function [chantypes,senstype_mapping]=cosmo_meeg_chantype(ds,varargin)
% return channel types and optionally a feature mask matching a type
%
% [chantypes,senstype_mapping]=cosmo_meeg_chantype(ds)
%
% Inputs:
%    ds                 dataset struct for MEEG dataset
%
% Output:
%    chantypes          1xN cell with type of each channel in ds, where
%                       N is the number of channels.
%    senstype_mapping   struct with keys the unique chantypes, and values
%                       the sensor (acquisition) type
%
% Example:
%     % This example requires FieldTrip
%     cosmo_skip_test_if_no_external('fieldtrip');
%     %
%     % generate synthetic dataset with meg_planar and meg_axial channels
%     % as found in the neuromag306 system
%     ds=cosmo_synthetic_dataset('type','meeg','sens','neuromag306_all',...
%                     'size','big','nchunks',1,'ntargets',1);
%     [chantypes,senstypes]=cosmo_meeg_chantype(ds);
%     cosmo_disp(chantypes,'edgeitems',2);
%     %|| { 'meg_axial'  'meg_planar' ... 'meg_planar' 'meg_planar' }@1x306
%     cosmo_disp(senstypes,'strlen',inf);
%     %|| .meg_axial
%     %||   'neuromag306alt_mag'
%     %|| .meg_planar
%     %||   'neuromag306alt_planar'
%     %
%     % filter the dataset to only contain the planar channels:
%     %
%     % see which features have a matching channel
%     chan_indices=find(cosmo_match(chantypes,'meg_planar'));
%     planar_msk=cosmo_match(ds.fa.chan,chan_indices);
%     % slice and prune dataset along feature dimension
%     ds_planar=cosmo_slice(ds,planar_msk,2);
%     ds_planar=cosmo_dim_prune(ds_planar);
%     % the output dataset has only the 204 planar channels left
%     cosmo_disp(ds_planar.a.fdim,'edgeitems',2);
%     %|| .labels
%     %||   { 'chan'
%     %||     'time' }
%     %|| .values
%     %||   { { 'MEG0112'  'MEG0113' ... 'MEG2642'  'MEG2643'   }@1x204
%     %||     [ -0.2     -0.15  ...  0.05       0.1 ]@1x7               }
%     %
%     cosmo_disp(ds_planar.fa.chan);
%     %|| [ 1         2         3  ...  202       203       204 ]@1x1428
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    persistent cached_opt;
    persistent cached_ds_labels;
    persistent cached_chantypes;
    persistent cached_senstype_mapping

    ds_labels=get_channel_labels(ds);

    defaults=struct();
    % quality scores of match between labels and senstype
    % ('secret' feature)
    defaults.label_threshold=.25;
    defaults.layout_threshold=.3;
    defaults.both_threshold=.1;
    opt=cosmo_structjoin(defaults,varargin);


    if ~(isequal(opt, cached_opt) && isequal(cached_ds_labels,ds_labels))
        [cached_chantypes,cached_senstype_mapping]=get_meeg_chantype(...
                                                    ds_labels,opt);
        cached_opt=opt;
        cached_ds_labels=ds_labels;
    end
    chantypes=cached_chantypes;
    senstype_mapping=cached_senstype_mapping;


function [chantypes,senstype_mapping]=get_meeg_chantype(labels,opt)
    nlabels=numel(labels);

    senstype_collection=cosmo_meeg_senstype_collection();
    keys=fieldnames(senstype_collection);
    nkeys=numel(keys);

    % get channel types and labels for each sensor type
    all_chantypes=cell(nkeys,1);
    all_senstypes=cell(nkeys,1);
    all_sens_labels=cell(nkeys,1);
    for k=1:nkeys
        key=keys{k};
        senstype=senstype_collection.(key);
        all_senstypes{k}=senstype.sens;
        all_sens_labels{k}=senstype.label(:);
        all_chantypes{k}=senstype.type;
    end

    % compute quality for each sensor type
    all_quality=compute_overlap(labels, all_sens_labels);

    % restrict to the best one in each modality
    [keep_idxs,quality]=get_best_idxs(all_quality,opt);
    keep_types=all_chantypes(keep_idxs);
    keep_quality=quality(keep_idxs);

    if isempty(keep_quality)
        error('Could not identify channel type');
    end

    % set the channel types
    [idxs,unq_types_cell]=cosmo_index_unique({keep_types});
    sens_chantypes=unq_types_cell{1};
    nsenstypes=numel(idxs);

    visited_msk=false(size(labels));
    chantypes=cell(size(labels));
    senstype_mapping=struct();

    for k=1:nsenstypes;
        idx=idxs{k};
        [unused,i]=max(keep_quality(idx));
        all_idx=keep_idxs(idx(i));

        hit_msk=cosmo_match(labels,all_sens_labels{all_idx});
        chantypes(~visited_msk & hit_msk)=sens_chantypes(k);
        visited_msk=visited_msk|hit_msk;

        senstype_mapping.(sens_chantypes{k})=keys{all_idx};
    end

    chantypes(~visited_msk)={'unknown'};

function [keep_idxs,quality]=get_best_idxs(all_quality, opt)

    qs=[all_quality, mean(all_quality,2)];
    thrs=[opt.label_threshold, opt.layout_threshold opt.both_threshold];

    nsens=size(qs,1);
    keep_msk=true(nsens,1);

    for j=1:3
        quality=qs(:,j);
        exceed_thr=quality>thrs(j);

        if any(exceed_thr)
            keep_msk=keep_msk & exceed_thr;
        end

    end

    if any(keep_msk)
        keep_idxs=find(keep_msk);
        return
    end

    error('Could not identify channel type');

function quality=compute_overlap(x,ys)
    [q1,q2]=cosmo_overlap(ys,{x});
    quality=[q1 q2];



function chan_labels=get_channel_labels(ds)
    if iscellstr(ds)
        chan_labels=ds;
    else
        [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'chan',true);
        chan_labels=ds.a.(dim_name).values{index};
    end



