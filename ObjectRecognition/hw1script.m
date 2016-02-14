%%% Skeleton script for 395T Visual Recognition Assignment 1%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Kristen Grauman, UT-Austin
%%% Using the VLFeat library.  http://www.vlfeat.org.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ****Be sure to add vl feats to the search path: ****
% >>> run('VLFEATROOT/toolbox/vl_setup');
% where VLFEATROOT is the directory where the code was downloaded.
% See http://www.vlfeat.org/install-matlab.html
run('../../vlfeat-0.9.20/toolbox/vl_setup'); 
fprintf('Be sure to add VLFeat path.\n');

clear;
close all;


% Some flags
DISPLAY_PATCHES = 1;
SHOW_ALL_MATCHES_AT_ONCE = 1;

% Constants
N = 50;  % how many SIFT features to display for visualization of features


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
% third row gives the scales, fourth row gives the orientations.  You will
% need the x and y positions for this assignment.
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
for scenenum = 1:1%length(scenenames)
    
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
    
    
    %%% DUMMY CODE -- will be replaced with your complete matching etc.%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find the nearest neighbor descriptor in im2 for some random descriptor
    % from im1:
    
    % Extract a random descriptor (just for illustration)
    randomIndices = randperm(n1);
    aSingleSIFTDescriptor = d1(:,randomIndices(1));
    size(aSingleSIFTDescriptor)
    
    % Compute the Euclidean distance between that descriptor
    % and all descriptors in im2
    % This function is an efficient implementation to compute all pairwise Euclidean
    % distances between two sets of vectors.  See the header.
    size(d2)
    dists = dist2(double(aSingleSIFTDescriptor)', double(d2)');
    size(dists)
    
    % Sort those distances
    [sortedDists, sortedIndices] = sort(dists, 'ascend');
    
    % Take the first neighbor as a candidate match.
    % Record the match as a column in the matrix 'matchMatrix',
    % where the first row gives the index of the feature from the first
    % image, the second row gives the index of the feature matched to it in
    % the second image, and the third row records the distance between
    % them.
    matchMatrix = [randomIndices(1); sortedIndices(1); sortedDists(1)];
    
    
    % We have just one match here, but to use the display functions below, you
    % can simply expand this matrix to include one column for each match.
    numMatches = size(matchMatrix,2);
    
    
    % Display the matched patch
    clf;
    showMatchingPatches(matchMatrix, d1, d2, f1, f2, im1, im2, SHOW_ALL_MATCHES_AT_ONCE);
    fprintf('Showing an example of a nearest neighbor patch match.  Type dbcont to continue.\n');
    keyboard;
    
    
    % An alternate display - show lines connecting the matches (no patches)
    % Allows you to visualize the smoothness of the connections without
    % clutter of the patches.
    clf;
    showLinesBetweenMatches(im1, im2, f1, f2, matchMatrix);
    fprintf('Showing the matches with lines connecting.  Type dbcont to continue.\n');
    keyboard;
    fprintf('scenenum=%d\n', scenenum);
end