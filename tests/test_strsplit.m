function test_suite = test_strsplit
% tests for cosmo_strsplit
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_strsplit_basics
    aeq=@(a,varargin)assertEqual(cosmo_strsplit(varargin{:}),a);

    aeq({'A','AbbAbA','AbA','A','Ab'},'A*AbbAbA*AbA*A*Ab','*');
    aeq({'','A','AbbAbA','','AbA','A','Ab',''},'*A*AbbAbA**AbA*A*Ab*','*');
    aeq({'','bbAb','b','*Ab'},'A*AbbAbA*AbA*A*Ab','A*A');
    aeq('bbAb','A*AbbAbA*AbA*A*Ab','A*A',2);
    aeq('*Ab','A*AbbAbA*AbA*A*Ab','A*A',-1);
    aeq({'bb','b'},'A*AbbAbA*AbA*A*Ab','A*A',2,'A');
    aeq('bb','A*AbbAbA*AbA*A*Ab','A*A',2,'A',1);

    aeq({'a','b','c'},' a b  c ');
    aeq({'','a','b','','c','','',''},' a b  c   ',' ');
    aeq({' a b','c',' '},' a b  c   ','  ');

    aeq({'a','b','c'},sprintf('a\nb\t\tc\t\n\t'));
    aeq({'a','b','','c'},sprintf('a\tb\t\tc'),'\t');

    aeq({'abcd'},'abcd','e');
    aeq({''},'','');
    aeq({''},'','x');
    aeq({'abc'},'abc','');

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_strsplit(varargin{:}),'');
    aet('A*A','A',1:2);
    aet('A*A',struct());
    aet('A*A',{});
    aet(struct(),'A*A');
    aet({},'A*A');
    aet({});








