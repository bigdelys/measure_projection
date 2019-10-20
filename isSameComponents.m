function res = are_the_same_components(STUDY, measureName)
res = false;
if isfield(STUDY,'cluster') && isfield(STUDY.cluster,'comps') && isfield(STUDY.cluster,'sets')
    if isfield(STUDY.projection.(measureName),'lastCalculation') && isfield(STUDY.projection.(measureName).lastCalculation,'comps') && isfield(STUDY.projection.(measureName).lastCalculation,'sets')
        if isequal(STUDY.projection.(measureName).lastCalculation.sets,STUDY.cluster(1).sets) && isequal(STUDY.projection.(measureName).lastCalculation.comps,STUDY.cluster(1).comps)
            res = true;
        else
            res = false;
        end
    end
end
        
    
    
   