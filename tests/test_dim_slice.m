 function test_suite = test_dim_slice
% tests for cosmo_dim_slice
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_dim_slice_no_prune()
    ds=cosmo_synthetic_dataset();
    helper_test_dim_slice_(ds,[1 6 2],2);
    helper_test_dim_slice_(ds,[1 6 2],1);

function test_dim_slice_prune()
    ds=cosmo_synthetic_dataset();
    helper_test_dim_slice_(ds,ds.fa.i~=2,2);
    helper_test_dim_slice_(ds,ds.fa.i==3,2);


function helper_test_dim_slice_(varargin)
    ds_sliced=cosmo_slice(varargin{:});
    expected_result=cosmo_dim_prune(ds_sliced);

    result=cosmo_helper_dim_slice_without_warning(varargin{:});
    assertEqual(result,expected_result);


function result=cosmo_helper_dim_slice_without_warning(varargin)
    warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(warning_state));
    empty_state=warning_state;
    empty_state.show_warnings=[];
    cosmo_warning(empty_state);
    cosmo_warning('off');

    result=cosmo_dim_slice(varargin{:});

    % deprecation warning must have been shown
    w=cosmo_warning();
    assert(~isempty(w.shown_warnings));
    assert(iscellstr(w.shown_warnings));


