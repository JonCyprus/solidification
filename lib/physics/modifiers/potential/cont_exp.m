function [mod_v] = cont_exp(v, a, b,D,alpha,Re, Rc, r)
% This function transitions the morse potential at c to a less steep
% exponential function near the origin. This is to retain the properties of
% the Morse potential without such a high value and gradient near the
% origin
%  a is the desired value at the origin
% b is the where the transition occurs

% Define the equations as a function
function F = root2solve(x)
    e = x(1);
    g = x(2);
    f = x(3);
    h = x(4);

    phi = D * (exp(-2 * alpha * (b-Re)) - 2 * exp(-alpha * (b-Re)));
    dphi = 2 * D * (-alpha * exp(-2 * alpha * (b-Re)) + alpha * exp(-alpha * (b-Re)));
    d2phi = 2 * (alpha^2) * D * (2 * exp(-2 * alpha * (b-Re)) + exp(-alpha * (b-Re)));

    F(1) = e * exp(-g * b + f) + h - phi;
    F(2) = e * (-g) * exp(-g * b + f) - dphi;
    F(3) = e * g^2 * exp(-g * b + f) - d2phi;
    F(4) = e * exp(f) + h - a;
end

% Initial guesses for [e, g, f, h]
initialGuess = [1, 1, 1, 1];

% Solve the equations numerically
options = optimoptions('fsolve', 'Display', 'iter'); % Shows the iteration process
[sol, fval, exitflag, output] = fsolve(@root2solve, initialGuess, options);

% Display the solution
sol

%exp_f = coeffs[1] * exp(-coeffs[2] * r + coeffs[3]) + coeffs[4];
filter = (r <= b);
mod_v = v;
mod_v(filter) = exp_f(filter);

end

