function chi = eulerCharacteristic2D_PBC(BW)
    BW = logical(BW);
    
    % Use circshift to find neighbors in a periodic domain
    % Edges (Horizontal and Vertical)
    E_h = BW & circshift(BW, [0, -1]);
    E_v = BW & circshift(BW, [-1, 0]);
    
    % Faces (2x2 squares)
    F = BW & circshift(BW, [0, -1]) & ...
             circshift(BW, [-1, 0]) & ...
             circshift(BW, [-1, -1]);
    
    V = sum(BW(:));
    E = sum(E_h(:)) + sum(E_v(:));
    F_count = sum(F(:));
    
    chi = V - E + F_count;
end