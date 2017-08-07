function test_suite = test_clusterize()
% tests for cosmo_clusterize
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_clusterize_basics
    ds=cosmo_synthetic_dataset('size','normal','ntargets',1,'nchunks',1);
    sample=ds.samples;

    nh_struct=cosmo_cluster_neighborhood(ds,'progress',false);
    nh=cosmo_convert_neighborhood(nh_struct,'matrix');

    x=sample;
    sample=x>2;
    cl1=cosmo_clusterize(sample,nh);
    assertEqual(cl1,{21,25});
    nb=cosmo_convert_neighborhood(nh,'cell');

    sample=round(x/2);
    cl2=cosmo_clusterize(sample,nh);
    assertEqual(cl2,{[1 11 9 14 17 21 22 23 26 30 25]',...
                    [3 6]',28});

    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_clusterize(varargin{:}),'');
    aet('foo',[]);
    aet(sample,[]);
    aet(sample,-1);
    aet('foo',nh);
    aet(zeros([2 2 2 ]),nh);
    aet([sample;sample],nh);
    aet(sample,zeros([1 1 6]));
    aet(sample,ones(1,7));
    aet(sample,[true;false;true;true;true;false]);

