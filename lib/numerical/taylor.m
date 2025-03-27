function [ df, lf ] = taylor( f, r )
% This function calculates the centered difference approximation for the
% derivative with respect to radius in polar coordinates. The formulas
% below are based on the matrix form of the second order Taylor series
% expansion.
%
% [ df, lf ] = taylor( f, r )
%
% f: function to be differentiated
% r: values of the distance
% df: derivative of f with respect to r
% lf: laplacian of f

n = numel( r );

r = r(:);
h1 = [ r(2) - r(1); r(1:n-2) - r(2:n-1); r(n-1) - r(n) ];
h2 = [ r(3) - r(1); r(3:n)   - r(2:n-1); r(n-2) - r(n) ];
c = 1. ./ ( h1 .* h2.^2 - h2 .* h1.^2 );

f = f(:);
df1 = [ f(2) - f(1); f(1:n-2) - f(2:n-1); f(n-1) - f(n) ];
df2 = [ f(3) - f(1); f(3:n)   - f(2:n-1); f(n-2) - f(n) ];

fd = c .* ( h2.^2 .* df1 - h1.^2 .* df2 );
sd = 2. * c .* ( h1 .* df2 - h2 .* df1 );

df = fd;
lf = [ 4 * ( f(2) - f(1) ) / r(2)^2; fd(2:n) ./ r(2:n) + sd(2:n) ];

end
