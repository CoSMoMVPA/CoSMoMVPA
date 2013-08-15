function data_path=cosmo_get_data_path(subject_id)
% helper function to get the data path.
% this function is to be extended to work on your machine, depending on
% where you stored the test data
% 
% Inputs
%   subject_id    optional subject id identifier. If provided it gives the
%                 data directory for that subject
%
% Returns
%  data_path      path where data is stored

% change the following depending on where your data resides
data_path='../../data';

if ismac()
    % specific code for NNO
    [p,q]=unix('uname -n');
    if p==0 && ~isempty(findstr(q,'nicks-MacBook-Pro.local'))
        data_path='/Users/nick/git/cosmo_repo2/data/';
    end
end


if nargin>=1
    if isnumeric(subject_id)
        subject_id=sprintf('s%02d', subject_id);
    end
    data_path=fullfile(data_path, subject_id);
end

if ~exist(data_path,'file')
    error('%s does not exist. Did you adjust %s?', data_path, mfilename());
end

if ~isempty(data_path)
    data_path=[data_path '/'];
end
