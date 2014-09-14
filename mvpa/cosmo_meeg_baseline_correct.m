function bl_ds=cosmo_meeg_baseline_correct(ds, reference, method)
% correct baseline of MEEG dataset
%
% bl_ds=cosmo_meeg_baseline_correct(ds, reference, method)
%
% Inputs:
%     ds            MEEG dataset struct with 'time' feature dimension
%     reference     Either:
%                   - interval [start, stop], with start and stop in
%                     seconds (in this case, parameters are estimated in
%                     this time interval)
%                   - MEEG dataset struct with 'time' feature dimension,
%                     with features  (in this case, parameters are
%                     estimated using this dataset)
%     method        One of:
%                   - 'absolute'   : bl=samples-mu
%                   - 'relative'   : bl=samples/mu
%                   - 'relchange'  : bl=(samples-mu)/mu
%                   - 'db'         : bl=10*log10(samples/mu)
%
% Output:
%     bl_ds         MEEG dataset struct with the same shape as ds,
%                   where samples are baseline corrected using reference.
%                   This is done separately for each combination of values
%                   in feature dimensions different from 'time', e.g.
%                   for 'chan' for a timelock dataset and for 'chan' and
%                   'freq' combinations for a timefreq dataset
%
%
% Examples:
%     % illustrate 'relative' baseline correction
%     ds=cosmo_synthetic_dataset('type','timelock','size','small');
%     ds=cosmo_slice(ds,1:2); % take first two samples
%     ds_rel=cosmo_meeg_baseline_correct(ds,[-.3,-.18],'relative');
%     cosmo_disp(ds_rel.samples);
%     > [ 1      1.39         1     -1.13         1      1.22
%     >   1     0.773         1      1.34         1      18.2 ]
%
%     % illustrate 'absolute' baseline correction
%     ds=cosmo_synthetic_dataset('type','timelock','size','small');
%     ds=cosmo_slice(ds,1:2); % take first two samples
%     ds_abs=cosmo_meeg_baseline_correct(ds,[-.3,-.18],'absolute');
%     cosmo_disp(ds_abs.samples);
%     > [ 0     0.871         0     0.922         0     0.163
%     >   0    -0.417         0     0.692         0     -1.08 ]
%
%     % illustrate use of another dataset as reference
%     ds=cosmo_synthetic_dataset('type','timelock','size','small');
%     ds=cosmo_slice(ds,1:2); % take first two samples
%     ref=cosmo_synthetic_dataset('type','timelock','size','small');
%     ref=cosmo_slice(ref,1:2);
%     ds_ref_relch=cosmo_meeg_baseline_correct(ds,ref,'relchange');
%     cosmo_disp(ds_ref_relch.samples);
%     > [ -0.165     0.165     -16.7      16.7    -0.101     0.101
%     >    0.128    -0.128    -0.146     0.146    -0.896     0.896 ]
%
% NNO Sep 2014


if isstruct(reference)
    f=@baseline_correct_ds;
elseif isnumeric(reference)
    f=@baseline_correct_interval;
else
    error('illegal reference: expected dataset struct or vector');
end

baseline_label='time';
check_dataset(ds, baseline_label)
bl_ds=f(ds, reference, baseline_label, method);

function check_dataset(ds, baseline_label)
    cosmo_check_dataset(ds);

    [dim, index]=cosmo_dim_find(ds,baseline_label,true);
    if dim~=2
        error(['''%s'' must be feature dimension, found as '...
                'sample dimension'], baseline_label);
    end

function bl=baseline_correct(samples, mu, method)
    assert(size(samples,1)==size(mu,1));
    assert(isvector(mu));
    assert(ismatrix(samples));

    switch method
        case 'absolute'
            bl=bsxfun(@minus,samples,mu);
        case 'relchange'
            % use absolute and relative, i.e. (samples-mu)/mu
            bl=baseline_correct(baseline_correct(samples,mu,'absolute'),...
                        mu,'relative');
        case 'relative'
            bl=bsxfun(@rdivide,samples,mu);
        case 'vssum'
            bl=bsxfun(@rdivide,baseline_correct(samples,mu,'absolute'),...
                        bsxfun(@plus,samples,mu));
        case 'db'
            bl=10*log10(baseline_correct(samples,mu,'relative'));
        otherwise
            error('illegal baseline correction method ''%s''',method);
    end

function bl_ds=baseline_correct_interval(ds,interval,baseline_label,method)
    if numel(interval)~=2
        error('interval must have two values');
    end

    matcher=@(x) interval(1) <= x & x <= interval(2);
    msk=cosmo_dim_match(ds,baseline_label,matcher);

    reference=cosmo_slice(ds,msk,2);
    bl_ds=baseline_correct_ds(ds,reference,baseline_label,method);


function bl_ds=baseline_correct_ds(ds,reference,baseline_label,method)
    check_dataset(reference,baseline_label);

    % ensure compatible at sample dimension
    [ds1,ds_sa]=first_feature(ds);
    [ref1,ref_sa]=first_feature(reference);
    if ~isequal(ref_sa, ds_sa)
        error('.sa mismatch for input and reference dataset');
    end

    % split both
    ds_split=split_by_other(ds, baseline_label);
    reference_split=split_by_other(reference, baseline_label);

    n=numel(ds_split);
    nref=numel(reference_split);
    if n~=nref
        error(['Input dataset has different number of dimension '...
                    'combinations (%d) than reference dataset (%d)'],...
                    n,nref);
    end

    parts=cell(n,1);
    for k=1:n
        part_ds=ds_split{k};
        part_reference=reference_split{k};

        mu=mean(part_reference.samples,2);

        ds_split{k}.samples=baseline_correct(part_ds.samples,mu,method);
    end

    bl_ds=cosmo_stack(ds_split,2);

function ds_split=split_by_other(ds, baseline_label)
    other_dims=setdiff(ds.a.fdim.labels,{baseline_label});
    ds_split=cosmo_split(ds,other_dims,2);


function [ds1, sa]=first_feature(ds, remove_fields)
    ds1=cosmo_slice(ds,1,2);
    nsamples=size(ds1.samples,1);

    require_matching_sa=true; % disabled for now
    sa=struct();
    if require_matching_sa
        if nargin<2
            remove_fields={'targets','labels'};
        end

        if isfield(ds,'sa')
            sa=ds1.sa;
            for k=1:numel(remove_fields)
                remove_field=remove_fields{k};
                if isfield(sa,remove_field)
                    sa=rmfield(sa,remove_field);
                end
            end
        end
    end
