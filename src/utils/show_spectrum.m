function S = show_spectrum(X, isImage, ax)
%   S = show_spectrum(F)             F = centered spectrum (from apply_freq_filter)
%   S = show_spectrum(img, true)     X is an IMAGE: do fft2 + fftshift first
%   show_spectrum(F)                 no output -> the spectrum is displayed
%   show_spectrum(F, false, ax)      display on a specific axes (for the GUI)
%
%   Inputs:
%     X       : centered spectrum (complex, M-by-N)  OR  an image
%     isImage : true  -> X is an image (gray or color)
%               false -> X is already a centered spectrum (default)
%     ax      : (optional) axes handle where the spectrum is drawn
%
%   Output:
%     S : M-by-N matrix with values from 0 to 1, ready for imshow

    if nargin < 2 || isempty(isImage)
        isImage = false;
    end

    % If X is an image, make its centered spectrum first
    if isImage
        X = im2double(X);
        if size(X, 3) > 1
            X = mean(X, 3);          % color -> one layer (average)
        end
        X = fftshift(fft2(X));
    end

    % Compress the big numbers with log, then stretch to 0..1
    S = log(1 + abs(X));
    lo = min(S(:));
    hi = max(S(:));
    if hi > lo
        S = (S - lo) / (hi - lo);
    else
        S = zeros(size(S));          % flat spectrum (e.g. all zeros)
    end

    % Show it only when no output is asked, or when an axes is given
    if nargout == 0 || nargin >= 3
        if nargin >= 3 && ~isempty(ax)
            imshow(S, 'Parent', ax);
        else
            imshow(S);
        end
    end
end