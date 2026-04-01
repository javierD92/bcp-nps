function [t_vec, Psi6_avg, Ndroplets, Area_mean, Area_std, Area_detailed, Perimeter_mean] = droplet_analysis_time(folder, L)
    % Find and sort CSV files
    file_pattern = fullfile(folder, 'droplet_stats_t*.csv');
    files = dir(file_pattern);
    
    % Sort files numerically by time
    tokens = regexp({files.name}, 't(\d+)', 'tokens');
    times = cellfun(@(x) str2double(x{1}), tokens);
    [t_vec, idx] = sort(times);
    files = files(idx);
    
    num_files = length(files);
    Psi6_avg = zeros(num_files, 1);
    Ndroplets = zeros(num_files, 1);
    Area_mean = zeros(num_files, 1);
    Area_std = zeros(num_files, 1);
    Perimeter_mean = zeros(num_files, 1);
    
    % Use a Cell Array for variable-length data per time step
    Area_detailed = cell(num_files, 1);
    
    for f = 1:num_files
        % readmatrix starts from row 2 by default if headers are present
        data = readmatrix(fullfile(folder, files(f).name));
        if isempty(data), continue; end
        
        % Data columns: [area, centroid_y, centroid_x]
        areas = data(:, 1);
        perimeter = data(:,2);
        points = data(:, 3:4); 
        
        num_droplets = size(points, 1);
        Ndroplets(f) = num_droplets;
        
        % --- Area Analysis ---
        Area_mean(f) = mean(areas);
        Area_std(f) = std(areas);
        Perimeter_mean(f) = mean(perimeter);
        Area_detailed{f} = areas; % Store the full vector for this time step
        
        if num_droplets < 4
            Psi6_avg(f) = 0; continue;
        end
        
        % --- PBC: Create Ghost Points ---
        ghost_points = [];
        for dx = -1:1
            for dy = -1:1
                ghost_points = [ghost_points; points + [dx*L, dy*L]];
            end
        end
        
        % Delaunay Triangulation for neighbor finding
        dt = delaunayTriangulation(ghost_points);
        
        psi6_local = zeros(num_droplets, 1);
        
        % Only loop over the original droplets
        for i = 1:num_droplets
            % Find edges attached to point i
            all_edges = edges(dt);
            connected_edges = all_edges(any(all_edges == i, 2), :);
            neighbors_i = connected_edges(connected_edges ~= i);
            
            % Calculate angles to neighbors
            dx_vec = ghost_points(neighbors_i, 1) - ghost_points(i, 1);
            dy_vec = ghost_points(neighbors_i, 2) - ghost_points(i, 2);
            angles = atan2(dy_vec, dx_vec);
            
            % Hexatic Order Parameter: |mean(exp(6*i*theta))|
            psi6_local(i) = abs(mean(exp(6i * angles)));
        end
        
        Psi6_avg(f) = mean(psi6_local);
    end
end