function test_suite=test_cosmo_notify_test_skipped
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

function test_cosmo_notify_test_skipped_basics()
    notify_state=cosmo_notify_test_skipped();
    warning_state=warning();

    notify_resetter=onCleanup(@()cosmo_notify_test_skipped(notify_state));
    warning_resetter=onCleanup(@()warning(warning_state));

    % empty notified tests
    cosmo_notify_test_skipped('on');
    s=cosmo_notify_test_skipped();
    assert(isempty(s));

    % switch of warnings
    warning('off');

    db=dbstack();

    if is_moxunit(db);
        try
            moxunit_throw_test_skipped_exception('foo');
        catch
            e=lasterror();
        end
        identifier=e.identifier;
        caller=@(varargin)assertExceptionThrown(@()...
                        cosmo_notify_test_skipped(varargin{:}),identifier);
    else
        caller=@(varargin)cosmo_notify_test_skipped(varargin{:});
    end

    % one notificiation
    reason1=['a' randstr()];
    caller(reason1);
    s=cosmo_notify_test_skipped();
    assert_has_substrings(s,{reason1});

    reason2=['b' randstr()];
    caller(reason2);
    s=cosmo_notify_test_skipped();
    assert_has_substrings(s,{reason1,reason2});


function assert_has_substrings(haystack,needle)
    n=numel(haystack);
    assertEqual(n,numel(needle));
    for k=1:n
        assert(~isempty(findstr(haystack{k},needle{k})));
    end


function tf=is_moxunit(db)
    tf=false;

    nm='initTestSuite';
    main='moxunit_runtests';

    if isempty(strmatch(nm,{db.name},'exact'))
        return;
    end

    rootdir=fileparts(which(nm));
    pth=fullfile(rootdir,[main '.m']);

    tf=isequal(which(main),pth);
