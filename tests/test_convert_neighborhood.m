function test_suite = test_convert_neighborhood()
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

    % verify matrix conversion
    mx4=cosmo_convert_neighborhood(nb2);
    assertEqual(mx4,mx);
    % conversion to struct

    % conversion to struct
    nh2=cosmo_convert_neighborhood(nb3,'struct');
    assertEqual(nh2.neighbors,nb);
    assert(isfield(nh2,'fa'));
    assert(isfield(nh2,'a'));
    nh3=cosmo_convert_neighborhood(mx,'struct');
    assertEqual(nh2,nh3)

    % test exceptions
    aet=@(x)assertExceptionThrown(@()cosmo_convert_neighborhood(x{:}),'');
    aet({'foo','foo'});
    aet({ds});
    aet({ds,'foo'});
    mx(1)=NaN;
    aet({mx});
    nh.neighbors{1}=NaN;
    aet({nh});
    nb{1}=NaN;
    aet({nb});





