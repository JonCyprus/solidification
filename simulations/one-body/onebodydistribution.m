% One-Body Distribution Function:
%%%Lower system size by factor of 4
%%%Change time step or lower it for stability
%%% Use same method jeremy did for picking time step to enforce positivity
%%%%% Working off of onebodyparams.mat
% Important as the 2d potential morse2D and p2_ref come from this.

%%%%%%%%%%%%%%%%%%%%% Access the functions from the library
thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);

% This file is 3 directories deep
projectRoot = fullfile(thisDir, '..', '..', '..');

addpath(genpath(fullfile(projectRoot,'lib')));

% Load params from config dir
configDir = fullfile(projectRoot, 'config');
sharedParams = load_params(fullfile(configDir, 'shared'));
onebodyParams = load_params(fullefile(configDir, 'one_body'));

% Loading.mat with intp2_ref (p0_12) and v2_12(Morse2D) functions
load onebody_params.mat
p0_12 = conv_p_2D;
v2_12 = mod_morse2D; 

% General Parameters
max_ts = 1e-3;          % Time increment
dt = 1e-4;
Re = 2.866;             % Lattice parameter from LAMMPS in Angstroms
kb = 8.61733262e-5;     % Boltzmann constant eV/K
T = 500;               % temperature (K), regulates diffusion term, changes
kbT = kb * T;           % kb * T;  % Product of kb and T; kbT = 0.1215 eV at 1410K (From MD)
beta = 1/kbT;
G = 1.;                 % Overall Mobility Constant
small = 1.e-8;
really_small = 1.e-16;

% Uniform Liquid/Cell Parameters
n = 2048;                   % Number of Grid Points
L =  (38.9823 * Re)/2;       % Length of simulation cell edge %Changed to half the size removed 2 * (division by 4 from original)
delta = L/n;                % Spacing of the grid
dA = delta * delta;         % Area between grid spacings
N =  1700/4 * 1.;               % number of particles removed 4 * (division by 16 from original)
one_body = N/(L^2);         % This is 0.1362 N/Angstrom^2 (One body density)

% Plotting parameters
total_step = 40000000;  % total number of steps
plotting_step = 100;     % Incremental step for plotting

% Initialization of x2 and y2 matrices
x2 = linspace(-L/2,L/2,n+1)'* ones(1,n+1);
x2 = x2(1:end-1, 1:end-1);
y2 = ones(1,n+1)' * linspace (-L/2,L/2,n+1);
y2 = y2(1:end-1, 1:end-1);

% Normalize the probability density matrix
p0_12 = p0_12 * (N * (N-1) / L^2) / (sum(p0_12(:)) * dA); 



% Adding perturbation to simulation box
p1 = ones(n);
p1 = p1 * N / (sum(sum(p1)) * dA);
noise = 50;
for a = 1:3
    row = randi( n - noise ) + ( 1:noise);
    col = randi( n - noise ) + ( 1:noise );
    p1(row,col) = p1( row, col ) + 0.1 * p1(1,1) * randn(noise); 
end
p2 = circshift(p1, [n/2,n/2]);

% Plot the initial case
Plot3D(1, 1, n, kbT, N, x2, y2, p1);

% Speed up Fast Fourier Transforms
 fftw('dwisdom', []);
 fftw('planner', 'patient');
 fftinfo = fftw('dwisdom');
 fftw('dwisdom', fftinfo);

% One Body Formulation

%Circ-shifts
%v2_12 = circshift(v2_12,[n/2,n/2]);
%p0_12 = 1 + (exchange_hole)./(p1 .* p2);
%p0_12 = circshift(p0_12,[n/2,n/2]);
p0_12 = circshift(p0_12,[n/2,n/2]);

%%%%%%%%%%% Values relates to V_2 that do not change as we iterate to a solution:

% Potential Gradients/Laplacian
grad_v2_12_x = nablax(v2_12, delta);
grad_v2_12_y = nablay(v2_12, delta);

