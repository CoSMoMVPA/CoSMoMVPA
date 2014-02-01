function s=cosmo_disp(x,varargin)
% converts data to a string representation
%
% NNO Jan 2014

    defaults.min_elips=3;
    defaults.precision=3;
    defaults.strlen=12;

    opt=cosmo_structjoin(defaults,varargin);

    if iscell(x)
        s=disp_cell(x,opt);
    elseif isnumeric(x) || islogical(x)
        s=disp_matrix(x,opt);
    elseif ischar(x)
        s=disp_string(x,opt);
    elseif isa(x, 'function_handle')
        s=disp_function_handle(x,opt);
    elseif isstruct(x)
        s=disp_struct(x,opt);
    else
        error('not supported: %s', class(x))
    end


    function y=strcat_vert(xs)
    % all elements in xs are char
    [nr,nc]=size(xs);
    y=cell(1,nc);

    % height of each row
    n_per_row=max(cellfun(@(x)size(x,1),xs),[],2);
    for k=1:nc
        xf=cell(nr,1);
        for j=1:nr
            x=xs{j,k};
            sx=size(x);
            % pad with spaces
            xf{j}=[x; repmat(' ',n_per_row(j)-sx(1), sx(2))];
        end
        y{k}=char(xf{:});
    end

    function y=strcat_hor(xs)
    y=strcat(xs); % TODO: check matlab versions supporting this


    function y=disp_struct(x,opt)
        fns=fieldnames(x);
        n=numel(fns);
        r=cell(n*2,1);
        for k=1:n
            fn=fns{k};
            r{k*2-1}=['.' fn];
            d=cosmo_disp(x.(fn),opt);
            r{k*2}=[repmat(' ',size(d,1),2) d];
        end
        v=strcat_vert(r);
        y=[v{:}];



    function s=disp_function_handle(x,opt)
        s=['@' disp_string(func2str(x),opt)];


    function s=disp_string(x, opt)
    if ~ischar(x), error('expected a char'); end
    if size(x,1)>1, error('need a single row'); end

    infix=' ... ';

    n=numel(x);
    if n>opt.strlen

        h=floor((opt.strlen-infix)/2);
        x=[x(1:h), infix ,x(n+((1-h):0))];
    end
    s=['''' x ''''];


    function s=disp_cell(x, opt)
    min_elips=opt.min_elips;
    precision=opt.precision;

    [ns,nf]=size(x);

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, min_elips, 1);
    [c_pre, c_post]=get_mx_idxs(x, min_elips, 2);

    y=x([r_pre r_post],[c_pre c_post]);
    sy=size(y);

    c=cell(sy);
    for k=1:numel(c)
        v=y{k};
        w=cosmo_disp(v,opt);
        c{k}=w;
    end

    sizes=cellfun(@numel,c);
    nmax=max(sizes(:));

    if ~isempty(r_post)
        d=cell(sy+[1,0]);
        d(1:min_elips,:)=c(1:min_elips,:);
        d(1+min_elips,:)=repmat({':'},1,sy(2));
        d(min_elips+1+(1:min_elips),:)=c(min_elips+(1:min_elips),:);
        c=d;
    end

    s=strcat_vert(c);

    if ~isempty(c_post)
        sy=size(y);
        d=cell(sy+[0,1]);
        d(:,1:min_elips)=c(:,1:min_elips);
        d(:,1+min_elips)=repmat({'  ...  '},sy(2)+1,1);
        d(:,min_elips+1+(1:min_elips))=c(:,min_elips+(1:min_elips));
        c=d;
    end

    [nr,nc]=size(y);

    s=cell(1,nc*2+1);

    for k=1:nc
        for j=1:nr
            if k==1 
                if j==1
                    s{j,k}='{ ';
                else
                    s{j,k}='  ';
                end
            end

            if k==nc
                if j==nr
                    filler=sprintf(' }@%dx%d',nr,nc);
                else
                    filler=' ;';
                end
            else
                filler='  ';
            end

            s{j,k*2+1}=filler;
            s{j,k*2}=c{j,k};

        end
    end

    s=strcat_vert(s);
    s=[s{:}];
    %s=c;


    function s=disp_matrix(x,opt)
    min_elips=opt.min_elips;
    precision=opt.precision;

    [ns,nf]=size(x);

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, min_elips, 1);
    [c_pre, c_post]=get_mx_idxs(x, min_elips, 2);

    y=x([r_pre r_post],[c_pre c_post]);

    s=num2str(y,precision);
    [nr,nc]=size(s);
    if ~isempty(r_post)
        % insert ':' halfway (row-wise)
        lastpos=find(sum(s~=' ',1)==0,1,'last');
        firstpos=find(sum(s~=' ',1)==0,1);
        step_size=floor(lastpos/(2*min_elips-1));

        offset=firstpos-1;
        cpos=offset:step_size:nc; % position of colon
        if isempty(cpos)
            cpos=nc;
        end

        line=repmat(' ',1,nc);
        line(cpos)=':';

        s=[s(1:min_elips,:); line; s(min_elips+(1:min_elips),:)];
    end

    if ~isempty(c_post)
        % insert '  ...  ' halfway (column-wise)
        [nr,nc]=size(s);
        step_size=nc/(2*min_elips);

        % position of dots
        dpos=floor(step_size*min_elips)+1;

        % insert dots
        lines=repmat('  ...  ',nr,1);
        s=[s(:,1:dpos) lines s(:,(dpos+1):end)];
    end

    if numel(x)>1
        nr=size(s,1);
        s=[['[ ';repmat('  ',nr-1,1)], s, [repmat(' ;',nr-1,1);' ]']];
    end


    function [pre,post]=get_mx_idxs(x, min_elips, dim)
    n=size(x,dim);

    if n>2*min_elips
        pre=1:min_elips;
        post=n-min_elips+(1:min_elips);
    else
        pre=1:n;
        post=[];
    end

