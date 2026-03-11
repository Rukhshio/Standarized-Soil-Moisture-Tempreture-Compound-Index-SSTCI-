function [Z]=STI_func(Data,scale,nseas)
% STI_func  Standardized Temperature Index (STI)
%
% INPUT:
%   Data  : daily temperature vector for one grid cell (NaNs removed before calling)
%   scale : aggregation scale in days (use 1 for daily)
%   nseas : number of seasonal bins (use 365 for DOY-based standardization)
%
% OUTPUT:
%   Z     : STI values for the input series (same length as input Data)
%
% NOTE:
%   This function keeps the original algorithm:
%   - build aggregated series XS (moving sum over "scale")
%   - for each seasonal bin: fit normal distribution (normfit)
%   - map through normcdf and back through norminv

erase_yr=ceil(scale/365);

A1=[];
for is=1:scale
    A1=[A1,Data(is:length(Data)-scale+is)];
end
XS=sum(A1,2);

if (scale>1)
    XS(1:nseas*erase_yr-scale+1)=[];
end

for is=1:nseas
    tind=is:nseas:length(XS);
    Xn=XS(tind);

    [muhat,sigmahat]=normfit(Xn);
    g=normcdf(Xn,muhat,sigmahat);
    Z(tind)=norminv(g);
end
end