function test_suite = test_fmri_dataset()
    initTestSuite;


function test_base_fmri_dataset()
    ds=get_base_dataset();
    assert_dataset_equal(ds, get_expected_dataset());

function test_afni_fmri_dataset()
    ds=get_base_dataset();
    afni=cosmo_map2fmri(ds,'-afni');
    assertAlmostEqualWithTol(afni, get_expected_afni());
    ds_afni=cosmo_fmri_dataset(afni);
    assert_dataset_equal(ds,ds_afni);

function test_nii_fmri_dataset()
    ds=get_base_dataset();
    nii=cosmo_map2fmri(ds,'-nii');
    assertAlmostEqualWithTol(nii, get_expected_nii());
    ds_nii=cosmo_fmri_dataset(nii);
    assert_dataset_equal(ds,ds_nii);

function test_bv_vmr_fmri_dataset()
    if ~can_test_bv()
        return
    end
    uint_ds=get_uint8_dataset();
    bv_vmr=cosmo_map2fmri(uint_ds,'-bv_vmr');
    bless(bv_vmr);
    assert_bv_equal(bv_vmr, get_expected_bv_vmr());
    ds_bv_vmr=cosmo_fmri_dataset(bv_vmr,'mask',false);
    ds_bv_vmr_lpi=cosmo_fmri_reorient(ds_bv_vmr,'LPI');
    assert_dataset_equal(uint_ds,ds_bv_vmr_lpi,'rotation');
    bv_vmr.ClearObject();

function test_bv_vmp_fmri_dataset()
    if ~can_test_bv()
        return
    end

    ds=get_base_dataset();
    bv_vmp=cosmo_map2fmri(ds,'-bv_vmp');
    assert_bv_equal(bv_vmp, get_expected_bv_vmp());
    bless(bv_vmp);
    ds_bv_vmp=cosmo_fmri_dataset(bv_vmp);
    ds_bv_vmp_lpi=cosmo_fmri_reorient(ds_bv_vmp,'LPI');
    assert_dataset_equal(ds,ds_bv_vmp_lpi,'translation');
    bv_vmp.ClearObject();

function test_bv_msk_fmri_dataset()
    if ~can_test_bv()
        return
    end

    uint_ds=get_uint8_dataset();
    bv_msk=cosmo_map2fmri(uint_ds,'-bv_msk');
    bless(bv_msk);
    assert_bv_equal(bv_msk, get_expected_bv_msk());

    ds_bv_msk=cosmo_fmri_dataset(bv_msk);
    ds_bv_msk_lpi=cosmo_fmri_reorient(ds_bv_msk,'LPI');
    assert_dataset_equal(uint_ds,ds_bv_msk_lpi,'translation');
    bv_msk.ClearObject();

function tf=can_test_bv()
    tf=cosmo_wtf('is_matlab') && cosmo_check_external('xff');
    if ~tf
        cosmo_notify_skip_test(['BrainVoyager fmri i/o cannot be '...
                    'tested because ''xff'' is not '...
                    'available']);
    end


function ds=get_base_dataset()
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',1);

function ds=get_uint8_dataset()
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',1);
    ds=cosmo_slice(ds,1);
    mn=min(ds.samples);
    mx=max(ds.samples);
    ds.samples=uint8((ds.samples-mn)/(mx-mn)*255);

function assertAlmostEqualWithTol(x,y)
    assertAlmostEqual(x,y,'relative',1e-3);


function assert_dataset_equal(x,y,opt)
    if nargin<3 || isempty(opt)
        opt='';
    end
    % dataset equality, without .sa
    assertAlmostEqualWithTol(double(x.samples), double(y.samples));
    assertAlmostEqualWithTol(x.fa, y.fa)

    switch opt
        case 'rotation'
            % BV VMR cannot store orientation, just check the rotation part
            assertAlmostEqualWithTol(x.a.fdim, y.a.fdim);
            assertAlmostEqualWithTol(x.a.vol.dim,y.a.vol.dim);
            assertAlmostEqualWithTol(x.a.vol.mat(1:3,1:3),...
                            y.a.vol.mat(1:3,1:3));
        case 'translation'
            % BV VMP cannot store xform, just check the matrix
            assertAlmostEqualWithTol(x.a.fdim, y.a.fdim);
            assertAlmostEqualWithTol(x.a.vol.dim,y.a.vol.dim);
            assertAlmostEqualWithTol(x.a.vol.mat,y.a.vol.mat);
        otherwise
            assertAlmostEqualWithTol(x.a, y.a)
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
            assert_bv_equal(x,y)
        else
            assertAlmostEqualWithTol(x,y);
        end

    end

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

    map1.VMPData=reshape([-0.2040   -1.0504   -0.2617   -3.6849    1.3494    2.0317],...
                                                        [2 1 3]);
    map2.VMPData=reshape([3.0349 -1.3077 4.4438 2.5365 0.3426 1.8339],...
                                                        [2 1 3]);
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
    ds.a.fdim.labels={'i','j','k'};
    ds.a.fdim.values={[1 2 3],[1 2],1};
    mat=diag([2 2 2 1]);
    mat(1:3,4)=-3;
    ds.a.vol.mat=mat;
    ds.a.vol.dim=[3 2 1];
    ds.a.vol.xform='scanner_anat';


function nii=get_expected_nii()
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
    hdr.hist.sform_code = 1;
    hdr.hist.descrip='';
    hdr.hist.aux_file='';
    hdr.hist.intent_name='';
    hdr.hist.qform_code = 0;
    hdr.hist.quatern_b = 0;
    hdr.hist.quatern_d = 0;
    hdr.hist.qoffset_x = 0;
    hdr.hist.qoffset_y = 0;
    hdr.hist.qoffset_z = 0;
    hdr.hist.srow_x = [ 2 0 0 -1 ];
    hdr.hist.srow_y = [ 0 2 0 -1 ];
    hdr.hist.srow_z = [ 0 0 2 -1 ];
    hdr.hist.quatern_c = 0;
    hdr.hist.originator = [ 2 1 1 1 ];

    data=zeros(3,2,1,2);
    data(:,:,1,1)=[ 2.0317  1.3494; -3.6849 -0.2617; -1.0504   -0.2040];
    data(:,:,1,2)=[ 0.5838 -0.3973;  1.7235  2.3387; -1.3265    0.4823];

    nii=struct();
    nii.hdr=hdr;
    nii.img=single(data);


