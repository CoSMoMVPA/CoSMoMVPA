function test_suite = test_match
% tests for cosmo_match
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_match_()
    % helper function to convert numeric to logical array
    b=@(x)logical(x);

    % basic numeric stuff
    assertEqual(cosmo_match(5:-1:1,[2 3]),b([0,0,1,1,0]));
    assertEqual(cosmo_match((5:-1:1)',[2 3]),b([0,0,1,1,0])');

    % basic strings
    assertEqual(cosmo_match({'a','b','c'},{'b','c','d','e','b'}),...
                                                        b([0 1 1]));
    assertEqual(cosmo_match({'b','c','d','e','b'},{'a','b','c'}),...
                                                        b([1 1 0 0 1]));

    assertEqual(cosmo_match({'a','b','c'}',{'b','c','d','e','b'}),...
                                                        b([0 1 1]'));
    assertEqual(cosmo_match({'b','c','d','e','b'}',{'a','b','c'}),...
                                                        b([1 1 0 0 1]'));

    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'a'}),b([0 0 1 0]));
    assertEqual(cosmo_match({'aaa','aa','a','aa'},'a'),b([0 0 1 0]));

    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'aa'}),b([0 1 0 1]));
    assertEqual(cosmo_match({'aaa','aa','a','aa'},{'a','aaa'}),...
                                                           b([1 0 1 0]));

    % multiple inputs
    assertEqual(cosmo_match(1:5,[2 5],6:10,7),b([0 1 0 0 0]));
    assertEqual(cosmo_match(1:5,[2 5],6:10,6),b([0 0 0 0 0]));
    assertEqual(cosmo_match(1:5,1:10,6:10,7:9),b([0 1 1 1 0]));
    assertEqual(cosmo_match(1:5,1:10,6:10,7:9,2:6,4:5),b([0 0 1 1 0]));

    assertEqual(cosmo_match({'a','b','c'},'b',{'d','e','f'},{'f','e'}),...
                                                    b([0 1 0]));


    % empty inputs ok if types match
    assertEqual(cosmo_match({},''),b([]));
    assertEqual(cosmo_match([],[]),b([]));

    assertExceptionThrown(@()cosmo_match({},[]),'');
    assertExceptionThrown(@()cosmo_match([],{}),'');

    % can use a single string
    assertEqual(cosmo_match({'b','c','d','e','b'},'b'),b([1 0 0 0 1]));

    % can use function handles
    assertEqual(cosmo_match(1:4,@(x)mod(x,2)==0),b([0 1 0 1]));
    assertEqual(cosmo_match({'b','c','d','c'},@(x)x=='c'),b([0 1 0 1]));


    % cannot deal with logical arrays
    assertExceptionThrown(@()cosmo_match(5:-1:1,b([0,0,1,1,0])),'');

    % first argument cannot be a string
    assertExceptionThrown(@()cosmo_match('',''),'');
    assertExceptionThrown(@()cosmo_match('x',''),'');

    % no mixed datatypes
    assertExceptionThrown(@()cosmo_match(1,''),'');
    assertExceptionThrown(@()cosmo_match({'x'},1),'');
    assertExceptionThrown(@()cosmo_match({1,2},''),'');
    assertExceptionThrown(@()cosmo_match('',{1,2}),'');

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

    % needs even number of arguments
    assertExceptionThrown(@()cosmo_match({'a'}),'');
    assertExceptionThrown(@()cosmo_match({'a'},{'b'},{'c'}),'');
    assertExceptionThrown(@()cosmo_match({'a'},{'b'},{'c'},1,2),'');

    % multiple inputs must have the same size of output
    assertExceptionThrown(@()cosmo_match(1:3,3,6:9,9),'');
    assertExceptionThrown(@()cosmo_match({'a','b'},{'a'},{'c'}',{'c'}),'');

    % odd elements must be cell string ro numeric
    assertExceptionThrown(@()cosmo_match('a','b','a','c',{'c'}),'');



    % function handle has to return boolean output
    assertExceptionThrown(@()cosmo_match(1:4,@(x)x+1),'');
