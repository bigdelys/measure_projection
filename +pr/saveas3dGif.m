function saveas3dGif(outputFilename, varargin)
% saveas3dGif(outputFilename, varargin)
% create animated GIF from Matlab figure.
% 
%   'rotationRange'       'real'     [1 360]   5;... % maximum rotation in azimuth
%   'numberOfFrames'      'integer'  [2 Inf]   5;... % number of rotation levels (actual number of frame in the gif file will be twice - 1 of this number).
%   'dpi'      'integer'     [10 800] 100;... % quality (dot per inch = DPI) of the output images. This will determine the image size of output file.
%   'dither'  'boolean'     []       false     ;... % dithering when reducing number of colors will increase the number of perceived  colors but add some spatial high frequency noise.
%   'emitWindowButtonMotionFcn'  'boolean' [] false;... % used for some special case with pr.plotCortex
%   'frameDelay'      'real'    [0 Inf]    0.1;... % how much each frame should be display. Lower values results in faster animation.
%   'figurehandle'   'real'    []   gcf;  % handle of the figure to be used.
%
%   Written by Nima Bigdely-Shamlo, Swartz Center. Copyright 2012, UCSD.



inputOptions = finputcheck(varargin, ...
    { 'rotationRange'       'real'     [1 360]   5;... % maximum rotation in azimuth
    'numberOfFrames'      'integer'  [2 Inf]   5;... % number of rotation levels (actual number of frame in the gif file will be twice - 1 of this number).
    'dpi'      'integer'     [10 800] 100;... % quality (dot per inch = DPI) of the output images. This will determine the image size of output file.
    'dither'  'boolean'     []       false     ;... % dithering when reducing number of colors will increase the number of perceived  colors but add some spatial high frequency noise.
    'emitWindowButtonMotionFcn'  'boolean' [] false;... % used for some special case with pr.plotCortex
    'frameDelay'      'real'    [0 Inf]    0.1;... % how much each frame should be display. Lower values results in faster animation.
    'figurehandle'   'object'    []   gcf;  % handle of the figure to be used.
    });

[OriginalAz,originalEl] = view;

%outputFilename = '~/plot/test3d.gif';

%azimuth = linspace(OriginalAz, OriginalAz + inputOptions.rotationRange, inputOptions.numberOfFrames);
nonlinearPower = 5;
%azimuth = real(linspace(OriginalAz^nonlinearPower, (OriginalAz + inputOptions.rotationRange) ^nonlinearPower, inputOptions.numberOfFrames) .^ (1/nonlinearPower));
azimuth = OriginalAz + -10+ linspace(10, 10+inputOptions.rotationRange ^nonlinearPower, inputOptions.numberOfFrames) .^ (1/nonlinearPower);


if inputOptions.emitWindowButtonMotionFcn
    callback =  get(gcf, 'WindowButtonMotionFcn');
end;

% save pictures with rotated azimuth in a temporary location
for i=1:length(azimuth)
    frameFilename{i}= [tempname '.png'];
    view(azimuth(i), originalEl);
    
    if inputOptions.emitWindowButtonMotionFcn
        callback{1}(gcf, [],callback{2}, callback{3}, callback{4}, callback{5}, callback{6});
    end;
    
    print('-dpng', ['-r' num2str(inputOptions.dpi)], frameFilename{i});
end;

% make a 3D gif from these images

% make the colormap index


% read, convert to indexed image and add to gif file.
clear frameInIndex
for i=1:length(azimuth)
    frameInRGB = imread(frameFilename{i});
    frameInRGB = im2double(frameInRGB);
    if i == 1
        [frameInIndex(:,:,1,i) colormapIndex] = rgb2ind(frameInRGB, 256, fastif(inputOptions.dither, 'dither', 'nodither'));
    else
        frameInIndex(:,:,1,i) = rgb2ind(frameInRGB, colormapIndex, fastif(inputOptions.dither, 'dither', 'nodither'));
    end;
end;

for i=(length(azimuth)-1):-1:1
    frameInIndex(:,:,1,end+1) = frameInIndex(:,:,1,i);
end;

imwrite(frameInIndex, colormapIndex, outputFilename, 'DelayTime', inputOptions.frameDelay, ...
    'LoopCount', inf);


