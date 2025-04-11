% This script finds the two-body distribution function for a uniform liquid
% in two dimensions.

%========================= IMPORTANT========================
% This mainly serves as a backup script for how we were doing things
% previously before using Git VC. This one does NOT use the dynamic
% slowdown method
%===========================================================

% Adding polynomial stitching functions for the potential
addpath("Functions")

%%% Overall parameters
max_t = 1e-3;           % increment of time
kb = 8.61733262e-5;     %Boltzmann constant eV/K
T = 1100;               % temperature (K), regulates diffusion term, changes
kbT = kb * T;           %kb .* T;  % Product of kb and T; kbT = 0.1215 eV at 1410K (From MD)
G = 1.;                 % overall mobility constant
red = 16;               % factor that reduces the set of frequencies

%%% Morse Potential Paramaters:
D = 0.3429;             %From Paper --Add Citation Here--
alpha = 1.3588;         % From Paper --Add Citation Here--
Re = 2.866;             % Lattice Parameter from LAMMPS (Angstroms)
Rc = 15;                % Used in LAMMPS

%%% Two dimensional parameters
L = 2 * 38.9823 * Re;      % length of simulation cell edge, adjusted for density 0.1362 atoms/angstrom^2 from L=40
N = 4 * 1700 * (1) ;               % number of particles

%%% Uniform liquid parameters
n = 2 * 4096;           % number of lattice sites in one dimension
R = 0.5 * L;            % maximum distance of interacting particles \ Was 20 when L was 40

%%% File parameters
scale_down = 2 .^ (3);  % Grid-scale down factor for fig4 (interp_p and surface); 0 <= exponent <= 5 for "sufficient" res
savets = 20000;       % Time step multiple that files are saved

%%% Quantities for the normalization of the distribution functions
one_body = N / L^2;     % This is 0.1362 N/Angstrom^2
two_body = N * ( N - 1 ) / L^4;



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
total_mass = 2 * pi * two_body * sum(rdr);

%%% For scaling the magnitude of changes
%epsilon = 1e-1;
%scaling = 1./(r + epsilon);

% Vector for smooth boundary condition
smoothing = bound_smooth(r, Re * 100, Re * 101);
far_mass = 2 * pi * two_body * sum((1-smoothing) .* rdr);
near_mass = total_mass - far_mass;

