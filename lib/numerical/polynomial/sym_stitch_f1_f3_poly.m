function [stitched_f] = sym_stitch_f1_f3_poly(equations, conditions, varargin)
% This function creates a symbolic piecewise function that stitches
% together two functions with a polynomial in between. Any number of
% boundary conditions can be applied. This functions ASSUMES that the
% symbolic equations given are differentiable by the diff() operation in
% MATLAB. Also assumed that symbolic equations are of one variable. 
% Manual arguments can also be input if one wishes to avoid using
% MATLAB's diff operation in this function.

% Every condition must be specified, including the obvious ones (matching y
% values at transition point).

% Representation of conditions are assumed in terms of (x_transition,
% deriv1, ... , deriv_n) It is also assumed that the first condition in the
% CELL ARRAY of conditions corresponds to eqn in equations(1).
% The y value will be found through symbolic substitution and conditions
% created for the polynomial solver

% probably should change the varargin to allow user to give symbolic
% equations for the derivatives instead!

% Initialize equations and error check
eqn1 = equations(1);
eqn2 = equations(2);

variable = symvar(eqn2);

if isempty(variable)
    variable = ['r'];
end

%{
if ~isequal(variable, symvar(eqn2)) || length(variable) > 1
    error("Invalid symbolic equations, unequal symbols or more than 1.")
end COMMENTED FOR TESTING
%}
% Declare symbolic variable to work with.
x = sym(variable(1));

% Gather conditions for polynomial solver
poly_conditions = [];

%  REST OF CODE ASSUMES CONDITIONS ARE IN A CELL ARRAY OF SPECIFIC REPRESENTATION
cond_count1 = length(conditions{1}) - 1;
cond_count2 = length(conditions{2}) - 1;

% Get conditions from first function
x1 = get_x(conditions, 1);

for i = 1:cond_count1  
    deriv_num = get_deriv(conditions, 1, i); %SELECTOR IS LOCAL TO THIS FUNCTION ONLY

    eqn_for_y = diff(eqn1, deriv_num);
    y_val = double(subs(eqn_for_y, x, x1));

    new_cond = poly_cons_sel('create_cond', x1, y_val, deriv_num);
    poly_conditions = poly_cons_sel('combine_conditions', poly_conditions, new_cond);
end

% Get conditions for second function
x2 = get_x(conditions, 2);

for i = 1:cond_count2 
    deriv_num = get_deriv(conditions, 2, i); %SELECTOR IS LOCAL TO THIS FUNCTION ONLY

    eqn_for_y = diff(eqn2, deriv_num);
    y_val = double(subs(eqn_for_y, x, x2));

    new_cond = poly_cons_sel('create_cond', x2, y_val, deriv_num);
    poly_conditions = poly_cons_sel('combine_conditions', poly_conditions, new_cond);
end

%%% Could combine two above loops in a double for loop (do later)

% Combine possible given conditions through varargin
poly_conditions = poly_cons_sel('combine_conditions', poly_conditions, varargin{:});

% Get symbolic polynomial that transitions from f1 to f3.
poly_transition = poly_solver(poly_conditions, variable(1));

% domains based off of the x_val they are matched at

stitched_f = piecewise(x < x1, eqn1, ...
                      (x1 <= x) & (x <= x2), poly_transition, ...
                      x2 < x, eqn2);


%%% WILL ASSUME CONDITIONS IS A CELL ARRAY FOR THESE SELECTORS
    function[n_deriv] = get_deriv(conditions, eqn_num, cond_num)
        eqn_conds = conditions{eqn_num};
        n_deriv = eqn_conds(cond_num + 1);
    end

    function[x_val] = get_x(conditions, eqn_num)
        eqn_conds = conditions{eqn_num};
        x_val = eqn_conds(1);
    end

end

