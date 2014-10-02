function test_suite = test_index_unique
    initTestSuite;


function test_index_unique_()
    n=100;
    a=round(rand(n,1)*2)+1;
    b=round(rand(n,1)*2)+1;
    c=round(rand(n,1)*2)+1;

    abc=[a b c];
    [unq1,unused,idx1]=unique(abc,'rows');
    [idx2,vals2]=cosmo_index_unique({a,b,c});

    assertEqual(unq1,[vals2{:}]);

    nunq=size(unq1,1);
    assert(nunq==numel(idx2));

    % test some random elements
    rp=randperm(nunq);
    rp=rp(1:10);
    for j=rp
        assertEqual(find(idx1==j),idx2{j})
    end

    % test with some string labels
    labels={'a','bb','ccc'}';

    [idx3,vals3]=cosmo_index_unique({labels(a),b,labels(c)});
    assertEqual(idx3,idx2);
    v2to3={labels(vals2{1}),vals2{2},labels(vals2{3})};
    assertEqual(vals3,v2to3)

    % test with matrix input
    [idx4,vals4]=cosmo_index_unique(abc);
    assertEqual(idx4,idx2);
    assertEqual(vals4,[vals2{:}]);

    % test vector input
    rp=randperm(10);
    [idx5,vals5]=cosmo_index_unique(rp+20);
    assertEqual(idx5,{1});
    assertEqual(vals5,rp+20);

    [idx6,vals6]=cosmo_index_unique(rp'+20);
    assertEqual(cell2mat(idx6(rp))',1:numel(rp));
    assertEqual(vals6,(1:numel(rp))'+20);

    % test empty input

    % test wrong inputs
    aet=@(x)assertExceptionThrown(@()cosmo_index_unique(x),'');
    aetp=@(x,m)assertExceptionThrown(@()cosmo_index_unique(x),m);
    aet({[1,2],[3]});
    aet({[1,2],'a'});
    aetp({[1,2],{1,2}},'MATLAB:UNIQUE:InputClass');
    aet(ones([2 2 2]));
