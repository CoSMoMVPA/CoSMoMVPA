function varargout=cosmo_warning(message, varargin)
% show a warning message; by default just once for each message
%
% cosmo_warning(message, ...)
%
% Inputs:
%   message      warning message to be shown, or one of:
%                'on'   : show all warning messages
%                'off'  : show no warning messages
%                'once' : show each warning message once [default]
%   ...          if a warning message is provided according with
%                placeholders as used in sprintf, then the subsequent
%                arguments should contain their values
%
% Notes:
%   - this function works more or less like matlab's warning function,
%     except that by default each warning is just shown once.
%
% NNO Aug 2014

    persistent when_show_warning;
    persistent shown_warnings;

    if nargin==0
        switch nargout
            case 0
                warning();
            case 1
                s=warning();
                s.when_show_warning=when_show_warning;
                s.shown_warnings=shown_warnings;
                varargout{1}=s;
            otherwise
                assert(false);
        end
        return
    end

    if isnumeric(when_show_warning)
        when_show_warning='once';
    end

    lmessage=lower(message);
    show_warning=true;

    if cosmo_match({lmessage},{'on','off','once','reset'})
        when_show_warning=lmessage;
        show_warning=false;
        if strcmp(lmessage,'reset')
            shown_warnings=[];
        end

    end

    if cosmo_match({message},{'on','off','query'})
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
    has_args=numel(args)>0;

    has_identifier=has_args && any(args{1}==':') && ~any(args{1}=='%');
    if has_identifier
        identifier=message;
        message=args(1);
        args=args(2:end);
    end

    if numel(args)>0
        full_message=sprintf(message, args{:});
    else
        full_message=message;
    end

    switch when_show_warning
        case 'once'
            if isnumeric(shown_warnings)
                shown_warnings=cell(0);
            end

            show_warning=~cosmo_match({full_message},shown_warnings);
            if show_warning

                shown_warnings{end+1}=full_message;
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
        s=warning(); % store state

        warning('on');
        % avoid extra entry on the stack
        if has_identifier
            warning(identifier,'%s',full_message);
        else
            warning('%s',full_message);
        end
        warning(s); % reset state
    end
