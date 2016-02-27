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

    persistent when_show_warning;
    persistent shown_warnings;

    if isempty(when_show_warning)
        when_show_warning='once';
        shown_warnings=[];
    end

    if nargin==0
        switch nargout
            case 0
                warning();
            case 1
                state=struct();
                state.warning=warning();
                state.when_show_warning=when_show_warning;
                state.shown_warnings=shown_warnings;
                varargout{1}=state;
            otherwise
                assert(false);
        end
        return
    end

    if isstruct(message)
        % input was warning state
        state=message;
        warning(state.warning);
        when_show_warning=state.when_show_warning;
        shown_warnings=state.shown_warnings;
        return;
    end

    if isnumeric(when_show_warning)
        when_show_warning='once';
    end

    lmessage=lower(message);
    show_warning=true;

    if cosmo_match({lmessage},{'on','off','once','reset'})
        if strcmp(lmessage,'reset')
            shown_warnings=[];
        end

        show_warning=false;
        if strcmp(lmessage,'reset')
            shown_warnings=[];
        else
            when_show_warning=lmessage;
        end
    end

    if cosmo_match({message},{'on','off'})
        if nargout>0
            varargout{1}=warning(message,varargin{:});
        else
            warning(message,varargin{:});
        end
        show_warning=false;
    end

    if ~show_warning
        return
    end

    args=varargin;
    has_identifier=numel(args)>0 && has_warning_identifier(message);
    if has_identifier
        identifier=message;
        message=args{1};
        args=args(2:end);
    end

    if numel(args)>0
        full_message=sprintf(message, args{:});
    else
        full_message=message;
    end

    has_warning=iscellstr(full_message) && ...
                    ~cosmo_match({full_message},shown_warnings);
    if ~has_warning
        if isnumeric(shown_warnings)
            shown_warnings=cell(0);
        end
        shown_warnings{end+1}=full_message;
    end

    switch when_show_warning
        case 'once'
            if ~has_warning
                me=mfilename();
                postfix=sprintf(['\n\nThis warning is shown only once, '...
                               'but the underlying issue may occur '...
                               'multiple times. To show each warning:\n'...
                               ' - every time:   %s(''on'')\n'...
                               ' - once:         %s(''once'')\n'...
                               ' - never:        %s(''off'')\n'],me,me,me);
                full_message=[full_message postfix];
            end
        case 'off'
            show_warning=false;
        case 'on'
            show_warning=true;
        otherwise
            assert(false);
    end

    if show_warning
        state=warning(); % store state
        state_resetter=onCleanup(@()warning(state));

        warning('on');
        % avoid extra entry on the stack
        if has_identifier
            warning(identifier,'%s',full_message);
        else
            warning('%s',full_message);
        end

    end

function tf=has_warning_identifier(s)
    alpha_num='([a-z_A-Z0-9]+)';
    pat=sprintf('^%s(:%s)?:%s$',alpha_num,alpha_num,alpha_num);
    tf=~isempty(regexp(s,pat,'once'));
