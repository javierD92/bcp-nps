function calculate_Sq_folder(folder)
    % 1. Read parameters to get physical dimensions
    param_file = fullfile(folder, 'parameters.in');
    if ~isfile(param_file)
        warning('Parameters file not found in %s. Skipping.', folder);
        return;
    end
    params = read_parameters(param_file);
    Lx = params.Lx;
    Ly = params.Ly;

    % 2. Find all psi field files
    files = dir(fullfile(folder, 'field_psi_*.txt'));
    if isempty(files)
        fprintf('No psi files found in %s\n', folder);
        return;
    end

    for f = 1:length(files)
        file_path = fullfile(folder, files(f).name);
        
        % 3. Load psi using your custom loader
        % Note: Assumes indices in load_psi are 1-based or handled correctly
        psi = load_psi(file_path, Lx, Ly);

        psi = psi - mean(psi,'all');
        
        % 4. Compute 2D FFT
        % Subtract mean to remove the q=0 (DC) peak
        psi_prime = psi - mean(psi(:));
        psi_hat = fftshift(fft2(psi_prime));
        
        % Power Spectrum (S2D)
        % Normalization: (1/N) * |FFT|^2
        Sq_2D = (abs(psi_hat).^2) / (Lx * Ly);
        
        % 5. Generate Physical q-coordinates
        % Physical spacing in Fourier space: dk = 2*pi / L
        dkx = 2*pi / Lx;
        dky = 2*pi / Ly;
        
        qx_vec = (-(Lx/2):(Lx/2-1)) * dkx;
        qy_vec = (-(Ly/2):(Ly/2-1)) * dky;
        [qx, qy] = meshgrid(qx_vec, qy_vec);
        q_mag = sqrt(qx.^2 + qy.^2);
        
        % 6. Circular Averaging
        % Maximum q to consider is the Nyquist frequency of the smaller dimension
        q_max_limit = pi; % Assuming unit pixel spacing in real space
        dq = max(dkx, dky);
        q_bins = 0:dq:q_max_limit;
        Sq_1D = zeros(size(q_bins));
        
        

        for i = 1:length(q_bins)-1
            % Create mask for the radial shell
            mask = (q_mag >= q_bins(i)) & (q_mag < q_bins(i+1));
            if any(mask(:))
                Sq_1D(i) = mean(Sq_2D(mask));
            end
        end
        
        % 7. Save results
        % Extract time step index using regex
        time_tokens = regexp(files(f).name, 'field_psi_(\d+)', 'tokens');
        if ~isempty(time_tokens)
            time_val = time_tokens{1}{1};
        else
            time_val = num2str(f); % Fallback
        end
        
        out_name = fullfile(folder, sprintf('Sq_%s.dat', time_val));
        
        % Save as [q, S(q)]
        output_data = [q_bins', Sq_1D'];
        save(out_name, 'output_data', '-ascii');
    end
end