function notifyUpdater(releaseNotes)

if nargin < 1
    releaseNotes = '';
end;

[versionString dateString]= pr.getVersionString;

try
    up.updater.writeReleaseXml('/home/nima/public_html/toolbox/mpt/latestRelease.xml', pr.robust_str2num(versionString), 'https://bitbucket.org/bigdelys/measure-projection/get/default.zip', releaseNotes);
catch
    error('Measure Projection: Error in writing releease description file into Nima''s folder, you may not be Nima or have not permission to wite into his folder!');
end;