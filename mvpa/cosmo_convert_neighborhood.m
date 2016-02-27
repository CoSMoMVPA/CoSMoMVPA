function conv_nbrhood=cosmo_convert_neighborhood(nbrhood, output_type)
% Converts between cell, matrix and struct representations of neighborhoods
%
% conv_nbrhood=cosmo_convert_neighborhood(nbrhood[, output_type])
%
% Inputs:
%     nbrhood               Either a cell, struct, or matrix with
%                           neighborhood information:
%                           - cell:    Nx1 with nbrhood{k} the indices of
%                                      the k-th neighborhood
%                           - struct:  with field .neighbors, which must
%                                      be a cell
%                           - matrix:  MxN with nbrhood(:,k) the indices of
%                                      the k-th neighborhood (non-positive
%                                      values indicating no index), with M
%                                      the maximum number of features in a
%                                      single neighborhood
%     output_type           Optional, one of 'cell', 'matrix', or
%                           'struct'.
%                           If empty or omitted, then output_type is set to
%                           'matrix', unless nbrhood is a matrix, in
%                           which case it is set to 'cell'.
% Output:
%     conv_nbrhood          Neighborhood information converted to cell,
%                           struct, or matrix (see above)
%
% Example:
%     ds=cosmo_synthetic_dataset();
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     % show the neighbor indices
%     cosmo_disp(nbrhood.neighbors)
%     > { [ 1         4         2 ]
%     >   [ 2         1         5         3 ]
%     >   [ 3         2         6 ]
%     >   [ 4         1         5 ]
%     >   [ 5         4         2         6 ]
%     >   [ 6         5         3 ]           }
%     %
%     % convert to matrix representation
%     mx=cosmo_convert_neighborhood(nbrhood,'matrix');
%     cosmo_disp(mx)
%     > [ 1         2         3         4         5         6
%     >   4         1         2         1         4         5
%     >   2         5         6         5         2         3
%     >   0         3         0         0         6         0 ]
%     %
%     % convert to cell representation
%     neighbors=cosmo_convert_neighborhood(nbrhood,'cell');
%     cosmo_disp(neighbors)
%     > { [ 1         4         2 ]
%     >   [ 2         1         5         3 ]
%     >   [ 3         2         6 ]
%     >   [ 4         1         5 ]
%     >   [ 5         4         2         6 ]
%     >   [ 6         5         3 ]           }
%
% Notes:
%    - the rationale of this function is that cell or struct
%      representations are more intuitive and possible more space
%      efficient, but also slower to access than matrix representations.
%      This function provides conversion between different representations.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2, output_type=''; end

    if isnumeric(nbrhood)
        converter=@convert_matrix;
    elseif iscell(nbrhood)
        converter=@convert_cell;
    elseif isstruct(nbrhood)
        converter=@convert_struct;
    else
        error('Expected matrix, cell, or struct input');
    end

    conv_nbrhood=converter(nbrhood, output_type);

function y=convert_cell(x,output_type)
    check_cell(x);
    switch output_type
        case {'','matrix'}
            y=convert_cell2matrix(x);
        case 'struct'
            y=convert_cell2struct(x);
        case {'cell'}
            y=x;
        otherwise
            throw_illegal_output_type_error();
    end


function y=convert_matrix(x,output_type)
    check_matrix(x);
    switch output_type
        case {'','cell'}
            y=convert_matrix2cell(x);
        case 'struct'
            y=convert_matrix2struct(x);
        case 'matrix'
            y=x;
        otherwise
            throw_illegal_output_type_error();
    end

function y=convert_struct(x,output_type)
    check_struct(x);
    switch output_type
        case 'cell'
            y=convert_struct2cell(x);
        case {'','matrix'}
            y=convert_struct2matrix(x);
        case 'struct'
            y=x;
        otherwise
            throw_illegal_output_type_error();
    end

function check_matrix(neighbors)
    if numel(size(neighbors))~=2
        error('input is not a matrix');
    end

    assert(isnumeric(neighbors));

    if ~isequal(round(neighbors),neighbors)
        error('input has non-integer values');
    end

function check_struct(nbrhood)
    cosmo_check_neighborhood(nbrhood,'show_warning',false);

function check_cell(neighbors)
    check_struct(convert_cell2struct(neighbors));

function nbrhood=convert_cell2struct(neighbors)
    nbrhood=struct();
    nbrhood.neighbors=neighbors;
    nbrhood.fa=struct();
    nbrhood.a=struct();

function neighbors=convert_struct2cell(nbrhood)
    neighbors=nbrhood.neighbors;

function neighbor_matrix=convert_cell2matrix(neighbors)
    nfeatures=numel(neighbors);
    nnbrs=cellfun(@numel, neighbors);
    maxn=max(nnbrs);

    neighbor_matrix=zeros(maxn, nfeatures);
    for k=1:nfeatures
        nbrs=neighbors{k};
        neighbor_matrix(1:numel(nbrs),k)=nbrs;
    end

function neighbors=convert_matrix2cell(neighbor_matrix)
    nfeatures=size(neighbor_matrix,2);
    neighbors=cell(nfeatures,1);

    for k=1:nfeatures
        nbrs=neighbor_matrix(:,k);
        neighbors{k}=nbrs(nbrs>0)';
    end

function nbrhood=convert_matrix2struct(neighbor_matrix)
    nbrhood=convert_cell2struct(convert_matrix2cell(neighbor_matrix));

function neighbor_matrix=convert_struct2matrix(nbrhood)
    neighbor_matrix=convert_cell2matrix(convert_struct2cell(nbrhood));



function throw_illegal_output_type_error()
    valid_output_types={'','matrix','struct','cell'};
    error('illegal output type, valid is one of: ''%s''.',...
                cosmo_strjoin(valid_output_types,''', '''));

