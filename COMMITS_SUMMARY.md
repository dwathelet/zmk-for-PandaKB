# 📊 Résumé des commits depuis le Fork

*Dernière mise à jour : 1 juin 2026 (15:24)*

Ce document résume les commits et les modifications apportées aux différentes branches de votre fork (`dwathelet/zmk-for-PandaKB`) par rapport au dépôt amont (`PandaKBLab/zmk-for-PandaKB`).

> [!NOTE]
> **Stratégie de maintien de ce fichier :** Afin d'éviter l'encombrement du dépôt avec de multiples fichiers datés, la date de génération est incluse directement au début de cet unique document `COMMITS_SUMMARY.md`. Cela permet un suivi propre et centralisé via l'historique Git tout en conservant un accès direct à la dernière version.

---

## 🔍 Aperçu des Branches Modifiées

Le dépôt contient deux branches principales personnalisées qui divergent de leurs homologues en amont (`upstream`) :
1. **`MyCorne`** : Basée sur `upstream/PandaKB_Corne`, contenant les configurations et personnalisations pour votre clavier Corne.
2. **`MySoffle`** : Basée sur `upstream/PandaKB_Sofle`, contenant les configurations et personnalisations pour votre clavier Sofle.

*Note : La branche `Description` est identique à son homologue en amont `upstream/Description`.*

---

## ⌨️ 1. Branche `MyCorne` (Corne Keyboard)
**Divergence :** 34 commits depuis `upstream/PandaKB_Corne`.

### 🛠️ Résumé des Modifications Principales
* **Améliorations Ergonomiques (Home Row Mods - HRM) :**
  * Configuration et optimisation des HRM pour les mains gauche et droite, y compris la configuration de touches Shift spécifiques (`ae8052c`).
  * Augmentation des délais temporels des HRM (`hrm time delay up` - `9cae7f3`) pour éviter les activations involontaires.
  * Nettoyage et suppression des comportements en doublon (`b190b9b`) dans la configuration ZMK.
* **Ajustements de Layout :**
  * Correction du positionnement des touches de virgule (`,`) et de point (`.`) (`5cf6856`).
  * Nombreuses adaptations et ajustements de la disposition générale (`Layout adaptation`).
* **Visualisation Automatisée :**
  * Intégration de `keymap-drawer` avec des flux de travail GitHub Actions pour générer automatiquement une représentation visuelle de la disposition des touches (`img/Corne.svg` et `img/Corne.yaml`).
* **Utilitaires de Flash :**
  * Ajout d'un script utilitaire `flash.sh` (`9fc1ecb`) pour faciliter le téléversement (flashing) du firmware compilé.

<details>
<summary><b>📋 Voir la liste complète des 34 commits de <code>MyCorne</code></b></summary>

```text
8dfcce6 keymap-drawer render
6fdfe6f Updated Corne.keymap
b190b9b behavior duplicates removal
9cae7f3 hrm time delay up
45a3f05 keymap-drawer render
ae8052c HRM left and right + specific shift
17a3999 keymap-drawer render
5cf6856 correct comma and dot positions
3ae7e12 keymap-drawer render
5c91f2b Updated Corne.keymap
97f968b keymap-drawer render
721d17b Updated Corne.keymap
a0110b9 keymap-drawer render
29b599e layout adaptation
11015f3 keymap-drawer render
826e70d Layout adaptation
a6549ef Updated Corne.keymap
b40278e keymap-drawer render
1b44644 Updated Corne.keymap
1bc94e9 keymap-drawer render
f6605ac Updated Corne.keymap
72931d2 keymap-drawer render
986feeb Updated Corne.keymap
67fe97f keymap-drawer render
23fb699 Updated Corne.keymap
d221274 keymap-drawer render
1cf3328 Updated Corne.keymap
a5b7c6f keymap-drawer render
e96870c Adapted layout
9fc1ecb Flash utility
a5e2d99 keymap-drawer render
bd9e002 Draw keymap configuration
df3d77a Draw keymap configuration
e3f3fb3 Adapted layout
```
</details>

---

## 🎛️ 2. Branche `MySoffle` (Sofle Keyboard)
**Divergence :** ~115 commits depuis `upstream/PandaKB_Sofle`.

### 🛠️ Résumé des Modifications Principales
* **Gestion du Layout & Clavier Numérique :**
  * Configuration complète d'un pavé numérique (`numpad`) sur la disposition (`c324055`, `d5555e9`).
  * Nombreuses mises à jour de la configuration de touches (`Sofle.keymap`).
* **Connectivité & Matériel :**
  * Activation explicite de la sortie BLE (Bluetooth) et USB (`2df29c0`).
  * Nettoyage de configurations obsolètes ou inutilisées (suppression de fichiers `eyeslash_dongle_config`, etc.).
