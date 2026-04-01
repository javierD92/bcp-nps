function marker_list = get_markers(N)
    % GET_MATLAB_MARKERS returns a cell array of marker strings.
    % Official markers based on MATLAB Line Properties documentation.
    
    official_markers = {'o', '+', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h', '|'};
    
    total_official = length(official_markers);
    
    if nargin < 1
        % If no N is provided, return only the official set
        marker_list = official_markers;
    elseif N <= total_official
        % Return a subset of the official markers
        marker_list = official_markers(1:N);
    else
        % N is greater than the available markers. 
        % We fill the remainder by cycling through the official list.
        marker_list = official_markers;
        for i = (total_official + 1):N
            % Modulo arithmetic to cycle through the list
            idx = mod(i-1, total_official) + 1;
            marker_list{end+1} = official_markers{idx};
        end
    end
end