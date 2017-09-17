function s=cosmo_wtf(param)
% return system, toolbox and externals information
%
% s=cosmo_wtf([param])
%
% Parameters
%   param     optional; if provided it can be 'is_octave' or 'is_matlab'
%
% Output:
%
%   s         - if param is not provided it returns a string
%               representation with system information;
%             - if param is 'is_{octave,matlab}' a boolean is returned
%             - if param is 'version_number' then a numeric vector with
%               version information is returned; for example version
%                '8.5.0.197613' results in [8, 5, 0, 197613].
%             - if param is one of 'computer', 'environment', version',
%               'toolboxes', 'cosmo_externals', 'cosmo_files', or 'java',
%               then the information of that parameter is returned.
%
%
% Examples:
%   % print the information to standard out (the command window)
%   cosmo_wtf();
%
%   % store the information in the variable 'w':
%   w=cosmo_wtf();
%
%   % see if this environment is octave
%   b=cosmo_wtf('is_octave');
%
% Notes:
%  - this function is intended to get system information in user support
%    situations.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    has_param=nargin>=1 && ~isempty(param);
    if has_param
        s=get_single_param_value(param);
    else
        s=get_all_param_values();
    end





function s=get_all_param_values()
    param2func=get_param2func();
    keys=fieldnames(param2func);
    value_printer=@(key)as_string(helper_get_param_from_func_value(key));
    printer=@(key) sprintf('%s: %s',...
                        key,value_printer(key));
    s_cell=cellfun(printer,keys,'UniformOutput',false);
    s=cosmo_strjoin(s_cell,'\n');

function s=as_string(v)
    if ischar(v)
        s=v;
    elseif isnumeric(v)
        s=sprintf('[ %s]',sprintf('%d ',v));
    elseif iscellstr(v)
        s=sprintf('\n  %s',v{:});
    else
        assert(false,'unsupported type');
    end

function s=get_single_param_value(param)
    if ~ischar(param)
        error('argument must be a string');
    end

    switch param
        case 'is_matlab'
            s=environment_is_matlab();

        case 'is_octave'
            s=environment_is_octave();

        otherwise
            s=helper_get_param_from_func_value(param);
    end

function s=helper_get_param_from_func_value(key)
    param2func=get_param2func();

    if ~isfield(param2func,key)
        error('Unsupported parameter ''%s''. Supported are:\n  ''%s''',...
                    key, cosmo_strjoin(fieldnames(param2func),'''\n  '''));
    end
    f=param2func.(key);
    s=f();


function param2func=get_param2func()
    persistent cached_param2func;

    if ~isstruct(cached_param2func)
        cached_param2func=struct();
        cached_param2func.computer=@computer_;
        cached_param2func.environment=@environment;
        cached_param2func.version=version_;
        cached_param2func.version_number=@version_number_;
        cached_param2func.java=java_;
        cached_param2func.cosmo_externals=@cosmo_externals;
        cached_param2func.toolboxes=@toolboxes;
        cached_param2func.warnings=@warning_helper;
        cached_param2func.cosmo_config=@cosmo_config_helper;
        cached_param2func.cosmo_files=@cosmo_files;
        cached_param2func.path=@path_;
    end

    param2func=cached_param2func;



function s=computer_()
    [c,m,e]=computer();
    s=sprintf('%s (maxsize=%d, endian=%s)',c,m,e);

function s=environment()
    if environment_is_octave()
        s='octave';
    elseif environment_is_matlab()
        s='matlab';
    end

function tf=environment_is_octave()
    tf=logical(exist('OCTAVE_VERSION', 'builtin'));

function tf=environment_is_matlab()
    % assume either matlab or octave, no third interpretr
    tf=~environment_is_octave();

function s=version_()
    if environment_is_matlab()
        [version_,date_]=version();
        s=sprintf('%s (%s)',version_,date_);
    else
        s=sprintf('%s',version());
    end

function v=version_number_()
    v_str=regexp(version(),'^\S*','match');
    parts=cosmo_strsplit(v_str{1},'.');
    v=cellfun(@str2num,parts);

function s=java_()
    if environment_is_matlab()
        s=version('-java');
    else
        s=not_in_this_environment();
    end

function s=not_in_this_environment()
    s=sprintf('not supported in environment ''%s''',environment());

function s=toolboxes()
    v=ver();
    formatter=@(x) sprintf('  %s v%s %s [%s]',x.Name,x.Version,...
                                                x.Release,x.Date);
    s=dir2str(v,formatter);

function s=cosmo_externals()
    s=cosmo_check_external('-list');


function s=cosmo_files()
    pth=fileparts(which(mfilename())); % cosmo root directory
    d=cosmo_dir(pth,'cosmo_*.m'); % list files
    s=dir2str(d);

function s=cosmo_config_helper()
    try
        c=cosmo_config();
        fns=fieldnames(c);
        n=numel(fns);
        ww=cell(n+1,1);
        ww{1}='';
        for k=1:n
            fn=fns{k};
            ww{k+1}=sprintf('  %s: %s',fn,c.(fn));
        end
        s=cosmo_strjoin(ww,'\n');
    catch
        caught_error=lasterror();
        s=caught_error.message;
    end

function s=path_()
    s=cosmo_strsplit(path(),pathsep());

function parts=warning_helper()
    s=warning();
    n=numel(s);

    parts=arrayfun(@(i)sprintf('%s: %s', s(i).identifier, s(i).state),...
                    1:n,'UniformOutput',false);

function s=dir2str(d, formatter)
    % d is the result from 'dir' or 'cosmo_dir'
    if nargin<2
        formatter=@(x)sprintf('  %s % 10d %s',x.date,x.bytes,x.name);
    end

    n=numel(d);
    ww=cell(n+1,1); % allocate space for output
    ww{1}='';       % start with newline
    pos=1;
    for k=1:n
        dk=d(k);

        % if any value is empty, replace it by the empty string
        fns=fieldnames(dk);
        for j=1:numel(fns)
            fn=fns{j};
            v=dk.(fn);
            if isempty(v)
                dk.(fn)='';
            end
        end

        pos=pos+1;
        ww{pos}=formatter(dk);
    end
    s=cosmo_strjoin(ww(1:pos),'\n');


