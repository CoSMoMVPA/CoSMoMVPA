function test_suite = test_stat
% tests for cosmo_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_stat_correspondence
    is_matlab=cosmo_wtf('is_matlab');

    if isempty(which('ttest'))
        cosmo_notify_test_skipped('ttest is not available');
        return
    end

    % test conformity with matlab's stat functions
    ds=cosmo_synthetic_dataset('nchunks',5,'ntargets',4,'sigma',0);
    ds=cosmo_slice(ds,[2 5 6],2);
    [ns,nf]=size(ds.samples);

    f=zeros(1,nf);
    p=zeros(1,nf);


    for k=1:nf
        if is_matlab
            [p(k),tab]=anova1(ds.samples(:,k), ds.sa.targets, 'off');
            f(k)=tab{2,5};
            df=[tab{2:3,3}];
        else
            [p(k),f(k),df_b,df_w]=anova(ds.samples(:,k), ds.sa.targets);
            df=[df_b df_w];
        end
    end
    % f stat

    ds.sa.chunks=(1:ns)';
    ff=cosmo_stat(ds,'F');
    assertVectorsAlmostEqual(f,ff.samples);
    assertEqual(ff.sa.stats,{sprintf('Ftest(%d,%d)',df)});

    pp=cosmo_stat(ds,'F','p');
    assertVectorsAlmostEqual(p,pp.samples);

    ds.sa.chunks(:)=1;
    assertExceptionThrown(@()cosmo_stat(ds,'F'),'');

    % t stat
    tails={'p','left','right','both'};
    for k=1:numel(tails)
        % one-sample ttest
        assertExceptionThrown(@()cosmo_stat(ds,'t'),'');
        ds1=ds;
        ds1.sa.targets(:)=10;
        ds1.sa.chunks=(1:ns)';

        tail=tails{k};


        if strcmp(tail,'p')
            ttest_arg=cell(0);
        else
            ttest_arg={'tail',tail};
        end

        % test t-statistic
        [h,p,ci,stats]=ttest_wrapper(ds.samples,0,ttest_arg{:});

        tt=cosmo_stat(ds1,'t');
        assertVectorsAlmostEqual(stats.tstat,tt.samples);
        assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});

        pp=cosmo_stat(ds1,'t',tail);
        assertVectorsAlmostEqual(p,pp.samples);

        ds1.sa.chunks(:)=1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t'),'');

        % two-sample (unpaired) ttest
        ds2=ds;
        i=randperm(ns)';
        ds2.sa.targets=mod(i,2)+1;
        ds2.sa.chunks=i;
        ds_sp=cosmo_split(ds2,'targets');
        x=ds_sp{1}.samples;
        y=ds_sp{2}.samples;

        [h,p,ci,stats]=ttest2_wrapper(x,y,ttest_arg{:});
        tt=cosmo_stat(ds2,'t2');

        assertVectorsAlmostEqual(stats.tstat,tt.samples);
        assertEqual(tt.sa.stats,{sprintf('Ttest(%d)',stats.df(1))});


        pp=cosmo_stat(ds2,'t2',tail);
        assertVectorsAlmostEqual(p,pp.samples);

        ds2.sa.chunks(1)=ds2.sa.chunks(1)+1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');

        ds2.sa.chunks(1)=ds2.sa.chunks(1)-1;
        ds2.sa.targets(1)=ds2.sa.targets(1)+1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');
        ds2.sa.targets(:)=1;
        assertExceptionThrown(@()cosmo_stat(ds1,'t2'),'');

    end

    assertExceptionThrown(@()cosmo_stat(ds,'t2'),'');
    assertExceptionThrown(@()cosmo_stat(ds,'t'),'');


