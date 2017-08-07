function ds=cosmo_dim_rename(ds, old_name, new_name, raise)
% rename dimension attribute name
%
% ds=cosmo_dim_rename(ds, old_name, new_name, raise)
%
% Inputs:
%   ds             dataset struct
%   old_name       original label of dimension
%   new_name       new label of dimension
%   raise          if true (default), raise an error if old_name is not
%                  found
% Output:
%   ds_renamed     dataset struct with renamed dimension
%
%
% Example:
%     ds=cosmo_synthetic_dataset('type','timefreq');
%     cosmo_disp(ds.a.fdim)
%     > .labels
%     >   { 'chan'
%     >     'freq'
%     >     'time' }
%     > .values
%     >   { { 'MEG0111'  'MEG0112'  'MEG0113' }
%     >     [ 2         4 ]
%     >     [ -0.2 ]                            }
%     cosmo_disp(ds.fa)
%     > .chan
%     >   [ 1         2         3         1         2         3 ]
%     > .freq
%     >   [ 1         1         1         2         2         2 ]
%     > .time
%     >   [ 1         1         1         1         1         1 ]
%     %
%     % rename 'freq' to 'frequency' (there is no good reason to do this
%     % except to illustrate its use here)
%     ds=cosmo_dim_rename(ds,'freq','frequency');
%     cosmo_disp(ds.a.fdim)
%     > .labels
%     >   { 'chan'
%     >     'frequency'
%     >     'time'      }
%     > .values
%     >   { { 'MEG0111'  'MEG0112'  'MEG0113' }
%     >     [ 2         4 ]
%     >     [ -0.2 ]                            }
%     cosmo_disp(ds.fa)
%     > .chan
%     >   [ 1         2         3         1         2         3 ]
%     > .time
%     >   [ 1         1         1         1         1         1 ]
%     > .frequency
%     >   [ 1         1         1         2         2         2 ]
%
% Notes:
%  - a use case is renaming dimensions to time and freq
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    cosmo_check_dataset(ds);

    if nargin<4
        raise=true;
    end

    [dim, index, attr_name, dim_name]=cosmo_dim_find(ds, old_name, raise);

    if ~isempty(dim)
        values=ds.(attr_name).(old_name);
        ds.(attr_name)=rmfield(ds.(attr_name),old_name);
        ds.(attr_name).(new_name)=values;

        ds.a.(dim_name).labels{index}=new_name;
    end



