function test_suite=test_check_external()
    initTestSuite;

function test_check_external_nifti()
    % nifti comes with CoSMoMVPA, so should always be available if the path
    % is set properly

    % ensure path is set
    orig_path=path();
    cleaner=onCleanup(@()path(orig_path));
    cosmo_set_path();

    assertTrue(cosmo_check_external('nifti'))
    assertEqual(cosmo_check_external({'nifti','nifti'}),[true;true]);

    externals=cosmo_check_external('-list');
    assert(~isempty(strmatch({'nifti'},externals)));




