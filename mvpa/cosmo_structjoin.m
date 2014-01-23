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
%               - if a string, then it is stored as s.(argX)=arg{X+1} 
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
% Notes:
%  - this function can be used to parse input arguments
%
% NNO Jan 2014

me=str2func(mfilename()); % support renaming, make immune to renaming

s=struct();
n=numel(varargin);

k=0;
while k<n
    % go over all input arguments
    k=k+1;
    v=varargin{k}; %k-th argument
    
    if iscell(v)
        % process contents of cell recursively
        v=me(v{:});
    end
    
    if isstruct(v)
        % overwrite any values in c
        fns=fieldnames(v);
        for j=1:numel(fns);
            fn=fns{j};
            s.(fn)=v.(fn);
        end
    elseif ischar(v)
        % <key>, <value> pair
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
        error(['Illegal input at position %d: expected cell, struct,',...
                    'or string <key>'], k);
    end
end
        
    

