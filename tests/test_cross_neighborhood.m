function test_suite=test_cross_neighborhood()
% tests for cosmo_cross_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_cross_neighborhood_time_freq()
    helper_test_cross_neighborhood(false);

function test_cross_neighborhood_chan_time_freq()
    if cosmo_skip_test_if_no_external('fieldtrip')
        return;
    end
    helper_test_cross_neighborhood(true);

function helper_test_cross_neighborhood(can_use_chan_nbrhood)
    ds_full=cosmo_synthetic_dataset('type','timefreq','size','big');
    msk=cosmo_match(ds_full.fa.chan,@(x)x<20);
    ds_full=cosmo_slice(ds_full,msk,2);
    ds_full=cosmo_dim_prune(ds_full);

    % make it sparse
    nfeatures=size(ds_full.samples,2);
    nkeep=round(nfeatures/4);
    fdim_values=ds_full.a.fdim.values;
    nchan=numel(fdim_values{1});
    nfreq=numel(fdim_values{2});
    ntime=numel(fdim_values{3});

    while true
        rp=randperm(nfeatures);
        ds=cosmo_slice(ds_full,rp(1:nkeep),2);
        ds=cosmo_dim_prune(ds);
        n=numel(ds.a.fdim.values{1});
        ds.a.fdim.values{1}=ds.a.fdim.values{1}(randperm(n));

        if numel(unique(ds.fa.chan))==nchan && ...
                    numel(unique(ds.fa.freq))==nfreq && ...
                    numel(unique(ds.fa.time))==ntime
            break
        end
    end

    nfeatures=size(ds.samples,2);

    % define neighborhoods
    freq_nbrhood=cosmo_interval_neighborhood(ds,'freq','radius',2);
    time_nbrhood=cosmo_interval_neighborhood(ds,'time','radius',1);
    if can_use_chan_nbrhood
        chan_nbrhood=cosmo_meeg_chan_neighborhood(ds,'count',5,...
                                'chantype','all','label','dataset');
    else
        chan_nbrhood='dummy';
    end

    all_nbrhoods={chan_nbrhood, freq_nbrhood, time_nbrhood};
    ndim=numel(all_nbrhoods);
    dim_labels={'chan';'freq';'time'};

    ntest=5;  % number of positions to test

    for i=7:-1:1
        use_chan=i<=4;
        use_freq=mod(i,2)==1;
        use_time=mod(ceil(i/2),2)==1;

        if ~can_use_chan_nbrhood && use_chan
            % no support for channel neighborhood, skip
            continue;
        end

        use_dim_msk=[use_chan;use_freq;use_time];
        nbrhood=cosmo_cross_neighborhood(ds,all_nbrhoods(use_dim_msk),...
                                                'progress',false);
        assertEqual(nbrhood.a.fdim.labels,dim_labels(use_dim_msk));
        assertEqual(fieldnames(nbrhood.fa),dim_labels(use_dim_msk));

        n=numel(nbrhood.neighbors);
        rp=randperm(n);

        for iter=1:min(n,ntest)
            pos=rp(iter);
            % verify neighborhoods in ds

            ds_fa=cosmo_slice(ds.fa,nbrhood.neighbors{pos},2,'struct');
            nbr_fa=cosmo_slice(nbrhood.fa,pos,2,'struct');

            nbr_msk=true(1,nfeatures);

            for dim=1:ndim
                dim_label=dim_labels{dim};
                if use_dim_msk(dim)
                    dim_nbrhood=all_nbrhoods{dim};

                    j=find(dim_nbrhood.fa.(dim_label)==nbr_fa.(dim_label));
                    assert(numel(j)==1);

                    m=false(1,nfeatures);
                    m(dim_nbrhood.neighbors{j})=true;
                else
                    assert(~isfield(nbrhood.fa,dim_label))
                    m=true(1,nfeatures);
                end

                nbr_msk=nbr_msk & m;

                fa=cosmo_slice(ds.fa.(dim_label),m,2);
                assert(isempty(setdiff(ds_fa.(dim_label),fa)));
            end

            assertEqual(nbrhood.neighbors{pos},find(nbr_msk));

            % test agreement between the crossed nbrhood and the
            % individual neighborhoods
            dim_nbr_msk=true(1,nfeatures);
            dim_pos=0;
            for dim=1:ndim
                if ~use_dim_msk(dim)
                    continue;
                end
                dim_pos=dim_pos+1;
                dim_label=dim_labels{dim};
                nbr_fa=nbrhood.fa.(dim_label);
                nbr_values=nbrhood.a.fdim.values{dim_pos}(nbr_fa(pos));

                dim_nbrhood=all_nbrhoods{dim};
                dim_nbr_values=dim_nbrhood.a.fdim.values{1};
                nbr_msk=cosmo_match(dim_nbr_values,nbr_values);

                m=false(size(dim_nbr_msk));
                m(dim_nbrhood.neighbors{nbr_msk})=true;
                dim_nbr_msk=dim_nbr_msk & m;
            end
            assertEqual(nbrhood.neighbors{pos},find(dim_nbr_msk));
        end
    end

