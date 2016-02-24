function test_suite=test_config
% tests for cosmo_config

    initTestSuite;

function s=randstr()
    s=char(ceil(rand(1,20)*20+64));

function test_config_reading_empty()
    % should raise an exception
    helper_write_read_config(false);

function test_config_reading_with_paths()
    helper_write_read_config(true);

function test_config_unable_to_find_file()
    fn=tempname();
    assertExceptionThrown(@()cosmo_config(fn),'');

function test_config_unable_to_open_file()
    dirname=fileparts(mfilename('fullpath'));
    assertExceptionThrown(@()cosmo_config(dirname),'');


function helper_write_read_config(include_path_settings)
    tmp_fn=tempname();
    file_deleter=onCleanup(@()delete(tmp_fn));
    fid=fopen(tmp_fn,'w');
    file_closer=onCleanup(@()fclose(fid));

    orig_warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(orig_warning_state));
    empty_warning_state=orig_warning_state;
    empty_warning_state.shown_warnings=[];
    cosmo_warning(empty_warning_state);

    cosmo_warning('off');

    n_keys=ceil(rand()*5+5);

    if include_path_settings
        include_keys={'tutorial_data_path','output_data_path'};
    else
        include_keys={};
    end

    s=struct();
    for k=1:n_keys
        if k<=numel(include_keys)
            key=include_keys{k};
            value=pwd();
        else
            key=randstr();
            value=randstr();
        end
        fprintf(fid,'%s=%s\n',key,value);
        s.(key)=value;
    end
    fprintf(fid,'\n\n# this is not used\n');

    clear file_closer;

    % read configuration
    [c,read_tmp_fn]=cosmo_config(tmp_fn);
    assertEqual(c,s);
    assertEqual(read_tmp_fn,tmp_fn);

    w=cosmo_warning();
    if include_path_settings
        % no warnign shown
        assert(isempty(w.shown_warnings));
    else
        % warning must have been shown if not include path settings
        assert(numel(w.shown_warnings)>0);
        assert(iscellstr(w.shown_warnings))
    end

    % add one key-value pair
    c2=c;
    key=randstr();
    c2.(key)=randstr();

    % write and read new configuration
    cosmo_config(tmp_fn,c2);
    c3=cosmo_config(tmp_fn);

    % should be different with missing key-value pair
    assert(~isequal(c,c3));

    % should be the same
    assertEqual(c2,c3);




