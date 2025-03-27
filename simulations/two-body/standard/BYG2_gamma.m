% This script finds the two-body distribution function for a uniform liquid
% in two dimensions.

% Adding polynomial stitching functions for the potential
addpath("Functions")

%%% Overall parameters
max_t = 1e-4;           % increment of time
kb = 8.61733262e-5;     %Boltzmann constant eV/K
T = 1200;               % temperature (K), regulates diffusion term, changes
kbT = kb * T;           %kb .* T;  % Product of kb and T; kbT = 0.1215 eV at 1410K (From MD)
G = 1.;                 % overall mobility constant (in non-constant gamma)
red = 16;               % factor that reduces the set of frequencies

max_steps = 5000000;
%%% Morse Potential Paramaters:
D = 0.3429;             %From Paper --Add Citation Here--
alpha = 1.3588;         % From Paper --Add Citation Here--
Re = 2.866;             % Lattice Parameter from LAMMPS (Angstroms)
Rc = 15;                % Used in LAMMPS

%%% Two dimensional parameters
L = 0.5 .* 38.9823 * Re;      % length of simulation cell edge, adjusted for density 0.1362 atoms/angstrom^2 from L=40
N = 0.25 .* 1700 * 1.;               % number of particles

%%% Uniform liquid parameters
n = 2 * 4096;           % number of lattice sites in one dimension
R = 0.5 * L;            % maximum distance of interacting particles \ Was 20 when L was 40

%%% File parameters
scale_down = 2 .^ (3);  % Grid-scale down factor for fig4 (interp_p and surface); 0 <= exponent <= 5 for "sufficient" res
savets = 1500000;       % Time step multiple that files are saved

%%% Quantities for the normalization of the distribution functions
A_circ = pi * R^2;
N_circ = 0.1362 * A_circ;
S_density = N_circ / A_circ;     % This is 0.1362 N/Angstrom^2
P_density = N_circ * (N_circ - 1) / A_circ^2; % is this really L^4 since we are doing radial distance?
PdS_density = (N_circ - 1) / A_circ;

%%% Plotting
plotting_step = 10000;

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
total_mass = N_circ - 1;

% Non-constant Gamma term
g_r = gamma_g(G, r, 4.5 * Re, 5.5 * Re);

%%% For scaling the magnitude of changes
%epsilon = 1e-1;
%scaling = 1./(r + epsilon);

% Vector for smooth boundary condition
smoothing = g_r; 
%smoothing = bound_smooth(r, 7 * Re, 8 * Re);
far_mass = 2 * pi * PdS_density * sum((1-smoothing) .* rdr);
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

% % Checking potential
% figure(100);
% plot(r,v);
% hold on
% plot(r, v_original, 'b-')
% plot(r, v1, 'g-')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ dv, lv ] = taylor( v, r );
[ dg, lg ] = taylor(g_r, r);

%%% Initial two-body distribution function
p = ones( n, 1 ) * PdS_density;
p = peak( r, rdr, p, 0., 0.5 * Re, 1. * Re, 0.75 .* Re, 1.25 .* Re ); %Changed from 1.5 to 1.25
lr = lrange( r, 7 * Re, 8 * Re ); % Changed from 12 and 12.5 to 17 * Re and 19 * Re

%%% Reference for forward and reverse transform
% P0 = c .* ( T0 * ( p0 .* rdr ) );
% p0 = T0' * ( c .* P0 );

%%% Quantities that do not change as we iterate to a solution

c1 = kbT * g_r;
c2 = g_r .* lv + dg .* dv;
c3 = g_r .* dv + kbT * dg;
c4 = g_r / S_density^1 .* 2 .* pi;

