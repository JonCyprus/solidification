function [mod_v] = cont_parabola(v, T,D,alpha,Re, r)
% This function transitions the morse potential at c parabolic function
% near the origin. This is to retain the properties of
% the Morse potential without such a high value and gradient near the
% origin
% T is the where the transition occurs

% Define the equations as a function


phi = D * (exp(-2 * alpha * (T-Re)) - 2 * exp(-alpha * (T-Re)));
dphi = 2 * D * (-alpha * exp(-2 * alpha * (T-Re)) + alpha * exp(-alpha * (T-Re)));
d2phi = 2 * (alpha^2) * D * (2 * exp(-2 * alpha * (T-Re)) + exp(-alpha * (T-Re)));

b = 0; %vertex at origin
a = dphi/(2 * T);
b = 0;
c = phi - a*T^2;

parabola = a*(r.^2) + b * r + c;
filter = (r <= T);
mod_v = v;
mod_v(filter) = parabola(filter);

end

