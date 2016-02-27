function test_suite = test_remove_useless_data
% tests for cosmo_remove_useless_data
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_remove_useless_data_basics
    ds=cosmo_synthetic_dataset();
    ds.samples(2,3)=NaN;
    ds.samples(3,4)=Inf;
    ds.samples(5,:)=1;
    ds.samples(:,6)=1;

    assert_equal_sliced(ds,[1 2 5],2);
    assert_equal_sliced(ds,[1 2 5],2,[]);
    assert_equal_sliced(ds,[1 2 5],2,1);
    assert_equal_sliced(ds,[1 4 6],1,2);
    assert_equal_sliced(ds,[1 2 5],2,1,'all');
    assert_equal_sliced(ds,[1 4 6],1,2,'all');
    assert_equal_sliced(ds,[1 2 5],2,[],[]);
    assert_equal_sliced(ds,[1 2 5],2,1,[]);
    assert_equal_sliced(ds,[1 4 6],1,2,[]);

    assert_equal_sliced(ds,[1 2 4 5],2,1,'variable');
    assert_equal_sliced(ds,[1 3 4 6],1,2,'variable');

    assert_equal_sliced(ds,[1 2 5 6],2,1,'finite');
    assert_equal_sliced(ds,[1 4 5 6],1,2,'finite');

function test_remove_useless_data_vec
    ds=cosmo_synthetic_dataset();
    ds1=cosmo_slice(ds,1);
    ds1.samples(2)=NaN;
    ds1.samples(4)=Inf;

    assert_equal_sliced(ds1,[1 3 5 6],2);
    assert_equal_sliced(ds1,[1 3 5 6],2,1,'all');
    assert_equal_sliced(ds1,[1 3 4 5 6],2,1,'variable');
    assert_equal_sliced(ds1,[1 3 5 6],2,1,'finite');

    ds2=cosmo_slice(ds,1,2);
    ds2.samples(2)=NaN;
    ds2.samples(4)=Inf;

    assert_equal_sliced(ds2,[1 3 5 6],1,2);
    assert_equal_sliced(ds2,[1 3 5 6],1,2,'all');
    assert_equal_sliced(ds2,[1 3 4 5 6],1,2,'variable');
    assert_equal_sliced(ds2,[1 3 5 6],1,2,'finite');

function test_remove_useless_data_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_remove_useless_data(varargin{:}),'');
    aet(struct);
    aet({});

    % must have samples
    ds=struct();
    ds.foo=[];
    aet(ds);

    % input must be matrix
    data=randn([2,3,2]);
    aet(data);
    ds=struct();
    ds.samples=data;

    % last argument must be kosher
    data=randn(2,3);
    aet(data,'foo');
    aet(data,1,'foo');
    aet(data,2,'foo');
    aet(data,2,struct());
    aet(data,3);
    aet(data,3,'variable');

    ds.samples=data;
    aet(ds,'foo');
    aet(ds,1,'foo');
    aet(ds,2,'foo');
    aet(ds,2,struct());
    aet(ds,3);
    aet(ds,3,'variable');






function assert_equal_sliced(ds, select, dim, varargin)
    [ds_useful,msk]=cosmo_remove_useless_data(ds, varargin{:});
    assert(islogical(msk));

    assertEqual(cosmo_slice(ds,select,dim),ds_useful);
    assertEqual(cosmo_slice(ds,msk,dim),ds_useful);
