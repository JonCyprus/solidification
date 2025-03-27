% This content is protected and may not be shared, uploaded, or distributed.
% © Jeremy K. Mason 2020
% jkmason@ucdavis.edu

function [result] = laplacian3(order, a)
% This function calculates the Laplacian of a scalar order parameter field,
% assuming that the order parameter is sampled on a square grid, assuming
% periodic boundary conditions.
%
% This specific choice of discrete operator is given by:
% Lindeberg, T., J Math Imaging Vis, 3 (1993): 349-76
% 
% [result] = laplacian(order, a)
%
% order: the order parameter
% 
% a: the spacing of the grid
% 
% result: the result of the Laplacian operator

cardinal = circshift(order, [ 0, -1]) + circshift(order, [ 1,  0])...
         + circshift(order, [ 0,  1]) + circshift(order, [-1,  0]);
diagonal = circshift(order, [ 1, -1]) + circshift(order, [ 1,  1])...
         + circshift(order, [-1,  1]) + circshift(order, [-1, -1]);

result = 2 * (cardinal + diagonal / 4 - 5 * order) / (3 * a * a);

% Assuming p1 is your matrix with NaN values

% % Check for NaN values
% nanLocations = isnan(result);
% 
% % Replace NaN with 0
% result(nanLocations) = 0;

end