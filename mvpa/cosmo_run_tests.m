function did_pass=cosmo_run_tests(varargin)
% run unit and documentation tests
%
% did_pass=cosmo_run_tests(['verbose',v]['output',fn])
%
% Inputs:
%   '-verbose'        do not run with verbose output
%   '-logfile',fn     store output in a file named fn (optional, if omitted
%                     output is written to the terminal window)
%   'file.m'          run tests in 'file.m'
%   '-no_doctest'     skip doctest
%   '-no_unittest'    skip unittest
%
% Examples:
%   % run tests with defaults
%   cosmo_run_tests
%
%   % run with non-verbose output
%   cosmo_run_tests('verbose',false);
%
%   % explicitly set verbose output and store output in file
%   cosmo_run_tests('verbose',true,'output','~/mylogfile.txt');
%
% Notes:
%   - Running the documentation tests requires the xUnit framework by
%     S. Eddings (2009), http://www.mathworks.it/matlabcentral/
%                         fileexchange/22846-matlab-xunit-test-framework
%   - Doctest functionality was inspired by T. Smith.
%   - Unit tests can be run using MOxUnit by N.N. Oosterhof (2015),
%           https://github.com/MOxUnit/MOxUnit
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    orig_pwd=pwd();
    pwd_resetter=onCleanup(@()cd(orig_pwd));

    [opt,args]=get_opt(varargin{:});

    run_doctest=~opt.no_doctest;
    run_unittest=~opt.no_unittest;

    has_logfile=~isempty(opt.logfile);

    if has_logfile && run_doctest && run_unittest
        error('Cannot have logfile with both doctest and unittest');
    end

    runners={@run_doctest_helper,@run_unittest_helper};

    orig_path=path();
    path_resetter=onCleanup(@()path(orig_path));

    did_pass=all(cellfun(@(runner) runner(opt,args),runners));


function did_pass=run_doctest_helper(opt,unused)
    did_pass=true;

    location=opt.doctest_location;
    if ~ischar(location)
        return;
    elseif isempty(location)
        location=get_default_dir('doc');
    end

    if cosmo_wtf('is_octave')
        cosmo_warning('Doctest not (yet) available for GNU Octave, skip');
        return
    end

    % xUnit is required
    cosmo_check_external('xunit');

    % run test using custom CosmoDocTestSuite
    cd(opt.run_from_dir);
    suite=CosmoDocTestSuite(location);
    if opt.verbose
        monitor_constructor=@VerboseTestRunDisplay;
    else
        monitor_constructor=@TestRunDisplay;
    end

    has_logfile=ischar(opt.logfile);
    if has_logfile
        fid=fopen(opt.logfile,'w');
        file_closer=onCleanup(@()fclose(fid));
    else
        fid=1;
    end

    monitor=monitor_constructor(fid);
    did_pass=suite.run(monitor);


function did_pass=run_unittest_helper(opt,args)
    did_pass=true;

    location=opt.unittest_location;
    if ~ischar(location)
        return;
    elseif isempty(location)
        location=get_default_dir('unit');
        args{end+1}=location;
    end


    unittest_dir=get_directory(location);
    addpath(unittest_dir);

    test_runner=get_test_field('runner');
    did_pass=test_runner(args{:});

function directory=get_directory(location)
    if isdir(location)
        directory=location;
    elseif exist(location,'file')
        directory=fileparts(location);
    else
        error('illegal location %s',location);
    end

function s=get_all_test_runners_struct()
    s=struct();
    s.moxunit.runner=@moxunit_runtests;
    s.moxunit.arg_with_value={'-cover',...
                              '-cover_xml_file',...
                              '-cover_html_dir',...
                              '-cover_json_file',...
                              '-with_coverage',...
                              '-junit_xml_file',...
                              '-cover_method'};

    s.xunit.runner=@runtests;
    s.xunit.arg_with_value={};

function key=get_test_runner_name()
    runners_struct=get_all_test_runners_struct();
    keys=fieldnames(runners_struct);

    present_ids=find(cosmo_check_external(keys,false));

    if isempty(present_ids)
        raise_exception=true;
        cosmo_check_external(keys, raise_exception);
    end

    key=keys{present_ids};


function value=get_test_field(sub_key)
    key=get_test_runner_name();
    s=get_all_test_runners_struct();
    value=s.(key).(sub_key);


function d=get_default_dir(name)
    switch name
        case 'root'
            d=fileparts(fileparts(mfilename('fullpath')));

        case 'unit'
            d=fullfile(get_default_dir('root'),'tests');

        case 'doc'
            d=fullfile(get_default_dir('root'),'mvpa');
    end


function [opt,passthrough_args]=get_opt(varargin)
    defaults=struct();
    defaults.verbose=false;
    defaults.no_doctest=false;
    defaults.no_unittest=false;
    defaults.logfile=[];
    defaults.unittest_location='';
    defaults.doctest_location='';

    n_args=numel(varargin);
    passthrough_args=varargin;
    keep_in_passthrough=true(1,n_args);
    k=0;

    arg_with_value=get_test_field('arg_with_value');
    opt=defaults;
    opt.run_from_dir=get_default_dir('unit');

    while k<n_args
        k=k+1;
        arg=varargin{k};

        switch arg
            case '-verbose'
                opt.verbose=true;

            case '-no_doctest'
                opt.no_doctest=true;
                keep_in_passthrough(k)=false;

            case '-no_unittest'
                opt.no_unittest=true;
                keep_in_passthrough(k)=false;

            case '-logfile'
                [opt.logfile,k]=next_arg(varargin,k);

            otherwise
                is_option=~isempty(regexp(arg,'^-','once'));

                if is_option
                    arg_has_value=~isempty(strmatch(arg,arg_with_value));
                    if arg_has_value
                        k=k+1;
                    end
                else
                    test_location=get_location(arg);
                    passthrough_args{k}=test_location;

                    opt.unittest_location=test_location;
                    opt.doctest_location=test_location;
                end
        end
    end

    passthrough_args=passthrough_args(keep_in_passthrough);
    if opt.no_unittest
        opt.unittest_location=[];
    end

    if opt.no_doctest
        opt.doctest_location=[];
    end

function full_path=get_location(location)
    if exist(location,'file')
        p=fileparts(location);
        if isempty(p)
            full_path=fullfile(pwd(),location);
        else
            full_path=location;
        end
        return
    end

    parent_dirs={'',get_default_dir('unit'),get_default_dir('doc')};
    n=numel(parent_dirs);
    for use_which=[false,true]
        for k=1:n
            full_path=fullfile(parent_dirs{k},location);

            if isdir(full_path) || ~isempty(dir(full_path))
                return;
            end

            if use_which && isdir(parent_dirs{k})
                orig_pwd=pwd();
                cleaner=onCleanup(@()cd(orig_pwd));
                cd(parent_dirs{k});
                full_path=which(location);
                if ~isempty(full_path)
                    return;
                end
                clear cleaner;
            end
        end
    end


    error('Unable to find ''%s''',location);


function [value,next_k]=next_arg(args,k)
    n=numel(args);
    next_k=k+1;
    if next_k>n
        error('missing argument after ''%s''',args{k});
    end
    value=args{next_k};
