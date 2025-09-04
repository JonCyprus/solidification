% One-Body Distribution Function:
%%%%% Working off of onebodyparams.mat
% Important as the 2d potential morse2D and p2_ref come from this.

%%% Access the functions from the library
thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);

% This file is 2 directories deep
projectRoot = fullfile(thisDir, '..', '..');

addpath(genpath(fullfile(projectRoot,'lib')));

%%% TODO: Add TCP Socket for file uploading/storage %%%

%%%                                           %%%

% Load params from config dir
configDir = fullfile(projectRoot, 'config');
disp(fullfile(configDir, 'shared', 'shared_params.json'));

sharedParams = load_params(fullfile(configDir, 'shared', 'shared_params.json'));
onebodyParams = load_params(fullfile(configDir, 'one_body', 'one_body_params.json'));

% Loading.mat with p__hole (p__star in other code) v functions
dataFile = fullfile(projectRoot, 'local data','converged_two_body', 'conv_hole_1300.mat'); %%% Make sure to use formatted strings and adhere to convention to make it work seamlessly btwn Temps
data = load(dataFile);

% General Parameters
kb = sharedParams.boltzmann;     % Boltzmann constant eV/K
T = sharedParams.temperature;    % temperature (K), regulates diffusion term, changes
G = sharedParams.mobility;       % Overall Mobility Constant

max_ts = 1e-6;          % Time increment
% dt = 1e-4;            % Calculated below to enforce positivity
Re = 2.866;             % Lattice parameter from LAMMPS in Angstroms
kbT = kb * T;           % kb * T;  % Product of kb and T; kbT = 0.1215 eV at 1410K (From MD)
beta = 1/kbT;
           
small = 1.e-8;
really_small = 1.e-16;

% Uniform Liquid/Cell Parameters
n = 2048;                   % Number of Grid Points
L =  (38.9823 * Re)/2;       % Length of simulation cell edge %Changed to half the size removed 2 * (division by 4 from original) remove magic number it is tied to density
delta = L/n;                % Spacing of the grid
dA = delta * delta;         % Area between grid spacings
N =  1700/4 * 1.;               % number of particles removed 4 * (division by 16 from original)
N1_A = (N-1)/L^2;
N_A = N/(L^2);         % This is 0.1362 N/Angstrom^2 (One body density)

% Initialize p_hole and v (in two dimensions from 1D)
p_hole = interp_data_spectral(L, n, data.L, 2, data.r, data.p__star); %horrible interface change it ASAP
v = interp_data_spectral(L, n, data.L, 2, data.r, data.v); %2 needs to be generalized

% Plotting parameters
total_step = 40000000;  % total number of steps
plotting_step = 200;     % Incremental step for plotting

% Initialization of x2 and y2 matrices (Real Space)
% x2 = linspace(-L/2,L/2,n+1)'* ones(1,n+1);
% x2 = x2(1:end-1, 1:end-1);
% y2 = ones(1,n+1)' * linspace (-L/2,L/2,n+1);
% y2 = y2(1:end-1, 1:end-1);
x1D = linspace(-L/2, L/2 - delta, n); %Remove last point for wrapping for spectral methods
[x2, y2] = meshgrid(x1D); 

% Get spectral differentiation operators (used as a multiplier after fft)
spectral_x = get_spectral_multiplier(n, n, L, L, 'dx');
spectral_y = get_spectral_multiplier(n, n, L, L, 'dy');
spectral_lap = get_spectral_multiplier(n, n, L, L, 'laplacian');

% Normalize the probability density matrix
%p_hole = p_hole * (N / (sum(p_hole(:)) * dA)); %break point and double check density is the same integration should end up to N atoms
p_hole = gpuArray(p_hole);

%%% Check that integrates to N-1 outside cutoff (after 1 Re) %%%
% Distance from origin
% R = sqrt(x2.^2 + y2.^2);
% outside_hole_mask = R > Re;
% 
% %Integrate and average outside the hole
% outside_integral = sum(p_hole(outside_hole_mask)) * dA;
% outside_area = sum(outside_hole_mask(:)) * dA;
% outside_density = outside_integral / outside_area;
% fprintf('Density outside hole: %.6f | N1_A: %.6f\n', outside_density, N1_A);

%%%                 %%%

% Adding perturbation to simulation box
p1 = ones(n);
p1 = p1 * N / (sum(sum(p1)) * dA);
noise = 50;
for a = 1:3
    row = randi( n - noise ) + ( 1:noise);
    col = randi( n - noise ) + ( 1:noise );
    p1(row,col) = p1( row, col ) + 0.1 * p1(1,1) * randn(noise); 
end

p2=p1;


% Plot the initial case
Plot3D(1, 1, n, kbT, N, x2, y2, p1);

% Speed up Fast Fourier Transforms
 fftw('dwisdom', []);
 fftw('planner', 'patient');
 fftinfo = fftw('dwisdom');
 fftw('dwisdom', fftinfo);

% One Body Formulation

%%% Values that do not change as we iterate

%%% Potential Gradients/Laplacian
% dv_dx = nablax(v2_12, delta);
% dv_dy = nablay(v2_12, delta);
dv_dx = real(ifft2(spectral_x .* fft2(v)));
dv_dy = real(ifft2(spectral_y .* fft2(v))); % check that these work prolly make another function to return w/o ifft

v_lap = laplacian3(v, delta);
%v_lap = real(ifft2(spectral_lap .* fft2(v)));

%%% Two-body probability Gradients
% dp_hole_dx = nablax(p_hole, delta);
% dp_hole_dy = nablay(p_hole, delta);
dp_hole_dx = real(ifft2(spectral_x .* fft2(p_hole)));
dp_hole_dy = real(ifft2(spectral_y .* fft2(p_hole)));

