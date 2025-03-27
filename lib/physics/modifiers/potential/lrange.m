function [ lr ] = lrange( r, ra, rb )
% This function returns a function that is used to remove the long range
% interactions of the particles.
%
% [ lr ] = lrange( r, ra, rb )

lr = ones( size( r ) );

fltr = ( r > rb );
lr(fltr) = 0.;

tmp = ( rb - ra )^7.;
a = rb^4 * ( rb^3 - 7. * rb^2 * ra + 21. * rb * ra^2 - 35. * ra^3 );
b = 140. * rb^3 * ra^3;
c = -210. * rb^2 * ra^2 * ( rb + ra );
d = 140. * rb * ra * ( rb^2 + 3. * rb * ra + ra^2 );
e = -35. * ( rb + ra ) * ( rb^2 + 8. * rb * ra + ra^2 );
f = 84. * ( rb^2 + 3. * rb * ra + ra^2 );
g = -70. * ( rb + ra );
h = 20.;

fltr = ( r > ra & r <= rb );
lr(fltr) = ( a + b * r(fltr) + c * r(fltr).^2 + d * r(fltr).^3 + e * r(fltr).^4 + f * r(fltr).^5 + g * r(fltr).^6 + h * r(fltr).^7 ) / tmp;

end