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
%     % ds is an MEEG dataset with a time dimension
%     ds=cosmo_synthetic_dataset('type','meeg','size','big');
%     %
%     % neighborhoods with time bins 7 (=3*2+1) timepoints wide
%     % (every neighborhood contains all channels)
%     nbrhood=cosmo_interval_neighborhood(ds,'time',3);
%     cosmo_disp(nbrhood);
%     > .a
%     >   .fdim
%     >     { [ -0.2     -0.15      -0.1  ...  0      0.05       0.1 ]@1x7 }
%     >   .meeg
%     >     .samples_type
%     >       'timelock'
%     >     .samples_field
%     >       'trial'
%     >     .samples_label
%     >       'rpt'
%     >   .hdr_ft
%     > .fa
%     >   .time
%     >     [ 1 2 3  ...  5 6 7 ]@1x7
%     > .neighbors
%     >   { [ 1 2 3  ...  1.22e+03  1.22e+03  1.22e+03 ]@1x1224
%     >     [ 1 2 3  ...  1.53e+03  1.53e+03  1.53e+03 ]@1x1530
%     >     [ 1 2 3  ...  1.83e+03  1.84e+03  1.84e+03 ]@1x1836
%     >                                      :
%     >     [ 307 308 309  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x1836
%     >     [ 613 614 615  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x1530
%     >     [ 919 920 921  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x1224 }@7x1
%     %
%     % neighborhoods containing just each timepoint itself
%     nbrhood=cosmo_interval_neighborhood(ds,'time',0);
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1         2         3    ...  304       305       306 ]@1x306
%     >   [ 307       308       309  ...  610       611       612 ]@1x306
%     >   [ 613       614       615  ...  916       917       918 ]@1x306
%     >                                      :
%     >   [ 1.22e+03  1.23e+03  1.23e+03  ...  1.53e+03  1.53e+03  1.53e+03 ]@1x306
%     >   [ 1.53e+03  1.53e+03  1.53e+03  ...  1.83e+03  1.84e+03  1.84e+03 ]@1x306
%     >   [ 1.84e+03  1.84e+03  1.84e+03  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x306 }@7x1
%
%     % Illustrate the 'freq' dimension in MEEG time-frequency dataset
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     %
%     % Neighborhoods with 5 (=2*2+1) elements wide
%     nbrhood=cosmo_interval_neighborhood(ds,'freq',2);
%     cosmo_disp(nbrhood)
%     > .a
%     >   .fdim
%     >     { [ 2         4         6  ...  10        12        14 ]@1x7 }
%     >   .meeg
%     >     .samples_type
%     >       'timefreq'
%     >     .samples_field
%     >       'powspctrm'
%     >     .samples_label
%     >       'rpt'
%     >   .hdr_ft
%     > .fa
%     >   .freq
%     >     [ 1         2         3  ...  5         6         7 ]@1x7
%     > .neighbors
%     >   { [ 1         2         3  ...  9.48e+03  9.48e+03  9.49e+03 ]@1x4590
%     >     [ 1         2         3  ...  9.79e+03  9.79e+03  9.79e+03 ]@1x6120
%     >     [ 1         2         3  ...  1.01e+04  1.01e+04  1.01e+04 ]@1x7650
%     >                                         :
%     >     [ 613       614       615  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x7650
%     >     [ 919       920       921  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x6120
%     >     [ 1.22e+03  1.23e+03  1.23e+03  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x4590 }@7x1
%
% Notes:
%   - to combine neighborhoods from different dimensions, use
%     cosmo_neighborhood
%
% See also: cosmo_neighborhood
%
% NNO Feb 2014

    cosmo_check_dataset(ds);

    % find dimension index
    [dim,index,attr_name,dim_name]=cosmo_dim_find(ds,label);


    % get dimension values
    dim_values=ds.a.(dim_name).values{index};
    nvalues=numel(dim_values);

    % get feature attribute values
    fa_values=ds.(attr_name).(label);

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

    a_dim=struct();
    a_dim={label};
    a_dim={dim_values};
    nbrhood.a.(dim_name)=a_dim;

    nbrhood.(attr_name)=struct();
    nbrhood.(attr_name).(label)=1:nvalues;
    nbrhood.neighbors=neighbors;
