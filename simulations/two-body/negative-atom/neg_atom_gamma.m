% This script finds the two-body distribution function for a uniform liquid
% in two dimensions.

%%%%%%%%%%%%%%%%% Access the functions from the library and params
thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);

% This file is 3 directories deep
projectRoot = fullfile(thisDir, '..', '..', '..');

addpath(genpath(fullfile(projectRoot,'lib')));

% Load params from config dir
configDir = fullfile(projectRoot, 'config');
sharedParams = load_params(fullfile(configDir, 'shared', 'shared_params.json'));
twobodyParams = load_params(fullfile(configDir, 'two_body', 'two_body_params.json'));

% Start the fileREPL to upload files to S3 and SQL
replDir = fullfile(projectRoot, 'go-tools');
replPath = fullfile(replDir, 'fileREPL.exe');
tempDir = fullfile(projectRoot, 'temp_data');

try
    sock = tcpclient("127.0.0.1", 9000, "Timeout", 1);
    disp("REPL already running.");
catch
    disp("Starting REPL...");
    
    oldDir = cd(replDir);  % <- go to folder where the .exe is
    system('start "" fileREPL.exe --socket');  % use relative path now
    cd(oldDir);  % <- go back to where MATLAB started
    
    pause(2);
    sock = tcpclient("127.0.0.1", 9000, "Timeout", 3);
end

cleanUp = onCleanup(@() cleanup(sock));
writeline(sock, "start-run two-body");
pause(2);
runNote = 'none';
writeline(sock, runNote)

%%% Simulation parameters
kb = sharedParams.boltzmann;     %Boltzmann constant eV/K
T = sharedParams.temperature;    % temperature (K), regulates diffusion term, changes
G = sharedParams.mobility;       % overall mobility constant (in non-constant gamma)
kbT = kb * T;                    %kb .* T;  % Product of kb and T; kbT = 0.1215 eV at 1410K (From MD)

max_t = 1e-4;           % increment of time
red = 16;               % factor that reduces the set of frequencies
max_steps = 5000000;

%%% Morse Potential Paramaters: NOTE: ADD TO SEP PARAMS.JSON
D = 0.3429;             % From Paper --Add Citation Here--
alpha = 1.3588;         % From Paper --Add Citation Here--
Re = 2.866;             % Lattice Parameter from LAMMPS (Angstroms) Do a slow down at 0.75 and 1.2
Rc = 15;                % Used in LAMMPS

%%% Two dimensional parameters: NOTE: ADD TO TWO_BODY PARAMS.JSON
L = 0.5 .* 38.9823 * Re;      % length of simulation cell edge, adjusted for density 0.1362 atoms/angstrom^2 from L=40
N = 0.25 .* 1700 * 1.;        % number of particles

%%% Uniform liquid parameters NOTE: ADD TO SHARED_PARAMS.JSON
n = 2 * 4096;           % number of lattice sites in one dimension
%R = 4 * Re; %0.5 * L;            % maximum distance of interacting particles \ Was 20 when L was 40
R = 6 * Re;

%%% File parameters
scale_down = 2 .^ (3);  % Grid-scale down factor for fig4 (interp_p and surface); 0 <= exponent <= 5 for "sufficient" res
savets = 1500000;       % Time step multiple that files are saved

% Convergence study w/ reduction and wiggles
% Running 1 where slowdown is further out
% Try running the one-body code 

%%% 
L =  (38.9823 * Re)/2;       % Length of simulation cell edge %Changed to half the size removed 2 * (division by 4 from original) remove magic number it is tied to density
N =  1700/4 * 1.; 
S_density = N/(L^2); 
PdS_density = (N-1)/L^2;
 
%%% Quantities for the normalization of the distribution functions
A_circ = pi * R^2;
N_circ = PdS_density * A_circ + 1;
%S_density = N_circ / A_circ;     
%P_density = N_circ * (N_circ - 1) / A_circ^2; 
%PdS_density = (N_circ - 1) / A_circ;

%two_body = N * ( N - 1 ) / L^4;

%%% Plotting
plotting_step = 1000;

%%% Stopping Criterion Subvector
%subset_r = r(1:(0.5 * size(r)));
subset_p = 0;
subset_change = 0;
%%%%%%%%%%%%%%%%%%%%

% Quantities for the Fourier-Bessel series
% % Most efficient when ( k_max * bond length ) is around forty
z = bessel_root( 1, n )';
k = z( 2:n/red ) / R;
r = R / z(n) * z;
rdr = integrate( r );
total_mass = N_circ;

% Non-constant Gamma term
g_r = gamma_g(G, r, 0.5 * Re, 1. * Re);
%g_r = gamma_g(G, r, 0.75 * R, 0.9 * R); %0.75 * R to 0;.9 * R

%%% For scaling the magnitude of changes
%epsilon = 1e-1;
%scaling = 1./(r + epsilon);

% Vector for smooth boundary condition
smoothing = g_r; 
%smoothing = bound_smooth(r, 7 * Re, 8 * Re);
far_mass = 2 * pi * PdS_density * sum((1-smoothing) .* rdr); %changed to PdS
near_mass = total_mass - far_mass;

