function loweIndices = loweElimination(loweRatio, sortedDists)
    sortedDists = double(sortedDists);
    numMatches = size(sortedDists,1);
    loweIndices = zeros(numMatches,1);
    for (matchIndex = 1:numMatches)
        if (sortedDists(matchIndex,1)/sortedDists(matchIndex, 2) <= loweRatio)
            loweIndices(matchIndex) = 1;
        end
    end
    loweIndices = find(loweIndices > 0);    
end