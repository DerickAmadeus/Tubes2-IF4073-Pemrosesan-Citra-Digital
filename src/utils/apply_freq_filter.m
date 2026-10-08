function [out, Fbefore, Fafter] = apply_freq_filter(img, H, mode)
%
%   out = apply_freq_filter(img, H)
%   out = apply_freq_filter(img, H, mode)
%   [out, Fbefore, Fafter] = apply_freq_filter(img, H)
%
%   Inputs:
%     img  : grayscale (M-by-N) or color (M-by-N-by-3) image,
%            any type (uint8, double, ...)
%     H    : M-by-N filter mask, CENTERED (same style as freq_grid)
%     mode : 'clip' (default) -> result is cut to the range [0, 1]
%            'none'           -> result is returned as it is
%                                (useful if you want to rescale it yourself)
%
%   Outputs:
%     out     : filtered image, double, same size as img
%     Fbefore : centered spectrum BEFORE filtering (complex, M-by-N)
%     Fafter  : centered spectrum AFTER filtering  (complex, M-by-N)
%               For color images these are the AVERAGE of the channels,
%               so you can show them with show_spectrum.

    if nargin < 3
        mode = 'clip';
    end

    % 0 to 1
    img = im2double(img);

    [M, N, C] = size(img);

    % must have the same size as the image
    if ~isequal(size(H), [M, N])
        error('apply_freq_filter:sizeMismatch', ...
              'H must be %d-by-%d, but it is %d-by-%d.', ...
              M, N, size(H,1), size(H,2));
    end

    out     = zeros(M, N, C);
    Fbefore = zeros(M, N);
    Fafter  = zeros(M, N);

    for c = 1:C
        F = fftshift(fft2(img(:,:,c)));
        G = F .* H;
        out(:,:,c) = real(ifft2(ifftshift(G)));

        % Save spectra (average over channels)
        Fbefore = Fbefore + F / C;
        Fafter  = Fafter  + G / C;
    end

    if strcmp(mode, 'clip')
        out = min(max(out, 0), 1);
    end
end