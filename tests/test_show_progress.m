function test_suite=test_show_progress
% tests for cosmo_show_progress
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_show_progress_basics
    if ~has_evalc()
        cosmo_notify_test_skipped('''evalc'' is not available');
        return;
    end

    clock_start=clock();

    assert_progress_equal(['\+00:00:00 \[------------'...
                            '--------\] -oo  '],...
                          [],...
                          clock_start,0);
    assert_progress_equal(['\+00:00:00 \[-----------'...
                            '---------\] -oo  foo'],...
                          [],...
                          clock_start,0,'foo','');
    pause(.5);
    assert_progress_equal(['\+00:00:01 \[##########'...
                            '----------\] -00:00:01  foo'],...
                          [],...
                          clock_start,.5,'foo','');
    assert_progress_equal(['\+00:00:01 \[----------'...
                            '----------\] -2d.*  foo'],...
                          [],...
                          clock_start,1/(60*60*24)/5,'foo','');
    assert_progress_equal(sprintf(['\\+00:00:01 \\[###########'...
                            '#########\\] -00:00:00  foo\n']),...
                          [],...
                          clock_start,1,'foo','');
    assert_progress_equal(sprintf(['bar\\+00:00:01 \\[###########'...
                            '#########\\] -00:00:00  foo\n']),...
                          'barbaz',...
                          clock_start,1,'foo','baz');
    assertExceptionThrown(@()cosmo_show_progress(clock_start,-1),'');
    assertExceptionThrown(@()cosmo_show_progress(clock_start,2),'');




function assert_progress_equal(re,infix,varargin)
%     if isempty(infix)
%         cmd='';
%     else
%         cmd='fprintf(''%s'',infix);';
%     end
%     result=evalc([cmd 'cosmo_show_progress(varargin{:});']);
    expr='helper_print_infix_and_show_progress(infix,varargin{:})';
    result=evalc(expr);

    while true
        % replace a backspace character and the preceeding character by
        % nothing
        idx=find(result==sprintf('\b'),1);
        if isempty(idx)
            break;
        end
        result=result([1:(idx-2),(idx+1):end]);
    end

    assert(~isempty(regexp(result,re,'once')))

function helper_print_infix_and_show_progress(infix,varargin)
    if ~isempty(infix)
        fprintf('%s',infix);
    end
    cosmo_show_progress(varargin{:});


function tf=has_evalc()
    tf=exist('evalc','builtin') || ~isempty(which('evalc'));