% Show sphere offsets for used in spherical neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

radii=2:.5:6;
nradii=numel(radii);

for k=1:nradii
    radius=radii(k);
    offsets=cosmo_sphere_offsets(radius);

    subplot(3,3,k);
    plot(offsets)
    legend({'i','j','k'});
    nfeatures=size(offsets,1);
    title(sprintf('r=%.1f: n=%d',radius,nfeatures));

end
