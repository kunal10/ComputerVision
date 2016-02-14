function displaySiftAndLineMatches(matchMatrix, d1, d2, f1, f2, ...
    im1, im2, showAllMatchesAtOnce)
    
    % Display Sift matches 
    clf;
    fprintf('Displaying SiftMatches. Type dbcont to continue\n');
    showMatchingPatches(matchMatrix, d1, d2, f1, f2, im1, im2, ...
        showAllMatchesAtOnce);    
    keyboard;    
    
    % Display line matches.
    clf;
    fprintf('Displaying LineMatches. Type dbcont to continue\n');
    showLinesBetweenMatches(im1, im2, f1, f2, matchMatrix);        
    keyboard;
end