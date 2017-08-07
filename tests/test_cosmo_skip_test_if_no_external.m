function test_suite=test_cosmo_skip_test_if_no_external
% tests for cosmo_align
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function s=randstr()
    s=char(ceil(rand(1,10)*26+64));

function test_cosmo_skip_test_if_no_external_basics
    notify_state=cosmo_notify_test_skipped();
    warning_state=warning();

    notify_resetter=onCleanup(@()cosmo_notify_test_skipped(notify_state));
    warning_resetter=onCleanup(@()warning(warning_state));

    % empty notified tests
    cosmo_notify_test_skipped('on');
    s=cosmo_notify_test_skipped();
    assert(isempty(s));

    % test for external that should not lead to skip
    cosmo_skip_test_if_no_external('cosmo');
    s=cosmo_notify_test_skipped();
    assert(isempty(s));

    % another test that should lead to skip
    nonexistent_func_name=['unused_foo_' randstr()];
    func_label=['!' nonexistent_func_name];
    try
        cosmo_skip_test_if_no_external(func_label);
    catch
    end
    s=cosmo_notify_test_skipped();
    assert(~isempty(s));



