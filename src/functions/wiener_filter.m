function [imgRestored, H, W] = wiener_filter(img, PSF, K)
    if nargin < 3 || isempty(K)
        K = 0.01; % Nilai estimasi NSR default
    end
    
    rows = size(img, 1);
    cols = size(img, 2);
    numChannels = size(img, 3);
    
    H = OTF(PSF, rows, cols);
    
    H_conj = conj(H);
    absH2 = abs(H).^2;
    W = H_conj ./ (absH2 + K);
    
    imgRestored = zeros(size(img), 'uint8');
    
    if numChannels == 1
        imgRestored = terapkanFilter(img, W);
    
    elseif numChannels == 3
        for ch = 1:3
            imgRestored(:, :, ch) = terapkanFilter(img(:, :, ch), W);
        end
    
    else
        error('wienerfilter: citra harus grayscale (2D) atau RGB (3D dengan 3 kanal).');
    end
end

function channelOut = terapkanFilter(channel, W)
    channelDbl = im2double(channel);
    
    G = fft2(channelDbl);
    
    F_hat = G .* W;
    
    f_restored = real(ifft2(F_hat));
    
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