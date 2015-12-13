function did_pass=cosmo_run_tests(varargin)
% run unit and documentation tests
%
% did_pass=cosmo_run_tests(['verbose',v]['output',fn])
%
% Inputs:
%   'verbose',v     run doctest with verbose output (optional,
%                   default=true)
%   'output',fn     store output in a file named fn (optional, if omitted
%                   output is written to the terminal window
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
%   - This class requires the xUnit framework by S. Eddings (2009),
%     BSD License, http://www.mathworks.it/matlabcentral/fileexchange/
%                         22846-matlab-xunit-test-framework
%   - Doctest functionality was inspired by T. Smith.
%   - Documentation test classes are in CoSMoMVPA's tests/ directory;
%     CosmoDocTest{Case,Suite} extend the xUnit classes Test{Case,Suite}.
%   - Documentation tests can be added in the help section of functions in
%     CoSMoMVPA's mvpa/ directory. A doctest is specified in the comment
%     header section of an .m file; it is based on the text that is
%     showed by the command 'help the_function'
%
% %     (this example pretends to be the help of a function definition)
% %
% %     (other documentation here ...)
% %
% %     Example:                     % legend: line  block  type  test-type
% %         % this is a comment               %  1      1     C     C
% %         negative_four=-4;                 %  2      1     E     P 1.1
% %         sixteen=negative_four^2;          %  3      1     E     P 1.2
% %         abs([negative_four; sixteen])     %  4      1     E     E 1.1
% %         > 4                               %  5      1     W     W 1.1.1
% %         > 16                              %  6      1     W     W 1.1.2
% %         %                                 %  7      1     C     C
% %         nine=3*3;                         %  8      1     E     P 1.3
% %         abs(negative_four-nine)           %  9      1     E     E 1.2
% %         > 13                              % 10      1     W     W 1.2.1
% %                                           % 11            S     S
% %         unused=3;                         % 12      2     E     E 2.1
% %                                           % 13            S     S
% %         postfix=' is useful'              % 14      3     E     P 3.1
% %         disp({@abs postfix})              % 15      3     E     E 3.1
% %         >   @abs    ' is useful '         % 16      3     W     W 3.1.1
% %
% %     (more documentation here ['offside position'; see (3) below] ...)
%
%     The right-hand side shows (for clarification) four columns with line
%     number, block number, type and test-type. Doctests are processed as
%     follows:
%     1) A doctest section starts with a line containing just 'Example'
%        (or 'Examples:', 'example' or other variants; to be exact,
%        the regular expression to be matched is '^\s*[eE]xamples?:?\s*$').
%     2) The indent level is the number of spaces after the first non-empty
%        line after the Example line.
%     3) A doctest section ends whenever a line is found with a lower
%        indent level ('offside rule').
%     4) Only a single doctest section is supported. If multiple doctest
%        sections are found an error is raised.
%     5) Doctests are split in blocks by empty lines. (A line containing
%        only spaces is considered empty; a line with comment is considered
%        non-empty.)
%     6) In a first pass over all doctest lines, each line is assigned a
%        type:
%        + (E)xpression (string that can be evaluated by matlab)
%        + (W)ant       (expected output from evaluating an expression)
%        + (C)omment    (not an 'E' or 'W' line; contains '%' character)
%        + (S)pace      (white-space, i.e. not 'E', 'W' or 'C' line)
%     7) In a second pass, 'E' lines followed by another 'E' line are
%        set to the (P)reamble state (see test-type column, above).
%        Preamble lines can assign values to variables, but should not
%        produce output.
%        Non-preamble expression lines followed by one or more W-lines
%        should produce the output indicated by these W-lines.
%     8) A single doctest is run as follows:
%        - each block is processed separately
%        - for each line with test-type E (in each block):
%          + if it is not followed by one or more W-lines, then the
%            expression is ignored.
%          + otherwise:
%            * run all preceding preamble lines in the block
%              # if this produces non-empty output or an error, the test
%                fails.
%            * run the line with test-type E
%              # if this produces an error, the test fails
%            * compare the output of the previous step with the W-lines
%              # comparison of equality is somewhat 'lenient':
%                + equality is based on the output without the ' ans = '
%                  prefix string that matlab gives when showing output
%                + both the output of the W-lines and the evaluated output
%                  is compared after splitting the string by white-space
%                  characters. For example, if the real output is 'foo bar'
%                  and the expected output is '   foo   bar ', the test
%                  passes
%                + if the previous string comparison does not pass the
%                  test, an attempt is made to convert both the output of
%                  the W-lines and the evaluated output to a numeric array.
%                  If this conversion is succesfull and both arrays are
%                  equal, the test passes.
%                + if the conversion to numeric does not make the test
%                  pass, the W-lines are evaluated (and any ' ans = '
%                  prefix is removed). If this evaluation is succesfull
%                  (does not raise an exception) in is equal to the
%                  evaluated output, the test passes.
%              # if none of the above attempts make the test pass, the test
%                fails.
%            * if no test has failed, the test passes
%        - To illustrate, in the example above:
%          + E-1.1 is executed after P-1.1 and P-1.2; evaluating P-1.[1-2]
%            should not give output. The output of evaluating E-1.1
%            should be W-1.1.1 and W-1.1.2
%          + E-1.2 is executed after P-1.1, P-1.2, and P-1.3; evaluating
%            P-1.[1-3] should not give output. The output of evaluating
%            E-1.2 should be W-1.2.1.
%          + E-2.1 is ignored, because there is no corresponding W-2.1.*
%          + E-3.1 is executed after P-3.1; evaluating P-3.1 should
%            not give ouput. The output of evaluating E-1.3 should be
%            W-3.1.1.
%     9) The suite passes if all tests pass
%
% NNO Jul 2014
    test_suite_name=find_external();

    defaults=struct();
    defaults.verbose=true;
    defaults.output=1;     % standard out
    defaults.filename=[];

    opt=get_opt(defaults,varargin{:});

    % store original directory
    orig_pwd=pwd();

    % set paths for unit tests and doc tests
    mvpa_func='cosmo_fmri_dataset';

    doctest_dir=fileparts(which(mvpa_func));
    unittest_dir=fullfile(fileparts(doctest_dir),'tests');

    has_filename=~isempty(opt.filename);
    if has_filename
        % test a single file
        unittest_location=opt.filename;
        doctest_location=opt.filename;

    else
        % test a set of files in directories
        unittest_location=unittest_dir;
        doctest_location=doctest_dir;
    end

    % if opt.output is numeric it's assumed to be a file descriptor;
    % output is written to the corresponding file but the file is not
    % closed afterwards
    do_open_output_file=~isnumeric(opt.output);

    if do_open_output_file
        fid=fopen(opt.output,'w');
        file_closer=onCleanup(@()fclose(fid));
    else
        fid=opt.output;
    end

    path_resetter=onCleanup(@()cd(orig_pwd));

    % avoid setting the path for CosmoDocTest{Case,Suite} classes;
    % instead, cd to the tests directory and run the tests from there.
    cd(unittest_dir);

    % reset set of skipped tests
    cosmo_notify_test_skipped('on');

    verbosity=opt.verbose+1;

    unit_suite=get_suite(unittest_location,...
                            unittest_dir,'unit');
    doc_suite=get_suite(doctest_location,...
                            doctest_dir,'doc');

    did_pass=run_suites(fid,verbosity,{unit_suite,doc_suite});

