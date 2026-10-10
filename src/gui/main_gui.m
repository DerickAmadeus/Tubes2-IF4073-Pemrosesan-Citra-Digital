function main()
% MAIN  Satu GUI untuk semua bagian tugas IF4073 (B sampai F).
%
%   Cara pakai:  main          (dari folder mana saja, path diatur otomatis)
%
%   Tab:
%     B  Low-pass     : ILPF, GLPF, BLPF
%     C  High-pass    : IHPF, GHPF, BHPF
%     D  Brightness   : peningkatan kecerahan di ranah frekuensi
%     E  Periodic     : bandreject (3 jenis) dan notch reject (3 jenis)
%     F  Motion blur  : inverse filtering dan Wiener filtering
%
%   Setiap parameter angka punya SLIDER dan KOTAK ANGKA yang saling terhubung.
%   Tidak ada tombol terapkan: hasil dihitung ulang otomatis saat slider
%   digeser atau dilepas, angka diketik, atau pilihan diganti.
%
%   Fungsi yang dipanggil (harus ada di src/functions dan src/utils):
%     [out,H,spec] = lowpass_filter(img, type, D0, n)
%     [out,H,spec] = highpass_filter(img, type, D0, n, displayMode)
%     [out,H,spec] = enhance_brightness(img, params)
%     [out,H]      = bandreject_filter(img, D0, W, type, n)
%     [out,H]      = notch_reject_filter(img, centers, D0, type, n)
%     PSF          = motion_blur_psf(len, theta)  atau  [~,PSF] = motion_blur_psf(img, len, theta)
%     [out,H]      = inverse_filter(img, PSF, radius, threshold)
%     [out,H,W]    = wiener_filter(img, PSF, K)

    % ---- path: tambahkan seluruh folder src ---------------------------
    here = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(here, '..')));

    dataDir = fullfile(here, '..', '..', 'data');
    if ~isfolder(dataDir)
        dataDir = pwd;
    end

    % ---- keadaan aplikasi ---------------------------------------------
    img = imread('cameraman.tif');     % citra bawaan supaya GUI langsung bisa dicoba
    ref = [];                          % citra acuan (opsional)

    % ---- jendela utama ------------------------------------------------
    fig = uifigure('Name', 'Pemrosesan Citra Ranah Frekuensi - IF4073', ...
                   'Position', [40 40 1320 760]);
    root = uigridlayout(fig, [3 1]);
    root.RowHeight = {40, '1x', 28};
    root.Padding = [8 8 8 8];
    root.RowSpacing = 6;

    % baris atas: tombol buka citra + pilihan terapkan otomatis
    top = uigridlayout(root, [1 4]);
    top.Layout.Row = 1;
    top.ColumnWidth = {130, 160, 260, '1x'};
    top.Padding = [0 0 0 0];
    uibutton(top, 'push', 'Text', 'Buka citra', ...
             'ButtonPushedFcn', @(~, ~) loadImage());
    btnRef = uibutton(top, 'push', 'Text', 'Buka citra acuan', ...
             'ButtonPushedFcn', @(~, ~) loadReference());
    chkLive = uicheckbox(top, 'Text', 'Langsung saat slider digeser', 'Value', true);
    lblName = uilabel(top, 'Text', 'Citra: cameraman.tif (bawaan)');

    % badan: kiri = tab kontrol + hasil + pratinjau, kanan = 6 kotak gambar
    body = uigridlayout(root, [1 2]);
    body.Layout.Row = 2;
    body.ColumnWidth = {400, '1x'};
    body.Padding = [0 0 0 0];

    left = uigridlayout(body, [3 1]);
    left.Layout.Column = 1;
    left.RowHeight = {'1x', 120, 210};
    left.Padding = [0 0 0 0];
    left.RowSpacing = 6;

    tabs = uitabgroup(left);
    tabs.Layout.Row = 1;
    tabs.SelectionChangedFcn = @(~, ~) onTabChange();

    % kotak hasil pengukuran (PSNR, rata-rata terang): besar dan mudah dibaca
    resultPanel = uipanel(left, 'Title', 'Hasil pengukuran', 'FontWeight', 'bold', ...
                          'FontSize', 13);
    resultPanel.Layout.Row = 2;
    rg = uigridlayout(resultPanel, [1 1]);
    rg.Padding = [10 6 10 6];
    resultLbl = uilabel(rg, 'Text', {'-'}, 'FontSize', 16, 'FontWeight', 'bold', ...
                        'WordWrap', 'on', 'VerticalAlignment', 'center');

    % pratinjau tetap: citra masukan dan citra acuan
    preview = uigridlayout(left, [1 2]);
    preview.Layout.Row = 3;
    preview.Padding = [0 0 0 0];
    axIn = uiaxes(preview);
    axIn.Layout.Column = 1;
    axRef = uiaxes(preview);
    axRef.Layout.Column = 2;

    right = uigridlayout(body, [2 3]);
    right.Layout.Column = 2;
    right.Padding = [0 0 0 0];
    ax = gobjects(1, 6);
    for k = 1:6
        ax(k) = uiaxes(right);
        ax(k).Layout.Row = ceil(k / 3);
        ax(k).Layout.Column = mod(k - 1, 3) + 1;
    end

    % baris bawah: petunjuk singkat
    status = uilabel(root, 'Text', 'Siap.');
    status.Layout.Row = 3;

    % ================= TAB B : LOW-PASS ================================
    tB = uitab(tabs, 'Title', 'B Low-pass');
    gB = makeGrid(tB, 4);
    ddB = makeDropdown(gB, 1, 'Jenis', {'ideal', 'gaussian', 'butterworth'}, 'gaussian', @autoRun);
    d0B = makeSliderNumber(gB, 2, 'D0 (radius)', 30, [1 5000], [1 300], 0, @autoRun);
    nB  = makeSliderNumber(gB, 3, 'Orde n (Butterworth)', 2, [1 50], [1 20], 0, @autoRun);

    % ================= TAB C : HIGH-PASS ===============================
    tC = uitab(tabs, 'Title', 'C High-pass');
    gC = makeGrid(tC, 5);
    ddC = makeDropdown(gC, 1, 'Jenis', {'ideal', 'gaussian', 'butterworth'}, 'gaussian', @autoRun);
    d0C = makeSliderNumber(gC, 2, 'D0 (radius)', 30, [1 5000], [1 300], 0, @autoRun);
    nC  = makeSliderNumber(gC, 3, 'Orde n (Butterworth)', 2, [1 50], [1 20], 0, @autoRun);
    ddViewC = makeDropdown(gC, 4, 'Tampilan hasil', ...
        {'Potong (latar hitam)', 'Regangkan (latar abu-abu)', 'Nilai mutlak'}, ...
        'Potong (latar hitam)', @autoRun);

    % ================= TAB D : BRIGHTNESS ==============================
    tD = uitab(tabs, 'Title', 'D Brightness');
    gD = makeGrid(tD, 6);
    ddD     = makeDropdown(gD, 1, 'Metode', {'lowboost', 'dc', 'homomorphic'}, 'lowboost', @autoRun);
    gainD   = makeSliderNumber(gD, 2, 'Gain (lowboost, dc)', 3, [0.1 50], [0.1 10], 1, @autoRun);
    d0D     = makeSliderNumber(gD, 3, 'D0 (radius)', 30, [1 5000], [1 300], 0, @autoRun);
    gammaLD = makeSliderNumber(gD, 4, 'gammaL (homomorphic)', 1.5, [0.1 10], [0.1 5], 1, @autoRun);
    gammaHD = makeSliderNumber(gD, 5, 'gammaH (homomorphic)', 1.0, [0.1 10], [0.1 5], 1, @autoRun);
    % ================= TAB E : DERAU PERIODIK ==========================
    tE = uitab(tabs, 'Title', 'E Periodic noise');
    gE = makeGrid(tE, 9);
    ddModeE = makeDropdown(gE, 1, 'Filter', {'notch', 'bandreject'}, 'notch', @autoRun);
    ddTypeE = makeDropdown(gE, 2, 'Jenis', {'gaussian', 'butterworth', 'ideal'}, 'gaussian', @autoRun);
    d0E     = makeSliderNumber(gE, 3, 'D0 (radius)', 10, [0.5 5000], [1 100], 1, @autoRun);
    wE      = makeSliderNumber(gE, 4, 'W (lebar, bandreject)', 10, [0.5 5000], [1 100], 0, @autoRun);
    nE      = makeSliderNumber(gE, 5, 'Orde n (Butterworth)', 2, [1 50], [1 20], 0, @autoRun);
    edCent  = makeText(gE, 6, 'Titik notch [baris kolom]', '35 40; 20 -50', @autoRun);
    makeButton(gE, 7, 'Tampilkan spektrum saja', @(~, ~) runSpectrumE());
    makeHint(gE, 8, ['Cara membaca titik: arahkan kursor ke bintik terang di spektrum. ' ...
                     'Sumbu sudah berupa jarak dari pusat. Y = baris, X = kolom. ' ...
                     'Isi sebagai "Y X". Pasangan simetrisnya ditambah otomatis, ' ...
                     'jadi cukup tulis satu dari tiap pasang. Pisahkan titik dengan titik koma.'], 110);

    % ================= TAB F : MOTION BLUR =============================
    tF = uitab(tabs, 'Title', 'F Motion blur');
    gF = makeGrid(tF, 7);
    lenF = makeSliderNumber(gF, 1, 'Panjang blur (piksel)', 15, [1 500], [1 100], 0, @autoRun);
    angF = makeSliderNumber(gF, 2, 'Sudut (derajat)', 0, [-360 360], [-180 180], 0, @autoRun);
    radF = makeSliderNumber(gF, 3, 'Radius inverse (0 = otomatis)', 0, [0 5000], [0 300], 0, @autoRun);
    thrF = makeSliderNumber(gF, 4, 'Threshold |H| inverse', 0.05, [0 1], [1e-4 1], 'log', @autoRun);
    kF   = makeSliderNumber(gF, 5, 'K (NSR) Wiener', 0.01, [0 10], [1e-4 1], 'log', @autoRun);
    makeHint(gF, 6, ['Panjang dan sudut blur terisi otomatis dari nama berkas ' ...
                     '(contoh: ..._L17_A0.png). Threshold dan K memakai slider logaritmik.'], 60);

    onTabChange();     % tampilkan citra awal

    % ======================================================================
    %  CALLBACK  (fungsi bersarang: boleh memakai img, ref, ax, status ...)
    % ======================================================================

    function loadImage()
        [f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Citra'}, ...
                           'Pilih citra', [dataDir filesep]);
        figure(fig);
        if isequal(f, 0), return; end
        try
            img = readImg(fullfile(p, f));
            lblName.Text = ['Citra: ' f];

            % nama berkas bagian F memuat parameter, contoh: ..._motion_L17_A0.png
            tok = regexp(f, 'L(\d+(?:\.\d+)?)_A(-?\d+(?:\.\d+)?)', 'tokens', 'once');
            if ~isempty(tok)
                lenF.Value = str2double(tok{1});
                angF.Value = str2double(tok{2});
                lenF.UserData(lenF.Value);      % gerakkan slider ikut angkanya
                angF.UserData(angF.Value);
            end

            onTabChange();
        catch err
            uialert(fig, err.message, 'Gagal membuka citra');
        end
    end

    function loadReference()
        [f, p] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Citra'}, ...
                           'Pilih citra acuan', [dataDir filesep]);
        figure(fig);
        if isequal(f, 0), return; end
        try
            ref = readImg(fullfile(p, f));
            updatePreview();
            status.Text = ['Citra acuan dimuat: ' f ' (PSNR dihitung setelah restorasi).'];
        catch err
            uialert(fig, err.message, 'Gagal membuka citra acuan');
        end
    end

    function onTabChange()
        updatePreview();
        resultLbl.Text = {'-'};
        resetAxes();
        show(ax(1), img, 'Citra masukan');
        status.Text = 'Geser slider atau ubah angka: hasil langsung diperbarui.';
        runCurrent();
    end

    function autoRun(isLive)
        % dipanggil saat slider digeser (isLive = true), dilepas,
        % atau saat angka / pilihan diubah
        if nargin < 1, isLive = false; end
        if isLive && ~chkLive.Value, return; end
        runCurrent();
    end

    function runCurrent()
        % jalankan perhitungan untuk tab yang sedang terbuka
        sel = tabs.SelectedTab;
        if isequal(sel, tB)
            runLowpass();
        elseif isequal(sel, tC)
            runHighpass();
        elseif isequal(sel, tD)
            runBrightness();
        elseif isequal(sel, tE)
            runPeriodic();
        elseif isequal(sel, tF)
            runMotion();
        end
    end

    function runLowpass()
        try
            [out, H, spec] = lowpass_filter(img, ddB.Value, d0B.Value, nB.Value);
            resetAxes();
            show(ax(1), img, 'Citra masukan');
            show(ax(2), out, sprintf('Hasil low-pass %s, D0=%g', ddB.Value, d0B.Value));
            showScaled(ax(3), H, 'Mask H(u,v)');
            show(ax(4), show_spectrum(img, true), 'Spektrum sebelum');
            show(ax(5), spec, 'Spektrum sesudah');
            reportPSNR({'hasil'}, {out}, '');
        catch err
            disp(getReport(err));      % cetak lokasi error lengkap di command window
            uialert(fig, err.message, 'Error');
        end
    end

    function runHighpass()
        try
            viewModes = {'clip', 'stretch', 'abs'};
            viewMode = viewModes{strcmp(ddViewC.Value, ddViewC.Items)};
            [out, H, spec] = highpass_filter(img, ddC.Value, d0C.Value, nC.Value, viewMode);
            resetAxes();
            show(ax(1), img, 'Citra masukan');
            show(ax(2), out, sprintf('Hasil high-pass %s, D0=%g', ddC.Value, d0C.Value));
            showScaled(ax(3), H, 'Mask H(u,v)');
            show(ax(4), show_spectrum(img, true), 'Spektrum sebelum');
            show(ax(5), spec, 'Spektrum sesudah');
            % bagian C tidak memakai citra acuan, jadi tidak ada PSNR
            status.Text = sprintf(['Selesai: high-pass %s, D0=%g. ' ...
                'Ganti jenis (ideal, gaussian, butterworth) untuk membandingkan IHPF, GHPF, BHPF.'], ...
                ddC.Value, d0C.Value);
        catch err
            disp(getReport(err));
            uialert(fig, err.message, 'Error');
        end
    end

    function runBrightness()
        try
            p.method = ddD.Value;
            p.gain   = gainD.Value;
            p.D0     = d0D.Value;
            p.gammaL = gammaLD.Value;
            p.gammaH = gammaHD.Value;
            [out, H, spec] = enhance_brightness(img, p);
            resetAxes();
            show(ax(1), img, 'Citra masukan');
            show(ax(2), out, sprintf('Hasil brightness (%s)', p.method));
            showScaled(ax(3), H, 'Mask H(u,v)');
            show(ax(4), show_spectrum(img, true), 'Spektrum sebelum');
            show(ax(5), spec, 'Spektrum sesudah');
            if ~isempty(ref)
                show(ax(6), ref, 'Citra acuan');
            end
            extra = sprintf('Terang rata-rata: %.3f -> %.3f', ...
                            mean(im2double(img(:))), mean(im2double(out(:))));
            reportPSNR({'hasil'}, {out}, extra);
        catch err
            disp(getReport(err));
            uialert(fig, err.message, 'Error');
        end
    end

    function runSpectrumE()
        try
            resetAxes();
            show(ax(1), img, 'Citra terdegradasi');
            showSpecOffset(ax(2), img, 'Spektrum (sumbu = jarak dari pusat)');
            status.Text = 'Cari bintik terang yang tidak wajar, catat X (kolom) dan Y (baris).';
        catch err
            disp(getReport(err));
            uialert(fig, err.message, 'Error');
        end
    end

    function runPeriodic()
        try
            switch ddModeE.Value
                case 'notch'
                    centers = parseCenters(edCent.Value);
                    [out, H] = notch_reject_filter(img, centers, d0E.Value, ...
                                                   ddTypeE.Value, nE.Value);
                    ttl = sprintf('Notch %s, D0=%g', ddTypeE.Value, d0E.Value);
                case 'bandreject'
                    [out, H] = bandreject_filter(img, d0E.Value, wE.Value, ...
                                                 ddTypeE.Value, nE.Value);
                    ttl = sprintf('Bandreject %s, D0=%g, W=%g', ddTypeE.Value, ...
                                  d0E.Value, wE.Value);
            end
            resetAxes();
            show(ax(1), img, 'Citra terdegradasi');
            showSpecOffset(ax(2), img, 'Spektrum sebelum');
            showScaled(ax(3), H, ['Mask: ' ttl]);
            showSpecOffset(ax(4), out, 'Spektrum sesudah');
            show(ax(5), out, 'Hasil restorasi');
            noise = abs(im2double(img) - im2double(out));
            showScaled(ax(6), noise, 'Derau yang dibuang');
            reportPSNR({'hasil'}, {out}, '');
        catch err
            disp(getReport(err));
            uialert(fig, err.message, 'Error');
        end
    end

    function runMotion()
        try
            len = lenF.Value;
            ang = angF.Value;

            % membuat PSF (mendukung dua gaya pemanggilan motion_blur_psf)
            if nargin('motion_blur_psf') == 2
                PSF = motion_blur_psf(len, ang);
            else
                [~, PSF] = motion_blur_psf(img, len, ang);
            end

            rad = radF.Value;
            if rad <= 0
                rad = [];
                radText = 'otomatis';
            else
                radText = sprintf('%g', rad);
            end

            outI = inverse_filter(img, PSF, rad, thrF.Value);
            outW = wiener_filter(img, PSF, kF.Value);

            resetAxes();
            if ~isempty(ref)
                show(ax(1), ref, 'Citra acuan');
            else
                ax(1).XTick = [];
                ax(1).YTick = [];
                title(ax(1), 'Citra acuan: belum dimuat');
            end
            show(ax(2), img, 'Citra terdegradasi');
            showScaled(ax(3), PSF, sprintf('PSF: panjang %g, sudut %g', len, ang));
            show(ax(4), show_spectrum(img, true), 'Spektrum citra terdegradasi');
            show(ax(5), outI, sprintf('Inverse: radius %s, thr %g', radText, thrF.Value));
            show(ax(6), outW, sprintf('Wiener: K = %g', kF.Value));
            reportPSNR({'inverse', 'wiener'}, {outI, outW}, '');
        catch err
            disp(getReport(err));
            uialert(fig, err.message, 'Error');
        end
    end

    % ======================================================================
    %  PEMBANTU TAMPILAN
    % ======================================================================

    function updatePreview()
        % pratinjau tetap: citra masukan dan citra acuan (tidak ikut dihapus resetAxes)
        cla(axIn);
        axIn.Visible = 'on';
        imshow(img, 'Parent', axIn);
        title(axIn, ['Citra masukan: ' size2text(img)]);

        % tab C (high-pass) tidak punya citra acuan: sembunyikan tombol dan kotaknya
        if isequal(tabs.SelectedTab, tC)
            btnRef.Visible = 'off';
            preview.ColumnWidth = {'1x', 0};
            cla(axRef);
            axRef.Visible = 'off';
            return
        end
        btnRef.Visible = 'on';
        preview.ColumnWidth = {'1x', '1x'};

        cla(axRef);
        axRef.Visible = 'on';
        if isempty(ref)
            axRef.XTick = [];
            axRef.YTick = [];
            title(axRef, 'Citra acuan: belum dimuat');
        else
            imshow(ref, 'Parent', axRef);
            title(axRef, ['Citra acuan: ' size2text(ref)]);
        end
    end

    function resetAxes()
        for kk = 1:6
            cla(ax(kk));
            title(ax(kk), '');
            ax(kk).Visible = 'on';
            ax(kk).XTickMode = 'auto';
            ax(kk).YTickMode = 'auto';
            ax(kk).XTickLabelMode = 'auto';
            ax(kk).YTickLabelMode = 'auto';
        end
    end

    function show(a, im, ttl)
        imshow(im, 'Parent', a);
        title(a, ttl);
    end

    function showScaled(a, im, ttl)
        imshow(im, [], 'Parent', a);
        title(a, ttl);
    end

    function showSpecOffset(a, im, ttl)
        % spektrum dengan sumbu = jarak dari pusat (cocok dengan titik notch)
        S = show_spectrum(im, true);
        [M, N] = size(S);
        cr = floor(M / 2) + 1;
        cc = floor(N / 2) + 1;
        imagesc(a, [1 - cc, N - cc], [1 - cr, M - cr], S);
        colormap(a, 'gray');
        axis(a, 'image');
        title(a, ttl);
    end

    function reportPSNR(names, outs, extra)
        lines = {};
        if ~isempty(strtrim(extra))
            lines{end+1} = strtrim(extra);
        end
        if isempty(ref)
            lines{end+1} = 'Acuan belum dimuat (PSNR tidak dihitung).';
        else
            for kk = 1:numel(outs)
                try
                    lines{end+1} = sprintf('%s: PSNR %.2f dB', names{kk}, ...
                        psnr(im2uint8(outs{kk}), im2uint8(ref)));
                catch
                    lines{end+1} = sprintf('%s: ukuran/jenis berbeda dengan acuan', names{kk});
                end
            end
        end
        resultLbl.Text = lines;
    end
