function db=cosmo_meeg_layout_collection()
% return supported MEEG channel layouts
%
% db=cosmo_meeg_layout_collection()
%
% Output:
%     db            Nx1 cell for N layouts. Each elements has the following
%                   fields:
%                   .pos      Mx2 x and y coordinates for M channels
%                   .width    Mx1 width of channel
%                   .height   Mx1 height of channel
%                   .label    Mx1 cell string with channel labels
%                   .name     string with filename of layout
%
% Example:
%     % get all layouts
%     layouts=cosmo_meeg_layout_collection();
%     %
%     % find index of neuromag306cmb layout
%     names=cellfun(@(x)x.name,layouts,'UniformOutput',false);
%     i=find(cosmo_match(names,'neuromag306cmb.lay'));
%     %
%     % show neuromag306 combined planar layout (with 102 channels)
%     pl_layout=layouts{i};
%     cosmo_disp(pl_layout.label)
%     > { 'MEG0112+0113'
%     >   'MEG0122+0123'
%     >   'MEG0132+0133'
%     >         :
%     >   'MEG2642+2643'
%     >   'COMNT'
%     >   'SCALE'        }@104x1
%     cosmo_disp([pl_layout.pos pl_layout.width pl_layout.height])
%     > [ -0.408     0.273    0.0645    0.0712
%     >   -0.328     0.306    0.0645    0.0712
%     >   -0.377     0.179    0.0645    0.0712
%     >      :         :         :         :
%     >    0.373    -0.104    0.0645    0.0712
%     >    -0.45     -0.45    0.0645    0.0712
%     >     0.45     -0.45    0.0645    0.0712 ]@104x4
%     pl_layout.name
%     > neuromag306cmb.lay
%
% Note:
%   - this function requires FieldTrip, as it uses its collection of
%     layouts
%   - the output from this function is similar to FieldTrip's
%     ft_prepare_layout.
%   - this function caches previously read layouts, for optimization
%     reasons. run "clear functions" to reset the cache.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % cache the layouts, so that after the first call layouts don't have to
    % be read from disc
    persistent cached_layout_db;

    if isempty(cached_layout_db)
        cached_layout_db=read_all_layouts();
    end
    db=cached_layout_db;

function layouts=read_all_layouts()
    cosmo_check_external('fieldtrip');

    % see where fieldtrip is
    ft_dir=fileparts(which('ft_defaults'));
    lay_dir=fullfile(ft_dir,'template','layout');

    % get layout filenames
    lay_fns=dir(fullfile(lay_dir,'*.lay'));
    nlay=numel(lay_fns);

    if nlay==0, error('No layout founds in %s', lay_dir); end

    layout_names={lay_fns.name}';

    % allocate space for output
    layouts=cell(nlay,1);

    % read each layout
    for k=1:nlay
        lay_name=layout_names{k};
        lay_fn=fullfile(lay_dir,lay_name);
        lay=read_single_layout(lay_fn);
        lay.name=lay_name;
        layouts{k}=lay;
    end

    layouts=apply_fixers(layouts);

function layouts=apply_fixers(layouts)
    fixers={@fix_elec1020_old_fieldtrip,...
            @fix_make_ft_compatible};
    for j=1:numel(fixers)
        fixer=fixers{j};
        layouts=fixer(layouts);
    end


