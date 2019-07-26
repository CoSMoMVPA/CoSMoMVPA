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
% A searchlight is run with a 100 voxel searchlight, using a
% disc for which the metric radius varies from node to node.
%
% This example requires the surfing toolbox, github.com/nno/surfing
%
% This example may take quite some time to run. For faster execution but
% lower spatial precision, set ld=16 below; for slower execution use ld=64.
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
cosmo_check_external('afni');

%% Set data paths
% The function cosmo_config() returns a struct containing paths to tutorial
% data. (Alternatively the paths can be set manually without using
% cosmo_config.)
config=cosmo_config();

digit_study_path=fullfile(config.tutorial_data_path,'digit');
readme_fn=fullfile(digit_study_path,'README');
cosmo_type(readme_fn);

output_path=config.output_data_path;

%%

% resolution parameter for input surfaces
% 64 is for high-quality results; use 16 for fast execution
surface_ld=16;

% Define twin surface filenames (FreeSurfer)
pial_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.pial_al.asc', surface_ld));
white_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.smoothwm_al.asc', surface_ld));


% read the surface in pial_fn using surfing_read, and assign the vertices
% and faces to variables pial_v and pial_f, respectively
% >@@>
[pial_v, pial_f] = surfing_read(pial_fn);
% <@@<

fprintf('The pial surface has %d vertices, %d faces\n',...
            size(pial_v,1), size(pial_f,1))

% do the same for the white_fn, assign the faces and vertices to
% white_v and white_f
% >@@>
[white_v, white_f] = surfing_read(white_fn);
% <@@<

fprintf('The white surface has %d vertices, %d faces\n',...
            size(pial_v,1), size(pial_f,1))

% verify that the face information in pial_f and white_f are the same
assert(isequal(white_f, pial_f));

% show the content of the surfaces
fprintf('pial_v\n');
cosmo_disp(pial_v)

fprintf('pial_f\n');
cosmo_disp(pial_f)

fprintf('white_v\n');
cosmo_disp(white_v)

fprintf('white_f\n');
cosmo_disp(white_f)


%% Part 1: compute thickness of the cortex

% compute the element-wise difference in coordinates between pial_v
% and white_v, and assign to a variable delta
% >@@>
delta = pial_v - white_v;
% <@@<

% square the differences element-wise, and assign to delta_squared.
% hint: use ".^2"
% >@@>
delta_squared = delta .^ 2;
% <@@<

% compute the thickness squared, by summing the elements in
% delta_squared along the second dimension. Assign to thickness_squared
% >@@>
thickness_squared = sum(delta_squared,2);
% <@@<

% finally compute the thickness by taking the square root, assign
% the result to thickness
% >@@>
thickness = sqrt(thickness_squared);
% <@@<
%%
% plot a histogram of the thickness values
% >@@>
hist(thickness,100);
xlabel('thickness (mm)');
% <@@<

%% For visualization purposes, read inflated surface
inflated_fn=fullfile(digit_study_path,...
                            sprintf('ico%d_mh.inflated_alCoMmedial.asc', surface_ld));
[infl_v,infl_f]=surfing_read(inflated_fn);
fprintf('The inflated surface has %d vertices, %d faces\n',...
            size(infl_v,1), size(infl_f,1))

%% visualize surface in Matlab using AFNI Matlab toolbox
nvertices=size(infl_v,1);

min_thickness=1;
max_thickness=4;
show_edge=false;

opt=struct();
opt.ShowEdge=show_edge;
opt.Zlim=[min_thickness,max_thickness]; % this does not seem to work
opt.Dim='3D';

if show_edge
    t='with edges';
else
    t='without edges';
end

desc='thickness';
header=strrep([desc ' ' t],'_',' ');

range_adj_thickness=max(min_thickness,...
                        min(thickness,max_thickness));

DispIVSurf(infl_v,infl_f,1:nvertices,...
                        range_adj_thickness,0,opt);
title(sprintf('Inflated %s', header));


