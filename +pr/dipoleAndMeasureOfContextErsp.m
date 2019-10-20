classdef dipoleAndMeasureOfContextErsp < pr.dipoleAndMeasure
    % holds ERSP measure related to a context cluster (clustered by question templates)
    properties
        time = [];
        frequency = [];
        scalpmap % information about dipole scalp maps
        contextCluster = [];
        erspMask
    end % properties
    methods
        function obj = dipoleAndMeasureOfContextErsp(contextCluster, coordinateFormat, varargin) % constructor
            
            % parent constructor
            obj = obj@pr.dipoleAndMeasure();
            
            % fix polarities based on the polarities of the question templates
            contextCluster = optimize_context_cluster_template_polarity(contextCluster);
            
            for i=1:length(contextCluster.template)
                obj.linearizedMeasure(:,i) = contextCluster.template(i).vectorizedErspTemplate * contextCluster.template(i).displayPolarity;
                
                obj.erspMask(:,i) = obj.linearizedMeasure(:,i) > contextCluster.template(i).erspSignificanceMin & obj.linearizedMeasure(:,i) < contextCluster.template(i).erspSignificanceMax;
                
                %obj.linearizedMeasure(erspMask,i) = 0;
                obj.location(i,:) = contextCluster.template(i).dipfitModel.posxyz(1,:);
                obj.direction(i,:) = contextCluster.template(i).dipfitModel.momxyz(1,:);
                
                obj.time = contextCluster.template(1).times;
                obj.frequency = contextCluster.template(1).frequencies;
                obj.contextCluster = contextCluster;
                
                % import scalp maps by interpolating them here.
                

               obj.measureLabel = 'Context ERSP';
            end;
            
            
            % make all the dipoles are in MNI coordinates. If they are in Spherical coordinates,
            % convert them to MNI.
            if strcmpi(coordinateFormat, 'spherical')
                obj = obj.convertDipoleCoordinatesFromSphericalToMni;
            end;
        end;
        function plot(obj, linearProjectedMeasureForCombinedCondition, createNewFigure, varargin)
            % varargin is for passing parameters to the plotting function
            
            if nargin < 3
                createNewFigure = true;
            end;
            
            if createNewFigure
                figure;
            end;
            
            erspTemplates = reshape(linearProjectedMeasureForCombinedCondition, length(obj.frequency), length(obj.time));
            logimagesc(obj.time, obj.frequency, erspTemplates);
            colorThreshold = max(abs(erspTemplates(:)));
            caxis([-colorThreshold colorThreshold]);
        end;
        function plotQuestionAndImage(obj, significanceLevel)
            
            if nargin < 2
                significanceLevel = 0.03;
            end;
            
            figure;
            plot_context_cluster_image(obj.contextCluster, 1, 'on', significanceLevel);
            
        end;
        
    end;
end