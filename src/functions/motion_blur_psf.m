function [imgBlurred, PSF] = motion_blur_psf(img, len, theta)
    PSF = applyMotionBlur(len, theta);

    numChannels = size(img, 3);

    imgBlurred = zeros(size(img), 'uint8');

    if numChannels == 1
        imgBlurred = konvolusi(img, PSF);

    elseif numChannels == 3
        for ch = 1:3
            imgBlurred(:, :, ch) = konvolusi(img(:, :, ch), PSF);
        end

    else
        error('motion_blur: citra harus grayscale (2D) atau RGB (3D dengan 3 kanal).');
    end
end

function channelOut = konvolusi(channel, PSF)
    channelDbl = im2double(channel);

    blurredDbl = conv2(channelDbl, PSF, 'same');

    blurredDbl = max(0, min(1, blurredDbl));
    channelOut = uint8(round(blurredDbl * 255));
end

function PSF = applyMotionBlur(len, theta)
    if len <= 0
        error('Panjang motion blur (len) harus lebih besar dari 0.');
    end

    rad = deg2rad(theta);

    dx = cos(rad);
    dy = -sin(rad);              % baris gambar turun ke bawah, jadi tanda dibalik

    % Garis sepanjang len piksel: dari -len/2 sampai +len/2.
    % (Memakai (len-1)/2 membuat dua ujung hanya setengah bobot.)
    halfExt = len / 2;

    halfWidth  = max(ceil(abs(halfExt * dx) - 0.5), 0);
    halfHeight = max(ceil(abs(halfExt * dy) - 0.5), 0);

    sizeR = 2 * halfHeight + 1;
    sizeC = 2 * halfWidth + 1;

    centerR = halfHeight + 1;
    centerC = halfWidth + 1;

    PSF = zeros(sizeR, sizeC);

    % Titik-titik di sepanjang garis. Dipakai titik TENGAH tiap potongan kecil,
    % sehingga ujung garis tidak ikut terhitung berlebih atau kurang.
    numSamples = ceil(len * 50);
    t = ((1:numSamples) - 0.5) / numSamples * len - halfExt;

    for i = 1:numSamples
        x = t(i) * dx;
        y = t(i) * dy;

        r = round(centerR + y);
        c = round(centerC + x);

        if r >= 1 && r <= sizeR && c >= 1 && c <= sizeC
            PSF(r, c) = PSF(r, c) + 1;
        end
    end

    % jumlah total harus 1 supaya gambar tidak jadi lebih terang atau gelap
    totalSum = sum(PSF(:));
    if totalSum > 0
        PSF = PSF / totalSum;
    end
end