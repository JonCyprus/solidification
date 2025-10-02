function [] = Plot3D(axOrFig, x, y, z)
%Plots the 3-D surface of the one-body distribution function. Saves figures
%to One_body Figures
    if isa(axOrFig, 'matlab.graphics.axis.Axes')
        axes(axOrFig);
    else
        figure(axOrFig);
    end
        surf(x,y,z, 'EdgeAlpha', 0);
        xlabel(inputname(2));
        ylabel(inputname(3));
        zlabel(inputname(4));

        view(2)
        colorbar
        axis tight

end

