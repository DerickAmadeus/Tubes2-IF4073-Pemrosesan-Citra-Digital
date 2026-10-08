# Tubes2-IF4073-Pemrosesan-Citra-Digital

# Struktur Repo
```text
Tubes 2/
│
├── README.md                      # Informasi utama repositori
│
├── src/                           # Folder khusus source code MATLAB & GUI
│   ├── gui/
│   │   └── main.mlapp             # Main App
│   └── functions/                 # Folder fungsi-fungsi utama pemrosesan citra
│       ├── lowpass_filter.m       # ILPF, GLPF, dan BLPF
│       ├── highpass_filter.m      # IHPF, GHPF, dan BHPF
│       ├── enhance_brightness.m   # Enhance Brightness
│       ├── restore_periodic_noise.m # Bandreject & Notch filter
│       └── restore_motion_blur.m  # Inverse & Wiener filtering
│
├── data/                          # Folder untuk data uji resmi
│   ├── B_smoothing_blurring_frequency/
│   ├── C_high_pass_filtering_frequency/
│   ├── D_brightness_frequency/
│   ├── E_periodic_noise_restoration/
│   └── F_motion_blur_restoration/
│
└── docs/                       
    └── 18223090_NIM2_Tugas2_IF4073.pdf
```