function test_suite=test_randperm
% tests for cosmo_randperm
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_randperm_no_seed
    helper_test_deterministic(false);

function test_randperm_with_seed
    helper_test_deterministic(true);

function helper_test_deterministic(with_seed)
    if with_seed
        seed=ceil(rand()*1e5);
        args={'seed',seed};
    else
        args={};
    end

    f=@(varargin)cosmo_randperm(varargin{:},args{:});

    % single input
    n=randint();
    x1=f(n);
    assertEqual(size(x1),[1 n]);
    assertEqual(sort(x1),1:n);

    x1a=f(n);
    if with_seed
        assertEqual(x1,x1a);
    else
        assert(~isequal(x1,x1a));
    end

    % two inputs, select all
    x1a=f(n,n);

    if with_seed
        assertEqual(x1,x1a);
    else
        assert(~isequal(x1,x1a));
    end

    % two inputs, k<n
    k=randint();
    n=k+randint();
    assert(k<n);
    x2=f(n,k);
    assertEqual(size(x2),[1 k]);
    msk=bsxfun(@eq,(1:n)',x2);
    assertEqual(sum(msk(:)==1),k);
    assertEqual(sum(sum(msk==1,1),2),k); % each column has one 1
    assertEqual(sum(sum(msk==1,2),1),k); % each row has one 1


    if with_seed
        % deterministic
        x2a=f(n,k);
        assertEqual(x2,x2a);
    else
        found=false;
        for attempt=1:10
            x2a=f(n,k);
            if ~isequal(x2,x2a)
                found=true;
                break;
            end
        end

        if ~found
            error('Different calls do not lead to different outputs');
        end
    end

    x3=f(0);
    assertTrue(isempty(x3));

    x4=f(1);
    assertEqual(x4,1);

    x5=f(1,1);
    assertEqual(x5,1);

function test_randperm_different_seeds
    count=10;
    seed=0;
    result=cell(count,1);
    for k=1:count
        seed=seed+randint();

        result{k}=cosmo_randperm(1000,'seed',seed);
        for j=1:(k-1)
            assertFalse(isequal(result{j},result{k}));
        end
    end




function test_randperm_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_randperm(varargin{:}),'');
    illegal_args={-1,.5,[1 2],'foo',struct,cell(0)};
    narg=numel(illegal_args);

    % illegal first and/or second arguments
    for k=1:narg
        for second_arg=[false,true]
            for j=1:narg
                if second_arg
                    args=illegal_args([k j]);
                elseif j>1
                    continue;
                else
                    % single arg if j==1
                    args=illegal_args(k);
                end
                aet(args{:});
            end
        end
    end

    % illegal seed arguments
    for k=1:narg
        arg=illegal_args(k);
        aet(4,2,'seed',arg{:});
    end

    % missing seed
    aet(4,2,'seed');

    % double seed
    aet(4,2,'seed',1,'seed',1);

    % 3 numeric arguments
    aet(4,2,1);

    % second argument greater than first
    aet(2,4);
    aet(2,4,'seed',1);

    % unknown keyword
    aet(2,'foo',1);
    aet(2,'foo');

function x=randint(n)
    x=ceil(10+rand()*50);




