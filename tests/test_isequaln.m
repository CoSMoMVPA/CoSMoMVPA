function test_suite=test_isequaln
% tests for cosmo_isequaln
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function is_eq_diff_cell=get_eq_diff_cells()
    x=randn();
    y=x+1;

    s=struct();
    s.a=x;
    s.b='foo';
    s.c=[NaN NaN];

    is_eq={ ...
            x,x;...
            {x},{x};...
            {x,x},{x,x};...
            NaN,NaN;...
            [NaN,NaN,2],[NaN,NaN,2];...
            };

    is_diff={...
            x,y;...
            {x},{y};...
            {x,x},{x,y};...
            {x,x},{x;x};...
            x,NaN;...
            NaN,x;...
            [NaN,2,NaN],[NaN,NaN,2];...
            [NaN,2,NaN],[NaN;2;NaN];...
            s,x;...
            };

    is_eq_diff_cell={is_eq,is_diff};


function test_isequaln_regression()
    is_eq_diff_cell=get_eq_diff_cells();
    for col=1:2
        is_eq=col==1;

        value_cell=is_eq_diff_cell{col};
        for row=1:size(value_cell,1);
            args=value_cell(row,:);
            assertEqual(is_eq,cosmo_isequaln(args{:}));
        end
    end

function test_isequaln_compare_builtin_isequaln
    helper_test_comparison('isequaln');

function test_isequaln_compare_builtin_isequalwithequalnans
    helper_test_comparison('isequalwithequalnans');

function helper_test_comparison(func_name)
    ext_name=sprintf('!%s',func_name);

    if cosmo_skip_test_if_no_external(ext_name)
        return
    end

    if cosmo_wtf('is_octave')
        warning_state=warning();
        warning_resetter=onCleanup(@()warning(warning_state));
        warning('off','Octave:deprecated-keyword');
        warning('off','Octave:deprecated-function');
    end

    is_eq_diff_cell=get_eq_diff_cells();
    all_eq_diff=cat(1,is_eq_diff_cell{:});

    func=str2func(func_name);

    for row=1:size(all_eq_diff,1);
        args=all_eq_diff(row,:);
        assertEqual(cosmo_isequaln(args{:}),func(args{:}));
    end