function db=fix_elec1020_old_fieldtrip(db)
    % old fieldtrip had channel locations differently;
    % fix that there so that the unit tests pass
    i=find_layout(db,'elec1020.lay');
    lay=db{i};
    if isequal(lay.pos(1,:),[-0.308949 0.951110]) && ...
                isequal(unique(lay.width),.75)
        suffix=cellfun(@(x)x(end),lay.label)';

        suffix1=suffix=='1';
        suffix2=suffix=='2';

        assert(isequal(lay.label(suffix1),{'Fp1','O1'}'));
        assert(isequal(lay.label(suffix2),{'Fp2','O2'}'));

        lay.pos(suffix1,:)=[-.38 .89111; -.38 -.89111];
        lay.pos(suffix2,:)=[.38  .891004; .38 -.891004];
        lay.width(:)=.35;
        lay.height(:)=.25;
        db{i}=lay;
    end

function i=find_layout(db,name)
    names=cellfun(@(x)x.name,db,'UniformOutput',false);
    i=find(cosmo_match(names,name));
    assert(numel(i)==1);


function layout=read_single_layout(fn)
    % read FT layout (.lay) file

    fid=fopen(fn);
    lay_string=fread(fid,inf,'char=>char')';
    fclose(fid);

    % pattern to match is 5 numeric values followed by a string that can
    % contain whitespaces and plus characters, followed by newline
    pat=['(\d+)\s+([\d\.-]+)\s+([\d\.-]+)\s+([\d\.-]+)\s+([\d\.-]+)\s+'...
            '([\w\s\+]+\w)\s*' sprintf('\n')];

    matches=regexp(sprintf('%s\n',lay_string),pat,'tokens');

    % convert to (nchannel x 6) matrix
    layout_matrix=cat(1,matches{:});

    % convert values in first five columns to numeric
    num_values_cell=layout_matrix(:,1:5)';
    str_values=sprintf('%s %s %s %s %s; ', num_values_cell{:});
    num_values=str2num(str_values);

    % store layout information (omit channel number in first column)
    layout.pos    = num_values(:,2:3);
    layout.width  = num_values(:,4);
    layout.height = num_values(:,5);
    layout.label  = layout_matrix(:,6);


function layouts=fix_make_ft_compatible(layouts)
    for j=1:numel(layouts)
        layouts{j}=make_single_ft_compatible(layouts{j});
    end

function layout=make_single_ft_compatible(layout)
    processors={@layout_ft_add_outline,...
                @layout_ft_scale,...
                @layout_ft_add_misc_labels};

    for k=1:numel(processors)
        processor=processors{k};
        layout=processor(layout);
    end

function layout=layout_ft_add_outline(layout)
    % add outline and mask to the layout
    alpha=(0:.01:1)'*(2*pi);
    head=[cos(alpha) sin(alpha)]*.5;
    nose=[0.09  0.496;
          0     0.575;
          -0.09 0.496];
    right_ear=[ 0.4970    0.0555
                0.5100    0.0775
                0.5180    0.0783
                0.5299    0.0746
                0.5419    0.0555
                0.5400   -0.0055
                0.5470   -0.0932
                0.5320   -0.1313
                0.5100   -0.1384
                0.4890   -0.1199 ];
    left_ear=bsxfun(@times,[-1 1],right_ear);

    layout.outline={head, nose, right_ear, left_ear};
    layout.mask={head};

function layout=layout_ft_scale(layout)
    % do not consider the COMNT and SCALE channels
    chan_msk=~cosmo_match(layout.label,{'COMNT','SCALE'});

    chan_pos=layout.pos(chan_msk,:);
    extent=(max(chan_pos)-min(chan_pos));

    % put everything in circle around origin with radius .45
    layout.pos=(bsxfun(@rdivide,bsxfun(@minus,...
                    layout.pos,min(chan_pos)),extent))*.9-.45;
    layout.width=layout.width/extent(1);
    layout.height=layout.height/extent(2);

function stacked_layout=stack_channels(layouts)
    % helper function to stack the channels
    % if any element is empty it is just ignored
    keys={'pos','width','height','label'};
    nlayout=numel(layouts);
    nkeys=numel(keys);

    stacked_layout=layouts{1};
    for k=1:nkeys
        key=keys{k};
        values_cell=cell(nlayout,1);
        keep=false(nlayout,1);
        for j=1:nlayout
            layout=layouts{j};
            if ~isempty(layout)
                values_cell{j}=layout.(key);
                keep(j)=true;
            end
        end
        stacked_layout.(key)=cat(1,values_cell{keep});
    end

function layout=layout_ft_add_misc_labels(layout)
    comnt_layout=get_single_label(layout,'COMNT',[-.45 -.45]);
    scale_layout=get_single_label(layout,'SCALE',[ .45 -.45]);
    layout=stack_channels({layout,comnt_layout,scale_layout});

function y=get_single_label(x,label,pos)
    % return a layout
    if cosmo_match({label},x.label);
        y=[];
    else
        y.width=mean(x.width,1);
        y.height=mean(x.height,1);
        y.label={label};
        y.pos=pos;
    end


