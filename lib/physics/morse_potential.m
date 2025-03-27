function [Morse] = morse_potential(D,alpha,Re,Rc,r)
%This function calculates the morse potential at each point on the 1-D grid

% The morse potential used is the same potential that is used in the LAMMPS
% simulation to determine the melting point of Cu using the
% morse/smooth/linear command with a cutoff of 15 Angstroms

% r is the vector describing distance for each point from the origin
% Rc is the cutoff distance from the origin
% D, alpha, Re are parameters from LAMMPS --Insert Citation Here--

phi = D .* (exp(-2 .* alpha .* (r-Re))- 2 .* exp(-alpha .* (r-Re)));
%phi_f = 2 .* alpha .* D .* (-exp(-2 .* alpha .* (r-Re))+ exp(-alpha .* (r-Re)));
%d2phi = 2 .* (alpha .^ 2) .* D .* (2 .* exp(-2 .* alpha .* (r-Re))+ exp(-alpha .* (r-Re)));

phiRc = D .* (exp(-2 .* alpha .* (Rc-Re))- 2 .* exp(-alpha .* (Rc-Re)));
phiRc_f = 2 .* alpha .* D .* (-exp(-2 .* alpha .* (Rc-Re))+ exp(-alpha .* (Rc-Re)));

Morse = phi - phiRc -(r-Rc) .* phiRc_f;
%dMorse = dphi - dphiRc;
%d2Morse = d2phi;

end

