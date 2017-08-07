function test_suite = test_convert_neighborhood()
% tests for cosmo_convert_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_convert_neighborhood_basis()
    ds=cosmo_synthetic_dataset();
    nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
    %
    % conversion to matrix
    mx=cosmo_convert_neighborhood(nh,'matrix');
    assertEqual(mx,[  1 2 3 4 5 6
                      4 1 2 1 4 5
                      2 5 6 5 2 3
                      0 3 0 0 6 0 ]);
    mx2=cosmo_convert_neighborhood(nh);
    assertEqual(mx,mx2);
    mx3=cosmo_convert_neighborhood(nh.neighbors);
    assertEqual(mx,mx3);
    mx4=cosmo_convert_neighborhood(mx,'matrix');
    assertEqual(mx,mx4);

    %
    % conversion to cell
    nb=cosmo_convert_neighborhood(nh,'cell');
    assertEqual(nb,{  [ 1 4 2 ]
                      [ 2 1 5 3 ]
                      [ 3 2 6 ]
                      [ 4 1 5 ]
                      [ 5 4 2 6 ]
                      [ 6 5 3 ] });
    nb2=cosmo_convert_neighborhood(mx);
    assertEqual(nb,nb2)
    nb3=cosmo_convert_neighborhood(mx,'cell');
    assertEqual(nb,nb3)
    nb4=cosmo_convert_neighborhood(nb,'cell');
    assertEqual(nb,nb4);

    % verify matrix conversion
    mx5=cosmo_convert_neighborhood(nb2);
    assertEqual(mx5,mx);
    % conversion to struct

    % conversion to struct
    nh2=cosmo_convert_neighborhood(nb3,'struct');
    assertEqual(nh2.neighbors,nb);
    assert(isfield(nh2,'fa'));
    assert(isfield(nh2,'a'));
    nh3=cosmo_convert_neighborhood(mx,'struct');
    assertEqual(nh2,nh3)
    nh4=cosmo_convert_neighborhood(nh2,'struct');
    assertEqual(nh2,nh4)


    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_convert_neighborhood(varargin{:}),'');
    aet('foo','foo');
    aet(ds);
    aet(ds,'foo');

    aet(mx,'foo');
    aet(nb,'foo');
    aet(nh,'foo');

    mx(1)=NaN;
    aet(mx);
    nh.neighbors{1}=NaN;
    aet(nh);
    nb{1}=NaN;
    aet(nb);

    mx=zeros([2 2 2]);
    aet(mx);
    mx=[false true];
    aet(mx);




