function test_suite = test_cartprod
% tests for cosmo_cartprod
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_cartprod_cells()
    aeq=@(arg,v) assertEqual(cosmo_cartprod(arg),v);
    aeq({{1,2},{'a','b','c'}},...
            {1,2,1,2,1,2;'a','a' ,'b','b','c','c'}')

    aeq({[1,2],[5,6,7]},...
         [1,2,1,2,1,2;5,5,6,6,7,7]');

    aeq(repmat({1:2},1,4),...
       [1 2 1 2 1 2 1 2 1 2 1 2 1 2 1 2;...
        1 1 2 2 1 1 2 2 1 1 2 2 1 1 2 2;...
        1 1 1 1 2 2 2 2 1 1 1 1 2 2 2 2;...
        1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]')

function test_cartprod_struct()
    s=struct();
    s.name={'foo','bar'};
    s.dim=1:3;
    s.bool=[true,false];

    p=cosmo_cartprod(s);
    assertEqual(p{5}.name,'foo');
    assertEqual(p{5}.dim,3);

    m=[p{:}];
    assertEqual({m.name},repmat(s.name,1,6))
    assertEqual([m.dim],[1 1 2 2 3 3 1 1 2 2 3 3]);
    assertEqual([m.bool],(1:12)<=6);
    assertEqual(fieldnames(m),fieldnames(s));

function test_cartprod_empty()
    aeq=@(arg,v) assertEqual(cosmo_cartprod(arg),v);

    aeq(struct(),cell(1,0));
    aeq(cell(1),cell(0,1));

