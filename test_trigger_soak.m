% TEST_TRIGGER_SOAK - Long rig test for false trigger codes (no participant)
%
% The false code 135 can take from minutes to over an hour to appear, so a
% short test cannot catch it. This script holds the trigger pixel black for
% hours on the gray background and sends a one-frame marker every few seconds.
% Any other code on the Status channel is a false code, and a missing marker
% means a real trigger was overwritten. Analyse the recording with check_soak.m.
%
% The screen alternates between two phases, so check_soak can compare them:
%   static   - nothing is drawn between the markers (code 201)
%   flipping - a flip on every frame, pixel black (code 202)
% Each marker labels the interval that follows it. 210 = run start, 211 = run end.
%
% HOW TO USE
%   1. Set the refresh rate in the operating system and fill in the settings
%      below. Change one thing per run (refresh rate, video cable, ...).
%   2. Turn off display sleep, screen saver and automatic updates.
%   3. Connect the trigger cable, turn the amplifier on and start recording in
%      ActiView BEFORE running this script. A cap is not needed.
%   4. Run it and leave the computer alone. ESC stops it early.
%   5. Stop the recording and run check_soak.m on the BDF.
%
% It writes a log to soak_logs/ (marker times and flip timing).

clearvars; sca;

%% Settings
run_label      = 'cable_A_120Hz';   % describe this run (used in the log file name)
duration_min   = 120;               % length of the run
expected_hz    = 120;               % stops if the measured refresh rate differs
marker_every_s = 2;                 % time between markers
phase_s        = 30;                % length of each static / flipping phase

MARK_STATIC = 201;
MARK_FLIP   = 202;
MARK_START  = 210;
MARK_END    = 211;

%% Setup
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'Functions'));      % flip_trig, draw_trigger, trigger_rgb
cfg.triggers.enabled = true;

log_dir = fullfile(root, 'soak_logs');
if ~exist(log_dir, 'dir')
    mkdir(log_dir);
end
log_file = fullfile(log_dir, sprintf('%s_%s.mat', run_label, ...
    char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))));

KbName('UnifyKeyNames');
esc = KbName('ESCAPE');

n_max       = ceil(duration_min * 60 / marker_every_s) + 10;
marker_time = nan(n_max, 1);       % measured onset of each marker
marker_code = nan(n_max, 1);
marker_lag  = nan(n_max, 1);       % measured minus planned onset (s)
k           = 0;
win         = [];
ifi         = NaN;

try
    % same settings as set_screen(2, 0, cfg)
    PsychDefaultSetup(2);
    screen_ID = max(Screen('Screens'));
    white = WhiteIndex(screen_ID);
    bg    = white / 2;
    Screen('Preference', 'SkipSyncTests', 0);
    [win, ~] = PsychImaging('OpenWindow', screen_ID, bg);
    Priority(MaxPriority(win));
    HideCursor(screen_ID);
    flip_trig(win, cfg, 0);

    ifi = Screen('GetFlipInterval', win);
    if abs(1 / ifi - expected_hz) > 1
        error('soak:rate', 'Measured %.2f Hz, expected %g Hz. Set the rate in the OS or change expected_hz.', ...
            1 / ifi, expected_hz);
    end
    fprintf('Run "%s": %.2f Hz, %g min. ESC stops it.\n', run_label, 1 / ifi, duration_min);

    %% Run
    t_start   = flip_trig(win, cfg, MARK_START);
    t_stop    = t_start + duration_min * 60;
    next      = t_start + marker_every_s;
    last_save = t_start;

    while next < t_stop
        is_flipping = mod(floor((next - t_start) / phase_s), 2) == 1;
        if is_flipping
            code = MARK_FLIP;
        else
            code = MARK_STATIC;
        end

        vbl = flip_trig(win, cfg, code, next - ifi / 2);
        k = k + 1;
        marker_time(k) = vbl;
        marker_code(k) = code;
        marker_lag(k)  = vbl - next;
        next = next + marker_every_s;

        if vbl - last_save > 300
            save_log(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k);
            last_save = vbl;
            fprintf('%.0f of %g min\n', (vbl - t_start) / 60, duration_min);
        end

        % the interval that this marker labels
        if is_flipping
            while GetSecs < next - 1.5 * ifi
                flip_trig(win, cfg, 0);
                check_quit(esc);
            end
        else
            while GetSecs < next - 0.02
                check_quit(esc);
                WaitSecs(0.005);
            end
        end
    end

    flip_trig(win, cfg, MARK_END);
    WaitSecs(2);
    finish(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k);

catch err
    if strcmp(err.identifier, 'soak:quit') && ~isempty(win)
        flip_trig(win, cfg, MARK_END);     % so check_soak still finds the end
        finish(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k);
        disp(err.message);
    else
        if k > 0
            save_log(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k);
        end
        sca; ShowCursor; Priority(0);
        rethrow(err);
    end
end


function finish(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k)
save_log(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k);
sca; ShowCursor; Priority(0);
late = sum(marker_lag(1:k) > ifi / 2);
fprintf('Done: %d markers, %d later than planned (max lag %.1f ms).\n', ...
    k, late, 1000 * max([marker_lag(1:k); 0]));
fprintf('Log: %s\nStop the ActiView recording, then run check_soak.m on the BDF.\n', log_file);
end

function save_log(log_file, run_label, ifi, marker_time, marker_code, marker_lag, k)
marker_time = marker_time(1:k); %#ok<NASGU>
marker_code = marker_code(1:k); %#ok<NASGU>
marker_lag  = marker_lag(1:k);  %#ok<NASGU>
save(log_file, 'run_label', 'ifi', 'marker_time', 'marker_code', 'marker_lag');
end

function check_quit(esc)
[down, ~, keys] = KbCheck;
if down && keys(esc)
    error('soak:quit', 'Stopped with ESC.');
end
end
