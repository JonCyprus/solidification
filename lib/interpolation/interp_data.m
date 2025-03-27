function [interp_d] = interp_data(L,n_grid, int_r, scaling_factor, r, p,farfield_val)
% This function interpolates one-dimensional data and maps it to a 2-D grid
% with some factor of scale-down from original size due to computational
% cost. This uses the vector r (dist. from origin) and p or v depending on need. Values of p or v
% on the 2-D grid that are not explicitly given by 
% (r, p or v) ordered pairs in data are interpolated using linear interpolation.

%%% Description of Input Arguments:

% L = length of the simulation cell edge
% n_grid = # of gridpoints from origin to edge in 1-D (L/2)
% int_r = the max interaction dist. in terms of # Angstroms
% scaling_factor = factor to scale down box for computational efficiency
% r = vector of distance of gridpoints from origin in 1-D
% p = vector of probability densities on gridpoints

%%% Initialized parameters when Testing: (Input arguments)

% L = 40;
% n_grid = 4096;
% int_r = 20;
% scaling_factor = 2^ (2) % Change exponent to change resolution, should be <6
% r from .mat files
% p from .mat files
%farfield_val = 0.1875

%%%%%%%%%%%%%%%%%%

% Scaling grid down for quicker computation when scaling_factor !=1
scaled_n_grid = n_grid ./ scaling_factor;

% Creation of meshgrid
grid_1D = linspace( (-L/2), (L/2), (scaled_n_grid .* 2));
[X,Y] = meshgrid(grid_1D, flip(grid_1D'));

% Distance from origin for every point on grid
R = sqrt( (X.^2) + (Y.^2) );

% Interpolation of p values on grid
interp_d = ones( (scaled_n_grid .* 2) );
filter = ( R <= int_r );
interp_d(filter) = interp1( r, p, R(filter), "linear" );

% Change all values where R > 20 to farthest known p value from origin
filter = ( R > int_r); 
interp_d(filter) = farfield_val;

% % Remove the Last Row and Column for size compatability in onebodydistribution.m
% interp_d = interp_d(1:end-1, 1:end-1);

end

