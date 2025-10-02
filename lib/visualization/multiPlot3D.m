function [] = multiPlot3D(dir, varargin)
%MULTIPLOT3D Plots multiple subplots on same plot
% dir - 'horizontal', 'vertical' direction of subplot (defaults to horizontal)
% Expects data tuples with cells; {x, y, z}


% Check if first argument is actually a direction if not put it into
% varargin and default to horizontal
if ~(ischar(dir) || isstring(dir))
    varargin = [{dir} varargin];
    dir = 'horizontal';
end

% Calculate dimenions for rectangle based on input args
N = numel(varargin);
dim1 = floor(sqrt(N));
dim2 = ceil(N/dim1);

switch dir
    case 'horizontal'
        rows = min(dim1, dim2);
        cols = max(dim1, dim2);
    case 'vertical'
        rows = max(dim1, dim2);
        cols = min(dim1, dim2);
end

for k = 1:N
    data = varargin{k};
    x = data{1};
    y = data{2};
    z = data{3};
    Plot3D(subplot(rows, cols, k), x, y, z);
end

