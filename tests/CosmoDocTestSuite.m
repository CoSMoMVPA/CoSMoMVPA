classdef CosmoDocTestSuite < TestSuite
% CoSMoMVPA doctest suite
%
% Provides doctest functionality using the help information associated
% with an .m file. It also supports directories with such files; it
% collects the doc tests in directories recursively
%
% A doctest is specified in the comment header section of an .m file; it is
% based on the text that is showed by the command 'help the_function'
%
% An example of a set of doctests:
% % (function documentation here)
% % 
% % Example:                                    % 1
% %     % this is a comment                     % 2
% %     negative_four=2+2;                      % 3
% %     sixteen=negative_four^2;                % 4
% %     abs([negative_four sixteen])            % 5
% %     > 4 16                                  % 6
% %     %                                       % 7
% %     abs(negative_four-sixteen)     
% %     > 20
% %
% %     disp({@abs ' is a useful function'})
% %     > foo
% %
% % % (end of example)
%
% 
% This class extends the xUnit framework by S. Eddings (2009),
% BSD License, http://www.mathworks.it/matlabcentral/fileexchange/
%                       22846-matlab-xunit-test-framework

    
    methods
        function self = CosmoDocTestSuite(name)
            %TestSuite Constructor
            %   suite = TestSuite constructs an empty test suite. suite =
            %   TestSuite(name) constructs a test suite by searching for test
            %   cases defined in an M-file with the specified name.
            
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
    error_=@(msg,line) error([CosmoDocTestCase.linkto(...
                                        filename,line) ' : ' msg]);

    suite=CosmoDocTestSuite();
    suite.Name=filename;
    
    w=which(filename);
    if isempty(w)
        return;
    end
    suite.Location=w;
    
    help_str=help(filename);
    help_lines=cosmo_strsplit(help_str,'\n');
    
    n=numel(help_lines);
    line_states=zeros(n,1);

    state_pre=0;
    state_whitespace=1;
    state_comment=2;
    state_preamb=3;
    state_expr=4;
    state_want=5;
    state_post=9;

    prefix_want='>';
    prefix_comment='%';

    start_re='^\s*[eE]xamples?:?\s*$';
    first_indent=[];

    state=state_pre;
    for k=1:numel(help_lines)
        line_number=k;
        line=help_lines{k};
        line_trim=strtrim(line);

        if ~isempty(regexp(line,start_re,'once'))
            if state>0
                error_('repeat of ''Examples'' header ',line_number);
            end
            state=state_comment;
        elseif any(state==[state_pre, state_post])
            % pre or post; do nothing
        elseif isempty(line_trim) 
            state=state_whitespace;
        else
            indent=regexp(line,'(\S)+.*$','start');
            assert(~isempty(indent));
            if isempty(first_indent)
                first_indent=indent;
            end
            
            
            if indent<first_indent
                state=state_post;
            elseif line_trim(1)==prefix_want
                state=state_want;
            elseif line_trim(1)==prefix_comment
                state=state_comment;
            else
                state=state_expr;
            end
        end
        line_states(k)=state;
    end
    
    expr_msk=line_states==state_expr & [line_states(2:end);0]==state_want;
    line_states(line_states==state_expr & ~expr_msk)=state_preamb;

    rng=1:numel(help_lines);

    states_block=[state_expr,state_comment,state_preamb,state_want];
    block_msk=cosmo_match(line_states,states_block);
    block_start=find(~block_msk & [block_msk(2:end);false])+1;
    block_end=find(rng'>1 & block_msk & ~[block_msk(2:end);false])-1;

    nblocks=numel(block_start);
    if nblocks~=numel(block_end)
        error_('Unfinished block', block_end(end));
    end

    for k=1:nblocks

        block_msk=block_start(k)<=rng & rng<=block_end(k);
        expr_idxs=find(expr_msk' & block_msk);
        nexprs=numel(expr_idxs);
        expr=cell(nexprs,1);
        wants=cell(nexprs,1);
        for j=1:nexprs
            expr_idx=expr_idxs(j);
            preamb_msk=block_msk' & line_states==state_preamb & ...
                                                    rng'<=expr_idx;
            preamb=help_lines(preamb_msk);
            
            want_idx=expr_idx+1;
            while line_states(want_idx)==state_want
                want_idx=want_idx+1;
            end
            wants_with_prefix=help_lines((expr_idx+1):(want_idx-1));
            
            if numel(wants_with_prefix)==0
                warning('Skipping %d',k)
                continue;
            end
            
            preamb=preamb;
            
            expr_lines=help_lines(expr_idx);
            expr=cosmo_strjoin(expr_lines,'\n');
            
            re=['^\s*' prefix_want '(?<f>.*)$'];
            wants_lines=regexprep(wants_with_prefix,re,'$1');
            wants=cosmo_strjoin(wants_lines,'\n');

            line_number=expr_idx;
            doctest=CosmoDocTestCase(preamb,expr,wants,filename,line_number);
            suite.add(doctest);
        end
    end
end