% Transformation matrices
c = sqrt( 2. ) ./ ( R * besselj( 0, z( 2:n/red ) ) ); 
j1 = sqrt( 2. ) ./ ( R * besselj( 1, z( 2:n/red ) ) );
T0 = besselj( 0, k * r' );
T1 = besselj( 1, k * r' );

%%% Potentials: exp-6, 10-6, Morse, hard sphere
% v = 1. / ( 1. - 6. / 12. ) * ( ( 6. / 12. ) * exp( 12. * ( 1 - r / 1. ) ) - ( 1. ./ r ).^6 );
%v_old = 1. / ( 10. - 6. ) * ( 6. * ( 1. ./ r ).^10 - 10. * ( 1. ./ r ).^6 );
% v = ( 1. - exp( -2.4 * ( r - 1 ) ) ).^2 - 1.;
% v = 15. * ( tanh( 15. * ( 1. -  r ) ) + 1. );
v_original = morse_potential(D,alpha,Re,Rc,r);

%%% Modifies the potential - should change with kbT and density
% v = plateau_a( v, r, 2. );
% v = plateau_b( v, r, 2. );
% v_original( 1:find( v_original > (25. * D), 1, 'last' ) ) = 25. * D; % -0.3429 = min(Morse) = -D
v = cutoff( v_original, r, 15 .* Re, 16 .* Re ); %Changed from 6 to 15 and 6.5 to 16
%v = cont_pot(v, r, Re);
%v = cont_linear(v, 0.75*Re, D, alpha, Re, r);
%v = cont_exp(v,10,0.71 * Re, D, alpha, Re, Rc, r);
v = cont_parabola(v, 0.75 * Re, D, alpha, Re, r);

%v = v_original; % Testing original potential instead of modified one.
[ dv, lv ] = taylor( v, r );

%%% Initial two-body distribution function
p = ones( n, 1 ) * two_body;
p = peak( r, rdr, p, 0., 0.5 * Re, 1. * Re, 0.75 .* Re, 1.25 .* Re ); %Changed from 1.5 to 1.25
lr = lrange( r, 100, 101 ); % Changed from 12 and 12.5 to 17 * Re and 19 * Re

%%% Reference for forward and reverse transform
% P0 = c .* ( T0 * ( p0 .* rdr ) );
% p0 = T0' * ( c .* P0 );

% % Move to GPU arrays for faster computing
% v = gpuArray(v);
% p = gpuArray(p);
% lr = gpuArray(lr);
% dv = gpuArray(dv);
% lv = gpuArray(lv);
% T1 = gpuArray(T1);
% T0 = gpuArray(T0);
% c = gpuArray(c);
% r = gpuArray(r);
% k = gpuArray(k);
% z = gpuArray(z);

time = 0;
for a = 0:3000000
    %%%Scaling Temperature down per time step amount
    % if mod( a, 10000 )==0 && (T > 1400)
    %     T = 2400 - (a / 10000) * 100;
    %     kbT = kb.*T;
    % end

    % CHECK WHETHER THIS HELPS
    %p = lr .* ( p - two_body) + two_body %%breaks code and gives NaN
    [ dp, lp ] = taylor( p, r );
    P0 = c .* ( T0 * ( p .* rdr ) );
    
    % Calculates change
    fst = kbT * lp;
    snd = dv .* dp + lv .* p;
    trd = p .* ( T0' * ( P0 .* c .* ( T0 * ( snd .* rdr ) ) ) );
    fth = dp .* ( T1' * ( P0 .* c .* ( T1 * ( dv .* p .* rdr ) ) ) );
    change = 2. * G * (fst + snd + 2. * pi * (trd + fth) / one_body^3);
    %change = change .* scaling;
    
    % Enforces positivity
    tmp = -p ./ change;
    dt = min([0.5 * min(tmp(tmp > 0)), max_t]);
    time = time + dt;
    
    % Applies change
    p = p + dt * change;
    %current_near_mass = 2 * pi * sum((p .* smoothing) .* rdr);
    %p = (p .* smoothing) * (near_mass/current_near_mass) + two_body * (1. - smoothing);
    p = (p .* smoothing) + two_body * (1. - smoothing);
    lim = n;
    
    % Saving every savets timestep
    if mod ( a, savets ) == 0 && a ~= 0
        %filename = sprintf('Step_%d', a);
        %save(filename);
    end

    % Visualization
    if mod( a, 1000 ) == 0
        disp(['Total Mass: ', num2str(2 * pi * sum(p .* rdr))]);
        disp(['Step: ', num2str(a), ' | Time-step: ', num2str(dt), ' | P_min: ', num2str(min(p)) , ' | max(abs(change)): ', num2str(max(abs(change))), ' | kbT: ', num2str(kbT), ' | relative change: ', num2str(max( abs(subset_change))/max( subset_p ))]);

        figure(1);
        plot( r(1:lim), p(1:lim) / two_body ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['Probability density (p) time Evolution', 'T = ', num2str(T), ' density = ', num2str(two_body)]);
        filename1= fullfile('Figure 1', [ num2str(a/1000), '.png']);
        saveas(gcf,filename1);

        figure(2), clf, hold on;
        plot( r(1:lim), fst(1:lim), 'r' );
        plot( r(1:lim), snd(1:lim), 'g' );
        plot( r(1:lim), trd(1:lim), 'b' );
        plot( r(1:lim), fth(1:lim), 'c' );

        figure(3);
        plot( r(1:lim), change(1:lim) / two_body, 'k' );
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('dp/dt','FontSize',16);
        filename3 = fullfile('Figure 3',[ num2str(a/1000), '.png']);
        title('dp/dt time Evolution');
        saveas(gcf,filename3);

        interp_p = interp_data( L, n, R, scale_down, r, p, two_body);
        interp_surf( L, interp_p, n, a, N, scale_down, savets);

        filename4 = fullfile('Figure 4',[ num2str(a/1000), '.png']);
        saveas(gcf,filename4);

        figure(5);
        plot( r(1:lim), log(p(1:lim) / two_body) ); 
        xlabel('radial distance (Angstroms)', 'FontSize', 16);
        ylabel('p','FontSize',16);
        title(['ln(p)',  'T = ', num2str(T), ' density = ', num2str(two_body)]);
        filename5= fullfile('Figure 5', [ num2str(a/1000), '.png']);
        saveas(gcf,filename5);
    end
    
    % Stopping criterion
    subset_p = p(1:(0.5 * size(p)));
    subset_change = change(1:(0.5 * size(change)));
    if max( abs(subset_change))/max( subset_p ) < 0.06 && a > 15000
    %if max( abs( change ) ) / max( p ) < 0.01 % Try decreasing and see how p changes
        break;
    end
end
% Normalize and calculate exchange hole
%p = p/two_body;
%exchange_hole = (p - 1) * (one_body^2);

% Converged 2-D interp_p data and surface
interp_p = interp_data( L, n, R, scale_down, r, p, two_body);
interp_surf( L, interp_p, n, a, N, scale_down, savets);
filename = sprintf('Step_%d', a);
save(filename);

% Save data for use in one_body distribution program
prep_onebody;