
import wave
import math
import struct

# Audio parameters
sample_rate = 44100
duration = 0.5  # seconds
frequency = 880.0  # Hz (A5)

# Generate audio data
num_samples = int(sample_rate * duration)
data = []
for i in range(num_samples):
    sample = 32767.0 * math.sin(2.0 * math.pi * frequency * i / sample_rate)
    data.append(int(sample))

# Write to WAV file
file_path = "assets/audio/notification.wav"
with wave.open(file_path, 'w') as wav_file:
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(2)  # 16-bit
    wav_file.setframerate(sample_rate)
    for sample in data:
        wav_file.writeframes(struct.pack('<h', sample))

print(f"Generated {file_path}")
