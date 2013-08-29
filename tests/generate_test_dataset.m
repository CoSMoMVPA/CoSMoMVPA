function ds=generate_test_dataset()

ni=generate_test_nifti_struct();
ds=cosmo_fmri_dataset(ni);
