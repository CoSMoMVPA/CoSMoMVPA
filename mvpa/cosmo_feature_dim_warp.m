function ds_warped=cosmo_feature_dim_warp(ds_base, ds_towarp, label)
% Warps feature attributes from one dataset to match another one.
% 
% ds_warped=cosmo_feature_dim_warp(ds_base, ds_towarp, label)
% 
% Inputs:
%   ds_base      base dataset struct
%   ds_towarp    dataset struct that is to be warped to ds_base.
%                ds_base.a.dim and ds_towarp.a.dim have to be present
%                and identical
%   label        feature attribute label that has to be present in
%                both ds_base.fa and ds_towarp.fa (default: 'time').
%
% Output:
%   ds_warped    dataset struct with the same data as ds_towarp but
%                with ds_warped.fa.(label) matched to ds_base.fa.(label).
%
% Note:
%  - A use case is matching MEEG datasets in a pre and post stimulus period
%
% Example:
%   - % ds_pre and ds_post are MEEG datasets with data form pre- and post-
%     % stimulus onsets
%     ds_pre=ds_warped(ds_post, ds_pre);
%     > % now ds_pre has the same time information as ds_pre and can
%       % be stacked
%
% Use case; time warp of pre and post period

    if nargin<3, label='time'; end

    [ns_base, nf_base]=size(ds_base.samples);
    [ns_towarp, nf_other]=size(ds_towarp.samples);

    if nf_base ~= nf_other, 
        error('Feature count mismatch: %d ~= %d', nf_base, nf_other);
    end

    [base_values, base_idxs]=get_values_indices(ds_base, label);
    [towarp_values, towarp_idxs]=get_values_indices(ds_towarp, label);

    % compute the (usually time) difference between base and towarp.
    % the difference should be very small for all features.
    delta=base_values-towarp_values;
    epsilon=1e-5; % allowed difference in time
    mismatch_idx=find(abs(delta(1)-delta)>epsilon,1);

    if ~isempty(mismatch_idx)
        error(['Cannot warp because of mismatch between feature %d and %d',...
                ' with delta values %d and %d (delta=%d)'], ...
                base_idxs(1), base_idxs(mismatch_idx),...
                delta(1), delta(mismatch_idx), delta(1), ...
                delta(mismatch_idx)-delta(1));
    end

    ds_warped=ds_towarp;
    ds_warped.fa.(label)=ds_base.fa.(label);

    % check it works - any mismatch in fa should be caught here
    cosmo_stack({ds_warped, ds_base});


function [values, indices]=get_values_indices(ds, label)
    % helper function: given a dataset and an fa label, return
    % the values and indices for that fa.
    if ~isfield(ds,'a') || ~isfield(ds.a,'dim') || ...
            ~isfield(ds.a.dim,'labels') || ~isfield(ds.a.dim,'values')
        error('Need .a.dim.{label,values}');
    end

    dim=find(cosmo_match(ds.a.dim.labels, label));
    if numel(dim)~=1
        error('match error for label %s', label); 
    end

    indices=ds.fa.(label);
    values=ds.a.dim.values{dim}(indices);





