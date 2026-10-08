function [out, H, spec] = lowpass_filter(img, type, D0, n)
%   [out, H, spec] = lowpass_filter(img, type, D0)
%   [out, H, spec] = lowpass_filter(img, type, D0, n)
%
%   Inputs:
%     img  : grayscale or color image
%     type : 'ideal'       -> ILPF (sharp cut)
%            'gaussian'    -> GLPF (smooth fade)
%            'butterworth' -> BLPF (in between, controlled by n)
%     D0   : cutoff radius (> 0). Smaller D0 = more blur.
%     n    : order of the Butterworth filter (default 2).
%            Ignored by 'ideal' and 'gaussian'.
%
%   Outputs:
%     out  : filtered image
%     H    : the filter mask (M-by-N)
%     spec : spectrum AFTER filtering (0..1)


    if nargin < 4 || isempty(n)
        n = 2;                       % default order
    end
    if D0 <= 0
        error('lowpass_filter:badD0', 'D0 must be greater than 0.');
    end

    % dist from center
    [M, N, ~] = size(img);
    D = freq_grid(M, N);

    % mask H
    switch lower(type)
        case 'ideal'
            H = double(D <= D0);                 % 1 inside the circle, 0 outside

        case 'gaussian'
            H = exp(-(D.^2) ./ (2 * D0^2));      % smooth fade

        case 'butterworth'
            H = 1 ./ (1 + (D ./ D0).^(2 * n));   % n controls how sharp

        otherwise
            error('lowpass_filter:badType', ...
                  'Unknown type "%s". Use ideal, gaussian, or butterworth.', type);
    end

    % filter
    [out, ~, Fafter] = apply_freq_filter(img, H);

    spec = show_spectrum(Fafter);
end