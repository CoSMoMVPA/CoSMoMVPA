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
    test_subdir=fullfile('..','tests');

    doctest_dir=fileparts(which(mvpa_func));
    unittest_dir=fullfile(doctest_dir,test_subdir);

    has_filename=~isempty(opt.filename);
    if has_filename
        unittest_location=opt.filename;
        doctest_location=opt.filename;

        filename_dir=which(opt.filename);
        is_in_dir=@(parent, fn) ~isempty(strmatch(parent,fileparts(fn)));
        has_unittest=is_in_dir(unittest_dir,filename_dir);
        has_doctest=is_in_dir(doctest_dir,filename_dir);
    else
        unittest_location=unittest_dir;
        doctest_location=doctest_dir;

        has_unittest=true;
        has_doctest=true;
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

    unit_test_count=NaN;
    doc_test_count=NaN;

    switch test_suite_name
        case 'xunit'
            % start with empty test suite
            suite=TestSuite();

            % collect unit tests
            if has_unittest
                unittest_suite=TestSuite.fromName(unittest_location);
                suite.add(unittest_suite);
                unit_test_count=unittest_suite.numTestCases;
            end

            if has_doctest
                doctest_suite=CosmoDocTestSuite(doctest_location);
                suite.add(doctest_suite);
                doc_test_count=doctest_suite.numTestCases;
            end

            monitor_constructors={@TestRunDisplay,@VerboseTestRunDisplay};
            monitor_constructor=monitor_constructors{verbosity};

            % xUnit does not report which tests were skipped
            do_report_test_result=true;

        case 'moxunit'
            suite=MOxUnitTestSuite();
            if isdir(unittest_location)
                suite=addFromDirectory(suite,unittest_location);
            else
                suite=addFromFile(suite,unittest_location);
            end

            unit_test_count=countTestCases(suite);

            monitor_constructor=@(fid)MOxUnitTestResult(verbosity,fid);

            % MOxUnit reports which tests were skipped
            do_report_test_result=false;
    end

    show_test_count(fid, 'unit',unit_test_count);
    show_test_count(fid, 'doc',doc_test_count);

    monitor = monitor_constructor(fid);

    % run the tests
    switch test_suite_name
        case 'xunit'
            did_pass=suite.run(monitor);

        case 'moxunit'
            test_result=run(suite, monitor);
            disp(test_result);

            did_pass=wasSuccessful(test_result);
    end

    if do_report_test_result
        report_test_result(fid, did_pass);
    end


function show_test_count(fid, label, count)
    if isnan(count)
        postfix='no tests (not supported on this platform)';
    else
        postfix=sprintf('%d tests', count);
    end
    fprintf(fid,'%s test suite: %s\n', label, postfix);


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
        external='moxunit';
    else
        external_candidates={'xunit','moxunit'};
        has_external=cosmo_check_external(external_candidates,false);
        if ~any(has_external)
            cosmo_check_external(external_candidates,true);
        end
        i=find(has_external,1,'first');
        external=external_candidates{i};
    end

function opt=get_opt(defaults,varargin)
    if ~isempty(varargin) && numel(varargin)==1 && ischar(varargin{1})
        opt=defaults;
        opt.filename=varargin{1};
    else
        opt=cosmo_structjoin(defaults,varargin{:});
    end
