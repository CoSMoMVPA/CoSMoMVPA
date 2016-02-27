function test_suite = test_dim_rename()
% tests for cosmo_dim_rename
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite

function test_dim_rename_basics
    ds=cosmo_synthetic_dataset();

    % simple rename
    ds2=cosmo_dim_rename(ds,'j','jj');
    assertEqual(ds2.a.fdim.labels{2},'jj');
    assertEqual(ds2.a.fdim.values,ds.a.fdim.values);
    assertEqual(ds2.samples,ds.samples);
    assertEqual(ds2.sa,ds.sa);

    fa=ds.fa;
    fa.jj=fa.j;
    fa=rmfield(fa,'j');
    assertEqual(ds2.fa,fa);

    % if raise=false, input is same as output
    ds3=cosmo_dim_rename(ds,'xxx','jj',false);
    assertEqual(ds,ds3,ds);

    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_dim_rename(varargin{:}),'');
    aet(ds,'xxx','jj');
    aet(ds,'xxx','jj',true);
