function tf=cosmo_isfield(s, name, raise)
% checks the presence of (possibly nested) fieldnames in a struct
%
% tf=cosmo_isfield(s, name, raise)
%
% Inputs:
%    s               struct for which fieldnames are assessed
%    name            string or cell of strings with fieldnames.
%                    Fieldnames can take the form 'a.b.c', meaning that
%                    it checks for s to have a field 'a', s.a to have a
%                    field 'b', and s.a.b to have a field 'c'.
%    raise           Optional logical indicating whether an error should be
%                    raised if any fieldname is not present (default:
%                    false)
%
% Output:
%    tf              Nx1 logical array, where N=1 if name is a string and
%                    N=numel(name) if name is a cell. Each value is true
%                    only if the corresponding fieldname is present in s.
%
% Examples:
%     % make a simple struct
%     s=struct();
%     s.a=1;
%     s.b=2;
%     s.c.d.e=3;
%     %
%     % check for presence of 'a' in s
%     cosmo_isfield(s,'a')
%     > 1
%     %
%     % check for present of 'c' in s, 'd' in s.d, and 'e' in s.c.d
%     cosmo_isfield(s,'c.d.e')
%     > 1
%     %
%     % check for the present of four fields (two are absent)
%     cosmo_isfield(s,{'c.d.e','c.d.f','a','x'})
%     > 1
%     > 0
%     > 1
%     > 0
%     %
%     % this would raise an error if 'c.d.e' is not present
%     cosmo_isfield(s,'c.d.e',true)
%     > 1
%
% Notes:
%  - Unlike the builtin 'isfield' function
%    * only structs with at most one element (empty or 1x1) are supported
%    * this function can check for multiple fields in one call and can
%      check for the presence of nested structs
%    * this function accepts non-structs as the first input argument; the
%      result is then false for every name
%
% See also: isfield
%
% NNO Aug 2014

    if nargin<3
        raise=false;
    end

    if ischar(name)
        tf=single_isfield(s, name, raise);
    elseif iscellstr(name)
        tf=cellfun(@(x)single_isfield(s,x,raise),name);
    else
        error('Second argument must be string or cell with strings');
    end


function s=key_name(keys, index)
    s=cosmo_strjoin(keys(1:index),'.');

function has_key=single_isfield(s, name, raise)
    has_key=false;

    keys=cosmo_strsplit(name,'.');
    nkeys=numel(keys);

    value=s;
    for j=1:nkeys
        if ~isstruct(value)
            if raise
                if j==1
                    error('Input is not a struct');
                else
                    error('Not a struct: .%s', key_name(keys,j));
                end
            end
            return;
        end

        if numel(value)~=1
            if raise
                error('Unsupported non-singleton struct');
            end
            return
        end

        key=keys{j};

        if ~isfield(value,key)
            if raise
                error('Struct has missing field .%s',key_name(keys,j));
            end
            return;
        end

        if j<nkeys
            value=value.(key);
        end
    end

    has_key=true;
