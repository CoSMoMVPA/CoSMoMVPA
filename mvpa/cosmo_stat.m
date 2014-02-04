function [stat,df]=cosmo_stat(stat_name, samples, targets)
% compute one-sample t, two-sample t, or F statistic
%
% Usages:
%  - [stat,df]=cosmo_stats(stat_name, samples, targets)
%  - stat_ds=cosmo_stats(stat_name, ds)
%
% Inputs:
%  - stat_name        't', 't2' or 'f'
%  - ds or samples    dataset struct or PxQ sample matrix.
%                     if a struct it should have a field .sa.targets
%  - targets          if samples is a matrix, Px1 class labels
%
% Returns:
%  - stat_ds or stat  dataset struct or 1xQ sample matrix with t or F
%                     scores. If a struct it has fields
%                     .sa.label={stat_name} and .sa.df with degrees of
%                     freedom.
%  - df               if samples is a matrix, degrees of freedom.
%
% Notes
%  - this function runs conserably faster than builtin matlab 
%
% NNO Jan 2014

if isstruct(samples)
    % deal with dataset struct case
    if nargin<3 && isfield(samples,'samples') && ...
                    isfield(samples,'sa') && isfield(samples.sa,'targets')
        targets=samples.sa.targets;
        samples=samples.samples;
        is_ds=true;
    else
        error('Illegal input: struct needs .samples and .sa.targets')
    end
else
    is_ds=false;
end

switch stat_name
    case 't'
        [stat,df]=quick_ttest(samples);
        
    case {'t2','f'}
        if numel(targets)~=size(samples,1)
            error('Targets has %d values, expected %d', ...
                        numel(targets), size(samples,1));
        end
        classes=unique(targets);
        nclasses=numel(classes);
        if strcmp(stat_name,'t2')
            if nclasses~=2
                error('%s stat: expected 2 classes, found %s',...
                        stat_name, nclasses);
            end
            [stat,df]=quick_ttest2(samples(targets==classes(1),:),...
                              samples(targets==classes(2),:));
        else
            [stat,df]=quick_ftest(samples, targets, classes, nclasses);
        end
        
    otherwise
        error('illegal statname %s', stat_name);
end

if is_ds
    % if input was datset struct, return a dataset too
    ds=struct();
    ds.samples=stat;
    ds.sa.labels={stat_name};
    ds.sa.df=df;
    stat=ds;
end

function [f,df]=quick_ftest(samples, targets, classes, nclasses)

ns=size(samples,1);
mu=sum(samples,1)/ns;

bss=0;
wss=0;

for k=1:nclasses
    msk=classes(k)==targets;
    
    nc=sum(msk);
    sample=samples(msk,:);
    muc=sum(sample,1)/nc;
    
    bss=bss+nc*(mu-muc).^2;
    wss=wss+sum(bsxfun(@minus,muc,sample).^2,1);
end



df=[nclasses-1,ns-nclasses];

bss=bss/df(1);
wss=wss/df(2);

f=bss./wss;



function [t,df]=quick_ttest(x)
n=size(x,1);
mu=sum(x,1)/n;

df=n-1;
ss=sum(bsxfun(@minus,x,mu).^2,1);
scaling=n*df;

t=mu .* sqrt(scaling./ss);


function [t,df]=quick_ttest2(x,y)
nx=size(x,1);
ny=size(y,1);
mux=sum(x,1)/nx;
muy=sum(y,1)/ny;

df=nx+ny-2;
scaling=(nx*ny)*df/(nx+ny);
ss=sum([bsxfun(@minus,x,mux);bsxfun(@minus,y,muy)].^2,1);

t=(mux-muy) .* sqrt(scaling./ss);

