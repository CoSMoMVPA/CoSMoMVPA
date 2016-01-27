function test_suite=test_check_external()
    initTestSuite;

function test_check_external_nifti()
    % nifti comes with CoSMoMVPA, so should always be available if the path
    % is set properly

    warning_state=cosmo_warning();
    orig_path=path();
    cleaner=onCleanup(@()do_sequentially({...
                            @()path(orig_path),...
                            @()cosmo_warning(warning_state)}));

    % ensure path is set; disable warnings by cosmo_set_path
    cosmo_warning('off');
    cosmo_set_path();

    assertTrue(cosmo_check_external('nifti'))
    assertEqual(cosmo_check_external({'nifti','nifti'}),[true;true]);

    % test list
    externals=cosmo_check_external('-list');
    assert(~isempty(strmatch('nifti',externals,'exact')));

    % test tic/toc
    cosmo_check_external('-tic');
    assert(isempty(cosmo_check_external('-toc')));

    % must cite CoSMoMVPA, but not NIFTI
    c=cosmo_check_external('-cite');
    assert(~isempty(findstr(c,'N. N. Oosterhof')));
    assert(~isempty(findstr(c,'CoSMoMVPA')));
    assert(isempty(findstr(c,'NIFTI toolbox')));

    % after checking for nifti it must be present
    cosmo_check_external('nifti');
    assertEqual(cosmo_check_external('-toc'),{'nifti'});
    c=cosmo_check_external('-cite');
    assert(~isempty(findstr(c,'NIFTI toolbox')));


function test_check_external_mocov()
    has_mocov=~isempty(which('mocov'));
    disp(has_mocov)
    disp(cosmo_check_external('mocov',false))
    assertEqual(has_mocov,cosmo_check_external('mocov',false));


function do_sequentially(f_cell)
    cellfun(@(x)x(),f_cell);
