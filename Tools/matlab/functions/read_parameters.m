function params = read_parameters(filename)
    % readParams - Reads available simulation parameters from a .in file
    % Returns a struct containing only the fields found in the file.
    
    fid = fopen(filename, 'r');
    if fid == -1
        error('Could not open file: %s', filename);
    end

    % Initialize empty struct
    params = struct();

    % Helper to read next line and return numeric vector
    % Returns empty [] if EOF is reached or line is empty
    function val = getNext(f)
        line = fgetl(f);
        if ischar(line) && ~isempty(strtrim(line))
            val = sscanf(line, '%f');
        else
            val = [];
        end
    end

    try
        % Line 1: Lx, Ly
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.Lx = data(1); params.Ly = data(2);

        % Line 2: Np
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.Np = data(1);

        % Line 3: total_steps
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.total_steps = data(1);

        % Line 4: save_interval
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.save_interval = data(1);

        % Line 5: stats interval
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.stats_interval = data(1);

        % Line 6: dt
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.dt = data(1);

        % Line 7: Field Params (M, D, tau, u)
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.M = data(1); params.D = data(2); 
        params.tau = data(3); params.u = data(4);

        % Line 8: mean psi
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.mean_psi = data(1);

        % Line 9: Coupling
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.coupling = data';

        % Line 10: Reff
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.Reff = data(1);

        % Line 11: WCA
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.wca = data';

        % Line 12: temp
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.temp = data(1);

        % Line 13: Gammas
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.gammas = data';

        % Line 14: vact
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.vact = data(1);

        % Line 15: noise strength
        data = getNext(fid);
        if isempty(data), fclose(fid); return; end
        params.noise_strength = data(1);

        % Line 16: custom initial condition
        line16 = fgetl(fid);
        if ischar(line16)
            params.custom_init = contains(lower(line16), 'true');
        end

    catch ME
        fclose(fid);
        rethrow(ME);
    end
    fclose(fid);
end