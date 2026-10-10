function [imgBlurred, PSF] = motion_blur_psf(img, len, theta)
    PSF = applyMotionBlur(len, theta);
    
    rows = size(img, 1);
    cols = size(img, 2);
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
    dy = -sin(rad);

    halfLen = (len-1)/2;
    halfWidth = ceil(abs(halfLen * dx));
    halfHeight = ceil(abs(halfLen * dy));

    sizeR = 2 * halfHeight + 1;
    sizeC = 2 * halfWidth + 1;

    centerR = halfHeight + 1;
    centerC = halfWidth + 1;

    PSF = zeros(sizeR, sizeC);

    numSamples = ceil(len * 50); 
    t = linspace(-halfLen, halfLen, numSamples);

    for i = 1:numSamples
        x = t(i) * dx;
        y = t(i) * dy;

        r = round(centerR + y);
        c = round(centerC + x);

        if r >= 1 && r <= sizeR && c >= 1 && c <= sizeC
            PSF(r, c) = PSF(r, c) + 1;
        end
    end

    totalSum = sum(PSF(:));
    if totalSum > 0
        PSF = PSF / totalSum;
    end
end