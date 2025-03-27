% function [damping_factor] = bound_smooth(r, Re)
% % Function is intended to decrease interactions farther from the origin to
% % prevent boundary conditions from interfering.
% % The function is a 5th degree polynomial that smoothly decreases the
% % interactions from the origin to 0 starting at distance ro to r1 from the
% % origin
% % Polynomial's General Form: g(r) = a + br + cr^2 + dr^3 + er^4 + fr^5
% % Constants were calculated using r0 = 15(r_e) and r1 = 17(r_e)
% % r_e is the equilibrium bond distance, grid in BYG2.m is 20 (20 eq. bd.)
% 
% % r is the vector of distance from the origin for each gridpoint
% 
% % Bound Parameters
% r_inner = 7* Re;
% r_outer = 8 * Re;
% 
% % Calculating factor to smoothly decrease
% damping_factor = zeros(size(r));
% damping_factor(r < r_inner) = 1.0;
% 
% a =  61526528956.1007 ;
% b =  -3061122361.512875 ;
% c = 60919365.77446848 ;
% d =  -606172.8458773352 ;
% e =  3015.8101835026323 ;
% f =  -6.001612302142585 ;
% 
% filter = (r >= r_inner & r < r_outer);
% damping_factor(filter) = a + b*r(filter) + c*r(filter).^2 + d*r(filter).^3+ e*r(filter).^4 + f*r(filter).^5;

function [smoothing] = bound_smooth(r, r_start_t, r_end_t)
% This function creates a one dimensional function g(x12, y12) that depends
% on the positions of particles 1 and 2. This is to taper down
% self-interactions using the mobility. Mobility of a particle will
%  smoothly transition to full mobility from 0 starting at some distance 
% from the first particle.

% gamma is a mobility constant
% r is a vector specifying distances from the origin from each gridpoint
% r_transition: distance to start transition from full mobility

g1 = sym(1);
g2 = sym(0);

condg1 = [r_start_t 0 1];
condg2 = [r_end_t 0 1];

poly = sym_stitch_f1_f3_poly([g1, g2], {condg1 condg2});
var = symvar(poly);

smoothing = double(subs(poly, var, r));

% gamma_g = gamma * gamma_g; %derivation has these quantities separated

% Check for monotonicity
if not(all(diff(smoothing) <= 0))
    error('Polynomial is not monotonically decreasing for gamma')
end

end


