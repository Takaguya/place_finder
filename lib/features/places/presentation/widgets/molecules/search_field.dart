import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// The search box. It reports what the user types and shows whatever [text] it
/// is given, so the text can be cleared from elsewhere.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          hintText: 'Search malls, food or an area',
          prefixIcon: const Icon(Icons.search, color: AppColors.ink),
          suffixIcon: widget.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, color: AppColors.ink),
                  onPressed: () => widget.onChanged(''),
                ),
        ),
      ),
    );
  }
}
