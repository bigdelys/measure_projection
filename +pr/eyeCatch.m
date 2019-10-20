classdef eyeCatch
    % Detetcs eye ICs based solely based on on their scalpmaps.
    % The input can be an EEG structure, an array of scalpmaps (channwel weights and location, e.g.
    % from EEG.chanlocs and EEG.icawinv) or an pr.scalpmap object from MPT.
    %
    % Example 1:   (finding eye ICs in the EEG structure)
    %
    % >> eyeDetector = pr.eyeCatch; % create an object from the class. Once you made an object it can
    %                               % be used for multiple detections (much faster than creating an
    %                               % object each time).
    % >> [eyeIC similarity scalpmapObj] = eyeDetector.detectFromEEG(EEG); % detect eye ICs
    % >> eyeIC   % display the IC numbers for eye ICs.
    % >> scalpmapObj.plot(eyeIC)   % plot eye ICs
    %
    % Example 2:
    %
    % >> eyeDetector = pr.eyeCatch; % create an object from the class. Once you made an object it can
    %                               % be used for multiple detections (much faster than creating an
    %                               % object each time).
    % >> [isEye similarity scalpmapObj] = pr.eyeDetector.detectFromStudy(STUDY, ALLEEG); % read data from a loaded study
    % >> find(isEye)   % display the IC numbers for eye ICs (since isEye is a logical array). The
    %                  % order of ICs is same order as in STUDY.cluster(1).comps .
    % >> scalpmapObj.plot(isEye)   % plot eye ICs
    %
    % Written by Nima Bigdely-Shamlo, Swartz Center, INC, UCSD.
    % Copyright © 2012 University Of California San Diego. Distributed under BSD License.
    
    properties
        eyeScalpmapDatabase
        eyeChannelWeightNormalized % precomputed normalized eye scalpmaps channel weights on interpolated 2D scalp.
        similarityThreshold = 0.944
    end;
    
    methods
        function obj = eyeCatch(similarityThreshold, varargin)
            % obj = eyeCatch(similarityThreshold)
            if nargin > 0
                obj.similarityThreshold = similarityThreshold;
            end;
            
            eyeDataset = load('eyeScalpmapDataset.mat');
           
            obj.eyeScalpmapDatabase = eyeDataset.pooledEyeScalpmap;
            obj.eyeChannelWeightNormalized = eyeDataset.eyeChannelWeightNormalized;
            if size(obj.eyeChannelWeightNormalized,1) ~= obj.eyeScalpmapDatabase.numberOfScalpmaps
                fprintf('Precomputed weights are being recomputed.\n');
                % to do compute weights
                channelWeight = obj.eyeScalpmapDatabase.originalChannelWeight(:,:);
                channelWeight(isnan(channelWeight)) = 0;
                channelWeight = channelWeight';
                
                channelWeightNormalized = bsxfun(@minus, channelWeight,  mean(channelWeight));
                channelWeightNormalized = bsxfun(@rdivide, channelWeightNormalized,  std(channelWeightNormalized));
                eyeChannelWeightNormalized = channelWeightNormalized';
                
                % save the file (overwrite)
                pooledEyeScalpmap = obj.eyeScalpmapDatabase;
                fullPath = which('eyeScalpmapDataset.mat');
                try
                    save(fullPath, 'pooledEyeScalpmap', 'eyeChannelWeightNormalized');
                    fprintf('New precomputed weights saved.\n');
                catch
                    fprintf('Could not save newly precomputed weights, please check if you have write permission.\n');
                end;
            end;
        end;
        
        function [isEye similarity] = detectFromInterpolatedChannelWeight(obj, channelWeight, similarityThreshold, varargin)
            % [isEye similarity] = detectFromInterpolatedChannelWeight(obj, channelWeight, similarityThreshold)
            
            if nargin < 3
                similarityThreshold = obj.similarityThreshold;
            end;
            
            channelWeight(isnan(channelWeight)) = 0;
            channelWeight = channelWeight';
            
            channelWeightNormalized = bsxfun(@minus, channelWeight,  mean(channelWeight));
            channelWeightNormalized = bsxfun(@rdivide, channelWeightNormalized,  std(channelWeightNormalized));
            channelWeightNormalized = channelWeightNormalized';
            
            if size(channelWeightNormalized,1)<1000
                similarity  = max(abs(obj.eyeChannelWeightNormalized * channelWeightNormalized')) / (size(obj.eyeChannelWeightNormalized,2));;
            else % to prevent memoery issues when creating a large matrix of similarities to ~3500 eye scalpmaps, we calculate it blockwise.               
                similarity = zeros(size(channelWeightNormalized, 1), 1);
                for i=1:1000:size(channelWeightNormalized, 1)
                    id = i + (1:1000) - 1;
                    id(id>size(channelWeightNormalized, 1)) = [];
                    similarity(id)  = max(abs(obj.eyeChannelWeightNormalized * channelWeightNormalized(id,:)')) / (size(obj.eyeChannelWeightNormalized,2));
                end;
                similarity = similarity';
            end;
            
            isEye = similarity > similarityThreshold;
        end;
        
        function [isEye similarity] = detectFromScalpmapObj(obj, scalpmapObj, similarityThreshold, varargin)
            % [isEye similarity] = detectFromScalpmapObj(obj, scalpmapObj, similarityThreshold)
            
            if nargin < 3
                similarityThreshold = obj.similarityThreshold;
            end;
            
            [isEye similarity] = detectFromInterpolatedChannelWeight(obj, scalpmapObj.originalChannelWeight(:,:), similarityThreshold);
        end;
        
        function [eyeIC similarity scalpmapObj] = detectFromEEG(obj, EEG, similarityThreshold, varargin)
            % [eyeIC similarity scalpmapObj] = detectFromEEG(obj, EEG, similarityThreshold)
            
            if nargin < 3
                similarityThreshold = obj.similarityThreshold;
            end;
            
            if isempty(EEG.icachansind)
                EEG.icachansind= 1:length(EEG.chanlocs);
            end;
            
            [isEye similarity scalpmapObj] = detectFromChannelWeight(obj, EEG.icawinv, EEG.chanlocs(EEG.icachansind), similarityThreshold);
            eyeIC = find(isEye); % actual indices might be easier to understand than a logical array.
        end;
        
        function [isEye similarity scalpmapObj] = detectFromChannelWeight(obj, channelWeight, channelLocation, similarityThreshold, varargin)
            % [isEye similarity] = detectFromChannelWeight(obj, channelWeight, channelLocation, similarityThreshold)
            if nargin < 3
                similarityThreshold = obj.similarityThreshold;
            end;
            
            scalpmapObj = pr.scalpmap; 
            scalpmapObj = scalpmapObj.addFromChannels(channelWeight, channelLocation);
            [isEye similarity] = detectFromScalpmapObj(obj, scalpmapObj, similarityThreshold);
        end;
        
        function [isEye similarity scalpmapObj] = detectFromStudy(obj, STUDY, ALLEEG, similarityThreshold, varargin)
            scalpmapObj = pr.scalpmapOfStudy(STUDY, ALLEEG, [], 'normalizePolarity', false);
            [isEye similarity] = detectFromScalpmapObj(obj, scalpmapObj, similarityThreshold);
        end;
    end;
end