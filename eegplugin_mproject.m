function eegplugin_mproject(fig, try_strings, catch_strings)

% add main MPA folder to matlab path.
fullpath = which('eegplugin_mproject');
addpath(genpath(fullpath(1:end - length('eegplugin_mproject.m'))));

% setup dependencies.
pr.setup;
assignin('base', 'mptUpdater', mptUpdater);

% ---------------------
studymenu = findobj(fig, 'tag', 'study');
submenu = uimenu(studymenu, 'label', 'Measure Projection', 'Callback', @command_on_MPA_GUI_entrance, 'userdata', 'study:on');

% create a menu item for showing that a new update is available and place it in the updater object.
newerVersionMenu = uimenu(submenu, 'Label', 'Upgrade to the Latest Version', 'visible', 'off', 'userdata', 'study:on');
mptUpdater.menuItemHandle = newerVersionMenu;

% set the callback to bring up the updater GUI
icadefs; % for getting background color
mptUpdater.menuItemCallback = {@command_on_update_menu_click, mptUpdater, pr.getToolboxFolder, true, BACKEEGLABCOLOR};
assignin('base', 'mptUpdater', mptUpdater);

erpmenu = uimenu(submenu, 'Label', 'ERP', 'userdata', 'study:on');
erspmenu = uimenu(submenu, 'Label', 'ERSP', 'userdata', 'study:on');
itcmenu = uimenu(submenu, 'Label', 'ITC', 'userdata', 'study:on');
specmenu = uimenu(submenu, 'Label', 'Spec', 'userdata', 'study:on');
siftmenu = uimenu(submenu, 'Label', 'SIFT', 'userdata', 'study:on');
optionmenu = uimenu(submenu, 'Label', 'Options', 'Callback', @show_gui_options, 'userdata', 'study:on');
aboutmenu = uimenu(submenu, 'Label', 'About', 'Callback', @show_about, 'separator','on', 'userdata', 'study:on');


% global variables thet are used in the visualization functions.
global visualize_menu_label
global visualize_by_measure_menu_label
global visualize_by_domain_menu_label
global visualize_by_significance_menu_label

visualize_menu_label = 'Show volume';
visualize_by_measure_menu_label = 'Show colored by Measure';
visualize_by_domain_menu_label = 'Show colored by Domain';
visualize_by_significance_menu_label =  'Show colored by Significance';

measureMenu = {erpmenu erspmenu itcmenu specmenu siftmenu};

measureString = {'erp' 'ersp' 'itc' 'spec','sift'};
    
for i = 1:length(measureMenu)
    create_mpt_submenu(measureMenu{i}, measureString{i})    
end;

update_measure_projection_menu;
end

function command_on_update_menu_click(callerHandle, tmp, mptUpdater, installDirectory, goOneFolderLevelIn, backGroundColor)
postInstallCallbackString = 'clear all function functions; eeglab';
mptUpdater.launchGui(installDirectory, goOneFolderLevelIn, backGroundColor, postInstallCallbackString);
end

function command_on_MPA_GUI_entrance(callerHandle, tmp)
STUDY = evalin('base', 'STUDY;');

% populate STUDY.measureProjection.option field with default option values if necessary.
if ~isfield(STUDY, 'measureProjection') || ~isfield(STUDY.measureProjection, 'option') || isempty(STUDY.measureProjection.option)
    
    % initialize the field
    if ~isfield(STUDY, 'measureProjection')
        STUDY.measureProjection = struct;
    end;
    
    assignin('base', 'STUDY', STUDY);
    
    show_gui_options(0, true);
    STUDY = evalin('base', 'STUDY;'); % get it back into this workspace.
end;

% make sure the menu is updated and shows if domains are present for each measure;
update_measure_projection_menu;

% check for updates
if pr.updateCheckAllowed
    try
        mptUpdater = evalin('base', 'mptUpdater;');
        mptUpdater = mptUpdater.checkForNewVersion({'mpt_event' 'GUI_enter'});
        assignin('base', 'mptUpdater', mptUpdater);
    catch
    end;
end;
end


