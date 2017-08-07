classdef CosmoDocTestSuite < TestSuite
% CoSMoMVPA doctest suite
%
% Provides doctest functionality using the help information associated
% with an .m file. It also supports directories with such files; it
% collects the doc tests in such directories recursively.
%
% A doctest is specified in the comment header section of an .m file; it is
% based on the text that is shown by the command 'help foo' if the function
% is defined in a file 'foo.m'.
%
% Example:
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
%
% Notes:
%   - Typically test cases are generated using CosmoDocTestSuite, or run
%     using cosmo_run_tests
%   - This class extends the xUnit framework by S. Eddings (2009),
%     BSD License, http://www.mathworks.it/matlabcentral/fileexchange/
%                         22846-matlab-xunit-test-framework
%   - Doctest functionality was inspired by T. Smith.
%
% See also: CosmoDocTestCase, cosmo_run_tests
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    methods
        function self = CosmoDocTestSuite(name)
            % constructs an empty suite when no arguments are give;
            % otherwise name is used to construct tests

            if nargin >= 1
                self = CosmoDocTestSuite.fromName(name);
            end
        end
    end

    methods (Static)
        function suite = fromName(name)
            % collects tests from an .m file with doctests, from a
            % cell with .m files, or from a directory with such files
            % (recursively)
            if ischar(name) && isdir(name)
                suite=CosmoDocTestSuite.fromDir(name);
                return;
            end

            suite = CosmoDocTestSuite();
            suite.Name = name;
            suite.Location = name;

            if iscell(name)
                % typically the output from from{Dir,Pwd}; add
                % the tests from each component
                for k=1:numel(name)
                    suite_k=CosmoDocTestSuite.fromName(name{k});
                    components=suite_k.TestComponents;
                    for j=1:numel(components)
                        suite.add(components{j});
                    end
                end
                return;
            end

            try
                % process filename of '.m' file (possibly with doctest)
                suite = get_tests_from_help(name);
            catch me
                disp(getReport(me))
            end
        end

        function test_suite = fromPwd()
            % collects tests from the current directory (recursively)
            test_suite = CosmoDocTestSuite.fromDir(pwd());
        end

        function test_suite=fromDir(dir_)
            % collects tests from the directory 'dir_ ' (recursively)
            filenames_struct=cosmo_dir(dir_,'*.m');
            filenames_cell={filenames_struct.name};
            test_suite=CosmoDocTestSuite.fromName(filenames_cell);
            test_suite.Name=dir_;
            test_suite.Location=dir_;
        end
    end
end

function suite=get_tests_from_help(filename)
    % helper function to return test suite from an .m file named 'filename'

    % define helper function to show error location
    error_=@(msg,line) error([CosmoDocTestCase.linkto(...
                                        filename,line) ' : ' msg]);

    % initialize empty test suite
    suite=CosmoDocTestSuite();
    suite.Name=filename;

    % if not in path skip the test
    w=which(filename);
    if isempty(w)
        return;
    end

    % constants for state of every line in the help output
    state_pre=0;           % before any doctest
    state_whitespace=1;    % line with only whitespaces
    state_comment=2;       % line that has only a comment
    state_preamb=3;        % expression with expression on the next line
    state_expr=4;          % expression with no expression on the next line
    state_want=5;          % expected output after 'state_want' line
    state_post=9;          % after all doctests

    % prefixes indicating 'want' and 'comment' states
    prefix_want='>';
    prefix_comment='%';

    % examples start with a line which may start and end with white space,
    % and otherwise just contains 'example' with the first 'e' in either
    % upper or lower case, either in singular or plurar,
    % and optionally with a colon at the end
    start_re='^\s*[eE]xamples?:?\s*$';

    % initialize variables to go over doctests
    suite.Location=w;
    help_str=help(filename);
    help_lines=cosmo_strsplit(help_str,'\n');

    n=numel(help_lines);
    line_states=zeros(n,1);

    % initialize to empty; once this is eet, doctests end when an indent
    % less than first_indent is encountered ('offside')
    first_indent=[];

    state=state_pre;
    for line_number=1:numel(help_lines)
        line=help_lines{line_number};

        % remove whitespace
        line_trim=strtrim(line);

        if ~isempty(regexp(line,start_re,'once'))
            % start of 'Examples:' section
            if state>0
                error_('repeat of ''Examples'' header ',line_number);
            end
            state=state_comment;
        elseif any(state==[state_pre, state_post])
            % pre or post (no doctest); do nothing
        elseif isempty(line_trim)
            % empty line
            state=state_whitespace;
        else
            % non-whitespace line
            indent=regexp(line,'(\S)+.*$','start');

            % sanity check
            assert(~isempty(indent));

            % first line after 'Examples:'; store indent level
            if isempty(first_indent)
                first_indent=indent;
            end

            if indent<first_indent
                % offside; done with doctest section
                state=state_post;
            elseif line_trim(1)==prefix_want
                % in 'want' section
                state=state_want;
            elseif line_trim(1)==prefix_comment
                % comment section
                state=state_comment;
            else
                % expression section
                state=state_expr;
            end
        end
        line_states(line_number)=state;
    end

    % every 'expr' line followed by another 'expr' line is preamble
    expr_msk=line_states==state_expr & [line_states(2:end);0]==state_want;
    line_states(line_states==state_expr & ~expr_msk)=state_preamb;

    % store line numbers
    rng=1:numel(help_lines);

    % divide all lines into blocks (separated by white space)
    states_block=[state_expr,state_comment,state_preamb,state_want];
    block_msk=cosmo_match(line_states,states_block);
    block_start=find(block_msk & ~[false; block_msk(1:(end-1))]);
    block_end=find(rng'>1 & block_msk & ~[block_msk(2:end);false])-1;

    % sanity check
    nblocks=numel(block_start);
    if nblocks~=numel(block_end)
        error_('Unfinished block', block_end(end));
    end

    for k=1:nblocks
        block_msk=block_start(k)<=rng & rng<=block_end(k);

        % find expressions to test for
        expr_idxs=find(expr_msk' & block_msk);
        nexprs=numel(expr_idxs);
        expr=cell(nexprs,1);
        wants=cell(nexprs,1);

        for j=1:nexprs
            expr_idx=expr_idxs(j);

            % preamble contains all non-'expr' lines preceding the 'expr'
            preamb_msk=block_msk' & line_states==state_preamb & ...
                                                    rng'<=expr_idx;
            preamb=help_lines(preamb_msk);

            % 'want'-part has all lines following 'expr' until a non-'want'
            % line is encountered
            want_idx=expr_idx+1;
            while line_states(want_idx)==state_want
                want_idx=want_idx+1;
            end
            wants_with_prefix=help_lines((expr_idx+1):(want_idx-1));

            if numel(wants_with_prefix)==0
                % no want lines, do not add test
                continue;
            end

            % 'expr' line is after 'preamb' and before 'wants'
            % (expr_lines should have one element, for now, so
            % using strjoin is a not really necessary)
            expr_lines=help_lines(expr_idx);
            expr=cosmo_strjoin(expr_lines,'\n');

            % remove the 'want' prefix ('>')
            re=['^\s*' prefix_want '(?<f>.*)$'];
            wants_lines=regexprep(wants_with_prefix,re,'$1');
            wants=cosmo_strjoin(wants_lines,'\n');

            % store line number of expression
            line_number=expr_idx;

            % add doctest
            doctest=CosmoDocTestCase(preamb,expr,wants,...
                                            filename,line_number);
            suite.add(doctest);
        end
    end
end
