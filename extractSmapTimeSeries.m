function [ dnRange, vsm, idcsNotRec, flaggedBits ] = extractSmapTimeSeries(qLon, qLat, smapL3data)
%
% extractSmap This function will pull out a single time series from the SMAP database.
% It will only remove data flagged for:
% static water bodies,
% precipitation,
% snow,
% ice,
% frozen ground (from GMAO, not radiometer, which was messing things up before)
% mountains,
% dense veg (>5 kg/m2)
%
% Inputs to the function:
% qLon and qLat: the lon and lat of the location requested.
% smapL3data: the smap database
%
% Outputs from the function:
% dnRnage: The datenums corresponding to the data being returned. Datenums may have missing days, but correspondence with data is still good.
% vsm: The volumetric soil moisture sensed by SMAP passive L3 enhanced, version 1.
% idcsNotRec: A vector containing the indices of vsm data that are not recommended to be used.
% flaggedBits: A cell array containing the bit numbers that had flags raised. Cell size is identical to idcsNotRec and correspond to those indices. The bit numbers in each cell correspond to to the surface conditions described here: https://nsidc.org/data/smap/spl3smp_e/data-fields#surf

% Peter Shellito 5/31/2017

% ===============================================================
% Initialize the variables to return
dnRange = [];
vsm = [];
idcsNotRec = [];
flaggedBits = {};

% ===============================================================
% Read data from the smap database

% Determine the lon and lat indices of this site
[lonDiff, qLonIdx] = min(abs(smapL3data.longitude-qLon));
[latDiff, qLatIdx] = min(abs(smapL3data.latitude-qLat));

% If the site requested is more than 1/4 degree away from the closest
% pixel, do not return any data for this site
if lonDiff > 0.25 || latDiff > 0.25
    disp('This site''s lon and lat do not fall within the smap database domain.')
else
    % Read the smap vsm
    vsm = squeeze(smapL3data.soil_moisture(qLonIdx, qLatIdx, :));
    % Read the smap datenumbers
    dnRange = squeeze(smapL3data.tb_time_utc(qLonIdx, qLatIdx, :));
    % Read the smap flags
    surfFlag = squeeze(smapL3data.surface_flag(qLonIdx, qLatIdx, :));
    % Convert the surface flags to 16-bit binary and flip it left-right so that bit zero is on the left
    surfFlagBin = fliplr(dec2bin(surfFlag,16));
    % Convert binary to logcial
    surfFlagLogic = logical(surfFlagBin-'0');
    % Flag indices that we care about (see
    % https://nsidc.org/data/smap/spl3smp_e/data-fields#surf for complete list)
    flagIdcs = [1 5 6 7 9 10 11];
    % Dates with a flag that we care about
    dateIdcsFlagged = any(surfFlagLogic(:,flagIdcs),2);

    % Indices of data that have VSM values returned but have a flag
    idcsNotRec = find(dateIdcsFlagged & ~isnan(vsm));
    % Keep only the surface flags of these problem dates
    surfFlagBin = surfFlagBin(idcsNotRec,:);

    % Loop through each index that is not recommended
    for ii = 1:length(idcsNotRec)
        % The bit numbers that have been flagged. Subtract 1 because bits start at zero.
        flaggedBits{ii,1} = regexp(surfFlagBin(ii,:),'1')-1;
    end % ii loop through each index that is not recommended
end % If this site is within the smap domain
end % function extractSmap.m
