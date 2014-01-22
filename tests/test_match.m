function test_suite = test_match
    initTestSuite;


function test_match_()
    % helper function to convert numeric to logical array
    b=@(x)logical(x);

    % basic numeric stuff
    assertEqual(cosmo_match(5:-1:1,[2 3]),b([0,0,1,1,0]));
    assertEqual(cosmo_match((5:-1:1)',[2 3]),b([0,0,1,1,0])');

    % basic strings
    assertEqual(cosmo_match({'a','b','c'},{'b','c','d','e','b'}),b([0 1 1]));
    assertEqual(cosmo_match({'b','c','d','e','b'},{'a','b','c'}),...
                                                        b([1 1 0 0 1]));

    assertEqual(cosmo_match({'a','b','c'}',{'b','c','d','e','b'}),b([0 1 1]'));
    assertEqual(cosmo_match({'b','c','d','e','b'}',{'a','b','c'}),...
                                                        b([1 1 0 0 1]'));

    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'a'}),b([0 0 1 0]));                                                
    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'aa'}),b([0 1 0 1]));                                                
    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'a','aaa'}),b([1 0 1 0]));                                                


    % empty inputs ok if types match
    assertEqual(cosmo_match({},''),b([]));
    assertEqual(cosmo_match([],[]),b([]));

    assertExceptionThrown(@()cosmo_match({},[]),'');
    assertExceptionThrown(@()cosmo_match([],{}),'');                                                

    % can use a single string                                                
    assertEqual(cosmo_match({'b','c','d','e','b'},'b'),b([1 0 0 0 1]));

    % cannot deal with logical arrays
    assertExceptionThrown(@()cosmo_match(5:-1:1,b([0,0,1,1,0])),'');

    % first argument cannot be a string
    assertExceptionThrown(@()cosmo_match('',''),'');
    assertExceptionThrown(@()cosmo_match('x',''),'');

    % no mixed datatypes
    assertExceptionThrown(@()cosmo_match(1,''),'');
    assertExceptionThrown(@()cosmo_match({'x'},1),'');
    assertExceptionThrown(@()cosmo_match({1,2},''),'');
    assertExceptionThrown(@()cosmo_match(['x'],1),'');

    assertExceptionThrown(@()cosmo_match({'x',1},''),'');
    assertExceptionThrown(@()cosmo_match({'x',1},[]),'');
    assertExceptionThrown(@()cosmo_match({'x',1},'x'),'');
    assertExceptionThrown(@()cosmo_match({'x',1},1),'');

    % no support for 2D arrays
    assertExceptionThrown(@()cosmo_match(eye(2),1),'');
    assertExceptionThrown(@()cosmo_match(cell(2),1),'');

    % no structs
    assertExceptionThrown(@()cosmo_match(struct(),[]),'');
    assertExceptionThrown(@()cosmo_match(struct(),''),'');
    assertExceptionThrown(@()cosmo_match([],struct()),'');
    assertExceptionThrown(@()cosmo_match({},struct()),'');
