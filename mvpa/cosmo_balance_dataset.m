function [balanced_ds,idxs,classes]=cosmo_balance_dataset(ds,varargin)
% sub-sample a dataset to have an equal number of samples for each target
%
% [balanced_ds,idxs,classes]=cosmo_balance_dataset(ds)
%
% Inputs:
%   ds                      dataset struct with fields .samples,
%                           .sa.targets and .sa.chunks. All values in
%                           .sa.chunks must be different from each other.
%   'sample_balancer', f    (optional)
%                           function handle with signature
%                               [idxs,classes]=f(targets,seed)
%                           where idxs is a SxC vector with indices for C
%                           classes and S targets per class. If omitted a
%                           builtin function is used.
%   'seed', s               (optional, default=1)
%                           Seed to use for pseudo-random number generation
%
% Output:
%   balanced_ds             dataset with a subset of the samples from ds
%                           so that each target occurs equally often.
%                           Selection is (by default) done in a
%                           pseudo-determistic manner.
%   idxs                    SxC vector indicating which
%   classes                 Cx1 vector containing unique class labels
%
% Notes:
%   - this function is to be used with MEEG datasets. it is not intended
%     for fMRI data.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    defaults=struct();
    defaults.seed=1;
    defaults.sample_balancer=[];

    opt=cosmo_structjoin(defaults,varargin{:});

    check_inputs(ds,opt)

    [idxs,classes]=select_subset(ds.sa.targets,opt);
    balanced_ds=cosmo_slice(ds,idxs(:),1);


function [idxs,classes]=select_subset(targets,opt)
    sample_balancer=opt.sample_balancer;
    if isempty(sample_balancer)
        sample_balancer=@default_sample_balancer;
    end

    [idxs,classes]=sample_balancer(targets,opt.seed);


function [idxs,classes]=default_sample_balancer(targets,seed)
    [all_idxs,classes]=cosmo_index_unique(targets);
    class_counts=cellfun(@numel,all_idxs);

    min_count=min(class_counts);
    max_count=max(class_counts);

    nclasses=numel(class_counts);
    % invoke PRNG only once
    rand_vals=cosmo_rand(max_count,nclasses,'seed',seed);

    idxs=zeros(min_count,nclasses);
    for k=1:nclasses
        % set class_idxs to have values in the range 1:class_counts in
        % random order
        [unused,class_idxs]=sort(rand_vals(1:class_counts(k),k));

        % select min_count values from the indices in class_idxs
        idxs(:,k)=all_idxs{k}(class_idxs(1:min_count));
    end


function check_inputs(ds,opt)
    cosmo_check_dataset(ds);

    % chunks and targets must be present
    raise_exception=true;
    cosmo_isfield(ds,{'sa.targets','sa.chunks'},raise_exception);

    chunks=ds.sa.chunks;
    if numel(sort(chunks)) ~= numel(unique(chunks))
        error(['All values in .sa.chunks must be unique. If '...
                '*and only if* all '...
                'observations in .samples can be assumed to be '...
                'independent, for a dataset ds you can set '...
                '  ds.sa.chunks(:)=1:numel(ds.sa.chunks,1)'...
                'to indicate independence. This assumption typically '...
                'only applies to M/EEG datasets; this function should '...
                'not be used for typical fMRI datasets']);
    end






