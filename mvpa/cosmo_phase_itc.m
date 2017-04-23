function itc_ds=cosmo_phase_itc(ds,varargin)
% compute phase inter trial coherence
%
% itc_ds=cosmo_phase_itc(ds,varargin)
%
% Inputs:
%   ds                      dataset struct with fields:
%       .samples            PxQ complex matrix for P samples (trials,
%                           observations) and Q features (e.g. combinations
%                           of time points, frequencies and channels)
%       .sa.targets         Px1 array with trial conditions. Each condition
%                           must occur equally often; that is, the
%                           samples must be balanced.
%                           In the typical case of two conditions,
%                           .sa.targets must have exactly two unique
%                           values.
%       .sa.chunks          Px1 array indicating which samples can be
%                           considered to be independent. It is required
%                           that all samples are independent, therefore
%                           all values in .sa.chunks must be different from
%                           each other
%       .fa                 } optional feature attributes
%       .a                  } optional sample attributes
%  'samples_are_unit_length',u  (optional, default=false)
%                           If u==true, then all elements in ds.samples
%                           are assumed to be already of unit length. If
%                           this is indeed true, this can speed up the
%                           computation of the output.
%  'check_dataset',c        (optional, default=true)
%                           if c==false, there is no check for consistency
%                           of the ds input.
%
% Output:
%   itc_ds                  dataset struct with fields:
%       .samples            (N+1)xQ array with inter-trial coherence
%                           measure, where U=unique(ds.sa.targets) and
%                           N=numel(U). The first N rows correspond to the
%                           inter trial coherence for each condition. The
%                           last row is the inter trial coherence for all
%                           samples together.
%       .sa.targets         (N+1)x1 vector containing the values
%                           [U(:);NaN]' with trial conditions
%       .a                  } if present in the input, then the output
%       .fa                 } contains these fields as well
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.samples_are_unit_length=false;
    defaults.check_dataset=true;

    opt=cosmo_structjoin(defaults,varargin{:});

    check_input(ds,opt);

    samples=ds.samples;
    if opt.samples_are_unit_length
        quick_check_some_samples_being_unit_length(samples);
    else
        % normalize
        samples=samples./abs(samples);
    end

    % split based on .sa.targets
    [idxs,classes]=cosmo_index_unique(ds.sa.targets);
    nclasses=numel(classes);
    nfeatures=size(samples,2);

    % allocate space for output
    itc=zeros(nclasses+1,nfeatures);

    % ITC for each class
    for k=1:nclasses
        samples_k=samples(idxs{k},:);
        itc(k,:)=itc_on_unit_length_elements(samples_k);
    end

    % overall ITC
    itc(nclasses+1,:)=itc_on_unit_length_elements(samples);

    % set output
    itc_ds=set_output(itc,ds,classes);


function itc_ds=set_output(itc,ds,classes)
    % store results
    itc_ds=struct();
    itc_ds.samples=itc;
    itc_ds.sa.targets=[classes(:); NaN];

    % copy .a and .fa fields, if present
    if isfield(ds,'a')
        itc_ds.a=ds.a;

        if isfield(ds.a,'sdim')
            % remove sample dimensions if present
            itc_ds.a=rmfield(itc_ds.a,'sdim');
        end
    end

    if isfield(ds,'fa')
        itc_ds.fa=ds.fa;
    end


function itc=itc_on_unit_length_elements(samples)
    % computes inter-trial coherence for each column seperately
    itc=abs(sum(samples,1)/size(samples,1));


function quick_check_some_samples_being_unit_length(samples)
    % instead of checking all values, only verify for a subset of values.
    % This should prevent most use cases where the user accidentally
    % uses non-normalized data, whereas checking all values would be
    % equivalent to actually computing their length for each of them.
    count_to_check=10;

    % generate random positions to check for unit length
    nelem=numel(samples);
    pos=ceil(rand(1,count_to_check)*nelem);

    samples_subset=samples(pos);
    lengths=abs(samples_subset);

    % safety margin
    delta=10*eps('single');
    if any(lengths+delta<1 | lengths-delta>1)
        error('.samples input is not of unit length');
    end


function check_input(ds,opt)
    % must be a proper dataset
    if opt.check_dataset
        raise_exception=true;
        cosmo_check_dataset(ds,raise_exception);

        % must have targets and chunks
        cosmo_isfield(ds,{'sa.targets','sa.chunks'},raise_exception);
    end

    % all chunks must be unique
    if ~isequal(sort(ds.sa.chunks),unique(ds.sa.chunks))
        error(['All values in .sa.chunks must be different '...
                    'from each other']);
    end

    % trial counts must be balanced
    [idxs,classes]=cosmo_index_unique(ds.sa.targets);
    class_count=cellfun(@numel,idxs);
    unequal_pos=find(class_count~=class_count(1),1);
    if ~isempty(unequal_pos)
        error(['.sa.targets indicates unbalanced targets, with '...
                        '.sa.targets==%d occuring %d times, and '...
                        '.sa.targets==%d occuring %d times.\n'...
                        'To obtain balanced targets, consider '...
                        'using cosmo_balance_dataset.'],...
                    classes(1),class_count(1),...
                    classes(unequal_pos),class_count(unequal_pos));
    end

    % input must be complex
    if isreal(ds.samples)
        error('.samples must be complex');
    end

    v=opt.samples_are_unit_length;
    if ~(islogical(v) ...
            && isscalar(v))
        error('option ''samples_are_unit_length'' must be logical scalar');
    end
