# student_match_flutter

A new Flutter project.

## Getting Started

## Ordnerstruktur

| Ordner              | Inhalt                              | Zweck (Der „Job“ des Ordners) |
|---------------------|--------------------------------------|--------------------------------|
| `lib/models/`       | Dart-Klassen (z. B. `student_model.dart`) | Die **Daten-Baupläne**. Hier definierst du, wie ein Student oder ein Interview aussieht. Reiner Code ohne Logik – nur Datenfelder und „Übersetzer“ für Firebase. |
| `lib/repositories/` | Firebase-Service-Klassen             | Die **Außenminister**. Diese Klassen kommunizieren mit der Außenwelt (Firebase). Hier steht, wie man sich einloggt oder Daten aus der Datenbank lädt. Die View kennt Firebase nicht direkt. |
| `lib/viewmodels/`   | Logik-Klassen      | Das **Gehirn**. Verarbeitet die Logik. Die View sagt z. B. „Login“, das ViewModel fragt das Repository und meldet der View zurück: „Fertig – UI aktualisieren“. |
| `lib/views/`        | Flutter Widgets (Screens)            | Das **Gesicht**. Reiner UI-Code (Buttons, Texte, Layouts). Keine Logik – nur Events, die Funktionen im ViewModel aufrufen. |
| `lib/core/`         | Konstanten, Styles, Hilfsfunktionen  | Die **Werkzeugkiste**. Gemeinsame Dinge wie App-Farben, Schriftarten, Konstanten oder Firebase-Konfiguration. |

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
