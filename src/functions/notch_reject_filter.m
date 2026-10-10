function [imgFiltered, H] = notch_reject_filter(img, notchCenters, D0, filterType, n)
    if nargin < 5 || isempty(n)
        n = 2;
    end
    if D0 <= 0
        error('notch_reject_filter:badD0', 'D0 must be greater than 0.');
    end
    if isempty(notchCenters) || size(notchCenters, 2) ~= 2
        error('notch_reject_filter:badCenters', ...
              'notchCenters must be a K-by-2 matrix: [row col].');
    end
    [rows, cols, numChannels] = size(img);

    H = createBand(rows, cols, notchCenters, D0, filterType, n)

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

function H = createBand(rows, cols, notchCenters, D0, filterType, n)
 
    [~, U, V] = freq_grid(rows, cols);   % row / column offset from the center
 
    H = ones(rows, cols);
    numNotches = size(notchCenters, 1);
 
    for k = 1:numNotches
        uk = notchCenters(k, 1);
        vk = notchCenters(k, 2);
 
        % distance to the spot, and to its symmetric partner
        D1 = sqrt((U - uk).^2 + (V - vk).^2);
        D2 = sqrt((U + uk).^2 + (V + vk).^2);
 
        switch lower(filterType)
            case 'ideal'
                Hk = double(~(D1 <= D0 | D2 <= D0));
 
            case 'butterworth'
                Hk = 1 ./ (1 + (D0^2 ./ (D1 .* D2)).^n);
                Hk(D1 .* D2 == 0) = 0;       % exactly on the spot: remove
 
            case 'gaussian'
                Hk = 1 - exp(-0.5 * (D1 .* D2) ./ D0^2);
 
            otherwise
                error('notch_reject_filter:badType', ...
                      'Unknown filterType "%s". Use ideal, butterworth, or gaussian.', filterType);
        end
 
        H = H .* Hk;
    end
end
