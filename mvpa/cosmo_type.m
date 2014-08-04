function s=cosmo_type(fn)
% print or return ASCII contents of a file
%
% Usages
%  - cosmo_type(fn);     prints the contents of file fn
%  - s=cosmo_type(fn);   return the contents of file fn
%
% See also: type
%
% NNO Feb 2014

fid=fopen(fn);
s=fread(fid,inf,'char=>char');
fclose(fid);

if nargout==0
    fprintf(s);
end
