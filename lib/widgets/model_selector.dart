import 'package:flutter/material.dart';

class ModelSelector extends StatefulWidget {
  final List<Map<String, String>> models;
  final void Function(String) onModelSelected;
  final String selectedModel;

  const ModelSelector({
    super.key,
    required this.models,
    required this.onModelSelected,
    required this.selectedModel,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.selectedModel,
      items: widget.models
          .map((model) => DropdownMenuItem(
                value: model['asset']!,
                child: Text(model['name']!),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          widget.onModelSelected(value);
        }
      },
    );
  }
}
