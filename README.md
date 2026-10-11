# Tugas 2 IF4073 Pemrosesan Citra Digital

Aplikasi MATLAB untuk pemrosesan citra di **ranah frekuensi**: filtering, peningkatan kecerahan, penghilangan noise periodik, dan restorasi citra akibat motion blur. Semua filter diimplementasikan sendiri (FFT → kalikan dengan H(u,v) → inverse FFT), dan seluruhnya dapat dicoba lewat satu GUI.

## Fitur

| Tab | Topik | Metode |
|-----|-------|--------|
| B | Smoothing / blurring | Low-pass: ILPF, GLPF, BLPF |
| C | High-pass filtering | High-pass: IHPF, GHPF, BHPF |
| D | Peningkatan kecerahan | Enhancement di ranah frekuensi |
| E | Restorasi noise periodik | Band reject dan Notch reject (Ideal, Butterworth, Gaussian) |
| F | Restorasi motion blur | Inverse filtering dan Wiener filtering dengan PSF motion blur |

Fitur GUI:
- Mendukung citra grayscale dan berwarna.
- Setiap parameter punya slider dan kotak angka yang saling terhubung.
- Hasil dihitung ulang otomatis saat parameter berubah (tanpa tombol "terapkan").
- Menampilkan spektrum frekuensi dan filter H(u,v).

## Prasyarat

- MATLAB R2026a / versi yang kompatibel
- Image Processing Toolbox (`imshow`, `im2double`, `psnr`, dst.)

## Cara Menjalankan

1. Clone repo ini.
2. Buka MATLAB, lalu pindah ke folder root repo (atau folder `src/gui`).
3. Jalankan:

   ```matlab
   main_gui
   ```

   Seluruh folder `src` ditambahkan ke path secara otomatis.
4. Pilih tab (B–F), klik tombol untuk memuat citra dari folder `data/<tab>/input/`, lalu atur parameter dengan slider.

Fungsi juga dapat dipanggil langsung tanpa GUI, misalnya:

```matlab
img = imread('data/B_smoothing_blurring_frequency/input/grass_gray_gaussian_noise.png');
[out, H, spec] = lowpass_filter(img, 'gaussian', 40);
imshow(out)
```

## Struktur Repo

```text
.
├── README.md
├── data/                            # citra uji (input/ dan reference/ per bagian)
│   ├── B_smoothing_blurring_frequency/
│   ├── C_high_pass_filtering_frequency/
│   ├── D_brightness_frequency/
│   ├── E_periodic_noise_restoration/
│   └── F_motion_blur_restoration/   # README berisi parameter PSF tiap citra
└── src/
    ├── gui/
    │   └── main_gui.m               # GUI utama (tab B–F)
    ├── functions/
    │   ├── lowpass_filter.m         # ILPF, GLPF, BLPF
    │   ├── highpass_filter.m        # IHPF, GHPF, BHPF
    │   ├── enhance_brightness.m     # peningkatan kecerahan
    │   ├── bandreject_filter.m      # band reject (Ideal, Butterworth, Gaussian)
    │   ├── notch_reject_filter.m    # notch reject (Ideal, Butterworth, Gaussian)
    │   ├── motion_blur_psf.m        # PSF motion blur (panjang, sudut)
    │   ├── inverse_filter.m         # inverse filtering
    │   └── wiener_filter.m          # Wiener filtering
    └── utils/
        ├── freq_grid.m              # jarak D(u,v) dari pusat spektrum
        ├── show_spectrum.m          # spektrum magnitudo (skala log)
        └── apply_freq_filter.m      # FFT → kali H → inverse FFT (gray & color)
```

## Data Uji

Gunakan seluruh citra pada subfolder `input/`. Subfolder `reference/` (bila ada) hanya dipakai sebagai ground truth untuk perbandingan.

Parameter motion blur untuk bagian F (panjang L, sudut A):

| Citra | L | A |
|-------|---|---|
| astronaut_color_motion_L19_A20 (+ gaussian noise) | 19 | 20° |
| retina_color_motion_L15_A-25 (+ gaussian noise) | 15 | -25° |
| coins_gray_motion_L23_A35 | 23 | 35° |
| brick_gray_motion_L17_A0 | 17 | 0° |

## Antarmuka Fungsi

```matlab
[out, H, spec] = lowpass_filter(img, type, D0, n)
[out, H, spec] = highpass_filter(img, type, D0, n, displayMode)
[out, H, spec] = enhance_brightness(img, params)
[out, H]       = bandreject_filter(img, D0, W, type, n)
[out, H]       = notch_reject_filter(img, centers, D0, type, n)
[blurred, PSF] = motion_blur_psf(img, len, theta)
[out, H]       = inverse_filter(img, PSF, radius, threshold)
[out, H, W]    = wiener_filter(img, PSF, K)
```

`type` bernilai `'ideal'`, `'gaussian'`, atau `'butterworth'`; `n` adalah orde Butterworth (default 2).

## Author
- Wilson / 18223012
- Derick Amadeus Budiono / 18223090
