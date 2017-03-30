function stat_ds=cosmo_phase_stat(ds,varargin)
% Compute phase perturbation, or opposition sum or product phase statistic
%
% stat_ds=cosmo_phase_stat(ds,...)
%
% Inputs:
%   ds                      dataset struct with fields:
%       .samples            PxQ complex matrix for P samples (trials,
%                           observations) and Q features (e.g. combinations
%                           of time points, frequencies and channels)
%       .sa.targets         Px1 array with trial conditions.
%                           There must be exactly two conditions, thus
%                           .sa.targets must have exactly two unique
%                           values.
%       .sa.chunks          Px1 array indicating which samples can be
%                           considered to be independent. It is required
%                           that all samples are independent, therefore
%                           all values in .sa.chunks must be different from
%                           each other
%       .fa                 } optional feature attributes
%       .a                  } optional sample attributes
%  'output',p               Return statistic, one of the following:
%                           - 'pbi' - phase bifurcation index
%                           - 'pos' - phase opposition sum
%                           - 'pop' - phase opposition product
%  'samples_are_unit_length',u  (optional)
%                           If u==true, then all elements in ds.samples
%                           are assumed to be already of unit length. If
%                           this is indeed true, this can speed up the
%                           computation of the output.
%  'sample_balancer', f       (optional)
%                           If targets are unbalanced (there are more
%                           trials in one condition than in the other one),
%                           this function is used to balance the targets.
%                           If the smallest number of targets is S,
%                           this function must have the signature
%                             idxs=f(t1,t2,seed)
%                           where t1 and t2 are vectors with the target
%                           positions, seed is an optional value that can
%                           be used for a pseudo-random number generator,
%                           and idxs is an Sx2 matrix containing the
%                           balanced indices for the rows in targets for
%                           the two classes.
%                           By default a function is used that
%                           pseudo-randomly selects a subset for each
%                           class.
%  'check_dataset',c        (optional, default=true)
%                           if c==false, there is no check for consistency
%                           of the ds input.
%
% Output:
%   stat_ds                 struct with fields
%       .samples            1xQ array with 'pbi', 'pos', or 'pop' function
%       .a                  } if present in the input, then the output
%       .fa                 } contains these fields as well
%
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    default=struct();
    default.sample_balancer=@default_sample_balancer;
    default.check_dataset=true;
    default.seed=1;
    opt=cosmo_structjoin(default,varargin{:});

    check_inputs(ds,opt);

    % balance dataset
    balanced_ds=balance_dataset(ds,opt);

    % compute inter-trial coherence for the two conditions
    itc_ds=cosmo_phase_itc(balanced_ds,opt);

    %itc_ds must have three rows in .samples
    assert(size(itc_ds.samples,1)==3);
    assert(isnan(itc_ds.sa.targets(3)));

    % compute PBI, POP or POS
    itc1=itc_ds.samples(1,:);
    itc2=itc_ds.samples(2,:);
    itc_all=itc_ds.samples(3,:);

    stat=compute_phase_stat(opt.output,itc1,itc2,itc_all);

    % set result
    stat_ds=cosmo_slice(itc_ds,1,1,false);
    stat_ds.samples=stat;
    stat_ds.sa=struct();



function s=compute_phase_stat(name, itc1, itc2, itc_all)
    switch name
        case 'pbi'
            s=(itc1-itc_all).*(itc2-itc_all);

        case 'pop'
            s=(itc1.*itc2)-itc_all.^2;

        case 'pos'
            s=itc1+itc2-2*itc_all;

        otherwise
            assert(false,'this should not happen');
    end




function balanced_ds=balance_dataset(ds,opt)
    target_idxs=cosmo_index_unique(ds.sa.targets);

    if numel(target_idxs)~=2
        error('Need exactly two targets');
    end

    sample_idxs=opt.sample_balancer(target_idxs{1},target_idxs{2},...
                                opt.seed);
    balanced_ds=cosmo_slice(ds,sample_idxs,1,false);


function idxs=default_sample_balancer(t1,t2,seed)
    n1=numel(t1);
    n2=numel(t2);

    if n1<n2
        idxs=[t1,select_subset_from(t2,n1,seed)];
    else
        idxs=[select_subset_from(t1,n2,seed),t2];
    end

function vec_subset=select_subset_from(vec, count, seed)
    % pseudo-random selection of subset
    idxs=cosmo_randperm(numel(vec),count,'seed',seed);
    vec_subset=vec(idxs);


function [t1,t2]=get_two_targets_row(targets)
    idxs=cosmo_index_unique(targets);
    if numel(idxs)~=2
        error('Input must have exactly two unique values in .sa.targets');
    end
    t1=idxs{1};
    t2=idxs{2};

function check_inputs(ds,opt)
    if opt.check_dataset
        cosmo_check_dataset(ds);
    end

    if ~(isstruct(ds) ...
            && isfield(ds,'samples') ...
            && isfield(ds,'sa') ...
            && isfield(ds.sa,'targets'))
        error(['first input must be struct with fields .samples and '...
                            '.sa.targets']);
    end

    if ~isa(opt.sample_balancer,'function_handle')
        error('option ''sample_balancer'' must be a function handle');
    end

    if ~isfield(opt,'output')
        error('option ''output'' is required');
    end

    allowed_values={'pbi','pos','pop'};
    if ~cosmo_match({opt.output},allowed_values)
        error('option ''output'' must be one of: ''%s''',...
                cosmo_strjoin(allowed_values,''', '''));
    end

