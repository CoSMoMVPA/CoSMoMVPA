function test_suite = test_fmri_dataset()
% tests for cosmo_fmri_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_base_fmri_dataset()
    ds=get_base_dataset();
    assert_dataset_equal(ds, get_expected_dataset());

function test_afni_fmri_dataset()
    if cosmo_skip_test_if_no_external('afni')
        return;
    end

    ds=get_base_dataset();
    afni=cosmo_map2fmri(ds,'-afni');
    afni_expected=get_expected_afni();

    assertAlmostEqualWithTol(afni.img, afni_expected.img);
    afni_no_img=rmfield(afni,'img');
    afni_expected_no_img=rmfield(afni_expected,'img');
    assertEqual(afni_no_img,afni_expected_no_img);

    ds_afni=cosmo_fmri_dataset(afni);
    assert_dataset_equal(ds,ds_afni);

function test_nii_sform_fmri_dataset()
    ds=get_base_dataset();
    nii=cosmo_map2fmri(ds,'-nii');
    nii_expected=get_expected_nii_sform();
    assertEqual(nii.hdr, nii_expected.hdr);
    assertAlmostEqualWithTol(nii.img,nii_expected.img);
    ds_nii=cosmo_fmri_dataset(nii);
    assert_dataset_equal(ds,ds_nii);

