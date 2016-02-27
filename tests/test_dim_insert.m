function test_suite = test_dim_insert()
% tests for cosmo_dim_insert
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_dim_insert_basics()

    ds=cosmo_synthetic_dataset();
    ds2=cosmo_dim_remove(ds,'j');
    ds3=cosmo_dim_insert(ds2,2,2,{'j'},ds.a.fdim.values(2),ds.fa);
    assertEqual(ds,ds3);

    ds4=cosmo_dim_insert(ds2,2,3,{'j'},ds.a.fdim.values(2),ds.fa);
    assertEqual(ds.samples,ds4.samples);
    assertEqual(ds.fa,ds4.fa);
    assertEqual(ds.a.fdim.values,ds4.a.fdim.values([1 3 2]));
    assertEqual(ds.a.fdim.labels,ds4.a.fdim.labels([1 3 2]));

    ds5=cosmo_dim_insert(ds2,2,1,{'j'},ds.a.fdim.values(2),ds.fa);
    assertEqual(ds.samples,ds5.samples);
    assertEqual(ds.fa,ds5.fa);
    assertEqual(ds.a.fdim.values,ds5.a.fdim.values([2 1 3]));
    assertEqual(ds.a.fdim.labels,ds5.a.fdim.labels([2 1 3]));


    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_dim_insert(varargin{:}),'');


    prefixes='sf';
    for dim=1:2
        prefix=prefixes(dim);
        dim_name=[prefix 'dim'];

        ds=cosmo_synthetic_dataset();
        dim_labels=ds.a.fdim.labels;
        if dim==1
            ds=cosmo_dim_transpose(ds,{'i','j','k'},1);
        end


        combis=cell2mat(cosmo_cartprod(repmat({[false,true]},3,1)));

        for j=1:size(combis,1);
            msk=combis(j,:);

            if ~any(msk)
                continue;
            end

            use_struct_attr=sum(msk)==2 && msk(2);
            transpose_dim_labels=msk(1);

            if transpose_dim_labels
                dim_labels=dim_labels';
            end

            labels=dim_labels(msk);

            [dsr,attr,values]=cosmo_dim_remove(ds,labels);
            expected_values=ds.a.(dim_name).values(msk);
            assertEqual(values,expected_values);

            if ~use_struct_attr
                attr=struct2cell(attr);
            end

            nlabels_keep=numel(dim_labels)-sum(msk);

            for pos=1:(nlabels_keep+1)
                if mod(j,3)==0
                    index=-nlabels_keep+pos-1;
                else
                    index=pos;
                end

                ds2=cosmo_dim_insert(dsr,dim,index,labels,values,attr);
                xdim=ds2.a.(dim_name);
                ds2.a.(dim_name)=ds.a.(dim_name);
                assertEqual(ds,ds2);

                trg=pos+(0:numel(labels)-1);
                xdim_labels=xdim.labels(trg);
                xdim_values=xdim.values(trg);
                assertTrue(isvector(xdim_labels));
                assertTrue(isvector(xdim_values));

                assertEqual(size(xdim_labels,dim),1);
                assertEqual(size(xdim_values,dim),1);

                assertEqual(xdim_labels(:),labels(:));
                assertEqual(xdim_values(:),values(:));
            end
        end

        % test exceptions
        aet(dsr,1,index,'foo',values,attr);
        aet(dsr,1,index,labels,'foo',attr);
        aet(dsr,dim,index,labels,values,attr(1:2));
        aet(dsr,dim,index,labels,values,[1 2]);
        aet(dsr,dim,index,labels(1:2),values,attr);
        aet(dsr,dim,index,labels,values(1:2),attr);
        aet(dsr,dim,4,labels,values,attr);
        aet(dsr,dim,-4,labels,values,attr);

        if dim==1
            values{1}=[values{1} values{1}];
        else
            values{1}=[values{1};values{1}];
        end

        % test matrix_labels option
        aet(dsr,dim,index,labels,values,attr);
        cosmo_dim_insert(dsr,dim,index,labels,values,attr,...
                                    'matrix_labels',labels(1));
    end
