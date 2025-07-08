# Localization

### Add new language to app (step 1)

In `${FLUTTER_PROJECT}/assets/translations`, add the `en.json` template file. For example:

`en.json`

```json
{  
  "helloWorld": "Hello World!"  
}
```

`{}` is used to place arguments and `{name}` for named arguments.

After editing the translation JSON files make sure that every key is listed
in `lib/generated/codegen_loader.g.dart`. The file contains constants used in
the codebase and should be updated manually when new keys are added.

### Step 2

To add a new language translation in the app you need to add an `fr.json` file in the same directory for French translation of the same message:
`fr.json`

```json
{  
  "helloWorld": "Bonjour le Monde"  
}
```

no additional code generation is required.

and update constants.dart file to:

```dart
const List<Locale> localeList = [Locale('en'), Locale('fr')];
```

### Step 3

Translate text
lets suppose we start with this code

`home.dart`

```dart
  
  ..

  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
          Text(
            'Hello World'
          ),
          Text(
            'Welcome'
          ),
        ]
    );
  }

```

and we want to translate `Hello World` text to french when people device localization is french language
`home.dart`

```dart
import 'package:web_dex/localization/app_localizations.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';

  ...
  
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
          Text(
            LocaleKeys.helloWorld.tr() 
          ),
          Text(
            'Welcome'
          ),
        ]
    );
  }
```

### How to translate string with variable

How to translate sentence with the variables in it, say `10` and `KMD` in `Max amount is 10 KMD, please select other amount`?

```dart
  Text('Max amount is $amount $kmd, please select other amount') // amount & kmd is variable
```

Process:

- Add declaration in json file
`en.json`

```json
{  
  "maxMount": "Max amount is {amount} {coinAbbr}, please select other amount"
}
```

- update your code like the following snippet

```dart
  Text(LocaleKeys.maxMount.tr(namedArgs:{amount:10, coinAbbr:'KMD'}))
```

or you can just use arguments like the following example

- Add declaration in json file
`en.json`

```json
{  
  "maxMount": "Max amount is {} {}, please select other amount"  
}
```

- update your code like the following snippet

```dart
  Text(LocaleKeys.maxMount.tr(args:[10,'KMD'])) 
```

how to deal with Plurals?

update the value of required key in json file like following

`en.json`

```json
{
  "money": {
    "zero": "You have no money",
    "one": "You have {} dollar",
    "two": "You have {} dollars",
    "many": "You have {} dollars",
    "few": "You have {} dollars",
    "other": "You have {} dollars"
  },
  "money_args": {
    "zero": "{} has no money",
    "one": "{} has {} dollar",
    "two": "{} has {} dollars",
    "many": "{} has {} dollars",
    "few": "{} has {} dollars",
    "other": "{} has {} dollars"
  }
}
```

- update your code like the following snippet
  
```dart
  Text(LocaleKeys.money.plural(10.23)),
  Text(LocaleKeys.money_args.plural(10.23,args:['John', '10.23'])), 
```

After modifying the translation JSON files, simply restart the application to
load the updated strings; no further code generation is required.
