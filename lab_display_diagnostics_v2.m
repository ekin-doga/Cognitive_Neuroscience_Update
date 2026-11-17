function lab_display_diagnostics_v2()
% LAB_DISPLAY_DIAGNOSTICS_V2  One-click diagnostics for the VIEWPixx / trigger setup.
%
% ===================== HOW TO RUN (no changes needed) =====================
%  1. Set everything up EXACTLY as for your experiment: VIEWPixx on, screen
%     switch set to THIS PC, same refresh rate you normally use (120 Hz).
%     Move the mouse once so the VIEWPixx screen is awake (not blanked).
%  2. Make sure the EEG system is NOT recording anything important.
%  3. In MATLAB, go to the folder with this file and type:
%         lab_display_diagnostics_v2
%  4. If MATLAB says the VIEWPixx receives NO video: check the screen switch,
%     then press Enter to retry. Otherwise don't touch mouse/keyboard
%     (~5-8 minutes). The VIEWPixx will flash grey and colours - expected.
%  5. At the end, the path of a .zip file is printed. Send that zip to Marius.
% ==========================================================================
%
% Changes vs. v1: checks that the VIEWPixx actually receives the video signal
% (incl. dual-link) before and during the test; reads back with an explicit
% line length; logs xrandr for ALL X screens; reads EDIDs correctly; adds a
% 60 s random-colour signal-integrity test; drops the PTB dithering toggle
% (it is a no-op on this GPU: PTB has no low-level access to DCN GPUs).
% Changes in v2.1: also saves kernel messages from earlier boots (back to
% 25 Oct 2026, if the journal keeps them); reads the VIEWPixx status fields
% robustly (a missing field no longer stops the script); always writes the
% summary and the zip, even if something fails.
% Nothing on the PC is changed.

stamp        = datestr(now, 'yyyymmdd_HHMMSS');
startTimeStr = datestr(now, 'yyyy-mm-dd HH:MM:SS');
outDir = fullfile(getenv('HOME'), ['display_diag_v2_' stamp]);
mkdir(outDir);
logFile = fullfile(outDir, 'full_log.txt');
diary(logFile);

R = struct(); R.stamp = stamp;
dpOpen = false;
screenId = max(Screen('Screens'));
oldVerb = Screen('Preference', 'Verbosity', 4);
oldSkip = Screen('Preference', 'SkipSyncTests');

fprintf('\n#### VIEWPixx display diagnostics v2, started %s ####\n', startTimeStr);
fprintf('Output folder: %s\n', outDir);

