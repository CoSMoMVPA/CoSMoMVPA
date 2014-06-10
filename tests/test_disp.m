function test_suite = test_disp
    initTestSuite;


function test_disp_()
    aeq=@(s,y) assertEqual(s,cosmo_disp(y));

    aeq(['[ 1         2         3        ...     '...
            '8         9        10 ]@1x10'],1:10);
    
    
    x=struct();
    x.a_cell={[],{'cell in cell',[1 2; 3 4]}};
    x.a_matrix=[10 11 12; 13 14 15];
    x.a_string='hello world';
    x.a_struct.another_struct.name='me';

    s=['.a_cell                                                        ';
    '  { [  ]@0x0  { ''cell in cell''  [ 1         2                  ';
    '                                  3         4 ]@2x2 }@1x2 }@1x2';
    '.a_matrix                                                      ';
    '  [ 10        11        12                                     ';
    '    13        14        15 ]@2x3                               ';
    '.a_string                                                      ';
    '  ''hello world''                                                ';
    '.a_struct                                                      ';
    '  .another_struct                                              ';
    '    .name                                                      ';
    '      ''me''                                                     '];

    aeq(s,x);
    
    
    
    
    