function bestTform = ransac(confidence, inlierErrorThreshold, numIterations, matchMatrix, f1, f2)
% Uses RANSAC to find a suitable affineTform model for given matching data

    % Start with identity model and computer no of inliers.
    bestTform = affine2d();
    [bestInlierCount, bestError] = findInliers(inlierErrorThreshold, ...
        bestTform, matchMatrix, f1, f2);
    
    % Iteratively update best model.
    for (iter = 1:numIterations)
        % [templatePoints, scenePoints] = sampleMatches(matchMatrix, f1, f2)
        indices = datasample(1:size(matchMatrix, 2), 3, 'Replace', false)
        [templatePoints, scenePoints] = getMatchingPoints(indices, matchMatrix, f1, f2)
        curTform = fitgeotrans(templatePoints, scenePoints, 'affine');
        [curInlierCount, error] = findInliers(inlierErrorThreshold, curTform, matchMatrix, f1, f2);
        if (curInlierCount > bestInlierCount)
            bestInlierCount = curInlierCount
            bestTform = curTform
            bestError = error
        end
    end
end

% TODO : Return inliers as well.
function [inlierCount, error] = findInliers(inlierErrorThreshold, tform, matchMatrix, f1, f2)
% Computes the inlierCount and error for passed transformation model
    inlierCount = 0;
    error = 0;
    for (idx = 1:size(matchMatrix, 2)) 
        [templatePoint, scenePoint] = getMatchingPoints(idx, matchMatrix, f1, f2);
        [tx, ty] =  transformPointsForward(tform, templatePoint(1), templatePoint(2));
        terror = pdist2([tx, ty], scenePoint, 'euclidean');
        if (terror < inlierErrorThreshold)
            inlierCount = inlierCount + 1;
        end
        error = error + terror;
    end
end

function [templatePoints, scenePoints] = getMatchingPoints(indices, matchMatrix, f1, f2)
    templateIdx = matchMatrix(1, indices);
    sceneIdx = matchMatrix(2, indices);
    templatePoints = f1(1:2, templateIdx)';
    scenePoints = f2(1:2, sceneIdx)';
end