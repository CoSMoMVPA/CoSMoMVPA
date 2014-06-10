function s=cosmo_structjoin(varargin)
% joins values in structs or key-value pairs
%
% s=cosmo_structjoin(arg1, arg2, ...)
%
% Inputs:
%   argX        Any of the following:
%               - if a cell, then it should contain structs or key-value
%                 pairs
%               - if a struct, then value=argX.(key) for each key in
%                 fieldnames(argX) is stored as s.(key)=value
%               - if a string, then:
%                 * if '!' then the output must contain a subset of the 
%                   fields in arg{X+1}
%                 * otherwise this stored as s.(argX)=arg{X+1} 
%               
%
% Returns:
%   s           Struct with fieldnames and their associated values
%               as key-value pairs. Values in the input are stored from
%               left-to-right.
%
% Example:
%   >> x=cosmo_structjoin('a',{1;2},'b',{3,4})
%   x.a: {1;2}
%   x.b: {3,4}
%
%   >> y=cosmo_structjoin(x,'a',3,'x',x,{'c','hello'})
%   y.a: 3
%   y.b: {1,2}
%   y.x.a: {1;2}
%   y.x.b  {3,4}
%   y.c: 'hello'
%
%   % check input arguments; raise error if a key not in defaults.
%   >> defaults=struct();
%   >> defaults.a=1;
%   >> defaults.b=2;
%   >> cosmo_structjoin('!',defaults,'a',3,'c',4)
%   Error using cosmo_structjoin (line 106)
%   Illegal key c - not one of a,b
%
%   % To override defaults in a function:
%   >> params=cosmo_structjoin('!',defaults,varargin);
%
% Notes:
%  - this function can be used to parse input arguments.
%  - the '!' can be used multiple times; the effect is to use the union of
%    the fieldnames indicates by the arguments following them.
%
% NNO Jan 2014

me=[]; % function handle to current function, set upon first recursive call

s=struct(); % output
n=numel(varargin);

q={}; % superset of output fieldnames, or '[]' for no superset

k=0;
while k<n
    % go over all input arguments
    k=k+1;
    v=varargin{k}; %k-th argument
    
    check_super=strcmp(v,'!');
    if check_super
        k=k+1;
        v=varargin{k};
    end
    
    if iscell(v)
        if isempty(v)
            continue;
        end
        
        % process contents of cell recursively
        if isempty(me)
            me=str2func(mfilename());
        end
        v=me(v{:});
    end
    
    if isstruct(v)
        if isempty(v)
            continue;
        elseif isempty(s)
            s=v;
            continue;
        end
        
        % overwrite any values in c
        fns=fieldnames(v);
        for j=1:numel(fns);
            fn=fns{j};
            s.(fn)=v.(fn);
        end
        
        if check_super
            q=union(q, fns);
        end
        
    elseif ischar(v)
        % <key>, <value> pair
        
        if check_super
            q=union(q, {v});
            continue;
        end
        
        if k+1>n
            % cannot be last argument
            error('Missing argument after %s', v);
        end
        
        % move forward to next argument and get value
        k=k+1;
        vv=varargin{k};
        
        % store value
        s.(v)=vv;
        
        
    else
        error(['Illegal input at position %d: expected cell, struct, ',...
                    'or string'], k);
    end
end
        
if ~isempty(q)
    d=setdiff(fieldnames(s), q);
    if ~isempty(d)
        error('Illegal key %s - not one of %s', ...
                        d{1}, cosmo_strjoin(q, ','));
    end
end

