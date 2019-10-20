function update_measure_projection_menu(callerHandle, tmp)

if nargin<2
    parentMenu = [];
end
    
maxDomainNo = 30;


try
    studyHasErpDomain = evalin('base', '~isempty(STUDY.measureProjection.erp.projection.domain)');
catch
    studyHasErpDomain = false;
end;

try
    studyHasErspDomain = evalin('base', '~isempty(STUDY.measureProjection.ersp.projection.domain)');
catch
    studyHasErspDomain = false;
end;

try
    studyHasItcDomain = evalin('base', '~isempty(STUDY.measureProjection.itc.projection.domain)');
catch
    studyHasItcDomain = false;
end;

try
    studyHasSpecDomain = evalin('base', '~isempty(STUDY.measureProjection.spec.projection.domain)');
catch
    studyHasSpecDomain = false;
end;

try
    studyHasSiftDomain = evalin('base', '~isempty(STUDY.measureProjection.sift.projection.domain)');
catch
    studyHasSiftDomain = false;
end;

mainfig = findobj('tag','EEGLAB');
if ~isempty(mainfig)
    std_menu  = findobj('parent', mainfig, 'type', 'uimenu', 'label', 'Study');
    mprojection_menu = findobj('parent', std_menu , 'type', 'uimenu', 'label', 'Measure Projection');
    mprojection_ERPmenu = findobj('parent', mprojection_menu , 'type', 'uimenu', 'label', 'ERP');
    mprojection_ERSPmenu = findobj('parent', mprojection_menu , 'type', 'uimenu', 'label', 'ERSP');
    mprojection_ITCmenu = findobj('parent', mprojection_menu , 'type', 'uimenu', 'label', 'ITC');
    mprojection_Specmenu = findobj('parent', mprojection_menu , 'type', 'uimenu', 'label', 'Spec');
    mprojection_SIFTmenu = findobj('parent', mprojection_menu , 'type', 'uimenu', 'label', 'SIFT');
    
    erpDomainMenu = findobj('parent', mprojection_ERPmenu , 'type', 'uimenu', 'label','Domains');
    erspDomainMenu = findobj('parent', mprojection_ERSPmenu , 'type', 'uimenu', 'label','Domains');
    itcDomainMenu = findobj('parent', mprojection_ITCmenu , 'type', 'uimenu', 'label','Domains');
    specDomainMenu = findobj('parent', mprojection_Specmenu , 'type', 'uimenu', 'label','Domains');
    siftDomainMenu = findobj('parent', mprojection_SIFTmenu , 'type', 'uimenu', 'label','Domains');
    
    set(erpDomainMenu,'enable',fastif(studyHasErpDomain,'on','off'));
    set(erspDomainMenu,'enable',fastif(studyHasErspDomain,'on','off'));
    set(itcDomainMenu,'enable',fastif(studyHasItcDomain,'on','off'));
    set(specDomainMenu,'enable',fastif(studyHasSpecDomain,'on','off'));
    set(siftDomainMenu,'enable',fastif(studyHasSiftDomain,'on','off'));
    
    if studyHasErpDomain
        nbErpDomains = evalin('base','size(STUDY.measureProjection.erp.projection.domain,2)');
        
        for i = 1:maxDomainNo
            if i <= nbErpDomains
                set(findobj('parent',erpDomainMenu,'Label',['Domain ' num2str(i)]),'visible','on');
            else
                set(findobj('parent',erpDomainMenu,'Label',['Domain ' num2str(i)]),'visible','off');
                
            end
        end
        
    end
    
    if studyHasErspDomain
        nbErspDomains = evalin('base','size(STUDY.measureProjection.ersp.projection.domain,2)');
        for i = 1:maxDomainNo
            if i <= nbErspDomains
                set(findobj('parent',erspDomainMenu,'Label',['Domain ' num2str(i)]),'visible','on');
            else
                set(findobj('parent',erspDomainMenu,'Label',['Domain ' num2str(i)]),'visible','off');
                
            end
        end
    end
    
    
    if studyHasItcDomain
        nbItcDomains = evalin('base','size(STUDY.measureProjection.itc.projection.domain,2)');
        for i = 1:maxDomainNo
            if i <= nbItcDomains
                set(findobj('parent',itcDomainMenu,'Label',['Domain ' num2str(i)]),'visible','on');
            else
                set(findobj('parent',itcDomainMenu,'Label',['Domain ' num2str(i)]),'visible','off');
            end
        end
    end
    
    
    
    if studyHasSpecDomain
        nbSpecDomains = evalin('base','size(STUDY.measureProjection.spec.projection.domain,2)');
        for i = 1:maxDomainNo
            if i <= nbSpecDomains
                set(findobj('parent',specDomainMenu,'Label',['Domain ' num2str(i)]),'visible','on');
            else
                set(findobj('parent',specDomainMenu,'Label',['Domain ' num2str(i)]),'visible','off');
            end
        end
    end
    
    if studyHasSiftDomain
        nbSiftDomains = evalin('base','size(STUDY.measureProjection.sift.projection.domain,2)');
        for i = 1:maxDomainNo
            if i <= nbSiftDomains
                set(findobj('parent',siftDomainMenu,'Label',['Domain ' num2str(i)]),'visible','on');
            else
                set(findobj('parent',siftDomainMenu,'Label',['Domain ' num2str(i)]),'visible','off');
                
            end
        end
    end
    
else
    evalin('base','eeglab redraw');
    update_measure_projection_menu
end

%evalin('base','mainfig = findobj(''tag'',''EEGLAB'');')