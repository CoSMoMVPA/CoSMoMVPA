function skip_test=cosmo_skip_test_if_no_external(external)
% Notify that test is skipped if no external is present
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
%   - Because xUnit does not support skipping tests directly, recommended
%     usage within a unit test is:
%
%       if cosmo_skip_test_if_no_external('fieldtrip')
%           return
%       end
%
% See also: cosmo_check_external, cosmo_notify_test_skipped
%
% NNO Apr 2015

    skip_test=~cosmo_check_external(external,false);

    if skip_test
        reason=sprintf('External ''%s'' is absent',external);
        cosmo_notify_test_skipped(reason);
    end
