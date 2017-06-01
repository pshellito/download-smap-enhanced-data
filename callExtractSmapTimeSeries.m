% This script will read a list of requested stations and pull the
% SMAP data for each one

% Peter Shellito 5/31/17

% ==============================================================
% File names and directories

% Directory where SMAP data are held
smapDir = './';
% Name of SMAP database
smapDbFn = [smapDir 'smapL3Edatabase.mat'];
% Name of directory to hold SMAP data for each station
smapStationDir = [smapDir 'stationTimeSeries/'];
% File name holding requested stations
inFile = [smapDir 'stationList.txt'];

% ========================================================================
% Record the starting time of this script
disp('Starting the script at')
startTime = datetime;
disp(startTime)

% ==============================================================
% Load the list of station names
% Open the input file
fid = fopen(inFile);
% Read the data in the input file
data = textscan(fid,'%s\t%f\t%f', 'headerlines', 1);
% Close the input file
fclose(fid);

% Organize input data and create the needed vectors to pass into the function
% A cell array of strings
qNames = data{1,1};
% Latitude of the sites in qNames
qLat = data{1,2};
% Longitude of the sites in qNames
qLon = data{1,3};
% The number of stations requeste
nStations = length(qLat);

% ==============================================================
% Load data

% Load the smap database if necessary
if exist('smapL3data', 'var')
    disp('SMAP database is already in the workspace. No need to re-load.')
else
    disp('Loading smap database...')
    load(smapDbFn)
    disp('Done loading.')
end

% ==============================================================
% Create a directory to hold the station data if needed
if ~exist(smapStationDir, 'dir')
    mkdir(smapStationDir)
end

% =============================================================
% Loop through each station
for ss = 1:nStations
    % Display progress
    disp(['Reading station ' num2str(ss) ' of ' num2str(nStations)])

    % Call function to extract this site's data
    [datenumber vsm idcsNotRec flaggedBits] = ...
        extractSmapTimeSeries(qLon(ss), qLat(ss), smapL3data);

    % Save the SMAP data as its own file
    save([smapStationDir qNames{ss}], ...
        'datenumber', 'vsm', 'idcsNotRec', 'flaggedBits');
    % Flags meanings found here: https://nsidc.org/data/smap/spl3smp_e/data-fields/v1#surf
end % ss loop through stations

% =============================================================
% Display how long this script took
disp(['Finished. Start time was:'])
disp(startTime)
disp(['End time was:'])
disp(datetime)

