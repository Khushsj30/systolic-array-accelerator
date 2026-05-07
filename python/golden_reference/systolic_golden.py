import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os

N = 4
BITS = 8
MAX_VAL = 2**BITS - 1
np.random.seed(42)

A = np.random.randint(0, MAX_VAL, size=(N, N), dtype=np.int32)
B = np.random.randint(0, MAX_VAL, size=(N, N), dtype=np.int32)

print("=" * 50)
print("INPUT MATRIX A (activations):")
print(A)
print("\nINPUT MATRIX B (weights):")
print(B)

C_golden = np.matmul(A, B)
print("\nGOLDEN OUTPUT C = A x B:")
print(C_golden)

PE = np.zeros((N, N), dtype=np.int64)
A_skewed = []
for t in range(2 * N - 1):
    row = np.zeros(N, dtype=np.int32)
    for i in range(N):
        if 0 <= t - i < N:
            row[i] = A[i][t - i]
    A_skewed.append(row)

for t in range(3 * N):
    for i in range(N):
        for j in range(N):
            if t >= i and (t - i) < N and t < len(A_skewed):
                a_val = A_skewed[t][i] if t >= i else 0
                b_val = B[t - i][j] if 0 <= t - i < N else 0
                PE[i][j] += a_val * b_val

print("\nSYSTOLIC ARRAY OUTPUT:")
print(PE)

match = np.array_equal(C_golden, PE)
print("\n" + "=" * 50)
if match:
    print("VERIFICATION PASSED: Systolic output matches golden reference!")
else:
    print("VERIFICATION FAILED!")
    print("Difference:")
    print(C_golden - PE)
print("=" * 50)

os.makedirs("../../sim/logs", exist_ok=True)
np.savetxt("../../sim/logs/matrix_A.txt", A, fmt="%d")
np.savetxt("../../sim/logs/matrix_B.txt", B, fmt="%d")
np.savetxt("../../sim/logs/matrix_C_golden.txt", C_golden, fmt="%d")
print("\nMatrices saved to sim/logs/")

fig, axes = plt.subplots(1, 3, figsize=(14, 4))
fig.suptitle("Systolic Array - Matrix Operands and Result", fontsize=13, fontweight="bold")
for ax, matrix, title, cmap in zip(axes, [A, B, C_golden], ["Matrix A (Activations)", "Matrix B (Weights)", "Matrix C = AxB (Golden)"], ["Blues", "Oranges", "Greens"]):
    im = ax.imshow(matrix, cmap=cmap, aspect="auto")
    ax.set_title(title, fontsize=10, fontweight="bold")
    for i in range(N):
        for j in range(N):
            ax.text(j, i, str(matrix[i, j]), ha="center", va="center", fontsize=7)
    plt.colorbar(im, ax=ax, shrink=0.8)
plt.tight_layout()
os.makedirs("../../docs/diagrams", exist_ok=True)
plt.savefig("../../docs/diagrams/matrix_visualization.png", dpi=150, bbox_inches="tight")
plt.close()
print("Visualization saved to docs/diagrams/matrix_visualization.png")