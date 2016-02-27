function test_suite = test_type()
% tests for cosmo_type
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_type_basics()
    fn=cosmo_make_temp_filename();
    cleaner=onCleanup(@()delete(fn));

    data=write_data(fn);

    s=cosmo_type(fn);
    assertEqual(s,data);

function test_dim_type_fprintf()
    if cosmo_wtf('is_octave')
        cosmo_notify_test_skipped('''evalc'' is not available in Octave');
        return;
    end

    fn=cosmo_make_temp_filename();
    cleaner=onCleanup(@()delete(fn));

    data=write_data(fn);

    s=evalc('cosmo_type(fn);');
    assertEqual(s,data);


function data=write_data(fn)
    fid=fopen(fn,'w');
    data=sprintf('foo\nbar%s',cosmo_make_temp_filename());
    fprintf(fid,data);
    fclose(fid);


