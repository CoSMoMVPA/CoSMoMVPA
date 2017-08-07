function test_suite = test_statcode()
% tests for cosmo_statcode
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_statcode_self()
    stats=get_test_stats();
    assertEqual(cosmo_statcode(stats),stats);

    ds=struct();
    ds.samples=[];
    assertEqual(cosmo_statcode(ds),[]);

    ds.sa.stats=stats;
    assertEqual(cosmo_statcode(ds),stats);

    aet=@(varargin)assertExceptionThrown(@()...
                            cosmo_statcode(varargin{:}),'');
    % store warning state
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    % test illegal input
    aet({'()'});
    aet({'foo(;)'});
    aet({'Zscore()'},'foo');
    aet('Zscore');

    % unknown input
    s=cosmo_statcode({'foo'},'afni');
    assertEqual(s.BRICK_STATAUX,[]);

    s=cosmo_statcode({'foo'},'nifti');
    assertEqual(s.intent_code,0);
    assertEqual(s.intent_p1,0);
    assertEqual(s.intent_p1,0);
    assertEqual(s.intent_p1,0);

    % empty input
    assertEqual(cosmo_statcode({}),cell(0,1));
    assertEqual(cosmo_statcode({},'bv'),cell(0,1));
    assertEqual(cosmo_statcode({},'nifti'),struct());
    assertEqual(cosmo_statcode({},'afni'),...
                        cosmo_structjoin('BRICK_STATAUX',[]));




function test_statcode_bv()
    [stats,stats_proper]=get_test_stats();
    bv_statcode=cosmo_statcode(stats,'bv');
    bv_values={[],[1 5],[4 2 3],5,5,[]};
    nvalues=numel(bv_values);
    assertEqual(nvalues,numel(bv_statcode))

    for j=1:numel(bv_values)
        bv_value=bv_values{j};

        s=struct();
        nv=numel(bv_value);

        if nv==0
            s.Type=0;
        else
            s.Type=bv_value(1);
            for k=1:(nv-1)
                label=sprintf('DF%d',k);
                s.(label)=bv_value(k+1);
            end
        end

        assertEqual(s,bv_statcode{j});
    end

    bv_map=struct();
    bv_map.VMRDimX=[];
    bv_map.VMRDimX=[];

    map_cell=cell(nvalues,1);
    for k=1:numel(map_cell)
        m=struct();
        m.DF1=0;
        m.DF2=0;
        m.DF3=0;
        m.Type=0;

        if ~isempty(bv_statcode{k})
            m=cosmo_structjoin(m,bv_statcode{k});
        end
        map_cell{k}=m;
    end

    bv_map.Map=cat(1,map_cell{:});
    assertEqual(cosmo_statcode(bv_map),stats_proper);



function test_statcode_afni()
    [stats,stats_proper]=get_test_stats();
    afni_statcode=cosmo_statcode(stats,'afni');
    afni_struct=struct();
    afni_struct.BRICK_STATAUX=[1 3 1 5 2 4 2 2 3 3 5 0 4 5 0];
    assertEqual(afni_statcode,afni_struct);

    afni_struct.DATASET_RANK=[NaN numel(stats)];
    assertEqual(cosmo_statcode(afni_struct),stats_proper);

    % error for too many elements
    afni_struct.BRICK_STATAUX(end+1)=0;
    afni_struct.BRICK_STATAUX(end+1)=0;
    assertExceptionThrown(@()cosmo_statcode(afni_struct),'');
    afni_struct.BRICK_STATAUX=afni_struct.BRICK_STATAUX(1:(end-3));
    assertExceptionThrown(@()cosmo_statcode(afni_struct),'');
    afni_struct.BRICK_STATAUX=afni_struct.BRICK_STATAUX(1:(end-6));
    assertExceptionThrown(@()cosmo_statcode(afni_struct),'');

function test_statcode_nifti()
    stats=get_test_stats();

    % NIFTI does not support multiple stats
    % silence warning
    warning_state=cosmo_warning();
    cleaner=onCleanup(@()cosmo_warning(warning_state));
    cosmo_warning('off');

    assertEqual(cosmo_statcode(stats,'nifti'),struct());
    stats=repmat(stats(3),6,1);
    stats_proper=stats;

    nifti_statcode=cosmo_statcode(stats,'nifti');
    nifti_dime=struct();
    nifti_dime.intent_code=4;
    nifti_dime.intent_p1=2;
    nifti_dime.intent_p2=3;
    nifti_dime.intent_p3=0;

    assertEqual(nifti_statcode,nifti_dime);
    nifti_hdr=struct();
    nifti_hdr.dime=nifti_dime;
    nifti_hdr.dime.dim=[NaN NaN NaN NaN 1 numel(stats) 1];
    assertEqual(cosmo_statcode(nifti_hdr),stats_proper);





function [stats,stats_proper]=get_test_stats()
    stats={'none';'Ttest(5)';'Ftest(2,3)';'Zscore';'Zscore()';''};
    stats_proper=stats;
    stats_proper{1}='';
    stats_proper{4}='Zscore()';
    stats_proper{6}='';
