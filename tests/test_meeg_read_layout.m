function test_suite=test_meeg_read_layout()
% regression tests for meeg_read_layout
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_layout_exceptions()
    aet=@(varargin)assertExceptionThrown(@()...
                cosmo_meeg_read_layout(varargin{:}),'');

    % illegal input type
    aet(struct);
    aet(1);

    % file does not exist
    aet(['foobar' rand_str() rand_str() rand_str()]);

    % not enough data fields
    aet(sprintf('1\n2)'));

    % illegal character
    for illegal_char='~!@#$%^&*()[]{};:'
        aet(sprintf('1 1 1 1 1 foo%s\n2 2 2 2 2 baz)', illegal_char));
    end


function test_layout_labels_with_hyphens()
    lay=struct();
    lay.label={'chan-1';'chan-2'};

    helper_test_with(lay);

function test_layout_labels_with_spaces()
    lay=struct();
    lay.label={'chan 1';'chan 2'};

    helper_test_with(lay);


function test_layout_labels_with_int_pos()
    nlabels=ceil(rand()*10+10);

    lay=struct();
    lay.pos=ceil(rand(nlabels,2)*10+10);

    helper_test_with(lay);

function test_layout_labels_with_float_pos()
    nlabels=ceil(rand()*10+10);

    lay=struct();
    lay.pos=rand(nlabels,2)*10+10;

    helper_test_with(lay);


function helper_test_with(lay)
    lay=make_full_lay(lay);

    helper_test_with_string(lay);
    helper_test_with_file(lay);


function helper_test_with_string(lay)
    s=lay2str(lay);
    lay_from_s=cosmo_meeg_read_layout(s);

    assert_layout_equal(lay,lay_from_s);

function helper_test_with_file(lay)
    s=lay2str(lay);

    tmp_fn=tempname();
    fid=fopen(tmp_fn,'w');
    file_closer=onCleanup(@()fclose(fid));
    file_deleter=onCleanup(@()delete(tmp_fn));
    fprintf(fid,'%s',s);
    clear file_closer;

    lay_from_tmp_fn=cosmo_meeg_read_layout(tmp_fn);

    assert_layout_equal(lay,lay_from_tmp_fn);




function assert_layout_equal(x,y)
    if isfield(x,'index')
        x=rmfield(x,'index');
    end

    if isfield(y,'index')
        y=rmfield(y,'index');
    end

    fns=sort(fieldnames(x));
    assertEqual(fns,sort(fieldnames(y)));

    for k=1:numel(fns)
        fn=fns{k};
        value_x=x.(fn);
        value_y=y.(fn);

        if isnumeric(value_x)
            assertElementsAlmostEqual(value_x,value_y,'absolute',1e-3);
        else
            assertEqual(value_x,value_y);
        end
    end




function s=lay2str(lay)
    lay=lay_convert_numeric_to_cell(lay);
    cell_elems=cat(2,lay.index,lay.pos,lay.width,lay.height,lay.label)';

    pat='%d  %.4f  %.4f  %.4f  %.4f  %s\n';
    s=sprintf(pat,cell_elems{:});



function lay=lay_convert_numeric_to_cell(lay)
    fns=fieldnames(lay);
    for k=1:numel(fns)
        fn=fns{k};
        value=lay.(fn);
        if isnumeric(value)
            value=num2cell(value);
            lay.(fn)=value;
        end
    end



function lay=make_full_lay(lay)
    % get size
    fns=fieldnames(lay);
    assert(numel(fns)==1);
    fn=fns{1};
    value=lay.(fn);
    nlabels=size(value,1);

    % add missing values
    to_add={'index',@() (1:nlabels)';...
            'pos',@() rand(nlabels,2);...
            'width',@() rand(nlabels,1);...
            'height',@() rand(nlabels,1);...
            'label',@() arrayfun(@rand_str,(1:nlabels)',....
                            'UniformOutput',false)};

    for k=1:size(to_add,1)
        label=to_add{k,1};

        if isfield(lay,label)
            continue
        end

        func=to_add{k,2};
        value=func();

        lay.(label)=value;
    end


function s=rand_str(unused)
    s=char(ceil(rand(1,10)*20+65));


