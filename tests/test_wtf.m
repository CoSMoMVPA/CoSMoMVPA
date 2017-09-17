function test_suite=test_wtf
% tests for cosmo_wtf
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
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

    external_cell=cosmo_wtf('cosmo_externals');
    external_expected_cell=cosmo_check_external('-list');
    assertEqual(sort(external_cell(:)), sort(external_expected_cell(:)));

    assertExceptionThrown(@()cosmo_wtf('illegal'),'');

function test_wtf_warnings()
    rand_str_func=@()char(ceil(rand(20,1)*26+64));
    warning_id=sprintf('%s:%s',rand_str_func(),rand_str_func());

    warning_state=warning();
    warning_state_resetter=onCleanup(@()warning(warning_state));

    on_off_labels={'on','off'};
    for k=1:numel(on_off_labels);
        label=on_off_labels{k};
        anti_label=on_off_labels{3-k};

        warning(anti_label,'all');
        warning(label,warning_id);

        w_cell=cosmo_wtf('warnings');
        w=cosmo_strjoin(w_cell,', ');
        assert_contains(w,sprintf('%s: %s',warning_id,label));
        assert_not_contains(w,sprintf('%s: %s',warning_id,anti_label));
    end

function test_wtf_version_number()
    vn=cosmo_wtf('version_number');
    assert(isnumeric(vn));

    vs=sprintf('%d.',vn);
    vs=vs(1:(end-1));

    vs_expected=regexp(version(),'^\S*','match');
    assert(numel(vs_expected{1})>=3);
    assertEqual(vs,vs_expected{1});

function test_wtf_is_matlab
    is_octave=environment_is_octave;
    assertEqual(cosmo_wtf('is_matlab'),~is_octave);
    assertEqual(cosmo_wtf('is_octave'),is_octave);

function test_wtf_cosmo_externals()
    s=cosmo_wtf('cosmo_externals');
    assert(iscellstr(s));

function test_wtf_path()
    s=cosmo_wtf('path');
    assert(iscellstr(s));
    p=path();
    assertEqual(cosmo_strjoin(s,pathsep()),p);


function assert_contains(haystack, needle)
    assert_contains_helper(haystack, needle, true);

function assert_not_contains(haystack, needle)
    assert_contains_helper(haystack, needle, false);

function assert_contains_helper(haystack, needle, expected_tf)
    re=regexptranslate('escape',needle);
    assertEqual(~isempty(regexp(haystack,re,'once')),expected_tf);

function tf=environment_is_octave()
    tf=logical(exist('OCTAVE_VERSION', 'builtin'));

