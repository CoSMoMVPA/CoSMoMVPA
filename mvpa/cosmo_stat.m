function stat_ds=cosmo_stat(ds, stat_name, output_stat_name)
% compute t-test or F-test (ANOVA) statistic
%
% stat_ds=cosmo_stats(ds, stat_name[, output_stat_name])
%
% Inputs:
%   ds                dataset struct with
%                       .samples PxQ, for P observations on Q features
%                       .sa.targets Px1 observation conditions (levels)
%                       .sa.chunks  Px1 observation chunks (e.g. subjects)
%   stat_name         One of:
%                     't' : one-sample t-test against zero, or paired
%                           t-test
%                     't2': two-sample t-test with equal variance,
%                           contrasting samples with unq(1) minus unq(2)
%                           where unq=unique(ds.sa.targets)
%                     'F' : one-way ANOVA or repeated measures ANOVA.
%   output_stat_name  (optional) 'left', 'right', 'both', 'z', 'p', or
%                      empty (default).
%                     - 'left', 'right', and 'both' return a p-value with
%                        the specified tail.
%                     - 'p' returns a p-value, with tail='right' if
%                        stat_name='F' and tail='both' otherwise.
%                     - 'z' returns a z-score corresponding to the p-value
%                     - '' (empty) returns the t or F statistic.
%
% Returns:
%   stat_ds          dataset struct with fields:
%     .samples       1xQ statistic value, or (if output_stat_name is
%                    non-empty) z-score or p-value. See the Notes below
%                    for interpreting p-values.
%     .sa.stats      One of 'Ftest(df1,df2)', 'Ttest(df)', 'Zscore()', or
%                    'Pval()', where df* are the degrees of freedom
%     .[f]a          identical to hte input ds.[f]a, if present.
%
% Examples:
%     % one-sample t-test
%     % make a simple dataset
%     ds=struct();
%     ds.samples=reshape(mod(1:7:(12*3*7),13)',[],3)-3;
%     ds.sa.targets=ones(12,1);
%     ds.sa.chunks=(1:12)';
%     cosmo_disp(ds.samples);
%     >   [ -2         4        -3
%     >      5        -2         4
%     >     -1         5        -2
%     >      :         :         :
%     >      9         2         8
%     >      3         9         2
%     >     -3         3         9 ]@12x3
%     %
%     % run one-sample t-test
%     s=cosmo_stat(ds,'t');
%     cosmo_disp(s);
%     > .samples
%     >   [ 2.49      3.36      2.55 ]
%     > .sa
%     >   .stats
%     >     { 'Ttest(11)' }
%     %
%     % compute z-score of t-test
%     s=cosmo_stat(ds,'t','z');
%     cosmo_disp(s);
%     > .samples
%     >   [ 2.17      2.73      2.21 ]
%     > .sa
%     >   .stats
%     >     { 'Zscore()' }
%     %
%     % compute (two-tailed) p-value of t-test
%     s=cosmo_stat(ds,'t','p');
%     cosmo_disp(s);
%     > .samples
%     >   [ 0.03   0.00633    0.0268 ]
%     > .sa
%     >   .stats
%     >     { 'Pval()' }
%     %
%     % compute left-tailed p-value of t-test
%     s=cosmo_stat(ds,'t','left');
%     cosmo_disp(s);
%     > .samples
%     >   [ 0.985     0.997     0.987 ]
%     > .sa
%     >   .stats
%     >     { 'Pval()' }
%
%     % one-way ANOVA
%     % each observation is independent and thus each chunk is unique;
%     % there are three conditions with four observations per condition
%     ds=struct();
%     ds.samples=reshape(mod(1:7:(12*3*7),13)',[],3)-3;
%     ds.sa.targets=repmat(1:3,1,4)';
%     ds.sa.chunks=(1:12)';
%     s=cosmo_stat(ds,'F');
%     cosmo_disp(s);
%     > .samples
%     >   [ 0.472    0.0638      0.05 ]
%     > .sa
%     >   .stats
%     >     { 'Ftest(2,9)' }
%     % compute z-score
%     s=cosmo_stat(ds,'F','z'); % convert to z-score
%     cosmo_disp(s);
%     > .samples
%     >   [ -0.354     -1.54     -1.66 ]
%     > .sa
%     >   .stats
%     >     { 'Zscore()' }
%
%
%     % two-sample t-test
%     % each observation is independent and thus each chunk is unique;
%     % there are two conditions with four observations per condition
%     ds=struct();
%     ds.samples=reshape(mod(1:7:(12*3*7),13)',[],3)-3;
%     ds.sa.targets=repmat(1:2,1,6)';
%     ds.sa.chunks=(1:12)';
%     s=cosmo_stat(ds,'t2','p'); % return p-value
%     cosmo_disp(s);
%     > .samples
%     >   [ 0.0307  0.000242  7.07e-05 ]
%     > .sa
%     >   .stats
%     >     { 'Pval()' }
%     %
%     % for illustration, this test gives the same p-values as a
%     % repeated measures ANOVA
%     s=cosmo_stat(ds,'F','p');
%     cosmo_disp(s);
%     > .samples
%     >   [ 0.0307  0.000242  7.07e-05 ]
%     > .sa
%     >   .stats
%     >     { 'Pval()' }
%
% Notes:
%  - If output_stat_name is not provided or empty, then this function runs
%    considerably faster than the builtin matlab functions.
%  - When output_stat_name=='p' then the p-values returned are the same as
%    the builtin matlab functions anova1, ttest, and ttest2 with the
%    default tails.
%  - To run a one-sample t-tests against x (if x~=0), one has to
%    subtract x from ds.samples before using ds as input to this function
%  - The .sa.chunks and .sa.targets determine which test is performed:
%    * statname=='t': all chunks are unique => one-sample t-test
%                   : each chunk present twice => paired-sample t-test
%    * statname=='F': all chunks are unique => one-way ANOVA
%                   : each chunk present N times => repeated measures ANOVA
%    See cosmo_montecarlo_cluster_stat for examples on how .sa.targets and
%    .sa.chunks should be set for different statistics.
%
% See also: anova1, ttest, ttest2, cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<3
        output_stat_name='';
    end

    [output_stat_name,tail]=get_stat_definition(stat_name,...
                                                output_stat_name);
    [samples,targets,chunks,type]=get_descriptors(ds);

    % Set label to be used for cdf (in case 'p' or 'z' has to be computed).
    % This is only different from stat_name in the case of 't2'

    % run specified helper function
    if isfield(ds.sa,'contrast')
        contrast=ds.sa.contrast;
    else
        contrast=[];
    end

    stat_func=get_stat_func(stat_name);

    [stat,df,stat_label]=stat_func(samples,targets,chunks,type,contrast);

    [stat,stat_label]=compute_output_stat(stat,df,stat_label,...
                                                tail,output_stat_name);

    % store output
    stat_ds=struct();
    if isfield(ds,'a'), stat_ds.a=ds.a; end
    if isfield(ds,'fa'), stat_ds.fa=ds.fa; end
    stat_ds.samples=stat;
    stat_ds.sa.stats={stat_label};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=get_stat_func(stat_name)
    stat_name2func=struct();
    stat_name2func.t=@ttest1_wrapper;
    stat_name2func.t2=@ttest2_wrapper;
    stat_name2func.F=@ftest_wrapper;

    if ~isfield(stat_name2func,stat_name)
        error('illegal statname ''%s'', supported are: %s',stat_name,...
                    cosmo_strjoin(fieldnames(stat_name2func),', '));
    end

    f=stat_name2func.(stat_name);

function [stat,stat_label]=compute_output_stat(stat,df,stat_name,...
                                                 tail,output_stat_name)
% transform output is required
    if isempty(output_stat_name)
        stat_label=stat_name;
    else
        % transform to left-tailed p-value
        df_cell=num2cell(df);
        stat=cdf_wrapper(stat_name,stat,df_cell{:});

        % reset degrees of freedom, because z-score or p value have none
        df=[];

        switch output_stat_name
            case 'z'
                % transform to z-score
                stat=norminv_wrapper(stat);
                stat_label='Zscore';
            case 'p'
                switch tail
                    case 'left'
                        % do nothing
                    case 'right'
                        % invert p-value
                        stat=1-stat;
                    case 'both'
                        % take whichever tail is more extreme
                        stat=(.5-abs(stat-.5))*2;
                    otherwise
                        assert(false,'this should not happen');
                end
                stat_label='Pval';
            otherwise
                error('illegal output type %s', output_stat_name);
        end
    end

    df_str=cellfun(@(x) sprintf('%d',x), num2cell(df),...
                    'UniformOutput',false);
    stat_label=sprintf('%s(%s)',stat_label,cosmo_strjoin(df_str,','));

function [stat,df,stat_label]=ttest1_wrapper(samples,targets,chunks,...
                                                           type,contrast)
    if ~isempty(contrast)
        error('contrast is not supported for t-stat');
    end

    nclasses=max(targets);
    if nclasses==2
        samples=pairwise_differences(samples,targets,chunks);
        nclasses=1;
    end

    if nclasses~=1
        error('t-stat: expected 1 or 2 classes, found %d',...
                    nclasses);
    end

    [stat,df]=quick_ttest(samples);
    stat_label='Ttest';

function [stat,df,stat_label]=ttest2_wrapper(samples,targets,chunks,...
                                                           type,contrast)
    if ~isempty(contrast)
        error('contrast is not supported for t-stat');
    end

    nclasses=max(targets);

    if nclasses~=2
        error('ttest2 stat: expected 2 classes, found %d',...
                    nclasses);
    end

    if strcmp(type,'within')
        error(['ttest2 stat: the values in chunks and targets suggest '...
                    'a within-subject design. If you want to '...
                    'run a paired-test, use ''t'' (not ''t2'') ',...
                    'as the second argument']);
    end

    m1=targets==1;
    m2=targets==2;

    [stat,df]=quick_ttest2(samples(m1,:),...
                          samples(m2,:));
    cdf_label='t';
    stat_label='Ttest';

function [stat,df,stat_label]=ftest_wrapper(samples,targets,chunks,...
                                                            type,contrast)
    nclasses=max(targets);

    if nclasses<2
        error('F stat: expected >=2 classes, found %d',nclasses);
    end

    switch type
        case 'between'
            [stat,df]=quick_ftest_between(samples, targets, ...
                                        chunks,contrast);
        case 'within'
            [stat,df]=quick_ftest_within(samples, targets, ...
                                        chunks,contrast);

    end
    stat_label='Ftest';


function [f,df]=quick_ftest_between(samples,targets,chunks,contrast)
    % one-way ANOVA
    has_contrast=~isempty(contrast);
    contrast_sum=0;

    nclasses=max(targets);

    [ns,nf]=size(samples);
    mu=sum(samples,1)/ns; % grand mean

    b=zeros(nclasses,nf); % between-class sum of squares
    nsc=zeros(nclasses,1);
    wss=0; % within-class sum of squares

    for k=1:nclasses
        msk=k==targets;

        nsc(k)=sum(msk); % number of samples in this class
        sample=samples(msk,:);
        muc=sum(sample,1)/nsc(k); % class mean

        % between- and within-class sum of squares
        if has_contrast
            cmsk=contrast(msk);
            if ~all(cmsk(1)==cmsk)
                error('Contrast has differerent values in level %d',k);
            end
            contrast_sum=contrast_sum+cmsk(1);
            b(k,:)=sum(bsxfun(@times,contrast(msk),mu-muc),1);
        else
            b(k,:)=(mu-muc);
        end
        wss=wss+sum(bsxfun(@minus,muc,sample).^2,1);
    end

    if has_contrast
        if contrast_sum~=0
            error('contrast has sum %d, should be 0', contrast_sum);
        end
        bss=sum(b,1).^2/sum(contrast.^2);
        df1=1;
    else
        bss=sum(bsxfun(@times,nsc,b.^2),1);
        df1=nclasses-1;
    end

    df=[df1,ns-nclasses];

    mbss=bss/df(1);
    mwss=wss/df(2);

    f=mbss./mwss;

function [f,df]=quick_ftest_within(samples,targets,chunks,contrast)
    % repeated measures anova
    if ~isempty(contrast)
        error('contrast is not supported for within-subject design');
    end

    nchunks=max(chunks);
    nclasses=max(targets);

    nfeatures=size(samples,2);
    gm=mean(samples,1); % grand mean

    sst=zeros(1,nfeatures);
    ssw=zeros(1,nfeatures);
    for k=1:nclasses
        xk=samples(k==targets,:);
        n=size(xk,1);
        mu=mean(xk,1);
        sst=sst+n*(gm-mu).^2;
        ssw=ssw+sum(bsxfun(@minus,mu,xk).^2);
    end

    sss=zeros(1,nfeatures);
    for k=1:nchunks
        xk=samples(k==chunks,:);
        n=size(xk,1);
        mu=mean(xk,1);
        sss=sss+n*(gm-mu).^2;
    end

    df1=(nclasses-1);
    mst=sst/df1;

    df2=df1*(nchunks-1);
    sse=ssw-sss;
    mse=sse/df2;
    f=mst./mse;
    df=[df1 df2];



function [t,df]=quick_ttest(x)
    % one-sample t-test against zero

    n=size(x,1);
    mu=sum(x,1)/n; % grand mean

    df=n-1;
    scaling=n*df;

    % sum of squares
    ss=sum(bsxfun(@minus,x,mu).^2,1);

    t=mu .* sqrt(scaling./ss);


function [t,df]=quick_ttest2(x,y)
    % two-sample t-test with equal variance assumption

    nx=size(x,1);
    ny=size(y,1);
    mux=sum(x,1)/nx; % mean of class x
    muy=sum(y,1)/ny; % "           " y

    df=nx+ny-2;
    scaling=(nx*ny)*df/(nx+ny);

    % sum of squares
    ss=sum([bsxfun(@minus,x,mux);bsxfun(@minus,y,muy)].^2,1);

    t=(mux-muy) .* sqrt(scaling./ss);

function y=cdf_wrapper(name, x, df1, df2)
    ensure_has_stats_toolbox();
    switch name
        case 'Ttest'
            assert(nargin==3);
            y=tcdf(x, df1);
        case 'Ftest'
            assert(nargin==4);
            y=fcdf(x, df1, df2);
        otherwise
            assert(false);
    end


function y=norminv_wrapper(x)
    ensure_has_stats_toolbox();
    y=norminv(x);

function ensure_has_stats_toolbox()
    % - Octave has the required functionality in the octave-forge
    %   statistics toolbox and will raise an error if it is not installed.
    % - Matlab needs checking for the toolbox
    if cosmo_wtf('is_matlab')
        cosmo_check_external('@stats');
    end

function [samples,targets,chunks,type]=get_descriptors(ds)
    cosmo_isfield(ds,{'samples','sa.chunks','sa.targets'},true);

    samples=ds.samples;

    % unique targets
    [unused,unusued,targets]=unique(ds.sa.targets);

    % unique chunks
    [unq_chunks,unusued,chunks]=unique(ds.sa.chunks);
    nc=max(chunks);

    if isequal(sort(ds.sa.chunks),unq_chunks)
        type='between';
    else
        combis=(targets-1)*nc+chunks;
        if isequal(sort(combis),(1:numel(combis))')
            type='within';
        else
            error(['Either all chunks must be unique, or each chunk '...
                        'must contain the same targets']);
        end
    end

function delta=pairwise_differences(samples,targets,chunks)
    % for one-sample t-test: compute differences between first and second
    % chunk
    n=size(samples,1);
    assert(numel(targets)==n);
    assert(numel(chunks)==n);

    assert(mod(n,2)==0);
    n2=n/2;

    idxs=zeros(n2,2);
    for k=1:n
        assert(idxs(chunks(k),targets(k))==0);
        idxs(chunks(k),targets(k))=k;
    end
    assert(isequal(size(idxs),[n2,2]));
    assert(all(idxs(:)>0));

    delta=samples(idxs(:,1),:)-samples(idxs(:,2),:);

function [output_stat_name,tail]=get_stat_definition(stat_name,...
                                                    output_stat_name)
    if any(cosmo_match({'left','right','both'},output_stat_name))
        tail=output_stat_name;
        output_stat_name='p';
    elseif strcmp(output_stat_name,'p')
        switch stat_name
            case 'F'
                tail='right'; % show anova1  behaviour w.r.t. p-values
            otherwise
                tail='both'; % show ttest[2] "                       "
        end
    else
        tail='both';
    end

