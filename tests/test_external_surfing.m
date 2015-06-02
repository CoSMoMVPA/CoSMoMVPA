function test_suite=test_external_surfing()
    initTestSuite;

function test_surfing_subsample_surface()
    if cosmo_skip_test_if_no_external('surfing')
        return;
    end
    opt=struct();
    opt.progress=false;

    vertices=[0 -1 -2 -1  1  2  1  3  4  3;
              0 -2  0  2  2  0 -2  2  0 -2;
              0  0  0  0  0  0  0  0  0  0]';

    faces=[1 1 1 1 1 1 5 8 6  6;
           2 3 4 5 6 7 8 9 9 10;
           3 4 5 6 7 2 6 6 10 7]';


    [v_sub,f_sub]=surfing_subsample_surface(vertices,faces,1,.2,false);

    assertEqual(v_sub',[ -1 -2 -1 1 2 1 3 4 3
                         -2 0 2 2 0 -2 2 0 -2
                          0 0 0 0 0 0 0 0 0 ]);
    assertEqual(f_sub',[ 1 1 1 1 4 5 7 5
                         2 3 4 5 7 9 8 8
                         3 4 5 6 5 6 5 9 ]);

    [v_sub2,f_sub2]=surfing_subsample_surface(v_sub,f_sub,1,.2,false);
    assertEqual(v_sub2',[ -1 -2 -1 1 1 3 4 3
                          -2 0 2 2 -2 2 0 -2
                           0 0 0 0 0 0 0 0 ]);

    assertEqual(f_sub2',[ 1 1 1 4 6 4
                          2 3 4 8 7 7
                          3 4 5 5 4 8 ]);

    [v_sub2_alt,f_sub2_alt]=surfing_subsample_surface(vertices,faces,...
                                                        2,.2,false);
    assertEqual(v_sub2_alt,v_sub2);
    assertEqual(f_sub2_alt,f_sub2);

