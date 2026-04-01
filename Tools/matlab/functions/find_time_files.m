function [sortedFileNames,sortedIndices] = find_time_files(dataDir)

filePattern = fullfile(dataDir, 'field_psi_*.txt');
files = dir(filePattern);

if isempty(files)
    error('No files found in %s matching the pattern.', dataDir);
end

% 2. Extract numerical indices for proper sorting
% This prevents "field_psi_10.txt" coming before "field_psi_2.txt"
fileNames = {files.name};
indices = zeros(1, length(fileNames));

for i = 1:length(fileNames)
    % Extracts the digits between 'field_psi_' and '.txt'
    tokens = regexp(fileNames{i}, 'field_psi_(\d+)\.txt', 'tokens');
    if ~isempty(tokens)
        indices(i) = str2double(tokens{1}{1});
    end
end

% Sort indices and the file list accordingly
[sortedIndices, sortIdx] = sort(indices);
sortedFileNames = fileNames(sortIdx);

end