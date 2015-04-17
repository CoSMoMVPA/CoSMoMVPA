function varargout=cosmo_notify_test_skipped(reason)
    persistent skipped_tests

    if isempty(skipped_tests)
        skipped_tests=cell(0);
    end

    if nargin<1
        varargout={skipped_tests};
        return;
    else
        varargout={};
    end

    switch reason
        case 'on'
            skipped_tests=cell(0);

        otherwise
            % notify that a unit test was skipped
            %
            db=dbstack('-completenames');

            db_up=db(2);
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
    files={db.file};
    tf=any(~cellfun(@isempty,regexp(files,string)));