try
    % ============================================== 1. SYSTEM INFORMATION
    fprintf('\n===== 1. SYSTEM INFO =====\n');
    R.matlab = version;
    R.ptb = tryget(@() PsychtoolboxVersion);
    R.sys.uname   = sh('uname -a');
    R.sys.release = sh('lsb_release -ds 2>/dev/null');
    R.sys.gpu     = sh('lspci -nn | grep -iE "vga|display"');
    R.sys.connectors = sh(['for c in /sys/class/drm/card*-*; do echo "$(basename $c): ' ...
        '$(cat $c/status 2>/dev/null) enabled=$(cat $c/enabled 2>/dev/null)"; done']);
    % xrandr for every X screen (the VIEWPixx is usually NOT on screen 0)
    xcmd = ['B=${DISPLAY%%.*}; for s in 0 1 2 3; do echo "########## X screen $s"; ' ...
            'DISPLAY=$B.$s xrandr --verbose 2>&1 | grep -vE "^\s+[0-9a-f]{32}$"; done'];
    sh(xcmd, fullfile(outDir, 'xrandr_all_screens.txt'));
    R.sys.xrandrShort = sh(['B=${DISPLAY%%.*}; for s in 0 1 2 3; do echo "## X screen $s"; ' ...
        'DISPLAY=$B.$s xrandr --verbose 2>/dev/null | grep -E " connected|max bpc|Colorspace|link-status|\*current| clock .*Hz"; done']);
    R.sys.xdepth = sh('xdpyinfo 2>/dev/null | grep -iE "depth of root"');
    R.sys.glx    = sh('glxinfo -B 2>/dev/null | grep -iE "renderer string|core profile version"');
    % EDIDs: sysfs reports size 0 for these files, so read them directly
    sh(['for c in /sys/class/drm/card*-*; do n=$(cat $c/edid 2>/dev/null | wc -c); ' ...
        'if [ "$n" -gt 0 ]; then echo "===== $(basename $c) ($n bytes)"; ' ...
        'if command -v edid-decode >/dev/null; then edid-decode $c/edid; else od -An -tx1 $c/edid; fi; fi; done'], ...
        fullfile(outDir, 'edid.txt'));
    R.sys.kernelLogAccess = sh(['(journalctl -k -b --no-pager 2>/dev/null; dmesg 2>/dev/null) | ' ...
        'grep -ciE "amdgpu|drm"']);
    sh(['(journalctl -k -b --no-pager 2>/dev/null || dmesg 2>/dev/null) | ' ...
        'grep -iE "amdgpu|drm|hpd|hotplug|link|bpc|dither" | tail -n 400'], fullfile(outDir, 'kernel_log_boot.txt'));
    % Kernel messages from EARLIER boots, covering the faulty sessions
    % (29.10, 02.11, 09.11, 11.11). Only works if the journal is persistent.
    sh('journalctl --list-boots --no-pager 2>&1', fullfile(outDir, 'boot_list.txt'));
    sh(['journalctl -k --since "2026-10-25 00:00:00" --no-pager -o short-iso 2>&1 | ' ...
        'grep -iE "amdgpu|drm|hpd|hotplug|link|bpc|dither|Linux version|journal"'], ...
        fullfile(outDir, 'kernel_log_since_2026-10-25.txt'));
    % Ubuntu's rsyslog keeps its own rotated kernel log (/var/log/kern.log*,
    % usually ~4 weeks), even when the journal is not kept across reboots.
    sh(['ls -l /var/log/kern.log* /var/log/syslog* 2>&1; echo; ' ...
        'zgrep -ihE "amdgpu|drm|hpd|hotplug|link|bpc|dither" /var/log/kern.log* 2>&1 | tail -n 20000'], ...
        fullfile(outDir, 'kern_log_files.txt'));

    % ============================================== 2. VIEWPIXX: IS VIDEO ARRIVING?
    fprintf('\n===== 2. VIEWPIXX STATUS (before opening a PTB window) =====\n');
    Datapixx('Open'); dpOpen = true;
    R.dp.isViewpixx = tryget(@() Datapixx('IsViewpixx'));
    R.dp.firmware   = tryget(@() Datapixx('GetFirmwareRev'));
    for attempt = 1:3
        R.dp.statusBefore = vstatus();
        if receiving(R.dp.statusBefore), break; end
        fprintf(2, ['\n>>> The VIEWPixx reports that it receives NO video signal from this PC.\n' ...
                    '>>> Check that the screen switch is set to this PC and the VIEWPixx shows the desktop.\n']);
        a = input('>>> Press Enter to check again (or type c + Enter to continue anyway): ', 's');
        if strcmpi(strtrim(a), 'c'), break; end
    end
    R.dp.retries = attempt - 1;

    % ============================================== 3. SCREEN + WINDOW
    fprintf('\n===== 3. SCREEN / WINDOW =====\n');
    R.screen.id = screenId;
    R.screen.allScreens = Screen('Screens');
    R.screen.res = Screen('Resolution', screenId);
    R.screen.nominalHz = Screen('NominalFrameRate', screenId, 1);
    Screen('Preference', 'SkipSyncTests', 0);
    try
        win = Screen('OpenWindow', screenId, 0);
        R.syncTestsPassed = true;
    catch e
        R.syncTestsPassed = false; R.syncTestError = e.message;
        sca;   % clean up the failed window before trying again
        Screen('Preference', 'SkipSyncTests', 1);
        win = Screen('OpenWindow', screenId, 0);
    end
    HideCursor(screenId);
    Priority(MaxPriority(win));
    LoadIdentityClut(win);
    R.clut.table = Screen('ReadNormalizedGammaTable', win);
    ifi = Screen('GetFlipInterval', win);
    for i = 1:round(3 / ifi), Screen('Flip', win); end   % 3 s for the VIEWPixx to lock
    R.dp.statusWithWindow = vstatus();
    st = R.dp.statusWithWindow;
    nPix = R.screen.res.width;
    videoOK = receiving(st) && ~(sf(st, 'horizontalResolution') == 0);

    % ============================================== 4. TIMING TEST
    fprintf('\n===== 4. TIMING TEST (~10 s) =====\n');
    nFlips = round(10 / ifi);
    vbl = zeros(nFlips, 1); missed = zeros(nFlips, 1);
    t = Screen('Flip', win);
    for i = 1:nFlips
        Screen('FillRect', win, mod(i, 2) * 128);
        [vbl(i), ~, ~, missed(i)] = Screen('Flip', win, t + 0.5 * ifi);
        t = vbl(i);
    end
    d = diff(vbl);
    R.timing.measuredHz = 1 / ifi;
    R.timing.nFlips = nFlips;
    R.timing.nLateIntervals = sum(d > 1.5 * ifi);
    R.timing.nMissedFlag = sum(missed > 0);

    if videoOK
        % ========================================== 5. READBACK ALL LEVELS
        fprintf('\n===== 5. PIXEL READBACK, all levels (~1-2 min) =====\n');
        R.rb = readback_test(win, ifi, 3, nPix);
        % ========================================== 6. SIGNAL INTEGRITY
        fprintf('\n===== 6. RANDOM-COLOUR SIGNAL INTEGRITY TEST (60 s) =====\n');
        R.integrity = integrity_test(win, 60, nPix);
        R.dp.statusEnd = vstatus();
    else
        R.rb.error = 'SKIPPED: VIEWPixx reports no video input while the PTB window was open';
        fprintf(2, '%s\n', R.rb.error);
    end

    Priority(0); ShowCursor(screenId); sca;
    Datapixx('Close'); dpOpen = false;

    % ============================================== 7. PTB REFERENCE TEST
    if videoOK
        fprintf('\n===== 7. PTB DatapixxGPUDitherpatternTest (~1 min) =====\n');
        try, help DatapixxGPUDitherpatternTest; catch, end   % logs what the argument means
        try
            DatapixxGPUDitherpatternTest(1);
            figs = findobj('Type', 'figure');
            if ~isempty(figs), saveas(figs(1), fullfile(outDir, 'ptb_ditherpattern_plot.png')); end
            R.ptbDitherTest = 'ran (see full_log.txt and plot)';
        catch e
            R.ptbDitherTest = ['error: ' e.message]; sca;
        end
    else
        R.ptbDitherTest = 'skipped (no video at VIEWPixx)';
    end

