function create_mpt_submenu(measureMenuItem, measureString)

n_maxdomain = 30; %allowing max of 5 domains for demo

% global variables thet are used in the visualization function below.
global visualize_menu_label
global visualize_by_measure_menu_label
global visualize_by_domain_menu_label
global visualize_by_significance_menu_label

uimenu(measureMenuItem, 'Label', 'Project','Callback', {@command_measure_project, measureString}, 'userdata', 'study:on');
uimenu(measureMenuItem, 'Label', 'Create Domains','Callback',{@command_measure_create_domain, measureString}, 'userdata', 'study:on');
domains_menu = uimenu(measureMenuItem, 'Label', 'Domains','enable','off', 'userdata', 'study:on');

for j = 1:n_maxdomain
    domain_menu = uimenu(domains_menu, 'Label', ['Domain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show condition difference','Callback',{@command_measure_show_domain_condition_difference, measureString}, 'tag',[measureString 'ConditionDiffForDomain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show group difference','Callback',{@command_measure_show_domain_group_difference, measureString}, 'tag',[measureString 'GroupDiffForDomain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show measure','Callback',{@command_measure_show_domain_measure, measureString}, 'tag',[measureString 'MeasureForDomain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show volume','Callback',{@command_measure_show_domain_volume, measureString},'tag',[measureString 'VolumeForDomain ' num2str(j)],'separator','on', 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show cortex','Callback',{@command_measure_show_domain_on_cortex, measureString},'tag',[measureString 'VolumeForDomain ' num2str(j)], 'userdata', 'study:on');        
    uimenu(domain_menu,'Label', 'Show volume as MRI','Callback',{@command_measure_show_domain_volume_as_mri, measureString},'tag',[measureString 'VolumeMRIForDomain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show high contributing dipoles','Callback',{@command_measure_show_domain_dipole, measureString},'tag',[measureString 'DipoleForDomain ' num2str(j)], 'userdata', 'study:on');
    uimenu(domain_menu,'Label', 'Show high contributing scalp maps','Callback',{@command_measure_show_domain_scalpmap, measureString},'tag',[measureString 'ScalpMapForDomain ' num2str(j)], 'userdata', 'study:on');

    uimenu(domain_menu,'Label', 'Anatomical information','Callback',{@command_measure_show_domain_anatomical_information, measureString},'tag',[measureString 'ScalpMapForDomain ' num2str(j)], 'userdata', 'study:on', 'separator','on');
end

uimenu(measureMenuItem, 'Label', visualize_menu_label,'Callback',{@command_measure_visualize, measureString, visualize_menu_label},'separator','on', 'userdata', 'study:on');
uimenu(measureMenuItem, 'Label', 'Show cortex','Callback',{@command_measure_visualize_on_cortex, measureString},'separator','off', 'userdata', 'study:on');        

uimenu(measureMenuItem, 'Label', visualize_by_significance_menu_label,'Callback',{@command_measure_visualize, measureString, visualize_by_significance_menu_label},'separator','off', 'userdata', 'study:on');

uimenu(measureMenuItem, 'Label', visualize_by_measure_menu_label,'Callback',{@command_measure_visualize, measureString, visualize_by_measure_menu_label},'separator','off', 'userdata', 'study:on');
uimenu(measureMenuItem, 'Label', visualize_by_domain_menu_label,'Callback',{@command_measure_visualize, measureString, visualize_by_domain_menu_label},'separator','off', 'userdata', 'study:on');                
uimenu(measureMenuItem, 'Label', 'Show volume as MRI','Callback',{@command_measure_visualize_as_mri, measureString}, 'userdata', 'study:on');
end




function command_measure_project(callerHandle, evnt, measureName)

% get the STUDY and ALLEEG variables from workspace
STUDY = evalin('base', 'STUDY;');
ALLEEG = evalin('base', 'ALLEEG;');


% populate STUDY.measureProjection.option field with default option values.
if ~isfield(STUDY, 'measureProjection') || ~isfield(STUDY.measureProjection, 'option') || isempty(STUDY.measureProjection.option)
    
    % initialize the field
    if ~isfield(STUDY, 'measureProjection')
        STUDY.measureProjection = struct;
    end;
    assignin('base', 'STUDY', STUDY);
    
    show_gui_options(0, true);
    STUDY = evalin('base', 'STUDY;'); % get it back into this workspace.    
end;

switch measureName
    case 'erp'
        STUDY.measureProjection.(measureName).object = pr.dipoleAndMeasureOfStudyErp(STUDY, ALLEEG);
    case 'ersp'
        STUDY.measureProjection.(measureName).object = pr.dipoleAndMeasureOfStudyErsp(STUDY, ALLEEG);
    case 'itc'
        STUDY.measureProjection.(measureName).object = pr.dipoleAndMeasureOfStudyItc(STUDY, ALLEEG);
    case 'spec'
        STUDY.measureProjection.(measureName).object = pr.dipoleAndMeasureOfStudySpec(STUDY, ALLEEG);
    case 'sift'
        if ~exist('grp_mpa_prjGraphMetric','file')
            error('You must install the SIFT toolbox to use this feature');
        end
        cfg = arg_guipanel('Function',@grp_mpa_prjGraphMetric,'Parameters',{'STUDY',STUDY,'ALLEEG',ALLEEG},'PanelOnly',false);
        [~, STUDY.measureProjection.(measureName).object] = grp_mpa_prjGraphMetric('STUDY',STUDY,'ALLEEG',ALLEEG,cfg);
end;

STUDY.measureProjection.(measureName).headGrid = pr.headGrid(STUDY.measureProjection.option.headGridSpacing);
STUDY.measureProjection.(measureName).projection = pr.meanProjection(STUDY.measureProjection.(measureName).object, STUDY.measureProjection.(measureName).object.getPairwiseMutualInformationSimilarity, STUDY.measureProjection.(measureName).headGrid, 'numberOfPermutations', STUDY.measureProjection.option.numberOfPermutations, 'stdOfDipoleGaussian', STUDY.measureProjection.option.standardDeviationOfEstimatedDipoleLocation,'numberOfStdsToTruncateGaussian', STUDY.measureProjection.option.numberOfStandardDeviationsToTruncatedGaussaian, 'normalizeInBrainDipoleDenisty', fastif(STUDY.measureProjection.option.normalizeInBrainDipoleDenisty,'on', 'off'));

STUDY = place_components_for_projection_of_measure(STUDY, measureName);

% put the STUDY variable back from workspace
assignin('base', 'STUDY', STUDY);


% show significant areas as volume.
significanceLevel = getVoxelSignificance(STUDY, measureName);
STUDY.measureProjection.(measureName).projection.plotVolume(significanceLevel);
end

function significanceLevel = getVoxelSignificance(STUDY, measureName)
if STUDY.measureProjection.option.([measureName 'FdrCorrection'])
    significanceLevel = fdr(STUDY.measureProjection.(measureName).projection.convergenceSignificance(STUDY.measureProjection.(measureName).headGrid.insideBrainCube(:)), STUDY.measureProjection.option.([measureName 'Significance']));
else
    significanceLevel = STUDY.measureProjection.option.([measureName 'Significance']);
end;
end

function command_measure_visualize(callerHandle, evnt, measureName, visualizationType)
if nargin<2
    visualizationType = 'by color';
end;
% get the STUDY and ALLEEG variables from workspace
STUDY = evalin('base', 'STUDY;');

if ~are_the_same_components(STUDY, measureName)
    command_measure_project([], [], measureName);
    STUDY = evalin('base', 'STUDY;');
end;

significanceLevel = getVoxelSignificance(STUDY, measureName);

global visualize_menu_label
global visualize_by_measure_menu_label
global visualize_by_domain_menu_label
global visualize_by_significance_menu_label
switch visualizationType
    case visualize_by_measure_menu_label % color by projected measure.
        STUDY.measureProjection.(measureName).projection.plotVolumeColoredByMeasure(significanceLevel, STUDY.measureProjection.(measureName).object);
    case visualize_menu_label   % only use a single uniform color.
        STUDY.measureProjection.(measureName).projection.plotVolume(significanceLevel);
    case visualize_by_domain_menu_label  % plot domains with different colors
        % check if domains are present, if not it will create them before visualiziation.
        if isempty(STUDY.measureProjection.(measureName).projection.domain)
         fprintf('Measure Projection: No Domain is present, creating Domains now...\n');
         command_measure_create_domain(measureName);   
         
         % update our copy of study;
         STUDY = evalin('base', 'STUDY;');
        end;
        
        STUDY.measureProjection.(measureName).projection.plotVolumeColoredByDomain;
    case visualize_by_significance_menu_label
        STUDY.measureProjection.(measureName).projection.plotVoxelColoredBySignificance;
end;


% put the STUDY variable back from workspace
assignin('base', 'STUDY', STUDY);
end

function command_measure_visualize_as_mri(callerHandle, evnt, measureName)

% get the STUDY and ALLEEG variables from workspace
STUDY = evalin('base', 'STUDY;');

componentsAreTheSame = are_the_same_components(STUDY, measureName);
if ~componentsAreTheSame
    command_measure_project([], [], measureName);
    STUDY = evalin('base', 'STUDY;');
end;

significanceLevel = getVoxelSignificance(STUDY, measureName);
STUDY.measureProjection.(measureName).projection.plotMri(significanceLevel);

% put the STUDY variable back from workspace
if ~componentsAreTheSame
    assignin('base', 'STUDY', STUDY);
    eeglab redraw;
end;
end

function command_measure_visualize_on_cortex(callerHandle, evnt, measureName)

% get the STUDY and ALLEEG variables from workspace
STUDY = evalin('base', 'STUDY;');

componentsAreTheSame = are_the_same_components(STUDY, measureName);
if ~componentsAreTheSame
    command_measure_project([], [], measureName);
    STUDY = evalin('base', 'STUDY;');
end;

% put the STUDY variable back from workspace
if ~componentsAreTheSame
    assignin('base', 'STUDY', STUDY);
    eeglab redraw;
end;

significanceLevel = getVoxelSignificance(STUDY, measureName);
STUDY.measureProjection.(measureName).projection.plotCortex(significanceLevel);
end

function command_measure_create_domain(callerHandle, evnt, measureName)

% get the STUDY and ALLEEG variables from workspace
STUDY = evalin('base', 'STUDY;');

if ~are_the_same_components(STUDY, measureName)
    command_measure_project([], [], measureName);
    STUDY = evalin('base', 'STUDY;');
end;

significanceLevel = getVoxelSignificance(STUDY, measureName);
maxDomainExemplarCorrelation = STUDY.measureProjection.option.([measureName 'MaxCorrelation']);
STUDY.measureProjection.(measureName).projection = STUDY.measureProjection.(measureName).projection.createDomain(STUDY.measureProjection.(measureName).object, maxDomainExemplarCorrelation, significanceLevel);

% put the STUDY variable back from workspace
assignin('base', 'STUDY', STUDY);
update_measure_projection_menu;

% show the newly created domain with different colors.
STUDY.measureProjection.(measureName).projection.plotVolumeColoredByDomain;
        
end

function command_measure_show_domain_volume(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotVolume;
    else
        return;
    end   
end

function command_measure_show_domain_on_cortex(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotCortex;
    else
        return;
    end   
end


function command_measure_show_domain_measure(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotMeasure;
    else
        return;
    end   
end

function command_measure_show_domain_condition_difference(callerHandle1, evnt1, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        if isfield(STUDY, 'measureProjection') && isfield(STUDY.measureProjection, 'option') && isfield(STUDY.measureProjection.option, 'conditionDifferenceOption') && ~isempty(STUDY.measureProjection.option.conditionDifferenceOption)
            STUDY.measureProjection.option.conditionDifferenceOption = STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotConditionDifferenceGui(STUDY.measureProjection.(measureName).object, STUDY.measureProjection.option.conditionDifferenceOption);
        else
            STUDY.measureProjection.option.conditionDifferenceOption = STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotConditionDifferenceGui(STUDY.measureProjection.(measureName).object);
        end;
        
        % put the STUDY variable back from workspace
        assignin('base', 'STUDY', STUDY);
    else
        return;
    end   
end

function command_measure_show_domain_group_difference(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        if isfield(STUDY, 'measureProjection') && isfield(STUDY.measureProjection, 'option') && isfield(STUDY.measureProjection.option, 'groupDifferenceOption') && ~isempty(STUDY.measureProjection.option.groupDifferenceOption)
            STUDY.measureProjection.option.groupDifferenceOption = STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotGroupDifferenceGui(STUDY.measureProjection.(measureName).object, STUDY.measureProjection.option.groupDifferenceOption);
        else
            STUDY.measureProjection.option.groupDifferenceOption = STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotGroupDifferenceGui(STUDY.measureProjection.(measureName).object);
        end;
        
        % put the STUDY variable back from workspace
        assignin('base', 'STUDY', STUDY);
    else
        return;
    end   
end

function command_measure_show_domain_volume_as_mri(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotMri;
        eeglab redraw;
    else
        return;
    end   
end

function command_measure_show_domain_dipole(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotDipole(STUDY.measureProjection.(measureName).object);
    else
        return;
    end   
end

function command_measure_show_domain_scalpmap(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).plotScalpMap;
    else
        return;
    end   
end

function command_measure_show_domain_anatomical_information(callerHandle, evnt, measureName)
    tagForHandle = get(gcbo, 'tag');
    if ischar(tagForHandle(end)) && ~isempty(tagForHandle(end))
        domainIndex = str2num(tagForHandle(end));
        STUDY = evalin('base', 'STUDY;');
        STUDY.measureProjection.(measureName).projection.domain(domainIndex).describeInPopup;
    else
        return;
    end   
end

function show_about(callerHandle, tmp)
    handle = open ('about.fig');
    icadefs; % provides GUIBACKCOLOR in current workspace.
    set(handle, 'color', GUIBACKCOLOR);
    
    % change background color of text elements to background color of the figure (which is EEGLAB
    % GUI color)
    set(findobj(get(handle,'children'), 'style','text'), 'backgroundcolor', GUIBACKCOLOR);
end




function res = are_the_same_components(STUDY, measureName)
res = false;
if isfield(STUDY,'cluster') && isfield(STUDY.cluster,'comps') && isfield(STUDY.cluster,'sets')
    if isfield(STUDY,'measureProjection') && isfield(STUDY.measureProjection, measureName) && isfield(STUDY.measureProjection.(measureName),'lastCalculation') && isfield(STUDY.measureProjection.(measureName).lastCalculation,'comps') && isfield(STUDY.measureProjection.(measureName).lastCalculation,'sets')
        if isequal(STUDY.measureProjection.(measureName).lastCalculation.sets,STUDY.cluster(1).sets) && isequal(STUDY.measureProjection.(measureName).lastCalculation.comps,STUDY.cluster(1).comps)
            res = true;
        else
            res = false;
        end
    end
end
end

function STUDY = place_components_for_projection_of_measure(STUDY, measureName)
    STUDY.measureProjection.(measureName).lastCalculation.sets = STUDY.cluster(1).sets;
    STUDY.measureProjection.(measureName).lastCalculation.comps = STUDY.cluster(1).comps;    
end