dp1_dx = real(ifft2(spectral_x .* fft2(p_hole)));
dp1_dy = real(ifft2(spectral_y .* fft2(p_hole)));
lap_p1 = real(ifft2(spectral_lap .* fft2(p_hole))); % Double check and make clear just initializing

v_hat = fft2(v);
v_test = ifftshift(v); %fixes it for term 2??????????? not sure why; was one accidentally corner convention?
%%% MATLAB expects corner origin convention. But p is center origin so not sure what gives
%%% Integral constants
subtract_hole = p_hole - N1_A;

% 2nd Term
second_constant = -sum(v_lap .* subtract_hole, 'all')  .* dA;
second_constant = second_constant - sum(dv_dx .* dp_hole_dx + dv_dy .* dp_hole_dy, 'all') .* dA;

% 3rd Term
third_constant = sum(dv_dx .* subtract_hole, 'all') .* dA;

% 4th Term
fourth_constant = sum(dv_dy .* subtract_hole, 'all') .* dA;

% Move to GPU for calculations

p2 = gpuArray(p2);
p1 = gpuArray(p1);
spectral_x = gpuArray(spectral_x);
spectral_y = gpuArray(spectral_y);
spectral_lap = gpuArray(spectral_lap);
second_constant = gpuArray(second_constant);
third_constant = gpuArray(third_constant);
fourth_constant = gpuArray(fourth_constant);

start = 1;
for s = start:total_step
    disp(s)
    p_hat = fft2(p1);

    %%% Derivatives for p1
    % dp1_dx = nablax(p1,delta);
    % dp1_dy = nablay(p1,delta);
    % lap_p1 = laplacian3(p1,delta);
    dp1_dx = real(ifft2(spectral_x .* p_hat));
    dp1_dy = real(ifft2(spectral_y .* p_hat));
    lap_p1 = real(ifft2(spectral_lap .* p_hat));

    % 1st Term
    first = kbT * lap_p1;

    % 2nd Term
    %second = real(ifft2(spectral_lap .* (p_hat .* v_hat)));
    %second = (second + second_constant) .* p1; % Make sure to add this back in
    second = real(ifft2(spectral_lap .* p_hat .* v_hat)); % original one
    %second = real(ifft2(spectral_lap .* fftshift(p_hat) .* fft2(v_test))); %weird background noise
    if mod(s, 20) == 0
        Plot3D(3, s, n , kbT, N, x2, y2, second);
        1;
    end
    
    % 3rd Term (x contributions)
    third = real(ifft2(spectral_x .* p_hat .* v_hat));
    if mod(s, 20) == 0
        Plot3D(4, s, n , kbT, N, x2, y2, third);
        1;
    end
    third = third - third_constant; %%% The plus may be a minus sign 
    third = third .* dp1_dx;

    % 4th Term (y contributions)
    fourth = real(ifft2(spectral_y .* p_hat .* v_hat));
    fourth = fourth - fourth_constant; %%% The plus may be a minus sign 
    fourth = fourth .* dp1_dy;

    % Total Contribution:
    change = G * (first + second + third + fourth);

    %%% Applying Change - EULER STEP
    % Enforces Positivity
    tmp = -p1 ./ change; %%% Change should be non-zero everywhere; but may want to guard for division by near 0
    dt = min(0.0005 * min(tmp(tmp > 0)), max_ts);
    %dt = max_ts;
    % Applies change
    p1 = p1 + change .* dt;
    %p2 = p1;
    

    %%% Applying Change - RK4 STEP
    % k1 = change;
    % 
    % tmp = -(p1 - small) ./ k1;
    % dt = min([1.0 * min(tmp(tmp > 0)), max_ts]);
    % 
    % p1_temp = p1 + (k1 * (dt/2));
    % k2 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);
    % 
    % p1_temp = p1 + (k2 * (dt/2));
    % k3 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);
    % 
    % p1_temp = p1 + (k3 * dt);
    % k4 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);
    % 
    % change = (1/6) * (k1 + (2 * k2) + (2 * k3) + k4);
    % 
    % disp(['Time step: ', num2str(dt)]);
    % disp(['Min value: ', num2str(min(p1(:)))])
    % p1 = p1 + change * dt;
    

    %%% I don't remember what this was for; check later
    %p1(p1 < 0.) = 0.;
    % if any(p1(:) < 0.)
    %     dt = dt / 4.;
    %     p1(p1 < 0.) = 0.;
    %     p1 = p1 * N / (sum(p1(:)) * dA);
    % else
    %     if dt < 1e-3
    %         dt = dt * 2.;
    %     end 
    % end
    
    %%% Normalization of p1
    p1 = p1 * N / (sum(sum(p1)) * dA);
    % p2 = circshift(p1,[n/2, n/2]);
    

    % Plot Data
    if mod(s, plotting_step) == 0
        Plot3D(1, s, n , kbT, N, x2, y2, p1);
        % Plotting terms for debugging
        %Plot3D(2, s, n , kbT, N, x2, y2, first);
        %Plot3D(3, s, n , kbT, N, x2, y2, second); % Problematic term
        % Plot3D(4, s, n, kbT, N, x2, y2, third);
        % Plot3D(5, s, n, kbT, N, x2, y2, fourth);
        figure(1);
        filename1= fullfile('y', [ num2str(a/plotting_step), '.png']);
        % saveas(gcf,filename1);
    end
    %%% Convert arrays to GPU arrays to greatly speed up computation
    if s == 1
        dp1_dx = gpuArray(dp1_dx);
        dp1_dy = gpuArray(dp1_dy);
        lap_p1 = gpuArray(lap_p1);
    end
end

