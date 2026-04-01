function [t, Nc, Psi6] = domain_analysis_time(dataDir)
    % 1. Load parameters
    params = read_parameters('parameters.in');
    Lx = params.Lx;
    Ly = params.Ly;
    dt = params.dt;
    save_interval = params.save_interval;
    
    % 2. File handling
    filePattern = fullfile(dataDir, 'droplet_stats_t*.csv');
    files = dir(filePattern);
    fileNames = {files.name};
    tokens = regexp(fileNames, 'droplet_stats_t(\d+)\.csv', 'tokens');
    indices = cellfun(@(x) str2double(x{1}{1}), tokens);
    [~, sortIdx] = sort(indices);
    sortedFileNames = fileNames(sortIdx);
    
    Nframes = length(sortedFileNames);
    Psi6 = zeros(1, Nframes);
    Nc = zeros(1, Nframes);

    % 3. Main Analysis Loop
    for n = 1:Nframes
        data = readmatrix(fullfile(dataDir, sortedFileNames{n}));
        x = data(:, 3);
        y = data(:, 2);
        Nc(n) = length(x);
        
        % Calculate Psi6 with PBC Ghost Particles
        Psi6(n) = calculate_voronoi_psi6_pbc(x, y, Lx, Ly);
    end
    
    t = (1:Nframes) * dt * save_interval;
end
