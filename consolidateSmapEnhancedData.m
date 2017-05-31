% This script will create database of SMAP L3 Enhanced (9 km) data over the continental US
% using data downloaded by the downloadSmap.m script. It will save fields
% as specified in data_set_names.csv. If the SMAP database already exists,
% it will simply append to it. If the SMAP database does not already exist,
% it will create one anew with the data available. 

% Adapted by Peter Shellito 1/20/17 from 
% Emily Carbone and Peter Shellito
% 6/28/2016

clear all
close all
% ========================================================================
% User controls

saveData = true;

% (1) Modify input file,'data_set_names.csv' to define what data sets to 
%     include in the database.
%     '//' is a comment marker, so delete the comment marker before the 
%     data sets you want to include in the database
dataSetsFn = './fieldsToSave.txt';

% (2) The location of the SMAP data to use
smapDir = './outFiles/';
% The prefix on the smap data file names. Must include everything up to 
% the 8-digit string indicating the retreival date.
smapPrefix = 'SMAP_L3_SM_P_E_';

% (3) Define the extent of the world to extract and save. Do not change
% these numbers if you hope to combine the database created with data from 
% an old one.
% Maximum extent:
% 'eastBoundLongitude':  180.000000
% 'westBoundLongitude':  -180.000000
% 'southBoundLatitude':  -85.044502
% 'northBoundLatitude':  85.044502
% The continental US:
minLon = -125.3;
maxLon = -66.2;
minLat = 24.9; 
maxLat = 53.1;

% (4) The mat file holding the lat and lon of the 9 km ease grid
lonLatValFn = 'globalEnhancedLonLatVals.mat';

% (5) The location and name of the SMAP database to add to or create
dbN = './smapL3Edatabase.mat';

% ========================================================================

% A note from the h5 file metadata:
% Group '/Metadata/Extent' 
%         Attributes:
%             'description':  'Soil moisture is retrieved over land targets 
%              on the descending (AM) SMAP half-orbits when the SMAP spacecraft 
%              is travelling from North to South, while the SMAP instruments 
%              are operating in the nominal mode.  The L3_SM_P_E product 
%              represents soil moisture retrieved over the entre UTC day. 
%              Retrievals are performed but flagged as questionable over urban 
%              areas, mountainous areas with high elevation variability, and 
%              areas with high ( &gt; 5 kg/m**2) vegetation water content; 
%              for retrievals using the high-resolution radar, cells in the 
%              nadir region are also flagged. Retrievals are inhibited for 
%              permanent snow/ice, frozen ground, and excessive static or 
%              transient open water in the cell, and for excessive RFI in 
%              the sensor data.'
% Record the starting time of this script
disp('Starting the script at')
startTime = datetime;
disp(startTime)

% Create array of field names to record. For a full description of what
% each fild name means, see https://nsidc.org/data/smap/spl3smp_e/data-fields/v1
% The most important to pay attention to is the retreival_qual_flag.
fns=textscan(fopen(dataSetsFn),'%s','CommentStyle',{'#'});
fieldNames=fns{:,1};

