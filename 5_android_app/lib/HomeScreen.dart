import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:kapasai/ChatbotPage.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _detectInsect = true;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _result = "";

  bool _isModelLoading = false;
  bool _isPredicting = false;
  bool _modelLoaded = false;

  bool? _loadedModelIsInsect;

  Interpreter? _interpreter;
  List<String> _labels = [];

  static const String _insectModelPath =
      "assets/models/cotton_insect_mobilenetv2_float16.tflite";
  static const String _insectLabelsPath = "assets/models/insect_labels.txt";
  static const String _leafModelPath =
      "assets/models/cotton_leaf_mobilenetv2_float16.tflite";
  static const String _leafLabelsPath = "assets/models/cotton_leaf_labels.txt";

  static const int _inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    if (!mounted) return;
    if (_modelLoaded && _loadedModelIsInsect == _detectInsect) return;
    if (_isModelLoading) return;

    setState(() {
      _isModelLoading = true;
      _modelLoaded = false;
    });

    try {
      _interpreter?.close();
      _interpreter = null;
      _labels = [];

      final String modelPath = _detectInsect
          ? _insectModelPath
          : _leafModelPath;
      final String labelsPath = _detectInsect
          ? _insectLabelsPath
          : _leafLabelsPath;

      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);

      debugPrint(
        "Input tensor shape: ${_interpreter!.getInputTensor(0).shape}",
      );
      debugPrint(
        "Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}",
      );

      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) {
            final arrowSplit = line.split('->');
            if (arrowSplit.length >= 2) return arrowSplit[1].trim();
            final spaceSplit = line.split(RegExp(r'\s+'));
            if (spaceSplit.length >= 2 && int.tryParse(spaceSplit[0]) != null) {
              return spaceSplit.sublist(1).join(' ').trim();
            }
            return line;
          })
          .toList();

      debugPrint("Labels loaded (${_labels.length}): $_labels");

      if (!mounted) return;
      setState(() {
        _modelLoaded = true;
        _loadedModelIsInsect = _detectInsect;
      });
    } catch (e) {
      debugPrint("Model load error: $e");
      if (!mounted) return;
      setState(() {
        _modelLoaded = false;
        _loadedModelIsInsect = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    }
  }

  Float32List _preprocessImage(File imageFile) {
    final rawBytes = imageFile.readAsBytesSync();
    img.Image? original = img.decodeImage(rawBytes);
    if (original == null) throw Exception("Image decode nahi hua");

    final resized = img.copyResize(
      original,
      width: _inputSize,
      height: _inputSize,
    );

    final input = Float32List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r.toDouble();
        input[pixelIndex++] = pixel.g.toDouble();
        input[pixelIndex++] = pixel.b.toDouble();
      }
    }
    return input;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPredicting) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = "";
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image select karne mein masla: $e")),
        );
      }
    }
  }

  Future<void> _predictImage() async {
    if (_image == null || _isPredicting) return;

    if (_isModelLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        return _isModelLoading;
      });
    }

    if (!_modelLoaded || _interpreter == null) {
      await _loadModel();
      if (!_modelLoaded || _interpreter == null) {
        setState(() {
          _result = "❌ Model load nahi hua. App restart karein.";
        });
        return;
      }
    }

    setState(() {
      _isPredicting = true;
      _result = "";
    });

    try {
      final inputData = _preprocessImage(_image!);
      final inputTensor = inputData.reshape([1, _inputSize, _inputSize, 3]);

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final numClasses = outputShape[1];
      final outputBuffer = List.filled(
        1 * numClasses,
        0.0,
      ).reshape([1, numClasses]);

      _interpreter!.run(inputTensor, outputBuffer);

      final List<double> probabilities = List<double>.from(
        outputBuffer[0] as List,
      );

      debugPrint("Model output probabilities: $probabilities");

      // Top class find karo
      int topIndex = 0;
      double topProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > topProb) {
          topProb = probabilities[i];
          topIndex = i;
        }
      }

      final double confidence = topProb * 100;

      final String label = topIndex < _labels.length
          ? _labels[topIndex]
          : "Class $topIndex";

      final capitalLabel = label.isNotEmpty
          ? label[0].toUpperCase() + label.substring(1)
          : label;

      debugPrint(
        "Top: $capitalLabel | Confidence: ${confidence.toStringAsFixed(1)}%",
      );

      final bool isHealthy = capitalLabel.toLowerCase().contains('healthy');

      if (!mounted) return;
      setState(() {
        if (confidence > 50) {
          if (isHealthy) {
            _result =
                "✅ Aapki fasal bilkul theek hai!\n"
                "Koi ${_detectInsect ? 'insect' : 'disease'} nahi mili.\n"
                "Confidence: ${confidence.toStringAsFixed(1)}%";
          } else {
            _result =
                "⚠️ ${_detectInsect ? 'Insect' : 'Disease'}: $capitalLabel\n"
                "Confidence: ${confidence.toStringAsFixed(1)}%";
          }
        } else {
          _result =
              "🔍 $capitalLabel\n"
              "Confidence kam hai: ${confidence.toStringAsFixed(1)}%\n"
              "Dobara clear image lein.";
        }
      });
    } catch (e) {
      debugPrint("Prediction error: $e");
      if (!mounted) return;
      setState(() {
        _result = "❌ Prediction error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF0D5C3A);
    final bool isDark = widget.isDarkMode;

    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final Color btnBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final Color btnBorder = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade300;
    final Color btnFg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF2F2F2),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/logo.png",
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 0),
                        Image.asset(
                          "assets/image.png",
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    if (_isModelLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Good morning, Farmer 🌾",
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Cotton Crop\nIntelligence",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 2,
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Mode Label ────────────────────────────
                      Text(
                        _detectInsect
                            ? "🐛 INSECT DETECTION"
                            : "🍃 DISEASE DETECTION",
                        style: TextStyle(
                          color: subtextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectInsect
                            ? "Apni fasal mein keeray detect karein"
                            : "Pattay ki bimari detect karein",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ── Detection Mode Buttons ────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _detectInsect
                                    ? primaryGreen.withAlpha(30)
                                    : Colors.transparent,
                                foregroundColor: _detectInsect
                                    ? primaryGreen
                                    : subtextColor,
                                side: BorderSide(
                                  color: _detectInsect
                                      ? primaryGreen
                                      : btnBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _isPredicting
                                  ? null
                                  : () {
                                      if (!_detectInsect) {
                                        setState(() {
                                          _detectInsect = true;
                                          _result = "";
                                          _image = null;
                                        });
                                        _loadModel();
                                      }
                                    },
                              icon: Icon(
                                Icons.pest_control,
                                size: 18,
                                color: _detectInsect
                                    ? primaryGreen
                                    : subtextColor,
                              ),
                              label: Text(
                                "Insect Detect",
                                style: TextStyle(
                                  color: _detectInsect
                                      ? primaryGreen
                                      : subtextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: !_detectInsect
                                    ? primaryGreen.withAlpha(30)
                                    : Colors.transparent,
                                foregroundColor: !_detectInsect
                                    ? primaryGreen
                                    : subtextColor,
                                side: BorderSide(
                                  color: !_detectInsect
                                      ? primaryGreen
                                      : btnBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _isPredicting
                                  ? null
                                  : () {
                                      if (_detectInsect) {
                                        setState(() {
                                          _detectInsect = false;
                                          _result = "";
                                          _image = null;
                                        });
                                        _loadModel();
                                      }
                                    },
                              icon: Icon(
                                Icons.eco_outlined,
                                size: 18,
                                color: !_detectInsect
                                    ? primaryGreen
                                    : subtextColor,
                              ),
                              label: Text(
                                "Disease Detect",
                                style: TextStyle(
                                  color: !_detectInsect
                                      ? primaryGreen
                                      : subtextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Camera / Gallery Buttons ──────────────
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnBg,
                                foregroundColor: btnFg,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: btnBorder),
                                ),
                              ),
                              onPressed: _isPredicting
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: btnFg,
                              ),
                              label: Text(
                                "Camera",
                                style: TextStyle(
                                  color: btnFg,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnBg,
                                foregroundColor: btnFg,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: btnBorder),
                                ),
                              ),
                              onPressed: _isPredicting
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                              icon: Icon(
                                Icons.photo_library_outlined,
                                color: btnFg,
                              ),
                              label: Text(
                                "Gallery",
                                style: TextStyle(
                                  color: btnFg,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Image Preview ─────────────────────────
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: btnBorder),
                        ),
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_enhance_outlined,
                                    size: 48,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Camera ya Gallery se image lein",
                                    style: TextStyle(color: subtextColor),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  if (_isPredicting)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(140),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "Analyzing...",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ── Predict Button ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            disabledForegroundColor: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          onPressed: (_image == null || _isPredicting)
                              ? null
                              : _predictImage,
                          icon: _isPredicting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.bolt),
                          label: Text(
                            _isPredicting
                                ? "Analyzing..."
                                : _detectInsect
                                ? "Predict Insects"
                                : "Predict Disease",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // ── Model Loading Notice ──────────────────
                      if (_isModelLoading) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "AI model load ho raha hai...",
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Result Box ────────────────────────────
                      if (_result.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _result.startsWith("✅")
                                ? primaryGreen.withAlpha(25)
                                : _result.startsWith("⚠️")
                                ? Colors.orange.withAlpha(25)
                                : _result.startsWith("🔍")
                                ? Colors.blue.withAlpha(25)
                                : Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _result.startsWith("✅")
                                  ? primaryGreen
                                  : _result.startsWith("⚠️")
                                  ? Colors.orange.shade600
                                  : _result.startsWith("🔍")
                                  ? Colors.blue.shade400
                                  : Colors.red.shade400,
                            ),
                          ),
                          child: Text(
                            _result,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _result.startsWith("✅")
                                  ? primaryGreen
                                  : _result.startsWith("⚠️")
                                  ? Colors.orange.shade800
                                  : _result.startsWith("🔍")
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Zarkhez FAB ──────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: SizedBox(
          width: 100,
          height: 100,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/logo.png", width: 60, height: 60),
                  const SizedBox(height: 4),
                  const Text(
                    "Zarkhez",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
