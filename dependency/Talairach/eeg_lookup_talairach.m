function EEG = eeg_lookup_talairach(EEG,confusion_sphere)
% Look up dipole structure labels from Talairach, and add to EEGLAB dataset (in the .dipfit field)
% EEG = eeg_lookup_talairach(EEG)
%
% In:
%   EEG : EEGLAB data set with .dipfit structure
%
%   ConfusionSphere : radius of assumed sphere of confusion around dipfit locations (to arrive at 
%                     probabilities), in milimeters (default: 10)
%
% Out:
%   EEG : EEGLAB data set with associated labels
%
% Example:
%   % load data set and do a lookup
%   eeg = pop_loadset('/data/projects/RSVP/exp53/realtime/exp53_target_epochs.set')
%   labeled = eeg_lookup_talairach(eeg)
%
%   % show structure labels and associated probabilities for component/dipole #17
%   labeled.dipfit.model(17).structures
%   labeled.dipfit.model(17).probabilities
%
% TODO:
%   % Replace sphere by a Gaussian with std. dev.
%
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2011-04-06

if ~exist('confusion_sphere','var')
    confusion_sphere = 10; end

if ~exist('org.talairach.Database','class')
    javaaddpath('/data/common/brain_atlases/Talairach/talairach.jar'); end

db = org.talairach.Database;
db.load('/data/common/brain_atlases/Talairach/talairach.nii');
for k=1:length(EEG.dipfit.model)
    try
        p = icbm_spm2tal(EEG.dipfit.model(k).posxyz);
        EEG.dipfit.model(k).labels = cellfun(@(d)char(d),cell(db.search_range(p(1),p(2),p(3),confusion_sphere)),'UniformOutput',false);
        % and compute structure probabilities within the selected volume
        [structures,x,idxs] = unique(hlp_split(sprintf('%s,',EEG.dipfit.model(k).labels{:}),',')); %#ok<ASGLU>
        probabilities = mean(bsxfun(@eq,1:max(idxs),idxs'));
        [probabilities,reindex] = sort(probabilities,'descend');
        structures = structures(reindex);
        mask = ~strcmp(structures,'*');
        EEG.dipfit.model(k).structures = structures(mask);
        EEG.dipfit.model(k).probabilities = probabilities(mask)*5; % there are 5 partitions
    catch
        EEG.dipfit.model(k).labels = {};
        EEG.dipfit.model(k).structures = {};
        EEG.dipfit.model(k).probabilities = [];
    end
end




function outpoints = icbm_spm2tal(inpoints)
%
% This function converts coordinates from MNI space (normalized 
% using the SPM software package) to Talairach space using the 
% icbm2tal transform developed and validated by Jack Lancaster 
% at the Research Imaging Center in San Antonio, Texas.
%
% http://www3.interscience.wiley.com/cgi-bin/abstract/114104479/ABSTRACT
% 
% FORMAT outpoints = icbm_spm2tal(inpoints)
% Where inpoints is N by 3 or 3 by N matrix of coordinates
% (N being the number of points)
%
% ric.uthscsa.edu 3/14/07

% find which dimensions are of size 3
dimdim = find(size(inpoints) == 3);
if isempty(dimdim)
  error('input must be a N by 3 or 3 by N matrix')
end

% 3x3 matrices are ambiguous
% default to coordinates within a row
if dimdim == [1 2]
  disp('input is an ambiguous 3 by 3 matrix')
  disp('assuming coordinates are row vectors')
  dimdim = 2;
end

% transpose if necessary
if dimdim == 2
  inpoints = inpoints';
end

% Transformation matrices, different for each software package
icbm_spm = [0.9254 0.0024 -0.0118 -1.0207
	   	   -0.0048 0.9316 -0.0871 -1.7667
            0.0152 0.0883  0.8924  4.0926
            0.0000 0.0000  0.0000  1.0000];

% apply the transformation matrix
inpoints = [inpoints; ones(1, size(inpoints, 2))];
inpoints = icbm_spm * inpoints;

% format the outpoints, transpose if necessary
outpoints = inpoints(1:3, :);
if dimdim == 2
  outpoints = outpoints';
end



function res = hlp_split(str,delims)
% Split a string according to some delimiter(s).
% Result = hlp_split(String,Delimiters)
%
% In:
%   String : a string (char vector)
%
%   Delimiters : a vector of delimiter characters (includes no special support for escape sequences)
%
% Out:
%   Result : a cell array of (non-empty) non-Delimiter substrings in String
%
% Examples:
%   % split a string at colons and semicolons; returns a cell array of four parts
%   hlp_split('sdfdf:sdfsdf;sfdsf;;:sdfsdf:',':;')
% 
%                                Christian Kothe, Swartz Center for Computational Neuroscience, UCSD
%                                2010-11-05

pos = find(diff([0 ~sum(bsxfun(@eq,str(:)',delims(:)),1) 0]));
res = cell(~isempty(pos),length(pos)/2);
for k=1:length(res)
    res{k} = str(pos(k*2-1):pos(k*2)-1); end