% The names of all files in the smap directory
fileNames = extractfield(dir([smapDir smapPrefix '*']), 'name');
% Convert the file names to a character matrix
fileNamesMat = cell2mat(fileNames');
% The datenums of these files
fileDns = sort(datenum(fileNamesMat(:,length(smapPrefix)+1:length(smapPrefix)+8), 'yyyymmdd'))';
% The number of files
nFiles = length(fileNames);

% Set group name for the data sets in h5 file
group='/Soil_Moisture_Retrieval_Data_AM/';
% Load the lon and lat values for the 9 km ease grid
load(lonLatValFn)
% The indices that correspond to the requested extent
lonIdcs = find(allLon>minLon & allLon<maxLon);
latIdcs = find(allLat>minLat & allLat<maxLat);

% Initialize a structure to hold the data being read in
smapL3data = struct;
% Record the lon and lat associated with this subset
smapL3data.longitude = allLon(lonIdcs);
smapL3data.latitude = allLat(latIdcs);

% Loop through the new files to read in and crop data to the requested
% extent
for ff = 1:nFiles
    % The path to the file name
    fileLocation = [smapDir fileNames{1,ff}];
    disp(['Reading h5 file ' fileLocation '...'])
    % Loop through each variable to record
    for mm = 1:numel(fieldNames)
        % If this field does not hold lon or lat, read it in
        if ~strcmp(fieldNames{mm}, 'longitude') && ~strcmp(fieldNames{mm}, 'latitude')
            % Read the variable (globally) from the hdf5 file
            globalData = h5read(fileLocation, [group fieldNames{mm}]);
            % Record only the portion of the globe requested
            globalDataTrimmed = globalData(lonIdcs, latIdcs);
            % If this is the cell array that contains the utc time
            if strcmp(fieldNames{mm}, 'tb_time_utc')
                % Rename this field to reflect that it is a cell array
                globalDataTrimmedCell = globalDataTrimmed;
                % The number of rows and columns in this cell array
                [nRows, nCols] = size(globalDataTrimmed);
                % Overwrite globalDataTrimmed as a nan matrix 
                globalDataTrimmed = nan(nRows, nCols);
                % Loop through each row
                for jj = 1:nRows
                    % Loop through each column
                    for ii = 1:nCols
                        % If the data in the cell is not N/A
                        if ~strcmp(globalDataTrimmedCell{jj,ii}(1:3), 'N/A')
                            % Then record the overpass time as a datenum
                            try
                                globalDataTrimmed(jj,ii) = ...
                                    datenum(globalDataTrimmedCell{jj,ii}(1:23), ...
                                    'yyyy-mm-ddThh:MM:SS.FFF');
                            catch
                                globalDataTrimmed(jj,ii) = ...
                                    datenum(globalDataTrimmedCell{jj,ii}(1:23), ...
                                    'yyyy-mm-ddThh:MM:SS.***');
                            end
                        end % if the data in the cell is not N/A. (Otherwise leave globalDataTrimmed as nan.)
                    end % Loop over each column
                end % Loop over each row
            end % If this field holds the utc time
            % Replace -9999 with nan
            globalDataTrimmed(globalDataTrimmed==-9999) = nan;
            % Assign to structure to save
            smapL3data.(fieldNames{mm})(:,:,ff) = globalDataTrimmed;
        end % If this field does not hold lon or lat, read it in
    end
    % Record the datenum of the file, too
    smapL3data.fileDatenum(ff) = fileDns(ff);
%     % Make a vsm vigure
%     figure;
%     imagesc(smapL3data.soil_moisture(:,:,ff)');
end % ff loop through the new files

% If there are also data in a database previously created
if exist(dbN, 'file') == 2
    % Load that old databse
    oldDb = load(dbN);
    % Find any datenums that are overlapping between the new and old
    [aa, bb, cc] = intersect(fileDns, oldDb.smapL3data.fileDatenum);
    % If there are some data that don't overlap, we want to concatenate
    % them together
    if ~isequal(aa,smapL3data.fileDatenum) || isempty(aa) % Equal would mean all dates overlap. Empty would mean no dates overlap.
        % The datenums from the old database
        oldDns = oldDb.smapL3data.fileDatenum;
        % Prepare to move some of the data from the old database to the new
        % one. Start by listing all the old datenum indices.
        idcsToMove = 1:length(oldDns);
        % The indices to move are those that did NOT have matching datenums
        % already in the database.
        idcsToMove(cc) = [];
        % Concatenate the new database's datenums with the old. There
        % should now be no datenums that are repeated, but they may be out
        % of order
        concatd.fileDatenum = [fileDns oldDns(idcsToMove)];
        % Sort these dns sequentially and get the indices
        [concatd.fileDatenum, sortIdcs] = sort(concatd.fileDatenum);
        % The lon and lat will stay the same
        concatd.longitude = smapL3data.longitude;
        concatd.latitude = smapL3data.latitude;
        % Loop through all the fieldNames and concatenate them too, also
        % sorting them in the same order as the datenums.
        for mm = 1:numel(fieldNames)
            % If the old database has this field name and it's not lon or
            % lat
            if isfield(oldDb.smapL3data, fieldNames{mm}) && ...
                ~strcmp(fieldNames{mm}, 'longitude') && ~strcmp(fieldNames{mm}, 'latitude')
                % Concatentate it with the new data along dimension 3,
                % keeping only the data corresponding to days that did not
                % overlap between old and new. If there is an erorr at this
                % line it means the old db had a different spatial extent
                % as the new database.
                concatd.(fieldNames{mm}) = cat(3, smapL3data.(fieldNames{mm}), ...
                    oldDb.smapL3data.(fieldNames{mm})(:,:,idcsToMove));
                % Sort it according to the indices found by sorting the
                % date
                concatd.(fieldNames{mm}) = concatd.(fieldNames{mm})(:,:,sortIdcs);
            end % If the old database has this field name
        end % mm loop through each field name
        % Overwrite the data with the concatenated data
        smapL3data = concatd;
    end % If there are some data that don't overlap
end % If there are data in a datebase that was previously created

% If instucted to save the data
if saveData
    % Save the data
    disp(['Saving data as ' dbN '...'])
    save(dbN, 'smapL3data', '-v7.3');
end

% Display how long this script took
disp(['Finished. Start time was:'])
disp(startTime)
disp(['End time was:'])
disp(datetime)