function test_stat_contrast()
    ds=cosmo_synthetic_dataset('nchunks',6,'ntargets',4,'sigma',0);
    ds.sa.contrast=zeros(size(ds.sa.targets));
    ds.sa.contrast(ds.sa.targets==2)=1;
    ds.sa.contrast(ds.sa.targets==4)=-1;
    chunks=ds.sa.chunks;
    ds.sa.chunks=chunks*6+ds.sa.targets;

    res=cosmo_stat(ds,'F','z');
    assertElementsAlmostEqual(res.samples,...
                    [0.2695 0.9675 -0.8770 -1.0542 0.9173 1.2814],...
                    'absolute',1e-4);

    % test exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_stat(varargin{:}),'');

    ds2=cosmo_slice(ds,ds.sa.contrast~=0);
    aet(ds2,'t');
    aet(ds2,'t2');

    ds.sa.contrast(1)=1;
    aet(ds,'F');

    ds.sa.contrast(ds.sa.targets==1)=1;
    aet(ds,'F');

    % within subject F
    ds.sa.chunks=chunks;
    aet(ds,'F');
    aet(ds,'t');
    aet(ds,'t2');

function [h,p,ci,stats]=ttest_wrapper(varargin)
    [h,p,ci,stats]=general_ttestX_wrapper(@ttest,varargin{:});

function [h,p,ci,stats]=ttest2_wrapper(varargin)
    [h,p,ci,stats]=general_ttestX_wrapper(@ttest2,varargin{:});

function [h,p,ci,stats]=general_ttestX_wrapper(func,varargin)
    args=varargin;
    switch nargin(func)
        case {5,6}
            % old Matlab
            args=remove_keys_from_arguments(2,{'alpha','tail','dim'},args);
        case -3
            % GNU Octave and recent Matlab

        otherwise
            assert(false);
    end

    [h,p,ci,stats]=func(args{:});

function short_args=remove_keys_from_arguments(skip_count,keys,args)
    n=numel(keys);
    short_args=cell(1,skip_count+n);
    short_args(1:skip_count)=args(1:skip_count);
    for k=1:n
        key=keys{k};
        i=strmatch(key,args((skip_count+1):2:end));
        if isempty(i)
            short_arg=[];
        else
            short_arg=args{skip_count+i*2};
        end
        short_args{skip_count+k}=short_arg;
    end




function test_stat_exceptions()
    ds=cosmo_synthetic_dataset('ntargets',3);
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_stat(varargin{:}),'');
    aet(ds,'foo');
    aet(ds,'F','foo');
    aet(ds,'t');

    ds2=cosmo_slice(ds,ds.sa.targets==1);
    aet(ds2,'F');
    aet(ds2,'t2');


function test_stat_regression()
    ds=cosmo_synthetic_dataset('nchunks',6,'ntargets',4,'sigma',0);
    ds=cosmo_slice(ds,[2 6],2);

    params=get_stat_regression_params();
    for k=1:numel(params)
        param=params{k};

        args=param{1};
        targets=param{2}{1};
        is_between=param{2}{2};
        should_raise_error=param{2}{3};

        ds_sel=cosmo_slice(ds,cosmo_match(ds.sa.targets,targets));

        if is_between
            ds_sel.sa.chunks=ds_sel.sa.chunks+6*ds_sel.sa.targets;
        end

        stat_func=@()cosmo_stat(ds_sel,args{:});
        if should_raise_error
            assertExceptionThrown(stat_func,'');
            continue;
        end

        result=stat_func();

        samples=param{3}{1};
        assertElementsAlmostEqual(result.samples,samples,'absolute',1e-4);
        stat_sa=struct();
        stat_sa.stats=param{3}(2);
        assertEqual(result.sa,stat_sa);

        % test errors for wrong assignment of chunks and targets
        if is_between
            ds_sel.sa.chunks(1)=ds_sel.sa.chunks(2);
            assertExceptionThrown(@()cosmo_stat(ds_sel,args{:}),'');
        else
            ds_sel.sa.chunks(ds_sel.sa.chunks==2)=1;
            assertExceptionThrown(@()cosmo_stat(ds_sel,args{:}),'');
        end

    end


