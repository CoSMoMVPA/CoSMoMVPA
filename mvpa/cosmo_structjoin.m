function s=cosmo_structjoin(varargin)
% joins values in structs or key-value pairs
%
% s=cosmo_structjoin(arg1, arg2, ...)
%
% Inputs:
%   arg{X}      Any of the following:
%               - if a cell, then it should contain structs or key-value
%                 pairs
%               - if a struct, then value=arg{X}.(key) for each key in
%                 fieldnames(arg{X}) is stored as s.(key)=value
%               - if a string, then it is stored as s.(arg{X})=arg{X+1}
%
% Returns:
%   s           Struct with fieldnames and their associated values
%               as key-value pairs. Values in the input are stored from
%               left-to-right.
%
% Example:
%     x=cosmo_structjoin('a',{1;2},'b',{3,4});
%     cosmo_disp(x);
%     > .a
%     >   { [ 1 ]
%     >     [ 2 ] }
%     > .b
%     >   { [ 3 ]  [ 4 ] }
%     y=cosmo_structjoin(x,'a',66,'x',x,{'c','hello'});
%     cosmo_disp(y);
%     > .a
%     >   [ 66 ]
%     > .b
%     >   { [ 3 ]  [ 4 ] }
%     > .x
%     >   .a
%     >     { [ 1 ]
%     >       [ 2 ] }
%     >   .b
%     >     { [ 3 ]  [ 4 ] }
%     > .c
%     >   'hello'
%
%     % simulate a function definition function out=f(varargin)
%     % to illustrate overriding default values
%     varargin={'radius',2,'nsamples',12};
%     defaults=struct();
%     defaults.radius=10;
%     defaults.nfeatures=2;
%     params=cosmo_structjoin(defaults,varargin);
%     cosmo_disp(params);
%     > .radius
%     >   [ 2 ]
%     > .nfeatures
%     >   [ 2 ]
%     > .nsamples
%     >   [ 12 ]
%
%     % illustrate overriding values in 'sub-structs' (structs as values in
%     % other structs)
%     v=struct();
%     v.a.foo={1,2};
%     v.b=3;
%     w=struct();
%     w.a.bar=[2,3];
%     w.c=4;
%     j=cosmo_structjoin(v,w);
%     cosmo_disp(j)
%     > .a
%     >   .foo
%     >     { [ 1 ]  [ 2 ] }
%     >   .bar
%     >     [ 2         3 ]
%     > .b
%     >   [ 3 ]
%     > .c
%     >   [ 4 ]
%
%
% Notes:
%  - this function can be used to parse input arguments (including
%    varargin in a "'key1',value1,'key2',value2,..." fashion)
%
% NNO Jan 2014

persistent me; % function handle to current function

if isempty(me)
    me=str2func(mfilename());
end

s=struct(); % output
n=numel(varargin);

k=0;
while k<n
    % go over all input arguments
    k=k+1;
    v=varargin{k}; %k-th argument

    if iscell(v)
        if isempty(v)
            continue;
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

        % overwrite any values in s
        fns=fieldnames(v);

        for j=1:numel(fns);
            fn=fns{j};
            s=update_struct(s, fn, v.(fn), me);
        end
    elseif ischar(v)
        % <key>, <value> pair
        if k+1>n
            % cannot be last argument
            error('Missing argument after key ''%s''', v);
        end

        % move forward to next argument and get value
        k=k+1;
        vv=varargin{k};

        s=update_struct(s, v, vv);
    else
        error(['Illegal input at position %d: expected cell, struct, ',...
                    'or string'], k);
    end
end

function s=update_struct(s, fn, v, me)
    if isfield(s,fn) && isstruct(s.(fn)) && isstruct(v)
        s.(fn)=me(s.(fn),v);
    else
        s.(fn)=v;
    end