end

% ==========================================================================
%  FUNGSI LOKAL (tidak memakai keadaan aplikasi)
% ==========================================================================

function g = makeGrid(tab, n)
    g = uigridlayout(tab, [n 2]);
    g.ColumnWidth = {130, '1x'};
    rh = repmat({36}, 1, n);
    rh{n} = '1x';
    g.RowHeight = rh;
    g.Padding = [8 8 8 8];
    g.RowSpacing = 8;
    g.Scrollable = 'on';          % isi tab bisa digulir kalau tidak muat
end

function c = makeDropdown(g, r, labelText, items, value, onChange)
    if nargin < 6, onChange = []; end
    l = uilabel(g, 'Text', labelText);
    l.Layout.Row = r;
    l.Layout.Column = 1;
    c = uidropdown(g, 'Items', items, 'Value', value);
    c.Layout.Row = r;
    c.Layout.Column = 2;
    if ~isempty(onChange)
        c.ValueChangedFcn = @(~, ~) onChange();
    end
end

function c = makeSliderNumber(g, r, labelText, value, limits, slim, mode, onChange)
% Satu baris: label + SLIDER + KOTAK ANGKA yang saling terhubung.
%   limits : batas kotak angka (boleh lebih lebar dari slider)
%   slim   : jangkauan slider
%   mode   : 0 = bilangan bulat, 1 = kelipatan 0.1, 2 = kelipatan 0.01,
%            'log' = slider logaritmik (3 angka penting)
%   onChange : (opsional) fungsi tanpa argumen, dipanggil setelah nilai berubah
% Keluaran: kotak angka. Pakai c.Value untuk membaca nilainya.
% Kalau nilainya diubah lewat kode, panggil c.UserData(c.Value) agar slider ikut.
    if nargin < 8, onChange = []; end

    l = uilabel(g, 'Text', labelText, 'WordWrap', 'on');
    l.Layout.Row = r;
    l.Layout.Column = 1;

    sub = uigridlayout(g, [1 2]);
    sub.Layout.Row = r;
    sub.Layout.Column = 2;
    sub.ColumnWidth = {'1x', 72};
    sub.Padding = [0 0 0 0];
    sub.ColumnSpacing = 10;

    isLog = ischar(mode) && strcmp(mode, 'log');
    if isLog
        toS = @(v) log10(min(max(v, slim(1)), slim(2)));
        sl  = log10(slim);
    else
        toS = @(v) min(max(v, slim(1)), slim(2));
        sl  = slim;
    end

    s = uislider(sub, 'Limits', sl, 'Value', toS(value));
    s.Layout.Column = 1;
    s.MajorTicks = [];
    s.MinorTicks = [];

    c = uieditfield(sub, 'numeric', 'Value', value, 'Limits', limits, ...
                    'ValueDisplayFormat', '%.4g');
    c.Layout.Column = 2;
    c.UserData = @(v) set(s, 'Value', toS(v));

    % saat slider DIGESER: angka ikut berubah, dan gambar dihitung ulang langsung
    s.ValueChangingFcn = @(~, ev) sliderMoving(ev, c, mode, onChange);
    % saat slider dilepas atau angka diketik: sinkronkan lalu panggil onChange
    s.ValueChangedFcn  = @(src, ~) sliderDone(src, c, mode, onChange);
    c.ValueChangedFcn  = @(src, ~) editDone(src, onChange);
