function varargout=cosmo_notify_test_skipped(reason)
% notify that a test in the test suite is skipped
%
% Usages:
%   - cosmo_notify_test_skipped(reason)
%
%       Input:
%           reason          string indicating why a test is skipped, and
%                           store reason internally in this function.
%
%   - skipped_tests=cosmo_notify_test_skipped()
%
%       Output:
%           skipped_tests   cell with strings containing the reason values
%                           stored internally
%
%   - cosmo_notify_test_skipped()
%
%       Side effect: this empties the internal list of skipped tests
%
% Notes:
%   - depending on the call stack, this function:
%       * when called through MOxUnit's moxunit_run_tests, it raises an
%         exception through  moxunit_throw_test_skipped_exception. When
%         moxunit_run_tests is finished testing, it can summarize which
%         tests were skipped.
%       * when called through cosmo_run_tests, no warning is shown and no
%         error is thrown. When cosmo_run_tests is finished testing, it can
%         summarize which tests were skipped.
%       * otherwise, a warning message is shown with the reason.
%
% See also: moxunit_throw_test_skipped_exception, cosmo_run_tests
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    persistent skipped_tests

    if isempty(skipped_tests)
        skipped_tests=cell(0);
    end

    if nargin<1
        varargout={skipped_tests};
        return;
    end

    varargout=cell(0);

    switch reason
        case 'on'
            skipped_tests=cell(0);

        otherwise
            % notify that a unit test was skipped
            %
            db=dbstack('-completenames');

            db_idx=last_non_testing_suite_stack_index(db);

            db_up=db(db_idx);
            desc=sprintf('%s: %s (%s:%d)', db_up.name, reason, ...
                                    db_up.file, db_up.line);

            if test_was_run_by_MOxUnit(db)
                moxunit_throw_test_skipped_exception(desc);
            elseif test_was_run_by_cosmo_run_tests(db)
                % do nothing
            else
                warning('%s',desc)
            end

            skipped_tests{end+1}=desc;
    end

function tf=test_was_run_by_MOxUnit(db)
    tf=dbstack_contains_string(db,'@MOxUnit');

function tf=test_was_run_by_cosmo_run_tests(db)
    tf=dbstack_contains_string(db,'cosmo_run_tests.m');

function tf=dbstack_contains_string(db, string)
    tf=~isempty(first_stack_index_with_string(db, string));

function idx=first_stack_index_with_string(db, string)
    files={db.file};
    has_string=~cellfun(@isempty,regexp(files,string));
    idx=find(has_string,1,'first');


function idx=last_non_testing_suite_stack_index(db)
    if test_was_run_by_MOxUnit(db)
        suite_dir=fileparts(which('moxunit_runtests'));
        idx=first_stack_index_with_string(db, suite_dir)-1;

    elseif test_was_run_by_cosmo_run_tests(db)
        suite_dir=fileparts(which('runtests'));
        idx=first_stack_index_with_string(db, suite_dir)-1;

    else
        idx=[];
    end
