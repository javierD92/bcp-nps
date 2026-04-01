function FigureFormat(ax)
    % APSSTYLE - Formats MATLAB plots to match APS publication quality.
    %
    % Parameters:
    % ax - Handle to the axes (use gca to get the current axes)
    
    % Set font and tick properties
    ax.FontName = 'Times New Roman';
    ax.FontSize = 14;
    ax.TickLabelInterpreter = 'latex';
    ax.XMinorTick = 'on';
    ax.YMinorTick = 'on';
    ax.LineWidth = 1.2;
    
    % Preserve existing axis labels while formatting
    ax.XLabel.FontSize = 16;
    ax.YLabel.FontSize = 16;
    
    % Title formatting
    ax.Title.Interpreter = 'latex';
    ax.Title.FontSize = 16;
    
    % Legend settings (if legend exists)
    leg = findobj(gcf, 'Type', 'Legend');
    if ~isempty(leg)
        leg.Interpreter = 'latex';
        leg.FontSize = 14;
        leg.Box = 'off'; % APS prefers no box around the legend
    end
    
    % Grid settings
    % ax.XGrid = 'on';
    % ax.YGrid = 'on';
    % ax.GridLineStyle = ':';
    % ax.GridAlpha = 0.3; % Light transparency for grid
    
    % Marker and line properties
    lines = findobj(ax, 'Type', 'Line');
    for i = 1:length(lines)
        lines(i).LineWidth = 1.5;
        lines(i).MarkerSize = 8;
        lines(i).MarkerFaceColor = lines(i).Color; % Filled markers
    end
    
    % Figure background color
    set(gcf, 'Color', 'w');
    
    % Set the figure size for APS publication (in inches)
    width = 3.5;  % Single-column width
    height = 2.625; % Aspect ratio ~ 4:3
    set(gcf, 'Units', 'inches', 'Position', [1, 1, width, height]);
    
    % Set box on for better appearance
    box on;
    
    % Tight layout to remove excessive whitespace
    set(gca, 'LooseInset', max(get(gca, 'TightInset'), 0.02));
end