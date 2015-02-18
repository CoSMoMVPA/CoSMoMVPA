function test_suite=test_flatten()
    initTestSuite;

function test_flatten_and_unflatten()


    aet_fl=@(varargin) assertExceptionThrown(@()...
                                cosmo_flatten(varargin{:}),'');
    aet_unfl=@(varargin) assertExceptionThrown(@()...
                                cosmo_unflatten(varargin{:}),'');

    %% single sample, flatten along features
    % test flatten
    data=reshape(1:30, [1 2 3 5]);
    ds=cosmo_flatten(data,{'i','j','k'},{1:2,1:3,{'a','b','c','d','e'}});
    assertEqual(ds.samples,1:30);
    assertEqual(ds.fa.i,repmat([1 2],1,15));
    assertEqual(ds.fa.j,repmat([1 1 2 2 3 3],1,5));
    assertEqual(ds.fa.k,kron(1:5,ones(1,6)));
    aet_fl(ds,{'i','j','k'},{1:2,1:3,{'a','b','c','d'}});

    % test unflatten
    [data2,labels,values]=cosmo_unflatten(ds,2);
    assertEqual(data,data2);
    assertEqual(labels,{'i','j','k'});
    assertEqual(values,{1:2,1:3,{'a','b','c','d','e'}});
    aet_unfl(ds,1);

    %% single feature, flatten along samples
    % test flatten
    data=reshape(1:30, [2 3 5 1]);
    ds=cosmo_flatten(data,{'i','j','k'},{1:2,1:3,{'a','b','c','d','e'}},1);
    assertEqual(ds.samples,(1:30)');
    assertEqual(ds.sa.i,repmat([1 2],1,15)');
    assertEqual(ds.sa.j,repmat([1 1 2 2 3 3],1,5)');
    assertEqual(ds.sa.k,kron(1:5,ones(1,6))');
    aet_fl(ds,{'i','j','k'},{1:2,1:3,{'a','b','c','d'}},1);


    % test unflatten
    [data2,labels,values]=cosmo_unflatten(ds,1);
    assertEqual(data,data2);
    assertEqual(labels,{'i','j','k'});
    assertEqual(values,{1:2,1:3,{'a','b','c','d','e'}});
    aet_unfl(ds,2);


    %% two samples, flatten along features
    % test flatten
    data=reshape(1:60, [2 2 3 5]);
    ds=cosmo_flatten(data,{'i','j','k'},{1:2,1:3,{'a','b','c','d','e'}});
    assertEqual(ds.samples,[1:2:60;2:2:60]);
    assertEqual(ds.fa.i,repmat([1 2],1,15));
    assertEqual(ds.fa.j,repmat([1 1 2 2 3 3],1,5));
    assertEqual(ds.fa.k,kron(1:5,ones(1,6)));
    aet_fl(ds,{'i','j','k'},{1:2,1:3,{'a','b','c','d'}});


    % test unflatten
    [data2,labels,values]=cosmo_unflatten(ds,2);
    assertEqual(data,data2);
    assertEqual(labels,{'i','j','k'});
    assertEqual(values,{1:2,1:3,{'a','b','c','d','e'}});
    aet_unfl(ds,1);


    %% two features, flatten along samples
    % test flatten
    data=reshape(1:60, [2 3 5 2]);
    ds=cosmo_flatten(data,{'i','j','k'},{1:2,1:3,{'a','b','c','d','e'}},1);
    assertEqual(ds.samples,[1:30;31:60]');
    assertEqual(ds.sa.i,repmat([1 2],1,15)');
    assertEqual(ds.sa.j,repmat([1 1 2 2 3 3],1,5)');
    assertEqual(ds.sa.k,kron(1:5,ones(1,6))');
    aet_fl(ds,{'i','j','k'},{1:2,1:3,{'a','b','c','d'}},1);

    % test unflatten
    [data2,labels,values]=cosmo_unflatten(ds,1);
    assertEqual(data,data2);
    assertEqual(labels,{'i','j','k'});
    assertEqual(values,{1:2,1:3,{'a','b','c','d','e'}});
    aet_unfl(ds,2);


