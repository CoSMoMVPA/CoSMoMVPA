function test_suite = test_dim_find()
% tests for cosmo_dim_find
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_find_basics()
    prefixes='sf';
    for dim=1:2
        if dim==1
            transposer=@transpose;
        else
            transposer=@(x)x;
        end


        prefix=prefixes(dim);
        attr_name=[prefix 'a'];
        dim_name=[prefix 'dim'];

        dim_labels={'i','j','k'};

        ds=cosmo_synthetic_dataset();
        if dim==1
            ds=cosmo_dim_transpose(ds,{'i','j','k'},1);
        end

        combis=cell2mat(cosmo_cartprod(repmat({[false,true]},3,1)));

        for j=1:size(combis,1);
            msk=combis(j,:);

            use_string_name=sum(msk)==1 && msk(2);

            if use_string_name
                name=dim_labels{msk};
            else
                name=dim_labels(msk);
            end

            [d,i,an,dn,vs]=cosmo_dim_find(ds,name,false);

            if ~any(msk)
                assertEqual({d,i,an,dn,vs},{[],[],[],[],[]});

            else
                assertEqual(d,dim);
                assertEqual(i,transposer(find(msk)'));
                assertEqual(an,attr_name);
                assertEqual(dn,dim_name);

                values=ds.a.(dim_name).values;

                if use_string_name
                    assertEqual(vs,values{msk});
                else
                    assertEqual(vs,values(transposer(msk)));
                end
            end
        end
    end


function test_dim_find_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_dim_find(varargin{:}),'');


    ds=cosmo_synthetic_dataset();

    ds=cosmo_dim_transpose(ds,'i',1);
    aet(ds,{'i','j'});
    assertEqual(cosmo_dim_find(ds,{'i','j'},false),[]);
    aet(ds,{'foo'});
    assertEqual(cosmo_dim_find(ds,{'foo'},false),[]);
    aet(ds,'foo');
    aet(ds,[]);
    assertEqual(cosmo_dim_find(ds,'foo',false),[]);
    ds=cosmo_dim_transpose(ds,'i',2);
    cosmo_dim_find(ds,'i');
    ds.a.fdim.labels{1}='k';
    aet(ds,'k',true);



