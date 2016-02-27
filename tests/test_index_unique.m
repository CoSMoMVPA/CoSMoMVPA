function test_suite = test_index_unique
% tests for cosmo_index_unique
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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

    if cosmo_wtf('is_matlab')
        id_different_classes='MATLAB:UNIQUE:InputClass';
    else
        id_different_classes='';
    end
    aetp({[1,2],{1,2}},id_different_classes);
    aet(ones([2 2 2]));


function test_unique_with_nans
    n_rows_half=100+ceil(rand()*20);
    %n_rows_half=2;
    n_rows=n_rows_half*2;
    x=ceil(rand(n_rows,2)*sqrt(n_rows_half));

    rp=get_non_identity_randperm(n_rows);

    rp1=rp(1:n_rows_half);
    rp2=rp(n_rows_half+(1:n_rows_half));

    % first column, half of the rows become NaN
    x(rp1,1)=NaN;
    x(rp1,2)=1:n_rows_half;
    x(rp2,1)=1:n_rows_half;
    x(rp2,2)=1:n_rows_half;


    rp_y=get_non_identity_randperm(n_rows);

    y=x(rp_y,:);

    % test with numeric input
    [x_idx,x_unq]=cosmo_index_unique(x);
    [y_idx,y_unq]=cosmo_index_unique(y);

    assertFalse(isequal(x_unq,y_unq));
    % due to NaNs, the indices must be different
    assertFalse(isequal([x_idx{:}],rp_y([y_idx{:}])));

    % test with cell input
    [xx_idx,xx_unq]=cosmo_index_unique({x(:,1),x(:,2)});
    [yy_idx,yy_unq]=cosmo_index_unique({y(:,1),y(:,2)});

    assertFalse(isequal(xx_unq,yy_unq));
    % due to NaNs, the indices must be different
    assertFalse(isequal([xx_idx{:}],rp_y([yy_idx{:}])));


function test_index_unique_empty()
    empty_args={{},{[],{}},{[]},{{},{}}};
    for k=1:numel(empty_args)
        empty_arg=empty_args{k};

        [idxs,unq]=cosmo_index_unique(empty_arg);
        assertTrue(iscell(idxs));
        assertTrue(numel(idxs)==1);
        assertEqual(numel(unq),numel(empty_arg));
        assertTrue(all(cellfun(@isempty,unq)));
    end


function rp=get_non_identity_randperm(n)
    while true
        rp=randperm(n);
        if ~isequal(rp,1:n)
            break;
        end
    end