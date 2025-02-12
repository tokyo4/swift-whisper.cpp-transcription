# 📝 Real-Time Transcription App  
**Powered by [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)**  
Swift | SwiftUI  

## Description  
Effortlessly transcribe audio to text in real time with on-device processing using Whisper.cpp. This app offers multiple preloaded models, performance insights, and a modern SwiftUI design for the ultimate transcription experience.  

## 🚀 Features  
- **Real-Time Transcription:** Accurate, on-device speech-to-text transcription powered by Whisper.cpp.  
- **Multiple Preloaded Models:** Choose from various Whisper models based on your device’s capabilities and transcription requirements.  
- **Performance Metrics:**  
  - Memory usage statistics.  
  - Processing time for each transcription chunk.  
  - Visual tracking of the number of processed chunks.  
- **SwiftUI Design:** A modern, clean, and intuitive user interface.  
- **Privacy Focused:** All processing happens on-device, ensuring user data remains secure.  

## 📸 Screenshots  
(Add screenshots or GIFs showcasing the app UI and features.)  

---

## 🛠️ Installation  

### Prerequisites  
- **iOS 15+**  
- **Xcode 14+**  

### Steps  
1. Clone the repository:  
   ```bash  
   git clone https://github.com/DeepBhupatkar/swift-whisper.cpp-transcription.git
   cd RealTimeTranscriptionExample  
   ```  
2. Build and run the app on a physical device or simulator.  

---

## ⚙️ How It Works  

1. **Model Selection:**  
   
- Select a preloaded Whisper model from the settings menu.
- Supported models include tiny, base, small, medium, and large.
- You can download models from below given link and after downloading, place them inside RealTimeTranscription/Resource/models.

   *Available Models :*
 
    **tiny** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin) (F16, 75 MiB)  
    **tiny-q5_1** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin) (31 MiB)  
    **tiny-q8_0** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q8_0.bin) (42 MiB)  
    **tiny.en** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin) (F16, 75 MiB)  
    **tiny.en-q5_1** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-q5_1.bin) (31 MiB)  
    **tiny.en-q8_0** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-q8_0.bin) (42 MiB)  
    **base-q5_1** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin) (57 MiB)  
    **base-q8_0** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q8_0.bin) (78 MiB)  
    **base.en-q5_1** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q5_1.bin) (57 MiB)  
    **base.en-q8_0** - [Download](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q8_0.bin) (78 MiB)  

2. **Transcription:**  
   - Tap the record button to start transcribing in real time.  
   - The app processes audio in chunks for seamless transcription.  

3. **Device Stats:**  
   - Displays real-time memory usage and chunk processing time to help optimize performance.  

---

## 📊 Performance Metrics  

| Metric             | Description                                                                 | Example Value       |  
|--------------------|-----------------------------------------------------------------------------|--------------------|  
| **Memory Usage**    | Tracks how much memory is utilized by the app during transcription.         | ~200 MB            |  
| **Processing Time** | Measures the time (ms) taken to process each audio chunk.                   | ~50 ms/chunk       |  
| **Chunks Processed**| Tracks how many audio chunks are processed during a transcription session.  | 120 chunks         |  

---

## 🧰 Tools and Technologies  

- **Whisper.cpp:** A lightweight Whisper implementation for fast on-device transcription.  
- **Swift & SwiftUI:** For building a modern and efficient iOS application.  
---

## 🤝 Contributing  

Contributions are welcome!  

1. Fork the repository.  
2. Create a feature branch: `git checkout -b feature-name`.  
3. Commit your changes: `git commit -m 'Add feature'`.  
4. Push to the branch: `git push origin feature-name`.  
5. Submit a pull request.  

---

## 📄 License  

This project is licensed under the MIT License. See the `LICENSE` file for details.  

---

## 🙌 Acknowledgments  

- **Whisper.cpp:** For enabling lightweight, efficient on-device transcription.  
- **OpenAI Whisper:** The foundation for Whisper.cpp’s functionality.  
- Special thanks to the open-source community for contributing to AI advancements.  
