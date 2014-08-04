function ni=generate_test_nifti_struct()
% Generates a struct that behaves like a NIFTI struct
%
% NNO Aug 2013

    voldim=[7 11 13];
    voxdim=[3 3 3];
    nsamples=20;

    imgshape=[voldim nsamples];

    ni=struct();

    ni.img=single(generate_random_deterministic(imgshape));

    hdr=struct();

    dime=struct();
    dime.datatype=16; %single
    dime.dim=[4 imgshape 1 1 1];
    dime.pixdim=[1 voldim 0 0 0 0];
    fns={'intent_p1','intent_p2','intent_p3','intent_code',...
        'slice_start','slice_duration','slice_end',...
        'scl_slope','scl_inter','slice_code','cal_max',...
        'cal_min','toffset'};

    dime=set_all(dime,fns);
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
    hist=set_all(hist,{'qform_code','sform_code'});
    hist.originator=[1 1 1 1 0];
    hist=set_all(hist,{'descrip','aux_file'},'');
    hist=set_all(hist,{'qform_code','sform_code','quatern_b',...
                        'quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z'});
    hist=set_all(hist,{'intent_name'},'');

    hist.srow_x=[1 0 0 10];
    hist.srow_y=[0 2 0 20];
    hist.srow_z=[0 0 3 30];

    hist.quatern_c=1;
    hdr.hist=hist;

    ni.hdr=hdr;

    function s=set_all(s, fns, v)
    % sets all fields in fns in struct s to v
    % if v is omitted it is set to 0.
    if nargin<3, v=0; end
    n=numel(fns);
    for k=1:n
        fn=fns{k};
        s.(fn)=v;
    end
