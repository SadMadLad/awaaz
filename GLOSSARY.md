# Terms and Definitions for Audio Processing

- **PCM (Pulse Code Modulation):** A method to convert analog audio signals into digital form by sampling the signal's amplitude at regular intervals.
- **RMS (Root Mean Square)**: Basically measures the average signal's power or loudness of time.
- **Spectral Bandwidth:** Calculation of variation of frequencies around the spectral centroid of the audio. Low bandwidth indicates low variation in audio and the audio is concentrated around the centroid. Like a flute note. Higher bandwidth highlights noisy, loud sound, like a distorted guitar.
- **Spectral Centroid**: It tells us about the 'center of mass' of the sound. Intuitively, lower spectral centroid score means bassier, muffled sound while high centroid value indicates bright, sharp, tinny audio.
- **Spectral Rolloff:** Measures the frequency below which a certain percentage of the total spectral energy is contained. Low rolloff - more energy is concentrated in lower frequencies, like drums, bass, male voices. High rolloff - significant energy in high frequencies like female voice, hissing sound etc.
- **ZCR (Zero Crossing Rate)**: Counts how many times the audio changes signal from positive to negative and vice versa. If ZCR is high, the audio is noisy, sharp or high-pitched. And an audio with low ZCR is smooth, steady or low-pitched.
