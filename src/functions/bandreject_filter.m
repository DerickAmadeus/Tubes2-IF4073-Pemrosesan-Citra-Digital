function [imgFiltered, H] = bandreject_filter(img, D0, W, filterType, n)
    rows = size(img, 1)
    cols = size(img, 2)
    numChannels = size(img, 3)

    H = createBand(rows, cols, D0, W, filterType, n)
    
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
    H = zeros(rows, cols);

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
                    if abs(D^2 - D0^2) < 1e-10
                        H(r, c) = 0;
                    else
                        val = (D * W) / (D^2 - D0^2);
                        H(r, c) = 1 / (1 + val^(2*n));
                    end

                case 'gaussian'
                    if D == 0
                        H(r, c) = 1;
                    else
                        val = (D^2 - D0^2) / (D * W);
                        H(r, c) = 1 - exp(-0.5*val^2);
                    end
            end
        end
    end
end