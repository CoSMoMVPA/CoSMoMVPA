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
%             - if param is one of 'computer', 'environment', version',
%               'matlab_toolboxes', 'cosmo_externals', 'cosmo_files'
%               then the information of that parameter is returned.
%
% Notes:
%  - this function is intended to get system information in user support
%    situations.
%
% Examples:
%   % print the information to standard out (the command window)
%   cosmo_wtf()
%
%   % store the information in the variable 'w':
%   w=cosmo_wtf();
%
%   % see if this environment is octave
%   b=cosmo_wtf('is_octave');
%
% NNO Apr 2014

has_param=nargin>=1 && ~isempty(param);
if has_param
    if strcmp(param,'is_matlab')
        s=environment_is_matlab();
        return
    elseif strcmp(param,'is_octave')
        s=environment_is_octave();
        return
    end
end

params2func=struct();
params2func.computer=@computer_;
params2func.environment=@environment;
params2func.version=version_;
params2func.matlab_toolboxes=@matlab_toolboxes;
params2func.cosmo_externals=@cosmo_externals;
params2func.cosmo_files=@cosmo_files;

has_param=nargin>=1 && ~isempty(param);
if has_param;
    if ~isfield(params2func,param)
        error('Unsupported parameter ''%s''. Supported are: %s',...
                    param, cosmo_strjoin(fieldnames(params2func),', '));
    end
    f=params2func.(param);
    s=f();
    return
end

me=str2func(mfilename());
params=fieldnames(params2func);
printer=@(param) sprintf('%s: %s',param,me(param));
s_cell=cellfun(printer,params,'UniformOutput',false);
s=cosmo_strjoin(s_cell,'\n');


function s=computer_()
    [c,m,e]=computer();
    s=sprintf('%s (maxsize=%d, endian=%s)',c,m,e);

function s=environment()
    if environment_is_octave()
        s='octave';
    elseif environment_is_matlab()
        s='matlab';
    else
        assert(false,'This should not happen');
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
    
function s=matlab_toolboxes()
    if ~environment_is_matlab()
        s=sprintf('not supported in environment ''%s''',environment());
        return
    end
    
    d=dir(toolboxdir(''));
    to_omit={'.','..','matlab','system'};
    s=dir2str(d,to_omit);
    
function s=cosmo_externals()
    s=cosmo_strjoin(cosmo_check_external('-list'),', ');
    
function s=cosmo_files()    
    pth=fileparts(which(mfilename())); % cosmo root directory
    d=cosmo_dir(pth,'cosmo_*.m'); % list files
    s=dir2str(d);
    
function s=cosmo_config()
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
    catch e
        s=e.getReport();
    end

    
function s=dir2str(d, to_omit)
% d is the result from 'dir' or 'cosmo_dir'
if nargin<2, to_omit=cell(0); end

n=numel(d); 
ww=cell(n+1,1); % allocate space for output
ww{1}='';       % start with newline
pos=1;
for k=1:n
    dk=d(k);
    name=dk.name;
    
    if ~any(cosmo_match(to_omit, {name}))
        pos=pos+1;
        ww{pos}=sprintf('  %s % 10d %s',dk.date,dk.bytes,dk.name);
    end
end
s=cosmo_strjoin(ww(1:pos),'\n');



function w=append(w,desc,str)
% helper function to add an element in a cell.
% the cell size doubles every time the cell becomes filled.

% first empty position in w
i=find(cellfun(@isempty,w),1);

if isempty(i)
    % allocate space
    n=numel(w);
    w{n*2}=[];
    i=n+1;
end

if nargin==3
    w{i}=sprintf('%s: %s',desc,str);
else
    w{i}=desc;
end

function w=cut(w)
% remove empty elements in w
i=find(cellfun(@isempty,w),1);
if ~isempty(i)
    w=w(1:(i-1));
end