% Transformation matrices
j0 = sqrt( 2. ) ./ ( R * besselj( 0, z( 2:n/red ) ) ); 
j1 = sqrt( 2. ) ./ ( R * besselj( 1, z( 2:n/red ) ) );
T0 = besselj( 0, k * r' );
T1 = besselj( 1, k * r' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Code pertaining to potentials

%%% Potentials: exp-6, 10-6, Morse, hard sphere
% v_original = morse_potential(D,alpha,Re,Rc,r);

%%% Modifies the potential - should change with kbT and density
% v = plateau_a( v, r, 2. );
% v = plateau_b( v, r, 2. );
% v_original( 1:find( v_original > (25. * D), 1, 'last' ) ) = 25. * D; % -0.3429 = min(Morse) = -D
%v = cutoff( v_original, r, 15 .* Re, 16 .* Re ); %Changed from 6 to 15 and


%%% Creates the modified potential with the polynomial of given conditions
f1 = poly_solver([[0 8 0], [0 0 1], [0 -2 2]], 'r');
v = morse_modified(r, f1, 0.1 * Re, 0.75 * Re);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ dv, lv ] = taylor( v, r );
[ dg, lg ] = taylor(g_r, r);

% v__star terms by linearity
v__star = -v;
dv__star = -dv;
lv__star = -lv;

%%% Initial two-body distribution function
p__star = ones( n, 1 ) * PdS_density;
% p__star = peak( r, rdr, p__star, 0., 0.5 * Re, 1. * Re, 0.75 .* Re, 1.25 .* Re ); %Changed from 1.5 to 1.25
% lr = lrange( r, 7 * Re, 8 * Re ); % Changed from 12 and 12.5 to 17 * Re and 19 * Re

% Normalization of initial distribution
current_near_mass = 2 * pi * sum((p__star .* smoothing) .* rdr);
p__star = (p__star .* smoothing) * (near_mass/current_near_mass) + PdS_density * (1. - smoothing); %changed to PdS

%%% Reference for forward and reverse transform
% P0 = c .* ( T0 * ( p0 .* rdr ) );
% p0 = T0' * ( c .* P0 );

%%% Quantities that do not change as we iterate to a solution
% assuming g_r = g(2 | 1)

c1 = kbT * g_r;
c2 = g_r .* lv__star + dg .* dv;
c3 = g_r .* dv__star + kbT * dg;
c4 = pi/S_density;

%%% First time step visualization
fig_num = 1;
figure(fig_num);
plot( r(1:n), p__star(1:n)); % / two_body ); 
xlabel('radial distance (Angstroms)', 'FontSize', 16);
ylabel('p','FontSize',16);
title(['Probability density (p) time Evolution', 'T = ', num2str(T), ' density = ', num2str(PdS_density)]);


