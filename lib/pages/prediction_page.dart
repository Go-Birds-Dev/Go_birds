import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../domain/preprocess_kind.dart';
import '../domain/resolved_model.dart';
import '../services/tflite_model_service.dart';
import '../widgets/model_selector.dart';
import 'dart:developer' as developer;

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  List<String>? _classNames;
  final Map<String, String> _commonNames = const {
    // Especies VGG16/MobileNetV2
    'Ara ararauna': 'Guacamayo Azuliamarillo',
    'Chroicocephalus ridibundus': 'Gaviota Reidora',
    'Eubucco bourcierii': 'Cabezón Cabecirrojo',
    'Laterallus albigularis': 'Polluela Carrasqueadora',
    'Melanerpes formicivorus': 'Carpintero Bellotero',
    'Patagioenas subvinacea': 'Paloma Vinosa',
    'Platalea ajaja': 'Espátula Rosada',
    'Rynchops niger': 'Rayador Americano',
    'Theristicus caudatus': 'Bandurria Común',
    'Vultur gryphus': 'Cóndor Andino',
    // Especies DenseNet
    'Anisognathus igniventris': 'Tángara de Vientre Naranja',
    'Arremon auantiirostris': 'Rascador Piquinaranja',
    'Basileuterus rufifrons': 'Reinita de Corona Roja',
    'Columba livia': 'Paloma Doméstica',
    'Grallaria ruficapilla': 'Tororoi Cabecicastaño',
    'Pachyramphus versicolor': 'Anambé Versicolor',
    'Pheucticus ludovicianus': 'Picogrueso Pechirrosado',
    'Pipra mentalis': 'Saltarín Cabeciamarillo',
    'Sturnella magna': 'Turpial Oriental',
    'Thraupis palmarum': 'Tángara de Palmeras',
  };
  final TFLiteModelService _modelService = TFLiteModelService();
  static final List<ResolvedModel> _catalog = [
    ResolvedModel(
      specId: 'vgg16',
      displayName: 'VGG16',
      preprocessKind: PreprocessKind.vgg16MeanBGR,
      modelPath: 'assets/models/vgg16_aves.tflite',
      labelsPath: 'assets/classes.txt',
      usesBundledModel: true,
      usesBundledLabels: true,
    ),
    ResolvedModel(
      specId: 'mobilenet_v2',
      displayName: 'MobileNetV2',
      preprocessKind: PreprocessKind.mobilenet255,
      modelPath: 'assets/models/mobilenet_v2_aves.tflite',
      labelsPath: 'assets/classes.txt',
      usesBundledModel: true,
      usesBundledLabels: true,
    ),
    ResolvedModel(
      specId: 'densenet',
      displayName: 'DenseNet',
      preprocessKind: PreprocessKind.mobilenet255,
      modelPath: 'assets/models/modelo_final_densenet.tflite',
      labelsPath: 'assets/classes_densenet.txt',
      usesBundledModel: true,
      usesBundledLabels: true,
    ),
  ];

  String _selectedModel = _catalog.first.modelPath;
  String _selectedSpecId = _catalog.first.specId;
  bool _loading = false;
  String? _modelStatus;
  File? _selectedImageFile;
  img.Image? _selectedImagePreview;
  List<double>? _prediction;
  String? _predictionLabel;
  String? _topSpeciesName; // Nombre científico de la especie predicha

  @override
  void initState() {
    super.initState();
    _loadClassNames();
    _loadModel(_selectedModel);
  }

  Future<void> _loadClassNames() async {
    try {
      final model = _catalog.firstWhere(
        (m) => m.modelPath == _selectedModel,
        orElse: () => _catalog.first,
      );
      final classesFile = model.labelsPath;
      
      final content = await rootBundle.loadString(classesFile);
      final lines = content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      developer.log('Clases cargadas: ${lines.length} desde $classesFile');
      for (int i = 0; i < lines.length; i++) {
        developer.log('Clase $i: ${lines[i]}');
      }
      setState(() {
        _classNames = lines;
        _modelStatus = 'Clases cargadas: ${lines.length}';
      });
    } catch (e) {
      developer.log('Error cargando clases: $e', error: e);
      setState(() {
        _classNames = null;
        _modelStatus = 'Error cargando clases: $e';
      });
    }
  }

  Future<void> _loadModel(String assetPath) async {
    setState(() {
      _loading = true;
      _modelStatus = 'Cargando modelo...';
    });
    try {
      await _modelService.loadModel(assetPath);
      setState(() {
        final meta = _catalog.firstWhere((m) => m.modelPath == assetPath);
        _modelStatus = 'Modelo cargado: ${meta.displayName}';
        _selectedModel = assetPath;
        _selectedSpecId = meta.specId;
      });
      // Cargar las clases correspondientes al nuevo modelo
      await _loadClassNames();
    } catch (e) {
      setState(() {
        _modelStatus = 'Error al cargar el modelo';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _modelService.close();
    super.dispose();
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile == null) return;

    // Crop image (opcional, puedes quitar si no quieres crop)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Recortar imagen',
        ),
      ],
    );
    final file = File(croppedFile?.path ?? pickedFile.path);
    setState(() {
      _selectedImageFile = file;
      _prediction = null;
      _predictionLabel = null;
      _topSpeciesName = null;
    });
    // Ya no ejecutamos predicción aquí, solo guardamos la imagen
  }

  Future<void> _runPrediction() async {
    if (_selectedImageFile == null) return;
    final imageFile = _selectedImageFile!;
    setState(() {
      _loading = true;
      _modelStatus = 'Procesando imagen...';
    });
    try {
      // Leer bytes y decodificar imagen
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');
      // Preprocesar igual que en Streamlit
      final inputSize = 224; // VGG16 y MobileNetV2 usan 224x224
      final resized = img.copyResize(image, width: inputSize, height: inputSize);
      // Normalizar: VGG16 usa preprocess_input, MobileNetV2 usa x/255
      List<double> input;
      if (_selectedModel.contains('vgg16')) {
        // VGG16: RGB, float32, - Imagen a [0,255], luego: imagen - [103.939, 116.779, 123.68] (BGR)
        // Convertir a BGR y restar mean
        input = List.generate(inputSize * inputSize * 3, (i) {
          final c = i % 3;
          final x = (i ~/ 3) % inputSize;
          final y = (i ~/ 3) ~/ inputSize;
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          if (c == 0) return b - 103.939; // B
          if (c == 1) return g - 116.779; // G
          return r - 123.68; // R
        });
      } else {
        // MobileNetV2: RGB, float32, [0,1]
        input = List.generate(inputSize * inputSize * 3, (i) {
          final c = i % 3;
          final x = (i ~/ 3) % inputSize;
          final y = (i ~/ 3) ~/ inputSize;
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          if (c == 0) return r / 255.0;
          if (c == 1) return g / 255.0;
          return b / 255.0;
        });
      }
      // Convertir a Float32List y dar forma [1, 224, 224, 3]
      final inputTensor = Float32List.fromList(input).reshape([1, inputSize, inputSize, 3]);
      final interpreter = _modelService.interpreter;
      if (interpreter == null) throw Exception('Modelo no cargado');
      final outputShape = interpreter.getOutputTensor(0).shape;
      final output = Float32List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);
      interpreter.run(inputTensor, output);
      // Softmax si es necesario
      List<double> probs = List<double>.from(output.expand((e) => e is List ? e : [e]));
      final sum = probs.fold(0.0, (a, b) => a + b);
      if (sum < 0.99 || sum > 1.01) {
        probs = probs.map((v) => v / sum).toList();
      }
      // Mostrar top-3
      List<int> topIdx = List.generate(probs.length, (i) => i);
      topIdx.sort((a, b) => probs[b].compareTo(probs[a]));
      final top3 = topIdx.take(3).toList();
      String top3Text = '';
      String? topSpecies; // Nombre científico del top-1
      
      developer.log('_classNames: $_classNames');
      developer.log('_classNames length: ${_classNames?.length}');
      developer.log('probs length: ${probs.length}');
      developer.log('top3: $top3');
      
      for (int i = 0; i < top3.length; i++) {
        final idx = top3[i];
        final prob = (probs[idx] * 100).toStringAsFixed(2);
        
        // Obtener nombre científico
        String sci = 'Desconocido';
        String com = 'Desconocido';
        
        if (_classNames != null && _classNames!.isNotEmpty && idx >= 0 && idx < _classNames!.length) {
          sci = _classNames![idx];
          com = _commonNames[sci] ?? sci;
          developer.log('Índice $idx -> Sci: $sci, Com: $com');
        } else {
          developer.log('Índice $idx fuera de rango o clases null');
        }
        
        // Guardar la especie top-1
        if (i == 0) {
          topSpecies = sci;
          top3Text += '🥇 ${i + 1}. $com\n';
        } else if (i == 1) {
          top3Text += '🥈 ${i + 1}. $com\n';
        } else {
          top3Text += '🥉 ${i + 1}. $com\n';
        }
        top3Text += '   Científico: $sci\n';
        top3Text += '   Confianza: $prob%\n';
        if (i < 2) top3Text += '\n'; // Espacio entre elementos
      }
      setState(() {
        _selectedImagePreview = resized;
        _prediction = probs;
        _predictionLabel = top3Text.trim();
        _topSpeciesName = topSpecies;
        _modelStatus = 'Predicción realizada';
      });
    } catch (e) {
      setState(() {
        _modelStatus = 'Error en la predicción: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _selectedImageFile != null
                    ? CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.teal,
                        backgroundImage: FileImage(_selectedImageFile!),
                      )
                    : const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.image, size: 48, color: Colors.white),
                      ),
                const SizedBox(height: 24),
                Text(
                  'Sube una imagen de un ave',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Elige una foto para identificar la especie. Pronto verás aquí los resultados de la predicción.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ModelSelector(
                  models: _catalog,
                  selectedSpecId: _selectedSpecId,
                  onSelected: (specId) {
                    final m = _catalog.firstWhere((x) => x.specId == specId);
                    _loadModel(m.modelPath);
                  },
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : _modelStatus != null
                        ? Text(_modelStatus!, style: const TextStyle(color: Colors.teal))
                        : const SizedBox.shrink(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _showImageSourceActionSheet(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleccionar imagen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loading || _selectedImageFile == null ? null : _runPrediction,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Realizar predicción'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),
                // Sección de comparación de imágenes (cuando hay predicción)
                if (_predictionLabel != null && _topSpeciesName != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Comparación',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Imagen capturada
                          Column(
                            children: [
                              Text('Tu foto', style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal, width: 2),
                                ),
                                child: _selectedImageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          // Imagen de referencia
                          Column(
                            children: [
                              Text('Referencia', style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/bird_references/$_topSpeciesName.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                // Resultados de predicción
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  child: _predictionLabel != null
                      ? Text(
                          _predictionLabel!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                            height: 1.8,
                            fontSize: 15,
                          ),
                        )
                      : Text(
                          'Selecciona una imagen y haz clic en "Realizar predicción"',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
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
