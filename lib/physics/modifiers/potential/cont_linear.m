function [mod_v] = cont_linear(v, c,D,alpha,Re,r)
% This function modifies the morse potential to be continuous at c giving a
% linear line from the potential at c to the origin
% v is the potential to be modified
% c is whre the line connects

m = 2 * D * (-alpha * exp(-2*alpha*(c-Re)) + alpha * exp(-alpha * (c-Re)) );
b = (D .* (exp(-2 .* alpha .* (c-Re))- 2 .* exp(-alpha .* (c-Re))))-(m * c);
y = m * r + b;
filter = (r <= c);
mod_v = v;
mod_v(filter) = y(filter);

end

