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
dataFile = fullfile(projectRoot, 'local data','converged_two_body', 'conv_hole_1300_new.mat'); %%% Make sure to use formatted strings and adhere to convention to make it work seamlessly btwn Temps
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

% Initialization of x and y matrices (Real Space)
x1D = linspace(-L/2, L/2 - delta, n); %Remove last point for wrapping for spectral methods
[X, Y] = meshgrid(x1D); 

% Get spectral differentiation operators (used as a multiplier after fft)
spectral_x = get_spectral_multiplier(n, n, L, L, 'dx');
spectral_y = get_spectral_multiplier(n, n, L, L, 'dy');
spectral_lap = get_spectral_multiplier(n, n, L, L, 'laplacian');

% Normalize the probability density matrix
%p_hole = p_hole * (N / (sum(p_hole(:)) * dA)); %break point and double check density is the same integration should end up to N atoms
p_hole = gpuArray(p_hole);

% Initialize p1
p1 = ones(n);
p1 = p1 * N / (sum(sum(p1)) * dA);

%%% Add perturbation to simulation box
% Add Gaussian noise (Avoids derivative artifacts)
noise_count = 3;
sigma_range = [5 * delta, 10 * delta]; %[minSigma, maxSigma]
amplitude_range = [-0.01 * p1(1), 0.01 * p1(1)]; %[minAmp, maxAmp]

p1 = create_noise(noise_count, sigma_range, amplitude_range ,L, p1);
p2=p1;


% Plot the initial case
%Plot3D(1, x2, y2, p1);
tiledlayout(5,2, 'Padding','compact', 'TileSpacing','compact');
nexttile(1);
Plot3D(gca, X, Y, p1);
title(['Total steps = 0','   n =', num2str(n),'   KbT = ', num2str(kbT),'   N=',num2str(N)]);

% Speed up Fast Fourier Transforms
 fftw('dwisdom', []);
 fftw('planner', 'patient');
 fftinfo = fftw('dwisdom');
 fftw('dwisdom', fftinfo);

% One Body Formulation

%%% Values that do not change as we iterate

%%% Potential Gradients/Laplacian
% dv_dx = nablax(v, delta);
% dv_dy = nablay(v, delta);
dv_dx = real(ifft2(spectral_x .* fft2(v)));
dv_dy = real(ifft2(spectral_y .* fft2(v))); 


%v_lap = laplacian3(v, delta);
v_lap = real(ifft2(spectral_lap .* fft2(v)));

%%% Two-body probability Gradients
% dp_hole_dx = nablax(p_hole, delta);
% dp_hole_dy = nablay(p_hole, delta);
dp_hole_dx = real(ifft2(spectral_x .* fft2(p_hole)));
dp_hole_dy = real(ifft2(spectral_y .* fft2(p_hole)));

dp1_dx = real(ifft2(spectral_x .* fft2(p1)));
dp1_dy = real(ifft2(spectral_y .* fft2(p1)));
lap_p1 = real(ifft2(spectral_lap .* fft2(p1))); 

%v_hat = fft2(v); %original w/o fftshift
v_hat = fft2(circshift(v, [n/2, n/2])); %fixes it for terms not sure why;

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

% Evolve the system via loop
start = 1;
total_time = 0;
for s = start:total_step
    p_hat = fft2(p1);

    %%% Derivatives for p1
    % dp1_dx = nablax(p1,delta);
    % dp1_dy = nablay(p1,delta);
    % lap_p1 = laplacian3(p1,delta);
    dp1_dx = real(ifft2(spectral_x .* p_hat));
    dp1_dy = real(ifft2(spectral_y .* p_hat));
    lap_p1 = real(ifft2(spectral_lap .* p_hat));

    %%% 1st Term %%%
    first = kbT * lap_p1;
    % Plotting First Term
    if mod(s, plotting_step) == 0
        nexttile(2);
        Plot3D(gca, X, Y, first);
        gcf();
        title("First Term");
        1;
    end
    
    %%% 2nd Term %%%
    second = real(ifft2(spectral_lap .* p_hat .* v_hat)); 
    % Plotting 2nd term before offset
    if mod(s, plotting_step) == 0
        nexttile(3);
        Plot3D(gca, X, Y, second);
        gcf();
        title("Second Term Before Constant");
        1;
    end

    second = (second + second_constant) .* p1;

    % Plotting after offset and multiplication
    if mod(s, plotting_step) == 0
        nexttile(4);
        Plot3D(gca, X, Y, second);
        gcf();
        title("Second Term");
        1;
    end
    
    %%% 3rd Term (x contributions) %%%
    third = real(ifft2(spectral_x .* p_hat .* v_hat));

    %Plotting before offset
    if mod(s, plotting_step) == 0
        nexttile(5);
        Plot3D(gca, X, Y, third);
        gcf();
        title("Third Term Before Constant");
        1;
    end

    third = third - third_constant; %%% The minus may be plus (should be minus)
    third = third .* dp1_dx;

    %Plotting after offset and multiplication
    if mod(s, plotting_step) == 0
        nexttile(6);
        Plot3D(gca, X, Y, third);
        gcf();
        title("Third Term");
        1;
    end

    %%% 4th Term (y contributions) %%%
    fourth = real(ifft2(spectral_y .* p_hat .* v_hat));

    % Plotting before offset
    if mod(s, plotting_step) == 0
        nexttile(7);
        Plot3D(gca, X, Y, fourth);
        gcf();
        title("Fourth Term Before Constant");
        1;
    end

    fourth = fourth - fourth_constant; %%% The minus may be plus (should be minus)
    fourth = fourth .* dp1_dy;

    % Plotting after offset and multiplication
    if mod(s, plotting_step) == 0
        nexttile(8);
        Plot3D(gca, X, Y, fourth);
        gcf();
        title("Fourth Term");
        1;
    end

    % Total Contribution:
    change = G * (first + second + third + fourth);

    if mod(s, plotting_step) == 0
        nexttile(9);
        Plot3D(gca, X, Y, change);
        gcf();
        title("Total Change");
        1;
    end
    %%% Applying Change - EULER STEP
    % Enforces Positivity
    tmp = -p1 ./ change; %%% Change should be non-zero everywhere; but may want to guard for division by near 0
    dt = min(0.5 * min(tmp(tmp > 0)), max_ts);
    %dt = max_ts;
    % Applies change
    p1 = p1 + change .* dt;
    %p2 = p1;
    total_time = total_time + dt;

    %%% Normalization of p1
    p1 = p1 * N / (sum(sum(p1)) * dA);
    % p2 = circshift(p1,[n/2, n/2]);
    
    disp([num2str(s), ' ', num2str(total_time), ' ', num2str(max(max(p1)))]);
    % Plot Data
    if mod(s, plotting_step) == 0
        nexttile(1);
        Plot3D(gca, X, Y, p1);
        title(['Total steps = ' num2str(s),'   n =', num2str(n),'   KbT = ', num2str(kbT),'   N=',num2str(N)]);
        %figure(1);
        %filename1= fullfile('y', [ num2str(a/plotting_step), '.png']);
        % saveas(gcf,filename1);
    end
    %%% Convert arrays to GPU arrays to greatly speed up computation
    if s == 1
        dp1_dx = gpuArray(dp1_dx);
        dp1_dy = gpuArray(dp1_dy);
        lap_p1 = gpuArray(lap_p1);
    end
end

