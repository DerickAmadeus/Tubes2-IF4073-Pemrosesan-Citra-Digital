# Tubes2-IF4073-Pemrosesan-Citra-Digital

# Struktur Repo
```text
Tubes2/
├── README.md                 # name, description, toolboxes, how to run (required!)
├── .gitignore
│
├── src/
│   ├── gui/
│   │   └── main.mlapp
│   ├── functions/
│   │   ├── lowpass_filter.m          # ILPF, GLPF, BLPF
│   │   ├── highpass_filter.m         # IHPF, GHPF, BHPF
│   │   ├── enhance_brightness.m
│   │   ├── bandreject_filter.m       # Ideal, Butterworth, Gaussian
│   │   ├── notch_reject_filter.m
│   │   ├── restore_periodic_noise.m  # uses the two filters above
│   │   ├── motion_blur_psf.m         # builds H(u,v)
│   │   ├── inverse_filter.m
│   │   └── wiener_filter.m
│   └── utils/                # shared helpers
│       ├── freq_grid.m       # distance D(u,v) from the center
│       ├── show_spectrum.m   # log magnitude spectrum
│       └── apply_freq_filter.m  # FFT → multiply by H → inverse FFT (gray + color)
│
├── scripts/                  # NEW
│   ├── run_all_B.m ... run_all_F.m   # process every input image
│   └── compare_builtin.m             # deconvwnr etc. ONLY as comparison
│
├── data/                     # test images
├── results/                  # saved outputs
└── docs/
    └── NIM1_NIM2_Tugas2_IF4073.pdf
```

