function [imgRestored, H] = inverse_filter(img, PSF, radius, threshold)
    rows = size(img, 1);
    cols = size(img, 2);
    numChannels = size(img, 3);
    if nargin < 3 || isempty(radius)
        radius = min(rows, cols) / 2; 
    end
    if nargin < 4 || isempty(threshold)
        threshold = 1e-3;
    end

    H = OTF(PSF, rows, cols);

    imgRestored = zeros(size(img), 'uint8');

    if numChannels == 1
        imgRestored = terapkanFilter(img, H, radius, threshold);

    elseif numChannels == 3
        for ch = 1:3
            imgRestored(:, :, ch) = terapkanFilter(img(:, :, ch), H, radius, threshold);
        end

    else
        error('inversefilter: citra harus grayscale (2D) atau RGB (3D dengan 3 kanal).');
    end
end

function channelOut = terapkanFilter(channel, H, radius, threshold)
    rows = size(channel, 1);
    cols = size(channel, 2);

    channelDbl = im2double(channel);

    G = fft2(channelDbl);
    Gshift = fftshift(G);

    Hshift = fftshift(H);

    centerR = floor(rows / 2) + 1;
    centerC = floor(cols / 2) + 1;

    M = zeros(rows, cols);

    for r = 1:rows
        for c = 1:cols
            D = sqrt((r - centerR)^2 + (c - centerC)^2);
            absH = abs(Hshift(r, c));

            if (D <= radius) && (absH >= threshold)
                M(r, c) = 1 / Hshift(r, c);
            else
                M(r, c) = 0;
            end
        end
    end

    Fshift = Gshift .* M;

    F = ifftshift(Fshift);

    f_restored = real(ifft2(F));

    f_restored = max(0, min(1, f_restored));
    channelOut = uint8(round(f_restored * 255));
end


function H = OTF(PSF, rows, cols)
    [pRows, pCols] = size(PSF);

    paddedPSF = zeros(rows, cols);
    paddedPSF(1:pRows, 1:pCols) = PSF;

    centerR = floor(pRows / 2);
    centerC = floor(pCols / 2);
    paddedPSF = circshift(paddedPSF, [-centerR, -centerC]);

    H = fft2(paddedPSF);
end