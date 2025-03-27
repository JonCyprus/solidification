function [ dfx  ] = nablax(f,delta)

% three point stencil gradient

dfx =  (circshift( f, [ 0, -1] ) - circshift( f, [ 0, 1]))/(2 * delta);

% Assuming p1 is your matrix with NaN values

% Check for NaN values
nanLocations = isnan(dfx);

% Replace NaN with 0
dfx(nanLocations) = 0;

end

