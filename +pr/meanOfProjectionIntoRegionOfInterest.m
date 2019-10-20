classdef meanOfProjectionIntoRegionOfInterest
    properties
        membershipCube
        headGrid
        projectionParameter
        dipoleAndMeasure % contain a copy of the original dipoleAndMeasure but with the most memory-consuming part (linearizedMeasure field) removed.
        meanLinearizedProjectedMeasure   % weighted (by dipole denisty) mean of measure over all domain locations.
        stdOfLinearizedProjectedMeasure % (weighted) standard deviation of measure over all domain locations.
        significaqnceOfLinearizedProjectedMeasure % p values (e.g. from t-test) for the mean measure.
        totalDipoleMass
    end;
    
    methods
        function obj = meanOfProjectionIntoRegionOfInterest(dipoleAndMeasure, projectionParameter, membershipCube, headGrid, varargin)
            
            if nargin > 0
                % place input values in object
                obj.projectionParameter = projectionParameter;
                obj.membershipCube = membershipCube;
                obj.headGrid = headGrid;
                
                
                % project, average and find significance
                
                [projectionMatrix totalDipoleDenisty]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasure, headGrid, projectionParameter, membershipCube);
                
                obj.totalDipoleMass = sum(totalDipoleDenisty);
                totalDipoleDenisty = totalDipoleDenisty / obj.totalDipoleMass;
                
                linearizedProjectedMeasure = dipoleAndMeasure.linearizedMeasure * projectionMatrix;
                
                % collapse into one value (weighting by dipole denisty)
                projectedMeasureMeanIntoRoi = sum(linearizedProjectedMeasure .* repmat(totalDipoleDenisty, size(linearizedProjectedMeasure, 1),1), 2);
                
                % calculate weighted standard deviation
                differenceFromMean = (linearizedProjectedMeasure - repmat(projectedMeasureMeanIntoRoi, 1, size(linearizedProjectedMeasure, 2)));
                
                % we need to calculate the 'number of degrees of freedom' to calculate unbiased estimator of
                % weighted variance.
                V1 = sum(totalDipoleDenisty);
                V2 = sum(totalDipoleDenisty .^2);
                
                % I came up with this multipication by (numel(totalDipoleDenisty) - 1)
                % it is based on http://en.wikipedia.org/wiki/Weighted_mean#cite_note-0
                numberOfDegreesOfFreedom =  (numel(totalDipoleDenisty) - 1) * (V1^2-V2) / V1^2;
                
                projectedMeasureStdIntoRoi = (sum( differenceFromMean.^2 .* repmat(totalDipoleDenisty, size(linearizedProjectedMeasure, 1),1), 2) * (V1 / (V1^2-V2)) ) .^ 0.5;
                
                projectedMeasureTvalue = projectedMeasureMeanIntoRoi ./ (projectedMeasureStdIntoRoi / sqrt(numberOfDegreesOfFreedom));
                
                % place calculated values in the object
                obj.significaqnceOfLinearizedProjectedMeasure = tcdf(-abs(projectedMeasureTvalue), numberOfDegreesOfFreedom);
                obj.meanLinearizedProjectedMeasure = projectedMeasureMeanIntoRoi;
                obj.stdOfLinearizedProjectedMeasure = projectedMeasureStdIntoRoi;
                
                % remove measure data to save memory
                dipoleAndMeasure.linearizedMeasure = [];
                
                try % since scalpmap may not be a property
                    dipoleAndMeasure.scalpmap = [];
                catch
                end;
                
                obj.dipoleAndMeasure = dipoleAndMeasure;
            end;
        end;
        
        function figureHandle = plot(obj, pValueThreshold, varargin)
            
            if nargin <2
                pValueThreshold = 0.05;
            end;
            
            maskedMeanLinearizedProjectedMeasure = obj.meanLinearizedProjectedMeasure;
            maskedMeanLinearizedProjectedMeasure(obj.significaqnceOfLinearizedProjectedMeasure >= pValueThreshold) = 0;
            
            figureHandle = obj.dipoleAndMeasure.plot(maskedMeanLinearizedProjectedMeasure);
        end;
    end;
end