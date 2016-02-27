function test_suite=test_wtf
% tests for cosmo_wtf
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_wtf_basics()
    warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    h=cosmo_wtf();

    [c,m,e]=computer();
    computer_str=sprintf('%s (maxsize=%d, endian=%s)',c,m,e);
    assert_contains(h,computer_str);
    assertEqual(cosmo_wtf('computer'),computer_str);


    if environment_is_octave()
        env_string='octave';
    else
        env_string='matlab';
    end

    assert_contains(h,['environment: ' env_string]);
    assertEqual(cosmo_wtf('environment'),env_string);

    external_cell=cosmo_strsplit(h,'cosmo_externals: ',2,'\n',1, ', ');
    external_expected_cell=cosmo_check_external('-list');
    assertEqual(sort(external_cell(:)), sort(external_expected_cell(:)));

    assertExceptionThrown(@()cosmo_wtf('illegal'),'');

function assert_contains(haystack, needle)
    re=regexptranslate('escape',needle);
    assertFalse(isempty(regexp(haystack,re,'once')));

function tf=environment_is_octave()
    tf=logical(exist('OCTAVE_VERSION', 'builtin'));

function test_wtf_is_matlab
    is_octave=environment_is_octave;
    assertEqual(cosmo_wtf('is_matlab'),~is_octave);
    assertEqual(cosmo_wtf('is_octave'),is_octave);
