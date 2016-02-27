function test_suite = test_fmri_deoblique
% tests for cosmo_fmri_deoblique
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_fmri_deoblique_basics
    ds=cosmo_synthetic_dataset('size','normal','ntargets',1,'nchunks',1);
    % make dataset oblique (manually)
    ds.a.vol.mat(1,1)=.8;
    ds.a.vol.mat(2,1)=.6;

    ds_deoblique=cosmo_fmri_deoblique(ds);

    mat=eye(4);
    mat(2,2)=2;
    mat(3,3)=2;
    mat(1:3,4)=[-3.2 -2.4 -3];

    assertEqual(ds_deoblique.a.vol.mat,mat);
    ds.a.vol.mat=mat;
    assertEqual(ds,ds_deoblique);

    ds_deoblique2=cosmo_fmri_deoblique(ds_deoblique);
    assertEqual(ds_deoblique,ds_deoblique2);


