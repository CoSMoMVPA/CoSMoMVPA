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
    
    % deal with empty struct fine
    assertEqual(sj(struct),struct);
    assertEqual(sj(cell(0)),struct);
    
    % check exceptions
    ar=@(args) assertExceptionThrown(@()cosmo_structjoin(args{:}),'');
    ar({'a'});
    ar({struct,'a'});
    ar({1});
    ar({ar});
    ar({[]});
    
    % test shebang
    ar({'!',{'b'},'b',{1,2}});
    ar({'!',{'c',3},'b',{1,2}});
    ar({'!',{'c',3},'b',{1,2}});
    ar({'!',x_,y_});
    
    assertEqual(sj('!',y_,x_),sj(y_,x_));
    assertEqual(sj(x_,y_),sj(y_,x_,'!',y_));
    
    
    
    
