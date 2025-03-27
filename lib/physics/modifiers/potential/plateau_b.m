function [ v ] = plateau_b( v, r, min_v )
% This function modifies the potential v to have a vanishing first, second
% and third derivatives at the origin and continuous third derivative
% everywhere.
%
% [ v ] = plateau_b( v, r, min_v )

edge = find( v < min_v, 1 );
re = r( edge );
ve = v( edge );

h1 = r( edge - 1 ) - re;
h2 = r( edge + 1 ) - re;
h3 = r( edge + 2 ) - re;
A = [ h1, h1^2 / 2., h1^3 / 6.;
      h2, h2^2 / 2., h2^3 / 6.;
      h3, h3^2 / 2., h3^3 / 6. ];
b = [ v( edge - 1 ) - ve;
      v( edge + 1 ) - ve;
      v( edge + 2 ) - ve ];
x = A \ b;

g = ( 12. * x(1) - 6. * x(2) * re + x(3) * re^2 ) / ( 12. * re^5 );
f = -( 15. * x(1) - 7. * x(2) * re + x(3) * re^2 ) / ( 5. * re^4 );
e = ( 20. * x(1) - 8. * x(2) * re + x(3) * re^2 ) / ( 8. * re^3 );
a = ve - ( 60. * x(1) + re * ( x(3) * re - 12. * x(2) ) ) * re / 120.;

v( 1:edge ) = a + e * r( 1:edge ).^4 + f * r( 1:edge ).^5 + g * r( 1:edge ).^6;

end
