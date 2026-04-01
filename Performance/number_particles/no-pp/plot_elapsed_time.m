clc; clear; close all;

% Vectors based on your Python setup
data_vec1 = logspace(log10(0.001), log10(0.3), 10);
data_vec2 = 0.0001;

% Preallocate matrix for times (Rows = Vec1, Cols = Vec2)
performance_matrix = zeros(length(data_vec1), length(data_vec2));

% Loop through the known folder structure SIM_i_j
for i = 0:length(data_vec1)-1
    for j = 0:length(data_vec2)-1
        
        % Construct the path
        folder_name = sprintf('SIM_%d_%d', i, j);
        file_path = fullfile(folder_name, 'performance.txt');
        
        if exist(file_path, 'file')
            % Read the file
            fid = fopen(file_path, 'r');
            file_content = fread(fid, '*char')';
            fclose(fid);
            
            % Extract the numeric value using a regular expression
            % This looks for the number following the colon
            val = regexp(file_content, '(?<=CPU_Time_Seconds:\s+)[0-9.]+', 'match');
            
            if ~isempty(val)
                performance_matrix(i+1, j+1) = str2double(val{1});
            end
        else
            fprintf('Warning: %s not found\n', file_path);
            performance_matrix(i+1, j+1) = NaN;
        end
    end
end

%% Plotting
% Since data_vec2 only has one value, we plot performance vs data_vec1
figure('Color', 'w');

L = 512;
Reff = 1.56;
number_particles = data_vec1 * L^2 / ( pi * Reff^2 );

loglog(number_particles, performance_matrix(:, 1), 's-', 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'r', 'Color', 'k');

%set(gca, 'XScale', 'log'); % Apply log scale for the x-axis 
grid on;
xlabel('');
ylabel('CPU Time (Seconds)');
title('Sweep Performance Analysis');

%% save to file 
dlmwrite('time-particles.dat', [ number_particles', performance_matrix] )