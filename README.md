# Standarized Soil Moisture Tempreture Compound Index (SSTCI)
1️⃣ Conceptual Purpose

SSTCI is designed to quantify compound dry–hot extremes (CDHEs) at daily resolution and global scale. Instead of treating drought and heat separately, it explicitly models their dependence structure, which is physically important because soil moisture deficits and temperature anomalies amplify each other through land–atmosphere feedbacks.

2️⃣ Core Components

SSTCI combines two standardized signals:

SASMI (soil moisture–based antecedent drought index)

Built from ERA5-Land SWVL1

Incorporates grid-specific dry-down memory (τ-map derived from decay analysis)

Uses daily standardization stratified by day-of-year

Preserves daily temporal structure (1961–2023, 0.1° global)

STI (Standardized Temperature Index)

Derived from daily maximum temperature

Standardized relative to climatology

Instead of simple averaging, we use a Frank copula to model joint dependence between SASMI and STI and derive a compound probability-based index.


3️⃣ Event Detection Framework

Beyond the continuous daily SSTCI field, you created:

A Global CDHE Event Catalogue

Based on:

Threshold selection (e.g., −2 for extreme)

Removal–merging optimization to avoid fragmented spells

Independence filtering

Each event is stored with 13 attributes (duration, severity, end date, etc.)

Organized per latitude slice for computational scalability

This transforms SSTCI from a signal into a usable event-based dataset, which is a big methodological strength.


🌍 SSTCI: Global Daily Compound Dry–Hot Extreme Index (1961–2023)

This repository contains the full computational framework for constructing the Standardized Soil Moisture–Temperature Compound Index (SSTCI) and the associated Global Compound Dry–Hot Extreme (CDHE) Event Catalogue at 0.1° spatial resolution and daily temporal scale (1961–2023).

SSTCI is a probabilistically grounded compound index that integrates:

SASMI (Standardized Antecedent Soil Moisture Index), incorporating grid-specific soil moisture memory derived from dry-down analysis

STI (Standardized Temperature Index), derived from daily maximum temperature

A Frank copula dependence model to quantify joint dry–hot behavior

Unlike simple co-occurrence metrics, SSTCI explicitly models the statistical dependence between soil moisture deficits and temperature anomalies to produce a daily compound severity signal.

📦 Repository Contents

SASMI computation (memory-based soil moisture standardization)

STI computation (daily temperature standardization)

Copula fitting and SSTCI construction

Threshold-based extreme detection

Removal–merging optimization for independent event extraction


🔍 Key Features

Daily resolution (preserves sub-seasonal variability)

Global 0.1° spatial coverage (1961–2023)

Physically informed soil moisture memory (τ-map)

Event-based catalogue with statistically independent CDHEs




