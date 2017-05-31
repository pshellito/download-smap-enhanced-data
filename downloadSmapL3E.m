function [ outDir ] = downloadSmapL3E(qStart, qEnd, outDir)

% DOWNLOADSMAP This script will download SMAP enhanced data from NSIDC 
%       servers (via https://n5eil01u.ecs.nsidc.org/SMAP/SPL3SMP_E.001/) 
% Adapted from downloadNldasNoah by Peter J. Shellito 2/19/16
%
% qStart: a vector [yyyy, mm, dd] specifying the day to start downloading.
%       Start date must be [2015, 3, 31] or later. 
% qEnd: a vector [yyyy, mm, dd] specifying the day to stop downloading. End
%       date must be 1 day before today or earlier. Neither qStart nor 
%       qEnd support a starting hour and minute.
% outDir: Directory to place the output files. If nothing is provided,
%       default is to create a directory in the present directory titled
%       './outFiles/'
%  

% -------------------------------------------------------------------------
% If no output directory was provided
if nargin<3
    outDir = './outFiles';
end

% -------------------------------------------------------------------------
% Some initial checks

% Start date must be on or after March 31, 2015
dnStart = datenum(qStart);
if dnStart < datenum(2015,3,31)
    warning('Adjusting start date up to March 31, 2015, the first available SMAP retrieval')
    dnStart = datenum(2015,3,31);
end

% Make sure start date is not after end date
dnEnd = datenum(qEnd);
if dnEnd < dnStart
    error('Start date cannot be after end date')
end

% -------------------------------------------------------------------------
% Set up some variables

% The path to wget
PATH = getenv('PATH');
setenv('PATH', [PATH ':/opt/local/bin/']);

% The SMAP version to download
version = 1; % As of Jan 19, version 1 of enhanced data are available for all time periods

% The SMAP control release ID to download
crid = 'R14010';

% The datenums to get are the hourly data between dnStart and dnEnd
qDatenums = dnStart:dnEnd;

% Days that are known to be missing
missingDays = [...
    2015,5,13;
    2015,12,16;
    2016,05,01;
    2016,09,27];
% Their associated datenums
missingDns = datenum(missingDays);
% The intersections of mssing days and requested days
[~, ~, bb] = intersect(missingDns, qDatenums);
% Remove datenums that are missing
qDatenums(bb) = [];

% The year, month, day, and hour of each datenum in the query
[qYears, qMonths, qDays] = datevec(qDatenums);

% Convert qYears to string
qYearStr = num2str(qYears');
% Convert qMonths to string
qMonthStr = num2str(qMonths', '%02d');
% Convert qDays to string
qDayStr = num2str(qDays', '%02d');

% The base of the url where nldas forcings are held
httpsBaseUrl = 'https://n5eil01u.ecs.nsidc.org/SMAP/SPL3SMP_E.';

% The suffix of the files to download
endFn = 'h5';

% Authorization options
authOpts = '--load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on ';

% -------------------------------------------------------------------------
% Create a directory to hold output data
if exist(outDir, 'dir') ~= 7
    disp(['Making an output directory here: ' outDir])
    mkdir(outDir);
end

% -------------------------------------------------------------------------
% For each day requested, download the data
for dd = 1:length(qDatenums)
    % The complete https Url of the directory
    qDirName = [httpsBaseUrl num2str(version,'%03d') '/' qYearStr(dd,:) '.' qMonthStr(dd,:) '.' qDayStr(dd,:) ...
        '/'];
    % The bash command to be called. See
    % https://nsidc.org/support/faq/what-options-are-available-bulk-downloading-data-https-earthdata-login-enabled
    % or https://disc.sci.gsfc.nasa.gov/recipes/?q=recipes/How-to-Download-Data-Files-from-HTTP-Service-with-wget

    % This command will dl one specific file:
    command = ['wget ' authOpts ...
        ' -r --reject "index.html*" -np -nd ' ...
        qDirName 'SMAP_L3_SM_P_E_' qYearStr(dd,:) qMonthStr(dd,:) qDayStr(dd,:) ...
        '_' crid '_001.h5'];
    % Get that file
    disp(['Getting data file in directory: ' qDirName '...'])
    try
        % Use the unix system to carry out the wget command
        status = system(command);
    catch
        warning(['No directory ' qDirName ' exists.'])
    end % Try to download the data
    % Move file to the output directory
    movefile(['*' endFn], outDir);
end % dd loop through each day

end % function downloadNldasNoah