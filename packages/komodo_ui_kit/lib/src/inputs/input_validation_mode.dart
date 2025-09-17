/// Defines the modes of validation for the `UiTextFormField`.
///
/// - `aggressive`: Validate on every input change.
/// - `passive`: Validate on focus loss and form submission.
/// - `lazy`: Validate only on form submission.
/// - `eager`: Validate on focus loss and subsequent input changes.
enum InputValidationMode { aggressive, passive, lazy, eager }
