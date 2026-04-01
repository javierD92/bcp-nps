clc; clear; close all;

% Vectors based on your Python setup
data_vec1 = [0.0 0.1 , 0.2];
data_vec2 = 2.^(5:10);

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

phip_vec = data_vec1;
L_vec = data_vec2;

% number of steps
nsteps = 10000;

markers={'o','s','d','<','>','^','v','p','h','*','x','.','+'};

for i=1:length(phip_vec)

    phip = phip_vec(i);

    time_seconds  = performance_matrix(i,:)/nsteps;
    time_ms = time_seconds * 1e3;

    p = loglog(L_vec, time_ms, '-o','DisplayName',['\phi_p=',sprintf('%1.1f',phip)]);
    p.Marker = markers{i};
    hold on
end

% add scaling 
loglog(L_vec,0.5e-4*L_vec.^2,'--k','DisplayName','\propto L^2')

ylabel(' time per iteration / ms ')
xlabel('L Lateral system size')
grid on 
legend Location southeast

exportgraphics(gcf, 'cpuTime_systemsize.png')




