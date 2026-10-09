function [imgFiltered, H] = notch_reject_filter(img, notchCenters, D0, filterType, n)
    if nargin < 5
        n = 1;
    end
    rows = size(img, 1)
    cols = size(img, 2)
    numChannels = size(img, 3)

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
    H = ones(rows, cols);

    centerR = floor(rows / 2) + 1;
    centerC = floor(cols / 2) + 1;

    numNotches = size(notchCenters, 1)
    for k = 1:numNotches
        uk = notchCenters(k, 1);
        vk = notchCenters(k, 2);

        Hk = ones(rows, cols)
        for r = 1:rows
            for c = 1:cols
                D1 = sqrt((r - (centerR + uk))^2 + (c - (centerC + vk))^2);
                D2 = sqrt((r - (centerR - uk))^2 + (c - (centerC - vk))^2);

                switch lower(filterType)
                    case 'ideal'
                        if (D1 <= D0) || (D2 <= D0)
                            Hk(r, c) = 0;
                        else
                            Hk(r, c) = 1;
                        end
        
                    case 'butterworth'
                        if (D1 * D2) == 0
                            Hk(r, c) = 0;
                        else
                            val = (D0^2) / (D1 * D2);
                            Hk(r, c) = 1 / (1 + val^n);
                        end
        
                    case 'gaussian'
                        val = (D1 * D2) / (D0^2);
                        Hk(r, c) = 1 - exp(-0.5 * val);
                end
            end
        end

        H = H .* Hk;
    end
end
