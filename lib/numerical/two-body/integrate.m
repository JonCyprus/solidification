% Integrand r*dr for Fourier-Bessel series.
%
% r      Radial positions (r(1) == 0)
% w      Integrand (r*dr)
%
% Principle: The function f(r) is linearly interpolated 
%            between neighboring r values.
%
%            The integration interval is [0,r(end)].
%
% Marcel Leutenegger June 2006

function w = integrate( r )
w = numel(r);
switch w
case 0
   w = r;
case 1
   w = 0.5 * r * r;
case 2
   w = [ r(2)^2; 2. * r(w)^2 - r(w-1) * ( r(w) + r(w-1) ) ] / 6.;
otherwise
   r = r(:);
   w = [ r(2)^2;
         r(3:w) .* ( r(2:w-1) + r(3:w) ) - r(1:w-2) .* ( r(2:w-1) + r(1:w-2) );
         2. * r(w)^2 - r(w-1) * ( r(w) + r(w-1) ) ] / 6.;
end
