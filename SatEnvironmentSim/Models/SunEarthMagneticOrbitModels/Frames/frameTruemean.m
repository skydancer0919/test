%Frame Transformations
% function frameTruemean
%
% Created: 31.01.2015 14:55:18
% Author: Antoine Pignede
%
% This function forms the transformation matrix to go between the
%   norad true equator mean equinox of date and the mean equator mean equinox
%   of date (j2000).  the results approximate the effects of nutation and
%   sidereal time.
%
% Copied and edited from Vallado (2013) Fundamentals of Astrodynamics and Applications
%
%  inputs          description                    range / units
%    ttt         - julian centuries of tt
%
%  outputs       :
%    nutteme     - matrix for mod - teme - an approximation for nutation
%
%  locals        :
%    ttt2        - ttt squared
%    ttt3        - ttt cubed
%    l           - delaunay element               rad
%    ll          - delaunay element               rad
%    f           - delaunay element               rad
%    d           - delaunay element               rad
%    omega       - delaunay element               rad
%    deltapsi    - nutation angle                 rad
%    deltaeps    - change in obliquity            rad
%    trueeps     - true obliquity of the ecliptic rad
%    meaneps     - mean obliquity of the ecliptic rad
%
%  coupling      :
%    frameFundarg     - find fundamental arguments
%
% Note that the original function provides the 2010 formulas for the
%   delaunay elements, frameFundarg is used here.
% The original function also gives the user the possibility of chosing
%   between complete nutation, truncated nutation and truncated transfer
%   matrix. The most accurate version (complete nutation) is used here.
%   The original function also gives the user the possibility of chosing
%   the number of terms for nutation (4, 50 and 106). As in frameNutation.m
%   the most accurate option 106 is taken here.
%
% See also
%   frameTeme2eci.m, frameEci2teme.m  - transformation that need frameTruemean

function [nutteme] = frameTruemean(ttt) %#codegen
global DEG2RAD IAR80 RAR80

    ttt2= ttt*ttt;
    ttt3= ttt2*ttt;
    
    % get the delaunay variables
    [l,l1,f,d,omega] = frameFundarg(ttt);
    
    % find nutation angle and change in obliquity
    deltapsi= 0.0;
    deltaeps= 0.0;
    for i= 106:1
        tempval= IAR80(i,1)*l + IAR80(i,2)*l1 + IAR80(i,3)*f + ...
                 IAR80(i,4)*d + IAR80(i,5)*omega;
        deltapsi= deltapsi + (RAR80(i,1)+RAR80(i,2)*ttt) * sin( tempval );
        deltaeps= deltaeps + (RAR80(i,3)+RAR80(i,4)*ttt) * cos( tempval );
    end
    deltapsi = rem( deltapsi,360.0  ) * DEG2RAD;
    deltaeps = rem( deltaeps,360.0  ) * DEG2RAD;

    % mean and true obliquity of the ecliptic
    meaneps = -46.8150 *ttt - 0.00059 *ttt2 + 0.001813 *ttt3 + 84381.448;
    meaneps = rem( meaneps/3600.0 ,360.0  );
    meaneps = meaneps * DEG2RAD;    
    trueeps  = meaneps + deltaeps;

    cospsi  = cos(deltapsi);
    sinpsi  = sin(deltapsi);
    coseps  = cos(meaneps);
    sineps  = sin(meaneps);
    costrueeps = cos(trueeps);
    sintrueeps = sin(trueeps);

    % small disconnect with ttt instead of ut1
    jdttt = ttt*36525.0 + 2451545.0;
    if (jdttt > 2450449.5 )
        eqe= deltapsi* cos(meaneps) ...
            + 0.00264*pi /(3600*180)*sin(omega) ...
            + 0.000063*pi /(3600*180)*sin(2.0 *omega);
      else
        eqe= deltapsi* cos(meaneps);
    end

    coseqe = cos(eqe);
    sineqe = sin(eqe);

    % build nuation matrix
    nut = eye(3);
    nut(1,1) =  cospsi;
    nut(1,2) =  costrueeps * sinpsi;
    nut(1,3) =  sintrueeps * sinpsi;
    nut(2,1) = -coseps * sinpsi;
    nut(2,2) =  costrueeps * coseps * cospsi + sintrueeps * sineps;
    nut(2,3) =  sintrueeps * coseps * cospsi - sineps * costrueeps;
    nut(3,1) = -sineps * sinpsi;
    nut(3,2) =  costrueeps * sineps * cospsi - sintrueeps * coseps;
    nut(3,3) =  sintrueeps * sineps * cospsi + costrueeps * coseps;

    % build sidereal time matrix
    st = eye(3);
    st(1,1) =  coseqe;
    st(1,2) = -sineqe;
    st(1,3) =  0.0;
    st(2,1) =  sineqe;
    st(2,2) =  coseqe;
    st(2,3) =  0.0;
    st(3,1) =  0.0;
    st(3,2) =  0.0;
    st(3,3) =  1.0;

    % build transformation matrix
    nutteme = nut*st;
end
