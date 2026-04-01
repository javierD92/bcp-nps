function psi = load_psi(file,Lx,Ly)

% 1. Check if the file actually exists
if ~isfile(file)
    error('File Not Found: The file "%s" does not exist.', file);
end

% 2. Attempt to read the data
try
    data = readmatrix(file);
catch ME
    fprintf('Error reading the matrix. Check for non-numeric characters.\n');
    rethrow(ME);
end
psi = zeros(Lx,Ly);

% convert to 2D array 
for n=1:length(data(:,1))
    i = data(n,1);
    j = data(n,2);
    psi(i,j) = data(n,3);
end

end