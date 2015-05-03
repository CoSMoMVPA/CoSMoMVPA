function test_suite=test_surface_io()
    initTestSuite;

function test_surface_dataset_gifti()
    if cosmo_skip_test_if_no_external('gifti')
        return;
    end
    save_and_load('gii');

function test_surface_dataset_niml_dset()
    if cosmo_skip_test_if_no_external('afni')
        return;
    end
    save_and_load('niml_dset');

function test_surface_dataset_bv_smp()
    if cosmo_skip_test_if_no_external('neuroelf')
        return;
    end
    save_and_load('bv_smp');


function props=format2props(format)
    f2p=struct();
    f2p.gii.ext='.gii';
    f2p.gii.writer=@(fn,x)save(x,fn);
    f2p.gii.reader=@(fn)gifti(fn);
    f2p.gii.cleaner=@do_nothing;

    f2p.bv_smp.ext='.smp';
    f2p.bv_smp.writer=@(fn,x)x.SaveAs(fn);
    f2p.bv_smp.reader=@read_bv_and_bless;
    f2p.bv_smp.cleaner=@(x)x.ClearObject();

    f2p.niml_dset.ext='.niml.dset';
    f2p.niml_dset.writer=@(fn,x)afni_niml_writesimple(x,fn);
    f2p.niml_dset.reader=@(fn)afni_niml_readsimple(fn);
    f2p.niml_dset.cleaner=@do_nothing;

    props=f2p.(format);

function x=read_bv_and_bless(fn)
    x=xff(fn);
    bless(x);

function x=do_nothing(x)
    % do nothing


function save_and_load(format)
    ds=cosmo_synthetic_dataset('type','surface','nchunks',1);
    ds.sa=struct();
    ds.sa.stats={'Ftest(3,4)';'Zscore()'};
    ds.sa.labels={'label1';'label2'};



    props=format2props(format);
    ext=props.ext;
    tmp_fn=cosmo_make_temp_filename('_tmp',ext);

    cleaner=onCleanup(@()delete(tmp_fn));

    cosmo_map2surface(ds,tmp_fn);
    ds2=cosmo_surface_dataset(tmp_fn);

    assert_dataset_equal(ds,ds2,format);

    o=cosmo_map2surface(ds,['-' format]);
    writer=props.writer;
    reader=props.reader;

    writer(tmp_fn,o);
    o2=reader(tmp_fn);
    ds3=cosmo_surface_dataset(o2);

    assert_dataset_equal(ds,ds3,format);

function assert_dataset_equal(x,y,format)
    assertElementsAlmostEqual(x.samples,y.samples,'absolute',1e-4);
    assertEqual(x.fa,y.fa);
    assertEqual(x.a,y.a);

    if ~strcmp(format,'gii')
        assertEqual(x.sa,y.sa);
    end