lap_v2_12 = laplacian3(v2_12, delta);

% Two-body probability Gradients
grad_p0_12_x = nablax(p0_12, delta);
grad_p0_12_y = nablay(p0_12, delta);

% Integral part 1
wx1 = grad_v2_12_x .* grad_p0_12_x;
wy1 = grad_v2_12_y .* grad_p0_12_y;
fw1 = fft2(lap_v2_12 .* p0_12 + wx1 + wy1);

% Integral part 2
wx2 = (grad_v2_12_x .* p0_12);
fwx2 = fft2( wx2 );
wy2 = (grad_v2_12_y .* p0_12);
fwy2 = fft2 ( wy2 );

% Move to GPU for calculations
conv_p_2D = gpuArray(conv_p_2D);
p2 = gpuArray(p2);

grad_p1_x = nablax(p1,delta);
grad_p1_y = nablay(p1,delta);
lap_p1 = laplacian3(p1,delta);

start = 1;
for s = start:total_step %changed start to 1000
    disp(s)
    grad_p1_x = nablax(p1,delta);
    grad_p1_y = nablay(p1,delta);
    lap_p1 = laplacian3(p1,delta);

    
    % 1st Term
    first = kbT .* lap_p1;

    % 2nd Term
    fp = fft2( p2 ); 
    int1 = real(ifft2 (fw1 .* fp));
    intx2 = real(ifft2 ( fwx2 .* fp ));
    inty2 = real(ifft2( fwy2 .* fp ));

    % Total Contribution:
    integral1 = int1 .* p1 * dA;
    integral2 = (- intx2 .* grad_p1_x - inty2 .* grad_p1_y)*dA; %Changed to minus
    second = (integral1 + integral2)./(one_body ^2);

    % Applying Change to p1 by Runge-Kutta 4 Method:
    k1 = G * (first + second); % k1

    tmp = -(p1 - small) ./ k1;
    dt = min([1.0 * min(tmp(tmp > 0)), max_ts]);

    p1_temp = p1 + (k1 * (dt/2));
    k2 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);

    p1_temp = p1 + (k2 * (dt/2));
    k3 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);

    p1_temp = p1 + (k3 * dt);
    k4 = dp1_dt_calc(p1_temp,delta, kbT, p2, fw1, fwx2, fwy2, dA, one_body, G);

    change = (1/6) * (k1 + (2 * k2) + (2 * k3) + k4);

    disp(['Time step: ', num2str(dt)]);
    disp(['Min value: ', num2str(min(p1(:)))])
    p1 = p1 + change * dt;
    
    % Update p0_12
    %p0_12 = 1 + (exchange_hole)./(p1 .* p2);
    %p0_12 = circshift(p0_12,[n/2,n/2]);
    %p0_12 = p0_12 * (N * (N-1) / L^2) / (sum(p0_12(:)) * dA);

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
    
    p1 = p1 * N / (sum(sum(p1)) * dA);
    p2 = circshift(p1,[n/2, n/2]);
     
    % if s == 1000
    %     save('onebody_1000.mat');
    % end

    % Plot Data
    if mod(s, plotting_step) == 0
        Plot3D(1, s, n , kbT, N, x2, y2, p1);
        %Plot3D(2, s, n , kbT, N, x2, y2, first);
        %Plot3D(3, s, n , kbT, N, x2, y2, second);
        figure(1);
        filename1= fullfile('y', [ num2str(a/plotting_step), '.png']);
        saveas(gcf,filename1);
    end
    if s == 1
        grad_p1_x = gpuArray(grad_p1_x);
        grad_p1_y = gpuArray(grad_p1_y);
        lap_p1 = gpuArray(lap_p1);
        fw1 = gpuArray(fw1);
        fp = gpuArray(fp);
        fwx2 = gpuArray(fwx2);
        fwy2 = gpuArray(fwy2);
    end
end

save P_1_0.1163.m p1 p2
