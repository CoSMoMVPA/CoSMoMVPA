function test_suite=test_fmri_io
    initTestSuite;

function test_fmri_io_base
    x_base=get_base_dataset();

    x=x_base;
    exts={'.nii.gz', '.nii', '.hdr', '.img', '+orig.HEAD',...
              '+tlrc.BRIK','.vmp',...
              '.vmr', '.msk', };
    keep_exts=true(numel(exts),1);

    if ~usejava('jvm')
        cosmo_notify_test_skipped(['.nii.gz (gzipped) fmri i/o cannot be '...
                    'tested because the java virtual machine is not '...
                    'available']);
        keep_exts=keep_exts && ~cosmo_match(exts,'.nii.gz');
    end

    if cosmo_wtf('is_octave') || ~cosmo_check_external('neuroelf',false)
        cosmo_notify_test_skipped(['BrainVoyager fmri i/o cannot be '...
                    'tested because ''neuroelf'' is not '...
                    'available']);
        keep_exts=keep_exts && ~cosmo_match(exts,{'.vmp','.vmr','msk'});
    end

    exts=exts(keep_exts);

    n=numel(exts);
    for k=1:n
        ext=exts{k};
        y=save_and_load(x_base,ext);
        assert_samples_equal(x.samples,y.samples,ext);
        assert_a_equal(x,y,ext);
        assert_fa_equal(x,y,ext);
    end

function assert_samples_equal(xs,ys,ext)
    switch ext
        case '.msk'
            assert(cosmo_corr(xs',ys')>.999);
        case '.vmr'
            assert(cosmo_corr(xs',ys')>.999);
        otherwise
            assertElementsAlmostEqual(xs,ys,'relative',1e-5);
    end


function assert_a_equal(xd,yd,ext)
    x=xd.a;
    y=yd.a;
    x.vol=rmfield_if_present(x.vol,'xform');
    y.vol=rmfield_if_present(y.vol,'xform');

    switch ext
        case '.vmr'
            % does not store the offset, so do not check it
            x.vol.mat=x.vol.mat(:,1:3);
            y.vol.mat=y.vol.mat(:,1:3);
        otherwise
            % keep as is
    end

    assertEqual(x,y);

function assert_fa_equal(x,y,ext)
    assertEqual(x.fa,y.fa);


function s=rmfield_if_present(s, f)
    if isfield(s,f)
        s=rmfield(s,f);
    end


function x=get_base_dataset()
    x=cosmo_synthetic_dataset('size','big');
    x=cosmo_fmri_reorient(x,'ASR');
    x=cosmo_slice(x,1);

function ds_again=save_and_load(ds,ext)
    pat=['tmp%d' ext];
    fn=get_temp_filename(pat);
    fn2=get_sibling(fn,ext);
    cleaner=onCleanup(@()delete_files({fn,fn2}));


    cosmo_map2fmri(ds,fn);
    ds_again=cosmo_fmri_dataset(fn);

function sib_fn=get_sibling(fn,ext)
    switch ext
        case '.img'
            sib_ext='hdr';
        case '.hdr'
            sib_ext='img';
        case '+orig.HEAD'
            sib_ext='+orig.BRIK';
        case '+orig.BRIK'
            sib_ext='+orig.HEAD';
        case '+tlrc.HEAD'
            sib_ext='+tlrc.BRIK';
        case '+tlrc.BRIK'
            sib_ext='+tlrc.HEAD';
        otherwise
            sib_fn=[];
            return
    end

    sib_fn=strrep(fn,ext,sib_ext);


function delete_files(fns)
    for k=1:numel(fns)
        fn=fns{k};
        if ~isempty(fn) && exist(fn,'file')
            delete(fn);
        end
    end

function temp_path=get_temp_path()
    c=cosmo_config();
    if ~isfield(c,'temp_path')
        error('temp_path is not set in cosmo_config');
    end
    temp_path=c.temp_path;

function fn=get_temp_filename(pat)
    temp_path=get_temp_path();
    k=0;
    while true
        fn=fullfile(temp_path,sprintf(pat,k));
        if ~exist(fn,'file')
            return;
        end
        k=k+1;
    end
