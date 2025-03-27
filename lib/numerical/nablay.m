function [ dfy  ] = nablay(f,delta)
% three point stencil gradient

dfy =  (circshift( f, [ -1, 0] ) - circshift( f, [ 1, 0]))/(2 * delta);

% Assuming p1 is your matrix with NaN values

% Check for NaN values
nanLocations = isnan(dfy);

% Replace NaN with 0
dfy(nanLocations) = 0;

end