end

function v = sliderToValue(sv, mode)
    if ischar(mode) && strcmp(mode, 'log')
        v = str2double(sprintf('%.3g', 10 ^ sv));
    else
        v = round(sv * 10 ^ mode) / 10 ^ mode;
    end
end

function sliderMoving(ev, c, mode, onChange)
    % Dipanggil berkali-kali saat slider digeser. Angka selalu diperbarui,
    % tetapi gambar hanya dihitung ulang kalau perhitungan sebelumnya sudah
    % selesai lebih dari 0.12 detik lalu (supaya tidak menumpuk dan macet).
    persistent tEnd
    c.Value = sliderToValue(ev.Value, mode);
    if isempty(onChange), return; end
    if isempty(tEnd) || toc(tEnd) > 0.12
        onChange(true);
        tEnd = tic;
    end
end

function sliderDone(src, c, mode, onChange)
    c.Value = sliderToValue(src.Value, mode);
    if ~isempty(onChange), onChange(); end
end

function editDone(src, onChange)
    src.UserData(src.Value);          % gerakkan slider ke angka yang diketik
    if ~isempty(onChange), onChange(); end
end

function c = makeText(g, r, labelText, value, onChange)
    if nargin < 5, onChange = []; end
    l = uilabel(g, 'Text', labelText);
    l.Layout.Row = r;
    l.Layout.Column = 1;
    l.WordWrap = 'on';
    c = uieditfield(g, 'text', 'Value', value);
    c.Layout.Row = r;
    c.Layout.Column = 2;
    if ~isempty(onChange)
        c.ValueChangedFcn = @(~, ~) onChange();
    end
