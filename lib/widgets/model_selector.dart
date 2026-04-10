import 'package:flutter/material.dart';

import '../domain/resolved_model.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({
    super.key,
    required this.models,
    required this.selectedSpecId,
    required this.onSelected,
    this.enabled = true,
  });

  final List<ResolvedModel> models;
  final String? selectedSpecId;
  final void Function(String specId) onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return const Text('Sin modelos disponibles');
    }
    final value = selectedSpecId != null &&
            models.any((m) => m.specId == selectedSpecId)
        ? selectedSpecId!
        : models.first.specId;

    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      items: models
          .map(
            (m) => DropdownMenuItem(
              value: m.specId,
              enabled: enabled && m.isReady,
              child: Text(
                m.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (id) {
              if (id != null) onSelected(id);
            }
          : null,
    );
  }
}
