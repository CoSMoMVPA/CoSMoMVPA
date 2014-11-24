function sliced_pruned_ds=cosmo_dim_slice(ds, to_select, dim)
% slice and prune a dataset with dimension attributes
%
% sliced_pruned_ds=cosmo_dim_slice(ds, to_select, dim)
%
% Inputs:
%   ds                    dataset struct to be sliced, with PxQ field
%                         .samples and optionally fields .fa, .sa and .a.
%   elements_to_select    either a binary mask or a list of indices of
%                         the samples (if dim==1) or features (if dim==2)
%                         to select. If a binary mask then the number of
%                         elements should match the size of ds in the
%                         dim-th dimension.
%   dim                   Slicing dimension: along samples (dim==1) or
%                         features (dim==2). (default: 1).
%
% Example:
%     % generate MEEG time-frequency dataset
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     size(ds.samples)
%     > [ 6 10710]
%     % show dimension values
%     cosmo_disp(ds.a.fdim)
%     > .labels
%     >   { 'chan'  'freq'  'time' }
%     > .values
%     >   { { 'MEG0111'          [  2        [  -0.2
%     >       'MEG0112'             4          -0.15
%     >       'MEG0113'             6           -0.1
%     >          :                  :          -0.05
%     >       'MEG2641'            10              0 ]
%     >       'MEG2642'            12
%     >       'MEG2643' }@306x1    14 ]@7x1            }
%     % show feature dimension indices for time
%     cosmo_disp(ds.fa.time)
%     > [ 1 1 1  ...  5 5 5 ]@1x10710
%     %
%     % select time points between -.18 and -.03
%     msk=cosmo_dim_match(ds,'time',@(x) x>=-.18 & x<-.03);
%     ds_sel=cosmo_dim_slice(ds,msk,2);
%     size(ds_sel.samples)
%     > [ 6 6426 ]
%     % show values in time dimension
%     cosmo_disp(ds_sel.a.fdim)
%     > .labels
%     >   { 'chan'  'freq'  'time' }
%     > .values
%     >   { { 'MEG0111'          [  2        [ -0.15
%     >       'MEG0112'             4           -0.1
%     >       'MEG0113'             6          -0.05 ]
%     >          :                  :
%     >       'MEG2641'            10
%     >       'MEG2642'            12
%     >       'MEG2643' }@306x1    14 ]@7x1            }
%     %
%     % show feature dimension indices for time
%     cosmo_disp(ds_sel.fa.time)
%     > [ 1 1 1  ...  3 3 3 ]@1x6426
%
% Notes:
%  - a use case is removing certain time points or frequency bands from an
%    MEEG dataset
%  - use for fMRI or surface data does not make much sense
%  - this function first slices the data using cosmo_slice, then
%    prunes the dimenion using cosmo_dim_prune
%
% See also: cosmo_slice, cosmo_dim_prune
%
% NNO Nov 2014

% very simple implementation: first slice, then prune
sliced_pruned_ds=cosmo_slice(ds, to_select, dim);
sliced_pruned_ds=cosmo_dim_prune(sliced_pruned_ds,[],2);
