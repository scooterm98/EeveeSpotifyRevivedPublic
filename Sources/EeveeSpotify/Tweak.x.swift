import Orion
import EeveeSpotifyC
import UIKit

func writeDebugLog(_ message: String) {
    let logPath = NSTemporaryDirectory() + "eeveespotify_debug.log"
    let timestamp = Date().description
    let logMessage = "[\(timestamp)] \(message)\n"
    
    if FileManager.default.fileExists(atPath: logPath) {
        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            if let data = logMessage.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
    } else {
        try? logMessage.write(toFile: logPath, atomically: true, encoding: .utf8)
    }
}

func exitApplication() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
        exit(EXIT_SUCCESS)
    }
}

struct BasePremiumPatchingGroup: HookGroup { }

struct IOS14PremiumPatchingGroup: HookGroup { }
struct NonIOS14PremiumPatchingGroup: HookGroup { }
struct IOS14And15PremiumPatchingGroup: HookGroup { }
struct V91PremiumPatchingGroup: HookGroup { } // For Spotify 9.1.x versions
struct LatestPremiumPatchingGroup: HookGroup { }

func activatePremiumPatchingGroup() {
    BasePremiumPatchingGroup().activate()
    
    if EeveeSpotify.hookTarget == .lastAvailableiOS14 {
        IOS14PremiumPatchingGroup().activate()
    }
    else if EeveeSpotify.hookTarget == .v91 {
        // 9.1.x versions: Use NonIOS14 hooks but skip offline content hooks
        NonIOS14PremiumPatchingGroup().activate()
        V91PremiumPatchingGroup().activate()
    }
    else {
        NonIOS14PremiumPatchingGroup().activate()
        
        if EeveeSpotify.hookTarget == .lastAvailableiOS15 {
            IOS14And15PremiumPatchingGroup().activate()
        }
        else {
            LatestPremiumPatchingGroup().activate()
        }
    }
}

struct EeveeSpotify: Tweak {
    static let version = "6.4.8"
    
    static var hookTarget: VersionHookTarget {
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        
        NSLog("[EeveeSpotify] Detected Spotify version: \(version)")
        
        switch version {
        case "9.0.48":
            return .lastAvailableiOS15
        case "8.9.8":
            return .lastAvailableiOS14
        case "9.1.0", "9.1.6":
            // 9.1.x versions don't have offline content helper classes
            return .v91
        default:
            return .latest
        }
    }
    
    init() {
        NSLog("[EeveeSpotify] Swift tweak initialization starting...")
        writeDebugLog("Swift tweak initialization starting")
        NSLog("[EeveeSpotify] Hook target: \(EeveeSpotify.hookTarget)")
        writeDebugLog("Hook target: \(EeveeSpotify.hookTarget)")
        
        // For 9.1.x, activate premium patching only (lyrics not yet supported)
        if EeveeSpotify.hookTarget == .v91 {
            NSLog("[EeveeSpotify] Spotify 9.1.x detected - activating compatible features")
            writeDebugLog("9.1.x mode - limited feature set")
            
            // Premium patching
            if UserDefaults.patchType.isPatching {
                NSLog("[EeveeSpotify] Activating base premium patching for 9.1.x")
                writeDebugLog("Activating base premium patching for 9.1.x")
                BasePremiumPatchingGroup().activate()
                writeDebugLog("Base premium patching activated")
            }
            
            // Note: Custom lyrics are NOT supported on 9.1.x
            // The lyrics architecture is completely different and requires network request interception
            // which doesn't work with 9.1.x's lyrics implementation
            
            // Settings integration
            NSLog("[EeveeSpotify] Activating universal settings integration for 9.1.x")
            writeDebugLog("Activating universal settings integration for 9.1.x")
            UniversalSettingsIntegrationGroup().activate()
            writeDebugLog("Universal settings integration activated")
            
            NSLog("[EeveeSpotify] Initialization complete for 9.1.x (with experimental lyrics)")
            writeDebugLog("Initialization complete for 9.1.x")
            return
        }
        
        // For other versions, activate all features normally
        if UserDefaults.experimentsOptions.showInstagramDestination {
            NSLog("[EeveeSpotify] Activating Instagram destination hooks")
            writeDebugLog("Activating Instagram destination hooks")
            InstgramDestinationGroup().activate()
            writeDebugLog("Instagram hooks activated successfully")
        }
        
        if UserDefaults.darkPopUps {
            NSLog("[EeveeSpotify] Activating dark popups hooks")
            writeDebugLog("Activating dark popups hooks")
            DarkPopUps().activate()
            writeDebugLog("Dark popups hooks activated successfully")
        }
        
        if UserDefaults.patchType.isPatching {
            NSLog("[EeveeSpotify] Activating premium patching hooks")
            writeDebugLog("Activating premium patching hooks")
            activatePremiumPatchingGroup()
            writeDebugLog("Premium patching hooks activated successfully")
        }
        
        if UserDefaults.lyricsSource.isReplacingLyrics {
            NSLog("[EeveeSpotify] Activating lyrics hooks")
            writeDebugLog("Activating lyrics hooks")
            BaseLyricsGroup().activate()
            writeDebugLog("Base lyrics hooks activated successfully")
            
            // Activate error handling hooks (not compatible with 9.1.x)
            LyricsErrorHandlingGroup().activate()
            writeDebugLog("Lyrics error handling hooks activated successfully")
            
            if EeveeSpotify.hookTarget == .latest {
                writeDebugLog("Activating modern lyrics hooks")
                ModernLyricsGroup().activate()
                writeDebugLog("Modern lyrics hooks activated successfully")
            }
            else {
                writeDebugLog("Activating legacy lyrics hooks")
                LegacyLyricsGroup().activate()
                writeDebugLog("Legacy lyrics hooks activated successfully")
            }
        }
        
        // Always activate settings integration (except for 9.1.x which exits early above)
        NSLog("[EeveeSpotify] Activating universal settings integration")
        writeDebugLog("Activating universal settings integration")
        UniversalSettingsIntegrationGroup().activate()
        writeDebugLog("Universal settings integration activated")
        
        NSLog("[EeveeSpotify] Activating legacy settings integration (fallback)")
        writeDebugLog("Activating legacy settings integration (fallback)")
        SettingsIntegrationGroup().activate()
        writeDebugLog("Legacy settings integration activated successfully")
        
        NSLog("[EeveeSpotify] Swift tweak initialization completed successfully")
        writeDebugLog("Swift tweak initialization completed successfully")
    }
}
