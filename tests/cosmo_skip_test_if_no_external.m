function skip_test=cosmo_skip_test_if_no_external(external)
% Notify that test in the test suite is skipped if no external is present
%
% skip_test=cosmo_skip_test_if_no_external(external)
%
% Inputs:
%   external                Name of external to be checked; see
%                           cosmo_check_external
%
% Output:
%   skip_test               True if the external is not available, false
%                           otherwise. If the external is not available,
%                           then the skip of the test is notified through
%                           cosmo_notify_test_skipped, which (depending on
%                           the call stack) may raise an exception and/or
%                           display a warning.
%
% Notes:
%   - This function can be used for three different test suite
%     use case scenarios:
%     * runtests  (from the xUnit framework):
%         calling this function shows a warning message and does not raise
%         an exception.
%     * cosmo_run_tests (using the xUnit framework):
%         calling this function does not show a warning message, nor does
%         it raise an exception. Instead, cosmo_notify_test_skipped is
%         called, so that after all tests are run, cosmo_run_tests shows a
%         summary of skipped tests.
%     * moxunit_runtests (using MOxUnit):
%         calling this function does not show a warning message, but it
%         does raise an exception. This exception is caught by MOxUnit,
%         so that after all tests are run, moxunit_runtests shows a summary
%         of skipped tests.
%   - Because xUnit does not support skipping tests directly, recommended
%     usage within a unit test is:
%
%       if cosmo_skip_test_if_no_external('fieldtrip')
%           return
%       end
%
% See also: cosmo_check_external, cosmo_notify_test_skipped
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    skip_test=~cosmo_check_external(external,false);

    if skip_test
        if external(1)=='!'
            reason=sprintf('Function %s is absent',external(2:end));
        else
            reason=sprintf('External ''%s'' is absent',external);
        end
        cosmo_notify_test_skipped(reason);
    end
