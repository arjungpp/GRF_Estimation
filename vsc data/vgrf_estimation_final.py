# =========================================================
# FINAL vGRF ESTIMATION PIPELINE (CLEAN VERSION)
# =========================================================

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.io import loadmat
from pathlib import Path

# =========================================================
# 1. LOAD INPUT DATA
# =========================================================
T_contacts = pd.read_csv(
    r"D:\Projects\GRF_Estimation\vsc data\My_Left_Input_FullSteps_vsc.csv"
)

# =========================================================
# 2. LOAD FORCEPLATE REFERENCE DATA
# =========================================================
sup = loadmat(r"D:\GRF\SR results\grf_estimates.mat", simplify_cells=True)
left_steps = sup["trials"]["trial_01"]["forceplate"]["left"]

# =========================================================
# 3. MODEL PARAMETERS (FINAL VALIDATED)
# =========================================================
dt1 = 0.045              # impact duration (corrected)
B2_factor = 0.38         # peak timing
threshold = 40           # contact detection
x_new = np.linspace(0, 100, 101)

# =========================================================
# 4. FUNCTION: BUILD vGRF FOR ONE STEP
# =========================================================
def compute_vgrf(tc, A1, A2):

    t = np.linspace(0, tc, 500)

    # ---- F1 (impact) ----
    F1 = np.zeros_like(t)
    idx1 = (t >= 0) & (t <= 2 * dt1)
    F1[idx1] = (A1 / 2) * (1 + np.cos(((t[idx1] - dt1) / dt1) * np.pi))

    # ---- F2 (active force) ----
    B2 = B2_factor * tc
    C2L = B2
    C2T = tc - B2

    F2 = np.zeros_like(t)

    idxL = (t >= 0) & (t <= B2)
    F2[idxL] = (A2 / 2) * (1 + np.cos(((t[idxL] - B2) / C2L) * np.pi))

    idxR = (t > B2) & (t <= tc)
    F2[idxR] = (A2 / 2) * (1 + np.cos(((t[idxR] - B2) / C2T) * np.pi))

    F2[F2 < 0] = 0

    FT = F1 + F2

    return t, FT


# =========================================================
# 5. FUNCTION: APPLY CONTACT DETECTION + NORMALIZATION
# =========================================================
def normalize_step(force):

    idx = np.where(force > threshold)[0]
    contact = force[idx[0]:idx[-1] + 1]

    x_old = np.linspace(0, 100, len(contact))
    norm = np.interp(x_new, x_old, contact)

    return norm


# =========================================================
# 6. SINGLE STEP ANALYSIS (STEP 1)
# =========================================================
i = 0

tc = T_contacts.loc[i, "ContactTime_s"]
A1 = T_contacts.loc[i, "A1_N"]
A2 = T_contacts.loc[i, "F2avg_N"]

_, FT = compute_vgrf(tc, A1, A2)
pred_norm = normalize_step(FT)

# ---- Reference ----
F3D = np.asarray(left_steps[i]["forceplate_truth_3d"]["raw"])
Fz = F3D[:, 2]
ref_norm = normalize_step(Fz)

# ---- RMSE ----
rmse = np.sqrt(np.mean((pred_norm - ref_norm)**2))

print("RMSE =", rmse)

# =========================================================
# 7. ALL STEPS PROCESSING
# =========================================================
all_steps = []

for i in range(len(T_contacts)):

    tc = T_contacts.loc[i, "ContactTime_s"]
    A1 = T_contacts.loc[i, "A1_N"]
    A2 = T_contacts.loc[i, "F2avg_N"]

    _, FT = compute_vgrf(tc, A1, A2)
    pred_norm_step = normalize_step(FT)

    if i < len(left_steps):
        F3D = np.asarray(left_steps[i]["forceplate_truth_3d"]["raw"])
        Fz = F3D[:, 2]
        ref_norm_step = normalize_step(Fz)
    else:
        ref_norm_step = np.full_like(x_new, np.nan)

    for j in range(len(x_new)):
        all_steps.append({
            "Step": i + 1,
            "Percent_Stance": x_new[j],
            "Predicted_vGRF": pred_norm_step[j],
            "Reference_vGRF": ref_norm_step[j]
        })

T_all_steps = pd.DataFrame(all_steps)

# =========================================================
# 8. STEP SUMMARY
# =========================================================
summary = T_all_steps.groupby("Step")["Predicted_vGRF"].agg(["mean", "max"]).reset_index()
summary.columns = ["Step", "Mean_vGRF", "Peak_vGRF"]

# =========================================================
# 9. SAVE RESULTS
# =========================================================
save_path = Path(r"D:\Projects\GRF_Estimation\vsc data\GRF_FINAL_SUBMISSION.xlsx")

T_single = pd.DataFrame({
    "Percent_Stance": x_new,
    "Predicted_vGRF": pred_norm,
    "Reference_vGRF": ref_norm
})

T_metrics = pd.DataFrame({
    "Metric": ["RMSE", "dt1", "B2_factor"],
    "Value": [rmse, dt1, B2_factor]
})

with pd.ExcelWriter(save_path, engine="openpyxl", mode="w") as writer:
    T_contacts.to_excel(writer, sheet_name="Inputs", index=False)
    summary.to_excel(writer, sheet_name="Step_Summary", index=False)
    T_single.to_excel(writer, sheet_name="Single_Step", index=False)
    T_all_steps.to_excel(writer, sheet_name="All_Steps", index=False)
    T_metrics.to_excel(writer, sheet_name="Metrics", index=False)

print("✅ Final submission file saved:", save_path)

# =========================================================
# 10. FINAL PLOT
# =========================================================
plt.figure()
plt.plot(x_new, pred_norm, 'k', label='Predicted')
plt.plot(x_new, ref_norm, 'b', label='Reference')
plt.xlabel('% Stance')
plt.ylabel('Force (N)')
plt.title('Final vGRF Comparison')
plt.legend()
plt.grid(True)
plt.show()