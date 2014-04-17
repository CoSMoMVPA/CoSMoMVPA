function s=wtf
% return system, toolbox and externals information 
%
% s=cosmo_wtf()
%
% Output:
%   s         string representation of information
%
% Notes:
%  - this function is intended to get system information in user support
%    situations.
%
% Examples:
%   % print the information to standard out (the command window)
%   >> cosmo_wtf();
%
%   % store the information in the variable 'w':
%   >> w=cosmo_wtf()
%
% NNO Apr 2014

% space for output
w=cell(6,1);

% computer info
[c,m,e]=computer();
w=append(w,'Computer',sprintf('%s (maxsize=%d, endian=%s)',c,m,e));


% matlab info
[version_,date]=version();
w=append(w,'Matlab version',sprintf('%s (%s)',version_,date));
w=append(w,'Java',version('-java'));


% matlab toolboxes
d=dir(toolboxdir(''));
to_omit={'.','..','matlab','system'};
w=append(w,'Matlab toolboxes',dir2str(d,to_omit));


% CoSMoMVPA externals
w=append(w,'CoSMoMVPA externals',...
        cosmo_strjoin(cosmo_check_external('-list'),', '));

    
% CoSMoMVPA files
pth=fileparts(which(mfilename())); % cosmo root directory
d=cosmo_dir(pth,'cosmo_*.m'); % list files
w=append(w,'CoSMoMVPA files', dir2str(d));


% CoSMoMVPA configuration
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
    sw=cosmo_strjoin(ww,'\n');
catch e
    sw=e.getReport();
end
w=append(w,'CoSMoMVPA config', sw);
w=append(w,sprintf('\n')); % add newline
w=cut(w);    

% join elements in w
s=cosmo_strjoin(w,'\n');
if nargout==0
    % print output
    fprintf(s);
end

function s=dir2str(d, to_omit)
% d is the result from 'dir' or 'cosmo_dir'
if nargin<2, to_omit=cell(0); end

n=numel(d); 
ww=cell(n+1,1); % allocate space for output
ww{1}='';
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




