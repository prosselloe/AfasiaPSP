# Blueprint: Afàsia PSP App

## Visió General

Aquesta aplicació Flutter serà una eina d'assistència per a la logopèdia, aprofitant la intel·ligència artificial de Gemini a través de Firebase. L'objectiu és crear una experiència d'usuari moderna, accessible i visualment atractiva que ofereixi funcionalitats innovadores per a pacients i professionals.

## Disseny i Estil (Versió Actual)

- **Tema:** Material Design 3, amb un `ColorScheme` generat a partir d'un color llavor (`Colors.deepPurple`).
- **Tipografia:** `google_fonts` per a una estètica neta i llegible (Oswald per a títols, Roboto per al cos).
- **Mode Clar/Fosc:** Suport per a temes clar i fosc amb un commutador a l'aplicació.
- **Arquitectura:**
    - **Gestió d'estat:** `provider` per a la gestió de l'estat global (com el tema) i `ValueNotifier` per a l'estat local.
    - **Persistència local:** `shared_preferences` per guardar l'historial de converses.
    - **Estructura de fitxers:** Organització per funcionalitats per garantir l'escalabilitat.
- **Components:** Estils personalitzats per a `AppBar` i `ElevatedButton` per a una aparença consistent en tots dos temes.

## Tasques Realitzades

### Implementació de Persistència de l'Historial de Conversa
Es va solucionar el problema de la pèrdua de context del Logopeda IA integrant `shared_preferences`. L'historial s'inclou en cada prompt per mantenir la continuïtat de la sessió.

### Sistema de Sessions i Historial amb Dates
**Objectiu:** Proporcionar una cronologia real de les sessions de logopèdia realitzades per la pacient.

1.  **Estructura de Metadades:** S'ha implementat un sistema d'encapsulació de dades on cada missatge es guarda amb una marca de temps estructurada: `|dd/MM/yyyy HH:mm|`. Això permet un seguiment en temps real i precís de quan s'ha produït cada interacció sense trencar la compatibilitat amb el format de text pla existent.
2.  **Lògica de Reconstrucció Històrica:** Per a les dades prèvies a la implementació del sistema de metadades, s'ha desenvolupat un algorisme de reconstrucció basat en la proposta del Product Owner:
    *   L'última sessió detectada s'assigna a la data actual.
    *   Cada sessió anterior (identificada pel missatge d'inici de la pacient) retrocedeix exactament un dia en el calendari.
3.  **Visualitzador de Sessions Avançat:** La pantalla `lib/sessions_visualizer_screen.dart` s'ha actualitzat per ser un motor de processament híbrid:
    *   **Prioritat de Metadades:** Si troba el format `|...|`, extreu i mostra la data i hora real.
    *   **Fallback de Reconstrucció:** Si no hi ha metadades, aplica el càlcul de dies retroactius.
    *   **Neteja de UI:** S'utilitzen expressions regulars per eliminar les metadades de la vista de l'usuari, mantenint una interfície neta i professional.
4.  **Detecció de Sessions:** S'ha millorat la detecció d'inici de sessió per ser robusta davant la presència o absència de marques de temps en els missatges guardats.

---

### Historial d'Enginyeria Anterior

*   **Canvi de model Gemini i ajust de la UI d'Android:** Es va canviar el model a `gemini-flash-lite-latest` per resoldre errors de l'API i es va corregir un problema de superposició de la interfície amb la barra d'estat d'Android.
*   **Resolució de l'error `Undefined name 'FirebaseVertexAI'`:** La causa arrel era una configuració incorrecta de `firebase_core`. La solució va ser regenerar la configuració completa del projecte amb `flutterfire configure`.
*   **Millora de la navegació del comunicador visual:** S'ha redissenyat la pantalla del visualitzador (`lib/visualizer_screen.dart`) per implementar un sistema híbrid que combina la navegació per pàgines amb un índex de pestanyes (`TabBar`).