function did_all_pass=run_suites(fid, verbosity, all_suites)
    keep_msk=~cellfun(@isempty,all_suites);
    suites=all_suites(keep_msk);

    show_test_count(suites,fid);

    suites=merge_suites(suites);
    n_suites=numel(suites);

    did_all_pass=true;
    reporters=cell(n_suites,1);
    for k=1:n_suites
        suite_k=suites{k};
        monitor_constructor=get_test_monitor_constructor(suite_k, ...
                                                        verbosity);
        [did_pass,reporters{k}]=run_single_suite(suite_k,...
                                                monitor_constructor,fid);
        did_all_pass=did_all_pass & did_pass;
    end

    for k=1:n_suites
        reporters{k}();
    end

function [did_pass,reporter]=run_single_suite(suite, ...
                                monitor_constructor, fid)
    monitor = monitor_constructor(fid);

    switch get_suite_class(suite)
        case 'TestSuite'
            did_pass=suite.run(monitor);
            reporter=@()report_test_result(fid, did_pass);

        case 'MOxUnitTestSuite'
            test_result=run(suite, monitor);
            reporter=@()disp(test_result);

            did_pass=wasSuccessful(test_result);
    end

function show_test_count(suite,fid)
    if iscell(suite)
        cellfun(@(s)show_test_count(s,fid),suite);
        return;
    end

    count=suite_count(suite);
    postfix=sprintf('%d tests', count);
    fprintf(fid,'%s test suite: %s\n', class(suite), postfix);


function merged=merge_suites(suites)
    if numel(suites)==0
        error('No suites found');
    end

    suite_classes=get_suite_class(suites);
    if numel(suites)>0 && ...
            all(strcmp(suite_classes{1},suite_classes(2:end)))
        one_suite=suites{1};
        one_class=suite_classes{1};

        for k=2:numel(suites)
            suite_k=suites{k};
            switch one_class
                case 'TestSuite'
                    one_suite.add(suite_k);

                case 'MOxUnitTestSuite'
                    one_suite=addFromSuite(one_suite,suite_k);
            end
        end

        merged={one_suite};

        return;
    end

    merged=suites;


function suite=get_suite(location,parent_dir,type)
    suite=get_empty_suite(type);
    if ~isempty(suite)
        suite=suite_add_from_location(suite,location,parent_dir,type);
    end


