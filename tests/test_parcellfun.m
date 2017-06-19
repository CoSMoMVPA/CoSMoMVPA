function test_suite = test_parcellfun
% tests for cosmo_cartprod
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_parcellfun_single_proc()
    nproc=1;
    helper_test_parcellfun(nproc);

function test_cosmo_parallel_get_nproc_available()
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('reset');
    cosmo_warning('off');

    nproc=cosmo_parallel_get_nproc_available();
    assert(nproc>=1);

    % should not have shown any warnings
    w=cosmo_warning();
    assert(isempty(w.shown_warnings),sprintf('warning shown: %s',...
                                      w.shown_warnings{:}));





function test_parcellfun_multi_proc()
    nproc=cosmo_parallel_get_nproc_available();
    if nproc==1
        cosmo_notify_test_skipped('No parallel process available');
        return
    end

    helper_test_parcellfun(nproc);



function helper_test_parcellfun(nproc)
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    % try various functions
    funcs={@func_identity,...
            @func_reverse,...
            @numel,...
            @(x)numel(x)>0,...
            };

    % try with both uniform output and without
    arg_cell={{},...
                {'UniformOutput',false}};

    % various number of dimensions
    ndim={0,1,2,3,4}; % 0=empty

    combis=cosmo_cartprod({funcs,arg_cell,ndim});
    n=size(combis,1);

    for c_i=1:n
        combi=combis(c_i,:);
        func_arg=combi{1};
        other_arg=combi{2};
        rand_str_ndim=combi{3};

        rand_cellstr=generate_rand_cellstr(rand_str_ndim);
        func=@()cosmo_parcellfun(nproc,func_arg,rand_cellstr,...
                                other_arg{:});

        ref_func=@() cellfun(func_arg,rand_cellstr,other_arg{:});
        assert_equal_result_or_both_exception_thrown(func,ref_func);
    end


function assert_equal_result_or_both_exception_thrown(f, g)
    try
        f_result=f();
        f_exception=false;
    catch
        f_exception=lasterror();
    end

    try
        g_result=g();
        g_exception=false;
    catch
        g_exception=lasterror();
    end

    f_threw_exception=isstruct(f_exception);
    g_threw_exception=isstruct(g_exception);

    if f_threw_exception
        if ~g_threw_exception
            f_exception.message=sprintf('only f threw exception: %s',...
                                        f_exception.message);
            rethrow(f_exception);
        end
    else
        if g_threw_exception
            g_exception.message=sprintf('only g threw exception: %s',...
                                        g_exception.message);
            rethrow(g_exception);
        end

        assertEqual(f_result,g_result);
    end


function test_illegal_arguments
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_parcellfun(varargin{:}),'');

    % first argument is not scalar integer
    aet(0,@numel,{1,2});
    aet(1.5,@numel,{1,2});
    aet([2 3],@numel,{1,2});

    % second argument is not a function handle
    aet(2,'a',{1,2});
    aet(2,cell(0),{1,2});

    % third argument is not a cell
    aet(2,@numel,[1,2]);
    aet(2,@numel,struct);

    % no uniform output
    % (note: Octave accepts output when using
    %           @(x)[x x]
    %  This may be a bug)
    aet(1,@(x) repmat(x,1,x),{1;2});
    aet(2,@(x) repmat(x,1,x),{1;2});



function rand_cellstr=generate_rand_cellstr(ndim)
    switch ndim
        case 0
            sz=[0,0];

        case 1
            sz=[0,10];

        case 2
            sz=[1,1];

        otherwise
            sz=floor(rand(1,1+ndim)*4);
    end

    randstr=@(unused)char(rand(1,floor(rand()*10))*24+65);
    rand_cellstr=arrayfun(randstr,zeros(sz),'UniformOutput',false);


function y=func_identity(x)
    y=x;

function y=func_reverse(x)
    y=x;
    y(end:-1:1)=x(:);
