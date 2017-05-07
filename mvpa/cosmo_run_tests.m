function did_pass=cosmo_run_tests(varargin)
% run unit and documentation tests
%
% did_pass=cosmo_run_tests(['verbose',v]['output',fn])
%
% Inputs:
%   '-verbose'        run with verbose output
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
%   - Doctest functionality was inspired by T. Smith.
%   - Unit tests can be run using MOxUnit by N.N. Oosterhof (2015-2017),
%           https://github.com/MOxUnit/MOxUnit
%   - Documentation tests can be run usxing MOdox by N.N. Oosterhof (2017),
%           https://github.com/MOdox/MOdox
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    orig_pwd=pwd();
    pwd_resetter=onCleanup(@()cd(orig_pwd));

    [opt,test_locations,moxunit_args]=get_opt(varargin{:});

    run_doctest=~opt.no_doctest;
    run_unittest=~opt.no_unittest;

    orig_path=path();
    path_resetter=onCleanup(@()path(orig_path));

    suite=MOxUnitTestSuite();

    if run_doctest
        doctest_suite=get_doctest_suite(test_locations);
        suite=addFromSuite(suite,doctest_suite);
    end

    if run_unittest
        unittest_suite=get_unittest_suite(test_locations);
        suite=addFromSuite(suite,unittest_suite);
    end

    did_pass=moxunit_runtests(suite,moxunit_args{:});


function suite=get_doctest_suite(test_locations)
    cosmo_check_external({'moxunit','modox'});
    suite=MOdoxTestSuite();
    suite=add_test_locations(suite,'doc',test_locations);



function suite=get_unittest_suite(test_locations)
    cosmo_check_external({'moxunit'});
    suite=MOxUnitTestSuite();
    suite=add_test_locations(suite,'unit',test_locations);



function suite=add_test_locations(suite,type,test_locations)
    if isempty(test_locations)
        test_locations={get_default_dir(type)};
    end

    pat='^.*\.m$';
    for k=1:numel(test_locations)

        location=test_locations{k};

        if isdir(location)
            suite=addFromDirectory(suite,location,pat);
        else
            suite=addFromFile(suite,location);
        end
    end


function d=get_default_dir(name)
    switch name
        case 'root'
            d=fileparts(fileparts(mfilename('fullpath')));

        case 'unit'
            d=fullfile(get_default_dir('root'),'tests');

        case 'doc'
            d=fullfile(get_default_dir('root'),'mvpa');
    end


function [opt,test_locations,moxunit_args]=get_opt(varargin)
    defaults=struct();
    defaults.no_doctest=false;
    defaults.no_unittest=false;
    opt=defaults;

    n_args=numel(varargin);


    is_key_value_arg={'-cover',...
                      '-cover_xml_file',...
                      '-cover_html_dir',...
                      '-cover_json_file',...
                      '-with_coverage',...
                      '-junit_xml_file',...
                      '-cover_method',...
                      '-partition_index',...
                      '-partition_count',...
                      '-logfile'};

    test_locations=cell(n_args,1);
    moxunit_args=cell(n_args,1);

    k=0;
    while k<n_args
        k=k+1;
        arg=varargin{k};

        switch arg
            case '-no_doctest'
                opt.no_doctest=true;

            case '-no_unittest'
                opt.no_unittest=true;

            otherwise
                is_option=~isempty(regexp(arg,'^-','once'));

                if is_option
                    moxunit_args{k}=arg;

                    has_value=~isempty(strmatch(arg,is_key_value_arg));
                    if has_value
                        if k==n_args
                            error('Missing value after key ''%s''',arg);
                        end
                        k=k+1;
                        arg=varargin{k};
                        moxunit_args{k}=arg;
                    end
                else
                    test_location=get_location(arg);
                    test_locations{k}=test_location;
                end
        end
    end

    moxunit_args=remove_empty_from_cell(moxunit_args);
    test_locations=remove_empty_from_cell(test_locations);


function ys=remove_empty_from_cell(xs)
    keep=~cellfun(@isempty,xs);
    ys=xs(keep);

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
