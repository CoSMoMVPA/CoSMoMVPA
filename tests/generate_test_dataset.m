function ds=generate_test_dataset()

ni=generate_test_nifti_struct();
ds=cosmo_fmri_dataset(ni,'chunks',floor(((1:20)-1)/4)+1,...
                         'targets',repmat([1:5]',4,1));
