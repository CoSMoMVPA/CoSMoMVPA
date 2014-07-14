%% NIFTI basics
% In this example, load a brain and visualize it in matlab

% Set the path. 
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Set filename
fn=[data_path '/brain.nii'];

% Load with nifti
ni=load_nii(fn);

%% Show the contents of the nifti header
cosmo_disp(ni.hdr);

% print the dimensions
size(ni.img)

% plot a histogram of the intensities (use only values greater than zero)
% >@@>
hist(ni.img(ni.img>0),100)
% <@@<

%% Plot slices
% plot a sagital, coronal and axial slice
% at voxel positions (80,150,80) using squeeze and tranpose ("'") where
% necessary.
% (bonus points for proper orientations)
ii=80;
jj=150;
kk=80;
figure
% >@@>
subplot(2,2,1)
imagesc(squeeze(ni.img(ii,end:-1:1,end:-1:1))')
subplot(2,2,2)
imagesc(squeeze(ni.img(:,jj,end:-1:1))')
subplot(2,2,3)
imagesc(squeeze(ni.img(:,end:-1:1,kk)))
% <@@<

%% Plot slice in all three dimensions
% This uses the cosmo_plot_slices helper function
slice_step=15;

for dim=1:3
    figure
    % >@@>
    % make a new figure
    cosmo_plot_slices(ni.img,dim,slice_step);
    % <@@<
end


