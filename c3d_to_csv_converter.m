addpath('C:\Users\arjun\Downloads\btk-0.2.1_Win7_MatlabR2009b_64bit\BTK\share\btk-0.2\Wrapping\Matlab\btk');
savepath;
rehash;
which btkReadAcquisition
C:\Users\arjun\Downloads\btk-0.2.1_Win7_MatlabR2009b_64bit\BTK\share\btk-0.2\Wrapping\Matlab\btk\btkReadAcquisition.mexw64 %[output:0e0c8a12]
filePath = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 2.c3d';
acq = btkReadAcquisition(filePath);
disp('BTK is working')
BTK is working
filePath = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 2.c3d';

acq = btkReadAcquisition(filePath);
markers = btkGetMarkers(acq);
markerNames = fieldnames(markers);

pointFreq = btkGetPointFrequency(acq);
firstFrame = btkGetFirstFrame(acq);

nFrames = size(markers.(markerNames{1}), 1);

frame = (firstFrame:firstFrame+nFrames-1)';
time = (0:nFrames-1)' / pointFreq;

data = [frame time];
colNames = {'Frame', 'Time'};

for i = 1:length(markerNames)
    name = markerNames{i};
    xyz = markers.(name);
    data = [data xyz];
    colNames = [colNames, {[name '_X'], [name '_Y'], [name '_Z']}];
end

T = array2table(data, 'VariableNames', matlab.lang.makeValidName(colNames));

outPath = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 2.csv';
writetable(T, outPath);

disp(['Done: ' outPath]);
Done: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 2.csv
which btkReadAcquisition
C:\Users\arjun\Downloads\btk-0.2.1_Win7_MatlabR2009b_64bit\BTK\share\btk-0.2\Wrapping\Matlab\btk\btkReadAcquisition.mexw64
acq = btkReadAcquisition('C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 2.c3d');
filesToConvert = {
    'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 3.c3d'
    'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 4.c3d'
    'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Static trial 1.c3d'
};

for k = 1:length(filesToConvert)
    filePath = filesToConvert{k};
    fprintf('Processing: %s\n', filePath);

    acq = btkReadAcquisition(filePath);
    markers = btkGetMarkers(acq);
    markerNames = fieldnames(markers);

    pointFreq = btkGetPointFrequency(acq);
    firstFrame = btkGetFirstFrame(acq);

    nFrames = size(markers.(markerNames{1}), 1);

    frame = (firstFrame:firstFrame+nFrames-1)';
    time = (0:nFrames-1)' / pointFreq;

    data = [frame time];
    colNames = {'Frame', 'Time'};

    for i = 1:length(markerNames)
        name = markerNames{i};
        xyz = markers.(name);
        data = [data xyz];
        colNames = [colNames, {[name '_X'], [name '_Y'], [name '_Z']}];
    end

    T = array2table(data, 'VariableNames', matlab.lang.makeValidName(colNames));

    [folder, baseName, ~] = fileparts(filePath);
    outPath = fullfile(folder, [baseName '.csv']);
    writetable(T, outPath);

    fprintf('Saved: %s\n\n', outPath);
end

disp('Selected files converted.');
Processing: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 3.c3d
Saved: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 3.csv

Processing: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 4.c3d
Saved: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Running trial 4.csv

Processing: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Static trial 1.c3d
Saved: C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation\data\Static trial 1.csv

Selected files converted.
%%

%%


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":18.8}
%---
%[output:0e0c8a12]
%   data: {"dataType":"error","outputData":{"errorType":"syntax","isTransient":false,"text":"Invalid use of operator."}}
%---
