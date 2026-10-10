function [out, H, spec] = highpass_filter(img, type, D0, n, displayMode)

%   Inputs:
%     img         : grayscale or color image
%     type        : 'ideal'       -> IHPF (sharp cut)
%                   'gaussian'    -> GHPF (smooth fade)
%                   'butterworth' -> BHPF (in between, controlled by n)
%     D0          : cutoff radius (> 0). Bigger D0 = only the sharpest details stay.
%     n           : order of the Butterworth filter (default 2).
%                   Ignored by 'ideal' and 'gaussian'.
%     displayMode : how the result is turned into a picture (default 'clip')
%                   'clip'    -> negative values become 0. 
%                   'stretch' -> smallest value -> 0, biggest -> 1.                
%                   'abs'     -> absolute value, scaled so the biggest value is 1.
%
%   Outputs:
%     out  : filtered image (double, 0..1)
%     H    : the filter mask (M-by-N), useful for the report
%     spec : spectrum AFTER filtering (0..1), ready for imshow

    if nargin < 4 || isempty(n)
        n = 2;                       % default order
    end
    if nargin < 5 || isempty(displayMode)
        displayMode = 'clip';        % default display
    end
    if D0 <= 0
        error('highpass_filter:badD0', 'D0 must be greater than 0.');
    end

    [M, N, ~] = size(img);
    D = freq_grid(M, N);


    switch lower(type)
        case 'ideal'
            H = 1 - double(D <= D0);
        case 'gaussian'
            H = 1 - exp(-(D.^2) ./ (2 * D0^2));

        case 'butterworth'
            H = 1 - 1 ./ (1 + (D ./ D0).^(2 * n));

        otherwise
            error('highpass_filter:badType', ...
                  'Unknown type "%s". Use ideal, gaussian, or butterworth.', type);
    end

    [out, ~, Fafter] = apply_freq_filter(img, H, 'none');

    switch lower(displayMode)
        case 'clip'
            out = min(max(out, 0), 1);

        case 'stretch'
            lo = min(out(:));
            hi = max(out(:));
            if hi > lo
                out = (out - lo) / (hi - lo);
            else
                out = zeros(size(out));
            end

        case 'abs'
            out = abs(out);
            mx = max(out(:));
            if mx > 0
                out = out / mx;
            end

        otherwise
            error('highpass_filter:badDisplay', ...
                  'Unknown displayMode "%s". Use clip, stretch, or abs.', displayMode);
    end

    spec = show_spectrum(Fafter);
end