%% Demo: fMRI surface-based searchlights with LDA classifier
%
% The data used here is available from http://cosmomvpa.org/datadb.zip
%
% This example uses the following dataset:
% + 'digit'
%    A participant made finger pressed with the index and middle finger of
%    the right hand during 4 runs in an fMRI study. Each run was divided in
%    4 blocks with presses of each finger and analyzed with the GLM,
%    resulting in 2*4*4=32 t-values
%
% The example shows four possible searchlight analyses, covering typical
% use cases:
%   1) single or twin surfaces
%      + Caret and BrainVoyager use a single surface; a parameter 'offsets'
%        is used to define which voxels are considered to be in the "grey
%        matter" (but this may be not so precise)
%      + FreeSurfer uses twin surfaces (pial and white), and voxels in
%        between or on them are considered to be in the grey matter
%   2) lower resolution output map
%      + in the canonical surface-based searchlight, each node on the input
%        surface(s) is assigned a measure value (accuracy, in this example)
%      + it is also possible to have output in a lower resolution version
%        than the input surfaces; this reduces both the execution time
%        (a Good Thing) and spatial precision (a Bad Thing). Two approaches
%        are illustrated to use a lower resolution surface for output:
%        1) from MapIcosahedron, with a lower value for the number of
%          divisions of the triangles
%        2) using a surface subsampling approach, implemented by
%           surfing_subsample_surface
%
% In all cases a searchlight is run with a 100 voxel searchlight, using a
% disc for which the metric radius varies from node to node. For a fixed
% metric radius of the disc, use a positive value for 'radius' below.
% Distances are measured across the cortical surface using a geodesic
% distance metric.
%
% This example requires the surfing toolbox, github.com/nno/surfing
%
% This example may take quite some time to run. For faster execution, set
% ld=16 (instead of ld=64) below
%
% If you use this code for a publication, please cite:
% Oosterhof, N.N., Wiestler, T, Downing, P.E., & Diedrichsen, J. (2011)
% A comparison of volume-based and surface-based information mapping.
% Neuroimage. DOI:10.1016/j.neuroimage.2010.04.270
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

%% Check externals
cosmo_check_external('surfing');

%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();

digit_study_path=fullfile(config.tutorial_data_path,'digit');
readme_fn=fullfile(digit_study_path,'README');
cosmo_type(readme_fn);

output_path=config.output_data_path;

% reset citation list
cosmo_check_external('-tic');

% resolution parameter for input surfaces
% 64 is for high-quality results; use 16 for fast execution
ld=64;

% Twin surface case (FS)
pial_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.pial_al.asc', ld));
white_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.smoothwm_al.asc', ld));

% Single surface case (Caret/BV)
intermediate_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.intermediate_al.asc', ld));

% Used for visualization
inflated_fn=fullfile(digit_study_path,...
                         sprintf('ico%d_mh.inflated_alCoMmedial.asc', ld));

%%
% Set parameters

% Searchlight radius: select 100 features in each searchlight
% (to use a fixed radius of 8mm, use:
%    cosmo_surficial_neighborhood(...,'radius',8)
% in the code below)

feature_count=100;

% Single surface case: select voxels that are 3 mm or closer to the surface
% on the white-matter side, up to voxels that are 2 mm from the surface on
% the pial matter side
single_surf_offsets=[-2 3];

% Single surface case: number of iterations to downsample surface
lowres_output_onesurf_niter=10;

% Twin surface case: number of linear divisions from MapIcosahedron
lowres_output_twosurf_icold=16;
lowres_intermediate_fn=fullfile(digit_study_path,...
                                sprintf('ico%d_mh.intermediate_al.asc',...
                                        lowres_output_twosurf_icold));


% Use the cosmo_cross_validation_measure and set its parameters
% (classifier and partitions) in a measure_args struct.
measure = @cosmo_crossvalidation_measure;
measure_args = struct();

% Define which classifier to use, using a function handle.
% Alternatives are @cosmo_classify_{svm,nn,naive_bayes}
measure_args.classifier = @cosmo_classify_lda;



%% Load functional data
data_path=digit_study_path;
data_fn=fullfile(data_path,'glm_T_stats_perblock+orig');

targets=repmat(1:2,1,16)';    % class labels: 1 2 1 2 1 2 1 2 1 2 ... 1 2
chunks=floor(((1:32)-1)/8)+1; % run labels:   1 1 1 1 1 1 1 1 2 2 ... 4 4

ds = cosmo_fmri_dataset(data_fn,'targets',targets,'chunks',chunks);

% remove zero elements
zero_msk=all(ds.samples==0,1);
ds = cosmo_slice(ds, ~zero_msk, 2);

fprintf('Dataset has %d samples and %d features\n', size(ds.samples));

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds);

%% Set partition scheme. odd_even is fast; for publication-quality analysis
% nfold_partitioner is recommended.
% Alternatives are:
% - cosmo_nfold_partitioner    (take-one-chunk-out crossvalidation)
% - cosmo_nchoosek_partitioner (take-K-chunks-out  "             ").
measure_args.partitions = cosmo_oddeven_partitioner(ds);

% print measure and arguments
fprintf('Searchlight measure:\n');
cosmo_disp(measure);
fprintf('Searchlight measure arguments:\n');
cosmo_disp(measure_args);

