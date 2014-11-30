function senstype2layout=cosmo_meeg_senstype2layout_mapping(varargin)
% return mapping from MEEG sensor types to sensor layouts
%
% senstype2layout=cosmo_meeg_senstype2layout_mapping()
%
% Output:
%   senstype2layout       struct where the fieldnames (keys) are senstypes
%                         (acquisition systems with a possible suffix
%                         indicating a type of channel)
%                         If a senstype does not have an associated layout
%                         then the corresponding value is set to [].
%                         Otherwise each value has fields:
%                         .pos     Nx2 x and y coordinates (for N channels)
%                         .width   Nx1 channel widths
%                         .height  Nx1 channel heights
%                         .label   Nx1 cell with channel labels
%                         .name    string with name of layout
%
% Examples:
%     senstype2layout=cosmo_meeg_senstype2layout_mapping();
%     % get layout for neuromag306 MEG planar (gradiometers)
%     layout=senstype2layout.neuromag306alt_planar;
%     cosmo_disp(layout,'strlen',inf);
%     > .pos
%     >   [ -73.4      33.4
%     >     -73.4      38.4
%     >     -59.6      38.5
%     >       :         :
%     >      65.5     -35.3
%     >      61.2     -25.4
%     >      61.2     -20.4 ]@204x2
%     > .width
%     >   [ 5
%     >     5
%     >     5
%     >     :
%     >     5
%     >     5
%     >     5 ]@204x1
%     > .height
%     >   [ 4.8
%     >     4.8
%     >     4.8
%     >      :
%     >     4.8
%     >     4.8
%     >     4.8 ]@204x1
%     > .label
%     >   { 'MEG0113'
%     >     'MEG0112'
%     >     'MEG0122'
%     >        :
%     >     'MEG2632'
%     >     'MEG2642'
%     >     'MEG2643' }@204x1
%     > .name
%     >   'neuromag306planar.lay'
%
%     senstype2layout=cosmo_meeg_senstype2layout_mapping();
%     % get layout for neuromag306 MEG combined planar (combined gradiometers)
%     layout=senstype2layout.neuromag306alt_planar_combined;
%     cosmo_disp(layout,'strlen',inf);
%     > .pos
%     >   [ -67.4      35.9
%     >     -53.6        41
%     >       -62      21.2
%     >       :         :
%     >      79.8     -14.8
%     >      71.5     -37.8
%     >      67.2     -22.9 ]@102x2
%     > .width
%     >   [ 10
%     >     10
%     >     10
%     >      :
%     >     10
%     >     10
%     >     10 ]@102x1
%     > .height
%     >   [ 10
%     >     10
%     >     10
%     >      :
%     >     10
%     >     10
%     >     10 ]@102x1
%     > .label
%     >   { 'MEG0112+0113'
%     >     'MEG0122+0123'
%     >     'MEG0132+0133'
%     >           :
%     >     'MEG2622+2623'
%     >     'MEG2632+2633'
%     >     'MEG2642+2643' }@102x1
%     > .name
%     >   'neuromag306cmb.lay'
%     >
%
%     senstype2layout=cosmo_meeg_senstype2layout_mapping();
%     % get layout for EEG elec1020
%     layout=senstype2layout.eeg1020;
%     cosmo_disp(layout,'strlen',inf);
%     > .pos
%     >   [    -0.38     0.891
%     >     0.000121         1
%     >         0.38     0.891
%     >         :          :
%     >        -0.38    -0.891
%     >     0.000121        -1
%     >         0.38    -0.891 ]@21x2
%     > .width
%     >   [ 0.35
%     >     0.35
%     >     0.35
%     >       :
%     >     0.35
%     >     0.35
%     >     0.35 ]@21x1
%     > .height
%     >   [ 0.25
%     >     0.25
%     >     0.25
%     >       :
%     >     0.25
%     >     0.25
%     >     0.25 ]@21x1
%     > .label
%     >   { 'Fp1'
%     >     'Fpz'
%     >     'Fp2'
%     >      :
%     >     'O1'
%     >     'Oz'
%     >     'O2'  }@21x1
%     > .name
%     >   'elec1020.lay'
%
% Notes:
%   - this function requires FieldTrip, as it uses its collection of
%     layouts
%   - the output from this function is similar to FieldTrip's
%     ft_prepare_layout, but positions are not scaled as in FieldTrip
%   - this function caches previously read layouts, for optimization
%     reasons. run "clear functions" to reset the cache.
%   - this function uses cosmo_meeg_layout_collection and
%     cosmo_meeg_senstype_collection to match sensor types with layouts
%
% See also: cosmo_meeg_layout_collection, cosmo_meeg_senstype_collection
%
% NNO Nov 2014

    % 'secret' options with thresholds to find best matching layout
    defaults=struct();
    defaults.thr_layout=.7;
    defaults.thr_senstype=.8;
    opt=cosmo_structjoin(defaults,varargin);

    senstype2layout=get_mapping(opt);

