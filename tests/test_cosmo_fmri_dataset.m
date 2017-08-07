function test_suite = test_cosmo_fmri_dataset
% tests for cosmo_fmri_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_init()
    ds=cosmo_synthetic_dataset();

    assertTrue(numel(setxor(fieldnames(ds),...
               {'samples','a','sa','fa'}))==0);


function test_nifti()
    ni=generate_test_nifti_struct();
    g=cosmo_synthetic_dataset('size','normal');

    tmpfn='__tmp1_.nii';
    cleaner=onCleanup(@()delete(tmpfn));
    save_nii(ni,tmpfn);
    ds=cosmo_fmri_dataset(tmpfn,'targets',g.sa.targets,...
                                'chunks',g.sa.chunks);



    assertTrue(numel(setxor(fieldnames(ds),...
               fieldnames(g)))==0);

    assertElementsAlmostEqual(ds.samples, g.samples,'relative',1e-6);
    assertEqual(ds.sa.targets, g.sa.targets)
    assertEqual(ds.sa.chunks, g.sa.chunks)

function test_io()
    ds=cosmo_synthetic_dataset('size','normal');
    tmpfn='__tmp2_.nii';
    cleaner=onCleanup(@()delete(tmpfn));

    cosmo_map2fmri(ds,tmpfn);

    es=cosmo_fmri_dataset(tmpfn);
    assertElementsAlmostEqual(ds.samples,es.samples,'relative',1e-6);
    assertEqual(ds.a.fdim,es.a.fdim);



function ni=generate_test_nifti_struct()
% Generates a struct that behaves like a NIFTI struct
    ni=struct();

    ds=cosmo_synthetic_dataset('size','normal');
    ni.img=shiftdim(cosmo_unflatten(ds),1);

    hdr=struct();

    dime=struct();
    dime.datatype=16; %single
    dime.dim=[4 3 2 5 6 1 1 1];
    dime.pixdim=[0 2 2 2 0 0 0 0];
    fns={'intent_p1','intent_p2','intent_p3','intent_code',...
        'slice_start','slice_duration','slice_end',...
        'scl_slope','scl_inter','slice_code','cal_max',...
        'cal_min','toffset'};

    dime=nifti_helper_set_all(dime,fns);
    dime.xyzt_units=10;
    hdr.dime=dime;

    hk=struct();
    hk.sizeof_hdr=348;
    hk.data_type='';
    hk.db_name='';
    hk.extents=0;
    hk.session_error=0;
    hk.regular='r';
    hk.dim_info=0;
    hdr.hk=hk;

    hist=struct();
    hist.sform_code=1;
    hist.originator=[2 1 3 3];
    hist=nifti_helper_set_all(hist,{'descrip','aux_file'},'');
    hist=nifti_helper_set_all(hist,{'qform_code','quatern_b',...
                        'quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z'});
    hist=nifti_helper_set_all(hist,{'intent_name'},'');

    hist.srow_x=[2 0 0 -1];
    hist.srow_y=[0 2 0 -1];
    hist.srow_z=[0 0 2 -1];

    hist.quatern_c=0;
    hdr.hist=hist;

    ni.hdr=hdr;

function s=nifti_helper_set_all(s, fns, v)
    % sets all fields in fns in struct s to v
    % if v is omitted it is set to 0.
    if nargin<3, v=0; end
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        s.(fn)=v;
    end
