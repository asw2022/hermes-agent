#!/usr/bin/env python3
import numpy as np
import scipy
import pandas as pd
import matplotlib
import time

print("=== Rechenumgebung Babel-PC ===")
print(f"NumPy: {np.__version__}")
print(f"SciPy: {scipy.__version__}")
print(f"Pandas: {pd.__version__}")
print(f"Matplotlib: {matplotlib.__version__}")
print()

# Test 1: Matrix-Multiplikation
print("Test 1: Matrix-Multiplikation 2000x2000...")
a = np.random.rand(2000, 2000)
b = np.random.rand(2000, 2000)
t0 = time.time()
c = a @ b
t1 = time.time()
print(f"  Zeit: {t1-t0:.2f}s")
print(f"  Ergebnis[0,0]: {c[0,0]:.6f}")
print()

# Test 2: FFT
print("Test 2: FFT (10 Mio Punkte)...")
data = np.random.rand(10_000_000)
t0 = time.time()
result = np.fft.fft(data)
t1 = time.time()
print(f"  Zeit: {t1-t0:.2f}s")
print()

# Test 3: Pandas DataFrame
print("Test 3: Pandas DataFrame (1 Mio Zeilen)...")
df = pd.DataFrame({"A": np.random.rand(1_000_000), "B": np.random.rand(1_000_000)})
df["C"] = df["A"] * df["B"]
print(f"  Summe C: {df['C'].sum():.2f}")
print(f"  Mean A: {df['A'].mean():.6f}")
print()

print("Alle Tests bestanden!")
