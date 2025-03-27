function [] = sym_eqn_grapher(equation, var, lower, upper, grid_count, fig_num)
% Graphs a symbolic equation that is in terms of var. Lower and upper
% bounds of graphing are specified as well as how many points the
% polynomial is sampled at. Specifying figure number with 
% fig_num is optional, if not specified it will add a figure itself

% Check if fig_num is provided, otherwise create a new figure
if nargin < 6
    figure();
else
    figure(fig_num);
end

% Sample y values from the given symbolic equation
x = sym(var);
x_vals = linspace(lower, upper, grid_count);
y_vals = double(subs(equation, x, x_vals));

% Conversion of symbolic equation to string for title label
eqn_string = char(equation);

% Plot the polynomial
plot(x_vals, y_vals, 'b-', 'LineWidth', 2); % Plot with blue line of width 2
xlabel('x'); % Label x-axis
ylabel('y'); % Label y-axis
title('Graph of: ', eqn_string); % Title of the graph
grid on; % Add a grid

end

