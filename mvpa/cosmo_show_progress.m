function full_msg=cosmo_show_progress(clock_start, progress, msg, prev_msg)

    if nargin<4
        delete_count=0;
    elseif ischar(prev_msg)
        delete_count=numel(prev_msg);
    end
    
    if nargin<3 || isempty(msg)
        msg='';
    end

    took=etime(clock, clock_start);
    
    eta=(1-progress)/progress*took;
   
    delete_str=repmat('\b',1,delete_count);
    %delete_str='';
    %delete_count
    %numel(msg)
    %fprintf('@@ %s', prev_msg)
    
    bar_width=20;
    bar_done=round(progress*bar_width);
    bar_eta=bar_width-bar_done;
    bar_str=[repmat('#',1,bar_done) repmat('-',1,bar_eta)];
  
    st=dbstack();
    caller_str=st(end).name;
    
    full_msg=sprintf('%s [%s] %s  %s  [%s]\n', secs2str(took), bar_str, ...
                                        secs2str(-eta), msg, caller_str);
    
    fprintf([delete_str full_msg]);

    
    function [m,d]=moddiv(x,y)
        m=mod(x,y);
        d=(x-m)/y;

    function str=secs2str(secs)
        is_neg=secs<0;
        if is_neg
            secs=-secs;
        end
        
        if ~isfinite(secs)
            str='oo';
            return
        end
        
        secs=round(secs);
        
        [s,secs]=moddiv(secs,60);
        [m,secs]=moddiv(secs,60);
        [h,d]=moddiv(secs,24);
        
        % add prefix for day and sign, if necessary
        if d>0, daypf='%d+'; else daypf=''; end
        if is_neg, signpf='-'; else signpf='+'; end
        
        str=sprintf('%s%s%02d:%02d:%02d',signpf, daypf, h,m,s);
        
    
    



