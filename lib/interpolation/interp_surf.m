function [] = interp_surf( L, interp_p,n_grid, s, N, scaling_factor, save_s)
% This function creates a 3-D surface representing probability density against
% distance from the origin with given vectors p (probability density) 
% and r (dist. from origin). Values of p on the 2-D grid that are not explicitly given by 
% (r, p) ordered pairs in data are interpolated using linear interpolation.

%%% Description of Input Arguments:

% L = length of the simulation cell edge
% n_grid = # of gridpoints from origin to edge in 1-D (L/2)
% int_r = the max interaction dist. in units of angstroms
% s = current time step
% N = # of atoms in simulation box
% scaling_factor = factor to scale down box for computational efficiency
% save_s = what multiple of timestep to save images on
% r = vector of distance of gridpoints from origin in 1-D
% p = vector of probability densities on gridpoints

%%% Initialized parameters when Testing: (Input arguments)

% L = 40;
% n_grid = 4096;
% int_r = 20;
% s = 220000;
% N = 1700;
% scaling_factor = 2^ (2) % Change exponent to change resolution, should be <6 
% r from .mat files
% p from .mat files

%%%%%%%%%%%%%%%%%%


% Creation of meshgrid
scaled_n_grid = n_grid ./ scaling_factor;
grid_1D = linspace( (-L/2), (L/2), (scaled_n_grid .* 2));
[X,Y] = meshgrid(grid_1D, flip(grid_1D')); 

% Surface Generation
figure(4); % 4 is chosen due to 3 prev. figures from BYG2.m
surf(X, Y, interp_p, 'EdgeAlpha',0);  %% Eventually rewrite in terms of interp_p
colorbar

% Title Labeling
total_steps = ['Total Steps: ', num2str(s), '   ']; % Step Count 
grid_dim = ['n = ', num2str( size(grid_1D,2) ), 'x', num2str( size(grid_1D,2) ), '   ']; % Grid Dimensions
particle_count = ['N = ', num2str(N)]; % Particle Count
title([total_steps, grid_dim, particle_count]); 

% Top down view while running
azimuth = 270;
elevation = 270;
view([azimuth,elevation])
axis tight

% Saving figures
if mod( s, save_s ) == 0 && s ~= 0

% Side view image saved as .jpg
azimuth = 90;
elevation = 0;
view([azimuth,elevation])
axis tight
%saveas(4, sprintf('fig4Yaxis_step-%d_res-%d.jpg', s, size(grid_1D,2) ) );   

% Top down view image saved as .jpg
azimuth = 270;
elevation = 90;
view([azimuth,elevation])
axis tight
%saveas(4, sprintf('fig4Zaxis_step-%d_res-%d.jpg', s, size(grid_1D,2) ) );      

end

end

