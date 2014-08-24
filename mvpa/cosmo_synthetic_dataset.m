function ds=cosmo_synthetic_dataset(varargin)
% generate synthetic dataset
%
% ds=cosmo_synthetic_dataset(varargin)
%
% Inputs:
%   'size', s               determines the number of features. One of
%                           'tiny', 'small', 'normal', 'big', or 'huge'
%   'type', t               type of dataset. One of 'fmri', 'meeg',
%                           'timelock', 'timefreq', 'surface'. 'meeg' is
%                           equivalent to 'timelock'
%   'chan', c               for meeg datasets ('time{lock}, 'meeg'), this
%                           sets which channels from the neuromag system
%                           are used. One of 'all', 'planar', 'mag',
%                           'combined', or 'mag+combined'.
%
%   'sigma', sigma          parameter to influence class distance. The
%                           larger this value, the more discrimable the
%                           classes are.
%
%   'ntargets', nt          number of unique targets (default: 2)
%   'nchunks', nc           number of unique chunks (default: 3)
%
%   'nmodalities', nm       number of unique modalities (default: [])
%   'nsubjects', ns         number of unique subjects (default: [])
%   'nreps', nr             number of sample repeats (default: [])
%
% Output:
%    ds                     dataset struct according to parameters.
%                           The output has (nt*nc*nm*ns*nr) samples, and
%                           the number of features is determined by s.
%                           If any of the nt, nc, nm, ns, nr values are not
%                           empty, there is a corresponding sample
%                           attribute.
%
% Examples:
%
%
% NNO Aug 2014

    default=struct();
    default.ntargets=2;
    default.nchunks=3;

    default.sigma=3;
    default.size='small';
    default.type='fmri';

    default.nreps=[];
    default.nmodalities=[];
    default.nsubjects=[];
    default.chunks=[];
    default.targets=[];

    % for MEEG
    default.chan='all';

    opt=cosmo_structjoin(default,varargin);

    [ds, nfeatures]=get_fdim_fa(opt.type, opt.size, opt.chan);

    sa_labels_pl={'ntargets','nchunks','nmodalities','nsubjects','nreps'};
    cp=cosmo_cartprod(cellfun(@(x)1:max([opt.(x) 1]),sa_labels_pl,...
                                            'UniformOutput',false));
    sa_labels_si={'targets','chunks','modality','subject','rep'};
    for k=1:numel(sa_labels_si)
        if ~isempty(opt.(sa_labels_pl{k}))
            ds.sa.(sa_labels_si{k})=cp(:,k);
        end
    end


    nelem=log(nfeatures*max([opt.nreps 1]));
    class_distance=opt.sigma/nelem;

    ds.samples=generate_samples(ds, class_distance);
    ds=assign_sa(ds, opt, {'chunks','targets'});

    cosmo_check_dataset(ds);

function ds=assign_sa(ds, opt, names)
    nsamples=size(ds.samples,1);

    for k=1:numel(names)
        name=names{k};
        v=opt.(name);
        if ~isempty(v)
            if ~isscalar(v)
                error('Value for ''%s'' must be a scalar', name);
            end
            ds.sa.(name)=ones(nsamples,1)*v;
        end
    end


function samples=generate_samples(ds, class_distance)

    targets=ds.sa.targets;
    nsamples=numel(targets);
    nclasses=numel(unique(targets));

    fa_names=fieldnames(ds.fa);
    nfeatures=numel(ds.fa.(fa_names{1}));

    if cosmo_wtf('is_matlab')
        rng_state=rng();
        c=onCleanup(@()rng(rng_state));
        rng('default');
    else
        rng_state=randn('state');
        c=onCleanup(@()randn('state',rng_state));
        randn('default');
    end

    samples=randn(nsamples,nfeatures);

    for k=1:nfeatures
        class_msk=mod(k-targets, nclasses+1)==0;
        samples(class_msk,k)=samples(class_msk,k)+class_distance;
    end

function a=dim_labels_values(data_type, chan_type)
    a=struct();

    switch data_type
        case 'fmri'
            a.vol.mat=eye(4);
            a.vol.mat(1:3,1:3)=a.vol.mat(1:3,1:3)*10;

            labels={'i','j','k'};
            values={1:20,1:20,1:20};

        case {'meeg','timelock','timefreq'}
            % simulate full neuromag 306 system
            chan=get_neuromag_chan(chan_type);

            time=-.2:.05:1.3;

            switch data_type
                case 'timefreq'
                    freq=2:2:40;
                    values={chan,freq,time};
                    labels={'chan','freq','time'};
                    a.meeg.samples_type='timefreq';
                    a.meeg.samples_field='powspctrm';

                otherwise % meeg and timelock
                    values={chan,time};
                    labels={'chan','time'};
                    a.meeg.samples_type='timelock';
                    a.meeg.samples_field='trial';
            end

            a.meeg.samples_label='rpt';
            a.hdr_ft=struct();

        case 'surface'
            labels={'node_indices'};
            values={1:4000};

        otherwise
            error('Unsupported type ''%s''', data_type);
    end

    a.fdim.values=values;
    a.fdim.labels=labels;

function labels=get_neuromag_chan(chan_type)
    % get channels for neuromag system
    all_chan_idxs=cosmo_cartprod(cellfun(@num2cell,...
                                   {1:26,1:4},'UniformOutput',false));
    remove_msk=cosmo_match(all_chan_idxs(:,1), 8) & ...
                        cosmo_match(all_chan_idxs(:,2),[3 4]);
    chan_idxs=all_chan_idxs(~remove_msk,:);
    nloc=size(chan_idxs,1);
    assert(nloc==102);

    % columns are: mag, planar1, planar2, combined
    labels=cell(nloc,4);
    for k=1:nloc
        chan_idx=chan_idxs(k,:);
        for j=1:3
            labels{k,j}=sprintf('MEG%02d%d%d',chan_idx,j);
        end
        labels{k,4}=sprintf('MEG%02d%d%d+%02d%d%d',...
                                chan_idx,2,chan_idx,3);
    end

    keep_col=false(1,4);
    types=cosmo_strsplit(chan_type,'+');
    for k=1:numel(types)
        tp=types{k};
        switch tp
            case 'all'
                keep_col([1 2 3])=true;
            case {'cmb','combined'}
                keep_col(4)=true;
            case 'planar'
                keep_col([2 3])=true;
            case 'mag'
                keep_col(1)=true;
            otherwise
                error('Unsupported channel type %s', tp);
        end
    end

    if any(keep_col(2:3)) && keep_col(4)
        error('planar and cmb/combined are mutually exclusive');
    end

    labels=labels(:,keep_col)';
    labels=labels(:);


function dim_size=get_dim_size(size_label)
    % get dimension size. NaN means use input size
    size2dim=struct();
    size2dim.tiny=[2 1 1];
    size2dim.small=[3 2 1];
    size2dim.normal=[3 2 5];
    size2dim.big=[11 7 5];
    size2dim.huge=[NaN 17 19];

    if ~isfield(size2dim, size_label)
        error('Unsupported size %s. Supported are: %s',...
                    size_label, cosmo_strjoin(fieldnames(size2dim),', '));
    end

    dim_size=size2dim.(size_label);


function [ds, nfeatures]=get_fdim_fa(data_type, size_label, chan_type)
    % get dimension labels
    a=dim_labels_values(data_type, chan_type);
    labels=a.fdim.labels;
    values=a.fdim.values;
    a=rmfield(a,'fdim');

    % get dimension values
    dim_sizes=get_dim_size(size_label);
    dim_sizes=dim_sizes(1:numel(labels));

    for k=1:numel(dim_sizes)
        if isnan(dim_sizes(k))
            dim_sizes(k)=numel(values{k});
        end
        values{k}=values{k}(1:dim_sizes(k));
    end

    % get ds with proper size
    ds=cosmo_flatten(zeros([1 dim_sizes]),labels,values);
    ds.a=cosmo_structjoin(ds.a,a);
    if strcmp(data_type,'fmri')
        ds.a.vol.dim=dim_sizes;
    end

    nfeatures=prod(dim_sizes);

