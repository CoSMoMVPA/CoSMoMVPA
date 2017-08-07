classdef CosmoDocTestCase < TestCase
% CoSMoMVPA doctest
%
% A doctests consists of:
%  preamb:   zero or more lines with expressions
%  expr:     a single expression
%  wants:    one or more lines of output that should be produced by
%            evaluating 'expr' after evaluating the expressions in
%            'preamb'
%  filename: name of the file in which the doctest was found
%  line_number: position in file where the doctest was found
%
% Notes:
%   - Typically test cases are generated using CosmoDocTestSuite, or run
%     using cosmo_run_tests
%   - This class extends the xUnit framework by S. Eddings (2009),
%     BSD License, http://www.mathworks.it/matlabcentral/fileexchange/
%                         22846-matlab-xunit-test-framework
%   - Doctest functionality was inspired by T. Smith.
%
% See also: CosmoDocTestSuite, cosmo_run_tests
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    properties (SetAccess = protected, GetAccess = protected, Hidden = true)
        %
        preamb;
        expr;
        wants;
        filename;
        line_number;
    end

    methods
        function self = CosmoDocTestCase(preamb, expr, wants, ...
                                                filename, line_number)
            % constructor
            self = self@TestCase('runTestCase');

            self.preamb=preamb;
            self.expr=expr;
            self.wants=wants;
            self.filename=filename;
            self.line_number=line_number;

            [unused, name] = fileparts(filename);
            prefix='Doctest: ';
            linkto=@CosmoDocTestCase.linkto;
            self.Name=linkto(filename,line_number,[prefix name]);
            self.MethodName=linkto(filename, line_number, name);
            self.Location = linkto(filename, line_number);

        end

        function did_pass = run(self, monitor)
            % run the unit test
            if nargin < 2
                monitor = CommandWindowTestRunDisplay();
            end

            did_pass = true;
            monitor.testComponentStarted(self);

            try
                % delegate the real work to the helper function below
                run_doctest(self.preamb, self.expr, self.wants, ...
                                    self.filename, self.line_number)
            catch failureException
                monitor.testCaseFailure(self, failureException);
                did_pass = false;
            end

            monitor.testComponentFinished(self, did_pass);
        end

        function num = numTestCases(self)
            num = 1;
        end

        function print(self, numLeadingBlanks)
            if nargin < 2
                numLeadingBlanks = 0;
            end
            fprintf('%s%s\n', blanks(numLeadingBlanks), self.Name);
        end

        function setUp(self)
            % do nothing
        end

        function tearDown(self)
            % do nothing
        end
    end

    methods (Static)
        function s=linkto(filename, line_number, name)
            % helper function: makes a clickable link in matlab
            if nargin<3
                name=filename;
            end
            s=sprintf(['%s at <a href="matlab:opentoline(''%s'',%d)">'...
                        'line %d</a>'],name,filename,...
                                line_number,line_number);
        end
    end

end


function run_doctest(preamb, expr, wants, filename, line)
    % helper function to run the doctest.
    % If the test fails a variety of exceptions can be thrown
    failed=false;
    while true
        for preamble_with_expr=[false true]
            if preamble_with_expr
                lines=[preamb {expr}];
            else
                lines=preamb;
            end
            to_evaluate=cosmo_strjoin(lines,'\n');

            if isempty(to_evaluate) && ~preamble_with_expr
                % empty preamble and no expression, skip
                continue;
            end

            [ve,me]=CosmoDocTestCase__evalc(to_evaluate);
            exception_was_thrown=~isempty(me);

            preamble_exception=~preamble_with_expr && exception_was_thrown;
            wrong_exception=preamble_with_expr && ...
                            exception_was_thrown && ...
                            ~exception_is_wanted(wants);

            if preamble_exception || wrong_exception
                % exception was thrown
                failed=true;
                if exception_was_thrown
                    msg=sprintf(['Expression gave unexpected exception:'...
                                '\n%s\n%s'],...
                                to_evaluate,me.getReport);
                else
                    msg=sprintf(['Exception not thrown:\n\nExpected:'...
                                '\n%s\n\nGot:\n%s\n']...
                                ,wants,to_evaluate);
                end
                break;
            end

            if ~preamble_with_expr && ~isempty(ve)
                % Preamble alone gave output
                failed=true;
                msg=sprintf(['Preamble should not have output:\n%s\n\n'...
                                'Output:\n%s\n'],to_evaluate,ve);
                break;
            end
        end


        if ~failed && ~doctest_compare(ve,wants)
            % Unexpected output
            failed=true;
            msg=sprintf(['Expression:\n%s'...
                     '\n\nExpected:\n%s\n\nGot:\n%s\n'],...
                                expr,prefix_gt(wants),prefix_gt(ve));
            break
        end

        % always ensure to break out of the loop
        break;

        assert(false,'Should never come here');
    end

    if failed
        % raise exception with informative error message
        prefix=sprintf('%s\n',CosmoDocTestCase.linkto(filename, line));
        error([prefix msg]);
    end
end


function t=prefix_gt(s)
    % prefix each line with "'%     > '"
    % (this is useful to correct failing doc tests)
    lines=cosmo_strsplit(s,'\n');
    add_pf=@(x) ['%     > ' x];
    t=cosmo_strjoin(cellfun(add_pf,lines,'UniformOutput',false),'\n');
end


function [CosmoDocTestCase__eval_res,CosmoDocTestCase__eval_me]=...
                                        CosmoDocTestCase__evalc(expr)
    % helper function with minimal namespace to avoid variable name
    % collisions when using evalc
    %
    % CosmoDocTestCase__eval_me==[] means succesful evaluation of 'expr',
    % otherwise CosmoDocTestCase__eval_me contains the exception
    CosmoDocTestCase__eval_res=[];
    CosmoDocTestCase__eval_me=[];
    try
        CosmoDocTestCase__eval_res=evalc(expr);
    catch CosmoDocTestCase__eval_me
        % do nothing
    end
end

function cmp=doctest_compare(found, wanted)
    % not-so-stringent comparison of found (output from evaluting an
    % expression) and wanted (an expected output string)

    if isequal(found,[])
        cmp=exception_is_wanted(wanted);
        return
    end

    % remove ' ans = ' line if present
    found=without_ans(found);

    % split both inputs by whitespace
    se=cosmo_strsplit(found);
    sw=cosmo_strsplit(wanted);

    % if all strings equal, then they are considered equal
    cmp=isequal(se,sw);
    if cmp
        return;
    end

    % strings not equal; try conversion to numeric
    [ne,e_ok]=str2num(found);
    [nw,w_ok]=str2num(wanted);

    cmp=e_ok && w_ok && isequal(ne,nw);

    if cmp
        % equal in numeric form
        return
    end

    [evw,me]=CosmoDocTestCase__evalc(wanted);
    exception_was_thrown=~isequal(me,[]);

    cmp=(~exception_was_thrown && isequal(found,without_ans(evw))) || ...
            exception_was_thrown && exception_is_wanted(wanted);

end

function tf=exception_is_wanted(wanted)
    wanted_trimmed=strtrim(wanted);
    if isempty(wanted_trimmed)
        tf=false;
        return
    end

    prefix=cosmo_strsplit(wanted_trimmed,[],1,'(',1);
    tf=isequal(strtrim(prefix), 'error');
end

function t=without_ans(s)
    % remove ' ans = ' string that matlab prints when evaluating an
    % expression with semicolon

    t=regexprep(s,sprintf('^\nans = ?\n\n'),'');
end
