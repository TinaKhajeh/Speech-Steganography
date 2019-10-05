Speech Steganography
==============================
Hiding a secret speech signal in another carrier speech signal is the main goal of the project. According to the nature of
speech signals which is limited frequency bound, High-frequency components of the carrier are used to place the secret.
At the sender side, LPC coefficients of secret are hidden in the magnitude part of the Fast Fourier Transformation of high
frequencies which are calculated using Wavelet transformation.
