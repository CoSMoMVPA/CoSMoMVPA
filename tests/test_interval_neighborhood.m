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

        for j=1:numel(radii)
            ds=cosmo_slice(ds,randperm(nf),2);
            fa_time=ds.fa.time;

            radius=radii(j);

            nh=cosmo_interval_neighborhood(ds,'time',radius);
            assert(numel(nh.neighbors)==narg);
            assertEqual(nh.fa.time,1:narg);
            assertEqual(nh.a.fdim.values,...
                            {ds_full.a.fdim.values{2}(slicearg)});

            for m=1:narg
                msk=m-radius<=fa_time & ...
                        fa_time <= m+radius;
                assertEqual(find(msk),nh.neighbors{m});
            end
        end
    end

    % test exceptionsclc
    aet=@(x,i)assertExceptionThrown(@()...
                        cosmo_interval_neighborhood(x{:}),i);


    if cosmo_wtf('is_matlab')
        id_missing_arg='MATLAB:minrhs';
        id_missing_fieldname='MATLAB:mustBeFieldName';
    else
        id_missing_arg='Octave:undefined-function';
        id_missing_fieldname='';
    end
    aet({ds},id_missing_arg);
    aet({ds,'time'},id_missing_arg);
    aet({ds,'x',2},id_missing_fieldname);
    aet({ds,'time',-1},'');
    aet({ds,'time',[2 3]},'');
