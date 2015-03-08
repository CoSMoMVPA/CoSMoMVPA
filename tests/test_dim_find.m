function test_suite = test_dim_find()
    initTestSuite;

function test_dim_find_basics()
    prefixes='sf';
    for dim=1:2
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

            [d,i,an,dn,vs]=cosmo_dim_find(ds,name);

            if ~any(msk)
                assertEqual({d,i,an,dn,vs},{[],[],[],[],[]});
            else

                assertEqual(d,dim);
                assertEqual(i,find(msk));
                assertEqual(an,attr_name);
                assertEqual(dn,dim_name);

                values=ds.a.(dim_name).values;

                if use_string_name
                    assertEqual(vs,values{msk});
                else
                    assertEqual(vs,values(msk));
                end
            end
        end


    end