function suite=get_empty_suite(type)

    switch get_suite_runner_name(type)
        case 'moxunit'
            suite=MOxUnitTestSuite();

        case 'xunit'
            suite=TestSuite();

        case ''
            suite=[];
    end

function monitor_constructor=get_test_monitor_constructor(suite, verbosity)
    switch get_suite_class(suite)
        case 'MOxUnitTestSuite'
            monitor_constructor=@(fid)MOxUnitTestReport(verbosity,fid);

        case 'TestSuite'
            monitor_constructors={@TestRunDisplay,@VerboseTestRunDisplay};
            monitor_constructor=monitor_constructors{verbosity};
    end

function tf=skip_location(location,parent_dir)
    tf=true;
    if isdir(location)
        location_dir=location;
    else
        location_dir=fileparts(location);
    end

    if strcmp(location_dir,parent_dir)
        tf=false;
        return;
    end

    which_location=which(location);
    if ~isempty(which_location);
        location_dir=fileparts(which_location);
        tf=~strcmp(location_dir,parent_dir);
    end

function suite_class=get_suite_class(suite)
    if iscell(suite)
        suite_class=cellfun(@get_suite_class,suite,...
                                'UniformOutput',false);
        return;
    end

    super_classes={'TestSuite','MOxUnitTestSuite'};
    for k=1:numel(super_classes)
        super_class=super_classes{k};
        if isa(suite,super_class)
            suite_class=super_class;
        end
    end


function suite=suite_add_from_location(suite,location,parent_dir,type)
    if skip_location(location,parent_dir)
        return;
    end

    switch get_suite_class(suite)
        case 'MOxUnitTestSuite'
            if isdir(location)
                suite=addFromDirectory(suite,location);
            else
                suite=addFromFile(suite,location);
            end

        case 'TestSuite'
            location=regexprep(location,'\.m$','');

            switch type
                case 'doc'
                    suite_to_add=CosmoDocTestSuite(location);

                case 'unit'
                    suite_to_add=TestSuite.fromName(location);

            end

            suite.add(suite_to_add);

        otherwise
            assert(false);
    end

function count=suite_count(suite)
    switch get_suite_class(suite)
        case 'MOxUnitTestSuite'
            count=countTestCases(suite);


        case 'TestSuite'
            count=suite.numTestCases;
    end

function runner_name=get_suite_runner_name(type)
    % helper function to get unit and doc test runner name
    % result is 'moxunit' or 'xunit', or '' if not runner was found
    has_moxunit=cosmo_check_external('moxunit',false);
    has_xunit=cosmo_check_external('xunit',false);

    if ~(has_moxunit || has_xunit)
        if cosmo_wtf('is_matlab')
            % on Matlab, suggest to use xunit because it provides doctest
            % functionality
            cosmo_check_external('xunit');
        else
            % on Octave, suggest to use moxunit because doctest
            % functionality cannot be provided anyways
            cosmo_check_external('moxunit');
        end
    end

    which_dir=@(x)fileparts(which(x));
    which_dir_init=which_dir('initTestSuite');
    assert(~isempty(which_dir_init));

    init_moxunit=isequal(which_dir_init,which_dir('moxunit_runtests'));
    init_xunit=isequal(which_dir_init,which_dir('runtests'));

    if init_moxunit
        assert(~init_xunit);
        if strcmp(type,'doc')
            if has_xunit
                runner_name='xunit';
            else
                runner_name='';
            end
        else
            runner_name='moxunit';
        end
    else
        assert(~init_moxunit);
        runner_name='xunit';
    end





function report_test_result(fid, did_pass)
    if did_pass
        prefix='OK';
    else
        prefix='FAILED';
    end

    skipped_descs=cosmo_notify_test_skipped();
    nskip=numel(skipped_descs);

    if nskip>0
        for k=1:nskip
            fprintf(fid,'[skip] %s\n\n', skipped_descs{k});
        end
    end

    postfix=sprintf(' (skips=%d)', nskip);

    fprintf(fid,'%s%s\n',prefix,postfix);


function external=find_external()
    if cosmo_wtf('is_octave')
        % xunit is not supported
        external='moxunit';
    else
        external_candidates={'xunit','moxunit'};
        has_external=cosmo_check_external(external_candidates,false);
        if ~any(has_external)
            % raise an error
            cosmo_check_external(external_candidates,true);
        end

        % prefer xunit, because through CoSMoMVPA integration it
        % supports unit tests
        i=find(has_external,1,'first');
        external=external_candidates{i};
    end

function opt=get_opt(defaults,varargin)
    if ~isempty(varargin) && numel(varargin)==1 && ischar(varargin{1})
        % test a single file
        opt=defaults;
        opt.filename=varargin{1};
    else
        % use all defaults
        opt=cosmo_structjoin(defaults,varargin{:});
    end
