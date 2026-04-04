%% GRF ESTIMATION - RUNNING TRIAL 2 - FINAL FULL SCRIPT
clc;
clear;
close all;

%% ============================= USER INPUT ================================
filePath = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation_2\data\Running trial 2.csv';
refMatFile = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation_2\SR\GRF Estimation\processed_data\2p5ms_A.mat';

resultsDir = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation_2\results\running trial 2\results';
figuresDir = 'C:\Users\arjun\OneDrive\Documents\Intern_Test\GRF Estimation_2\results\running trial 2\figures';

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end
if ~exist(figuresDir, 'dir')
    mkdir(figuresDir);
end

%% ============================= LOAD CSV =================================
data = readtable(filePath);

disp('Column names in CSV:')
disp(data.Properties.VariableNames')

requiredCols = { ...
    'Time', ...
    'calc_back_left_Z', 'toe_left_Z', 'mal_lat_left_Z', ...
    'calc_back_right_Z', 'toe_right_Z', 'mal_lat_right_Z'};

for k = 1:length(requiredCols)
    if ~ismember(requiredCols{k}, data.Properties.VariableNames)
        error(['Missing required column: ' requiredCols{k}]);
    end
end

%% ========================== SAMPLING INFO ===============================
time = data.Time;
fs = round(1 / mean(diff(time)));
dt = 1 / fs;

fprintf('Estimated sampling frequency: %.2f Hz\n', fs);

%% ======================= PARTICIPANT DETAILS ============================
mb = 59.8;
g  = 9.81;
BW = mb * g;
m1 = 0.08 * mb;

fprintf('Body weight = %.3f N\n', BW);

%% ======================== EXTRACT MARKERS ===============================
heelL = data.calc_back_left_Z;
toeL  = data.toe_left_Z;
ankL  = data.mal_lat_left_Z;

heelR = data.calc_back_right_Z;
toeR  = data.toe_right_Z;
ankR  = data.mal_lat_right_Z;

% ankle in meters
ankL = ankL / 1000;
ankR = ankR / 1000;

%% ============================ FILTERING =================================
fc = 25;
[b,a] = butter(4, fc/(fs/2));

heelZ_L = filtfilt(b,a, heelL);
toeZ_L  = filtfilt(b,a, toeL);
ankZ_L  = filtfilt(b,a, ankL);

heelZ_R = filtfilt(b,a, heelR);
toeZ_R  = filtfilt(b,a, toeR);
ankZ_R  = filtfilt(b,a, ankR);

%% ======================= INSPECTION FIGURES =============================
f1 = figure('Name','Left_Heel_Toe_Signals','Color','w');
plot(time, heelZ_L, 'b', 'LineWidth', 1.2); hold on;
plot(time, toeZ_L, 'r', 'LineWidth', 1.2);
legend('Heel L','Toe L');
title('Left heel and toe vertical signals');
xlabel('Time (s)'); ylabel('Position');
grid on;

f2 = figure('Name','Right_Heel_Toe_Signals','Color','w');
plot(time, heelZ_R, 'b', 'LineWidth', 1.2); hold on;
plot(time, toeZ_R, 'r', 'LineWidth', 1.2);
legend('Heel R','Toe R');
title('Right heel and toe vertical signals');
xlabel('Time (s)'); ylabel('Position');
grid on;

%% ======================= TOUCHDOWN DETECTION ============================
[~, locs_L] = findpeaks(-heelZ_L, 'MinPeakDistance', round(0.30*fs));
[~, locs_R] = findpeaks(-heelZ_R, 'MinPeakDistance', round(0.30*fs));

%% ======================= TOE-OFF DETECTION ==============================
toeV_L = gradient(toeZ_L, dt);
toeV_R = gradient(toeZ_R, dt);

%% =================== EVENT PAIRING WITH ROBUST TO =======================
TD_L = [];
TO_L = [];
nextTD_L = [];
tc_L = [];
ta_L = [];
TD_frame_L = [];
TO_frame_L = [];
nextTD_frame_L = [];

for i = 1:length(locs_L)-1
    td = locs_L(i);
    td_next = locs_L(i+1);

    searchStart = td + round(0.10*fs);
    searchEnd   = min(td + round(0.35*fs), td_next - 1);

    if searchEnd <= searchStart
        continue;
    end

    seg = toeV_L(searchStart:searchEnd);
    [~, idxMax] = max(seg);
    to = searchStart + idxMax - 1;

    tc_val = (to - td) / fs;
    ta_val = (td_next - to) / fs;

    if tc_val < 0.08 || tc_val > 0.35
        continue;
    end
    if ta_val < 0.02 || ta_val > 0.35
        continue;
    end

    TD_L(end+1,1) = time(td);
    TO_L(end+1,1) = time(to);
    nextTD_L(end+1,1) = time(td_next);

    tc_L(end+1,1) = tc_val;
    ta_L(end+1,1) = ta_val;

    TD_frame_L(end+1,1) = td;
    TO_frame_L(end+1,1) = to;
    nextTD_frame_L(end+1,1) = td_next;
end

TD_R = [];
TO_R = [];
nextTD_R = [];
tc_R = [];
ta_R = [];
TD_frame_R = [];
TO_frame_R = [];
nextTD_frame_R = [];

for i = 1:length(locs_R)-1
    td = locs_R(i);
    td_next = locs_R(i+1);

    searchStart = td + round(0.10*fs);
    searchEnd   = min(td + round(0.35*fs), td_next - 1);

    if searchEnd <= searchStart
        continue;
    end

    seg = toeV_R(searchStart:searchEnd);
    [~, idxMax] = max(seg);
    to = searchStart + idxMax - 1;

    tc_val = (to - td) / fs;
    ta_val = (td_next - to) / fs;

    if tc_val < 0.08 || tc_val > 0.35
        continue;
    end
    if ta_val < 0.02 || ta_val > 0.35
        continue;
    end

    TD_R(end+1,1) = time(td);
    TO_R(end+1,1) = time(to);
    nextTD_R(end+1,1) = time(td_next);

    tc_R(end+1,1) = tc_val;
    ta_R(end+1,1) = ta_val;

    TD_frame_R(end+1,1) = td;
    TO_frame_R(end+1,1) = to;
    nextTD_frame_R(end+1,1) = td_next;
end

%% ========================= EVENT CHECK PLOTS ============================
f3 = figure('Name','Left_Paired_Events','Color','w');
plot(time, heelZ_L, 'b'); hold on;
plot(time(TD_frame_L), heelZ_L(TD_frame_L), 'bo', 'LineWidth', 1.5);
plot(time, toeZ_L, 'r');
plot(time(TO_frame_L), toeZ_L(TO_frame_L), 'ro', 'LineWidth', 1.5);
legend('Heel L','TD','Toe L','TO');
title('Left paired events');
xlabel('Time (s)'); ylabel('Position');
grid on;

f4 = figure('Name','Right_Paired_Events','Color','w');
plot(time, heelZ_R, 'b'); hold on;
plot(time(TD_frame_R), heelZ_R(TD_frame_R), 'bo', 'LineWidth', 1.5);
plot(time, toeZ_R, 'r');
plot(time(TO_frame_R), toeZ_R(TO_frame_R), 'ro', 'LineWidth', 1.5);
legend('Heel R','TD','Toe R','TO');
title('Right paired events');
xlabel('Time (s)'); ylabel('Position');
grid on;

%% ============================ STEP STATS ================================
disp('tc_L stats [min mean max]:')
disp([min(tc_L) mean(tc_L) max(tc_L)])
disp('ta_L stats [min mean max]:')
disp([min(ta_L) mean(ta_L) max(ta_L)])
disp('Left step count:')
disp(length(tc_L))

disp('tc_R stats [min mean max]:')
disp([min(tc_R) mean(tc_R) max(tc_R)])
disp('ta_R stats [min mean max]:')
disp([min(ta_R) mean(ta_R) max(ta_R)])
disp('Right step count:')
disp(length(tc_R))

fprintf('\nMean left tc   = %.4f s\n', mean(tc_L));
fprintf('Mean left ta   = %.4f s\n', mean(ta_L));
fprintf('Mean right tc  = %.4f s\n', mean(tc_R));
fprintf('Mean right ta  = %.4f s\n', mean(ta_R));

%% ===================== ANKLE VELOCITY FOR dv1 ===========================
ankV_L = gradient(ankZ_L, dt);
ankV_R = gradient(ankZ_R, dt);

f5 = figure('Name','Left_Ankle_Velocity','Color','w');
plot(time, ankV_L, 'b');
title('Left ankle vertical velocity');
xlabel('Time (s)'); ylabel('Velocity (m/s)');
grid on;

f6 = figure('Name','Right_Ankle_Velocity','Color','w');
plot(time, ankV_R, 'b');
title('Right ankle vertical velocity');
xlabel('Time (s)'); ylabel('Velocity (m/s)');
grid on;

%% ===================== COMPUTE dt1 AND dv1 ==============================
dt1_sec_L = [];
dv1_L = [];
ankMinFrame_L = [];
keepIdx_L = [];

for i = 1:length(TD_frame_L)
    td = TD_frame_L(i);
    to = TO_frame_L(i);

    startFrame = td + max(1, round(0.010*fs));
    if to <= startFrame
        continue;
    end

    [~, idxLocalMin] = min(ankZ_L(startFrame:to));
    minFrame = startFrame + idxLocalMin - 1;
    dt1_val = (minFrame - td) / fs;

    if dt1_val <= 0.005 || dt1_val > 0.08
        continue;
    end

    startPre = max(1, td - round(0.020*fs));
    v_down = min(ankV_L(startPre:td));
    dv1_val = abs(v_down);

    if dv1_val < 0.05 || dv1_val > 5
        continue;
    end

    dt1_sec_L(end+1,1) = dt1_val;
    dv1_L(end+1,1) = dv1_val;
    ankMinFrame_L(end+1,1) = minFrame;
    keepIdx_L(end+1,1) = i;
end

TD_L = TD_L(keepIdx_L);
TO_L = TO_L(keepIdx_L);
nextTD_L = nextTD_L(keepIdx_L);
tc_L = tc_L(keepIdx_L);
ta_L = ta_L(keepIdx_L);
TD_frame_L = TD_frame_L(keepIdx_L);
TO_frame_L = TO_frame_L(keepIdx_L);
nextTD_frame_L = nextTD_frame_L(keepIdx_L);

dt1_sec_R = [];
dv1_R = [];
ankMinFrame_R = [];
keepIdx_R = [];

for i = 1:length(TD_frame_R)
    td = TD_frame_R(i);
    to = TO_frame_R(i);

    startFrame = td + max(1, round(0.010*fs));
    if to <= startFrame
        continue;
    end

    [~, idxLocalMin] = min(ankZ_R(startFrame:to));
    minFrame = startFrame + idxLocalMin - 1;
    dt1_val = (minFrame - td) / fs;

    if dt1_val <= 0.005 || dt1_val > 0.08
        continue;
    end

    startPre = max(1, td - round(0.020*fs));
    v_down = min(ankV_R(startPre:td));
    dv1_val = abs(v_down);

    if dv1_val < 0.05 || dv1_val > 5
        continue;
    end

    dt1_sec_R(end+1,1) = dt1_val;
    dv1_R(end+1,1) = dv1_val;
    ankMinFrame_R(end+1,1) = minFrame;
    keepIdx_R(end+1,1) = i;
end

TD_R = TD_R(keepIdx_R);
TO_R = TO_R(keepIdx_R);
nextTD_R = nextTD_R(keepIdx_R);
tc_R = tc_R(keepIdx_R);
ta_R = ta_R(keepIdx_R);
TD_frame_R = TD_frame_R(keepIdx_R);
TO_frame_R = TO_frame_R(keepIdx_R);
nextTD_frame_R = nextTD_frame_R(keepIdx_R);

disp('dt1_L stats [min mean max]:')
disp([min(dt1_sec_L) mean(dt1_sec_L) max(dt1_sec_L)])
disp('dv1_L stats [min mean max]:')
disp([min(dv1_L) mean(dv1_L) max(dv1_L)])

disp('dt1_R stats [min mean max]:')
disp([min(dt1_sec_R) mean(dt1_sec_R) max(dt1_sec_R)])
disp('dv1_R stats [min mean max]:')
disp([min(dv1_R) mean(dv1_R) max(dv1_R)])

%% ====================== MODEL INPUT TABLES ==============================
nL = min([length(TD_L), length(TO_L), length(nextTD_L), length(tc_L), length(ta_L), length(dt1_sec_L), length(dv1_L)]);
nR = min([length(TD_R), length(TO_R), length(nextTD_R), length(tc_R), length(ta_R), length(dt1_sec_R), length(dv1_R)]);

Step_L = (1:nL)';
Step_R = (1:nR)';

T_model_inputs_left = table( ...
    Step_L, TD_L(1:nL), TO_L(1:nL), nextTD_L(1:nL), ...
    tc_L(1:nL), ta_L(1:nL), dt1_sec_L(1:nL), dv1_L(1:nL), ...
    'VariableNames', {'Step','Touchdown','ToeOff','NextTouchdown','tc','ta','dt1','dv1'});

T_model_inputs_right = table( ...
    Step_R, TD_R(1:nR), TO_R(1:nR), nextTD_R(1:nR), ...
    tc_R(1:nR), ta_R(1:nR), dt1_sec_R(1:nR), dv1_R(1:nR), ...
    'VariableNames', {'Step','Touchdown','ToeOff','NextTouchdown','tc','ta','dt1','dv1'});

%% ========================= IMPULSE CALCULATIONS =========================
tc  = T_model_inputs_left.tc;
ta  = T_model_inputs_left.ta;
dt1 = T_model_inputs_left.dt1;
dv1 = T_model_inputs_left.dv1;

strideTime_L = tc + ta;
t_step_L = strideTime_L / 2;
FT_avg_L = mb * g .* (t_step_L ./ tc);
JT_L = mb * g .* t_step_L;
J1_L = (m1 .* (dv1 ./ dt1) + m1 * g) .* (2 .* dt1);
J2_L = JT_L - J1_L;

tc  = T_model_inputs_right.tc;
ta  = T_model_inputs_right.ta;
dt1 = T_model_inputs_right.dt1;
dv1 = T_model_inputs_right.dv1;

strideTime_R = tc + ta;
t_step_R = strideTime_R / 2;
FT_avg_R = mb * g .* (t_step_R ./ tc);
JT_R = mb * g .* t_step_R;
J1_R = (m1 .* (dv1 ./ dt1) + m1 * g) .* (2 .* dt1);
J2_R = JT_R - J1_R;

% Keep only physical rows
validL = J2_L > 0;
validR = J2_R > 0;

T_model_inputs_left = T_model_inputs_left(validL,:);
FT_avg_L = FT_avg_L(validL);
JT_L = JT_L(validL);
J1_L = J1_L(validL);
J2_L = J2_L(validL);

T_model_inputs_right = T_model_inputs_right(validR,:);
FT_avg_R = FT_avg_R(validR);
JT_R = JT_R(validR);
J1_R = J1_R(validR);
J2_R = J2_R(validR);

%% ======================== GRF QUANTITY TABLES ===========================
T_GRF_left = table( ...
    (1:length(JT_L))', ...
    T_model_inputs_left.tc, ...
    T_model_inputs_left.ta, ...
    T_model_inputs_left.dt1, ...
    T_model_inputs_left.dv1, ...
    JT_L(:), J1_L(:), J2_L(:), FT_avg_L(:), ...
    'VariableNames', {'Step','tc','ta','dt1','dv1','JT','J1','J2','FT_avg'});

T_GRF_right = table( ...
    (1:length(JT_R))', ...
    T_model_inputs_right.tc, ...
    T_model_inputs_right.ta, ...
    T_model_inputs_right.dt1, ...
    T_model_inputs_right.dv1, ...
    JT_R(:), J1_R(:), J2_R(:), FT_avg_R(:), ...
    'VariableNames', {'Step','tc','ta','dt1','dv1','JT','J1','J2','FT_avg'});

%% ========================= BUILD vGRF WAVEFORMS =========================
GRF_left = cell(height(T_model_inputs_left),1);

for i = 1:height(T_model_inputs_left)
    tc  = T_model_inputs_left.tc(i);
    dt1 = T_model_inputs_left.dt1(i);

    t = linspace(0, tc, 500)';

    F1 = zeros(size(t));
    B1 = dt1;
    C1 = dt1;
    idx1 = (t >= 0) & (t <= 2*dt1);
    A1 = J1_L(i) / C1;
    F1(idx1) = (A1/2) .* (1 + cos(((t(idx1) - B1) ./ C1) * pi));

    F2 = zeros(size(t));
    B2 = 0.47 * tc;
    C2 = tc / 2;
    idx2 = (t >= 0) & (t <= tc);
    A2 = 2 * J2_L(i) / tc;
    F2(idx2) = (A2/2) .* (1 + cos(((t(idx2) - B2) ./ C2) * pi));

    F1(F1 < 0) = 0;
    F2(F2 < 0) = 0;
    FT = F1 + F2;

    GRF_left{i}.time = t;
    GRF_left{i}.F1 = F1;
    GRF_left{i}.F2 = F2;
    GRF_left{i}.FT = FT;
end

GRF_right = cell(height(T_model_inputs_right),1);

for i = 1:height(T_model_inputs_right)
    tc  = T_model_inputs_right.tc(i);
    dt1 = T_model_inputs_right.dt1(i);

    t = linspace(0, tc, 500)';

    F1 = zeros(size(t));
    B1 = dt1;
    C1 = dt1;
    idx1 = (t >= 0) & (t <= 2*dt1);
    A1 = J1_R(i) / C1;
    F1(idx1) = (A1/2) .* (1 + cos(((t(idx1) - B1) ./ C1) * pi));

    F2 = zeros(size(t));
    B2 = 0.47 * tc;
    C2 = tc / 2;
    idx2 = (t >= 0) & (t <= tc);
    A2 = 2 * J2_R(i) / tc;
    F2(idx2) = (A2/2) .* (1 + cos(((t(idx2) - B2) ./ C2) * pi));

    F1(F1 < 0) = 0;
    F2(F2 < 0) = 0;
    FT = F1 + F2;

    GRF_right{i}.time = t;
    GRF_right{i}.F1 = F1;
    GRF_right{i}.F2 = F2;
    GRF_right{i}.FT = FT;
end

%% ============================= EXAMPLE PLOTS ============================
if ~isempty(GRF_left)
    f7 = figure('Name','Left_Step_1_vGRF','Color','w');
    plot(GRF_left{1}.time, GRF_left{1}.F1, 'r', 'LineWidth', 1.5); hold on;
    plot(GRF_left{1}.time, GRF_left{1}.F2, 'b', 'LineWidth', 1.5);
    plot(GRF_left{1}.time, GRF_left{1}.FT, 'k', 'LineWidth', 2);
    legend('F1','F2','Total GRF');
    xlabel('Time (s)');
    ylabel('Force (N)');
    title('Left Step 1');
    grid on;
end

if ~isempty(GRF_right)
    f8 = figure('Name','Right_Step_1_vGRF','Color','w');
    plot(GRF_right{1}.time, GRF_right{1}.F1, 'r', 'LineWidth', 1.5); hold on;
    plot(GRF_right{1}.time, GRF_right{1}.F2, 'b', 'LineWidth', 1.5);
    plot(GRF_right{1}.time, GRF_right{1}.FT, 'k', 'LineWidth', 2);
    legend('F1','F2','Total GRF');
    xlabel('Time (s)');
    ylabel('Force (N)');
    title('Right Step 1');
    grid on;
end

%% =========================== PEAK SUMMARY ===============================
peak_L = zeros(length(GRF_left),1);
peak_R = zeros(length(GRF_right),1);

for i = 1:length(GRF_left)
    peak_L(i) = max(GRF_left{i}.FT);
end
for i = 1:length(GRF_right)
    peak_R(i) = max(GRF_right{i}.FT);
end

fprintf('\nMean predicted left peak  = %.2f N (%.2f BW)\n', mean(peak_L), mean(peak_L)/BW);
fprintf('Mean predicted right peak = %.2f N (%.2f BW)\n', mean(peak_R), mean(peak_R)/BW);
fprintf('Mean left avg contact force  = %.2f N\n', mean(FT_avg_L));
fprintf('Mean right avg contact force = %.2f N\n', mean(FT_avg_R));

nPeak = min(length(peak_L), length(peak_R));
T_peak_summary = table( ...
    (1:nPeak)', ...
    peak_L(1:nPeak), ...
    peak_R(1:nPeak), ...
    peak_L(1:nPeak)/BW, ...
    peak_R(1:nPeak)/BW, ...
    'VariableNames', {'Step','Peak_Left_N','Peak_Right_N','Peak_Left_BW','Peak_Right_BW'});

%% ===================== ALL POINTS TABLES ================================
StepID = [];
TimeAll = [];
F1All = [];
F2All = [];
FTAll = [];

for i = 1:length(GRF_left)
    n = length(GRF_left{i}.time);
    StepID = [StepID; i*ones(n,1)];
    TimeAll = [TimeAll; GRF_left{i}.time(:)];
    F1All   = [F1All; GRF_left{i}.F1(:)];
    F2All   = [F2All; GRF_left{i}.F2(:)];
    FTAll   = [FTAll; GRF_left{i}.FT(:)];
end

T_all_left = table(StepID, TimeAll, F1All, F2All, FTAll, ...
    'VariableNames', {'Step','Time_s','F1_N','F2_N','vGRF_N'});

StepID = [];
TimeAll = [];
F1All = [];
F2All = [];
FTAll = [];

for i = 1:length(GRF_right)
    n = length(GRF_right{i}.time);
    StepID = [StepID; i*ones(n,1)];
    TimeAll = [TimeAll; GRF_right{i}.time(:)];
    F1All   = [F1All; GRF_right{i}.F1(:)];
    F2All   = [F2All; GRF_right{i}.F2(:)];
    FTAll   = [FTAll; GRF_right{i}.FT(:)];
end

T_all_right = table(StepID, TimeAll, F1All, F2All, FTAll, ...
    'VariableNames', {'Step','Time_s','F1_N','F2_N','vGRF_N'});

%% ====================== COMPARE WITH REFERENCE MAT ======================
refCompareSummary = [];
if exist(refMatFile, 'file') == 2
    ref = load(refMatFile);

    if isfield(ref, 'measured_force_steps')
        measured = ref.measured_force_steps;

        if size(measured,1) < size(measured,2)
            measured = measured';
        end

        predSteps = {};

        for i = 1:length(GRF_left)
            predSteps{end+1} = interp1( ...
                GRF_left{i}.time, GRF_left{i}.FT, ...
                linspace(0, GRF_left{i}.time(end), 201)', 'linear');
        end

        for i = 1:length(GRF_right)
            predSteps{end+1} = interp1( ...
                GRF_right{i}.time, GRF_right{i}.FT, ...
                linspace(0, GRF_right{i}.time(end), 201)', 'linear');
        end

        pred = cell2mat(cellfun(@(x) x(:), predSteps, 'UniformOutput', false));

        nCompare = min(size(pred,2), size(measured,2));
        pred_use = pred(:,1:nCompare);
        meas_use = measured(:,1:nCompare);

        pred_peak = max(pred_use, [], 1);
        meas_peak = max(meas_use, [], 1);

        pred_mean_peak = mean(pred_peak);
        meas_mean_peak = mean(meas_peak);

        pred_mean_force = mean(pred_use(:));
        meas_mean_force = mean(meas_use(:));

        rmse_all = sqrt(mean((pred_use(:) - meas_use(:)).^2));

        C = corrcoef(mean(pred_use,2), mean(meas_use,2));
        overall_r = C(1,2);

        ss_res = sum((mean(meas_use,2) - mean(pred_use,2)).^2);
        ss_tot = sum((mean(meas_use,2) - mean(mean(meas_use,2))).^2);
        overall_r2 = 1 - ss_res/ss_tot;

        fprintf('\n========== REFERENCE COMPARISON ==========\n');
        fprintf('Compared steps              : %d\n', nCompare);
        fprintf('Predicted mean peak VGRF    : %.2f N\n', pred_mean_peak);
        fprintf('Measured  mean peak VGRF    : %.2f N\n', meas_mean_peak);
        fprintf('Peak error                  : %.2f N\n', pred_mean_peak - meas_mean_peak);
        fprintf('Predicted mean waveform val : %.2f N\n', pred_mean_force);
        fprintf('Measured  mean waveform val : %.2f N\n', meas_mean_force);
        fprintf('Waveform RMSE               : %.2f N\n', rmse_all);
        fprintf('Mean waveform correlation r : %.4f\n', overall_r);
        fprintf('Mean waveform R^2           : %.4f\n', overall_r2);

        refCompareSummary = table( ...
            nCompare, pred_mean_peak, meas_mean_peak, ...
            pred_mean_peak - meas_mean_peak, ...
            pred_mean_force, meas_mean_force, ...
            rmse_all, overall_r, overall_r2, ...
            'VariableNames', {'ComparedSteps','PredictedMeanPeak_N','MeasuredMeanPeak_N', ...
            'PeakError_N','PredictedMeanWaveform_N','MeasuredMeanWaveform_N', ...
            'RMSE_N','Corr_r','R2'});

        f9 = figure('Name','Mean_Waveform_Comparison','Color','w');
        plot(linspace(0,100,size(meas_use,1)), mean(meas_use,2), 'k', 'LineWidth', 2); hold on;
        plot(linspace(0,100,size(pred_use,1)), mean(pred_use,2), 'r--', 'LineWidth', 2);
        legend('Measured reference','Predicted two-mass');
        xlabel('% stance');
        ylabel('Force (N)');
        title('Mean measured vs predicted vGRF');
        grid on;
    else
        warning('Reference MAT file does not contain measured_force_steps.');
    end
else
    warning('Reference MAT file not found. Skipping comparison.');
end

%% ===================== EXPORT MY DATA LIKE REFERENCE ====================
allFT = {};
allF2 = {};

for i = 1:length(GRF_left)
    tOld = GRF_left{i}.time(:);
    FTold = GRF_left{i}.FT(:);
    F2old = GRF_left{i}.F2(:);

    tNew = linspace(0, 1, 201)';
    FTnew = interp1(linspace(0,1,length(tOld))', FTold, tNew, 'linear');
    F2new = interp1(linspace(0,1,length(tOld))', F2old, tNew, 'linear');

    allFT{end+1} = FTnew;
    allF2{end+1} = F2new;
end

for i = 1:length(GRF_right)
    tOld = GRF_right{i}.time(:);
    FTold = GRF_right{i}.FT(:);
    F2old = GRF_right{i}.F2(:);

    tNew = linspace(0, 1, 201)';
    FTnew = interp1(linspace(0,1,length(tOld))', FTold, tNew, 'linear');
    F2new = interp1(linspace(0,1,length(tOld))', F2old, tNew, 'linear');

    allFT{end+1} = FTnew;
    allF2{end+1} = F2new;
end

nSteps = length(allFT);
FTmat = zeros(201, nSteps);
F2mat = zeros(201, nSteps);

for i = 1:nSteps
    FTmat(:,i) = allFT{i};
    F2mat(:,i) = allF2{i};
end

timeNorm = linspace(0, 1, 201)';
meanFT = mean(FTmat, 2);
meanF2 = mean(F2mat, 2);

T_mean_time = table( ...
    timeNorm, meanFT, meanF2, ...
    'VariableNames', {'Time_normalized','Mean_Predicted_GRF_N','Mean_CoM_GRF_N'});

meanFT_per_step = mean(FTmat, 1)';
meanF2_per_step = mean(F2mat, 1)';

T_mean_step = table( ...
    (1:nSteps)', meanFT_per_step, meanF2_per_step, ...
    'VariableNames', {'Step_ID','Mean_Predicted_GRF_N','Mean_CoM_GRF_N'});

summaryData = {
    'Parameter', 'Value'
    'condition_label', 'Running Trial 2'
    'trial_name', 'Predicted Two-Mass GRF'
    'subject_mass_kg', mb
    'input_marker_sampling_rate_hz', fs
    'predicted_waveform_points', 500
    'number_of_steps', nSteps
    'mean_predicted_grf_n', mean(meanFT_per_step)
    'mean_com_grf_n', mean(meanF2_per_step)
    'mean_peak_predicted_grf_n', mean(max(FTmat, [], 1))
    'mean_peak_com_grf_n', mean(max(F2mat, [], 1))
    };

%% ============================== SAVE OUTPUTS ============================
requiredVars = { ...
    'T_model_inputs_left','T_model_inputs_right', ...
    'T_GRF_left','T_GRF_right', ...
    'GRF_left','GRF_right', ...
    'JT_L','J1_L','J2_L', ...
    'JT_R','J1_R','J2_R', ...
    'FT_avg_L','FT_avg_R'};

for i = 1:length(requiredVars)
    if ~exist(requiredVars{i}, 'var')
        error(['Missing variable before saving: ' requiredVars{i}]);
    end
end

% CSV and MAT
writetable(T_model_inputs_left,  fullfile(resultsDir,'Left_Model_Inputs.csv'));
writetable(T_model_inputs_right, fullfile(resultsDir,'Right_Model_Inputs.csv'));

save(fullfile(resultsDir,'Left_Model_Inputs.mat'),  'T_model_inputs_left');
save(fullfile(resultsDir,'Right_Model_Inputs.mat'), 'T_model_inputs_right');

writetable(T_GRF_left,  fullfile(resultsDir,'Left_GRF_Quantities.csv'));
writetable(T_GRF_right, fullfile(resultsDir,'Right_GRF_Quantities.csv'));

save(fullfile(resultsDir,'Left_GRF_Quantities.mat'),  'T_GRF_left','JT_L','J1_L','J2_L','FT_avg_L');
save(fullfile(resultsDir,'Right_GRF_Quantities.mat'), 'T_GRF_right','JT_R','J1_R','J2_R','FT_avg_R');

save(fullfile(resultsDir,'Left_vGRF.mat'),  'GRF_left');
save(fullfile(resultsDir,'Right_vGRF.mat'), 'GRF_right');

writetable(T_all_left,  fullfile(resultsDir,'Left_All_vGRF.csv'));
writetable(T_all_right, fullfile(resultsDir,'Right_All_vGRF.csv'));
writetable(T_peak_summary, fullfile(resultsDir,'Peak_Summary.csv'));

save(fullfile(resultsDir,'All_Results.mat'), ...
    'T_model_inputs_left','T_model_inputs_right', ...
    'T_GRF_left','T_GRF_right', ...
    'GRF_left','GRF_right', ...
    'JT_L','J1_L','J2_L', ...
    'JT_R','J1_R','J2_R', ...
    'FT_avg_L','FT_avg_R');

% Main Excel results workbook
excelFile = fullfile(resultsDir,'Final_Results.xlsx');
writetable(T_model_inputs_left,  excelFile, 'Sheet','Left_Model_Inputs');
writetable(T_model_inputs_right, excelFile, 'Sheet','Right_Model_Inputs');
writetable(T_GRF_left,           excelFile, 'Sheet','Left_GRF');
writetable(T_GRF_right,          excelFile, 'Sheet','Right_GRF');
writetable(T_all_left,           excelFile, 'Sheet','Left_AllPoints');
writetable(T_all_right,          excelFile, 'Sheet','Right_AllPoints');
writetable(T_peak_summary,       excelFile, 'Sheet','Peaks');

if ~isempty(refCompareSummary)
    writetable(refCompareSummary, excelFile, 'Sheet','Reference_Comparison');
end

% Reference-style workbook for your data
myRefStyleFile = fullfile(resultsDir,'GRF_Mean_Values_MyData.xlsx');
writetable(T_mean_time, myRefStyleFile, 'Sheet', 'Mean GRF (Time-Normalized)');
writetable(T_mean_step, myRefStyleFile, 'Sheet', 'Mean GRF per Step');
writecell(summaryData, myRefStyleFile, 'Sheet', 'Summary', 'Range', 'A1');

%% ======================= SAVE REFERENCE SUMMARY =========================
if exist(refMatFile, 'file') == 2
    ref = load(refMatFile);

    refSummaryNames = {};
    refSummaryValues = {};
    fields = fieldnames(ref);

    for i = 1:length(fields)
        val = ref.(fields{i});
        if isnumeric(val) && isscalar(val)
            refSummaryNames{end+1,1} = fields{i};
            refSummaryValues{end+1,1} = val;
        elseif ischar(val) || isstring(val)
            refSummaryNames{end+1,1} = fields{i};
            refSummaryValues{end+1,1} = string(val);
        end
    end

    T_ref_summary = table(refSummaryNames, refSummaryValues, ...
        'VariableNames', {'Parameter','Value'});

    writetable(T_ref_summary, fullfile(resultsDir,'Reference_Summary.xlsx'), 'Sheet', 'Summary');
end

%% ======================= SAVE ALL FIGURES ===============================
figHandles = findall(groot, 'Type', 'figure');

for i = 1:length(figHandles)
    fig = figHandles(i);
    figName = get(fig, 'Name');

    if isempty(figName)
        figName = ['Figure_' num2str(i)];
    end

    figName = regexprep(figName, '[^\w]', '_');

    saveas(fig, fullfile(figuresDir, [figName '.png']));
    savefig(fig, fullfile(figuresDir, [figName '.fig']));
end

disp('All result files and figures saved successfully.');
disp(['Results folder: ' resultsDir]);
disp(['Figures folder: ' figuresDir]);