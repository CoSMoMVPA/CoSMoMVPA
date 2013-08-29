function test_suite = test_cosmo_fmri_dataset
initTestSuite;

function test_init()
ds=generate_test_dataset();

assertTrue(numel(setxor(fieldnames(ds),...
           {'samples','a','sa','fa'}))==0);
       

function test_nifti()
ni=generate_test_nifti_struct();
tmpfn='__tmp_.nii';
save_nii(ni,tmpfn);
ds=cosmo_fmri_dataset(tmpfn);
delete(tmpfn)

g=generate_test_dataset();
assertTrue(numel(setxor(fieldnames(ds),...
           fieldnames(g)))==0);

assertElementsAlmostEqual(ds.samples, g.samples);