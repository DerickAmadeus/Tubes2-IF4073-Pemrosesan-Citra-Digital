function [out, H, spec] = highpass_filter(img, type, D0, n)
%   [out, H, spec] = highpass_filter(img, type, D0)
%   [out, H, spec] = highpass_filter(img, type, D0, n)
%
%   Inputs:
%     img  : grayscale or color image
%     type : 'ideal'       -> IHPF (sharp cut)
%            'gaussian'    -> GHPF (smooth fade)
%            'butterworth' -> BHPF (in between, controlled by n)
%     D0   : cutoff radius (> 0). Bigger D0 = only the sharpest details stay.
%     n    : order of the Butterworth filter (default 2).
%            Ignored by 'ideal' and 'gaussian'.
%
%   Outputs:
%     out  : filtered image, stretched to 0..1 so it can be seen
%     H    : the filter mask (M-by-N), useful for the report
%     spec : spectrum AFTER filtering (0..1), ready for imshow

    if nargin < 4 || isempty(n)
        n = 2;                       % default order
    end
    if D0 <= 0
        error('highpass_filter:badD0', 'D0 must be greater than 0.');
    end

    % dist from center
    [M, N, ~] = size(img);
    D = freq_grid(M, N);

    % mask
    switch lower(type)
        case 'ideal'
            H = 1 - double(D <= D0);                 % 0 inside, 1 outside

        case 'gaussian'
            H = 1 - exp(-(D.^2) ./ (2 * D0^2));

        case 'butterworth'
            H = 1 - 1 ./ (1 + (D ./ D0).^(2 * n));

        otherwise
            error('highpass_filter:badType', ...
                  'Unknown type "%s". Use ideal, gaussian, or butterworth.', type);
    end

    % image filter
    % 'none' = do NOT cut negative values (edges can be negative)
    [out, ~, Fafter] = apply_freq_filter(img, H, 'none');

    lo = min(out(:));
    hi = max(out(:));
    if hi > lo
        out = (out - lo) / (hi - lo);
    else
        out = zeros(size(out));
    end
    
    spec = show_spectrum(Fafter);
end