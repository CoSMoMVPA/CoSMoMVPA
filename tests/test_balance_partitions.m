function test_suite=test_balance_partitions
    initTestSuite;

function test_balance_partitions_repeats
    nchunks=5;
    nsamples=200;
    nclasses=4;
    [p,ds]=get_sample_data(nsamples,nchunks,nclasses);


    for pos=[0 1 5]
        if pos==0
            nrep=1;
            args={};
        else
            nrep=pos;
            args={'nrepeats',nrep};
        end

        b=cosmo_balance_partitions(p,ds,args{:});

        assertEqual(numel(b.train_indices),nrep*nchunks);
        assertEqual(numel(b.test_indices),nrep*nchunks);
        assertEqual(fieldnames(b),{'train_indices';'test_indices'});

        nfolds=numel(p.test_indices);
        for j=1:nfolds
            pi=p.train_indices{j};
            pt=ds.sa.targets(pi);
            pc=ds.sa.chunks(pi);

            for k=1:nrep
                bi=b.train_indices{(j-1)*nrep+k};
                bt=ds.sa.targets(bi);
                bc=ds.sa.chunks(bi);
                assertEqual(unique(bt)',1:nclasses);
                h=histc(bt,1:nclasses)';
                assertTrue(all(min(histc(pt,1:nclasses))==h));

                % no new targets introduced
                assertEqual(setdiff(bt,pt),zeros(0,1));

                % no double dipping
                assertEqual(unique(pc),unique(bc));
            end
        end
    end


function test_balance_partitions_nmin
    nchunks=5;
    nsamples=200;
    nclasses=4;
    [p,ds]=get_sample_data(nsamples,nchunks,nclasses);

    nmin=10;
    args={'nmin',nmin};
    b=cosmo_balance_partitions(p,ds,args{:});

    counter=zeros(nsamples,nchunks);

    for j=1:numel(b.train_indices)
        bi=b.train_indices{j};
        bj=b.test_indices{j};

        ch=unique(ds.sa.chunks(bj));
        assert(numel(ch)==1);

        assertEqual(bj,p.test_indices{ch});

        bt=ds.sa.targets(bi);

        h=histc(bt,1:nclasses);
        assertEqual(ones(nclasses,1)*h(1),h);

        counter(bi,ch)=counter(bi,ch)+1;
    end

    for k=1:nchunks
        msk=ds.sa.chunks~=k;
        assert(min(counter(msk,k))>=nmin);
        assert(all(counter(~msk,k)==0));
    end

function test_balance_partitions_exceptions

    ds=cosmo_synthetic_dataset();
    p=cosmo_nfold_partitioner(ds);
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_balance_partitions(varargin{:}),'');

    aet(struct,struct)
    aet(ds,p);

    aet(p,ds,'nmin',1,'nrepeats',1);

    % missing target
    p.train_indices{1}=p.train_indices{1}([1 3]);
    aet(p,ds);

    % double dipping
    p.train_indices{1}=p.train_indices{2};
    aet(p,ds);


function [p,ds]=get_sample_data(nsamples,nchunks,nclasses)


    ds=struct();
    ds.samples=(1:nsamples)';
    ds.sa.targets=ceil(cosmo_rand(nsamples,1)*nclasses);
    ds.sa.chunks=ceil(cosmo_rand(nsamples,1)*nchunks);

    p=cosmo_nfold_partitioner(ds);
