function test_suite=test_phase_stat
% tests for test_phase_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function r=randint()
    r=ceil(rand()*10+10);

function test_phase_stat_basic_balanced_trials
    r=randint();

    % test with both balanced and unbalanced number of trials
    helper_test_phase_stat_with_trial_counts(r,r);


function test_phase_stat_basic_unbalanced_trials
    names={'pos','pop','pbi'};
    for k=1:numel(names)
        name=names{k};
        for delta=[-1,0,1]
            r=randint();
            ds=generate_phase_dataset(r,r+delta);
            opt=struct();
            opt.output=name;

            func=@()cosmo_phase_stat(ds,opt);
            is_balanced=delta==0;
            if is_balanced
                % should be ok
                func();
            else
                assertExceptionThrown(func,'');
            end
        end
    end

function helper_test_phase_stat_with_trial_counts(ntrials1,ntrials2)
    ds=generate_phase_dataset(ntrials1,ntrials2);

    names={'pos','pop','pbi'};
    for k=1:numel(names)
        name=names{k};

        helper_test_phase_stat_with_name(ds,name);
    end


function helper_test_phase_stat_with_name(ds,stat_name)
    opt=struct();
    opt.output=stat_name;
    % compute result
    result=cosmo_phase_stat(ds,opt);

    % compute expected result
    samples=ds.samples;

    t1=find(ds.sa.targets==1);
    t2=find(ds.sa.targets==2);

    assert(numel(t1)==numel(t2));

    itc1=compute_itc(samples(t1,:));
    itc2=compute_itc(samples(t2,:));
    itc_all=compute_itc(samples);

    expected_samples=compute_phase_stat(stat_name,itc1,itc2,itc_all);

    % verify output matches expected output
    assertElementsAlmostEqual(result.samples,expected_samples);
    assertEqual(ds.a,result.a);
    assertEqual(ds.fa,result.fa);
    assertEqual(struct(),result.sa);

function test_phase_stat_with_signal()
    names={'pos','pop','pbi'};
    for k=1:numel(names)
        name=names{k};

        helper_test_phase_stat_with_signal_with_name(name);
    end


function helper_test_phase_stat_with_signal_with_name(name)
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',50);
    nsamples=size(ds.samples,1);
    ds.sa.chunks(:)=1:nsamples;
    ds=cosmo_slice(ds,1,2);

    % use small phase angle differences
    % generally increase the distance, which should lead to an increase in
    % PBI, POS and POP
    sd=pi/100;
    signals=0:10;
    nsignals=numel(signals);

    result=zeros(nsignals,1);
    for k=1:nsignals
        for target=[1,2]
            msk=ds.sa.targets==target;
            r=rand(sum(msk),size(ds.samples,2));

            rng=r;

            if target==1
                % add increasing difference between two classes
                rng=rng+signals(k);
            end

            angle=2*pi*rng*sd;

            x=exp(1i*angle);
            ds.samples(msk,:)=x;
        end

        s=cosmo_phase_stat(ds,'output',name);
        result(k)=s.samples;
    end

    assert(cosmo_corr(result,signals')>.5);


function s=compute_phase_stat(stat_name,itc1,itc2,itc_all)
    switch stat_name
        case 'pbi'
            s=(itc1-itc_all).*(itc2-itc_all);

        case 'pop'
            s=(itc1.*itc2)-itc_all.^2;

        case 'pos'
            s=(itc1+itc2)-2*itc_all;

        otherwise
            assert(false);
    end


function itc=compute_itc(samples)
    assert(~isreal(samples))
    s=samples./abs(samples);

    itc=abs(sum(s))/size(s,1);



function idx=select_randomly(targets,value,count)
    pos=find(targets(:)==value);
    [unused,rp]=sort(rand(numel(pos),1));

    idx=pos(rp(1:count));


function ds=generate_phase_dataset(varargin)
    ndatasets=numel(varargin);
    ds_cell=cell(ndatasets,1);
    for k=1:ndatasets
        ntrials=varargin{k};

        ds_k=cosmo_synthetic_dataset('seed',0,...
                                    'nchunks',ntrials,...
                                    'ntargets',1);
        ds_k.sa.targets(:)=k;

        ds_cell{k}=ds_k;
    end

    ds=cosmo_stack(ds_cell);
    ds.sa.chunks(:)=1:numel(ds.sa.chunks);

    sz=size(ds.samples);
    ds.samples=randn(sz)+1i*randn(sz);



function test_phase_stat_exceptions
    extra_args={'output','pbi'};
    aet=@(varargin)assertExceptionThrown(...
                    @()cosmo_phase_stat(varargin{:}),'');
    aet_arg=@(varargin)aet(varargin,extra_args{:});

    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',6);
    nsamples=size(ds.samples,1);
    sz=size(ds.samples);
    ds.samples=randn(sz)+1i*randn(sz);
    ds.sa.chunks(:)=1:nsamples;
    cosmo_phase_stat(ds,extra_args{:}); % ok

    % with targets being 2 or 3 is also ok
    ds.sa.targets=ds.sa.targets+1;
    cosmo_phase_stat(ds,extra_args{:}); % ok

     % input not imaginary
    bad_ds=ds;
    bad_ds.samples=randn(sz);
    aet_arg(bad_ds);

    % chunks not all unique
    bad_ds=ds;
    bad_ds.sa.chunks(1)=bad_ds.sa.chunks(2);
    aet_arg(bad_ds);

    % imbalance is not ok.
    bad_ds=ds;
    bad_ds.sa.targets(:)=[repmat([1 2],1,5),[1 1]];
    aet_arg(bad_ds);

    % bad values for samples_are_unit_length
    bad_samples_are_unit_length_cell={[],'',1,[true false]};
    for k=1:numel(bad_samples_are_unit_length_cell)
        arg={'samples_are_unit_length',...
                    bad_samples_are_unit_length_cell{k}};
        aet_arg(ds,arg{:});
    end

    % with samples_are_unit_length=true, raise exception if some values
    % are not unit length
    aet_arg(ds,'samples_are_unit_length',true);

    % number of classes must be exactly 2
    for bad_class_count=[1,3,4]
        bad_ds=ds;
        bad_ds.sa.targets(:)=mod(1:nsamples,bad_class_count)+1;
        idx=cosmo_index_unique(bad_ds.sa.targets);
        counts=cellfun(@numel,idx);
        assert(all(counts==counts(1))); % balanced counts
        aet_arg(bad_ds);                % yet an error is raised
    end

    % no samples
    bad_ds=cosmo_slice(ds,[],1);
    aet_arg(bad_ds);

    % single sample
    bad_ds=cosmo_slice(ds,1,1);
    aet_arg(bad_ds);


    % balancer function must be function handle
    aet_arg(bad_ds,'balancer_func',struct);

    % raise exception when called without the 'output' argument, or wrong
    % output
    aet(ds);
    aet(ds,'output','foo');
    aet(ds,'output',1);





