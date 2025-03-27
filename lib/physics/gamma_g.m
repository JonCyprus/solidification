function [gamma_g] = gamma_g(gamma, r, r_start_t, r_end_t)
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

condg1 = [r_start_t 0 1 2];
condg2 = [r_end_t 0 1 2];

poly = sym_stitch_f1_f3_poly([g1, g2], {condg1 condg2});
var = symvar(poly);

gamma_g = double(subs(poly, var, r));

% gamma_g = gamma * gamma_g; %derivation has these quantities separated

% Check for monotonicity
if not(all(diff(gamma_g) <= 0))
    error('Polynomial is not monotonically decreasing for gamma')
end

end

