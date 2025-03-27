function [var_vals, y_vals] = sample_sym_eqn(equation, variable, lower, upper, grid_count)
% This samples the (symbolic) equation at equidistant points x. It returns
% the variable values that it samples with as well as the function values.

var = sym(variable);
var_vals = linspace(lower, upper, grid_count);
y_vals = double(subs(equation, var, var_vals));
end

