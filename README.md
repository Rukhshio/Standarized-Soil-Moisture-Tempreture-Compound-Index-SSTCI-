# Standarized-Soil-Moisture-Tempreture-Compound-Index-SSTCI-
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

Instead of simple averaging, you use a Frank copula to model joint dependence between SASMI and STI and derive a compound probability-based index.

That’s actually the key innovation:
You’re not just co-occurrence filtering — you're statistically modeling joint behavior.

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

4️⃣ Validation Strategy

You validated at multiple levels:

SASMI vs SPEI & DEDI (daily drought credibility)

SSTCI vs SCDHI (compound index coherence)

Vegetation stress correspondence (LAI response during 2022 event)

Radar plots for major global CDHE mega-events

Regime shift analysis post-2000

This multi-layer validation strengthens physical credibility — but here’s where I’ll challenge you:

Agreement with other indices doesn’t automatically prove physical superiority.
It proves consistency.

You may want to be sharper in distinguishing:

Redundancy

Added physical value

Predictive skill

Right now SSTCI is well-validated descriptively — the next frontier would be predictive or impact-based skill metrics.

5️⃣ Strengths

Daily resolution (rare for global compound datasets)

Physically informed soil moisture memory

Copula-based dependence modeling

Event-level catalogue (not just gridded time series)

Global 0.1° coverage (1961–2023)

That’s ESSD-level infrastructure work.

6️⃣ Potential Weak Points (Devil’s Advocate Mode)

Let’s push harder:

The −2 threshold is extreme-focused — does SSTCI meaningfully characterize moderate compound stress?

Frank copula assumes symmetric dependence — is tail dependence adequately captured?

Does SSTCI outperform simpler multiplicative or percentile-based approaches?

How sensitive are trends to standardization window choice?

Are you double-counting temperature influence via soil moisture–temperature feedback embedded in SASMI climatology?

These are not flaws — they are the next intellectual battleground.

If I had to summarize SSTCI in one line:

SSTCI is a probabilistically grounded, daily, globally resolved compound dry–hot index that integrates soil moisture memory and temperature extremes using copula-based dependence modeling, coupled with an objective event catalogue.

Now tell me — do you see SSTCI more as a data product, a methodological contribution, or a new physical framework?

Because those are three different claims.

good you reemember so i am uploading myu code to github, i want a description for it 

Oh I love this stage — this is where it becomes infrastructure, not just a paper.

Here’s a clean, professional GitHub description you can use (ESSD-style but readable):

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

Event-level attribute generation (duration, severity, timing, etc.)

Scripts for global processing (latitude-sliced workflow)

Utilities for validation and visualization

🔍 Key Features

Daily resolution (preserves sub-seasonal variability)

Global 0.1° spatial coverage (1961–2023)

Physically informed soil moisture memory (τ-map)

Event-based catalogue with statistically independent CDHEs

Scalable latitude-wise processing architecture

🎯 Scientific Purpose

This framework enables:

Detection of extreme compound dry–hot events

Event-based climatological analysis

Regime shift and intensification assessment

Cross-index validation studies

Impact-focused analysis linking compound extremes to vegetation stress 