function params=get_stat_regression_params()
    % parameters to test regressions in stat test; format:
    % {{stat_name, output_stat_name},...
    %   {targets,is_between_test,should_raise_error},...
    %   {samples,.sa.stats{}}}
    %
    % based on input dataset generated by:
    % ds=cosmo_synthetic_dataset('nchunks',6,'ntargets',4,'sigma',0);
    % ds=cosmo_slice(ds,[2 6],2);
    params={{{'F',''},...
	{[1 2 3 4 ],0,0}...
	{[1.63475 2.00315],'Ftest(3,15)'}}
{{'F','z'},...
	{[1 2 3 4 ],0,0}...
	{[0.76051 1.00751],'Zscore()'}}
{{'F','p'},...
	{[1 2 3 4 ],0,0}...
	{[0.22348 0.15684],'Pval()'}}
{{'F','left'},...
	{[1 2 3 4 ],0,0}...
	{[0.77652 0.84316],'Pval()'}}
{{'F','right'},...
	{[1 2 3 4 ],0,0}...
	{[0.22348 0.15684],'Pval()'}}
{{'F','both'},...
	{[1 2 3 4 ],0,0}...
	{[0.44695 0.31369],'Pval()'}}
{{'t2',''},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t2','z'},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t2','p'},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t2','left'},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t2','right'},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t2','both'},...
	{[3 4 ],0,1}...
	'<should raise error>'}
{{'t',''},...
	{[3 4 ],0,0}...
	{[-0.47494 -0.73292],'Ttest(5)'}}
{{'t','z'},...
	{[3 4 ],0,0}...
	{[-0.44704 -0.68000],'Zscore()'}}
{{'t','p'},...
	{[3 4 ],0,0}...
	{[0.65485 0.49650],'Pval()'}}
{{'t','left'},...
	{[3 4 ],0,0}...
	{[0.32742 0.24825],'Pval()'}}
{{'t','right'},...
	{[3 4 ],0,0}...
	{[0.67258 0.75175],'Pval()'}}
{{'t','both'},...
	{[3 4 ],0,0}...
	{[0.65485 0.49650],'Pval()'}}
{{'F',''},...
	{[1 2 3 4 ],1,0}...
	{[1.84801 1.07461],'Ftest(3,20)'}}
{{'F','z'},...
	{[1 2 3 4 ],1,0}...
	{[0.95018 0.29948],'Zscore()'}}
{{'F','p'},...
	{[1 2 3 4 ],1,0}...
	{[0.17101 0.38229],'Pval()'}}
{{'F','left'},...
	{[1 2 3 4 ],1,0}...
	{[0.82899 0.61771],'Pval()'}}
{{'F','right'},...
	{[1 2 3 4 ],1,0}...
	{[0.17101 0.38229],'Pval()'}}
{{'F','both'},...
	{[1 2 3 4 ],1,0}...
	{[0.34202 0.76457],'Pval()'}}
{{'t2',''},...
	{[3 4 ],1,0}...
	{[-0.51279 -0.50269],'Ttest(10)'}}
{{'t2','z'},...
	{[3 4 ],1,0}...
	{[-0.49693 -0.48727],'Zscore()'}}
{{'t2','p'},...
	{[3 4 ],1,0}...
	{[0.61924 0.62607],'Pval()'}}
{{'t2','left'},...
	{[3 4 ],1,0}...
	{[0.30962 0.31303],'Pval()'}}
{{'t2','right'},...
	{[3 4 ],1,0}...
	{[0.69038 0.68697],'Pval()'}}
{{'t2','both'},...
	{[3 4 ],1,0}...
	{[0.61924 0.62607],'Pval()'}}
{{'t',''},...
	{[4 ],1,0}...
	{[-0.65552 0.32687],'Ttest(5)'}}
{{'t','z'},...
	{[4 ],1,0}...
	{[-0.61117 0.30942],'Zscore()'}}
{{'t','p'},...
	{[4 ],1,0}...
	{[0.54109 0.75700],'Pval()'}}
{{'t','left'},...
	{[4 ],1,0}...
	{[0.27055 0.62150],'Pval()'}}
{{'t','right'},...
	{[4 ],1,0}...
	{[0.72945 0.37850],'Pval()'}}
{{'t','both'},...
	{[4 ],1,0}...
	{[0.54109 0.75700],'Pval()'}}};
