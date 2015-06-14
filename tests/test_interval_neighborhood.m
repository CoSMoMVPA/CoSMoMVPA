function test_suite = test_interval_neighborhood()
    initTestSuite;


function test_interval_neighborhood_basis()
    ds_full=cosmo_synthetic_dataset('type','meeg','size','big');
    ds_full=cosmo_dim_slice(ds_full,ds_full.fa.chan<3,2);

    sliceargs={1:7,[1 4 7],[2 6]};
    radii=[0 1 2];
    for k=1:numel(sliceargs)
        slicearg=sliceargs{k};
        narg=numel(slicearg);

        ds=cosmo_dim_slice(ds_full,cosmo_match(ds_full.fa.time,slicearg),2);
        nf=size(ds.samples,2);
        ds=cosmo_slice(ds,randperm(nf),2);

        for j=1:numel(radii)
            ds=cosmo_slice(ds,randperm(nf),2);
            fa_time=ds.fa.time;

            radius=radii(j);

            nh=cosmo_interval_neighborhood(ds,'time','radius',radius);
            assert(numel(nh.neighbors)==narg);
            assertEqual(nh.fa.time,1:narg);
            assertEqual(nh.a.fdim.values,...
                            {ds_full.a.fdim.values{2}(slicearg)});

            assertEqual(nh.origin.a.fdim,ds.a.fdim);
            assertEqual(nh.origin.fa,ds.fa);

            for m=1:narg
                msk=m-radius<=fa_time & ...
                        fa_time <= m+radius;
                assertEqual(find(msk),nh.neighbors{m});
            end

            % should properly deal with permutations
            ds2=cosmo_slice(ds,randperm(nf),2);
            ds2.a.fdim.values=cellfun(@transpose,ds2.a.fdim.values,...
                                        'UniformOutput',false)';
            nh2=cosmo_interval_neighborhood(ds2,'time','radius',radius);
            assertEqual(nh.fa,nh2.fa);
            assertEqual(nh.a,nh2.a);
            mp=cosmo_align(ds.fa,ds2.fa);
            for m=1:numel(nh.neighbors)
                assertEqual(sort(mp(nh2.neighbors{m})),nh.neighbors{m});
            end
        end
    end

    % test exceptionsclc
    aet=@(x,i)assertExceptionThrown(@()...
                        cosmo_interval_neighborhood(x{:}),i);


    aet({ds},'');
    aet({ds,'time'},'');
    aet({ds,'x',2},'');
    aet({ds,'time',-1},'');
    aet({ds,'time',[2 3]},'');
    aet({ds,'time','radius'},'');
    aet({ds,'time','radius',-1},'');

function test_interval_neighborhood_sa()
    ds=cosmo_synthetic_dataset('type','meeg');
    ds_tr=cosmo_dim_transpose(ds,'time');
    ds_tr=cosmo_slice(ds_tr,randperm(12));
    for radius=0:1
        nbrhood=cosmo_interval_neighborhood(ds_tr,'time','radius',radius);
        unq_time=unique(ds_tr.sa.time);
        for k=1:numel(unq_time)
            msk=abs(ds_tr.sa.time-unq_time(k))<=radius;
            assertEqual(nbrhood.neighbors{k},find(msk)');
        end
    end


function test_interval_neighborhood_fa()
    ds=cosmo_synthetic_dataset('type','meeg','size','big');
    nf=size(ds.samples,2);
    rp=randperm(nf);
    dsp=cosmo_slice(ds,rp,2);

    for radius=0:10
        nhp=cosmo_interval_neighborhood(dsp,'time','radius',radius);
        assertEqual(nhp.a.fdim.values{1},ds.a.fdim.values{2});

        for k=1:numel(nhp.neighbors)
            idx=find(abs(nhp.fa.time(k)-dsp.fa.time)<=radius);
            assertEqual(nhp.neighbors{k},idx);
        end
    end
