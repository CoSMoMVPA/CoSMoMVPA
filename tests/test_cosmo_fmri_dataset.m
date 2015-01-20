function test_suite = test_cosmo_fmri_dataset
    initTestSuite;

function test_init()
    ds=cosmo_synthetic_dataset();

    assertTrue(numel(setxor(fieldnames(ds),...
               {'samples','a','sa','fa'}))==0);


function test_nifti()
    ni=generate_test_nifti_struct();
    g=cosmo_synthetic_dataset('size','normal');

    tmpfn='__tmp1_.nii';
    cleaner=onCleanup(@()delete(tmpfn));
    save_nii(ni,tmpfn);
    ds=cosmo_fmri_dataset(tmpfn,'targets',g.sa.targets,...
                                'chunks',g.sa.chunks);



    assertTrue(numel(setxor(fieldnames(ds),...
               fieldnames(g)))==0);

    assertElementsAlmostEqual(ds.samples, g.samples,'relative',1e-6);
    assertEqual(ds.sa.targets, g.sa.targets)
    assertEqual(ds.sa.chunks, g.sa.chunks)

function test_io()
    ds=cosmo_synthetic_dataset('size','normal');
    tmpfn='__tmp2_.nii';
    cleaner=onCleanup(@()delete(tmpfn));

    cosmo_map2fmri(ds,tmpfn);

    es=cosmo_fmri_dataset(tmpfn);
    assertElementsAlmostEqual(ds.samples,es.samples,'relative',1e-6);
    assertEqual(ds.a.fdim,es.a.fdim);