catch err
    R.fatalError = getReport(err, 'extended', 'hyperlinks', 'off');
    fprintf(2, '\n!!! Diagnostics stopped early:\n%s\n', R.fatalError);
end

try Priority(0); catch, end
try ShowCursor(screenId); catch, end
try sca; catch, end
if dpOpen, try Datapixx('Close'); catch, end, end
Screen('Preference', 'SkipSyncTests', oldSkip);
Screen('Preference', 'Verbosity', oldVerb);
R.kernelDuringTest = sh(sprintf(['journalctl -k --since "%s" --no-pager 2>/dev/null | ' ...
    'grep -iE "amdgpu|drm|hpd|hotplug|link|bpc|dither"'], startTimeStr), ...
    fullfile(outDir, 'kernel_log_during_test.txt'));
diary off;

try
    save(fullfile(outDir, 'results.mat'), 'R');
catch e
    fprintf(2, 'Could not save results.mat: %s\n', e.message);
end
try
    write_summary(R, logFile, fullfile(outDir, 'summary.txt'));
catch e
    fprintf(2, 'Could not write summary.txt: %s\n', e.message);
    fid = fopen(fullfile(outDir, 'summary_ERROR.txt'), 'w');
    fprintf(fid, '%s\n', getReport(e, 'extended', 'hyperlinks', 'off')); fclose(fid);
end
zipFile = [outDir '.zip'];
zip(zipFile, outDir);
fprintf('\n\n######################################################\n');
fprintf('DONE. Please send this file:\n   %s\n', zipFile);
fprintf('######################################################\n');
end

% ==========================================================================
function s = vstatus()
% Reads the VIEWPixx video status. Never throws: if the call or a field is
% missing, the value is logged as NaN and the full struct is printed instead.
try
    Datapixx('RegWrRd');
    s = Datapixx('GetVideoStatus');
    disp(s);   % all fields, whatever they are called, go to the log
catch e
    s = struct('error', e.message);
    fprintf(2, 'GetVideoStatus failed: %s\n', e.message);