* **Scripts de Build & Workflows :**
  * Ajout et amélioration du script `commitAndBuild.sh` (et `build.sh`) pour automatiser le commit et la compilation locale ou via GitHub Actions.
  * Configuration personnalisée de `keymap-drawer` (`keymap_drawer.config.yaml`) et automatisation avec le workflow GitHub `draw-keymap.yml`.
* **Visualisation :**
  * Génération automatique des rendus de la disposition des touches via `keymap-drawer` (`img/Sofle.svg` et `img/Sofle.yaml`).

<details>
<summary><b>📋 Voir la liste complète des commits de <code>MySoffle</code></b></summary>

```text
ee9faa1 keymap-drawer render
1833e00 Updated Sofle.keymap
ef07aad keymap-drawer render
6cd807e Updated Sofle.keymap
1e34d20 keymap-drawer render
3c93198 Updated Sofle.keymap
b025e34 Updated Sofle.keymap
f09b416 keymap-drawer render
a6ad60c Updated Sofle.keymap
5c07ab1 Updated Sofle.keymap
1bf77e1 keymap-drawer render
e19ffc1 Updated Sofle.keymap
49286bf Updated Sofle.keymap
3e5e893 keymap-drawer render
eef48b8 Updated Sofle.keymap
e7a7e83 keymap-drawer render
2ece1e8 Update keymap_drawer.config.yaml
be243f2 Update keymap_drawer.config.yaml
d82f264 keymap-drawer render
fa36144 Update keymap_drawer.config.yaml
a2002d9 keymap-drawer render
6c26615 Update keymap_drawer.config.yaml
9e0f9f8 keymap-drawer render
4e71ecc Update keymap_drawer.config.yaml
c104905 keymap-drawer render
e32117d Update keymap_drawer.config.yaml
2080585 Update keymap_drawer.config.yaml
25bd144 Update keymap_drawer.config.yaml
1fbaaee Update keymap_drawer.config.yaml
7870a54 Update keymap_drawer.config.yaml
18dedd2 keymap-drawer render
9e31742 Update keymap_drawer.config.yaml
a42bb35 Update keymap_drawer.config.yaml
49b161f Update keymap_drawer.config.yaml
3a404f5 keymap-drawer render
af8924b Update keymap_drawer.config.yaml
c873d41 keymap-drawer render
258eead Update keymap_drawer.config.yaml
57183cb keymap-drawer render
04044c6 Updated Sofle.keymap
7dc98b4 Update draw-keymap.yml
c1f2115 keymap-drawer render
5401852 Updated Sofle.keymap
e907c9b Update keymap_drawer.config.yaml
291e0f2 keymap-drawer render
91f26aa Updated Sofle.keymap
29f5612 Update keymap_drawer.config.yaml
db5b479 Update keymap_drawer.config.yaml
13f2a19 Update draw-keymap.yml
a960e18 Update keymap_drawer.config.yaml
87c5856 Update keymap_drawer.config.yaml
80080f6 keymap-drawer render
114fbd8 Revert "DTC"
7281fa3 keymap-drawer render
890be80 DTC
53b3a4f Changed buiild
9970783 Updated commitAndBuild.sh
f85f9b0 keymap-drawer render
a48b09c Updated Sofle.keymap
121851e keymap-drawer render
d42a4fb Print screen
bc831b0 keymap-drawer render
2df29c0 activate out ble and usb
f91dfb6 Update Sofle.conf
3dc9fc2 keymap-drawer render
d5555e9 update numpad
7d33c88 keymap-drawer render
8606449 Modified build
bd7d55f gros d
e3ed45d dfsfs
9c92c03 dsqds
c8e924c fsfs
bc4627c ds
8aa1dd7 sfs
3b574c9 fsfsfs
c6b0d23 fsf
2331a85 keymap-drawer render
5e7371c fsfs
04f81aa fs
28dc85e fsf
286a118 keymap-drawer render
6fdb77c dqsd
82528cd keymap-drawer render
0cb594f s
9ac0414 fsf
424a6ac fs
5e5fb2e fksjll
ea75c8c Dpoqi
7e3fd1f Bla
423432f keymap-drawer render
5323608 Update draw worfkflow configuration
6da47f6 keymap-drawer render
543a0ca Update layout
1006637 keymap-drawer render
c67b56d Update draw keymap workflow
ed93466 Update workflow
326a0d3 Update draw-keymap.yml
ac514a7 New workflow
03d0b33 Changed kbd to build
3cd118b Renamed util
7c78614 Added build.sh
3b29fa9 Update Sofle.keymap
337dacc Update Sofle.keymap
c324055 setup numpad (base)
a789bc3 Update Sofle.keymap
67d5c06 Update Sofle.keymap
2fcf3ac Update Sofle.keymap
654bc7b Update Sofle.keymap
4becbcb Update Sofle.keymap
9d97389 Update Sofle.keymap
```
</details>
