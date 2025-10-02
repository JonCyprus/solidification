function [out] = create_noise(num, sigmaRange, ampRange, L, field)
%CREATE_NOISE Creates a Gaussian noise on the 2D grid
%
% out = addGaussianBlobs(baseField, L, numBlobs, sigmaRange, ampRange)
%
% Inputs:
%   baseField  - NxN array to add blobs to
%   L          - domain length (assumes square domain [-L/2,L/2])
%   numBlobs   - number of Gaussian blobs
%   sigmaRange - [minSigma, maxSigma] for blob widths
%   ampRange   - [minAmp, maxAmp] for blob amplitudes
%
% Output:
%   out        - NxN array with blobs added

% grid
x = linspace(-L/2, L/2, size(field,1));
[X,Y] = meshgrid(x,x);

out = field;

% Generate blobs
for i = 1:num
    % random center
    x0 = (rand-0.5)* L;
    y0 = (rand-0.5)* L;

    % random width
    sigma = sigmaRange(1) + diff(sigmaRange)*rand;

    % random amplitude
    amp = ampRange(1) + diff(ampRange)*rand;

    % add blob
    blob = amp * exp( -((X-x0).^2 + (Y-y0).^2)/(2*sigma^2));

    %add to field
    out = out+ blob;
end
end

