function test_suite=test_meeg_find_layout()
% tests for cosmo_meeg_find_layout
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;

function test_meeg_find_layout_()
    if cosmo_skip_test_if_no_external('fieldtrip')
        return;
    end

    coverage=1; % allow for covering subset only

    props=get_props();
    n=numel(props);
    prev_name='';

    rp=randperm(n);
    rp=rp(1:ceil((coverage*n)));
    for k=1:numel(rp)
        prop=props{rp(k)};

        name=prop{1};
        chantype=prop{2};
        lay_prop=prop{3};
        parent_lay_prop=prop{4};
        unsupp=prop{5};

        if ~strcmp(prev_name,name)
            ds=cosmo_synthetic_dataset('type','meeg','size','big',...
                                'sens',name,'ntargets',1,'nchunks',1);
        end

        lay=cosmo_meeg_find_layout(ds,'chantype',chantype);

        check_lay(lay,lay_prop);
        if ~isempty(parent_lay_prop)
            check_lay(lay.parent,parent_lay_prop);
        end

        for j=1:numel(unsupp)
            assertExceptionThrown(@()cosmo_meeg_find_layout(ds,...
                            'chantype',unsupp{j}),'');
        end

        prev_name=name;
    end


function check_lay(lay,lay_prop)
    if isempty(lay.name) && isempty(lay_prop{1})
        return
    end
    assertEqual(lay.name,lay_prop{1});

    nchans=lay_prop{2};
    keep=find(~cosmo_match(lay.label,{'COMNT','SCALE'}));
    assertEqual(numel(keep),nchans);

    assertEqual(size(lay.pos,1),numel(lay.width));
    assertEqual(size(lay.pos,1),numel(lay.height));
    assertEqual(size(lay.pos,1),numel(lay.label));

    chans=lay_prop{3};
    has_child=~isempty(lay_prop{5});
    assertEqual(has_child, isfield(lay,'child_label'));

    for j=1:numel(chans)
        if j==1
            cpos=1;
        elseif j==numel(chans)
            cpos=nchans-2;
        end
        if ~strcmp(chans{j},lay.label(cpos))
            cpos=find(strcmp(chans{j},lay.label));
            assert(numel(cpos)==1)
        end
        assertVectorsAlmostEqual(lay.pos(cpos,:),lay_prop{4}(j,:),...
                            'absolute',1e-4);
        if has_child
            assertEqual(lay.child_label{cpos}(:),lay_prop{5}{j}(:));
        end
    end


