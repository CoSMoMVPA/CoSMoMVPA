function test_suite=test_meeg_chan_neighbors()
% tests for cosmo_meeg_chan_neighbors
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;


function test_meeg_neighbors()
    if cosmo_skip_test_if_no_external('fieldtrip')
        return;
    end

    % switch off warnings by fieldtrip
    warning_state=warning('query','all');
    cleaner=onCleanup(@()warning(warning_state));
    warning('off','all');

    props=get_props();
    n=numel(props);

    % test a subset
    ntest=round(n*.5);


    % test a subset for fieldtrip
    % (fieldtrip is very slow, so testing all would take too long)
    ntest_fieldtrip=1;

    % visit in random order
    rp=randperm(n);

    prev_sens='';
    for k=1:ntest
        prop=props{rp(k)};

        sens=prop{1};
        layout_name=prop{2};
        args=prop{3};
        nchan=prop{4};
        chan_stats=prop{5};
        chan_labels=prop{6};

        if ~isequal(sens,prev_sens)
            ds=cosmo_synthetic_dataset('type','meeg',...
                                        'sens',sens,...
                                        'size','big');
        end

        nbrs=cosmo_meeg_chan_neighbors(ds,args{:});
        assertEqual(numel(nbrs),nchan);


        chan_count=cellfun(@numel,{nbrs.neighblabel});
        stats=[min(chan_count), max(chan_count), mean(chan_count)];
        assertElementsAlmostEqual(stats, chan_stats,'relative',1e-3);

        % test neighbor labels
        for j=1:numel(chan_labels)
            chan_label=chan_labels{j};
            center=chan_label{1};
            around=chan_label{2};

            % little optimization for finding first and last channel
            if j==1
                pos=1;
            else
                pos=nchan;
            end


            if ~strcmp(center,nbrs(pos).label)
                pos=find(cosmo_match({nbrs.label},center));
                assert(numel(pos)==1);
            end


            assertEqual(sort(around(:)),sort(nbrs(pos).neighblabel));
        end

        can_test_fieldtrip=~isempty(layout_name) && ...
                                isequal(args{4},'layout') && ...
                                ~strcmp(args{1},'count');
        if can_test_fieldtrip && ntest_fieldtrip>0
            cfg=struct();
            cfg.layout=layout_name;
            switch args{1}
                case 'delaunay'
                    cfg.method='triangulation';
                case 'radius'
                    cfg.method='distance';
                    cfg.neighbourdist=args{2};
                otherwise
                    assert(false);
            end
            y=ft_prepare_neighbours(cfg);

            % reorder the labels if necessary
            nbrs_cell=cellfun(@(x){x},{nbrs.label},'UniformOutput',false);
            y_cell=cellfun(@(x){x},{y.label},'UniformOutput',false);

            p=cosmo_overlap(nbrs_cell,y_cell);
            [i,j]=find(p==1);
            y=y(i);

            assertEqual({nbrs.label},{y.label});

            [p,q]=cosmo_overlap({nbrs.neighblabel},{y.neighblabel});
            dp=diag(p);
            dq=diag(q);
            assert(mean(dp(isfinite(dp)))>.9);
            assert(mean(dq(isfinite(dq)))>.8);

            ntest_fieldtrip=ntest_fieldtrip-1;
        end
    end







