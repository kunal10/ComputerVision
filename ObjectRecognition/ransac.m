function [bestTform, bestInlierCount, bestInlierIdx, bestError] = ...
    ransac(inlierErrorThreshold, numIterations, matchMatrix, f1, f2)
% Uses RANSAC to find a suitable affineTform model for given matching data.
% If number of matches is less than 3, or no 3 non collinear matches are
% are foudn in sufficient no of iterations then returns identity.

    % Constans used to return quickly for easily obtained matches.
    FAST_INLIER_THRESHOLD = 300;
    FAST_NUM_ITERATIONS = 50;
    
    numMatches = size(matchMatrix, 2);
    % Start with identity model and compute no of inliers.
    bestTform = affine2d();
    [bestInlierIdx, bestInlierCount, bestError] = findInliers(...
        inlierErrorThreshold, bestTform, matchMatrix, f1, f2);
    
    if (numMatches < 3)
        fprintf('Matches dont contain sufficient number of non collinear points.');
        return;
    end
    
    % Iteratively update best model.
    for (iter = 1:numIterations)        
        indices = datasample(1:numMatches, 3, 'Replace', false);
        [templatePoints, scenePoints] = getMatchingPoints(indices, ...
            matchMatrix, f1, f2);            
        
        % Fit affine transform.
        try 
            curTform = fitgeotrans(templatePoints, scenePoints, 'affine');
        catch
            % Sample points are collinear so skip this iteration.
            continue;
        end
        
%         % Ignore selections which are almost collinear points.
%         if (areCollinear(templatePoints) | areCollinear(scenePoints))
%             continue;
%         end
        
        [inlierIdx, curInlierCount, error] = ...
            findInliers(inlierErrorThreshold, curTform, matchMatrix, f1, f2);
        
        % Update parameters.
        if (curInlierCount > bestInlierCount)
            bestInlierCount = curInlierCount;
            bestInlierIdx = inlierIdx;
            bestTform = curTform;
            bestError = error;
            
            numInliers = size(inlierIdx);
            if (numInliers < 3)
               continue; 
            end
            % Find a better model using a 3-subset of the found inliers.
            sampleIdx = datasample(inlierIdx, 3, 'Replace', false);
            [templatePoints, scenePoints] = ...
                getMatchingPoints(sampleIdx, matchMatrix, f1, f2);
            try
                curTform = fitgeotrans(templatePoints, scenePoints, 'affine');
            catch
                % Ignore if collinear points
                continue;
            end
            [inlierIdx, curInlierCount, error] = findInliers(...
                inlierErrorThreshold, curTform, matchMatrix, f1, f2);
            
            % Update parameters.
            if (curInlierCount >= bestInlierCount)
                bestInlierCount = curInlierCount;
                bestInlierIdx = inlierIdx;
                bestTform = curTform;
                bestError = error;
            end
        end
        
        % Return quickly if we have already found a reasonable match.
        if (bestInlierCount > FAST_INLIER_THRESHOLD & ...
                numIterations > FAST_NUM_ITERATIONS)
            return;
        end
    end
    iter
end

function [inlierIdx, inlierCount, error] = ...
    findInliers(inlierErrorThreshold, tform, matchMatrix, f1, f2)
% Computes the inlierCount and error for passed transformation model
    inlierCount = 0;
    error = 0;
    numMatches = size(matchMatrix, 2);
    inlierIdx = zeros(numMatches, 1);
    for (idx = 1:numMatches) 
        [templatePoint, scenePoint] = ...
            getMatchingPoints(idx, matchMatrix, f1, f2);
        [tx, ty] =  transformPointsForward(tform, templatePoint(1), templatePoint(2));
        terror = pdist2([tx, ty], scenePoint, 'euclidean');
        if (terror < inlierErrorThreshold)
            inlierCount = inlierCount + 1;
            inlierIdx(idx) = 1;
        end
        error = error + terror;
    end
    inlierIdx = find(inlierIdx > 0);
end

function [templatePoints, scenePoints] = ...
    getMatchingPoints(indices, matchMatrix, f1, f2)
% Returns matching points corresponding to passed indices.
% NOTE : Each point is a row, so final outputs are n x 2 where n is no of
% indices
    templateIdx = matchMatrix(1, indices);
    sceneIdx = matchMatrix(2, indices);
    templatePoints = f1(1:2, templateIdx)';
    scenePoints = f2(1:2, sceneIdx)';
end

function output = areCollinear(points)
% Returns 1 if points are almost collinear. Expects maximum 3 points.
    % Less than 3 points are always collinear.
    if (size(points, 1) < 3)
        output = true;
        return;
    end
    % For 3 points check if det is 0.
    eps = 0.0001;
    output = abs(det([points,ones(3,1)])) < eps;
end
