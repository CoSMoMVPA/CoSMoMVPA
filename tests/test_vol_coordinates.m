function test_suite = test_vol_coordinates
% tests for cosmo_vol_coordinates
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_vol_coordinates_()
    ds=cosmo_synthetic_dataset();

    [ns,nf]=size(ds.samples);

    % sample some features
    rp=randperm(nf);
    nsel=round(nf/2);
    rp=rp(1:nsel);
    ds_sel=cosmo_slice(ds,rp,2);

    % voxel to world space
    xyz=cosmo_vol_coordinates(ds_sel);
    assertEqual(size(ds_sel.samples),[ns nsel]);

    xyz_=cosmo_vol_coordinates(ds_sel,1:nsel);
    assertEqual(xyz, xyz_);

    selsel=randperm(nsel);
    xyz__=cosmo_vol_coordinates(ds_sel,selsel);
    assertEqual(xyz(:,selsel), xyz__);

    % check coordinate transform
    ijk1=[ds_sel.fa.i; ds_sel.fa.j; ds_sel.fa.k; ones(1,nsel)];
    xyz1=ds.a.vol.mat*ijk1;
    assertElementsAlmostEqual(xyz1(1:3,:),xyz_);

    % double the dataset
    ds_sel2=cosmo_stack({ds_sel,ds_sel},2);
    xyz2=cosmo_vol_coordinates(ds_sel2);
    assertEqual(xyz2, [xyz xyz]);

    % world to voxel space
    fa_indices=cosmo_vol_coordinates(ds_sel,xyz(:,selsel));
    assertVectorsAlmostEqual(fa_indices,selsel);

    % duplicate features cannot be matched back
    assertExceptionThrown(@()cosmo_vol_coordinates(ds_sel2,...
                                            xyz(:,selsel)),'');


function test_vol_coordinates_afni()
% test coordinates using AFNI's 3dmerge
    if cosmo_skip_test_if_no_external('afni_bin')
        return;
    end
    % make an fMRI dataset
    dim_sizes=[60 50 30];
    dim_values=cellfun(@(x) 1:x,num2cell(dim_sizes),'UniformOutput',false);
    dim_labels={'i','j','k'};
    vox_sizes=[3 3 3];
    origin=-dim_sizes.*vox_sizes*.4; % slightly off-center
    nsamples=2;

    data4d=zeros([nsamples,dim_sizes]);

    ds=cosmo_flatten(data4d,dim_labels,dim_values);
    ds.sa.labels=cellfun(@(x) sprintf('sample%d',x),...
                                    num2cell(1:nsamples)',...
                                    'UniformOutput',false);
    ds.sa.stats=repmat({'Ftest(10,1)'},nsamples,1);
    ds.a.vol.mat=[diag(vox_sizes),origin';[0 0 0 1]];
    ds.a.vol.dim=dim_sizes;


    ds.sa.labels=ds.sa.labels(:,1);

    center_distance=20;
    offsets=[3 7 11]; % some offsets in x, y, z directions
    xyz=bsxfun(@plus, cosmo_cartprod(repmat({[-1,1]*center_distance},1,3)),...
                        offsets);
    ncoord=size(xyz,1);

    fa_indices=cosmo_vol_coordinates(ds,xyz');
    xyz=cosmo_vol_coordinates(ds,fa_indices); % recompute
    ds.samples(:,fa_indices)=repmat(1:ncoord,nsamples,1); % 1 to 8

    % make temporary directory
    tmp_dir=cosmo_make_temp_filename();
    tmp_dir_cleaner=onCleanup(@()remove_dir_helper(tmp_dir));

    mkdir(tmp_dir);

    % generate AFNI files
    ext_postfix={'.nii',{''};
                 '+orig',{'.BRIK','.BRIK.gz','.HEAD'}};
    for j=1:size(ext_postfix,1)
        ext=ext_postfix{j,1};
        postfixes=ext_postfix{j,2};

        get_fn=@(x) fullfile(tmp_dir,[x ext]);
        get_to_delete=@(x,exts) cellfun(@(y) sprintf('%s%s',...
                            get_fn(x),y),postfixes,'UniformOutput',false);

        base_fn=get_fn('base');
        cosmo_map2fmri(ds,base_fn);

        orients={'lpi','rai','asr'};

        for k=1:numel(orients)
            orient=orients{k};
            fn=get_fn(orient);
            cmd=sprintf('3dresample -overwrite -orient %s -prefix %s -input %s',...
                            orient, fn, base_fn);
            r=unix(cmd);
            assert(r==0);
            cmd=sprintf(['3dclust -orient LPI -1clip .5 0 0 %s''[0]'' '...
                        '2>/dev/null | grep --invert-match ''#'''], fn);
            [r,v]=unix(cmd);
            assert(r==0);

            to_delete=get_to_delete(orient,postfixes);
            cmd=sprintf('rm -f %s', cosmo_strjoin(to_delete,' '));
            unused=unix(cmd);

            s=sscanf(v,'%f');
            table=reshape(s,16,[]);

            % sort by voxel value
            [unused,i]=sort(table(11,:));
            table=table(:,i);

            line1=ones(1,ncoord);
            line0=0*line1;
            line_inc=1:ncoord;
            expected_table=[line1; xyz; kron(xyz,[1 1]'); ...
                                line_inc; line0; line_inc; xyz];
            assertEqual(table, expected_table)
        end
    end

function test_test_vol_coordinates_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                    cosmo_vol_coordinates(varargin{:}),'');

    ds=cosmo_synthetic_dataset();

    % not 1xP or 3xP
    aet(ds, ones(2));
    aet(ds, [1;2]);

    % not in fdim
    ds_bad=ds;
    ds_bad=cosmo_dim_transpose(ds_bad,'i',1);
    aet(ds_bad,1);

    % size mismatch
    ds_bad=ds;
    ds_bad.a.vol.dim=ds_bad.a.vol.dim+1;
    aet(ds_bad,1);

    % no matrix
    ds_bad=ds;
    ds_bad.a.vol=rmfield(ds_bad.a.vol,'mat');
    aet(ds_bad,1);

    % not 4x4 matrix
    ds_bad=ds;
    ds_bad.a.vol.mat=eye(5);
    aet(ds_bad,1);



function remove_dir_helper(tmp_dir)
    if cosmo_wtf('is_octave')
        rmdir_state=confirm_recursive_rmdir();
        state_resetter=onCleanup(@()confirm_recursive_rmdir(rmdir_state);
        confirm_recursive_rmdir(false,'local');
    end
    rmdir(tmp_dir,'s');



