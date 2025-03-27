function [polynomial] = poly_solver(conditions, var)
% This code is meant to solve a polynomial given sufficient boundary
% conditions. The input (currently) is a set of boundary conditions ordered
% (x, y, deriv) where x and y are the values at the respective x coordinate
% and deriv is the nth derivative of the polynomial. The code expects a
% polynomial of degree (#conditions - 1), and will signal an error if the
% output does not match this.

%{
INPUTS:

Conditions - is a vector of concatenated vectors e.g [[1 2 3], [4 5 6]].
The selectors in this code expect this input type. Representation can
be changed however since the main code works on abstract data.

var - a (to be) symbolic variable that will be used to construct the polynomial and
in differentiation. Input is a character string e.g. 'x'.
%}

% Create a symbolic list and intialize array holding equations
n = poly_cons_sel('cond_count', conditions); % n is polynomial degree
coeffs = sym('a', [1 (n+1)]);
x = sym(var);

f = sum(coeffs .* x.^(0:n));
f_and_derivs = sym(zeros(1,(n+1)));

% Fill the derivative list
for i = 0:n
    switch i
        case 0
            f_and_derivs(i + 1) = f; % Store the initial case
        otherwise
            f_and_derivs(i + 1) = diff(f_and_derivs(i), x);
    end
end

% Initialize equations array
eqs = sym(zeros(1, (n+1)));

% Loop through each boundary condition and create equations
for i = 1:(n+1)
    x_cond = poly_cons_sel('get_x', conditions, i); 
    y_cond = poly_cons_sel('get_y', conditions, i);
    n_deriv_cond = poly_cons_sel('get_deriv', conditions, i);

    general_eq_cond = f_and_derivs(n_deriv_cond + 1);
    eq_cond = eqn_at_x_y (general_eq_cond, x_cond, y_cond);

    eqs(i) = eq_cond;
end

% Solve system of equations for coefficients
solns = solve(eqs, coeffs);

% Extract coefficients from solns struct
solved_coeff = zeros(1,n+1);

for i = 1:n+1
    coeff_name = char(coeffs(i));
   solved_coeff(i) = solns.(coeff_name); 
end

% Signal error if polynomial
if solved_coeff(n+1) == 0
    error("Polynomial less than expected degree. Please check boundary conditions. POLY_SOLVER")
end

% Resubstitute into the original function for final polynomial.
polynomial = subs(f, coeffs, solved_coeff);

% Helper function for substituting into eqn
    function[subs_eqn] = eqn_at_x_y(equation, x1, y1)
        subs_eqn = y1 == subs(equation, x, x1);
    end


end

%%% Things to improve
%add error handling for improper boundary condition input or derivative
%input
%do we always assume the polynomial is num of boundary conditions - 1?

% IMPORTANT NOTE
%%% Actually fails on the easiest case for solving -x^2 +1 with conditions
%%% of (-1 0 0) (1 0 0) (0 0 1). This is actually a valid solution to the
%%% system of equations, but its not what we want. If given a system of
%%% linear equations where they all equal 0, it may very well solve
%%% for the trivial solution (all zeros) might be due to having a
%%% coefficient be 0 which may mess things up.
