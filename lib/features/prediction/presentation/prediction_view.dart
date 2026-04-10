import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/reference_asset.dart';
import '../../../widgets/model_selector.dart';
import '../bloc/model_sync_cubit.dart';
import '../bloc/model_sync_state.dart';
import '../bloc/prediction_bloc.dart';
import '../bloc/prediction_event.dart';
import '../bloc/prediction_state.dart';

class PredictionView extends StatelessWidget {
  const PredictionView({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile == null || !context.mounted) return;

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
    if (!context.mounted) return;
    final file = File(croppedFile?.path ?? pickedFile.path);
    context.read<PredictionBloc>().add(PredictionImagePicked(file));
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickImage(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ModelSyncCubit, ModelSyncState>(
      listenWhen: (prev, curr) => !curr.isRefreshing && prev.isRefreshing,
      listener: (context, syncState) {
        context
            .read<PredictionBloc>()
            .add(PredictionCatalogUpdated(syncState.models));
      },
      child: BlocConsumer<PredictionBloc, PredictionState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, pred) {
          final sync = context.watch<ModelSyncCubit>().state;
          final topSci = pred.result?.topScientificName;
          final summary = pred.result?.formattedSummary;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sync.isRefreshing)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(),
                          ),
                        if (sync.warning != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              sync.warning!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (sync.lastSyncedAt != null && !sync.isRefreshing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Modelos: ${sync.lastSyncedAt!.toLocal()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: sync.isRefreshing
                                  ? null
                                  : () => context
                                      .read<ModelSyncCubit>()
                                      .refresh(),
                              icon: const Icon(Icons.sync, size: 18),
                              label: const Text('Actualizar modelos'),
                            ),
                          ],
                        ),
                        pred.imageFile != null
                            ? CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.teal,
                                backgroundImage: FileImage(pred.imageFile!),
                              )
                            : const CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.image,
                                    size: 48, color: Colors.white),
                              ),
                        const SizedBox(height: 24),
                        Text(
                          'Sube una imagen de un ave',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Elige una foto para identificar la especie.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ModelSelector(
                          models: pred.catalog,
                          selectedSpecId: pred.selectedSpecId,
                          enabled: !pred.isBusy && pred.catalog.isNotEmpty,
                          onSelected: (id) => context
                              .read<PredictionBloc>()
                              .add(PredictionModelSelected(id)),
                        ),
                        const SizedBox(height: 24),
                        pred.isBusy
                            ? const CircularProgressIndicator()
                            : pred.statusMessage != null
                                ? Text(
                                    pred.statusMessage!,
                                    style:
                                        const TextStyle(color: Colors.teal),
                                  )
                                : const SizedBox.shrink(),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: pred.isBusy
                              ? null
                              : () => _showImageSourceActionSheet(context),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Seleccionar imagen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: pred.isBusy ||
                                  pred.imageFile == null ||
                                  pred.selectedResolved == null
                              ? null
                              : () => context
                                  .read<PredictionBloc>()
                                  .add(PredictionRunRequested()),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Realizar predicción'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (summary != null && topSci != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Comparación',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text('Tu foto',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.teal, width: 2),
                                        ),
                                        child: pred.imageFile != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.file(
                                                  pred.imageFile!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text('Referencia',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.orange, width: 2),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.asset(
                                            referenceAssetForScientificName(
                                                topSci),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey[400],
                                                ),
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
                        Container(
                          constraints: const BoxConstraints(minHeight: 80),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal, width: 2),
                          ),
                          child: summary != null
                              ? Text(
                                  summary,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.w600,
                                        height: 1.8,
                                        fontSize: 15,
                                      ),
                                )
                              : Text(
                                  'Selecciona una imagen y haz clic en "Realizar predicción"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
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
        },
      ),
    );
  }
}
