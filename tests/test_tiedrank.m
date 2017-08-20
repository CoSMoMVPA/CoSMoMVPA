function test_suite=test_tiedrank
% tests for cosmo_tiedrank
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_tiedrank(varargin{:}),'');
    % illegal first argument
    aet('foo');
    aet({1,2});
    aet(false);

    % illegal second argument
    aet([1 2],'foo');
    aet([1 2],.5);
    aet([1 2],-1);

function test_tiedrank_simple_input()
    args_results={{rand()},1;...
                   {[3 2 1]},[1 1 1];...
                   {[3 2 1],1},[1 1 1];...
                   {[3 2 1],2},[3 2 1];...
                   {[5 NaN 3],2},[2 NaN 1];...
                  };
    n=size(args_results,1);
    for k=1:n
        row=args_results(k,:);
        args=row{1};
        result=row{2};
        assertElementsAlmostEqual(cosmo_tiedrank(args{:}),result);
    end

function test_tiedrank_vector_input()
    wrapper_func=@(x)cosmo_tiedrank(x,1);
    helper_test_tiedrank_vector_with(wrapper_func);


function test_tiedrank_ndim_input()
    for ndim=2:5
        data_size=zeros(1,ndim);

        for dim=1:ndim
            data_size(dim)=randint(3)+1;
        end

        for dim=1:ndim
            func=@(x)cosmo_tiedrank(x,dim);

            helper_test_tiedrank_ndim_with_size(func, data_size, dim);
        end
    end

function test_tiedrank_singleton_input()
    sizes={[1 2 3], [1 1 3], [3 1 1], [1 3 3], [1 1 3 3], ...
                    [1,1+randint(10)], [1+randint(10),1]};
    for k=1:numel(sizes)
        data_size=sizes{k};
        ndim=numel(data_size);

        for dim=1:ndim
            func=@(x)cosmo_tiedrank(x,dim);
            helper_test_tiedrank_ndim_with_size(func, data_size, dim);
        end
    end



function test_builtin_matlab()
    % sanity check that tests whether our test
    if cosmo_skip_test_if_no_external('!tiedrank')
        return;
    end

    if ~cosmo_wtf('is_matlab')
        cosmo_notify_test_skipped('not running Matlab');
        return;
    end

    helper_test_tiedrank_vector_with(@tiedrank);

function r=randint(n)
    r=ceil(rand()*n);


function helper_test_tiedrank_vector_with(func)
    dim=1;
    nsamples=randint(100)+100;
    data_size=[1,1];
    data_size(dim)=nsamples;
    helper_test_tiedrank_ndim_with_size(func, data_size, dim)

function helper_test_tiedrank_ndim_with_size(func, data_size, dim)
    data=generate_random_tied_data(data_size);
    expected_result=func(data);

    assert_result_matches(data,dim,expected_result);



function data=generate_random_tied_data(data_size)
    nan_ratio=.1;
    tied_ratio_min=.5;
    tied_ratio_max=.6;

    data=rand(data_size);
    n=numel(data);

    tied_ratio=tied_ratio_min+rand()*(tied_ratio_max-tied_ratio_min);
    tied_c=0;


    while tied_c*n<tied_ratio
        p=randint(n);
        q=randint(n);
        data(p)=data(q);
        tied_c=tied_c+1;
    end

    nan_msk=rand(data_size)<nan_ratio;
    nan_msk(randint(n))=true; % at least one NaN
    data(nan_msk)=NaN;



function result=builtin_matlab_tiedrank_wrapper(data)
    if cosmo_skip_test_if_no_external('!tiedrank') || ...
                ~cosmo_wtf('is_matlab')
        return;
    end

    result=tiedrank(data);


function assert_result_matches(data, dim, result)
    % data and result are both N-dimensional arrays and must be of the same
    % size. result should be equal to the tiedrank output from data
    assertEqual(size(data),size(result));

    nan_msk=isnan(data);
    assertEqual(isnan(result),nan_msk);

    if dim>numel(size(data))
        % all non-NaN values must be 1
        assertTrue(all(result(~nan_msk)==1))
        return;
    end


    % make the dimension along which tiedrank is applied the first
    % dimension in the *_sh variables
    shift_count=dim-1;
    data_sh=shiftdim(data,shift_count);
    result_sh=shiftdim(result,shift_count);

    % reshape in matrix form so that first dimension is the output for
    % each feature and the second dimension represents all other features
    nsamples=size(data_sh,1);
    nfeatures=numel(data)/nsamples;
    data_mat=reshape(data_sh,nsamples,nfeatures);
    result_mat=reshape(result_sh,nsamples,nfeatures);

    for k=1:nfeatures
        % test k-th feature
        d=data_mat(:,k);
        r=result_mat(:,k);

        % only consider non-nan values
        dkeep=d(~isnan(d));
        rkeep=r(~isnan(r));

        % sort the values
        [s,idx]=sort(dkeep,1);
        nkeep=numel(idx);

        % allocate space for expected output for k-th feature
        expected_rkeep=zeros(nkeep,1);
        m=0;
        while m<nkeep
            m=m+1;

            % index of first value in a possible row of equal values
            first=m;
            c=0;

            while m<nkeep && s(m)==s(m+1)
                c=c+1;
                m=m+1;
                if c>numel(d)
                    error('no convergence');
                end
            end

            % the number of equal values starting at first is equal to c+1
            expected_rkeep(idx(first+(0:c)))=c/2+first;
        end

        if isempty(expected_rkeep)
            assert(isempty(rkeep));
        else
            assertElementsAlmostEqual(expected_rkeep,rkeep);
        end
    end