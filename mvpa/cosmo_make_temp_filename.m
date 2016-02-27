function filename=cosmo_make_temp_filename(prefix,suffix)
% give temporary filename that does not exist when this function is called
%
% filename=cosmo_make_temp_filename(prefix,suffix)
%
% Inputs:
%   prefix              optional, string with prefix for temporary file
%                       (default: '')
%   suffix              string [or cellstring] with suffix [suffixes] for
%                       temporary file [files]
%                       (default: '')
%
% Output:
%   filename            filename that does not exist when this function was
%                       called (in the current directory), starting with
%                       prefix, ending with suffix, and with a random infix
%                       string.
%                       If suffix is a cellstring, then filename is a
%                       cellstring with as many elements as suffix,
%                       each with the same prefix and random infix.
%
% Examples:
%   % generate random filename
%   fn=cosmo_make_temp_filename();
%
%   % generate random filename starting with 'foo'
%   fn=cosmo_make_temp_filename('foo');
%
%   % generate random filename starting with 'foo' and ending with '.bar'
%   fn=cosmo_make_temp_filename('foo','.bar');
%
%   % generate two random filename, both starting with 'foo', and ending
%   % with '.bar' and '.baz', respectively. The output fns is a cell with
%   % two strings
%   fns=cosmo_make_temp_filename('foo',{'.bar','.bar'});
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2, suffix=''; end
    if nargin<1, prefix=''; end

    check_input(prefix,suffix);

    suffix_is_cell=iscell(suffix);

    if suffix_is_cell
        suffix_cell=suffix;
    else
        suffix_cell={suffix};
    end

    nsuffix=numel(suffix_cell);

    filename_cell=cell(nsuffix,1);
    while true
        infix=generate_random_infix();

        does_exist=false;

        for k=1:nsuffix
            fn=[prefix infix suffix_cell{k}];

            if exist(fn,'file')
                does_exist=true;
                break;
            end

            filename_cell{k}=fn;
        end

        if ~does_exist
            break;
        end
    end

    if suffix_is_cell
        filename=filename_cell;
    else
        filename=filename_cell{1};
    end


function infix=generate_random_infix(infix_length)
    if nargin<1
        infix_length=20;
    end

    char_val_min=double('a');
    char_val_max=double('z');
    char_val_range=char_val_max-char_val_min;

    rand_chars=char(rand(1,infix_length)*char_val_range+char_val_min);
    infix=['tmp_' rand_chars];


function check_input(prefix,suffix)
    if ~ischar(prefix)
        error('prefix must be a string');
    end

    if ~ischar(suffix) && ~iscellstr(suffix)
        error('suffix must be string or cell with strings');
    end
