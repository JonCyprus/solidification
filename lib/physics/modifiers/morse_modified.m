function [morse_pot] = morse_modified(r, f, trans_f, trans_morse)
% This function returns an the morse potential at every point r, given a
% vector r (distances from origin). More specifically, this is a modified
% morse potential, so that the potential at the origin does not diverge.
% There will be continuous 1st and 2nd derivatives when transitioning to
% the morse potential and from the first polynomial.

% f is the symbolic equation of a polynomial to be used at the origin.
% expected symbolic variable of r.
% trans_f is the r value where f transitions to the middle polynomial
% trans_morse is the r value where the polynomial transitions to the morse
% potential

var = 'r';
sym_morse = test_morse(var);

morse_cond = [trans_morse 0 1 2];
f_cond = [trans_f 0 1 2];

stitched_poly = sym_stitch_f1_f3_poly([f sym_morse], {f_cond morse_cond});

x = sym(var);

morse_pot = double(subs(stitched_poly, x, r));

if any(morse_pot(2:end) > morse_pot(1))
    error('Transition polynomial is not monotonically decreasing.')
end

