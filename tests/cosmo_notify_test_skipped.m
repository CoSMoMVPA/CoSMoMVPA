function cosmo_notify_test_skipped(reason)
    % notify that a unit test was skipped
    %
    db=dbstack('-completenames');

    db_up=db(2);
    desc=sprintf('%s: %s', db_up.name, reason);

    if test_was_run_by_MOxUnit(db)
        moxunit_throw_test_skipped_exception(desc);
    else
        warning('CoSMoMVPA:skipTest','Skipping test in %s (%s:%d)',...
                desc, db_up.file, db_up.line);
    end

function tf=test_was_run_by_MOxUnit(db)
    files={db.file};
    tf=any(~cellfun(@isempty,regexp(files,'@MOxUnit')));

