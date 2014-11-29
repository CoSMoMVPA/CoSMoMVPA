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
%     cosmo_disp(layouts{i})
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
%
% Note:
%   - this function requires FieldTrip, as it uses its collection of
%     layouts
%   - the output from this function is similar to FieldTrip's
%     ft_prepare_layout, but positions are not scaled as in FieldTrip
%   - this function caches previously read layouts, for optimization
%     reasons. run "clear functions" to reset the cahce.
%
% NNO Nov 2014

    % cache the layouts, so that after the first call layouts don't have to
    % be read from disc
    persistent cached_layout_db;

    if isempty(cached_layout_db)
        cached_layout_db=read_all_layouts();
    end
    db=cached_layout_db;

function db=read_all_layouts()
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

    db=layouts;


function layout=read_single_layout(fn)
    % read FT layout (.lay) file

    fid=fopen(fn);
    lay_string=fread(fid,inf,'char=>char')';
    fclose(fid);

    % pattern to match is 5 numeric values followed by a string that can
    % contain whitespaces and plus characters, followed by newline
    pat=['(\d+)\s+([\d\.-]+)\s+([\d\.-]+)\s+([\d\.-]+)\s+([\d\.-]+)\s+'...
            '([\w\s\+]+\w)\s*' sprintf('\n')];

    matches=regexp(lay_string,pat,'tokens');

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
