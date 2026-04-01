
function avg_psi6 = calculate_voronoi_psi6_pbc(x, y, Lx, Ly)
    n_orig = length(x);
    if n_orig < 4, avg_psi6 = 0; return; end

    % --- Step 1: Create 8 Ghost Images for PBC ---
    % Shift vectors for a 3x3 tiling
    dx = [-Lx, 0, Lx];
    dy = [-Ly, 0, Ly];
    [DX, DY] = meshgrid(dx, dy);
    DX = DX(:); DY = DY(:);
    
    x_aug = []; y_aug = [];
    % Original particles will be the first 'n_orig' entries (the center tile)
    % but for Delaunay it's safer to just tile all and track indices.
    for i = 1:9
        x_aug = [x_aug; x + DX(i)];
        y_aug = [y_aug; y + DY(i)];
    end

    % --- Step 2: Delaunay Triangulation on Augmented Set ---
    tri = delaunay(x_aug, y_aug);
    
    % --- Step 3: Filter for Original Particles ---
    % We only care about the bonds belonging to particles in the central box
    % (indices 1 to n_orig).
    edges = [tri(:,[1,2]); tri(:,[2,3]); tri(:,[3,1])];
    
    % Keep edges where at least one particle is an "original" (central box)
    % This ensures edge-particles get their PBC neighbors.
    mask = (edges(:,1) <= n_orig) | (edges(:,2) <= n_orig);
    edges = edges(mask, :);
    
    % Initialize complex order parameter
    psi_i = zeros(n_orig, 1);
    nn_count = zeros(n_orig, 1);
    
    % --- Step 4: Calculate Psi6 ---
    for k = 1:size(edges, 1)
        idx1 = edges(k, 1);
        idx2 = edges(k, 2);
        
        % Calculate angle
        angle = atan2(y_aug(idx2) - y_aug(idx1), x_aug(idx2) - x_aug(idx1));
        term = exp(6i * angle);
        
        % If idx1 is original, add contribution
        if idx1 <= n_orig
            psi_i(idx1) = psi_i(idx1) + term;
            nn_count(idx1) = nn_count(idx1) + 1;
        end
        % If idx2 is original, add contribution (with flipped angle)
        if idx2 <= n_orig
            psi_i(idx2) = psi_i(idx2) + exp(6i * (angle + pi));
            nn_count(idx2) = nn_count(idx2) + 1;
        end
    end
    
    % Remove duplicate contributions (each edge processed twice for original-original)
    % and normalize.
    local_psi6 = abs(psi_i ./ (nn_count));
    avg_psi6 = mean(local_psi6, 'omitnan');
end