%%
ds_thickness=struct();
ds_thickness.fa.node_indices=1:nvertices;
ds_thickness.samples=thickness(:)';
ds_thickness.a.fdim.labels={'node_indices'};
ds_thickness.a.fdim.values={(1:nvertices)'};

% July 2019: strangely enough these gifti files cannot be read by AFNI SUMA.
% https://github.com/CoSMoMVPA/CoSMoMVPA/issues/186
if cosmo_check_external('gifti',false)
    output_fn=fullfile(config.output_data_path,'thickness.gii');
    cosmo_map2surface(ds_thickness,output_fn,'encoding','ASCII');
end

% AFNI output
output_fn=fullfile(config.output_data_path,'thickness.niml.dset');
cosmo_map2surface(ds_thickness,output_fn);

%% Part 2: run surface-based searchlight

% Load volumetric functional data
data_path=digit_study_path;
data_fn=fullfile(data_path,'glm_T_stats_perblock+orig');

% set targets
targets=repmat(1:2,1,16)';    % class labels: 1 2 1 2 1 2 1 2 1 2 ... 1 2
chunks=floor(((1:32)-1)/8)+1; % run labels:   1 1 1 1 1 1 1 1 2 2 ... 4 4

% load functional data
ds = cosmo_fmri_dataset(data_fn,'targets',targets,'chunks',chunks);

% remove zero elements
zero_msk=all(ds.samples==0,1);
ds = cosmo_slice(ds, ~zero_msk, 2);

fprintf('Dataset has %d samples and %d features\n', size(ds.samples));

% print dataset
fprintf('Dataset input:\n');
cosmo_disp(ds);

%% set measure arguments
% Assign to measure a function handle to cosmo_cross_validation_measure
% >@@>
measure = @cosmo_crossvalidation_measure;
% <@@<

% use as arguments for the measure:
% - classifier: cosmo_classify_naive_bayes
% - partitions: odd-even partitions
% assign these to a struct measure_args
% >@@>
measure_args = struct();
measure_args.classifier = @cosmo_classify_naive_bayes;
measure_args.partitions = cosmo_oddeven_partitioner(ds);
% <@@<


%%
% Set neighborhood parameters
% Make a cell with the outer surface vertices (pial_v),
% the inner surface vertices (white_v), and the face
% indices (pial_f or white_f). Assign to a variable surface_def
% >@@>
surface_def={pial_v,white_v,pial_f};
% <@@<

% Define a surface-based neighborhood (using cosmo_surficial_neighborhood)
% with approximately 100 voxels per searchlight. Assign the result
% to nbrhood.

% >@@>
nbrhood=cosmo_surficial_neighborhood(ds,surface_def,'count',100);
% <@@<

% visualize the neighborhood using cosmo_disp.
% What is the feature attribute of the neighborhood?

%%
% run surface-based searchlight using the variables define above
% Assign the result to ds_sl
% >@@>
ds_sl=cosmo_searchlight(ds,nbrhood,measure,measure_args);
% <@@<

%% plot surface in Matlab using AFNI Matlab toolbox

nvertices=size(infl_v,1);
show_edge=false;

opt=struct();
opt.ShowEdge=show_edge;
opt.Dim='3D';

if show_edge
    t='with edges';
else
    t='without edges';
end

desc='classification accuracy';
header=strrep([desc ' ' t],'_',' ');

DispIVSurf(infl_v,infl_f,1:nvertices,...
                        ds_sl.samples',0,opt);
title(sprintf('Inflated %s', header));

% July 2019: strangely enough these gifti files cannot be read by AFNI SUMA.
% https://github.com/CoSMoMVPA/CoSMoMVPA/issues/186
if cosmo_check_external('gifti',false)
    output_fn=fullfile(config.output_data_path,'digit_accuracy.gii');
    cosmo_map2surface(ds_sl,output_fn,'encoding','ASCII');
end

% AFNI output
output_fn=fullfile(config.output_data_path,'digit_accuracy.niml.dset');
cosmo_map2surface(ds_sl,output_fn);

% Show citation information
cosmo_check_external('-cite');