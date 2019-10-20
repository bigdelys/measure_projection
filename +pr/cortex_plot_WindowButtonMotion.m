function cortex_plot_WindowButtonMotion(handle, eventdata, firstTime, fsfHandleInput, cortextDomainColor, cortexPointDomainDenisty, inputOptions)

persistent lastRunClock lastViewAzimuth lastViewElevation

if firstTime 
    lastViewAzimuth = Inf;
    lastViewElevation = Inf;
end;


figureUserData = get(handle, 'UserData');
if isempty(figureUserData)
    return;
else
    fsfHandle = figureUserData.fsfHandle;
end;

vertexNormals = figureUserData.vertexNormals;

if ~isempty(lastRunClock)
    timeFromLastRun = etime(clock, lastRunClock);
else
    timeFromLastRun = Inf;
end;

[currentViewAzimuth currentViewElevation] = view;
viewHasRotated = abs(currentViewAzimuth - lastViewAzimuth) + abs(lastViewElevation - currentViewElevation) > 1; % 1 degrees

if (viewHasRotated && timeFromLastRun > 1) || firstTime % 1 second time to roate withouth update.

    % use camera position and surface normals to create a custom 'lighting' method which highlights
    % cortex silhouette
    cameraPosition = campos;
    
    cortexVertices =  get(fsfHandle, 'vertices');
    
    cameraToVerticeVector = cortexVertices - repmat(cameraPosition, [size(cortexVertices, 1), 1]);
    % make them have lenght 1
    cameraToVerticeVector = cameraToVerticeVector ./ repmat(sum(cameraToVerticeVector .^2,2) .^ 0.5, [1 3]);
    
    % make locations with positive inner product dark and other white (exactly the opposite of default
    % lighting)
    innerProductOfNormalsAndCameraVector = -sum(cameraToVerticeVector .* vertexNormals, 2);
    
    innerProductOfNormalsAndCameraVector(innerProductOfNormalsAndCameraVector<0) = 0;
    
    % change the spread of darkness (this ^ 0.4 makes the scene more uniformly dark, istead of just in the
    % middle where surface normals are close to perpendicular)
    innerProductOfNormalsAndCameraVector = innerProductOfNormalsAndCameraVector .^ 0.4;
    
    
    
    % prevent very white spots which produce aliasing effetcs
    inverseOfInnerProduct = (1-innerProductOfNormalsAndCameraVector);
    inverseOfInnerProduct(inverseOfInnerProduct>0.7) = 0.7;
    
    % per Scott's suggestion, prevent dark areas to be 'completely dark'    
    % this is similar to do a soft max and limit the minimum to 0.2    
    if inputOptions.minimumCortexLight ~= 0
        inverseOfInnerProduct = almost(inverseOfInnerProduct, 0.3, inputOptions.minimumCortexLight);
    end;
    
    % add some random noise to bring out the 3D.
    if inputOptions.noiseAmplitude >0
    inverseOfInnerProduct = inverseOfInnerProduct + (rand(size(inverseOfInnerProduct))) * inputOptions.noiseAmplitude;
    end;
    
    finalColorValues=  inverseOfInnerProduct * inputOptions.lightAmount * [1 1 1];   
    
    if ~isempty(cortextDomainColor)
        
        domainMassId = cortexPointDomainDenisty > eps;
        %finalColorValues(domainMassId,:) = (minimumDomainLight + repmat(inverseOfInnerProduct(domainMassId), [1 3]) .* lightAmount) .* cortextDomainColor(domainMassId,:);
        
        inverseOfInnerProductForDomainMassId = inverseOfInnerProduct(domainMassId);
        inverseOfInnerProductForDomainMassId = max(inverseOfInnerProductForDomainMassId, 0.2);
        
        finalColorValues(domainMassId,:) = (max(inputOptions.minimumDomainLight , (inputOptions.baseDomainLight + repmat(inverseOfInnerProductForDomainMassId, [1 3]))) .* inputOptions.lightAmount) .* cortextDomainColor(domainMassId,:) * inputOptions.domainAlpha;
        
        % make sure that the cortext silhouette is still plotted under domain locations
                     
%         finalColorValuesAverageLight = mean(finalColorValues, 2);
%         finalColorValuesMaxLight = mean(finalColorValues, 2);
%         id =  finalColorValuesMaxLight > 0.6;
%         finalColorValues(id,:) = 0.6 * finalColorValues(id,:) ./ repmat(finalColorValuesAverageLight(id), 1,3);
%         
        whiteUnderToneOfCortexSilhouette = inverseOfInnerProduct * inputOptions.lightAmount * [1 1 1];
        finalColorValues = max(finalColorValues, whiteUnderToneOfCortexSilhouette);
    end;
    
    % directly assign colors to vertices
    finalColorValues(finalColorValues>1) = 1;
    set(fsfHandle, 'FaceVertexCData', finalColorValues);
    
    set(fsfHandle, 'facecolor', 'interp');
    set(fsfHandle, 'edgecolor', 'interp');
    
    lastRunClock = clock;
    lastViewAzimuth  = currentViewAzimuth;  
    lastViewElevation = currentViewElevation;
end;
end