# MetalHUDEnabler

MetalHUDEnabler allows for permanently enabling the new Metal 3 performance HUD for any Metal-enabled application on macOS Ventura.

![Metal HUD enabled on Life is Strange: True Colors running through CrossOver](screens/hud.jpg "Metal HUD enabled on Life is Strange: True Colors running through CrossOver")


# Usage

Using MetalHUDEnabler is as simple as executing ``./MetalHUDEnabler [path to application] [enable/disable]`` then launching the target app normally from the dock or wherever else.

``./MetalHUDEnabler /Applications/CrossOver.app enable`` would enable the Metal 3 performance HUD for the CrossOver application (and most games launched from it as a result).

``./MetalHUDEnabler /Applications/CrossOver.app disable`` would revert the changes made to the CrossOver application and disable the Metal HUD.

# Anything else?
This should work with any Metal-enabled application as of the latest code changes. Please let me know of any issues.

That being said, I am not responsible for any damages and you are running this application at your own risk (although I don't see much of a possibility for things to go wrong here). Have fun.