function nbrhood=cosmo_interval_neighborhood(ds, label, radius)
% compute neighborhoods stretching intervals
%
% nbrhood=cosmo_interval_neighborhood(ds, label, radius)
%
% Inputs:
%   ds            dataset struct
%   label         dimension label in ds.a.fdim.labels
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
%     % Illustrate the 'time' dimension in MEEG time-frequency dataset,
%     ds=cosmo_synthetic_dataset('type','timefreq','size','big');
%     %
%     % neighborhoods with bins 5 (=2*1+1) frequency bands wide
%     % (every neighborhood contains all channels and time points)
%     nbrhood=cosmo_interval_neighborhood(ds,'freq',2);
%     cosmo_disp(nbrhood.a.fdim)
%     > .labels
%     >   { 'freq' }
%     > .values
%     >   { [  2
%     >        4
%     >        6
%     >        :
%     >       10
%     >       12
%     >       14 ]@7x1 }
%     cosmo_disp(nbrhood.fa.freq)
%     > [ 1         2         3  ...  5         6         7 ]@1x7
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1         2         3  ...  9.48e+03  9.48e+03  9.49e+03 ]@1x4590
%     >   [ 1         2         3  ...  9.79e+03  9.79e+03  9.79e+03 ]@1x6120
%     >   [ 1         2         3  ...  1.01e+04  1.01e+04  1.01e+04 ]@1x7650
%     >                                       :
%     >   [ 613       614       615  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x7650
%     >   [ 919       920       921  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x6120
%     >   [ 1.22e+03  1.23e+03  1.23e+03  ...  1.07e+04  1.07e+04  1.07e+04 ]@1x4590 }@7x1
%
%     % ds is an MEEG dataset with a time dimension
%     ds=cosmo_synthetic_dataset('type','timelock','size','big');
%     %
%     % Neighborhoods just the frequency bin itself
%     % (every neighborhood contains all channels)
%     nbrhood=cosmo_interval_neighborhood(ds,'time',2);
%     cosmo_disp(nbrhood.a.fdim)
%     > .labels
%     >   { 'time' }
%     > .values
%     >   { [  -0.2
%     >       -0.15
%     >        -0.1
%     >         :
%     >           0
%     >        0.05
%     >         0.1 ]@7x1 }
%     cosmo_disp(nbrhood.fa.time)
%     > [ 1         2         3  ...  5         6         7 ]@1x7
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1         2         3  ...  916       917       918 ]@1x918
%     >   [ 1         2         3  ...  1.22e+03  1.22e+03  1.22e+03 ]@1x1224
%     >   [ 1         2         3  ...  1.53e+03  1.53e+03  1.53e+03 ]@1x1530
%     >                                      :
%     >   [ 613       614       615  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x1530
%     >   [ 919       920       921  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x1224
%     >   [ 1.22e+03  1.23e+03  1.23e+03  ...  2.14e+03  2.14e+03  2.14e+03 ]@1x918 }@7x1
%
%
% Notes:
%   - to combine neighborhoods from different dimensions (such as
%     time, freq, chan, use cosmo_neighborhood
%   - the output can be used for a searchlight using cosmo_searchlight
%
% See also: cosmo_neighborhood, cosmo_searchlight
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

    % get unique feature attributes
    [fa_idxs,fa_unq]=cosmo_index_unique(fa_values');
    nunq=numel(fa_unq);

    % cosmo_index_unique should return a sorted array of values
    assert(issorted(fa_unq));

    % allocate space for output
    neighbors=cell(nvalues,1);

    % go over all dimension values and find the neighborhood.
    % first_pos and last_pos point to the position in fa_idxs.
    % this works because fa_unq is sorted, so a window can be taken that
    % moves from left to right
    first_pos=1;
    last_pos=1;

    for center_id=1:nvalues
        % find left edge
        while first_pos<nunq && fa_unq(first_pos)<center_id-radius
            first_pos=first_pos+1;
        end

        last_pos=first_pos;
        % find right edge
        while last_pos<nunq && fa_unq(last_pos)<center_id+radius
            last_pos=last_pos+1;
        end
        if fa_unq(last_pos)>center_id+radius
            % avoid getting over the edge
            last_pos=last_pos-1;
        end

        % merge all indices in the neighborhood
        neighbors{center_id}=sort(cat(1,fa_idxs{first_pos:last_pos}))';
    end


    % store results
    nbrhood=struct();
    nbrhood.a=ds.a;

    a_dim=struct();
    a_dim.labels={label};
    a_dim.values={dim_values(:)};
    nbrhood.a.(dim_name)=a_dim;

    nbrhood.(attr_name)=struct();
    nbrhood.(attr_name).(label)=1:nvalues;
    nbrhood.neighbors=neighbors;

    cosmo_check_neighborhood(nbrhood);
