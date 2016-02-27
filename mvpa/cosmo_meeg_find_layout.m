function layout=cosmo_meeg_find_layout(ds, varargin)
% finds an MEEG channel layout associated with a dataset
%
% layout=cosmo_meeg_find_layout(ds, varargin)
%
% Inputs:
%   'chantype', ct     string indicating the channel type (if the dataset
%                      has channel labels that allow for different types of
%                      channels. Depending on the dataset, possible options
%                      are:
%                      - 'meg_planar'               pairs of planar MEG
%                      - 'meg_axial'                axial MEG
%                      - 'meg_planar_combined'      combined planar MEG
%                      - 'meg_combined_from_planar' pairs of planar MEG [*]
%                      - 'eeg'                      eeg channels
%
% Output:
%   layout             MEG channel layout with fields
%                      .pos     Nx2 x and y coordinates (for N channels)
%                      .width   Nx1 channel widths
%                      .height  Nx1 channel heights
%                      .label   Nx1 cell with channel labels
%                      .name    string with name of layout
%                      [*] when chantype is set to
%                      'meg_combined_from_planar', layout also contains a
%                      field .parent which is a layout in itself for the
%                      'meg_planar_combined channels'. In that case,
%                      layout.parent has the .pos, .width, .height, .label
%                      and .name fields (all of size Mx1 or Mx2 for M
%                      planar-combined channels, and in addition a cell
%                      .child_label (of size Mx1) which contains the
%                      channel labels in layout.name.
%
% Examples:
%     % generate neuromag306 dataset
%     ds=cosmo_synthetic_dataset('type','meeg','sens','neuromag306_all');
%     % get layout for the planar channels
%     pl_layout=cosmo_meeg_find_layout(ds,'chantype','meg_planar');
%     cosmo_disp(pl_layout.label)
%     > { 'MEG0113'
%     >   'MEG0112'
%     >   'MEG0122'
%     >      :
%     >   'MEG2643'
%     >   'COMNT'
%     >   'SCALE'   }@206x1
%     cosmo_disp([pl_layout.pos pl_layout.width pl_layout.height])
%     > [ -0.408     0.253    0.0323    0.0332
%     >   -0.408     0.284    0.0323    0.0332
%     >   -0.328     0.285    0.0323    0.0332
%     >      :         :         :         :
%     >    0.373    -0.082    0.0323    0.0332
%     >    -0.45     -0.45    0.0323    0.0332
%     >     0.45     -0.45    0.0323    0.0332 ]@206x4
%     pl_layout.name
%     > neuromag306planar.lay
%     %
%     % get layout for axial (magnetometer) channels
%     mag_layout=cosmo_meeg_find_layout(ds,'chantype','meg_axial');
%     cosmo_disp(mag_layout.label);
%     > { 'MEG0111'
%     >   'MEG0121'
%     >   'MEG0131'
%     >      :
%     >   'MEG2641'
%     >   'COMNT'
%     >   'SCALE'   }@104x1
%     %
%     % get layout for planar channels, but add a 'parent' layout which has the
%     % combined_planar channels
%     combined_from_planar_layout=cosmo_meeg_find_layout(ds,'chantype',...
%                                             'meg_combined_from_planar');
%     cosmo_disp(combined_from_planar_layout.label);
%     > { 'MEG0113'
%     >   'MEG0112'
%     >   'MEG0122'
%     >      :
%     >   'MEG2643'
%     >   'COMNT'
%     >   'SCALE'   }@206x1
%     cosmo_disp(combined_from_planar_layout.parent.label);
%     > { 'MEG0112+0113'
%     >   'MEG0122+0123'
%     >   'MEG0132+0133'
%     >         :
%     >   'MEG2642+2643'
%     >   'COMNT'
%     >   'SCALE'        }@104x1
%     cosmo_disp(combined_from_planar_layout.parent.child_label);
%     > { { 'MEG0112'
%     >     'MEG0113' }
%     >   { 'MEG0122'
%     >     'MEG0123' }
%     >   { 'MEG0132'
%     >     'MEG0133' }
%     >               :
%     >   { 'MEG2642'
%     >     'MEG2643' }
%     >   {  }
%     >   {  }          }@104x1
%
% See also: ft_prepare_neighbors, cosmo_meeg_chan_neighbors,
%           cosmo_meeg_chan_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    defaults.chantype=[];
    defaults.min_coverage=.2;
    opt=cosmo_structjoin(defaults, varargin);

    % get the sensor labels and channel types applicable to this dataset
    chantype2senstype=get_dataset_senstypes(ds);

    % get the single channel type based on the input and available channels
    ds_chantype=get_base_chantype(chantype2senstype,opt);

    % get the sensor type corresponding with the channel type
    senstype=chantype2senstype.(ds_chantype);

    % use the mapping from senstype to layout to get the layout
    senstype2layout=cosmo_meeg_senstype2layout_mapping();
    layout=senstype2layout.(senstype);

    % ensure that enough labels are covered in the dataset
    ds_label=get_dataset_channel_label(ds);
    coverage=label_coverage(ds_label(:),layout.label(:));

    % no coverage, throw an error
    if coverage<opt.min_coverage
        error(['channel coverage %.1f%% < 100%% for %s. This means '...
                'that the channel layout was not recognized based '...
                'on the channel labels. Your options are:\n '...
                '1) if this is a custom layout, define a neighbor '...
                'struct with fields .label and neighblabel (similar '....
                'to CoSMoMVPA''s ft_meeg_chan_neighbors and '...
                'FieldTrip''s ft_prepare_neighbors), and provide this '...
                'as the only input to cosmo_meeg_chan_neighborhood\n'...
                '2) if this is a common MEG or EEG layout, please get '...
                'in touch with the CoSMoMVPA developers to see if '
                'support for this layout can be added'], ...
                    100*coverage, ds_chantype);
    end

    % in case of planar channels with senstype set to
    % meg_combined_from_planar, add a parent layout that maps to the
    % original layout
    is_planar_layout=isempty(cosmo_strsplit(ds_chantype,'_planar',-1));
    if is_planar_layout && strcmp(opt.chantype,'meg_combined_from_planar')
        parent_senstype=chantype2senstype.meg_combined_from_planar;
        parent_layout=senstype2layout.(parent_senstype);

        sens_label=get_senstype_label(senstype);
        parent_sens_label=get_senstype_label(parent_senstype);

        nlabels=numel(parent_layout.label);
        parent_layout.child_label=cell(nlabels,1);
        all_child_labels=cell(nlabels,1);
        for k=1:nlabels
            i=find(cosmo_match(parent_sens_label,parent_layout.label(k)));
            if numel(i)~=1
                parent_layout.child_label{k}=cell(0,1);
            end

            child_label=sort(sens_label(i,:));
            all_child_labels{k}=child_label(:);
            parent_layout.child_label{k}=child_label(:);
        end

        % sanity check
        assert(cosmo_overlap({sens_label(:)},...
                    {cat(1,all_child_labels{:})})==1);

        layout.parent=parent_layout;
    end

function label=get_senstype_label(senstype)
    sc=cosmo_meeg_senstype_collection();
    label=sc.(senstype).label;

function senstype_mapping=get_dataset_senstypes(ds)
    % helper function to get supported senstypes
    [unused,senstype_mapping]=cosmo_meeg_chantype(ds);
    keys=fieldnames(senstype_mapping);

    if cosmo_match({'meg_planar'},keys)
        planar_senstype=senstype_mapping.meg_planar;
        planar_combined_senstype=[planar_senstype '_combined'];

        sc=cosmo_meeg_senstype_collection();
        if isfield(sc,planar_combined_senstype)
            senstype_mapping.meg_combined_from_planar=...
                                        planar_combined_senstype;
        end
    end


function c=label_coverage(x,y)
    % helper function to compute coverage of labels by a layout
    c=mean(cosmo_match(x(:),y(:)));


function chan_labels=get_dataset_channel_label(ds)
    % helper function to get labels from dataset
    if iscellstr(ds)
        chan_labels=ds;
    else
        [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'chan',true);
        chan_labels=ds.a.(dim_name).values{index};
    end


function chantype=get_base_chantype(chantype2senstype, opt)
    % helper function to get the base (i.e. the one
    % returned in layout) channel type.
    % (this is not the parent type)
    has_chantype=ischar(opt.chantype) && ~isempty(opt.chantype);
    chantypes=fieldnames(chantype2senstype);
    has_key=@(key)cosmo_match({key},chantypes);

    error_msg='';
    if has_chantype
        if strcmp(opt.chantype,'meg_combined_from_planar')
            if has_key('meg_planar')
                chantype='meg_planar';
            else
                error_msg=sprintf(['Cannot use senstype ''%s'' because '...
                                    'meg_planar not available'],...
                                        opt.chantype);
            end
        elseif ~has_key(opt.chantype);
            error_msg=sprintf('chantype ''%s'' is not supported',...
                                    opt.chantype);
        else
            chantype=opt.chantype;
        end
    else
        if numel(chantypes)>1
            error_msg=['''chantype'' argument is not provided, but '...
                        'multiple types are available'];
        else
            chantype=chantypes{1};
        end
    end

    if ~isempty(error_msg)
        error('%s. Set the ''chantype'' argument to one of: ''%s''.',...
                error_msg,cosmo_strjoin(chantypes, ''', '''));
    end
