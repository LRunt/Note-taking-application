part of components;

/// Class [StyledTextField] create styled [TextField].
///
/// My own designed textField, it has Icon that show that can helps with orientation.
class StyledTextField extends StatefulWidget {
  /// Indicates if the textField will be used for password or not.
  final bool isPasswordField;

  /// Placeholder text that will be shown inside the textField.
  final String hint;

  /// Controller of the textField. Allows external control of the textField text.
  final TextEditingController controller;

  /// Icon that will be displayed at the beginning of the textField.
  final Icon? pefIcon;

  /// Constructor of the class [StyledTextField]
  const StyledTextField(
      {Key? key,
      required this.isPasswordField,
      required this.hint,
      required this.controller,
      required this.pefIcon})
      : super(key: key);

  @override
  State<StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  /// State if the text inside password textField is visible or not.
  bool isVisible = true;

  /// Changes the visibility of the text inside a textField used to enter password
  void changeVisibility() {
    setState(() {
      isVisible = !isVisible;
    });
  }

  /// Builds the UI of the [TextField].
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPasswordField ? isVisible : false,
      obscuringCharacter: OBSCURE_CHAR,
      decoration: InputDecoration(
        labelText: widget.hint,
        suffixIcon: widget.isPasswordField
            ? IconButton(
                onPressed: changeVisibility,
                icon: isVisible ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
              )
            : null,
        prefixIcon: widget.pefIcon,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(BORDER_RADIUS)),
        ),
      ),
    );
  }
}
