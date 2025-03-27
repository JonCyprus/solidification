function [ p ] = peak( r, rdr, p, s, ra, rb, rc, rd )
% This function transforms the two-body distribution function to help
% convergence. The functions used have the property of vanishing first,
% second, and third derivatives at the specified boundaries to keep the
% various transforms of p sufficiently smooth.
%
% [ p ] = peak( r, rdr, p, s, ra, rb, rc, rd )

p0 = p(end);

fltr = ( r <= ra );
p(fltr) = s;

tmp = ( ra - rb )^7.;
a = ra^4 * ( ra^3 - 7. * ra^2 * rb + 21. * ra * rb^2 - 35. * rb^3 );
b = 140. * ra^3 * rb^3;
c = -210. * ra^2 * rb^2 * ( ra + rb );
d = 140. * ra * rb * ( ra^2 + 3. * ra * rb + rb^2 );
e = -35. * ( ra + rb ) * ( ra^2 + 8. * ra * rb + rb^2 );
f = 84. * ( ra^2 + 3. * ra * rb + rb^2 );
g = -70. * ( ra + rb );
h = 20.;
fltr = ( r > ra & r <= rb );
p(fltr) = s + ( p0 - s ) * ( a + b * r(fltr) + c * r(fltr).^2 + d * r(fltr).^3 + e * r(fltr).^4 + f * r(fltr).^5 + g * r(fltr).^6 + h * r(fltr).^7 ) / tmp;

tmp_a = ( rc + rd );
tmp_b = ( rc - rd )^9;
a = -1260. * rc^4 * rd^4 / tmp_a;
b = 5040. * rc^3 * rd^3;
c = -2520. * rc^2 * rd^2 * ( 3. * rc^2 + 8. * rc * rd + 3. * rd^2 ) / tmp_a;
d = 5040. * rc * rd * ( rc^2 + 5. * rc * rd + rd^2 );
e = -1260. * ( rc^4 + 16. * rc^3 * rd + 36. * rc^2 * rd^2 + 16. * rc * rd^3 + rd^4 ) / tmp_a;
f = 5040. * ( rc^2 + 5. * rc * rd + rd^2 );
g = -2520. * ( 3. * rc^2 + 8. * rc * rd + 3. * rd^2 ) / tmp_a;
h = 5040.;
k = -1260. / tmp_a;
const = sum( rdr .* ( p0 - p ) );
fltr = ( r > rc & r <= rd );
p(fltr) = p(fltr) + const * ( a + b * r(fltr) + c * r(fltr).^2 + d * r(fltr).^3 + e * r(fltr).^4 + f * r(fltr).^5 + g * r(fltr).^6 + h * r(fltr).^7 + k * r(fltr).^8 ) / tmp_b;

end