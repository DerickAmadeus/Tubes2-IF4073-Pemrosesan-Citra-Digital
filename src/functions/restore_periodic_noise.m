function restore_periodic_noise()
    clc; clear; close all;

    image_path = '../../data/E_periodic_noise_restoration/input/brick_gray_periodic_noise.png';

    if exist(image_path, 'file')
        f = imread(image_path);
    else
        f = buatCitraUjiSintetis();
    end

    filterMode = 'notchreject'; % Opsi: 'bandreject' | 'notchreject'
    filterType = 'gaussian';    % Opsi: 'ideal' | 'butterworth' | 'gaussian'
    n = 2;                      % Orde filter (khusus Butterworth)

    switch lower(filterMode)
        case 'bandreject'
            % Parameter khusus Bandreject
            D0 = 40; % Cutoff frequency (radius pusat pita)
            W  = 10; % Bandwidth (lebar pita)
            
            [f_filtered, H] = jalankanBandreject(f, D0, W, filterType, n);
            filterTitle = ['Bandreject (', upper(filterType), ')'];

        case 'notchreject'
            % Parameter khusus Notch Reject
            D0 = 10; % Radius area notch
            
            notchCenters = [
                 35,  40;
                -35, -40;
                 20, -50;
                -20,  50
            ];
            
            [f_filtered, H] = jalankanNotchReject(f, notchCenters, D0, filterType, n);
            filterTitle = ['Notch Reject (', upper(filterType), ')'];

        otherwise
            error('Filter mode tidak dikenal. Gunakan ''bandreject'' atau ''notchreject''.');
    end

    F_orig = hitungSpektrum(f);
    F_filt = hitungSpektrum(f_filtered);

    figure('Name', ['Hasil Restorasi - ', filterTitle], 'NumberTitle', 'off');

    subplot(2, 3, 1); imshow(f); title('Citra Asli');
    subplot(2, 3, 2); imshow(F_orig, []); title('Spektrum Fourier Asli');
    subplot(2, 3, 3); imshow(H, []); title(['Mask Filter ', filterTitle]);
    subplot(2, 3, 4); imshow(f_filtered); title('Citra Hasil Filter');
    subplot(2, 3, 5); imshow(F_filt, []); title('Spektrum Fourier Hasil');
    subplot(2, 3, 6); imshow(abs(double(f) - double(f_filtered)), []); title('Derau/Noise yang Dibuang');
end

function [imgOut, H] = jalankanBandreject(img, D0, W, filterType, n)
    [rows, cols, ~] = size(img);
    H = buatMaskBandreject(rows, cols, D0, W, filterType, n);
    imgOut = terapkanMask(img, H);
end

function [imgOut, H] = jalankanNotchReject(img, notchCenters, D0, filterType, n)
    [rows, cols, ~] = size(img);
    H = buatMaskNotchReject(rows, cols, notchCenters, D0, filterType, n);
    imgOut = terapkanMask(img, H);
end

function imgOut = terapkanMask(img, H)
    imgOut = zeros(size(img), 'uint8');
    numChannels = size(img, 3);
    
    for c = 1:numChannels
        f_dbl = im2double(img(:, :, c));
        F = fftshift(fft2(f_dbl));
        G = F .* H;
        g = real(ifft2(ifftshift(G)));
        g = max(0, min(1, g));
        imgOut(:, :, c) = uint8(round(g * 255));
    end
end

function H = buatMaskBandreject(rows, cols, D0, W, filterType, n)
    H = ones(rows, cols);
    centerR = floor(rows / 2) + 1;
    centerC = floor(cols / 2) + 1;

    for r = 1:rows
        for c = 1:cols
            D = sqrt((r - centerR)^2 + (c - centerC)^2);
            switch lower(filterType)
                case 'ideal'
                    if (D >= (D0 - W/2)) && (D <= (D0 + W/2))
                        H(r, c) = 0;
                    else
                        H(r, c) = 1;
                    end
                case 'butterworth'
                    if (D * W) == 0
                        H(r, c) = 0;
                    else
                        val = (D * W) / (D^2 - D0^2)^2;
                        H(r, c) = 1 / (1 + val^n);
                    end
                case 'gaussian'
                    if W == 0
                        val = 0;
                    else
                        val = ((D^2 - D0^2) / (D * W))^2;
                    end
                    H(r, c) = 1 - exp(-val);
            end
        end
    end
end

function H = buatMaskNotchReject(rows, cols, notchCenters, D0, filterType, n)
    H = ones(rows, cols);
    centerR = floor(rows / 2) + 1;
    centerC = floor(cols / 2) + 1;
    numNotches = size(notchCenters, 1);

    for k = 1:numNotches
        uk = notchCenters(k, 1);
        vk = notchCenters(k, 2);
        H_k = ones(rows, cols);

        for r = 1:rows
            for c = 1:cols
                D1 = sqrt((r - (centerR + uk))^2 + (c - (centerC + vk))^2);
                D2 = sqrt((r - (centerR - uk))^2 + (c - (centerC - vk))^2);

                switch lower(filterType)
                    case 'ideal'
                        if (D1 <= D0) || (D2 <= D0)
                            H_k(r, c) = 0;
                        else
                            H_k(r, c) = 1;
                        end
                    case 'butterworth'
                        if (D1 * D2) == 0
                            H_k(r, c) = 0;
                        else
                            val = (D0^2) / (D1 * D2);
                            H_k(r, c) = 1 / (1 + val^n);
                        end
                    case 'gaussian'
                        val = (D1 * D2) / (D0^2);
                        H_k(r, c) = 1 - exp(-0.5 * val);
                end
            end
        end
        H = H .* H_k;
    end
end

function S = hitungSpektrum(img)
    if size(img, 3) == 3
        imgGray = rgb2gray(img);
    else
        imgGray = img;
    end
    S = log(1 + abs(fftshift(fft2(im2double(imgGray)))));
end

function f_noisy = buatCitraUjiSintetis()
    f_base = uint8(ones(256, 256) * 128);
    f_base(50:200, 50:200) = 200;
    [X, Y] = meshgrid(1:256, 1:256);
    noise = 40 * sin(2*pi*X/8 + 2*pi*Y/8);
    f_noisy = uint8(max(0, min(255, double(f_base) + noise)));
end