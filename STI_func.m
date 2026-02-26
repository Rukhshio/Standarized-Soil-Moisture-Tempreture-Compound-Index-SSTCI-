function [Z]=STI_func(Data,scale,nseas)
% STI_func  Standardized Temperature Index (daily, DOY-based standardization)
%
% for daily temperature applications.
%
% INPUTS
%   Data  : Daily temperature VECTOR (not matrix) for a single location.
%           Units: Celsius
%           Assumes a 365-day calendar (leap days removed) when nseas=365.
%           NaNs should be removed before calling if you want to preserve NaN
%           positions externally (see example script).
%   scale : Aggregation scale in days (e.g., 1 for daily). If scale>1, the
%           function forms an aggregated series prior to standardization.
%   nseas : Number of seasonal bins. Use 365 for DOY-based daily standardization.
%
% OUTPUT
%   Z     : STI values aligned to the internally constructed series.
%
% Notes
% - Within each seasonal bin (each DOY across years when nseas=365), the method
%   fits a normal distribution (normfit), maps values to probabilities (normcdf),
%   and then maps back using the inverse normal CDF (norminv)

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
