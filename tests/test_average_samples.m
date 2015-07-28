function test_suite = test_average_samples
    initTestSuite;

function test_average_samples_
    ds=cosmo_synthetic_dataset();


    a=cosmo_average_samples(ds);

    assertElementsAlmostEqual(sort(a.samples), sort(ds.samples));
    assertElementsAlmostEqual(sort(a.samples(:,3)), sort(ds.samples(:,3)));


    a=cosmo_average_samples(ds,'ratio',.5);

    assertElementsAlmostEqual(sort(a.samples), sort(ds.samples));
    assertElementsAlmostEqual(sort(a.samples(:,3)), sort(ds.samples(:,3)));


    % check wrong inputs
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_average_samples(varargin{:}),'');

    aet(ds,'ratio',.1);
    aet(ds,'ratio',3);
    aet(ds,'ratio',.5,'count',2);

    ds.sa.chunks(:)=1;
    a=cosmo_average_samples(ds,'ratio',.5);
    a_=cosmo_fx(a,@(x)mean(x,1),'targets');
    assertEqual(a,a_);

    cosmo_check_dataset(a);

    ds=cosmo_slice(ds,3,2);
    ns=size(ds.samples,1);
    ds.samples=ds.sa.targets*1000+(1:ns)';

    a=cosmo_average_samples(ds,'ratio',.5,'nrep',10);

    % no mixing of different targets
    delta=a.samples/1000-a.sa.targets;
    assertTrue(all(.00099<=delta & delta<.05));
    assertElementsAlmostEqual(delta*3000,round(delta*3000));

    a=cosmo_average_samples(ds,'count',3,'nrep',10);
    % no mixing of different targets
    delta=a.samples/1000-a.sa.targets;
    assertTrue(all(.00099<=delta & delta<.05));
    assertElementsAlmostEqual(delta*3000,round(delta*3000));


function test_average_samples_with_repeats
    nchunks=ceil(rand()*4+3);
    ntargets=ceil(rand()*4+3);
    nrepeats=ceil(rand()*3+4);

    max_cyc=5;

    count_min=ceil(nrepeats/2);

    ds=cosmo_synthetic_dataset('nchunks',nchunks,...
                                'ntargets',ntargets,...
                                'nreps',nrepeats);
    ds.sa=rmfield(ds.sa,'rep');
    sp=cosmo_split(ds,{'targets','chunks'});
    n_splits=numel(sp);

    % select subset of samples, each with at least nrepeats_min repeats
    repeat_count=zeros(nchunks,ntargets);

    for k=1:n_splits
        if k==1
            % ensure at least one with minimum
            nkeep=count_min;
        else
            nkeep=count_min+floor(rand()*(nrepeats-count_min));
        end

        ds_k=cosmo_slice(sp{k},1:nkeep);
        ds_k.sa.repeats=(1:nkeep)';

        repeat_count(ds_k.sa.chunks(1),ds.sa.targets(1))=nkeep;

        sp{k}=ds_k;
    end

    assert(all(cellfun(@(x)size(x.samples,1),sp)));
    ds=cosmo_stack(sp);

    [nsamples,nfeatures]=size(ds.samples);

    % bit widths for features, chunks, targets, and repeats
    bws=[nfeatures,nchunks,ntargets,ceil(log2(max_cyc+1))+nrepeats];

    % encode features, chunks, targets and repeats into single number
    dsb=binarize_ds(ds,bws);


    for count=[1,ceil(rand()*count_min)];
        for repeats=[1,ceil(rand()*nrepeats)]
            mu=cosmo_average_samples(dsb,'count',count,'repeats',...
                                        repeats,'seed',1);
            [chunks,targets,ids]=unbinarize_ds(mu, bws, count);

            nsamples=size(ids,1);

            % chunk, target, repeat count
            ctr_count=zeros(nchunks,ntargets,nrepeats);


            % keep track of each target and chunk combination
            for j=1:nsamples
                for k=1:nfeatures
                    % select same samples for all features
                    id=ids{j,k};

                    if k==1
                        first_id=id;
                    else
                        assertEqual(first_id,id);
                    end
                end
                % no repeats
                id_sorted=sort(id(:));
                assert(all(diff(id_sorted)>0));

                % count should match
                assertEqual(numel(id),count);

                ctr_count(chunks(j),targets(j),id)=...
                            ctr_count(chunks(j),targets(j),id)+1;

            end

            ct_count=sum(ctr_count,3);

            assert(all(ct_count(:)==count*repeats));
        end
    end



    function [chunks,targets,ids]=unbinarize_ds(ds, bws, count)
        [nsamples, nfeatures]=size(ds.samples);

        ids=cell(nsamples,nfeatures);
        chunks=zeros(nsamples,1);
        targets=zeros(nsamples,1);

        for k=1:nsamples
            for j=1:nfeatures
                % Decode repeats; multiple repeats can be present.
                % As there can be multiple repeats, the averaging is undone
                % and then each bit represents just one repeat
                v_id=quick_dec2bin(mod(ds.samples(k,j)*count,...
                                                    2^bws(end)),...
                                                            bws(end));
                ids{k,j}=bws(end)-find(v_id)+1;

                % decode chunks, targets, ids
                v=decode(floor(ds.samples(k,j)/2^bws(end)),bws(1:(end-1)));
                assertEqual(log2(v(1))+1,j);
                c=log2(v(2))+1;
                t=log2(v(3))+1;

                if j==1
                    chunks(k)=c;
                    targets(k)=t;
                else
                    assertEqual(c,chunks(k));
                    assertEqual(t,targets(k));
                end
            end
        end


    function bds=binarize_ds(ds, bws)
        bds=ds;
        [nsamples,nfeatures]=size(ds.samples);
        for k=1:nsamples
            sa=cosmo_slice(ds.sa,k,1,'struct');
            for j=1:nfeatures
                vs=[j, sa.chunks sa.targets sa.repeats];

                bds.samples(k,j)=encode(vs,bws);
            end
        end

    function p=encode(vs, bws)
    % encode several decimal numbers in a single one, through
    %     encode([X1 ... Xn]) = bin2dec([dec2bin(X1) ... dec2bin(Xn)])
    % where bws contains the bit width for each number
        n=numel(bws);
        assert(numel(vs)==n);

        bs=cell(1,n);
        for k=1:n
            bw=bws(k);
            bs{k}=zeros(1,bw);
            bs{k}(bw-vs(k)+1)=1;
        end

        p=quick_bin2dec(cat(2,bs{:}));


    function vs=decode(p, bws)
    % encode single decimal numbers in multiple ones, through
    %     decode(P) = [bin2dec(PB1) ... bin2dec(PBn)]
    %     with PBi the binary representation part of P for each binary
    %     representation part

        arr=quick_dec2bin(p,sum(bws));

        c=0;
        n=numel(bws);
        vs=zeros(1,n);
        for k=1:n
            offset=bws(k);
            vs(k)=quick_bin2dec(arr(c+(1:offset)));
            c=c+offset;
        end


    function arr=quick_dec2bin(x,bw)
        % converts decimal number x to array with length bw and all
        % values in 0 and 1
        assert(round(x)==x);
        arr=zeros(1,bw);

        xbs=dec2bin(x);
        arr(bw-numel(xbs)+1:end)=(xbs=='1');
        return


    function x=quick_bin2dec(arr)
        % convert binary array to decimal number
        x=sum(2.^((numel(arr)-1):-1:0).*arr);