end
fprintf('VIEWPixx video: receiving=%g dualLink=%g %gx%g @ %.3f Hz, dotFrequency %g\n', ...
    sf(s, 'receivingVideo'), sf(s, 'receivingDualLinkVideo'), sf(s, 'horizontalResolution'), ...
    sf(s, 'verticalResolution'), sf(s, 'verticalFrequency'), sf(s, 'dotFrequency'));
end

function v = sf(s, name)
% Status field as a number, NaN if it does not exist.
if isstruct(s) && isfield(s, name) && ~isempty(s.(name)) && (isnumeric(s.(name)) || islogical(s.(name)))
    v = double(s.(name)(1));
else
    v = NaN;
end
end

function ok = receiving(s)
% True if the VIEWPixx reports video, or if it cannot tell us (unknown field).
r = sf(s, 'receivingVideo');
ok = isnan(r) || r ~= 0;
end

% ==========================================================================
function pix = readline(nPix)
Datapixx('RegWrRd');
pix = double(Datapixx('GetVideoLine', nPix));
if size(pix, 1) ~= 3, pix = pix'; end
end

% ==========================================================================
function T = readback_test(win, ifi, nReads, nPix)
v = (0:255)'; z = zeros(256, 1);
T.colors = [v v v; v z z; z v z; z z v];
T.chan = [repmat({'grey'}, 256, 1); repmat({'red'}, 256, 1); ...
          repmat({'green'}, 256, 1); repmat({'blue'}, 256, 1)];
n = size(T.colors, 1);
T.nReads = nReads;
T.topLeft = nan(n, 3, nReads);
T.nBadPix = nan(n, nReads);
T.maxErr  = nan(n, nReads);
T.errMask = zeros(n, 3, 'uint8');
T.linePixels = NaN; T.error = '';
try
    for k = 1:n
        expected = T.colors(k, :)';
        for r = 1:nReads
            Screen('FillRect', win, T.colors(k, :));
            Screen('Flip', win);
            WaitSecs(1.2 * ifi);
            pix = readline(nPix);
            if isempty(pix), error('GetVideoLine returned no pixels'); end
            T.linePixels = size(pix, 2);
            err = pix - repmat(expected, 1, size(pix, 2));
            T.topLeft(k, :, r) = pix(:, 1)';
            T.nBadPix(k, r) = sum(any(err ~= 0, 1));
            T.maxErr(k, r) = max(abs(err(:)));
            if T.nBadPix(k, r) > 0
                x = bitxor(uint8(pix), uint8(repmat(expected, 1, size(pix, 2))));
                for c = 1:3
                    u = unique(x(c, :));
                    for q = 1:numel(u), T.errMask(k, c) = bitor(T.errMask(k, c), u(q)); end
                end
            end
        end
        if mod(k, 128) == 0, fprintf('  %d / %d levels\n', k, n); end
    end
catch e
    T.error = e.message;
    fprintf(2, 'Readback error: %s\n', e.message);
end
end

