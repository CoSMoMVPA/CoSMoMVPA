function sliced_pruned_ds=cosmo_dim_slice(ds, to_select, dim)
% slice and prune a dataset with dimension attributes [deprecated]
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
%  - This function is deprecated and will be removed in the future;
%    instead of:
%
%           % this is deprecated
%           result=cosmo_dim_slice(ds, ...)
%
%     use:
%
%           ds_sliced=cosmo_slice(ds, ...)
%           result=cosmo_dim_prune(ds_sliced);
%
% See also: cosmo_slice, cosmo_dim_prune
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_warning(['%s is deprecated and will be removed in the future;'...
                    '     instead of:\n\n'...
                    '      %% this is deprecated:\n'...
                    '      result=cosmo_dim_slice(ds, ...)\n\n'...
                    'use:\n\n'...
                    '      ds_sliced=cosmo_slice(ds, ...)\n\n'...
                    '      result=cosmo_dim_prune(ds_sliced);\n'],...
                    mfilename());

% very simple implementation: first slice, then prune
sliced_pruned_ds=cosmo_slice(ds, to_select, dim);
sliced_pruned_ds=cosmo_dim_prune(sliced_pruned_ds,'dim',dim);
