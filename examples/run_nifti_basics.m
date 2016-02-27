%% NIFTI basics
% In this example, load a brain and visualize it in matlab
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

% Set the path.
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Set filename
fn=fullfile(data_path, 'brain.nii');

% Load with nifti
ni=load_nii(fn);

%% Show the contents of the nifti header
cosmo_disp(ni.hdr);

% print the dimensions
size(ni.img)

% plot a histogram of the intensities (use only values greater than zero)
% change the number of bins
% >@@>
figure
set(gcf, 'name', 'Intensity Histogram')
hist(ni.img(ni.img(:) > 0), 100)
xlabel('intensity')
ylabel('count')
box off
% <@@<
%% Plot slices
% plot a sagital, coronal and axial slice
% at voxel positions (80,150,80) using squeeze and tranpose ("'") where
% necessary.
% (bonus points for axis labels and proper orientations, i.e. in the
% sagittal view the front of the brain is on the left and the back
% is on the right)
ii=80;
jj=150;
kk=80;
figure
% >@@>
set(gcf, 'name', 'Canonical Views')
subplot(2,2,1)
%imagesc(fliplr(rot90(squeeze(ni.img(ii, :, :)))))
imagesc(squeeze(ni.img(ii,end:-1:1,end:-1:1))')
axis image
title('SAG')
xlabel('y [AP]')
ylabel('z [SI]')

subplot(2,2,2)
%imagesc(fliplr(rot90(squeeze(ni.img(:, jj, :)))))
imagesc(squeeze(ni.img(:,jj,end:-1:1))')
axis image
title('COR')
xlabel('x [LR]')
ylabel('z [SI]')

subplot(2,2,3)
%imagesc(fliplr(rot90(ni.img(:, :, kk))))
imagesc(squeeze(ni.img(:,end:-1:1,kk))')
axis image
title('TRA')
xlabel('x [LR]')
ylabel('y [AP]')
% <@@<
%% Plot slice in all three dimensions
% This uses the cosmo_plot_slices helper function
slice_step=15;
strView = {'SAG', 'COR', 'TRA'};

for dim=1:3
    figure
    % >@@>
    cosmo_plot_slices(ni.img, dim, slice_step)
    axh = findobj(gcf, 'Type', 'axes');
    set(axh, 'visible', 'off')
    set(gcf, 'name', sprintf('Slices %s', strView{dim}));
    % <@@<
end