time = 0;
for a = 0:max_steps
    %%%Scaling Temperature down per time step amount
    % if mod( a, 10000 )==0 && (T > 1400)
    %     T = 2400 - (a / 10000) * 100;
    %     kbT = kb.*T;
    % end
    
    % CHECK IF THIS HELPS
    %p = lr .* ( p - two_body) + two_body; %%gives p_min of 0.
    [ dp, lp ] = taylor( p, r );
    P0 = j0 .* ( T0 * ( ( lr .* ( p - PdS_density) + PdS_density ) .* rdr ) );
    h = dv .* dp + lv .* p;
    
    % Calculates change
    fst = c1 .* lp ;
    snd = c2 .* p;
    trd = c3 .* dp; 
    fourth = c4 .* p .* (T0' * ( P0 .* j0 .* ( T0 * ( h .* rdr ) ) ) );
    fifth = (g_r .* dp + dg .* p) .* (1/S_density^1) .* 2 .* pi;
    fifth = fifth .* ( T1' * ( P0 .* j0 .* ( T1 * ( dv .* p .* rdr ) ) ) );
    change = 2. * G .* (fst + snd + trd + fourth + fifth); 
    %change = change .* scaling;
    
    % Enforces positivity
    tmp = -p ./ change;
    dt = min([0.5 * min(tmp(tmp > 0)), max_t]);
    time = time + dt;
    
    % Applies change
    p_old = p;
    p = p + dt * change;
    current_near_mass = 2 * pi * sum((p .* smoothing) .* rdr);

    % One of two
    p = (p .* smoothing) * (near_mass/current_near_mass) + PdS_density * (1. - smoothing);
    %p = (p .* smoothing) + PdS_density * (1. - smoothing);

    p_new = p;
    lim = n;
    
    % Saving every savets timestep
    % if mod ( a, savets ) == 0 && a ~= 0
    %     filename = sprintf('Step_%d', a);
    %     save(filename);
    % end

    % Visualization
    if mod( a, 1000) == 0
        disp(['Total Mass: ', num2str(2 * pi * sum(p .* rdr))]);
        disp(['Step: ', num2str(a), ' | Time-step: ', num2str(dt), ...
            ' | P_min: ', num2str(min(p)) , ' | max(abs(change)): ', ...
            num2str(max(abs(change))), ' | kbT: ', num2str(kbT), ... 
            ' | relative change: ', num2str(max(abs(change))/max(p))]);
    end
    if mod( a, plotting_step ) == 0

        fig_num = 1;
        figure(fig_num);
        plot( r(1:lim), p(1:lim)); % / two_body ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['Probability density (p) time Evolution', 'T = ', num2str(T), ' density = ', num2str(PdS_density)]);
        filename1= fullfile('Figure 1', [ num2str(a/plotting_step), '.png']);
        saveas(gcf,filename1);

        fig_num = 2;
        figure(fig_num), clf, hold on;
        plot( r(1:lim), fst(1:lim), 'r' );
        plot( r(1:lim), snd(1:lim), 'g' );
        plot( r(1:lim), trd(1:lim), 'b' );
        plot( r(1: lim), fourth(1:lim), 'y');
        plot( r(1:lim), fifth(1:lim), 'c' );

        fig_num = 3;
        figure(fig_num);
        plot( r(1:lim), change(1:lim)); %/ two_body, 'k' );
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('dp/dt','FontSize',16);
        filename3 = fullfile('Figure 3',[ num2str(a/plotting_step), '.png']);
        title('dp/dt time Evolution');
        saveas(gcf,filename3);

        interp_p = interp_data( L, n, R, scale_down, r, p, PdS_density);
        interp_surf( L, interp_p, n, a, N, scale_down, savets);

        filename4 = fullfile('Figure 4',[ num2str(a/plotting_step), '.png']);
        saveas(gcf,filename4);

        fig_num = 5;
        figure(fig_num);
        plot( r(1:lim), log(p(1:lim))); %/ two_body) ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['ln(p)',  'T = ', num2str(T), ' density = ', num2str(PdS_density)]);
        filename5= fullfile('Figure 5', [ num2str(a/plotting_step), '.png']);
        saveas(gcf,filename5);

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
    
    % Stopping criterion
     subset_p = p(1:(0.5 * size(p)));
     subset_change = change(1:(0.5 * size(change)));
    if max( abs(subset_change))/max( subset_p ) < 0.01 && a > 15000
    %disp( max(abs(p_new - p_old) ) )
    %if max( abs( p_new - p_old ) ) < 1e-20 && a > 60000%/ max( p ) < 0.02 % Try decreasing and see how p changes
        %break; % commented so it doesn't stop for observation
    end
end
% Normalize and calculate exchange hole
%p = p/two_body;
%exchange_hole = (p - 1) * (one_body^2);

% Converged 2-D interp_p data and surface
interp_p = interp_data( L, n, R, scale_down, r, p, PdS_density);
interp_surf( L, interp_p, n, a, N, scale_down, savets);
filename = sprintf('Step_%d', a);
save(filename);

% Save data for use in one_body distribution program
prep_onebody;