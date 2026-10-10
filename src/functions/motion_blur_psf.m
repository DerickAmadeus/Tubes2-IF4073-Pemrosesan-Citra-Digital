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
    dy = -sin(rad);              

    halfExt = len / 2;
    halfWidth  = max(ceil(abs(halfExt * dx) - 0.5), 0);
    halfHeight = max(ceil(abs(halfExt * dy) - 0.5), 0);

    sizeR = 2 * halfHeight + 1;
    sizeC = 2 * halfWidth + 1;
    
    centerR = halfHeight + 1;
    centerC = halfWidth + 1;
    
    numSamples = ceil(len * 50);
    t = ((1:numSamples) - 0.5) / numSamples * len - halfExt;
    
    x = t * dx;
    y = t * dy;
    r = round(centerR + y);
    c = round(centerC + x);
    
    valid = (r >= 1 & r <= sizeR) & (c >= 1 & c <= sizeC);
    r = r(valid);
    c = c(valid);
    
    if ~isempty(r)
        PSF = accumarray([r(:), c(:)], 1, [sizeR, sizeC]);
    else
        PSF = zeros(sizeR, sizeC);
    end
    
    totalSum = sum(PSF(:));
    if totalSum > 0
        PSF = PSF / totalSum;
    end
end