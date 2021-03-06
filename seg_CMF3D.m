function [uu, erriter, num, tt] = seg_CMF3D(img,bg)
%
%   Function test_CMF3D
%
%   The matlab function to show how to use the functions CMF3D_Mex and CMF3D_GPU
%
%   Before using the functions CMF3D_mex, you should compile it as follows:
%       >> mex CMF3D_mex.c
%
%   Before using the functions CMF3D_GPU, you should compile the GPU program:
%       >> nvmex -f nvmexopts.bat CMF3D_GPU.cu -IC:\cuda\v4.0\include -LC:\cuda\v4.0\lib\x64 -lcufft -lcudart
%
%   After compilation, you can define all the parameters (penalty, C_s, C_t, para) as follows: 
%   
%        - penalty: point to the edge-weight penalty parameters to
%                   total-variation function.
% 
%          For the case without incorporating image-edge weights, 
%          penalty is given by the constant everywhere. For the case 
%          with image-edge weights, penalty is given by the pixelwise 
%          weight function:
% 
%          for example, penalty(x) = b/(1 + a*| grad f(x)|) where b,a > 0 .
% 
%        - C_s: point to the capacities of source flows ps
% 
%        - C_t: point to the capacities of sink flows pt
% 
%        - para: a sequence of parameters for the algorithm
%             para[0,1,2]: rows, cols, heights of the given image
%             para[3]: the maximum iteration number
%             para[4]: the error bound for convergence
%             para[5]: cc for the step-size of augmented Lagrangian method
%             para[6]: the step-size for the graident-projection step to the
%                    total-variation function. Its optimal range is [0.1, 0.17].
% 
%
%       Example:
% 
%             >> [u, erriter, i, timet] = CMF3D_GPU(single(penalty), single(Cs), single(Ct), single(para));
%
%             >> us = max(u, beta);  % where beta in (0,1)
%
%             >> figure, loglog(erriter,'DisplayName','erriterN');figure(gcf)
%
%
%   Please email Jing Yuan (cn.yuanjing@gmail.com) for any questions, 
%   suggestions and bug reports
%
%   The Software is provided "as is", without warranty of any kind.
%
%               Version 1.0
%   https://sites.google.com/site/wwwjingyuan/       
%
%   Copyright 2011 Jing Yuan (cn.yuanjing@gmail.com)   
%

Imax = max(img(:));
Imin = min(img(:));
ur = (img )/(Imax - Imin) ;

[rows,cols,heights] = size(ur);

varParas = [rows; cols; heights; 200; 1e-3; 0.35; 0.11];
%                para 0,1,2 - rows, cols, heights of the given image
%                para 3 - the maximum number of iterations
%                para 4 - the error bound for convergence
%                para 5 - cc for the step-size of augmented Lagrangian method
%                para 6 - the step-size for the graident-projection of p

h = fspecial('gaussian',9, 3);
img_smooth = imfilter(img,h);
[dx, dy, dz] =gradient(img_smooth);
grad_mag =  (dx.^2 + dy.^2 + dz.^2);

max_grad = max(grad_mag(:));
norm_grad = grad_mag/max_grad;
alpha(1) = 0.2; alpha(2) = 0.3;  alpha(3) = 2;
penalty = alpha(1) + alpha(2)*exp(-alpha(3)*norm_grad);

ulab(1) = 0.0;
ulab(2) = 0.7;

% build up the priori L_2 data terms
fCs = abs(ur - ulab(1));
fCt = abs(ur - ulab(2));



fCt(logical(bg)) = 1e6;
% ----------------------------------------------------------------------
%  Use the function CMF3D_mex to run the algorithm on CPU
% ----------------------------------------------------------------------

[uu, erriter,num,tt] = CMF3D_mex(single(penalty), single(fCs), single(fCt), single(varParas));

% ----------------------------------------------------------------------
%  Use the function CMF3D_GPU to run the algorithm on GPU
% ----------------------------------------------------------------------

%[uu, erriter,num,tt] = CMF3D_GPU(single(penalty), single(fCs), single(fCt), single(varParas));