function props=get_props()
    props={{'neuromag306_all','meg_planar',...
		{'neuromag306planar.lay',204,...
				{'MEG0113', 'MEG2643'},...
				[-0.4084 0.2532;0.3733 -0.0820],...
				[]},...
		[],...
		{'eeg', 'meg_planar_combined'}},...
{'neuromag306_all','meg_axial',...
		{'neuromag306mag.lay',102,...
				{'MEG0111', 'MEG2641'},...
				[-0.4084 0.2732;0.3733 -0.1036],...
				[]},...
		[],...
		{'eeg', 'meg_planar_combined'}},...
{'neuromag306_all','meg_combined_from_planar',...
		{'neuromag306planar.lay',204,...
				{'MEG0113', 'MEG2643'},...
				[-0.4084 0.2532;0.3733 -0.0820],...
				[]},...
		{'neuromag306cmb.lay',102,...
				{'MEG0112+0113', 'MEG2642+2643'},...
				[-0.4084 0.2732;0.3733 -0.1036],...
				{{'MEG0112', 'MEG0113'},{'MEG2642', 'MEG2643'}}},...
		{'eeg', 'meg_planar_combined'}},...
{'neuromag306_planar','meg_planar',...
		{'neuromag306planar.lay',204,...
				{'MEG0113', 'MEG2643'},...
				[-0.4084 0.2532;0.3733 -0.0820],...
				[]},...
		[],...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'neuromag306_planar','meg_combined_from_planar',...
		{'neuromag306planar.lay',204,...
				{'MEG0113', 'MEG2643'},...
				[-0.4084 0.2532;0.3733 -0.0820],...
				[]},...
		{'neuromag306cmb.lay',102,...
				{'MEG0112+0113', 'MEG2642+2643'},...
				[-0.4084 0.2732;0.3733 -0.1036],...
				{{'MEG0112', 'MEG0113'},{'MEG2642', 'MEG2643'}}},...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'neuromag306_planar_combined','meg_planar_combined',...
		{'neuromag306cmb.lay',102,...
				{'MEG0112+0113', 'MEG2642+2643'},...
				[-0.4084 0.2732;0.3733 -0.1036],...
				[]},...
		[],...
		{'eeg', 'meg_axial', 'meg_combined_from_planar', 'meg_planar'}},...
{'ctf151','meg_axial',...
		{'CTF151.lay',151,...
				{'MLC11', 'MZP02'},...
				[-0.0344 0.1732;0.0008 -0.2668],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'ctf151_planar','meg_planar',...
		{'',302,...
				{'MLC11_dH', 'MZP02_dV'},...
				[-0.0344 0.1732;0.0008 -0.2668],...
				[]},...
		[],...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'ctf151_planar','meg_combined_from_planar',...
		{'',302,...
				{'MLC11_dH', 'MZP02_dV'},...
				[-0.0344 0.1732;0.0008 -0.2668],...
				[]},...
		{'CTF151.lay',151,...
				{'MLC11', 'MZP02'},...
				[-0.0344 0.1732;0.0008 -0.2668],...
				{{'MLC11_dH', 'MLC11_dV'},{'MZP02_dH', 'MZP02_dV'}}},...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'ctf151_planar_combined','meg_planar_combined',...
		{'CTF151.lay',151,...
				{'MLC11', 'MZP02'},...
				[-0.0344 0.1732;0.0008 -0.2668],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'4d148','meg_axial',...
		{'4D148.lay',148,...
				{'A1', 'A148'},...
				[-0.0109 0.0939;0.3709 0.3364],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'4d148_planar','meg_planar',...
		{'',296,...
				{'A1_dH', 'A148_dV'},...
				[-0.0109 0.0939;0.3709 0.3364],...
				[]},...
		[],...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'4d148_planar','meg_combined_from_planar',...
		{'',296,...
				{'A1_dH', 'A148_dV'},...
				[-0.0109 0.0939;0.3709 0.3364],...
				[]},...
		{'4D148.lay',148,...
				{'A1', 'A148'},...
				[-0.0109 0.0939;0.3709 0.3364],...
				{{'A1_dH', 'A1_dV'},{'A148_dH', 'A148_dV'}}},...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'4d148_planar_combined','meg_planar_combined',...
		{'4D148.lay',148,...
				{'A1', 'A148'},...
				[-0.0109 0.0939;0.3709 0.3364],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'4d248','meg_axial',...
		{'4D248.lay',248,...
				{'A1', 'A248'},...
				[0.0038 0.0232;0.3897 0.3453],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'4d248_planar','meg_planar',...
		{'',496,...
				{'A1_dH', 'A248_dV'},...
				[0.0038 0.0232;0.3897 0.3453],...
				[]},...
		[],...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'4d248_planar','meg_combined_from_planar',...
		{'',496,...
				{'A1_dH', 'A248_dV'},...
				[0.0038 0.0232;0.3897 0.3453],...
				[]},...
		{'4D248.lay',248,...
				{'A1', 'A248'},...
				[0.0038 0.0232;0.3897 0.3453],...
				{{'A1_dH', 'A1_dV'},{'A248_dH', 'A248_dV'}}},...
		{'eeg', 'meg_axial', 'meg_planar_combined'}},...
{'4d248_planar_combined','meg_planar_combined',...
		{'4D248.lay',248,...
				{'A1', 'A248'},...
				[0.0038 0.0232;0.3897 0.3453],...
				[]},...
		[],...
		{'eeg', 'meg_combined_from_planar', 'meg_planar'}},...
{'eeg1020','',...
		{'EEG1020.lay',21,...
				{'Fp1', 'O2'},...
				[-0.1390 0.4280;0.1390 -0.4280],...
				[]},...
		[],...
		{'meg_axial', 'meg_combined_from_planar', 'meg_planar', 'meg_planar_combined'}},...
{'eeg1010','',...
		{'EEG1010.lay',86,...
				{'Fp1', 'I2'},...
				[-0.1112 0.4260;0.1390 -0.4256],...
				[]},...
		[],...
		{'meg_axial', 'meg_combined_from_planar', 'meg_planar', 'meg_planar_combined'}},...
{'eeg1005','',...
		{'EEG1005.lay',335,...
				{'Fp1', 'OI2'},...
				[-0.1112 0.3880;0.1252 -0.3814],...
				[]},...
		[],...
		{'meg_axial', 'meg_combined_from_planar', 'meg_planar', 'meg_planar_combined'}},...
    };


