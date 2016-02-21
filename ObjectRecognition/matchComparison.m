% ****Be sure to add vl feats to the search path: ****
% >>> run('VLFEATROOT/toolbox/vl_setup');
% where VLFEATROOT is the directory where the code was downloaded.
% See http://www.vlfeat.org/install-matlab.html
run('../../vlfeat-0.9.20/toolbox/vl_setup'); 
fprintf('Be sure to add VLFeat path.\n');

clear;
close all;

% Some flags
DISPLAY_INTERMEDIATE_RESULTS = 1;
DISPLAY_PATCHES = 0
SHOW_ALL_MATCHES_AT_ONCE = 1;

% Constants
N = 50;  % how many SIFT features to display for visualization of features
LOWE_RATIO = 0.6;
MEAN_DIST_THRESHOLD = 0.8;
INLIER_THRESHOLD = 10; % Error threshold for a point to be considered inlier
ITERATIONS = 100; % Number of iterations in RANSAC.

templatename = 'object-template.jpg';
scenenames = {'object-template-rotated.jpg', 'scene1.jpg', 'scene2.jpg'};


% Read in the object template image.  This is the thing we'll search for in
% the scene images.
im1 = im2single(rgb2gray(imread(templatename)));


% Extract SIFT features from the template image.
%
% 'f' refers to a matrix of "frames".  It is 4 x n, where n is the number
% of SIFT features detected.  Thus, each column refers to one SIFT descriptor.  
% The first row gives the x positions, second row gives the y positions, 
% third row gives the scales, fourth row gives the orientations. We will
% only need the x and y positions here.
%
% 'd' refers to a matrix of "descriptors".  It is 128 x n.  Each column 
% is a 128-dimensional SIFT descriptor.
%
% See VLFeats for more details on the contents of the frames and
% descriptors.
[f1, d1] = vl_sift(im1);

% count number of descriptors found in im1
n1 = size(d1,2);


% Loop through the scene images and do some processing
for scenenum = 1:length(scenenames)
    
    fprintf('Reading image %s for the scene to search....\n', scenenames{scenenum});
    im2 = im2single(rgb2gray(imread(scenenames{scenenum})));
    
    % Extract SIFT features from this scene image
    [f2, d2] = vl_sift(im2);
    n2 = size(d2,2);
    
    % Show a random subset of the SIFT patches for the two images
    if(DISPLAY_PATCHES)
        displayDetectedSIFTFeatures(im1, im2, f1, f2, d1, d2, N);
        fprintf('Showing a random sample of the sift descriptors.  Type dbcont to continue.\n');
        keyboard;
    end
    
    % Find the nearest neighbor descriptor in im2 for all descriptors from
    % im1
    
    % Compute the Euclidean distance between that descriptor
    % and all descriptors in im2
    % This function is an efficient implementation to compute all pairwise 
    % Euclidean distances between two sets of vectors.  See the header.    
    dists = dist2(double(d1)', double(d2)');    
    
    % Sort those distances
    [sortedDists, sortedIndices] = sort(dists, 2, 'ascend');
    
    % Take the first neighbor as a candidate match.
    % Record the match as a column in the matrix 'matchMatrix',
    % where the first row gives the index of the feature from the first
    % image, the second row gives the index of the feature matched to it in
    % the second image, and the third row records the distance between
    % them.
    matchMatrix = [[1:n1]; sortedIndices(:, 1)'; sortedDists(:, 1)'];
    numMatches = size(matchMatrix,2);
    fprintf('Number of feature matches without any eliminations %d\n',numMatches);
    if (DISPLAY_INTERMEDIATE_RESULTS)    
        fprintf('Showing initial matches.\n');
        displaySiftAndLineMatches(matchMatrix, d1, d2, f1, f2, im1, im2, ...
        SHOW_ALL_MATCHES_AT_ONCE); 
    end
    
    % Threshold nearest neighbors.
    meanDist = mean(sortedDists(:, 1));
    thresholdIndices = find(sortedDists(:, 1) <= MEAN_DIST_THRESHOLD * meanDist);
    fprintf('Number of feature matches after thresholding nearest neighbors %d\n',size(thresholdIndices, 1));
     
    if (DISPLAY_INTERMEDIATE_RESULTS)
        fprintf('Showing matches after neighbor thresholding.\n');
        displaySiftAndLineMatches(matchMatrix(:,thresholdIndices), ...
            d1, d2, f1, f2, im1, im2, SHOW_ALL_MATCHES_AT_ONCE); 
    end
    
    % Eliminate false matches using lowe's ratio test.
    loweIndices = loweElimination(LOWE_RATIO, sortedDists(:, 1:2));    
    survivedIndices = intersect(thresholdIndices, loweIndices);
    fprintf('Number of feature matches after lowe elimination %d\n',size(survivedIndices, 1));
    matchMatrix = matchMatrix(:,survivedIndices);
    
    % Display the matched patch after lowe elimination
    if (DISPLAY_INTERMEDIATE_RESULTS)    
        fprintf('Showing matches after neighbor thresholding.\n');
        displaySiftAndLineMatches(matchMatrix, d1, d2, f1, f2, ... 
            im1, im2, SHOW_ALL_MATCHES_AT_ONCE); 
    end
            
    [affineTform, inlierCount, inlierIdx, error] = ...
        ransac(INLIER_THRESHOLD, ITERATIONS, matchMatrix, f1, f2);
    matchMatrix = matchMatrix(:, inlierIdx);
    fprintf('Number of feature matches after ransac %d\n',inlierCount);
    
    % Display the matching patches after ransac.
    fprintf('Showing matches after RANSAC.\n');
    displaySiftAndLineMatches(matchMatrix, d1, d2, f1, f2, im1, im2, ...
        SHOW_ALL_MATCHES_AT_ONCE); 
        
    fprintf('scenenum=%d\n', scenenum);   
end