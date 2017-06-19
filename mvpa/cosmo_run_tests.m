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
%   '-no_doc_test'    skip doctest
%   '-no_unit)test'   skip unittest
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

    run_doctest=~opt.no_doc_test;
    run_unittest=~opt.no_unit_test;

    orig_path=path();
    path_resetter=onCleanup(@()path(orig_path));

    suite=MOxUnitTestSuite();

    if run_doctest
        doctest_suite=get_doctest_suite(test_locations);
        suite=addFromSuite(suite,doctest_suite);
        fprintf('doc test %s\n',str(doctest_suite));
    end

    if run_unittest
        unittest_suite=get_unittest_suite(test_locations);
        suite=addFromSuite(suite,unittest_suite);
        fprintf('unit test %s\n',str(unittest_suite));
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
        prefix=get_default_prefix(type);
    else
        prefix='';
    end

    pat=['^' prefix '.*\.m$'];
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

        otherwise
            assert(false);
    end

function prefix=get_default_prefix(name)
    s=struct();
    s.unit='test_';
    s.doc='cosmo_';
    prefix=s.(name);


function [opt,test_locations,moxunit_args]=get_opt(varargin)
    defaults=struct();
    defaults.no_doc_test=false;
    defaults.no_unit_test=false;
    opt=defaults;

    n_args=numel(varargin);


    is_key_value_arg={'-cover',...
                      '-cover_xml_file',...
                      '-cover_html_dir',...
                      '-cover_json_file',...
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
            case '-no_doc_test'
                opt.no_doc_test=true;

            case '-no_unit_test'
                opt.no_unit_test=true;

            otherwise
                is_option=~isempty(regexp(arg,'^-','once'));

                if is_option
                    moxunit_args{k}=arg;

                    has_value=~isempty(strmatch(arg,is_key_value_arg,'exact'));
                    if has_value
                        if k==n_args
                            error('Missing value after key ''%s''',arg);
                        end
                        k=k+1;
                        arg=varargin{k};
                        moxunit_args{k}=arg;
                    end
                else
                    test_locations{k}=get_location(arg);
                end
        end
    end

    moxunit_args=remove_empty_from_cell(moxunit_args);
    test_locations=remove_empty_from_cell(test_locations);


function ys=remove_empty_from_cell(xs)
    keep=~cellfun(@isempty,xs);
    ys=xs(keep);

function full_path=get_location(location)
    candidate_dirs={'',...
                    get_default_dir('unit'),...
                    get_default_dir('doc')};

    suffixes={'','.m'};

    n_dirs=numel(candidate_dirs);
    n_suffixes=numel(suffixes);
    for k=1:n_dirs
        for j=1:1:n_suffixes
            fn=sprintf('%s%s',location,suffixes{j});
            full_path=fullfile(candidate_dirs{k},fn);

            if exist(location,'file')
                return;
            end
        end
    end

    error('Unable to find ''%s''',location);
