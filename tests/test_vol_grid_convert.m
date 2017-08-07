function test_suite = test_vol_grid_convert
% tests for cosmo_vol_grid_convert
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_vol_grid_convert_basics
    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_vol_grid_convert(varargin{:}),'');

    ds_orig=cosmo_synthetic_dataset('size','normal');
    ds_orig.a.vol=rmfield(ds_orig.a.vol,'xform');
    nfeatures=size(ds_orig.samples,2);
    nfeatures2=round(nfeatures/2);
    while true
        rp=randperm(nfeatures);
        ds=cosmo_slice(ds_orig,repmat(rp(1:nfeatures2),1,2),2);
        ijk=[ds.fa.i; ds.fa.j; ds.fa.k];

        no_missing_features=true;
        for dim=1:3
            no_missing_features=no_missing_features && ...
                                        isequal(unique(ijk(dim,:)),...
                                                    1:ds.a.vol.dim(dim));
        end
        if no_missing_features
            break;
        end
    end


    ds2=cosmo_vol_grid_convert(ds);
    assert(all(~cosmo_isfield(ds2.fa,{'i','j','k'})));
    assertEqual(ds2.a.fdim.labels,{'pos'});
    assertEqual(numel(ds2.a.fdim.values),1);
    assertFalse(isfield(ds2.a,'vol'));

    assert(isfield(ds2.fa,'pos'));
    pos=ds2.a.fdim.values{1}(:,ds2.fa.pos);
    assertEqual(pos, cosmo_vol_coordinates(ds));

    ds3=cosmo_vol_grid_convert(ds,'togrid');
    assertEqual(ds2,ds3);
    ds4=cosmo_vol_grid_convert(ds3,'tovol');
    assertEqual(ds4,ds);
    ds4same=cosmo_vol_grid_convert(ds4,'tovol');
    assertEqual(ds4,ds4same);
    aet(ds4,'foo');

    ds4=cosmo_vol_grid_convert(ds2);
    assertEqual(ds4,ds);

    ds4=cosmo_vol_grid_convert(ds2);
    assertEqual(ds4,ds);

    ds5=cosmo_vol_grid_convert(ds2,'tovol');
    assertEqual(ds5,ds4);

    ds.fa=rmfield(ds.fa,'j');
    aet(ds);

    % irregular grid
    ds3.a.fdim.values{1}(1)=.5;
    aet(ds3);

    % should not work for datasets with missing pos and vol
    ds6=cosmo_synthetic_dataset('type','timelock');
    aet(ds6,'tovol');
    aet(ds6,'togrid');
    aet(ds6);
    aet(ds6,'tovol','togrid');



