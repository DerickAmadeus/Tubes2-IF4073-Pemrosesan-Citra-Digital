function [D, U, V] = freq_grid(M, N)
%
%   D = freq_grid(M, N)
%   [D, U, V] = freq_grid(M, N)
%
%   Inputs:
%     M : number of rows of the image
%     N : number of columns of the image
%
%   Outputs:
%     D : M-by-N matrix, D(u,v) = distance from the center (0,0)
%     U : M-by-N matrix, row offset from the center
%     V : M-by-N matrix, column offset from the center

    % Center
    centerRow = floor(M/2) + 1;
    centerCol = floor(N/2) + 1;

    u = (1:M) - centerRow;
    v = (1:N) - centerCol;

    % Create meshgrid
    [V, U] = meshgrid(v, u);

    % dist from center
    D = sqrt(U.^2 + V.^2);
end