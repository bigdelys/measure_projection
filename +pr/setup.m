%% add paths for /dependency/ folder

fprintf(['Measure Projection Toolbox (MPT) ' pr.getVersionString(false) ' - Written by Nima Bigdely-Shamlo, Copyright (c) 2013 University of Californa San Diego\n']);
fprintf('This software is released under BSD license.\n');


fullPath = which('pr.dipole');
prSuperFolderPath = fullPath(1:end - length('+pr/dipole.m'));
dependeoncyPath = [prSuperFolderPath  'dependency'];

addpath(genpath(dependeoncyPath));

%% setup CVX library (contained in the dependency folder)

try
    cvx_setup;
catch
    fprintf('CVX library does not seem to be able to install properly, but MPT can still work (without some advanced options.)\n');
end;

%% set up the updater
if pr.updateCheckAllowed    
    [versionString dateString]= pr.getVersionString;
    clear mptUpdater;
    mptUpdater = up4mpt.updater(pr.robust_str2num(versionString), 'http://sccn.ucsd.edu/~nima/toolbox/mpt/latest_version.php', 'Measure Projection toolbox', dateString);
    mptUpdater = mptUpdater.checkForNewVersion({'mpt_event' 'setup'});
    
    if mptUpdater.newerVersionIsAvailable
        fprintf('\nA newer version (%s, %d days newer) of Measure Projection toolbox is available to download at: \n%s\n\n', num2str(mptUpdater.latestVersionNumber), mptUpdater.daysCurrentVersionIsOlder, mptUpdater.downloadUrl);
    elseif isempty(mptUpdater.lastTimeChecked)
        fprintf('Could not check for the latest Measure Projection toolbox version (internet may be disconnected).\n');
    else
        fprintf('You are using the latest version of MPT.\n');
    end;
end;