function test_nii_qform_fmri_dataset()
    ds=get_base_dataset();
    nii=get_expected_nii_qform();
    ds_nii=cosmo_fmri_dataset(nii);
    assert_dataset_equal(ds,ds_nii);

    % check qform with illegal pixdims
    nii.hdr.dime.pixdim(1:4)=-1;
    nii.hdr.hist.quatern_b=1;
    nii.hdr.hist.quatern_c=0;
    nii.hdr.hist.quatern_d=0;

    ds_nii_alt=cosmo_fmri_dataset(nii);
    m=ds_nii_alt.a.vol.mat;
    assertEqual(diag(m),[1 -1 1 1]');
    assertEqual(m(1:3,4),[-2 0 -2]');


function test_nii_pixdim_fmri_dataset()
    ds=get_base_dataset();
    nii=get_expected_nii_pixdim();
    ds_nii=cosmo_fmri_dataset(nii);
    ds_nii.a.vol.mat(:,4)=ds.a.vol.mat(:,4);
    assert_dataset_equal(ds,ds_nii);

    nii.hdr.dime.scl_inter=200;
    nii.hdr.dime.scl_slope=17;

    ds_nii_scl=cosmo_fmri_dataset(nii);
    assertElementsAlmostEqual(17*ds.samples+200,ds_nii_scl.samples,...
                                    'absolute',1e-3);


function test_nii_sform_afni_5d_singleton_dataset()
    ds=get_base_dataset();
    nii=get_expected_nii_sform();

    % header: move 4th to 5th dimension
    nii.hdr.dime.dim(6)=nii.hdr.dime.dim(5);
    nii.hdr.dime.dim(5)=1;

    % data: move 4th to 5th dimension
    orig_size=size(nii.img);
    nii.img=reshape(nii.img,[orig_size(1:3) 1 orig_size(4)]);

    % test this test: verify size is ok
    assertEqual(nii.hdr.dime.dim(2:6),size(nii.img));

    ds_nii=cosmo_fmri_dataset(nii);
    assert_dataset_equal(ds,ds_nii);

function test_nii_sform_afni_5d_nonsingleton_dataset()
    ds=get_base_dataset();
    nii=get_expected_nii_sform();

    % header: add extra dimension
    nrep=ceil(rand()*3+2);
    nii.hdr.dime.dim(6)=nrep;

    % data: move 4th to 5th dimension
    img_rep=repmat({nii.img},1,nrep);
    nii.img=cat(5,img_rep{:});

    % test this test: verify size is ok
    assertEqual(nii.hdr.dime.dim(2:6),size(nii.img));

    % must not support this
    assertExceptionThrown(@()cosmo_fmri_dataset(nii),'');


function test_nii_sform_and_qform_fmri_dataset()
    ds=get_base_dataset();
    nii=get_expected_nii_sform_and_qform();
    ds_nii=cosmo_fmri_dataset(nii);
    assert_dataset_equal(ds,ds_nii);

    nii.hdr.hist.srow_x(1)=1;
    assertExceptionThrown(@()cosmo_fmri_dataset(nii),'');
    ds_nii_qform=cosmo_fmri_dataset(nii,'nifti_form','qform');
    assertEqual(ds_nii_qform,ds_nii);
    assertExceptionThrown(@()cosmo_fmri_dataset(nii,'nifti_form','X'),'');


function test_bv_vmr_fmri_dataset()
    if ~can_test_bv()
        return
    end
    uint_ds=get_uint8_dataset();
    bv_vmr=cosmo_map2fmri(uint_ds,'-bv_vmr');

    cleaner=onCleanup(@()bv_vmr.ClearObject());
    bless(bv_vmr);

    assert_bv_equal(bv_vmr, get_expected_bv_vmr());
    ds_bv_vmr=cosmo_fmri_dataset(bv_vmr,'mask',false);
    ds_bv_vmr_lpi=cosmo_fmri_reorient(ds_bv_vmr,'LPI');
    assert_dataset_equal(uint_ds,ds_bv_vmr_lpi,'rotation');


function test_bv_vmp_fmri_dataset()
    if ~can_test_bv()
        return
    end

    ds=get_base_dataset();
    bv_vmp=cosmo_map2fmri(ds,'-bv_vmp');

    cleaner=onCleanup(@()bv_vmp.ClearObject());
    bless(bv_vmp);

    assert_bv_equal(bv_vmp, get_expected_bv_vmp());
    ds_bv_vmp=cosmo_fmri_dataset(bv_vmp);
    ds_bv_vmp_lpi=cosmo_fmri_reorient(ds_bv_vmp,'LPI');
    assert_dataset_equal(ds,ds_bv_vmp_lpi,'translation');


function test_bv_msk_fmri_dataset()
    if ~can_test_bv()
        return
    end

    uint_ds=get_uint8_dataset();
    bv_msk=cosmo_map2fmri(uint_ds,'-bv_msk');

    cleaner=onCleanup(@()bv_msk.ClearObject());
    bless(bv_msk);

    assert_bv_equal(bv_msk, get_expected_bv_msk());

    ds_bv_msk=cosmo_fmri_dataset(bv_msk,'mask',false);
    ds_bv_msk_lpi=cosmo_fmri_reorient(ds_bv_msk,'LPI');
    assert_dataset_equal(uint_ds,ds_bv_msk_lpi,'translation');


function test_bv_vtc_fmri_dataset()
    if ~can_test_bv()
        return
    end

    ds=get_base_dataset();
    ds.samples=round(ds.samples);
    ds.samples(ds.samples<0)=0;

    xff_bv_vtc=get_expected_xff_bv_vtc();
    cleaner=onCleanup(@()xff_bv_vtc.ClearObject());
    bless(xff_bv_vtc);

    ds_bv_vtc=cosmo_fmri_dataset(xff_bv_vtc);
    ds_bv_glm_lpi=cosmo_fmri_reorient(ds_bv_vtc,'LPI');

    assert_dataset_equal(ds,ds_bv_glm_lpi,'translation');


function test_bv_glm_subject_fmri_dataset()
    if ~can_test_bv()
        return
    end

    % no support for map2fmri, so just test with neuroelf struct
    ds=get_base_dataset();

    xff_bv_glm=get_expected_xff_bv_glm();
    cleaner=onCleanup(@()xff_bv_glm.ClearObject());
    bless(xff_bv_glm);

    ds_bv_glm=cosmo_fmri_dataset(xff_bv_glm);
    ds_bv_glm_lpi=cosmo_fmri_reorient(ds_bv_glm,'LPI');

    assert_dataset_equal(ds,ds_bv_glm_lpi,'translation');


function test_mask_fmri_dataset()
    aet=@(varargin)assertExceptionThrown(@()...
                        cosmo_fmri_dataset(varargin{:}),'');
    ds=cosmo_synthetic_dataset();
    ds.samples(:,[2 6])=0;

    x=cosmo_fmri_dataset(ds,'mask','-auto');
    assertEqual(x,cosmo_slice(ds,[1 3 4 5],2));
    x1=cosmo_fmri_dataset(ds,'mask',true);
    assertEqual(x1,x);
    x2=cosmo_fmri_dataset(ds,'mask',false);
    assertEqual(x2,ds);


    aet(ds,'mask','foo');
    aet(ds,'mask','-foo');
    aet(ds,'mask',ds);
    aet(ds,'mask',struct);

    ds.samples(1,2)=1;
    aet(ds,'mask','-auto');

    x3=cosmo_fmri_dataset(ds,'mask','-any');
    assertEqual(x3,x);

    x4=cosmo_fmri_dataset(ds,'mask','-all');
    assertEqual(x4,cosmo_slice(ds,[1 2 3 4 5],2));

    msk_ds=cosmo_slice(cosmo_slice(x,randperm(size(x.samples,2)),2),1);
    x5=cosmo_fmri_dataset(ds,'mask',msk_ds);
    assertEqual(x5,x);





function test_meeg_source_fmri_dataset()
    ds=cosmo_synthetic_dataset('type','source');
    res=cosmo_fmri_dataset(ds);
    assertEqual(ds.samples,res.samples);
    assertEqual(diag(res.a.vol.mat),[10 10 10 1]');

function test_set_sa_fmri_dataset()
    ds=cosmo_synthetic_dataset();
    res=cosmo_fmri_dataset(ds,'targets',1:6,'chunks',3);
    assertEqual(res.sa.targets,(1:6)');
    assertEqual(res.sa.chunks,ones(6,1)*3);

    assertExceptionThrown(@()cosmo_fmri_dataset(ds,'targets',[1 2]),'');

function test_nan_warning_fmri_dataset()
    ds=cosmo_synthetic_dataset();
    ds.samples(1)=NaN;
    msk_ds=cosmo_slice(ds,2);

    orig_warning_state=cosmo_warning();
    warning_state_resetter=onCleanup(@()cosmo_warning(orig_warning_state));
    cosmo_warning('off');

    cosmo_fmri_dataset(ds,'mask',msk_ds);
    warning_state=cosmo_warning();

    warning_pos=strmatch('The input dataset has NaN',...
                    warning_state.shown_warnings);
    assert(~isempty(warning_pos));


function tf=can_test_bv()
    tf=~cosmo_skip_test_if_no_external('neuroelf');

function ds=get_base_dataset()
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',1);

function ds=get_uint8_dataset()
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',1);
    ds=cosmo_slice(ds,1);
    mn=min(ds.samples);
    mx=max(ds.samples);
    ds.samples=uint8((ds.samples-mn)/(mx-mn)*255);

function assertAlmostEqualWithTol(x,y)
    assertElementsAlmostEqual(double(x),double(y),'relative',1e-3);


function assert_dataset_equal(x,y,opt)
    if nargin<3 || isempty(opt)
        opt='';
    end
    % dataset equality, without .sa
    assertAlmostEqualWithTol(x.samples, y.samples);
    assertEqual(x.fa, y.fa)

    switch opt
        case 'rotation'
            % BV VMR cannot store orientation, just check the rotation part
            assertEqual(x.a.fdim, y.a.fdim);
            assertAlmostEqualWithTol(x.a.vol.dim,y.a.vol.dim);
            assertAlmostEqualWithTol(x.a.vol.mat(1:3,1:3),...
                            y.a.vol.mat(1:3,1:3));
        case 'translation'
            % BV VMP cannot store xform, just check the matrix
            assertEqual(x.a.fdim, y.a.fdim);
            assertAlmostEqualWithTol(x.a.vol.dim,y.a.vol.dim);
            assertAlmostEqualWithTol(x.a.vol.mat,y.a.vol.mat);
        otherwise
            assertEqual(x.a, y.a)
    end


function assert_bv_equal(x_xff, y_struct)
    % BV equality; first argument is xff class, second argument a struct
    % passes if all fields in y_struct have the same value in x_xff;
    % x_xff can have more fields than y_struct
    keys=fieldnames(y_struct);
    for k=1:numel(keys)
        key=keys{k};
        y=y_struct.(key);
        x=x_xff.(key);
        if isstruct(x)
            for j=1:numel(x)
                assert_bv_equal(x(j),y(j))
            end
        else
            assertAlmostEqualWithTol(x,y);
        end

    end

function xff_bv_glm=get_expected_xff_bv_glm()
    xff_bv_glm=xff('new:glm');
    xff_bv_glm.NrOfSubjects=1;
    xff_bv_glm.NrOfPredictors=2;
    xff_bv_glm.Predictor=struct('Name1',{'1','2'},...
                                'Name2',{'1','2'},...
                                'RGB',{[255 0 0] [0 255 0]});
    xff_bv_glm.Resolution=2;
    xff_bv_glm.XStart = 126;
    xff_bv_glm.XEnd = 130;
    xff_bv_glm.YStart = 128;
    xff_bv_glm.YEnd = 130;
    xff_bv_glm.ZStart = 124;
    xff_bv_glm.ZEnd = 130;

    data=zeros(2,1,3,2);
    data_size=size(data);
    mat_size=data_size(1:3);
    data(:,:,:,1)=reshape([ -0.2040   -1.0504   -0.2617 ...
                            -3.6849    1.3494    2.0317], mat_size);
    data(:,:,:,2)=reshape([0.4823 -1.3265 2.3387 ...
                            1.7235 -0.3973 0.5838], mat_size);
    xff_bv_glm.GLMData.BetaMaps=data;

function xff_bv_vtc=get_expected_xff_bv_vtc()
    xff_bv_vtc=xff('new:vtc');
    xff_bv_vtc.NrOfVolumes=2;

    xff_bv_vtc.Resolution=2;
    xff_bv_vtc.XStart = 126;
    xff_bv_vtc.XEnd = 130;
    xff_bv_vtc.YStart = 128;
    xff_bv_vtc.YEnd = 130;
    xff_bv_vtc.ZStart = 124;
    xff_bv_vtc.ZEnd = 130;

    data_orig=zeros(2,1,3,2);
    data_size=size(data_orig);
    mat_size=data_size(1:3);
    data_orig(:,:,:,1)=reshape([ -0.2040   -1.0504   -0.2617 ...
                            -3.6849    1.3494    2.0317], mat_size);
    data_orig(:,:,:,2)=reshape([0.4823 -1.3265 2.3387 ...
                            1.7235 -0.3973 0.5838], mat_size);

    data=uint16(data_orig);
    xff_bv_vtc.VTCData=zeros(2,2,1,3,'uint16');
    xff_bv_vtc.VTCData(1,:,:,:)=data(:,:,:,1);
    xff_bv_vtc.VTCData(2,:,:,:)=data(:,:,:,2);


function bv_msk=get_expected_bv_msk()
    bv_msk=struct();
    bv_msk.Resolution= 2 ;
    bv_msk.XStart = 126;
    bv_msk.XEnd = 130;
    bv_msk.YStart = 128;
    bv_msk.YEnd = 130;
    bv_msk.ZStart = 124;
    bv_msk.ZEnd = 130;

    data=zeros(2,1,3,'uint8');
    data(:,:,1) = [ 155 118 ];
    data(:,:,2) = [ 153 0 ];
    data(:,:,3) = [ 225 255 ];
    bv_msk.Mask=data;

function bv_vmp=get_expected_bv_vmp()
    bv_vmp=struct();
    bv_vmp.NrOfMaps = 2;
    bv_vmp.OverallMapType = 1;
    bv_vmp.OverallNrOfLags = [];
    bv_vmp.NrOfTimePoints = 0;
    bv_vmp.NrOfMapParameters = 0;
    bv_vmp.ShowParamsRangeFrom = 0;
    bv_vmp.ShowParamsRangeTo = 0;
    bv_vmp.FingerprintParamsRangeFrom = 0;
    bv_vmp.FingerprintParamsRangeTo = 0;
    bv_vmp.Resolution = 2;
    bv_vmp.XStart = 126;
    bv_vmp.XEnd = 130;
    bv_vmp.YStart = 128;
    bv_vmp.YEnd = 130;
    bv_vmp.ZStart = 124;
    bv_vmp.ZEnd = 130;

    map1.VMPData=reshape([-0.2040   -1.0504   -0.2617   ...
                            -3.6849    1.3494    2.0317],[2 1 3]);
    map2.VMPData=reshape([0.4823 -1.3265 2.3387 ...
                            1.7235 -0.3973 0.5838],[2 1 3]);
    bv_vmp.Map=cat(1,map1,map2);

function bv_vmr=get_expected_bv_vmr()

    bv_vmr=struct();
    bv_vmr.FileVersion = 3;
    bv_vmr.DimX = 2;
    bv_vmr.DimY = 1;
    bv_vmr.DimZ = 3;
    bv_vmr.VMRData16 = [];
    bv_vmr.OffsetX = 0;
    bv_vmr.OffsetY = 0;
    bv_vmr.OffsetZ = 0;
    bv_vmr.FramingCube = 256;
    bv_vmr.PosInfoVerified = false;
    bv_vmr.RowDirX = 0;
    bv_vmr.RowDirY = 1;
    bv_vmr.RowDirZ = 0;
    bv_vmr.ColDirX = 0;
    bv_vmr.ColDirY = 0;
    bv_vmr.ColDirZ = -1;
    bv_vmr.NRows = 256;
    bv_vmr.NCols = 256;
    bv_vmr.FoVRows = 256;
    bv_vmr.FoVCols = 256;
    bv_vmr.SliceThickness = 1;
    bv_vmr.GapThickness = 0;
    bv_vmr.ReferenceSpace = 0;
    bv_vmr.VoxResX = 2;
    bv_vmr.VoxResY = 2;
    bv_vmr.VoxResZ = 2;
    bv_vmr.VoxResInTalairach = false;
    bv_vmr.VoxResVerified = false;

    data=zeros(2,1,3,'uint8');
    data(:,:,1) = [ 155 118 ];
    data(:,:,2) = [ 153 0 ];
    data(:,:,3) = [ 225 255 ];
    bv_vmr.VMRData=data;



function afni=get_expected_afni()

    % header
    afni=struct();
    afni.SCENE_DATA = [ 0 11 1 ];
    afni.TYPESTRING = '3DIM_HEAD_FUNC' ;
    afni.BRICK_TYPES = [ 3 3 ];
    afni.BRICK_STATS = [];
    afni.BRICK_FLOAT_FACS = [ ];
    afni.DATASET_RANK = [ 3 2 ];
    afni.DATASET_DIMENSIONS = [ 3 2 1 ];
    afni.ORIENT_SPECIFIC = [ 1 2 4 ];
    afni.DELTA = [ -2 -2 2 ];
    afni.ORIGIN = [ 1 1 -1 ];
    afni.SCALE = 0;
    afni.BRICK_LABS = [];
    afni.BRICK_KEYWORDS = [];
    afni.BRICK_STATAUX = [];
    afni.STAT_AUX = [];
    afni.SCALE=0;
    afni.NOTES_COUNT=0;
    afni.WARP_TYPE=[0 0];
    afni.FileFormat='BRIK';
    [unused, unused, endian_ness] = computer();
    afni.BYTEORDER_STRING = sprintf('%sSB_FIRST',endian_ness );

    % data
    data=zeros(3,2,1,2);
    data(:,:,1,1)=[ 2.0317    1.3494;-3.6849   -0.2617;-1.0504   -0.2040];
    data(:,:,1,2)=[ 0.5838   -0.3973; 1.7235    2.3387;-1.3265    0.4823];

    % add to image
    afni.img=data;

function ds=get_expected_dataset()
    ds=struct();
    ds.samples=[ 2.0317   -3.6849   -1.0504    1.3494   -0.2617   -0.2040;
                 0.5838    1.7235   -1.3265   -0.3973    2.3387    0.4823];
    ds.fa.i=[1 2 3 1 2 3];
    ds.fa.j=[1 1 1 2 2 2];
    ds.fa.k=[1 1 1 1 1 1];
    ds.a.fdim.labels={'i';'j';'k'};
    ds.a.fdim.values={[1 2 3];[1 2];1};
    mat=diag([2 2 2 1]);
    mat(1:3,4)=-3;
    ds.a.vol.mat=mat;
    ds.a.vol.dim=[3 2 1];
    ds.a.vol.xform='scanner_anat';


function nii=get_expected_nii_pixdim()
    nii=get_expected_nii_helper();
    fields_to_clear={'quatern_b','quatern_c','quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z',...
                        'srow_x','srow_y','srow_z'};
    nii.hdr.hist=clear_fields(nii.hdr.hist,fields_to_clear);

function nii=get_expected_nii_sform_and_qform()
    nii=get_expected_nii_helper();
    nii.hdr.hist.sform_code = 1;
    nii.hdr.hist.qform_code = 1;

function nii=get_expected_nii_sform()
    nii=get_expected_nii_helper();
    nii.hdr.hist.sform_code = 1;

    fields_to_clear={'quatern_b','quatern_c','quatern_d',...
                        'qoffset_x','qoffset_y','qoffset_z'};
    nii.hdr.hist=clear_fields(nii.hdr.hist,fields_to_clear);

function nii=get_expected_nii_qform()
    nii=get_expected_nii_helper();
    nii.hdr.hist.qform_code = 1;

    fields_to_clear={'srow_x','srow_y','srow_z'};
    nii.hdr.hist=clear_fields(nii.hdr.hist,fields_to_clear);

function nii=get_expected_nii_helper()
    hdr=struct();
    hdr.dime.datatype = 16;
    hdr.dime.dim = [ 4 3 2 1 2 1 1 1 ];
    hdr.dime.pixdim = [ 0 2 2 2 0 0 0 0 ];
    hdr.dime.intent_p1 = 0;
    hdr.dime.intent_p2 = 0;
    hdr.dime.intent_p3 = 0;
    hdr.dime.intent_code = 0;
    hdr.dime.slice_start = 0;
    hdr.dime.slice_duration = 0;
    hdr.dime.slice_end = 0;
    hdr.dime.scl_slope = 0;
    hdr.dime.scl_inter = 0;
    hdr.dime.slice_code = 0;
    hdr.dime.cal_max = 0;
    hdr.dime.cal_min = 0;
    hdr.dime.toffset = 0;
    hdr.dime.xyzt_units = 10;
    hdr.hk.sizeof_hdr = 348;
    hdr.hk.data_type='';
    hdr.hk.db_name='';
    hdr.hk.extents = 0;
    hdr.hk.session_error = 0;
    hdr.hk.regular='r';
    hdr.hk.dim_info = 0;

    hdr.hist.descrip='';
    hdr.hist.aux_file='';
    hdr.hist.intent_name='';
    hdr.hist.srow_x = [ 2 0 0 -1 ];
    hdr.hist.srow_y = [ 0 2 0 -1 ];
    hdr.hist.srow_z = [ 0 0 2 -1 ];
    hdr.hist.quatern_c = 0;
    hdr.hist.originator = [ 2 1 1 1 ];

    hdr.hist.sform_code = 0;
    hdr.hist.qform_code = 0;

    % set up qform
    m=[hdr.hist.srow_x;hdr.hist.srow_y;hdr.hist.srow_z];
    quatern_a=.5*sqrt(1+m(1,1)+m(2,2)+m(3,3));
    hdr.hist.quatern_b = .25*(m(3,2)-m(2,3)) / quatern_a;
    hdr.hist.quatern_c = .25*(m(1,3)-m(3,1)) / quatern_a;
    hdr.hist.quatern_d = .25*(m(2,1)-m(1,2)) / quatern_a;

    hdr.hist.qoffset_x = m(1,4);
    hdr.hist.qoffset_y = m(2,4);
    hdr.hist.qoffset_z = m(3,4);

    data=zeros(3,2,1,2);
    data(:,:,1,1)=[ 2.0317  1.3494; -3.6849 -0.2617; -1.0504   -0.2040];
    data(:,:,1,2)=[ 0.5838 -0.3973;  1.7235  2.3387; -1.3265    0.4823];

    nii=struct();
    nii.hdr=hdr;
    nii.img=single(data);

function s=clear_fields(s,keys)
    n=numel(keys);
    for k=1:n
        key=keys{k};
        v=s.(key);
        v(:)=0;
        s.(key)=v;
    end