time = 0;
for a = 0:max_steps
    % Derivatives of the distribution function
    [ dp__star, lp__star ] = taylor( p__star, r );
    
    % Calculation of p from p__star
    p = S_density .* (S_density + PdS_density - p__star);
    [ dp, lp ] = taylor(p, r);

    % Calculation of functions h and k
    h__star = lv__star .* p__star + dv__star .* dp__star;
    h = v .* p + dv .* p;
    k__star = dg .* p__star + g_r .* dp__star;

    %P0 = j0 .* ( T0 * ( ( lr .* ( p__star - PdS_density) + PdS_density ) .* rdr ) );

    % Bessel-Fourier Calculations
    bf0_p__star = j0 .* (T0 * ( p__star .* rdr ));
    bf0_p = j0 .* (T0 * ( p__star .* rdr ));

    bf0_h__star = j0 .* (T0 * ( h__star .* rdr ));
    bf0_h = j0 .* (T0 * ( h .* rdr ));

    bf1_dvp__star = j0 .* (T1 * ( dv__star .* p__star .* rdr ));
    bf1_dv_p = j0 .* (T1 * ( dv .* p .* rdr ));
    

    % Calculates change
    first = c1 .* lp__star;
    second = c2 .* p__star;
    third = c3 .* dp__star;
    fourth = g_r .* p__star .* (T0' * ( bf0_p .* bf0_h__star + bf0_p__star .* bf0_h));
    fifth = k__star .* (T1' * (bf0_p .* bf1_dvp__star + bf0_p__star .* bf1_dv_p));

    change = 2. * G .* (first + second + third + (c4 * (fourth + fifth) ) ); 
    %change = change .* scaling;
    
    % Enforces positivity
    tmp = -p__star ./ change;
    dt = min([0.00005 * min(tmp(tmp > 0)), max_t]);
    time = time + dt;
    
    % Applies change
    p_old = p__star;
    p__star = p__star + dt * change;

    % Converve mass
    current_near_mass = 2 * pi * sum((p__star .* smoothing) .* rdr);
    p__star = (p__star .* smoothing) * (near_mass/current_near_mass) + PdS_density * (1. - smoothing);
    % p__star = (p__star .* smoothing) + S_density * (1. - smoothing);

    p_new = p__star;

    lim = n;
    
    % Saving every savets timestep
    % if mod ( a, savets ) == 0 && a ~= 0
    %     filename = sprintf('Step_%d', a);
    %     save(filename);
    % end

    % Visualization
    if mod( a, 1000) == 0
        disp(['Total Mass: ', num2str(2 * pi * sum(p__star .* rdr))]);
        disp(['Step: ', num2str(a), ' | Time-step: ', num2str(dt), ...
            ' | P_min: ', num2str(min(p__star)) , ' | max(abs(change)): ', ...
            num2str(max(abs(p_new-p_old))), ' | kbT: ', num2str(kbT), ... 
            ' | relative change: ', num2str(max(abs(p_new-p_old))/max(p_new-p_old))]);
    end
    if mod( a, plotting_step ) == 0

        fig_num = 1;
        figure(fig_num);
        plot( r(1:lim), p__star(1:lim)); % / two_body ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['Probability density (p) time Evolution', 'T = ', num2str(T), ' density = ', num2str(PdS_density)]);
        filename1 = 'fig1.jpg';
        saveas(gcf, fullfile(tempDir, filename1));
        cmd = sprintf("upload two-body Figure1 %d %s", a, filename1);
        writeline(sock, cmd)

        fig_num = 2;
        figure(fig_num), clf, hold on;
        plot( r(1:lim), first(1:lim), 'r' );
        plot( r(1:lim), second(1:lim), 'g' );
        plot( r(1:lim), third(1:lim), 'b' );
        plot( r(1: lim), fourth(1:lim), 'y');
        plot( r(1:lim), fifth(1:lim), 'c' );

        fig_num = 3;
        figure(fig_num);
        plot( r(1:lim), change(1:lim)); %/ two_body, 'k' );
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('dp/dt','FontSize',16);
        title('dp/dt time Evolution');
        filename3 = 'fig3.jpg';
        saveas(gcf, fullfile(tempDir, filename3));
        cmd = sprintf("upload two-body Figure3 %d %s", a, filename3);
        writeline(sock, cmd)

        interp_p = interp_data( L, n, R, scale_down, r, p__star, PdS_density);
        interp_surf( L, interp_p, n, a, N, scale_down, savets);

        % filename4 = fullfile('Figure 4',[ num2str(a/plotting_step), '.png']);
        % saveas(gcf,filename4);

        fig_num = 5;
        figure(fig_num);
        plot( r(1:lim), log(p__star(1:lim))); %/ two_body) ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['ln(p)',  'T = ', num2str(T), ' density = ', num2str(PdS_density)]);
        % filename5= fullfile('Figure 5', [ num2str(a/plotting_step), '.png']);
        % saveas(gcf,filename5);

        % Plot change terms for debugging.

        % fig_num = 6;
        % figure(fig_num);
        % plot( r(1:lim), fst / two_body); 
        % xlabel('radial distance (Angstroms)', 'FontSize', 16);
        % ylabel('dp/dt','FontSize',16);
        % title('First change term');
        % 
        % 
        % fig_num = 7;
        % figure(fig_num);
        % plot( r(1:lim), snd / two_body); 
        % xlabel('radial distance (Angstroms)', 'FontSize', 16);
        % ylabel('dp/dt','FontSize',16);
        % title('Second change term');
        % 
        % fig_num = 8;
        % figure(fig_num);
        % plot( r(1:lim), trd / two_body); 
        % xlabel('radial distance (Angstroms)', 'FontSize', 16);
        % ylabel('dp/dt','FontSize',16);
        % title('Third change term');
        % 
        % fig_num = 9;
        % figure(fig_num);
        % plot( r(1:lim), fourth / two_body); 
        % xlabel('radial distance (Angstroms)', 'FontSize', 16);
        % ylabel('dp/dt','FontSize',16);
        % title('Fourth change term');
        % 
        % fig_num = 10;
        % figure(fig_num);
        % plot( r(1:lim), fifth / two_body ); 
        % xlabel('radial distance (Angstroms)', 'FontSize', 16);
        % ylabel('dp/dt','FontSize',16);
        % title('Fifth change term');
    end
    
    % % Stopping criterion
    %  subset_p = p__star(1:(0.5 * size(p__star)));
    %  subset_change = change(1:(0.5 * size(change)));
    % if max( abs(subset_change))/max( subset_p ) < 0.01 && a > 15000
    %disp( max(abs(p_new - p_old) ) )
    %  try this convergence criterion
    if max( abs( p_new - p_old ) ) < 1e-9 %/ max( p ) < 0.02 % Try decreasing and see how p changes
        break; % commented so it doesn't stop for observation
    end
end

% Converged 2-D interp_p data and surface
interp_p = interp_data( L, n, R, scale_down, r, p__star, PdS_density);
interp_surf( L, interp_p, n, a, N, scale_down, savets);
filename = sprintf('Step_%d', a);
save(filename);

% Save data for use in one_body distribution program
prep_onebody;