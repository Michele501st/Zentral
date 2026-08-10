# 🌟 Zentral - Unified Apps Grid & Enhanced Tab Groups for Zen Browser
<img width="811" height="593" alt="Zentral-Demo" src="https://github.com/user-attachments/assets/4dec0e5f-5b7f-4558-90a1-04775ec7f658" />

![Version](https://img.shields.io/badge/version-v0.1.5a-blue.svg)
![License](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-orange.svg)
![Target](https://img.shields.io/badge/target-Zen%20Browser-purple.svg)

**Zentral** is a high-performance, feature-packed `userChrome.js` mod for [Zen Browser](https://zen-browser.app/). It unifies your favorite web applications and tab groups into a sleek, customizable sidebar experience with floating panels, workspace isolation, custom color pickers, and settings dialogs.

---

## ✨ Features

### 🚀 1. Floating Apps Grid & Panels
- **Grid Layout**: Display web app icons in a responsive sidebar grid or horizontal toolbar.
- **Workspace Isolation**: Right-click any app button to set visibility to **Current Space** or **All Spaces**.
- **Smooth Panel Transitions**: Slide-out panels powered by customizable easing curves (`slide`, `spring-gentle`, `spring-bouncy`, `elastic`).
- **Interactive Controls**: Pin panels, expand to full width, or drag resize handles dynamically.
- **Unread Notification Badges**: Automatic title tracking displays red badges or dot indicators for unread updates.
- **Background Preloading**: Staggered background preloading for instant app access.
<img width="1919" height="1040" alt="Zentral-Apps" src="https://github.com/user-attachments/assets/e2fe4049-b3f8-474c-b2bc-6c4f160770a3" />
<img width="1919" height="1040" alt="Zentral-Collapsed" src="https://github.com/user-attachments/assets/af0720f3-e7e4-4e33-b12d-f67ccb8f6ec4" />


### 🎨 2. Enhanced Tab Groups
- **Group Color Picker**: Integrated popup color wheel, preset swatches, RGB/Hex inputs, and a native screen eyedropper tool.
- **Initials Badges**: Automatic 2-letter uppercase initials displayed when the sidebar is collapsed.
- **Group Tooltips**: Hover over tab group pills to inspect instant tab lists.
- **State Persistence**: Remembers group hierarchy, nesting, and collapsed states across browser restarts.
- **Folder Conversion**: Seamlessly convert native Zen folders into Tab Groups and vice versa.
<img width="1919" height="1038" alt="Zentral-Groups" src="https://github.com/user-attachments/assets/d73f06d3-fa73-4f9c-95aa-e7cd0accb407" />

### ⚙️ 3. Native Settings UI
- Integrated preferences modal dialog accessible directly from the app context menu to customize animation speeds, row caps, apps per row, and group defaults on the fly.
<img width="1919" height="1039" alt="Zentral-Settings_1" src="https://github.com/user-attachments/assets/819fdd4a-64af-4488-8400-e5d4c9468104" />
<img width="1919" height="1040" alt="Zentral-Settings_2" src="https://github.com/user-attachments/assets/0e7b50d3-0578-4d0e-9641-28585e4ec3b6" />





---

## ⚡ Quick 1-Click Installation (Windows)

No manual setup or prerequisite installation required! The included 1-click installer sets up `fx-autoconfig` and installs Zentral automatically.

### Option A: Double-Click Installer
1. Download or clone this repository.
2. Double-click **`install.bat`**.
3. Restart **Zen Browser**.

### Option B: PowerShell Command
Open PowerShell and run:
```powershell
iwr -useb https://raw.githubusercontent.com/Michele501st/Zentral/main/install.ps1 | iex
```

---

## 🛠️ Manual Installation

If you already have `fx-autoconfig` or a `.uc.js` loader installed:
1. Copy `chrome/JS/Zentral.uc.js` into your active Zen profile's `chrome/JS/` folder:
   ```text
   <Zen-Profile-Directory>/chrome/JS/Zentral.uc.js
   ```
2. Restart Zen Browser.

---

## 📜 Architecture & Index

Zentral is organized into a modular, documented two-tier architecture:

```text
1.0 CONFIGURATION & CONSTANTS
    1.1 Pref Key Definitions
    1.2 Default Constant Values

2.0 ZENTRAL CORE ENGINE (ZentralCore)
    2.1 Core State & Config Storage
    2.2 Native Browser Preference Utilities
    2.3 System Event Bus

3.0 APPS MODULE (ZentralApps)
    3.1 State Initialization & Properties
    3.2 CSS Style Injection
    3.3 Layout & Sidebar Position Detection
    3.4 Grid & Tile Rendering
    3.5 App Panel Lifecycle & Animations
    3.6 Drag & Drop / Grid Reordering
    3.7 App Context Menus & Space Scoping

4.0 TAB GROUPS MODULE (ZentralTabGroups)
    4.1 Initialization & Observers
    4.2 Custom CSS & Visual Enhancements
    4.3 Group Hierarchy & Storage Serialization
    4.4 Color Picker & Theme Processing
    4.5 Custom Tooltips & Context Menus

5.0 SETTINGS MODULE (ZentralSettings)
    5.1 Modal UI Structure & Injection
    5.2 Form Data Binding & Persistence
    5.3 Modal Animation & Dialog Styles

6.0 MASTER BOOTSTRAPPER & ENTRY POINT
    6.1 Global Namespace Definition
    6.2 Browser Startup Observers
```

---

## 📄 License

Distributed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)](LICENSE).

- **Attribution**: Credit must be given to the original author (Michele Pierini).
- **Non-Commercial**: Strictly forbidden to sell, monetize, or bundle Zentral for commercial gain.
- **ShareAlike**: Modified versions must be shared under the exact same CC BY-NC-SA 4.0 license.
