function [ v ] = plateau_a( v, r, min_v )
% This function modifies the potential v to have a vanishing first and 
% second derivative at the origin and continuous second derivative
% everywhere.
%
% [ v ] = plateau_a( v, r, min_v )

edge = find( v < min_v, 1 );
re = r( edge );
ve = v( edge );

h1 = r( edge - 1 ) - re;
h2 = r( edge + 1 ) - re;
A = [ h1, h1^2 / 2.;
      h2, h2^2 / 2. ];
b = [ v( edge - 1 ) - ve;
      v( edge + 1 ) - ve ];
x = A \ b;

e = ( x(2) * re - 2. * x(1) ) / ( 4. * re^3 );
d = ( 3. * x(1) - x(2) * re ) / ( 3. * re^2 );
a = ve + ( x(2) * re - 6. * x(1) ) * re / 12.;

v( 1:edge ) = a + d * r( 1:edge ).^3 + e * r( 1:edge ).^4;

end
