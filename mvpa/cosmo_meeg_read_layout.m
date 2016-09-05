function layout=cosmo_meeg_read_layout(fn)
% Read FieldTrip layout
%
% layout=cosmo_meeg_read_layout(fn)
%
% Inputs:
%   fn                  Filename of layout file, or a string containing the
%                       layout. In the latter case fn must contain at least
%                       one newline ('\n') character.
%                       A layout file is a text file with one line per
%                       sensor, with each line containing the following
%                       data separated by white-space:
%                       1) sensor number (integer)
%                       2) horizontal position (float)
%                       3) vertical position (float)
%                       4) width (float)
%                       5) height (float)
%                       6) label (string)
%
% Output:
%   layout              struct with fields containing data for N sensors:
%     .pos              Nx2 matrix with x and y position
%     .width            Nx1 vector
%     .height           Nx1 vector
%     .label            Nx1 cell string with channel labels
%
% Notes:
%   - whitespace is trimmed from the labels
%   - the sensor number is not used; the order of the sensors in layout is
%     the same as in the layout file
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_layout_input(fn)

    if string_contains_newline(fn)
        lay_string=fn;
        fn_descr=@()sprintf('input:\n''%s''',lay_string);
    else
        lay_string=read_lay_string_from_file(fn);
        fn_descr=@()sprintf('file %s',fn);
    end

    layout=parse_layout(lay_string, fn_descr);

function lay_string=read_lay_string_from_file(fn)
    if ~exist(fn,'file')
        error('layout file %s does ont exist', fn);
    end

    % read FT layout (.lay) file
    fid=fopen(fn);
    file_closer=onCleanup(@()fclose(fid));
    lay_string=fread(fid,inf,'char=>char')';


function check_layout_input(fn)
    if ~ischar(fn)
        error('first argument must be string, found %s', class(fn));
    end

function tf=string_contains_newline(fn)
    tf=any(fn==sprintf('\n'));


function layout=parse_layout(lay_string, fn_descr)
    % pattern to match is integer, then 4 numeric values followed by a
    % string that can contain whitespaces and plus characters, followed by
    % newline
    integer='(\d+)';
    float='([\d\.-]+)';
    space='\s+';
    channel_label='([\w \t\r\f\v\+\-]+)';
    single_newline='\n';

    pat=[integer, space, ...
         float, space, ...
         float, space, ...
         float, space, ...
         float, space, ...
         channel_label, single_newline];

    matches=regexp(sprintf('%s\n',lay_string),pat,'tokens');
    if isempty(matches)
        error('No valid layout definition found in %s', fn_descr());
    end

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

    % trim whitespace around channel names
    label=layout_matrix(:,6);
    label=regexprep(label,'^\s*','');
    label=regexprep(label,'\s*$','');
    layout.label  = label;