% ==========================================================================
function I = integrity_test(win, durSec, nPix)
% Random colour per readback; counts how often ANY pixel / the top-left pixel
% arrives wrong. Catches rare, random bit errors on the DVI path.
I.nReads = 0; I.nBadLine = 0; I.nBadTopLeft = 0; I.badBits = uint8([0 0 0]);
I.examples = zeros(0, 6); I.error = '';
try
    t0 = GetSecs;
    while GetSecs - t0 < durSec
        c = randi([0 255], 1, 3);
        Screen('FillRect', win, c);
        Screen('Flip', win);
        Screen('Flip', win);          % let one full frame pass on the new colour
        pix = readline(nPix);
        if isempty(pix), error('GetVideoLine returned no pixels'); end
        I.nReads = I.nReads + 1;
        bad = any(pix ~= repmat(c', 1, size(pix, 2)), 1);
        if any(bad)
            I.nBadLine = I.nBadLine + 1;
            x = bitxor(uint8(pix(:, bad)), uint8(repmat(c', 1, sum(bad))));
            for ch = 1:3, I.badBits(ch) = bitor(I.badBits(ch), bitor_all(x(ch, :))); end
        end
        if bad(1)
            I.nBadTopLeft = I.nBadTopLeft + 1;
            if size(I.examples, 1) < 20, I.examples(end+1, :) = [c pix(:, 1)']; end
        end
    end
catch e
    I.error = e.message;
    fprintf(2, 'Integrity test error: %s\n', e.message);
end
end

function m = bitor_all(v)
m = uint8(0);
for q = 1:numel(v), m = bitor(m, v(q)); end
end

% ==========================================================================
function write_summary(R, logFile, outFile)
L = {};
L{end+1} = sprintf('VIEWPixx DISPLAY DIAGNOSTICS v2 - SUMMARY  (%s)', R.stamp);
L{end+1} = repmat('=', 1, 70);
if isfield(R, 'fatalError'), L{end+1} = '!!! SCRIPT STOPPED EARLY:'; L{end+1} = R.fatalError; end
L{end+1} = ['MATLAB: ' tostr(R.matlab) ' | PTB: ' strtok(tostr(fget(R, 'ptb')), sprintf('\n'))];
if isfield(R, 'sys')
    f = fieldnames(R.sys);
    for i = 1:numel(f), L{end+1} = sprintf('[%s]\n%s', f{i}, strtrim(tostr(R.sys.(f{i})))); end
end
L{end+1} = ''; L{end+1} = '--- VIEWPIXX VIDEO INPUT ---';
if isfield(R, 'dp')
    L{end+1} = sprintf('firmware: %s | retries needed: %s', tostr(fget(R.dp, 'firmware')), tostr(fget(R.dp, 'retries')));
    names = {'statusBefore', 'before PTB window'; 'statusWithWindow', 'PTB window open'; 'statusEnd', 'end of tests'};
    for i = 1:size(names, 1)
        if isfield(R.dp, names{i, 1})
            s = R.dp.(names{i, 1});
            L{end+1} = sprintf('%-18s receiving=%g dualLink=%g %gx%g @ %.3f Hz, dotFrequency %g, pixelMode=%g', ...
                names{i, 2}, sf(s, 'receivingVideo'), sf(s, 'receivingDualLinkVideo'), sf(s, 'horizontalResolution'), ...
                sf(s, 'verticalResolution'), sf(s, 'verticalFrequency'), sf(s, 'dotFrequency'), sf(s, 'pixelMode'));
            if isfield(s, 'error'), L{end+1} = ['   GetVideoStatus error: ' s.error]; end
        end
    end
end
if isfield(R, 'screen')
    L{end+1} = ''; L{end+1} = '--- PTB ---';
    L{end+1} = sprintf('PTB screen %d of %s, %d x %d, nominal %.3f Hz, sync tests passed: %d', R.screen.id, ...
        mat2str(R.screen.allScreens), R.screen.res.width, R.screen.res.height, R.screen.nominalHz, fget(R, 'syncTestsPassed'));
end
if isfield(R, 'timing')
    tm = R.timing;
    L{end+1} = sprintf('Timing: %.3f Hz measured, %d flips, %d late intervals, %d flagged missed', ...
        tm.measuredHz, tm.nFlips, tm.nLateIntervals, tm.nMissedFlag);
end
if isfield(R, 'rb')
    if isfield(R.rb, 'colors'), L = [L, summarise_readback(R.rb)];
    else, L{end+1} = ''; L{end+1} = ['READBACK: ' R.rb.error]; end
end
if isfield(R, 'integrity')
    I = R.integrity;
    L{end+1} = ''; L{end+1} = '--- SIGNAL INTEGRITY (random colours) ---';
    if ~isempty(I.error), L{end+1} = ['error: ' I.error]; end
    L{end+1} = sprintf('%d reads: %d with any wrong pixel, %d with wrong top-left pixel, wrong bits R/G/B: %s', ...
        I.nReads, I.nBadLine, I.nBadTopLeft, mat2str(find_bits(I.badBits)));
    for j = 1:size(I.examples, 1)
        L{end+1} = sprintf('  sent %s, top-left read %s', mat2str(I.examples(j, 1:3)), mat2str(I.examples(j, 4:6)));
    end
end
L{end+1} = ''; L{end+1} = ['PTB DatapixxGPUDitherpatternTest: ' tostr(fget(R, 'ptbDitherTest'))];
L{end+1} = ''; L{end+1} = '--- KERNEL MESSAGES DURING TEST ---';
k = strtrim(tostr(fget(R, 'kernelDuringTest'))); if isempty(k), k = '(none, or no permission to read kernel log)'; end
L{end+1} = k;
L{end+1} = ''; L{end+1} = '--- KEY LINES FROM FULL LOG ---';
try
    lines = regexp(fileread(logFile), '\r?\n', 'split');
    pat = 'low-level|LoadIdentityClut|SYNCHRONIZATION|Frame buffer provides|FAILURE|Trouble|WARNING|ERROR|error|VIEWPixx video';
    hit = lines(~cellfun(@isempty, regexp(lines, pat, 'once')) & cellfun(@numel, lines) < 400);
    [~, iu] = unique(hit, 'stable'); hit = hit(iu);
    L = [L, hit(1:min(60, end))];
catch
end
fid = fopen(outFile, 'w'); fprintf(fid, '%s\n', L{:}); fclose(fid);
end

function b = find_bits(m)
b = cell(1, 3);
for c = 1:3, b{c} = find(bitget(m(c), 1:8)) - 1; end
b = sprintf('R%s G%s B%s', mat2str(b{1}), mat2str(b{2}), mat2str(b{3}));
end

% ==========================================================================
function L = summarise_readback(T)
L = {'', '--- READBACK, all 256 levels per channel ---'};
if ~isempty(T.error), L{end+1} = ['Readback error: ' T.error]; end
L{end+1} = sprintf('Pixels per read line: %d, reads per level: %d', T.linePixels, T.nReads);
sets = {'grey', 'red', 'green', 'blue'};
examples = {};
for s = 1:4
    idx = find(strcmp(T.chan, sets{s}));
    done = all(~isnan(T.nBadPix(idx, :)), 2);
    bad = any(T.nBadPix(idx, :) > 0, 2);
    tl = T.topLeft(idx, :, :);
    expd = repmat(T.colors(idx, :), [1 1 T.nReads]);
    tlBad = squeeze(any(any(tl ~= expd, 2), 3)) & done;
    tlVar = squeeze(any(any(diff(tl, 1, 3) ~= 0, 2), 3)) & done;
    mask = uint8(0);
    for q = idx', mask = bitor(mask, bitor(bitor(T.errMask(q, 1), T.errMask(q, 2)), T.errMask(q, 3))); end
    trunc = NaN;
    if any(tlBad)
        b = find(tlBad); ok = false(numel(b), 1);
        for j = 1:numel(b)
            g = squeeze(tl(b(j), :, :))';
            ok(j) = all(all(g == repmat(bitand(T.colors(idx(b(j)), :), 252), size(g, 1), 1)));
        end
        trunc = mean(ok);
    end
    L{end+1} = sprintf(['%-5s: tested %3d | any wrong pixel: %3d | top-left wrong: %3d | top-left varies ' ...
        'between reads: %3d | max error: %g | wrong bits: %s | matches 6-bit truncation: %s'], ...
        sets{s}, sum(done), sum(bad & done), sum(tlBad), sum(tlVar), max(T.maxErr(idx, :), [], 'all'), ...
        mat2str(find(bitget(mask, 1:8)) - 1), num2str(trunc, 3));
    for j = find(tlBad)'
        if numel(examples) >= 15, break; end
        examples{end+1} = sprintf('  %s level %3d: expected %s, top-left reads %s', sets{s}, j - 1, ...
            mat2str(T.colors(idx(j), :)), mat2str(squeeze(tl(j, :, :))')); %#ok<AGROW>
    end
end
if ~isempty(examples), L{end+1} = 'Examples of wrong top-left pixel (one row per read):'; L = [L, examples]; end
end

% ==========================================================================
function out = sh(cmd, saveTo)
[~, out] = system(['unset LD_LIBRARY_PATH; ' cmd]);
if nargin > 1 && ~isempty(saveTo)
    fid = fopen(saveTo, 'w'); fwrite(fid, out); fclose(fid);
    fprintf('$ %s\n  -> saved to %s\n', cmd, saveTo);
else
    fprintf('$ %s\n%s\n', cmd, out);
end
end

function v = tryget(f)
try, v = f(); catch e, v = ['n/a (' e.message ')']; end
end

function v = fget(S, name)
if isfield(S, name), v = S.(name); else, v = '(not reached)'; end
end

function s = tostr(x)
if ischar(x), s = x;
elseif isnumeric(x) || islogical(x), s = mat2str(x);
else, s = evalc('disp(x)');
end
end
