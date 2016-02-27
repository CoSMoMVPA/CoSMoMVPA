function test_suite=test_dir
% tests for cosmo_dir
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dir_basics()
    tmp_dir=cosmo_make_temp_filename();
    cleaner=onCleanup(@()remove_directory(tmp_dir));

    files={'foo.m',...          % 1
           'bar/foo.m',...      % 2
           'bar/bar.txt',...    % 3
           'bar/foo/x.m',...    % 4
           'bar/foo/y.m',...    % 5
           'bar/foo/yx.m',...   % 6
           'bar/foo/yy.m',...   % 7
           'foo.txt',...        % 8
           'fop.txt'};          % 9

    files=translate_to_platform(files);

    touch_files(tmp_dir, files);

    assert_dir_equal(files,tmp_dir);
    assert_dir_equal(files,tmp_dir,'*');
    assert_dir_equal([],tmp_dir,'*.x');


    assert_dir_equal(files([1 2 4 5 6 7]),tmp_dir,'*.m');
    assert_dir_equal(files([2 4 5 6 7]),tmp_dir,'bar','*.m');
    assert_dir_equal(files([4 5 6 7]),tmp_dir,'bar/foo','*.m');
    assert_dir_equal(files([4 5]),tmp_dir,'bar','?.m');
    assert_dir_equal(files([6 7]),tmp_dir,'bar','??.m');
    assert_dir_equal(files([3 8 9]),tmp_dir,'???.txt');
    assert_dir_equal(files([8 9]),tmp_dir,'fo?.txt');
    assert_dir_equal([],tmp_dir,'fo??.txt');
    assert_dir_equal([],tmp_dir,'');
    assert_dir_equal([],tmp_dir,'aa');

    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            run_cosmo_dir(varargin{:}),'');

    % directory must exist
    aet(tmp_dir,'','*');
    aet(tmp_dir,'xx','*');

    % arguments must be strings
    aet(tmp_dir,[]);
    aet(tmp_dir,{''});
    aet(tmp_dir,{''},'*');

    % cannot have more than two arguments
    aet(tmp_dir,'bar','*','*');



function result=run_cosmo_dir(in_dir,varargin)
    orig_pwd=pwd();
    cleaner=onCleanup(@()cd(orig_pwd));
    cd(in_dir);
    result=cosmo_dir(varargin{:});

function assert_dir_equal(expected, in_dir, varargin)
    result=run_cosmo_dir(in_dir,varargin{:});
    if isempty(expected)
        assert(isempty(result));
    else
        filenames={result.name};
        assertEqual(sort(filenames(:)),...
                    sort(translate_to_platform(expected(:))));
    end

function result=translate_to_platform(filenames)
    if iscell(filenames)
        result=cellfun(@translate_to_platform,filenames,...
                                            'UniformOutput',false);
    elseif ischar(filenames)
        result=strrep(filenames,'/',filesep);
    end


function touch_files(in_dir,filenames)
    cellfun(@(fn)touch_single_file(in_dir,fn),filenames);

function result=touch_single_file(in_dir,fn)
    pth_fn=fullfile(in_dir,fn);
    pth=fileparts(pth_fn);

    if ~isdir(pth)
        mkdir(pth);
    end

    fid=fopen(pth_fn,'w');
    fprintf(fid,'');
    fclose(fid);
    result=1;


function remove_directory(dir_name)
    is_octave=cosmo_wtf('is_octave');
    if is_octave
        % do not ask for confirmation
        confirm_val=confirm_recursive_rmdir(false);
        cleaner=onCleanup(@()confirm_recursive_rmdir(confirm_val));
    end

    rmdir(dir_name,'s');



