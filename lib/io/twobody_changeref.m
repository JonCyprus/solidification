function [twobodypref] = twobody_changeref(r,p, one_body)
% This function is designed to adjust the vector p for use in the
% onebodydistribution code. The p is changed from a value of ~0 to the
% far field p value of 1. It is designed such that there is a smooth transition from r1 to r2.
% This code is intended to be used with interp_data to interpolate a 2-D grid for the onebodydistribution code.
% It is not directly called here since matlab does not allow for such
% functionality.

%i don't like this, change it to use the polynomial solver instead.
% Bound Parameters
r1 = 15;
r2 = 16;

% Calculating factor to smoothly decrease
damping_factor = zeros(size(r));
damping_factor(r < r1) = 1.0;

a =  5349375.979203873 ;
b =  -1727999.9932821721 ;
c = 223199.999132269 ;
d =  -14409.99994397773 ;
e =  464.9999981921787 ;
f =  -5.99999997667296 ;

filter = (r >= r1 & r < r2);
damping_factor(filter) = a + b*r(filter) + c*r(filter).^2 + d*r(filter).^3+ e*r(filter).^4 + f*r(filter).^5;
twobodypref = (p .* damping_factor) + one_body * (1. - damping_factor);


end

