# Projecte Logopeda: Assistent de Comunicació i Teràpia

Aquesta és una aplicació desenvolupada amb Flutter, dissenyada com una eina de suport per a la teràpia de la parla i la comunicació, específicament enfocada a pacients amb afàsia. El projecte combina un assistent conversacional intel·ligent, basat en l'API de Gemini de Google, amb un comunicador visual ric en pictogrames.

## 🌟 Funcionalitats Principals

L'aplicació es divideix en tres eines principals:

### 1. Assistent de Teràpia amb IA

Una interfície conversacional que actua com a logopeda virtual per practicar la parla.

- **Interacció per Veu:** L'usuari pot parlar directament a l'aplicació. El sistema converteix la veu a text (`Speech-to-Text`).
- **IA Conversacional (Gemini):** El text de l'usuari s'envia a un model d'intel·ligència artificial de Google (Gemini), configurat amb un perfil de sistema per actuar com a logopeda (`logopeda.txt`).
- **Resposta Sonora:** La resposta generada per la IA es converteix de nou a veu (`Text-to-Speech`) en català, creant un diàleg fluid.
- **Configuració Flexible:** Permet introduir una API Key de Google AI Studio i seleccionar entre els models de Gemini disponibles.

### 2. Historial de Sessions Intel·ligent

Un sistema avançat per al seguiment i revisió del progrés de l'usuari.

- **Persistència Local:** Totes les converses es guarden de forma segura al dispositiu mitjançant `SharedPreferences`.
- **Marcatge de Temps (Metadata):** Cada interacció es registra amb la data i hora exactes (`|dd/MM/yyyy HH:mm|`) per a una traçabilitat precisa.
- **Visualitzador de Sessions:** Una interfície dedicada que organitza els missatges en blocs de sessió.
- **Reconstrucció Històrica:** Lògica intel·ligent capaç de reconstruir la cronologia de sessions antigues mancats de metadades, garantint que cap dada es perdi durant la transició del sistema.

### 3. Comunicador Visual

Un llibre digital interactiu basat en pictogrames, dissenyat per facilitar la comunicació no verbal.

- **Navegació Intuïtiva:**
  - **Menús a l'AppBar:** Dos menús desplegables permeten saltar directament a qualsevol **pàgina** o **categoria** del llibre.
  - **Gestos i Fletxes:** L'usuari pot lliscar el dit per la pantalla o utilitzar les fletxes inferiors per navegar seqüencialment entre les pàgines.
- **Organització Lògica:** El contingut està estructurat en pàgines i categories, carregat des del fitxer `assets/data/comunicador.json`.
- **Visualització Immersiva:** En tocar una imatge, aquesta s'obre a pantalla completa amb un fons fosc, permetent a l'usuari fer **zoom** i **desplaçar-se** per explorar-ne tots els detalls.

## 🎨 Disseny i Experiència d'Usuari

- **Material Design 3:** Interfície moderna i neta.
- **Tema Clar i Fosc:** Suport complet per a tots dos modes, amb opció de canvi manual o sincronitzat amb el sistema operatiu.
- **Tipografia Professional:** Ús de `google_fonts` per a una estètica cuidada.
- **Gestió d'Estat:** L'arquitectura utilitza el paquet `provider` per a una gestió de l'estat eficient.

## 🚀 Començar a Utilitzar el Projecte

Per executar aquest projecte al teu entorn de desenvolupament, segueix aquests passos:

1.  **Clona el Repositori:**
    ```shell
    git clone <URL_DEL_REPOSITORI>
    cd <NOM_DEL_DIRECTORI>
    ```

2.  **Instal·la les Dependències:**
    ```shell
    flutter pub get
    ```

3.  **Configura l'API de Gemini:**
    - Visita [Google AI Studio](https://aistudio.google.com/) per obtenir una **API Key**.
    - Inicia l'aplicació i, a la pantalla principal, introdueix la teva clau a l'apartat "API Key de Google AI Studio".
    - Prem el botó "Carregar Models" per activar l'assistent d'intel·ligència artificial.

4.  **Executa l'Aplicació:**
    ```shell
    flutter run
    ```

## 📂 Estructura del Projecte

- `lib/main.dart`: Punt d'entrada, configuració de temes, pantalla principal de l'assistent i gestió de la persistència de sessions.
- `lib/sessions_visualizer_screen.dart`: Lògica de visualització de l'historial i reconstrucció de dates.
- `lib/visualizer_screen.dart`: Pantalla principal del Comunicador Visual.
- `lib/full_screen_image_screen.dart`: Pantalla per a la visualització d'imatges en pantalla completa amb zoom.
- `lib/services/gemini_service.dart`: Lògica per a la comunicació amb l'API de Gemini.
- `assets/data/comunicador.json`: Fitxer JSON amb les dades del comunicador.
- `assets/txt/logopeda.txt`: Prompt de sistema que defineix la personalitat de l'assistent.