function props=get_props()

    % properties to test; each cell has these elements:
    % - dataset type
    % - arguments for neighbors
    % - number of neighbors
    % - min, max, mean number of channels
    % - a few channel labels and their neighbors
    props={{'neuromag306_all',...
                'neuromag306mag.lay',...
                {'delaunay',true,'label','layout','chantype',...
                    'meg_axial'},...
                102,[5 11 7.9412],...
                {{'MEG0111',...
                        {'MEG0111','MEG0121','MEG0131',...
                            'MEG0141','MEG0341','MEG0511'}},...
                    {'MEG2641',...
                        {'MEG1331','MEG2421','MEG2431',...
                            'MEG2441','MEG2521','MEG2611',...
                            'MEG2621','MEG2631','MEG2641'}}}},...
            {'neuromag306_all',...
                'neuromag306planar.lay',...
                {'delaunay',true,'label','layout','chantype',...
                    'meg_planar'},...
                204,[4 12 8.0392],...
                {{'MEG0113',...
                        {'MEG0113','MEG0112','MEG0122',...
                            'MEG0132','MEG0133','MEG0142',...
                            'MEG0343'}},...
                    {'MEG2643',...
                        {'MEG1333','MEG2423','MEG2422',...
                            'MEG2612','MEG2623','MEG2622',...
                            'MEG2642','MEG2643'}}}},...
            {'neuromag306_planar',...
                'neuromag306planar.lay',...
                {'radius',0.1,'label','dataset','chantype',...
                    'meg_planar'},...
                204,[4 14 8.9118],...
                {{'MEG0113',...
                        {'MEG0113','MEG0112','MEG0122',...
                            'MEG0132','MEG0133'}},...
                    {'MEG2643',...
                        {'MEG2423','MEG2422','MEG2623',...
                            'MEG2622','MEG2632','MEG2642',...
                            'MEG2643'}}}},...
            {'neuromag306_planar',...
                'neuromag306planar.lay',...
                {'radius',0.1,'label','dataset','chantype',...
                    'meg_combined_from_planar'},...
                102,[4 16 8.9804],...
                {{'MEG0112+0113',...
                        {'MEG0112','MEG0113','MEG0122',...
                            'MEG0123','MEG0132','MEG0133'}},...
                    {'MEG2642+2643',...
                        {'MEG2422','MEG2423','MEG2622',...
                            'MEG2623','MEG2632','MEG2633',...
                            'MEG2642','MEG2643'}}}},...
            {'neuromag306_planar_combined',...
                'neuromag306cmb.lay',...
                {'count',5,'label','layout','chantype',...
                    'meg_planar_combined'},...
                102,[5 5 5],...
                {{'MEG0112+0113',...
                        {'MEG0112+0113','MEG0122+0123',...
                            'MEG0132+0133','MEG0212+0213',...
                            'MEG0342+0343'}},...
                    {'MEG2642+2643',...
                        {'MEG2422+2423','MEG2432+2433',...
                            'MEG2622+2623','MEG2632+2633',...
                            'MEG2642+2643'}}}},...
            {'ctf151',...
                'CTF151.lay',...
                {'delaunay',true,'label','dataset','chantype',...
                    'meg_axial'},...
                151,[5 11 8.404],...
                {{'MLC11',...
                        {'MLC11','MLC12','MLC21','MLF41',...
                            'MLF51','MLF52','MRC11','MZC01',...
                            'MZF03'}},...
                    {'MZP02',...
                        {'MLO11','MLP21','MLP31','MRO11',...
                            'MRP21','MRP31','MZO01','MZP01',...
                            'MZP02'}}}},...
            {'ctf151',...
                'CTF151.lay',...
                {'delaunay',true,'label','dataset','chantype',...
                    'meg_planar_combined'},...
                151,[5 11 8.404],...
                {{'MLC11',...
                        {'MLC11','MLC12','MLC21','MLF41',...
                            'MLF51','MLF52','MRC11','MZC01',...
                            'MZF03'}},...
                    {'MZP02',...
                        {'MLO11','MLP21','MLP31','MRO11',...
                            'MRP21','MRP31','MZO01','MZP01',...
                            'MZP02'}}}},...
            {'ctf151_planar',...
                [],...
                {'radius',0.1,'label',...
                    {'MLC11_dH','MLC12_dH','MLC13_dH',...
                        'MLC14_dH','MLC15_dH','MLC21_dH',...
                        'MRT41_dV','MRT42_dV','MRT43_dV',...
                        'MRT44_dV','MZC01_dV','MZC02_dV'},...
                    'chantype','meg_planar'},...
                12,[1 4 2.3333],...
                {{'MLC11_dH',...
                        {'MLC11_dH','MLC12_dH','MLC21_dH',...
                            'MZC01_dV'}},...
                    {'MZC02_dV',{'MZC02_dV'}}}},...
            {'ctf151_planar',...
                [],...
                {'radius',0.1,'label',...
                    {'MLC11_dH','MLC12_dH','MLC13_dH',...
                        'MLC14_dH','MLC15_dH','MLC21_dH',...
                        'MRT41_dV','MRT42_dV','MRT43_dV',...
                        'MRT44_dV','MZC01_dV','MZC02_dV'},...
                    'chantype','meg_combined_from_planar'},...
                12,[1 4 2.3333],...
                {{'MLC11',...
                        {'MLC11_dH','MLC12_dH','MLC21_dH',...
                            'MZC01_dV'}},...
                    {'MZC02',{ 'MZC02_dV' }}}},...
            {'ctf151_planar_combined',...
                'CTF151.lay',...
                {'count',5,'label','dataset','chantype',...
                    'meg_axial'},...
                151,[5 5 5],...
                {{'MLC11',...
                        {'MLC11','MLC12','MLF51','MRC11',...
                            'MZF03'}},...
                    {'MZP02',...
                        {'MLO11','MLP21','MRO11','MRP21',...
                            'MZP02'}}}},...
            {'ctf151_planar_combined',...
                'CTF151.lay',...
                {'count',5,'label','dataset','chantype',...
                    'meg_planar_combined'},...
                151,[5 5 5],...
                {{'MLC11',...
                        {'MLC11','MLC12','MLF51','MRC11',...
                            'MZF03'}},...
                    {'MZP02',...
                        {'MLO11','MLP21','MRO11','MRP21',...
                            'MZP02'}}}},...
            {'4d148',...
                '4D148.lay',...
                {'delaunay',true,'label',...
                    {'A148','A147','A146','A145','A144',...
                        'A143','A13','A12','A11','A10','A9',...
                        'A8'},...
                    'chantype','meg_axial'},...
                12,[4 9 6.8333],...
                {{'A8',{'A8','A9','A10','A11','A13','A143'}},...
                    {'A148',...
                        {'A10','A11','A12','A13','A143',...
                            'A147','A148'}}}},...
            {'4d148',...
                '4D148.lay',...
                {'delaunay',true,'label',...
                    {'A148','A147','A146','A145','A144',...
                        'A143','A13','A12','A11','A10','A9',...
                        'A8'},...
                    'chantype','meg_planar_combined'},...
                12,[4 9 6.8333],...
                {{'A8',{'A8','A9','A10','A11','A13','A143'}},...
                    {'A148',...
                        {'A10','A11','A12','A13','A143',...
                            'A147','A148'}}}},...
            {'4d148_planar',...
                [],...
                {'radius',0.1,'label','layout','chantype',...
                    'meg_planar'},...
                296,[4 20 13.1351],...
                {{'A1_dH',...
                        {'A1_dH','A1_dV','A2_dH','A2_dV',...
                            'A3_dH','A3_dV','A5_dH','A5_dV',...
                            'A6_dH','A6_dV','A7_dH','A7_dV',...
                            'A10_dH','A10_dV','A11_dH','A11_dV',...
                            'A12_dH','A12_dV'}},...
                    {'A148_dV',...
                        {'A129_dH','A129_dV','A130_dH',...
                            'A130_dV','A148_dH','A148_dV'}}}},...
            {'4d148_planar',...
                [],...
                {'radius',0.1,'label','layout','chantype',...
                    'meg_combined_from_planar'},...
                148,[4 20 13.1351],...
                {{'A1',...
                        {'A10_dH','A10_dV','A11_dH','A11_dV',...
                            'A12_dH','A12_dV','A1_dH','A1_dV',...
                            'A2_dH','A2_dV','A3_dH','A3_dV',...
                            'A5_dH','A5_dV','A6_dH','A6_dV',...
                            'A7_dH','A7_dV'}},...
                    {'A148',...
                        {'A129_dH','A129_dV','A130_dH',...
                            'A130_dV','A148_dH','A148_dV'}}}},...
            {'4d148_planar_combined',...
                '4D148.lay',...
                {'count',5,'label',...
                    {'A148','A147','A146','A145','A144',...
                        'A143','A13','A12','A11','A10','A9',...
                        'A8'},...
                    'chantype','meg_axial'},...
                12,[5 5 5],...
                {{'A8',{'A8','A9','A10','A11','A12'}},...
                    {'A148',{'A12','A145','A146','A147','A148'}}}},...
            {'4d148_planar_combined',...
                '4D148.lay',...
                {'count',5,'label',...
                    {'A148','A147','A146','A145','A144',...
                        'A143','A13','A12','A11','A10','A9',...
                        'A8'},...
                    'chantype','meg_planar_combined'},...
                12,[5 5 5],...
                {{'A8',{'A8','A9','A10','A11','A12'}},...
                    {'A148',{'A12','A145','A146','A147','A148'}}}},...
            {'4d248',...
                '4D248.lay',...
                {'delaunay',true,'label','layout','chantype',...
                    'meg_axial'},...
                248,[5 12 8.2903],...
                {{'A1',...
                        {'A1','A2','A9','A10','A11','A12',...
                            'A13','A14'}},...
                    {'A248',...
                        {'A151','A152','A194','A195','A227',...
                            'A228','A246','A247','A248'}}}},...
            {'4d248',...
                '4D248.lay',...
                {'delaunay',true,'label','layout','chantype',...
                    'meg_planar_combined'},...
                248,[5 12 8.2903],...
                {{'A1',...
                        {'A1','A2','A9','A10','A11','A12',...
                            'A13','A14'}},...
                    {'A248',...
                        {'A151','A152','A194','A195','A227',...
                            'A228','A246','A247','A248'}}}},...
            {'4d248_planar',...
                [],...
                {'radius',0.1,'label','dataset','chantype',...
                    'meg_planar'},...
                496,[8 32 22.1452],...
                {{'A1_dH',...
                        {'A1_dH','A1_dV','A2_dH','A2_dV',...
                            'A9_dH','A9_dV','A10_dH','A10_dV',...
                            'A11_dH','A11_dV','A12_dH','A12_dV',...
                            'A13_dH','A13_dV','A14_dH','A14_dV',...
                            'A15_dH','A15_dV','A25_dH','A25_dV',...
                            'A28_dH','A28_dV','A30_dH','A30_dV',...
                            'A31_dH','A31_dV'}},...
                    {'A248_dV',...
                        {'A194_dH','A194_dV','A227_dH',...
                            'A227_dV','A228_dH','A228_dV',...
                            'A247_dH','A247_dV','A248_dH',...
                            'A248_dV'}}}},...
            {'4d248_planar',...
                [],...
                {'radius',0.1,'label','dataset','chantype',...
                    'meg_combined_from_planar'},...
                248,[8 32 22.1452],...
                {{'A1',...
                        {'A10_dH','A10_dV','A11_dH','A11_dV',...
                            'A12_dH','A12_dV','A13_dH','A13_dV',...
                            'A14_dH','A14_dV','A15_dH','A15_dV',...
                            'A1_dH','A1_dV','A25_dH','A25_dV',...
                            'A28_dH','A28_dV','A2_dH','A2_dV',...
                            'A30_dH','A30_dV','A31_dH','A31_dV',...
                            'A9_dH','A9_dV'}},...
                    {'A248',...
                        {'A194_dH','A194_dV','A227_dH',...
                            'A227_dV','A228_dH','A228_dV',...
                            'A247_dH','A247_dV','A248_dH',...
                            'A248_dV'}}}},...
            {'4d248_planar_combined',...
                '4D248.lay',...
                {'count',5,'label','layout','chantype',...
                    'meg_axial'},...
                248,[5 5 5],...
                {{'A1',{'A1','A2','A10','A12','A14'}},...
                    {'A248',{'A194','A227','A228','A247','A248'}}}},...
            {'4d248_planar_combined',...
                '4D248.lay',...
                {'count',5,'label','layout','chantype',...
                    'meg_planar_combined'},...
                248,[5 5 5],...
                {{'A1',{'A1','A2','A10','A12','A14'}},...
                    {'A248',{'A194','A227','A228','A247','A248'}}}},...
            {'eeg1005',...
                'EEG1005.lay',...
                {'delaunay',true,'label','dataset','chantype',...
                    'eeg'},...
                335,[5 11 8.3851],...
                {{'Fp1',...
                        {'Fp1','AFp9h','AFp7h','AFp5h','Fp1h',...
                            'AFp9','AFp7','AFp5','AFp3'}},...
                    {'OI2',...
                        {'O2','I2','POO8h','POO10h','OI2h',...
                            'O2h','I2h','POO6','POO8','POO10',...
                            'OI2'}}}},...
            {'eeg1010',...
                'EEG1010.lay',...
                {'radius',0.1,'label',...
                    {'TP10','TP7','TP8','TP9','CP1','CP2',...
                        'PO8','PO9','POz','O1','O2','Oz'},...
                    'chantype','eeg'},...
                12,[1 2 1.5],{{'TP9',{'TP9','TP7'}},{'O2',{'O2'}}}},...
            {'eeg1020',...
                'EEG1020.lay',...
                {'count',5,'label','layout','chantype',...
                    'eeg'},...
                21,[5 6 5.0952],...
                {{'Fp1',{'Fp1','Fpz','F7','F3','Fz'}},...
                    {'O2',{'Pz','P4','O1','Oz','O2'}}}}
        };
