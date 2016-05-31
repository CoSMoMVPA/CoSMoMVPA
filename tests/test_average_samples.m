function test_suite = test_average_samples
% tests for cosmo_average_samples
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

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


function test_average_samples_split_by
    plural_singular={'targets','targets';...
                     'chunks','chunks';...
                     'subjects','subject';...
                     'modalities','modality';...
                    };
    n_dim=size(plural_singular,1);

    combis=cosmo_cartprod(repmat({{true,false}},n_dim,1)');
    for k=1:size(combis,1);
        combi=cell2mat(combis(k,:));
        opt=struct();
        opt.seed=0; % truly random data
        for j=1:n_dim
            count=ceil(rand()*2+1);
            opt.(['n' plural_singular{j,1}])=count;
        end

        ds=cosmo_synthetic_dataset(opt);

        values=cell(n_dim,1);
        for j=1:n_dim
            if combi(j)
                values{j}=ds.sa.(plural_singular{j,2});
            end
        end
        values=values(combi);
        if any(combi)
            [idx,unq_cell]=cosmo_index_unique(values);
        else
            idx={1:(size(ds.samples,1))};
        end
        n_avg=numel(idx);
        n_features=size(ds.samples,2);
        expected_samples=zeros(n_avg,n_features);
        for m=1:n_avg
            expected_samples(m,:)=mean(ds.samples(idx{m},:),1);
        end

        result=cosmo_average_samples(ds,...
                            'split_by',plural_singular(combi,2));


        assertEqual(size(result.samples),size(expected_samples));
        delta=bsxfun(@minus,result.samples(:,1),expected_samples(:,1)');
        mapping=zeros(1,n_avg);
        for m=1:n_avg
            [mn,mn_idx]=min(abs(delta(m,:)));
            assert(mn<1e-5); % deal with rounding
            mapping(mn_idx)=m;
        end
        assertEqual(sort(mapping),1:n_avg);

        result_perm=cosmo_slice(result,mapping);
        assertElementsAlmostEqual(result_perm.samples,expected_samples);

        pos=0;
        for j=1:n_dim
            if combi(j)
                pos=pos+1;
                fn=plural_singular{j,2};
                assertEqual(unq_cell{pos},result_perm.sa.(fn));
            end
        end


        % check default result
        if isequal(plural_singular(combi),{'targets','chunks'});
            default_result=cosmo_average_samples(ds);
            assertEqual(result,default_result);
        end

    end


function test_average_samples_split_by_empty()
    ds=cosmo_synthetic_dataset('ntargets',ceil(rand()*5+2),...
                                'nchunks',ceil(rand()*5+2));
    result=cosmo_average_samples(ds,'split_by',{});
    assertElementsAlmostEqual(result.samples,mean(ds.samples,1));


function test_average_samples_exceptions
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_average_samples(varargin{:}),'');
    ds=cosmo_synthetic_dataset('nreps',5);

    aet([]);
    x=struct();
    x.samples=randn(4);
    aet(x);


    % illegal count
    aet(ds,'count',6)
    aet(ds,'count',[2 2])
    aet(ds,'count',3.5);
    aet(ds,'count',0);

    % illegal ratio
    aet(ds,'ratio',1.2)
    aet(ds,'ratio',-0.2);
    aet(ds,'ratio',[.5 .5]);

    % mutually exclusive
    aet(ds,'ratio',.5,'count',2);

    aet(ds,'repeats',[2 2])
    aet(ds,'repeats',-1);
    aet(ds,'resamplings',[2 2]);
    aet(ds,'resamplings',-1);
    aet(ds,'resamplings',1,'repeats',1);

    % not existing field
    ds_bad=ds;
    ds_bad.sa=rmfield(ds_bad.sa,'targets');
    aet(ds_bad);

    % illegal split-by arguments
    aet(ds,'split_by',[]);
    aet(ds,'split_by',struct());
    aet(ds,'split_by','foo');
    aet(ds,'split_by',{1,2});



function test_average_samples_with_repeats
    nchunks=ceil(rand()*4+3);
    ntargets=ceil(rand()*4+3);
    ncombi_max=ceil(rand()*3+4);

    max_cyc=5;

    ncombi_min=ceil(ncombi_max/2);

    ds=cosmo_synthetic_dataset('nchunks',nchunks,...
                                'ntargets',ntargets,...
                                'nreps',ncombi_max);
    ds.sa=rmfield(ds.sa,'rep');
    sp=cosmo_split(ds,{'targets','chunks'});
    n_splits=numel(sp);

    % select subset of samples, each with at least ncombi_min repeats
    combi_count=zeros(nchunks,ntargets);

    for k=1:n_splits
        if k==1
            % ensure at least one with minimum
            nkeep=ncombi_min;
        else
            nkeep=ncombi_min+floor(rand()*(ncombi_max-ncombi_min));
        end

        ds_k=cosmo_slice(sp{k},1:nkeep);
        ds_k.sa.repeats=(1:nkeep)';

        combi_count(ds_k.sa.chunks(1),ds_k.sa.targets(1))=nkeep;

        sp{k}=ds_k;
    end

    assert(all(cellfun(@(x)size(x.samples,1),sp)));
    ds=cosmo_stack(sp);

    [nsamples,nfeatures]=size(ds.samples);

    % bit widths for features, chunks, targets, and repeats
    bws=[nfeatures,nchunks,ntargets,ceil(log2(max_cyc+1))+ncombi_max];

    % encode features, chunks, targets and repeats into single number
    dsb=binarize_ds(ds,bws);

    % helper function
    check_with=@(args,...
                 count,...
                 repeats) check_with_helper(dsb,args,count,repeats,...
                                                nchunks,ntargets,...
                                                ncombi_max,combi_count,...
                                                bws);

    for repeats=[1,ceil(rand()*ncombi_max)]
        for count=[1,ceil(rand()*ncombi_min)];
            check_with({'count',count,'repeats',repeats},...
                                        count,repeats);
        end
        for ratio=[.5,.3+rand()*.7];
            count=round(ratio*min(combi_count(:)));
            check_with({'ratio',ratio,'repeats',repeats},...
                                        count,repeats);
        end
    end

    for resamplings=[0,1,2+round(rand()*4)]
        count=ceil(rand()*ncombi_min);
        if resamplings==0
            repeats=floor(ncombi_min/count);
            args={'count',count};
        else
            repeats=floor(resamplings*ncombi_min/count);
            args={'count',count,'resamplings',resamplings};
        end

        check_with(args,count,repeats);
    end




function  check_with_helper(dsb, args, count, repeats,...
                    nchunks, ntargets, ncombi_max, combi_count, bws)

    mu=cosmo_average_samples(dsb,args{:});
    [chunks,targets,ids]=unbinarize_ds(mu, bws, count);

    nsamples=size(ids,1);
    nfeatures=size(dsb.samples,2);

    % chunk, target, repeat count
    ctr_count=zeros(nchunks,ntargets,ncombi_max);


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

    % ensure each sample selected about equally often
    [nchunks,ntargets]=size(combi_count);
    for k=1:nchunks
        for j=1:ntargets
            c=squeeze(ctr_count(k,j,:));

            pre=c(1:combi_count(k,j));
            assert(max(pre)-min(pre)<=1);

            post=c((combi_count(k,j)+1):end);
            assert(all(post==0));
        end
    end

    % check each target and chunk combination was used the correct number
    % of times to form the average
    ct_count=sum(ctr_count,3);

    expected_ct_count=count*repeats*ones(nchunks,ntargets);

    assert(isequal(ct_count, expected_ct_count));


function [chunks,targets,ids]=unbinarize_ds(ds, bws, counts)
    [nsamples, nfeatures]=size(ds.samples);

    ids=cell(nsamples,nfeatures);
    chunks=zeros(nsamples,1);
    targets=zeros(nsamples,1);

    for k=1:nsamples
        for j=1:nfeatures
            % Decode repeats; multiple repeats can be present.
            % As there can be multiple repeats, the averaging is undone
            % and then each bit represents just one repeat
            v_id=quick_dec2bin(mod(ds.samples(k,j)*counts,...
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
