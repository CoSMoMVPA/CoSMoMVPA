function test_suite=test_cross_neighborhood()
    initTestSuite;


function test_cross_neighborhood_basis()
    can_use_chan_nbrhood=cosmo_check_external('fieldtrip',false);

    ds_full=cosmo_synthetic_dataset('type','timefreq','size','big');

    % make it sparse
    nfeatures=size(ds_full.samples,2);
    nkeep=round(nfeatures/4);
    while true
        rp=randperm(nfeatures);
        ds=cosmo_dim_slice(ds_full,rp(1:nkeep),2);
        n=numel(ds.a.fdim.values{1});
        ds.a.fdim.values{1}=ds.a.fdim.values{1}(randperm(n));

        if numel(unique(ds.fa.chan))==306 && ...
                    numel(unique(ds.fa.freq))==7 && ...
                    numel(unique(ds.fa.time))==5
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

    if ~can_use_chan_nbrhood
        cosmo_notify_test_skipped('channel neighborhood not available');
        return;
    end


function test_cross_neighborhood_exceptions()
    ds=cosmo_synthetic_dataset('type','meeg','size','big');
    time_nbrhood=cosmo_interval_neighborhood(ds,'time','radius',1);

    % test exceptions
    aet=@(x)assertExceptionThrown(@()cosmo_cross_neighborhood(ds,x{:}),'');

    aet({{}});
    aet({struct});
    aet({struct,time_nbrhood});
    aet({time_nbrhood,time_nbrhood});
    aet({ds});

    assertEqual(cosmo_cross_neighborhood(ds,{time_nbrhood}),time_nbrhood);
    time_nbrhood.neighbors{1}=1e9;
    aet({time_nbrhood});
    time_nbrhood.neighbors{1}=1.5;
    aet({time_nbrhood});

    time_nbrhood=cosmo_interval_neighborhood(ds,'time','radius',1);
    time_nbrhood.a.fdim.labels{1}='foo';
    time_nbrhood.fa.foo=time_nbrhood.fa.time;
    aet({time_nbrhood});

