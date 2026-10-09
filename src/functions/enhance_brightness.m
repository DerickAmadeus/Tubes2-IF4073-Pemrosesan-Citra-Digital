function [out, H, spec] = enhance_brightness(img, params)

%   [out, H, spec] = enhance_brightness(img)
%   [out, H, spec] = enhance_brightness(img, params)
%
%
%   Outputs:
%     out  : brighter image (double, 0..1)
%     H    : the filter mask (M-by-N)
%     spec : spectrum AFTER filtering (0..1), ready for imshow
%

    if nargin < 2 || isempty(params)
        params = struct();
    end
    method = getParam(params, 'method', 'lowboost');
    gain   = getParam(params, 'gain',   3);
    D0     = getParam(params, 'D0',     30);
    gammaL = getParam(params, 'gammaL', 1.5);
    gammaH = getParam(params, 'gammaH', 1.0);
    c      = getParam(params, 'c',      1);

    if D0 <= 0
        error('enhance_brightness:badD0', 'D0 must be greater than 0.');
    end

    img = im2double(img);


    isColor = size(img, 3) == 3;
    if isColor
        hsv = rgb2hsv(img);
        V = hsv(:, :, 3);
    else
        V = img;
    end

    [M, N] = size(V);
    D = freq_grid(M, N);

    % mask H
    switch lower(method)
        case 'dc'
            % only the center point (= average brightness)
            H = ones(M, N);
            H(floor(M/2) + 1, floor(N/2) + 1) = gain;
            [Vout, ~, Fafter] = apply_freq_filter(V, H, 'none');

        case 'lowboost'
            % low frequencies x gain, high frequencies x 1
            H = 1 + (gain - 1) * exp(-(D.^2) ./ (2 * D0^2));
            [Vout, ~, Fafter] = apply_freq_filter(V, H, 'none');

        case 'homomorphic'
            % work on log(image): illumination = low freq, details = high freq
            H = (gammaH - gammaL) * (1 - exp(-c * (D.^2) ./ (D0^2))) + gammaL;
            L = log(1 + V);
            [Lout, ~, Fafter] = apply_freq_filter(L, H, 'none');
            Vout = exp(Lout) - 1;

        otherwise
            error('enhance_brightness:badMethod', ...
                  'Unknown method "%s". Use lowboost, dc, or homomorphic.', method);
    end

    % keep the values between 0 and 1
    Vout = min(max(Vout, 0), 1);

    if isColor
        hsv(:, :, 3) = Vout;
        out = hsv2rgb(hsv);
    else
        out = Vout;
    end

    spec = show_spectrum(Fafter);
end


%getParam: get a parameter from a struct, or return a default value
function v = getParam(s, name, default)
    if isfield(s, name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end