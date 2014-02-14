function nbrhood=cosmo_interval_neighborhood(ds, label, radius)
% compute neighborhoods stretching intervals
%
% nbrhood=cosmo_interval_neighborhood(ds, label, radius)
%
% Inputs:
%   ds            dataset struct
%   label         dimension label in ds.a.dim.labels
%   radius        neighborhood size
%
% Returns:
%   nbrhood       struct with fields:
%     .a          } dataset and feature attributes of neighborhood
%     .fa         }
%     .neighbors  If ds has N values in the dimension label, then 
%                 neighbors is a Nx1 cell with indices of features 
%                 where the indices differ at most radius from each other.
%
% Examples
%   % ds is an MEEG dataset with a time dimension
%   % 
%   % neighborhoods with time bins 7 timepoints wide
%   >> nbrhood=cosmo_interval_neighborhood(ds, 'time', 3);
%   %
%   % neighborhoods containing just each timepoint itself
%   >> nbrhood=cosmo_interval_neighborhood(ds, 'time', 0);
%
% NNO Feb 2014

    cosmo_check_dataset(ds);

    % find dimension index
    dim_idx=find(cosmo_match(ds.a.dim.labels,label));
    if numel(dim_idx)~=1
        error('Could not locate %s in dimensions %s', ...
                label, cosmo_strjoin(ds.a.dim.labels,' ,'))
    end

    % get dimension values
    dim_values=ds.a.dim.values{dim_idx};
    nvalues=numel(dim_values);

    % get feature attribute values
    fa_values=ds.fa.(label);

    % compute neighborhood
    neighbors=cell(nvalues,1);
    for k=1:nvalues
        
        % deal with indices near borders
        mn=max(1,ceil(k-radius));
        mx=min(nvalues,floor(k+radius));

        ival=mn:mx;
        msk=cosmo_match(fa_values,ival);

        neighbors{k}=find(msk);
    end

    % store results
    nbrhood=struct();
    nbrhood.a=ds.a;
    nbrhood.a.dim=struct();
    nbrhood.a.dim.labels={label};
    nbrhood.a.dim.values={dim_values};
    nbrhood.fa.(label)=1:nvalues;
    nbrhood.neighbors=neighbors;