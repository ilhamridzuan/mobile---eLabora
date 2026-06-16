import 'package:flutter/material.dart';

/// Reusable dropdown widget with built-in validation and error display
/// Provides consistent styling and accessibility features
class ValidatedDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? hint;
  final String? errorText;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool enabled;
  final String? Function(T?)? validator;

  const ValidatedDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    this.hint,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine if field has error
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Semantics(
          label: label,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: hasError ? Colors.red.shade700 : colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        
        // Dropdown field
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: null, // We'll show error below manually
            filled: !enabled,
            fillColor: !enabled ? colorScheme.surfaceVariant.withOpacity(0.3) : null,
            
            // Suffix icon for error state
            suffixIcon: hasError
                ? Icon(Icons.error_outline, color: Colors.red.shade700)
                : null,
            
            // Border styling
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.25),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError 
                    ? Colors.red.shade700 
                    : colorScheme.outline.withOpacity(0.25),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade700 : colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.15),
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade700,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade700,
                width: 2,
              ),
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5),
          ),
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        
        // Error message
        if (hasError) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
