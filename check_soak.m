% check_soak.m
%
% Counts false trigger codes in a recording made with test_trigger_soak.m.
% Reads the Status channel of the BDF directly, so EEGLAB is not needed.
%
% A run goes from marker 210 to marker 211. One BDF can hold several runs,
% and each is reported separately. A run counts as CLEAN when it has no codes
% other than the markers and no marker is missing.
%
% Usage: set bdf_file below, then run.

clear; clc;

bdf_file = '/Users/ekindogailkel/Trigger_problem/soak_run.bdf';

marker_every_s = 2;       % as in test_trigger_soak.m
bin_min        = 10;      % width of the time bins for false codes
TRIG_SHIFT     = 8;       % experiment code is in Status bits 8-15

MARK_STATIC = 201;
MARK_FLIP   = 202;
MARK_START  = 210;
MARK_END    = 211;

[status, fs] = read_bdf_status(bdf_file);
code = double(bitand(bitshift(status, -TRIG_SHIFT), uint32(255)));
hw   = double(bitand(status, uint32(255)));

seg_start = [1; find(diff(code) ~= 0) + 1];
seg_end   = [seg_start(2:end) - 1; numel(code)];
seg_code  = code(seg_start);
seg_dur   = seg_end - seg_start + 1;

fprintf('%s\n%.1f min at %g Hz\n', bdf_file, numel(code) / fs / 60, fs);

%% Find the runs
starts = seg_start(seg_code == MARK_START);
ends   = seg_start(seg_code == MARK_END);
if isempty(starts)
    warning('No start marker (%d) found: treating the whole file as one run.', MARK_START);
    starts = 1;
end

for r = 1:numel(starts)
    a = starts(r);
    if r < numel(starts)
        limit = starts(r + 1) - 1;
    else
        limit = numel(code);
    end
    b = ends(find(ends > a & ends <= limit, 1));
    if isempty(b)
        warning('Run %d has no end marker (%d): using the data up to %.1f min.', ...
            r, MARK_END, limit / fs / 60);
        b = limit;
    end

    in_run = seg_start > a & seg_start < b & seg_code > 0;
    lat    = seg_start(in_run);
    cod    = seg_code(in_run);
    dur    = seg_dur(in_run);

    is_marker = cod == MARK_STATIC | cod == MARK_FLIP | cod == MARK_START | cod == MARK_END;
    mark_lat  = lat(is_marker);
    mark_cod  = cod(is_marker);

    false_lat = lat(~is_marker);
    false_cod = cod(~is_marker);
    false_dur = dur(~is_marker);

    % a gap of n marker intervals means n - 1 markers are missing
    gaps      = round(diff(mark_lat) / fs / marker_every_s);
    n_missing = sum(gaps(gaps > 1) - 1);

    run_min = (b - a) / fs / 60;
    fprintf('\n=== Run %d: %.1f to %.1f min of the file (%.1f min) ===\n', ...
        r, a / fs / 60, b / fs / 60, run_min);
    if isempty(false_lat) && n_missing == 0
        fprintf('  Result          : CLEAN\n');
    else
        fprintf('  Result          : FALSE CODES OR MISSING MARKERS\n');
    end
    fprintf('  Markers found   : %d (missing: %d)\n', numel(mark_lat), n_missing);
    fprintf('  False code runs : %d\n', numel(false_lat));

    if ~isempty(false_lat)
        t_min = (false_lat - a) / fs / 60;
        fprintf('  First false code: %.1f min after the run started\n', t_min(1));
        fprintf('  Time on false   : %.1f s in total, longest %.2f s\n', ...
            sum(false_dur) / fs, max(false_dur) / fs);

        fprintf('\n  %-6s %8s %12s %12s\n', 'Code', 'Runs', 'Total (s)', 'First (min)');
        for c = unique(false_cod)'
            m = false_cod == c;
            fprintf('  %-6d %8d %12.2f %12.1f\n', c, sum(m), sum(false_dur(m)) / fs, min(t_min(m)));
        end

        % phase = the marker before the false code
        phase = zeros(size(false_lat));
        for k = 1:numel(false_lat)
            i = find(mark_lat <= false_lat(k), 1, 'last');
            if ~isempty(i)
                phase(k) = mark_cod(i);
            end
        end
        fprintf('\n  By phase: static %d, flipping %d, before the first marker %d\n', ...
            sum(phase == MARK_STATIC), sum(phase == MARK_FLIP), sum(phase == 0));

        edges = 0:bin_min:(ceil(run_min / bin_min) * bin_min);
        fprintf('  Per %d min      : %s\n', bin_min, mat2str(histcounts(t_min, edges)));
    end

    hw_run = hw(a:b);
    fprintf('\n  Hardware bits 0-7: %.2f%% of samples at %d, %d changes\n', ...
        100 * mean(hw_run == mode(hw_run)), mode(hw_run), sum(diff(hw_run) ~= 0));
end


function [status, fs] = read_bdf_status(file)
% READ_BDF_STATUS - Returns the 24-bit Status channel as uint32 and its sample rate
fid = fopen(file, 'r', 'ieee-le');
if fid < 0
    error('Could not open %s', file);
end
closer = onCleanup(@() fclose(fid));

hdr     = fread(fid, 256, '*char')';
n_rec   = str2double(hdr(237:244));
rec_dur = str2double(hdr(245:252));
n_ch    = str2double(hdr(253:256));
labels  = cellstr(fread(fid, [16, n_ch], '*char')');
fseek(fid, 256 + 216 * n_ch, 'bof');
ns      = str2double(cellstr(fread(fid, [8, n_ch], '*char')'));
idx     = find(strcmpi(strtrim(labels), 'Status'), 1);
if isempty(idx)
    error('No Status channel in %s', file);
end

data_start = 256 * (n_ch + 1);
rec_bytes  = 3 * sum(ns);
skip       = 3 * sum(ns(1:idx - 1));
n_s        = ns(idx);
fs         = n_s / rec_dur;

status = zeros(n_rec * n_s, 1, 'uint32');
for r = 1:n_rec
    fseek(fid, data_start + (r - 1) * rec_bytes + skip, 'bof');
    b = uint32(fread(fid, 3 * n_s, '*uint8'));
    status((r - 1) * n_s + (1:n_s)) = b(1:3:end) + b(2:3:end) * 256 + b(3:3:end) * 65536;
end
end
