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
%  - Unlike the builtin 'isfield' function, this function can check for
%    multiple fields in one call and can check for the presence of nested
%    structs
%
% See also: isfield
%
% NNO Aug 2014

    if ~isstruct(s)
        error('First argument must be a struct');
    end

    if nargin<3
        raise=false;
    end

    if ischar(name)
        cell_names={name};
    else
        if ~iscellstr(name)
            error('Second argument must be string or cell with strings');
        end
        cell_names=name;
    end

    n=numel(cell_names);
    tf=zeros(n,1);
    for k=1:n
        name=cell_names{k};
        keys=cosmo_strsplit(name,'.');
        nkeys=numel(keys);

        has_key=true;
        value=s;
        for j=1:nkeys
            key=keys{j};
            if (j>1 && ~isstruct(value)) || ~isfield(value,key)
                if raise
                    key_name=cosmo_strjoin(keys(1:(j)),'.');
                    error('Missing field .%s', key_name);
                end
                has_key=false;
                break;
            end

            if j<nkeys
                value=value.(key);
            end
        end

        tf(k)=has_key;
    end
