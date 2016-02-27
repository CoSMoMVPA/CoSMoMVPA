function test_suite = test_partitions
% tests for partitioning functions
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_nfold_partitioner()
    ds=cosmo_synthetic_dataset('nchunks',5,'ntargets',4);

    p=cosmo_nfold_partitioner(ds);
    assertEqual(p, cosmo_nfold_partitioner(ds.sa.chunks));

    fns={'train_indices';'test_indices'};
    assertEqual(fns, fieldnames(p));
    for k=1:5
        test_indices=(k-1)*4+(1:4);
        train_indices=setdiff(1:20,test_indices);
        for j=1:2
            fn=fns{j};
            if j==1
                v=train_indices;
            else
                v=test_indices;
            end
            w=p.(fn);
            assertEqual(w{k}, v');
        end
    end

function test_nchoosek_partitioner()
    ds=cosmo_synthetic_dataset('nchunks',5,'ntargets',4);

    p=cosmo_nfold_partitioner(ds);
    q=cosmo_nchoosek_partitioner(ds,1);
    assertEqual(p,q);

    q=cosmo_nchoosek_partitioner(ds,.2);
    assertEqual(p,q);


    p=cosmo_nchoosek_partitioner(ds,3);
    q=cosmo_nchoosek_partitioner(ds,.6);

    assertEqual(p,q);
    assertFalse(isequal(p, cosmo_nchoosek_partitioner(ds,.4)));

    q2=cosmo_nchoosek_partitioner(ds.sa.chunks,3);
    assertEqual(p,q2);

    fns={'train_indices';'test_indices'};
    for j=1:2
        fn=fns{j};
        counts=zeros(20,1);

        v=p.(fn);
        assertEqual(size(v),[1 10]);

        for k=1:numel(v)
            w=v{k};
            counts(w)=counts(w)+1;
        end
        assertEqual(counts,ones(20,1)*j*2+2);
    end

function test_nchoosek_partitioner_half()
    offsets=[0 floor(rand()*10+20)];
    for offset=offsets
        for nchunks=2:4:10

            ds=cosmo_synthetic_dataset('nchunks',nchunks,'ntargets',3);
            ds.sa.chunks=ds.sa.chunks+offset;

            p=cosmo_nchoosek_partitioner(ds,'half');
            combis=nchoosek(1:nchunks,nchunks/2);

            n=size(combis,1);
            assertEqual(numel(p.train_indices),n/2);
            assertEqual(numel(p.test_indices),n/2);

            for k=1:n/2
                tr_idx=find(cosmo_match(ds.sa.chunks-offset,...
                                                        combis(k,:)));
                te_idx=find(cosmo_match(ds.sa.chunks-offset,...
                                                        combis(n-k+1,:)));

                assertEqual(p.train_indices{k},tr_idx);
                assertEqual(p.test_indices{k},te_idx);
            end
        end
    end



function test_nchoosek_partitioner_grouping()
    for nchunks=[2 5]
        ds=cosmo_synthetic_dataset('nchunks',nchunks,'ntargets',6);
        ds.sa.modality=mod(ds.sa.targets,2)+1;
        ds.sa.targets=floor(ds.sa.targets/2);

        for n_test=1:(nchunks-1)
            for moda_idx=1:4

                if moda_idx==3
                    modas={1 2};
                    moda_arg={1 2};
                elseif moda_idx==4
                    modas={1,2};
                    moda_arg=[];
                else
                    modas={moda_idx};
                    moda_arg=moda_idx;
                end

                n_moda=numel(modas);

                p=cosmo_nchoosek_partitioner(ds,n_test,'modality',...
                                                            moda_arg);
                combis=nchoosek(1:nchunks,n_test);
                n_combi=size(combis,1);

                n_folds=numel(p.train_indices);
                assertEqual(numel(p.test_indices),n_folds);
                assertEqual(n_folds,n_combi*n_moda);

                % each fold must be present exactly once
                visited_count=zeros(1,n_folds);
                for m=1:n_moda
                    for j=1:n_combi
                        tr_msk=~cosmo_match(ds.sa.chunks,combis(j,:)) & ...
                                    ~cosmo_match(ds.sa.modality,modas{m});
                        te_msk=cosmo_match(ds.sa.chunks,combis(j,:)) & ...
                                    cosmo_match(ds.sa.modality,modas{m});
                        tr_idx=find_fold(p.train_indices,tr_msk);
                        te_idx=find_fold(p.test_indices,te_msk);
                        assertEqual(tr_idx,te_idx);
                        visited_count(tr_idx)=visited_count(tr_idx)+1;
                    end
                end

                assertEqual(visited_count,ones(1,n_folds));

                % also possible with indices
                p2=cosmo_nchoosek_partitioner(ds.sa.chunks,n_test,...
                                            ds.sa.modality,moda_arg);
                assertEqual(p,p2);


            end
        end
    end

function pos=find_fold(folds, msk)
    idxs=find(msk);
    n=numel(folds);

    pos=[];
    for k=1:n
        if isequal(sort(folds{k}(:)),sort(idxs(:)))

            % no duplicates
            assert(isempty(pos));
            pos=k;
        end
    end
    assert(~isempty(pos));


function assert_disjoint(vs,i,j)
    common=intersect(vs(i),vs(j));
    if ~isempty(common)
        assertFalse(true,sprintf('element in common: %d', common(1)));

    end
function test_nchoosek_partitioner_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_nchoosek_partitioner(varargin{:}),'');
    for nchunks=2:3
        ds=cosmo_synthetic_dataset('nchunks',nchunks,'ntargets',4);


        aet(ds,-1);
        aet(ds,0);
        aet(ds,1.01);
        aet(ds,[1 1]);
        aet(ds,.99);
        aet(struct,1);
        aet(ds,'foo');
        aet(ds,.5,'foo');
        aet(ds,struct);
        aet(ds,1,1,1);
        aet(ds.sa.chunks,1,'chunks',1);
        aet(ds.sa.chunks,1,'chunks',1,'chunks');

        ds.sa.modality=3; % size mismatch
        aet(ds,1,'modality',1);

    end