function senstype2layout=get_mapping(opt)
    % helper function to actually compute the mapping
    persistent cached_opt;
    persistent cached_senstype2layout;

    if ~isequal(opt,cached_opt) || isempty(cached_senstype2layout)
        sc=cosmo_meeg_senstype_collection();
        names=fieldnames(sc);
        n=numel(names);

        senstype2layout=struct();

        for k=1:n
            name=names{k};
            lay=find_layout(name,opt);
            senstype2layout.(name)=lay;
        end

        cached_opt=opt;
        cached_senstype2layout=senstype2layout;
    end

    senstype2layout=cached_senstype2layout;


function pairs=senstypes_alt_names()
    % return pairs of sensor types with and without the 'alt' name, e.g.
    % neuromag306alt_planar and neuromag306_planar
    sc=cosmo_meeg_senstype_collection();
    names=fieldnames(sc);

    names_without_alt=strrep(names,'alt','');
    msk_with_alt=~cosmo_match(names, names_without_alt);
    idxs_with_alt=find(msk_with_alt);
    ncandidates=numel(idxs_with_alt);

    pairs=cell(ncandidates,2);
    pos=0;
    for k=1:ncandidates
        idx_with_alt=idxs_with_alt(k);
        name_without_alt=names_without_alt{idx_with_alt};
        idx_all=find(cosmo_match(names_without_alt,name_without_alt));
        idx_without_alt=setdiff(idx_all,idx_with_alt);
        switch numel(idx_without_alt)
            case 0
                continue
            case 1
                pos=pos+1;
                name_with_alt=names{idx_with_alt};
                pairs(pos,:)={name_without_alt,name_with_alt};
            otherwise
                assert(false);
        end
    end

    pairs=pairs(1:pos,:);

function alt_name=find_alt_name(name)
    alt_name=[];

    pairs=senstypes_alt_names();
    for col=1:2
        msk=cosmo_match(pairs(:,col),name);
        if any(msk)
            assert(sum(msk)==1)
            alt_name=pairs{msk,3-col};
            return
        end
    end



function lay=find_layout(name,opt)
    % find layout based on sensname
    % if no layout is found, lay is returned as []
    lay=find_layout_helper(name,opt);

    if ~isempty(lay)
        return
    end

    % not found, try to use the alternative name
    alt_name=find_alt_name(name);
    if ~isempty(alt_name)
        lay=find_layout_helper(alt_name,opt);
    end

function lay=find_layout_helper(name,opt)
    % helper function: first tries to get the layout directly, if that does
    % not work, try to infer planar channels from the combined channels
    sc=cosmo_meeg_senstype_collection();
    label=sc.(name).label;
    lay=find_layout_from_label(label,opt);

    if ~isempty(lay)
        return
    end

    lay=infer_planar_layout_from_combined(name,opt);

function planar_lay=infer_planar_layout_from_combined(planar_name,opt)
    % helper function in case no planar layout is found (e.g. ctf151)
    planar_lay=[];

    combined_name=[planar_name '_combined'];

    sc=cosmo_meeg_senstype_collection();
    if all(cosmo_isfield(sc,{planar_name,combined_name}))
        planar_label=sc.(planar_name).label;
        combined_label=sc.(combined_name).label;
        combined_lay=find_layout_from_label(combined_label,opt);
        if isempty(combined_lay)
            return;
        end

        % get rid of COMNT and SCALE labels
        keep=cosmo_match(combined_lay.label,combined_label);
        combined_lay=slice_layout(combined_lay,keep);

        if ~isequal(combined_lay.label,combined_label)
            return
        end

        % ensure mapping between number of labels
        nlabels=size(combined_lay.pos,1);
        combined2planar_idxs=reshape(repmat(1:nlabels,2,1),[],1);

        planar_lay=slice_layout(combined_lay,combined2planar_idxs);

        planar_lay.label=reshape(planar_label',[],1);
        planar_lay.name=[];
    end

function lay=slice_layout(lay, to_select)
    name=lay.name;
    lay=rmfield(lay,'name');
    lay=cosmo_slice(lay,to_select,1,'struct');
    lay.name=name;


function lay=find_layout_from_label(label,opt)
    % use labels from the layout to identify it
    lay_coll=cosmo_meeg_layout_collection();
    lay_label=cellfun(@(x)x.label,lay_coll,'UniformOutput',false);
    [in_lay, in_label]=cosmo_overlap(lay_label,{label});
    [coverage,i]=max(mean([in_lay, in_label],2));

    % try to be smart and use decent thresholds
    if in_lay(i)<opt.thr_layout || coverage<opt.thr_senstype
        lay=[];
    else
        lay=lay_coll{i};
    end