%% Read inflated surface
[v_inf,f_inf]=surfing_read(inflated_fn);
fprintf('The inflated surface has %d vertices, %d faces\n',...
            size(v_inf,1), size(f_inf,1))

%% Run four types of searchlights
for one_surf=[true,false]
    if one_surf
        desc='1surf';
    else
        desc='2surfs';
    end

    for lowres_output=[false,true]
        if lowres_output
            desc=sprintf('%s_lowres', desc);
        end
        fprintf('\n\n *** Starting analysis with %s *** \n\n\n', desc)

        % define searchlight surface paramters for each type of analysis
        if one_surf && lowres_output

            % single surface (Caret/BV) with lower-res output
            surf_def={intermediate_fn,single_surf_offsets,...
                            lowres_output_onesurf_niter};

        elseif one_surf && ~lowres_output

            % single surface (Caret/BV) with original-res output
            surf_def={intermediate_fn,single_surf_offsets};

        elseif ~one_surf && lowres_output

            % single surface (FS) with lower-res output
            surf_def={white_fn,pial_fn,lowres_intermediate_fn};

        elseif ~one_surf && ~lowres_output

            % single surface (FS) with original-res output
            surf_def={white_fn,pial_fn};

        else
            assert(false); % should never get here
        end

        % Define the feature neighborhood for each node on the surface
        % - nbrhood has the neighborhood information
        % - vo and fo are vertices and faces of the output surface
        % - out2in is the mapping from output to input surface
        fprintf('Defining neighborhood with %s\n', desc);
        [nbrhood,vo,fo,out2in]=cosmo_surficial_neighborhood(ds,surf_def,...
                                                    'count',feature_count);

        % print neighborhood
        fprintf('Searchlight neighborhood definition:\n');
        cosmo_disp(nbrhood);


        fprintf('The output surface has %d vertices, %d nodes\n',...
                        size(vo,1), size(fo,1));



        % Run the searchlight
        lda_results = cosmo_searchlight(ds,nbrhood,measure,measure_args);


        % print searchlight output
        fprintf('Dataset output:\n');
        cosmo_disp(lda_results);

        % Apply the node mapping from the surifical neighborhood
        % to the high-res inflated surface.
        % (This example shows how such a mapping can be applied to new
        % surfaces)
        if lowres_output
            v_inf_out=v_inf(out2in,:);
            f_inf_out=fo;
        else
            v_inf_out=v_inf;
            f_inf_out=f_inf;
        end

        % visualize the surfaces, if the afni matlab toolbox is present
        if cosmo_check_external('afni',false)
            nvertices=size(v_inf_out,1);

            opt=struct();

            for show_edge=[false, true]
                opt.ShowEdge=show_edge;

                if show_edge
                    t='with edges';
                else
                    t='without edges';
                end

                header=strrep([desc ' ' t],'_',' ');


                DispIVSurf(vo,fo,1:nvertices,lda_results.samples',0,opt);
                title(sprintf('Original %s', header));

                DispIVSurf(v_inf_out,f_inf_out,1:nvertices,...
                                        lda_results.samples',0,opt);
                title(sprintf('Inflated %s', header));
            end
        else
            fprintf('skip surface display; no afni matlab toolbox\n');
        end

        if lowres_output && one_surf
            % in this example only this case a new surface was generated.
            % To aid visualization using external tools, store it to disc.

            % The surface is stored in ASCII, GIFTI and BV SRF
            % formats, if the required externals are present
            surf_output_fn=fullfile(output_path,['inflated_' desc]);

            % AFNI/SUMA ASC
            surfing_write([surf_output_fn '.asc'],v_inf_out,f_inf_out);

            % BV SRF
            if cosmo_check_external('neuroelf',false)
                surfing_write([surf_output_fn '.srf'],v_inf_out,f_inf_out);
            end

            % GIFTI
            if cosmo_check_external('gifti',false)
                surfing_write([surf_output_fn '.gii'],v_inf_out,f_inf_out);
            end
        end

        % store searchlight results
        data_output_fn=fullfile(output_path,['lda_' desc]);

        if cosmo_check_external('afni',false)
            cosmo_map2surface(lda_results, [data_output_fn '.niml.dset']);
        end

        if cosmo_check_external('neuroelf',false)
            cosmo_map2surface(lda_results, [data_output_fn '.smp']);
        end

        % store voxel counts (how often each voxel is in a neighborhood)
        % take a random sample (the first one) from the input dataset
        % and count how often each voxel was selected.
        % If everything works, then voxels in the grey matter have high
        % voxel counts but voxels outside it low or zero counts.
        % Thus, this can be used as a sanity check that can be visualized
        % easily.

        vox_count_ds=cosmo_slice(ds,1);
        vox_count_ds.samples(:)=0;

        ncenters=numel(nbrhood.neighbors);
        for k=1:ncenters
            idxs=nbrhood.neighbors{k}; % feature indices in neigborhood
            vox_count_ds.samples(idxs)=vox_count_ds.samples(idxs)+1;
        end

        vox_count_output_fn=fullfile(output_path,['vox_count_' desc]);

        % store voxel count results
        cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '.nii']);

        if cosmo_check_external('afni',false)
            cosmo_map2fmri(vox_count_ds, [vox_count_output_fn '+orig']);
        end
    end
end

% Show citation information
cosmo_check_external('-cite');
