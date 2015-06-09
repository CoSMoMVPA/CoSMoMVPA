function test_suite=test_structjoin
    initTestSuite;

function test_structjoin_
    % test a few cell structures
    sj=@cosmo_structjoin;
    xa={'a',{1;2},'b',{1,2}};
    x_=struct();
    x_.a={1;2};
    x_.b={1,2};
    assertEqual(sj(xa),x_);
    assertEqual(sj(xa{:}),x_);

    ya={x_,'a',3,'x',x_,{'c','hello'}};
    y_=struct();
    y_.a=3;
    y_.b=x_.b;
    y_.x=x_;
    y_.c='hello';
    assertEqual(sj(ya),y_);
    assertEqual(sj(ya{:}),y_);

    % can override subfield
    x=struct();
    x.a.foo=1;
    x.b.bar=2;

    y=struct();
    y.a.foo=3;
    y.c.baz=3;

    z=struct();
    z.a.foo=3;
    z.b.bar=2;
    z.c.baz=3;
    assertEqual(sj(x,y),z);


    % deal with empty struct fine
    assertEqual(sj(struct),struct);
    assertEqual(sj(cell(0)),struct);

    % check exceptions
    aet=@(varargin) assertExceptionThrown(@()...
                            cosmo_structjoin(varargin{:}),'');
    aet('a');
    aet(struct,'a');
    aet(1);
    aet(aet);
    aet([]);

    s=struct();
    s.a=2;
    s.b=3;
    s2=cat(1,s,s);
    aet(s2);

