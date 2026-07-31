// config.js - fx-autoconfig main loader for Zen / Firefox
try {
  const { Services } = ChromeUtils.importESModule("resource://gre/modules/Services.sys.mjs");
  const chromeDir = Services.dirsvc.get("UChrm", Ci.nsIFile);
  const bootFile = chromeDir.clone();
  bootFile.append("utils");
  bootFile.append("boot.sys.mjs");
  if (bootFile.exists()) {
    ChromeUtils.importESModule(Services.io.newFileURI(bootFile).spec);
  }
} catch (e) {
  console.error("[fx-autoconfig] Failed to load boot.sys.mjs:", e);
}
