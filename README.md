Standardized Soil Moisture–Temperature Compound Index (SSTCI)
===========================================================

This repository contains a MATLAB workflow to compute a daily compound dry–hot
index (SSTCI) from daily 2m maximum temperature (mx2t) and daily soil moisture (swvl1)
provided as NetCDF files.

The workflow is organized into three main stages:

  1) STI   (temperature standardization)
  2) SASMI (soil moisture standardization) — includes the dry-down + k steps
  3) SSTCI (compound index from STI + SASMI using a Frank copula)

All outputs are written as NetCDF.


FILES IN THIS REPOSITORY
------------------------

Input example NetCDF (The method is designed for global 0.1° daily data; this repository includes a small subset for demonstration)
  - mx2t.nc    : daily temperature
  - swvl1.nc   : daily soil moisture

Step 1 — STI:
  - calculate_STI.m : driver script to compute STI from mx2t.nc
  - STI_func.m      : STI function used by calculate_STI.m
  - Output: STI.nc

Step 2 — SASMI (includes dry-down + k):
  This stage has three sub-steps:

  (2A) Dry-down (tau):
    - Calculate_drydown.m : computes median dry-down timescale tau per grid cell
                            using swvl1.nc
    - SM_drydowns2.m      : dry-down function used by Calculate_drydown.m
    - Output: medianTau.nc

  (2B) tau → k:
    - tau_to_k.m : clamps tau and computes dry-down constant k
    - Output: k_map.nc

  (2C) SASMI:
    - calculate_SASMI.m : computes SASMI from swvl1.nc + k_map.nc
    - SASMI_func.m      : SASMI function used by calculate_SASMI.m
    - Output: SASMI.nc

Step 3 — SSTCI:
  - Calculate_SSTCI.m : computes SSTCI from STI.nc + SASMI.nc
  - Output: SSTCI.nc


INPUT REQUIREMENTS
------------------

Required variables in mx2t.nc:
  - mx2t : daily temperature (dimensions include time/lat/lon; order can vary)
  - time, lat, lon

Required variables in swvl1.nc:
  - swvl1 : daily soil moisture (dimensions include time/lat/lon; order can vary)
  - time, lat, lon

Calendar assumption:
  - This workflow assumes a 365-day calendar (leap days removed).
  - DOY-based binning uses 365 bins.


OUTPUTS
-------

STI output:
  - STI.nc
  - Variable: STI(time, lat, lon)

Median dry-down tau output:
  - medianTau.nc
  - Variable: medianTau(lat, lon)

k map output:
  - k_map.nc
  - Variables: k_map(lat, lon) and tau_clamped(lat, lon)

SASMI output:
  - SASMI.nc
  - Variable: SASMI(time, lat, lon)

SSTCI output:
  - SSTCI.nc
  - Variable: SSTCI(time, lat, lon)


HOW TO RUN (RECOMMENDED ORDER)
-----------------------------

1) Compute STI:
   run('calculate_STI.m')
   Output: STI.nc

2) Compute SASMI (dry-down → k → SASMI):
   2A) median tau from soil moisture dry-down:
       run('Calculate_drydown.m')
       Output: medianTau.nc

   2B) clamp tau and compute k:
       run('tau_to_k.m')
       Output: k_map.nc

   2C) compute SASMI:
       run('calculate_SASMI.m')
       Output: SASMI.nc

3) Compute SSTCI:
   run('Calculate_SSTCI.m')
   Output: SSTCI.nc


METHOD NOTES (WHAT THE SCRIPTS DO)
---------------------------------

STI:
  - DOY-based standardization (365 bins)
  - Computed independently for each grid cell
  - NaNs preserved

SASMI:
  - Dry-down step: estimates multiple tau values using SM_drydowns2, then stores
    the median tau per grid cell
  - Clamp + k: tau is capped at 20 days and converted to k = exp(-1/tau)
  - SASMI: uses a 14-day weighted antecedent window controlled by grid-specific k,
    then DOY-based standardization (365 bins)
  - First 13 days are NaN due to the 14-day memory window

SSTCI:
  - Uses STI(14:end) and SASMI(14:end)
  - ECDF → uniform variates, Frank copula fit, copula CDF transform
  - Mapped to standard normal space with norminv
  - First 13 days stored as NaN

MATLAB REQUIREMENTS
-------------------

NetCDF I/O:
  - ncinfo, ncread, nccreate, ncwrite, ncwriteatt

Statistics toolbox functions used in STI/SSTCI:
  - normfit, normcdf, norminv, ecdf
  - copulafit, copulacdf

NOTE: Event-based CDHE catalogue generation is provided in a separate repository().
