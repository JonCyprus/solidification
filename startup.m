% Startup script for MATLAB

disp('Initializing MATLAB Project..');

% Add simulation folders to path (avoid annoying change directory)
addpath(genpath(fullfile(pwd,'simulations')));