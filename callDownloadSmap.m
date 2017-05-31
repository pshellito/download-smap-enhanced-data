% This script will call the downloadSmapL3E function
% P. Shellito
% 5/31/17

clear all
close all

% -------------------------------------------------------------------------
% Date range requested:

% Start year, month, day
qStart = [2015,6,1];
% End year, month, day,
qEnd = [2015,6,1];

% Directory to hold the files
outDir = './outFiles';

% -------------------------------------------------------------------------
% Record what time is is before the function is called
disp('Starting the script at')
disp(datetime)
startTime = datetime;

% -------------------------------------------------------------------------
% Call the function to download smap enhanced data (9 km grid)
outDirectory = downloadSmapL3E(qStart, qEnd, outDir);

% -------------------------------------------------------------------------
% Report where the data are held and how long the script took to run
disp('Finished! Grib files can be found here:')
disp(outDirectory)
disp('Start and finish times were:')
disp(startTime)
disp(datetime)
