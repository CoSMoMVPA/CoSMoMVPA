function cosmo_plot_slices(data, dim, slice_step, slice_start, slice_stop)
% Plots a set of slices from a dataset, nifti image, or 3D data array
%
% cosmo_plot_slices(data[, dim][, slice_step][, slice_start][, slice_stop])
%
% Inputs:
%  data         a dataset (from cosmo_fmri_dataset), nifti image (from
%               load_nii), or a 3D array with data. data should contain
%               data from a single volume (sample) only.
%  dim          dimension according to which slices are plotted
%               (default: 3).
%  slice_step   step between slices (default: 1). If negative then
%               -slice_step indicates the number of slices
%  slice_start  the index of the first slice to plot (default: 1).
%  slice_stop   the index of the last slice to plot (default: the number of
%               slices in the dim-th dimension).
%
% Examples:
%    % plot an fMRI dataset struct with default options
%    cosmo_plot_slices(ds)
%
%    % plot an fMRI dataset struct along the second spatial dimension
%    cosmo_plot_slices(ds, 2)
%
%    % plot a random gaussian 3D array along the first dimension
%    cosmo_plot_slices(randn([40,50,20]),1)
%
%    % plot an fMRI dataset struct along the default spatial dimension
%    % every 5-th slice
%    cosmo_plot_slices(ds, [], 5)
%
%    % plot an fMRI dataset struct along the third spatial dimension
%    % with about 12 slices
%    cosmo_plot_slices(ds, 3, -12)
%
%    % plot an fMRI dataset struct along the third spatial dimension
%    % with about 12 slices, starting at slice 10 and stopping at slice 25
%    cosmo_plot_slices(ds, 3, -12, 10, 25)
%
% Notes:
%  - Using this function only really makes sense for fMRI-like data.
%  - This function does not provide a consistent orientation for slices,
%    as this depends on the voxel-to-world transformation matrix, which is
%    completely ignored in this function. Thus left-right and top-down
%    swaps can occur. Different datasets may provide different views, for
%    example dim=1 may give a saggital view if the dataset comes from one
%    program and an axial view if it comes from another program.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2 || isempty(dim), dim=3; end
    if nargin<3 || isempty(slice_step), slice_step=-20; end
    if nargin<4 || isempty(slice_start), slice_start=1; end
    if nargin<5 || isempty(slice_stop), slice_stop=[]; end % set later

    if cosmo_check_dataset(data,false)
        data4D=cosmo_unflatten(data);
        sz=size(data4D);
        if sz(1)>1
            error(['expected single volume data, but found %d '...
                    'volumes. To select a single volume, use '...
                    'cosmo_slice. For example, to show the %d-th '...
                    'volume from a dataset struct ds, use:\n\n   '...
                    'cosmo_plot_slices(cosmo_slice(ds,%d))\n'],...
                    sz(1),sz(1),sz(1));
        end
        data=reshape(data4D, sz(2:4));
    end

    if numel(size(data))~=3
        error('expected 3D image - did you select a single volume?');
    end

    % get min and max values across the entire volume
    data_lin=data(:);
    mn=min(data_lin);
    mx=max(data_lin);

    % shift it so that we can walk over the first dimension
    data_sh=shiftdim(data, dim-1);

    if isempty(slice_stop)
        slice_stop=size(data_sh,1);
    end

    if slice_step<0
        nslices=-slice_step;
        slice_step=ceil((slice_stop-slice_start+1)/nslices);
    end

    % determine which slices to show
    slice_idxs=slice_start:slice_step:slice_stop;
    nslices=numel(slice_idxs);

    plot_ratio=.8; % ratio between number of rows and colums
    nrows=ceil(sqrt(nslices)*plot_ratio);
    ncols=ceil(nslices/nrows);

    % use header depending on dim
    header_labels={'i','j','k'};

    % order of slices and whether the slice should be transposed
    xorder=[-1 -1 1];
    yorder=[-1 1 -1];
    do_transpose=[true false true];


    for k=1:nslices
        slice_idx=slice_idxs(k);
        slice=squeeze(data_sh(slice_idx,:,:));

        if xorder(dim)<0
            slice=slice(end:-1:1,:);
        end
        if yorder(dim)<0
            slice=slice(:,end:-1:1);
        end
        if do_transpose(dim)
            slice=slice';
        end

        subplot(nrows, ncols, k);
        imagesc(slice, [mn, mx]);
        title(sprintf('%s = %d', header_labels{dim}, slice_idx));
    end
