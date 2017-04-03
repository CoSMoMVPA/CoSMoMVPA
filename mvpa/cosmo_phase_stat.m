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
%                           values. A balanced number of samples is
%                           requires, i.e. each of the two unique values in
%                           .sa.targets must occur equally often.
%       .sa.chunks          Px1 array indicating which samples can be
%                           considered to be independent. It is required
%                           that all samples are independent, therefore
%                           all values in .sa.chunks must be different from
%                           each other
%       .fa                 } optional feature attributes
%       .a                  } optional sample attributes
%  'output',p               Return statistic, one of the following:
%                           - 'pbi': phase bifurcation index
%                           - 'pos': phase opposition sum
%                           - 'pop': phase opposition product
%  'samples_are_unit_length',u  (optional)
%                           If u==true, then all elements in ds.samples
%                           are assumed to be already of unit length. If
%                           this is indeed true, this can speed up the
%                           computation of the output.
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
% Notes:
%   - if a dataset is not balanced for number of trials, consider using
%     cosmo_balance_dataset to balance it.
%
% See also: cosmo_balance_dataset, cosmo_phase_itc
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    default=struct();
    default.check_dataset=true;
    opt=cosmo_structjoin(default,varargin{:});

    check_inputs(ds,opt);

    % compute inter-trial coherence for the two conditions using
    % cosmo_phase_itc, which will thrown an error if samples are not
    % balanced.
    itc_ds=cosmo_phase_itc(ds,opt);

    % itc_ds must have last entry to be NaN, indicating it is the ITC for
    % all trials together
    if size(itc_ds.samples,1)~=3
        error(['Input must have exactly two unique values '...
                        'for .sa.targets']);
    end

    assert(isequal([false;false;true],isnan(itc_ds.sa.targets)));

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


    if ~isfield(opt,'output')
        error('option ''output'' is required');
    end

    allowed_values={'pbi','pos','pop'};
    if ~cosmo_match({opt.output},allowed_values)
        error('option ''output'' must be one of: ''%s''',...
                cosmo_strjoin(allowed_values,''', '''));
    end

