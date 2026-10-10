function [imgFiltered, H] = bandreject_filter(img, D0, W, filterType, n)
    if nargin < 5 || isempty(n)
        n = 2;
    end
    if D0 <= 0 || W <= 0
        error('bandreject_filter:badParam', 'D0 and W must be greater than 0.');
    end

    [rows, cols, numChannels] = size(img);

    H = createBand(rows, cols, D0, W, filterType, n);
    
    imgFiltered = zeros(size(img), 'uint8');

    if numChannels == 1
        imgFiltered = filterSatuKanal(img, H);
    elseif numChannels == 3
        for ch = 1:3
            imgFiltered(:, :, ch) = filterSatuKanal(img(:, :, ch), H)
        end
    end
end

function x = filterSatuKanal(channel, H)
    channelDbl = im2double(channel);

    F = fft2(channelDbl);
    Fshift = fftshift(F);

    Gshift = Fshift .* H;

    G = ifftshift(Gshift);
    g = real(ifft2(G));

    g = max(0, min(1, g));
    x = uint8(round(g * 255));
end

function H = createBand(rows, cols, D0, W, filterType, n)
    D = freq_grid(rows, cols);
 
    switch lower(filterType)
        case 'ideal'
            H = ones(rows, cols);
            H(D >= (D0 - W/2) & D <= (D0 + W/2)) = 0;
 
        case 'butterworth'
            val = (D .* W) ./ (D.^2 - D0^2);
            H = 1 ./ (1 + abs(val).^(2*n));
 
        case 'gaussian'
            val = (D.^2 - D0^2) ./ (D .* W);
            H = 1 - exp(-0.5 * val.^2);
 
        otherwise
            error('bandreject_filter:badType', ...
                  'Unknown filterType "%s". Use ideal, butterworth, or gaussian.', filterType);
    end
 
    % D = 0 (the center) can give 0/0 = NaN. The center must be KEPT.
    H(isnan(H)) = 1;
    H(D == 0)   = 1;
end