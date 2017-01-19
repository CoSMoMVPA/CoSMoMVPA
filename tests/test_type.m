function test_suite = test_type()
% tests for cosmo_type
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_type_basics()
    fn=cosmo_make_temp_filename();
    cleaner=onCleanup(@()delete(fn));

    data=write_data(fn);

    s=cosmo_type(fn);
    assertEqual(s,data);

function test_dim_type_fprintf()
    if cosmo_skip_test_if_no_external('!evalc')
        return;
    end

    fn=cosmo_make_temp_filename();
    cleaner=onCleanup(@()delete(fn));

    data=write_data(fn);

    expr=sprintf('cosmo_type(''%s'')',fn);

    s=evalc(expr);
    s_fixed=regexprep(s,'ans\s*=\s*','');
    s_fixed=regexprep(s_fixed,'\s*$','');

    assertEqual(s_fixed,data);


function data=write_data(fn)
    fid=fopen(fn,'w');
    data=sprintf('foo\nbar%s',cosmo_make_temp_filename());
    fprintf(fid,data);
    fclose(fid);


