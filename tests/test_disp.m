function test_suite = test_disp
    initTestSuite;


function test_disp_()
    if cosmo_wtf('is_octave')
        cosmo_notify_skip_test('Octave does not support ''evalc''');
        return;
    end

    aeq=@(s,y) assertEqual([s repmat(sprintf('\n'),size(s,1),1)],...
                                        evalc('cosmo_disp(y)'));

    aeq(['[ 1         2         3  ...  '...
                '8         9        10 ]@1x10'],1:10);


    x=struct();
    x.a_cell={[],{'cell in cell',[1 2; 3 4]}};
    x.a_matrix=[10 11 12; 13 14 15];
    x.a_string='hello world';
    x.a_struct.another_struct.name='me';

    s=sprintf(['.a_cell                                        \n'...
                '  { [  ]  { ''cell in cell''  [ 1         2      \n'...
                '                              3         4 ] } }\n'...
                '.a_matrix                                      \n'...
                '  [ 10        11        12                     \n'...
                '    13        14        15 ]                   \n'...
                '.a_string                                      \n'...
                '  ''hello world''                                \n'...
                '.a_struct                                      \n'...
                '  .another_struct                              \n'...
                '    .name                                      \n'...
                '      ''me''                                     ']);



    aeq(s,x);





