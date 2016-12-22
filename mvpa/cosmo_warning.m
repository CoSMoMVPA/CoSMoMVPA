function varargout=cosmo_warning(message, varargin)
% show a warning message; by default just once for each message
%
% cosmo_warning(message, ...)
% cosmo_warning(state)
% state=cosmo_warning()
%
% Inputs:
%   message      warning message to be shown, or one of:
%                'on'   : show all warning messages
%                'off'  : show no warning messages
%                'once' : show each warning message once [default]
%                'reset':
%   ...          if a warning message is provided according with
%                placeholders as used in sprintf, then the subsequent
%                arguments should contain their values
%   state        if a struct, then this queries or sets the state of
%                cosmo_warning.
%
% Notes:
%   - this function works more or less like matlab's warning function,
%     except that by default each warning is just shown once.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    if isempty(get_from_state('when'))
        set_default_state();
    end

    if nargin==0
        varargout={get_state()};
        return
    end

    if isstruct(message)
        set_state(message);
        return
    end

    lmessage=lower(message);

    switch lmessage
        case {'on','off','once'}
            update_state('when',lmessage);
            return;

        case 'reset'
            set_default_state();
            return;

        otherwise
            show_warning(message,varargin{:});
    end

function show_warning(message,varargin)
    [identifier,full_message]=get_identifier_and_message(...
                                    message,varargin{:});

    shown_warnings=get_from_state('shown_warnings');
    has_warning=cosmo_match({full_message},shown_warnings);
    if ~has_warning
        shown_warnings{end+1}=full_message;
        update_state('shown_warnings',shown_warnings);
    end

    when=get_from_state('when');
    switch when
        case 'once'
            do_show_warning=~has_warning;

            me=mfilename();
            postfix=sprintf(['\n\nThis warning is shown only once, '...
                           'but the underlying issue may occur '...
                           'multiple times. To show each warning:\n'...
                           ' - every time:   %s(''on'')\n'...
                           ' - once:         %s(''once'')\n'...
                           ' - never:        %s(''off'')\n'],me,me,me);
            full_message=[full_message postfix];

        case 'off'
            do_show_warning=false;
        case 'on'
            do_show_warning=true;
        otherwise
            assert(false);
    end

    if do_show_warning
        state=warning(); % store state
        state_resetter=onCleanup(@()warning(state));

        warning('on','all');
        % avoid extra entry on the stack
        has_identifier=~isempty(identifier);

        if has_identifier
            warning(identifier,'%s',full_message);
        else
            warning('%s',full_message);
        end
    end

function [identifier,full_message]=get_identifier_and_message(...
                                            message,varargin)
    args=varargin;
    has_identifier=numel(args)>0 && has_warning_identifier(message);
    if has_identifier
        identifier=message;
        message=args{1};
        args=args(2:end);
    else
        identifier='';
    end

    if numel(args)>0
        full_message=sprintf(message, args{:});
    else
        full_message=message;
    end



function tf=has_warning_identifier(s)
    alpha_num='([a-z_A-Z0-9]+)';
    pat=sprintf('^%s(:%s)?:%s$',alpha_num,alpha_num,alpha_num);
    tf=~isempty(regexp(s,pat,'once'));


function s=get_state()
    s=get_or_set_state();

function set_state(s)
    get_or_set_state(s);

function set_default_state()
    s=struct();
    s.when='once';
    s.shown_warnings=cell(0);
    set_state(s);

function value=get_from_state(key)
    s=get_state();
    value=s.(key);

function update_state(key, value)
    s=get_state();
    s.(key)=value;
    set_state(s);

function varargout=get_or_set_state(s)
    persistent state;
    switch nargin
        case 0
            % get state
            if isempty(state)
                set_default_state();
            end

            varargout={state};

        case 1
            % set state
            state=s;
            varargout={};

        otherwise
            assert(false);
    end











