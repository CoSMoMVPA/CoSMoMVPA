function test_suite=test_tail
% tests for cosmo_tail
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_tail_basics
    nsamples=ceil(15+rand()*5);
    nselect=floor(rand()*nsamples);
    ratio=nselect/nsamples;

    x=randn(nsamples,1);

    [xs,idxs]=sort(x);
    mp=zeros(nsamples,1);
    mp(idxs)=1:nsamples;

    s=cellfun(@(x)char(x),num2cell(70+mp),...
                        'UniformOutput',false);
    ss=sort(s);


    [v,i]=cosmo_tail(x,nselect);
    assertEqual(v,xs(end+(0:-1:-(nselect-1))));
    assertEqual(i,idxs(end+(0:-1:-(nselect-1))));
    [v2,i2]=cosmo_tail(x,ratio);
    assertEqual(v,v2);
    assertEqual(i,i2);
    [v3,i3]=cosmo_tail(s,nselect);
    assertEqual(v3,ss(end+(0:-1:-(nselect-1))));
    assertEqual(i,i3);
    [v4,i4]=cosmo_tail(s,ratio);
    assertEqual(v3,v4);
    assertEqual(i,i4);


    [v,i]=cosmo_tail(x,-nselect);
    assertEqual(v,xs(1:nselect));
    assertEqual(i,idxs(1:nselect));
    [v2,i2]=cosmo_tail(x,-ratio);
    assertEqual(v,v2);
    assertEqual(i,i2);
    [v3,i3]=cosmo_tail(s,-nselect);
    assertEqual(v3,ss(1:nselect));
    assertEqual(i,i3);
    [v4,i4]=cosmo_tail(s,-ratio);
    assertEqual(v3,v4);
    assertEqual(i,i4);


function test_tail_left_right()
    n=ceil(10*rand()+10);
    xs=randn(n,1);

    n_keep=ceil(rand()*3+2);
    res=cosmo_tail(xs,n_keep);
    assert(numel(res)==n_keep);

    % ensure results match
    s=sort(xs);
    assertEqual(s(end-(0:(n_keep-1))),res);

    % reverse tail and results
    res_inv=cosmo_tail(xs,-n_keep);
    assertEqual(s(1:n_keep),res_inv);





function test_tail_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_tail(varargin{:}),'');

    % not ok with non-cellstring / non-vector input
    aet(struct(),0);
    aet({1,2},0);

    % matrix input not ok
    aet(randn(4),2);
    aet({'a','b';'c','d'},1);

    % outside of range not ok
    aet(1:4,5);
    aet(1:4,-5);

    % second argument must be numeric scaler
    aet(1:4,[1 2])
    aet(1:4,struct)
