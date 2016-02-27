function progress_line=cosmo_show_progress(clock_start, progress, msg, prev_progress_line)
% Shows a progress bar, and time elapsed and expected to complete.
%
% progress_line=cosmo_show_progress(clock_start, progress[, msg[, prev_progress_line]])
%
% Inputs:
%   clock_start         The time the task started (from clock()).
%   progress            0 <= progress <= 1, where 0 means nothing
%                       completed and 1 means fully completed.
%   msg                 String with a message to be shown next to the
%                       progress bar (optional).
%   prev_progress_line  The output from the previous call to this
%                       function, if applicable (optional). If provided
%                       then invoking this function prefixes the output
%                       with numel(prev_progress_msg) backspace characters,
%                       which deletes the output from the previous call
%                       from the console. In other words, this allows for
%                       showing a progress message at a fixed location in
%                       the console window.
%
% Output:
%   progress_line       String indicating current progress using a bar,
%                       with time elapsed and expected time to complete
%                       (using linear extrapolation).
%
% Notes:
%   - As a side effect of this function, progress_msg is written to standard
%     out (the console).
%   - The use of prev_progress_line may not work properly if output is
%     written to standard out without using this function.
%
% Example:
%   % this code takes just over 3 seconds to run, and fills a progress bar.
%   prev_msg='';
%   clock_start=clock();
%   for k=0:100
%       pause(.03);
%       status=sprintf('done %.1f%%', k);
%       prev_msg=cosmo_show_progress(clock_start,k/100,status,prev_msg);
%   end
%   % output:
%   > +00:00:03 [####################] -00:00:00  done 100.0%
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<4 || isempty(prev_progress_line)
        delete_count=0; % nothing to delete
    elseif ischar(prev_progress_line)
        delete_count=numel(prev_progress_line); % count the characters
    end % if not a string, die ungracefully

    if nargin<3 || isempty(msg)
        msg='';
    end
    if progress<0 || progress>1
        error('illegal progress %d: should be between 0 and 1', progress);
    end

    if progress==0
        ratio_to_do=Inf;
    else
        ratio_to_do=(1-progress)/progress;
    end

    took=etime(clock, clock_start);
    eta=ratio_to_do*took; % 'estimated time of arrival'

    % set number of backspace characters
    delete_str=repmat(sprintf('\b'),1,delete_count);

    % define the bar
    bar_width=20;
    bar_done=round(progress*bar_width);
    bar_eta=bar_width-bar_done;
    bar_str=[repmat('#',1,bar_done) repmat('-',1,bar_eta)];

    % because msg may contain the '%' character (which is not to be
    % interpolated) care is needed to ensure that neither building the
    % progress line nor printing it to standard out applies interpolation.
    progress_line=[sprintf('+%s [%s] -%s  ', secs2str(took), bar_str, ...
                                        secs2str(-eta)),...
                   msg];

    if progress==1
        postfix=sprintf('\n');
    else
        postfix='';
    end

    fprintf('%s%s%s',delete_str,progress_line,postfix);

function [m,d]=moddiv(x,y)
    % helper function that does mod and div together so that m+d*y==x
    m=mod(x,y);
    d=(x-m)/y;

function str=secs2str(secs)
    % helper function that formats the number of seconds as
    % human-readable string

    % make secs positive (calling function should add '+' or '-')
    secs=abs(secs);

    if ~isfinite(secs)
        str='oo'; % attempt to look like 'infinity' symbol
        return
    end

    secs=round(secs); % do not provide sub-second precision

    % compute number of seconds, minutes, hours, and days
    [s,secs]=moddiv(secs,60);
    [m,secs]=moddiv(secs,60);
    [h,d]=moddiv(secs,24);

    % add prefix for day, if secs represents at least one day
    if d>0
        daypf=sprintf('%dd+',d);
    else
        daypf='';
    end

    str=sprintf('%s%02d:%02d:%02d', daypf, h, m, s);
