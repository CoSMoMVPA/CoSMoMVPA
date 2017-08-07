function test_suite=test_warning
% tests for cosmo_warning
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_warning_basics
    state=cosmo_warning();
    state_resetter=onCleanup(@()cosmo_warning(state));

    cosmo_warning('reset');
    cosmo_warning('off');

    % test simple message
    msg='foo';
    cosmo_warning(msg);
    assert_in_shown_warnings(msg);

    % test formatting a message
    args={'bar%d-%d_%d',randn(1,3)};
    cosmo_warning(args{:});
    assert_in_shown_warnings(args);

    % test with identifier
    args={'msg:id','foo%s-%d','baz',3};
    cosmo_warning(args{:});
    assert_in_shown_warnings(args(2:end));

    % test with identifier '%' (ascii code 65)
    args={'bar%d',65};
    cosmo_warning(args{:});
    assert_in_shown_warnings(args);


function assert_in_shown_warnings(msg)
    state=cosmo_warning();
    shown_warnings=state.shown_warnings;
    assert(~isempty(shown_warnings));

    if iscell(msg)
        msg=sprintf(msg{:});
    end
    assert(any(cosmo_match(shown_warnings,msg)));
