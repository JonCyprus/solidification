function [v] = cont_pot(v,r,Re)
% Function smooths the morse potential, v, for BYG2.m so the first, second and third 
% derivatives of v are continuous from r_inner to r_outter
% Polynomial's General Form: g(r) = a + br + cr^2 + dr^3 + er^4 + fr^5

% v is the vector describing morse potential between atom at the origin and
% the second atom at any given distance (r)
% r = vector describing distance from origin for each gridpoint

%Bound Parameters
r_inner = 0.4 .* Re;
r_outer = 0.71 .* Re;

%Coefficients - Calculated in Python script morse_continuous
a =  302.19161869984987 ;
b =  -1000.5035190046323 ;
c = 1324.7301029649234 ;
d =  -847.8087016735883 ;
e =  261.393375241924 ;
f =  -31.20441461400925 ;
% 5th Order Polynomial Transition
filter = (r >= r_inner & r < r_outer);
v(filter) = a + b*r(filter) + c*r(filter).^2 + d*r(filter).^3 + e*r(filter).^4 + f*r(filter).^5;

end