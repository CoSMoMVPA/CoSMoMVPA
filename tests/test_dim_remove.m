function test_suite = test_dim_remove()
% tests for cosmo_dim_remove
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_dim_remove_basics()
    ds_orig=cosmo_synthetic_dataset();
    prefixes='sf';
    for dim=1:2
        prefix=prefixes(dim);
        attr_name=[prefix 'a'];
        dim_name=[prefix 'dim'];


        if dim==1
            ds=cosmo_dim_transpose(ds_orig,{'i','j','k'});
        else
            ds=ds_orig;
        end

        [ds2,fa,values]=cosmo_dim_remove(ds,'j');
        assertEqual(ds2.a.(dim_name).labels,ds.a.(dim_name).labels([1 3]));
        assertEqual(ds2.a.(dim_name).values,ds.a.(dim_name).values([1 3]));
        assert_has_fields_diff(ds2.fa,ds.fa,{'j'});
        assertEqual(fa,copy_fields(ds.(attr_name),{'j'}));
        assertEqual(values,ds.a.(dim_name).values{2});

        [ds3,fa,values]=cosmo_dim_remove(ds,{'j','i'});
        assertEqual(ds3.a.(dim_name).labels,ds.a.(dim_name).labels(3));
        assertEqual(ds3.a.(dim_name).values,ds.a.(dim_name).values(3));
        assertEqual(fa,copy_fields(ds.(attr_name),{'j','i'}));
        assert_has_fields_diff(ds3.fa,ds.fa,{'j','i'});
        assertEqual(values,ds.a.(dim_name).values([2 1]));

        [ds4,fa,values]=cosmo_dim_remove(ds,{'j','i','k'});
        assertFalse(isfield(ds4.a,dim_name));
        assertFalse(any(cosmo_isfield(ds4.(attr_name),{'j','i','k'})));
        assertEqual(fa,copy_fields(ds.(attr_name),{'j','i','k'}));
        assert_has_fields_diff(ds4.fa,ds.fa,{'j','i','k'});
        assertEqual(values,ds.a.(dim_name).values([2 1 3]));

    end

function assert_has_fields_diff(new_struct, orig_struct, removed)
    kept=sort(fieldnames(new_struct));
    expected_kept=sort(setdiff(fieldnames(orig_struct),removed));
    assertEqual(kept(:),expected_kept(:));


function y=copy_fields(x, keys)
    y=struct();
    for k=1:numel(keys)
        key=keys{k};
        y.(key)=x.(key);
    end
