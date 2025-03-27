function [ v ] = cutoff( v, r, ra, rb )
% This function modifies the potential v to vanish for r > rb with
% continuous third derivatives everywhere.
%
% [ v ] = cutoff( v, r, ra, rb )

ind_a = find( r > ra, 1 );
ind_b = find( r > rb, 1 );

v( ind_b:end ) = 0.;

ra = r( ind_a );
rb = r( ind_b );
va = v( ind_a );

h1 = r( ind_a - 2 ) - ra;
h2 = r( ind_a - 1 ) - ra;
h3 = r( ind_a + 1 ) - ra;
A = [ h1, h1^2 / 2., h1^3 / 6.;
      h2, h2^2 / 2., h2^3 / 6.;
      h3, h3^2 / 2., h3^3 / 6. ];
b = [ v( ind_a - 2 ) - va;
      v( ind_a - 1 ) - va;
      v( ind_a + 1 ) - va ];
x = A \ b;

rp = ( ra + rb );
rm = ( ra - rb );
tmp = 6. * rm^7;
h = ( -120. * va + rm * ( 60. * x(1) + rm * ( -12. * x(2) + x(3) * rm ) ) ) / tmp;
g = ( 420. * va * rp - rm * ( 12. * x(1) * ( 17. * ra + 18. * rb ) + rm * ( x(3) * rm * ( 3. * ra + 4. * rb ) - 3. * x(2) * ( 13. * ra + 15. * rb ) ) ) ) / tmp;
f = ( -168. * va * ( ra^2 + 3. * ra * rb + rb^2 ) + rm * ( 6. * x(1) * ( 13. * ra^2 + 42. * ra * rb + 15. * rb^2 ) + rm * ( x(3) * rm * ( ra^2 + 4 * ra * rb + 2. * rb^2 ) - 2. * x(2) * ( 7. * ra^2 + 25. * ra * rb + 10. * rb^2 ) ) ) ) * 3. / tmp;
e = ( 210. * va * rp * ( ra^2 + 8. * ra * rb + rb^2 ) + rm * ( -30. * x(1) * ( 3. * ra^3 + 30. * ra^2 * rb + 33. * ra * rb^2 + 4. * rb^3 ) + rm * ( 15. * x(2) * ( ra^3 + 11. * ra^2 * rb + 14. * ra * rb^2 + 2. * rb^3 ) - x(3) * rm * ( ra^3 + 12 * ra^2 * rb + 18. * ra * rb^2 + 4. * rb^3 ) ) ) ) / tmp;
d = -( h * 35. * rb^4 + g * 20. * rb^3 + f * 10. * rb^2 + e * 4. * rb );
c = -( h * 21. * rb^5 + g * 15. * rb^4 + f * 10. * rb^3 + e * 6. * rb^2 + d * 3. * rb );
b = -( h * 7. * rb^6 + g * 6. * rb^5 + f * 5. * rb^4 + e * 4. * rb^3 + d * 3. * rb^2 + c * 2. * rb );
a = -( h * rb^7 + g * rb^6 + f * rb^5 + e * rb^4 + d * rb^3 + c * rb^2 + b * rb );

fltr = ind_a:ind_b;
v(fltr) = a + b * r(fltr) + c * r(fltr).^2 + d * r(fltr).^3 + e * r(fltr).^4 + f * r(fltr).^5 + g * r(fltr).^6 + h * r(fltr).^7;

end
