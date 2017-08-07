function test_suite = test_neighborhood_split()
% tests for cosmo_neighborhood_split
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_neighborhood_split_basics()
    ds=cosmo_synthetic_dataset('size','big');
    nfeatures=size(ds.samples,2);
    rp=randperm(nfeatures);
    ds=cosmo_slice(ds,[rp rp],2);
    nfeatures=size(ds.samples,2);


    radius=1+rand()*3;
    nh=cosmo_spherical_neighborhood(ds,'radius',radius,'progress',false);

    for divisions=[2 4]
        [nh_sp,masks]=cosmo_neighborhood_split(nh,'divisions',divisions);

        % basic checks
        assert(iscell(nh_sp));
        assert(iscell(masks));
        n_sp=numel(nh_sp);
        assertEqual(n_sp,numel(masks));

        assert(n_sp<=(divisions+1)^3);

        assert(n_sp>=(divisions-1)^3);

        % space for neighborhood matrix consisting of the different splits
        max_nh_count=max(cellfun(@numel,nh.neighbors));
        n_centers=numel(nh.neighbors);
        all_nh_mx=zeros(max_nh_count,n_centers);

        % space to store neighborhoods .fa
        all_fa_cell=cell(1,n_sp);

        feature_id=0;
        for k=1:n_sp
            sp_nh=nh_sp{k};

            assertEqual(sp_nh.a, nh.a);

            sp_msk=masks{k};
            % mask must have similar 'space' as dataset
            assert(islogical(sp_msk.samples));
            assertEqual(size(sp_msk.samples),[1,nfeatures]);
            assertEqual(sp_msk.fa,ds.fa);
            assertEqual(sp_msk.a,ds.a);

            % store feature attributes
            all_fa_cell{k}=[sp_nh.fa.i; sp_nh.fa.j; sp_nh.fa.k];


            m_k_idxs=find(sp_msk.samples);

            for j=1:numel(sp_nh.neighbors)
                nb=sp_nh.neighbors{j};

                % indirect indexing through neighbors must
                % only give features that are in the mask
                idx_msk=false(1,nfeatures);
                assert(max(nb)<=numel(m_k_idxs));
                assert(max(m_k_idxs(nb))<=nfeatures);
                idx_msk(m_k_idxs(nb))=true;

                assert(all(sp_msk.samples(idx_msk)));
                assert(~any(idx_msk & ~sp_msk.samples));

                % store neighbors in matrix
                n_nb=numel(nb);
                feature_id=feature_id+1;

                all_nh_mx(1:n_nb,feature_id)=m_k_idxs(nb);
            end
        end

        % all centers must be visited
        assert(feature_id==n_centers);

        % stack the .fa
        all_fa=cat(2,all_fa_cell{:});
        all_fa_ijk_cell={all_fa(1,:),all_fa(2,:),all_fa(3,:)};

        % get the original fa
        fa_ijk_cell={nh.fa.i, nh.fa.j, nh.fa.k};
        fa=cat(1,fa_ijk_cell{:});

        % order may be different as in the original, so find the mapping
        mp=cosmo_align(all_fa_ijk_cell,fa_ijk_cell);
        assertEqual(all_fa(:,mp),fa);

        % verify that neighbors are matching
        nh_mx=cosmo_convert_neighborhood(nh,'matrix');
        assertEqual(all_nh_mx(:,mp),nh_mx);

    end


function test_neighborhood_split_exceptions()
    return
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_neighborhood_split(varargin{:}),'');

    aet(struct);
    ds=cosmo_synthetic_dataset();
    aet(ds);

    nh=cosmo_interval_neighborhood(ds,'i','radius',1);
    aet(nh,'foo',2);
    aet(nh,'count',0);
    aet(nh,'count',1.0001);
    aet(nh,'count',[2 2]);
    aet(nh,'count',Inf);
    aet(nh,'count',[]);


    nh2=nh;
    nh2=rmfield(nh2,'origin');
    aet(nh2,'count',2);

    nh2=nh;
    nh2=rmfield(nh2,'neighbors');
    aet(nh2,'count',2);