end

function b = makeButton(g, r, txt, cb)
    b = uibutton(g, 'push', 'Text', txt, 'ButtonPushedFcn', cb);
    b.Layout.Row = r;
    b.Layout.Column = [1 2];
end

function makeHint(g, r, txt, height)
    l = uilabel(g, 'Text', txt, 'WordWrap', 'on', 'VerticalAlignment', 'top');
    l.Layout.Row = r;
    l.Layout.Column = [1 2];
    rh = g.RowHeight;
    rh{r} = height;
    g.RowHeight = rh;
end

function t = size2text(im)
    t = sprintf('%d x %d', size(im, 2), size(im, 1));   % lebar x tinggi
end

function x = readImg(path)
    [x, map] = imread(path);
    if ~isempty(map)                 % citra berindeks -> RGB
        x = im2uint8(ind2rgb(x, map));
    end
    if size(x, 3) == 4               % buang kanal alfa
        x = x(:, :, 1:3);
    end
end

function c = parseCenters(s)
    s = strrep(strrep(s, ';', ' '), ',', ' ');
    v = sscanf(s, '%f');
    if isempty(v) || mod(numel(v), 2) ~= 0
        error('Isi titik notch dengan pasangan [baris kolom], contoh: 35 40; 20 -50');
    end
    c = reshape(v, 2, [])';
end