function test_cross_neighborhood_transpose
    opt=struct();
    opt.progress=false;
    ds=cosmo_synthetic_dataset('type','timefreq','size','normal');
    ds=cosmo_dim_remove(ds,'chan');

    nh_time=cosmo_interval_neighborhood(ds,'time','radius',1);
    nh_freq=cosmo_interval_neighborhood(ds,'freq','radius',0);

    nh=cosmo_cross_neighborhood(ds,{nh_time,nh_freq},opt);

    cp=cosmo_cartprod(repmat({[false,true]},4,1));
    n=size(cp,1);

    for k=1:n
        t_label=cp{k,1};
        t_value=cp{k,2};
        t_elem1=cp{k,3};
        t_elem2=cp{k,4};

        ds2=ds;

        if t_label
            ds2.a.fdim.labels=ds2.a.fdim.labels';
        end

        if t_value
            ds2.a.fdim.values=ds2.a.fdim.values';
        end

        if t_elem1
            ds2.a.fdim.values{1}=ds2.a.fdim.values{1}';
        end

        if t_elem2
            ds2.a.fdim.values{2}=ds2.a.fdim.values{2}';
        end

        nh2_time=cosmo_interval_neighborhood(ds2,'time','radius',1);
        nh2_freq=cosmo_interval_neighborhood(ds2,'freq','radius',0);

        nh2=cosmo_cross_neighborhood(ds2,{nh2_time,nh2_freq},opt);
        assertEqual(nh2.a,nh.a);
        assertEqual(nh2.fa,nh.fa);
        assertEqual(nh2.neighbors,nh.neighbors);
    end





function test_cross_neighborhood_exceptions()
    ds=cosmo_synthetic_dataset('type','meeg','size','big');
    time_nbrhood=cosmo_interval_neighborhood(ds,'time','radius',1);

    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_cross_neighborhood(varargin{:}),'');

    aet(ds,{});
    aet(ds,struct);
    aet(ds,struct,time_nbrhood);
    aet(ds,time_nbrhood,time_nbrhood);
    aet(ds,ds);

    % should be fine
    assertEqual(cosmo_cross_neighborhood(ds,{time_nbrhood}),time_nbrhood);

    % no values too big
    time_nbrhood2=time_nbrhood;
    time_nbrhood2.neighbors{1}=1e9;
    aet(ds,{time_nbrhood2});

    % non-integers not supported
    time_nbrhood2=time_nbrhood;
    time_nbrhood2.neighbors{1}=1.5;
    aet(ds,{time_nbrhood2});

    % illegal labels
    time_nbrhood2=time_nbrhood;
    time_nbrhood2.a.fdim.labels{1}='foo';
    time_nbrhood2.fa.foo=time_nbrhood.fa.time;
    aet(ds,{time_nbrhood2});

    % duplicate labels
    aet(ds,{time_nbrhood,time_nbrhood});


function test_cross_neighborhood_unsorted_neighbors
    ds=cosmo_synthetic_dataset();
    nh=cosmo_interval_neighborhood(ds,'i','radius',1);

    nh_unsorted=nh;
    nh_unsorted.neighbors=cellfun(@(x)x(randperm(numel(x))),...
                                nh_unsorted.neighbors,...
                                'UniformOutput',false);
    assertEqual(nh,cosmo_cross_neighborhood(ds,{nh_unsorted}));


function test_cross_neighborhood_progress()
    if cosmo_skip_test_if_no_external('!evalc')
        return;
    end

    ds=cosmo_synthetic_dataset();
    nh1=cosmo_interval_neighborhood(ds,'i','radius',0);
    nh2=cosmo_interval_neighborhood(ds,'j','radius',0);
    f=@()cosmo_cross_neighborhood(ds,{nh1,nh2});
    res=evalc('f();');
    assert(~isempty(strfind(res,'[####################]')));
    assert(~isempty(strfind(res,'crossing neighborhoods')));

