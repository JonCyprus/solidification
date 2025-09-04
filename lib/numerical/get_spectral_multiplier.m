function D = get_spectral_multiplier(Nx, Ny, Lx, Ly, kind)
%get_spectral_multiplier: This function finds the spectral multiplier. This
%is not meant to be generalized, but written explicitly (with redundancy)
%to make it clear which spectral multiplier is being thrown back to use as
%a multiplier after taking an FFT

% TODO: Make sure to clean this up later since kx and ky are 
% calculated the same way. Also implement function caching so wavenumber vectors
% are not constantly recomputed

% Form the wavenumber vectors and scale them (for even grid Nx/Ny)
kx = [0:(Nx/2 -1), -Nx/2:-1]' * ((2 * pi) / Lx);
ky = [0:(Ny/2 -1), -Ny/2:-1]' * ((2 * pi) / Ly);

% Form the meshgrid for wavenumber vectors 
[KX, KY] = meshgrid(kx, ky);
% [KX, KY] = ndgrid(kx, ky);

% Select operator
switch lower(kind)
    case 'dx'
        D = 1i * KX;
    case 'dy'
        D = 1i * KY;
    case 'laplacian'
        D = - (KX.^2 + KY.^2);
    otherwise
        error('Invalid operator kind: %s. Use dx, dy, or laplacian.', kind);
end

