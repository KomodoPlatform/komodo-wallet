function Component()
{
   
}

Component.prototype.createOperations = function()
{
	component.createOperations();

    if (installer.value("os") === "win") {
		// Start Menu Shortcut
        component.addOperation("CreateShortcut", 
                               "@TargetDir@/atomicdex-desktop.exe", 
                               "@StartMenuDir@/AtomicDEX Desktop.lnk",
                               "workingDirectory=@TargetDir@", 
                               "iconPath=@TargetDir@/atomicdex-desktop.ico", "iconId=0",
                               "description=Start AtomicDEX Desktop");
        
        // Desktop Shortcut
        component.addOperation("CreateShortcut", 
                            "@TargetDir@/atomicdex-desktop.exe",
                            "@DesktopDir@/AtomicDEX Desktop.lnk",
                            "workingDirectory=@TargetDir@",
                            "iconPath=@TargetDir@/atomicdex-desktop.ico", "iconId=0",
                            "description=Start AtomicDEX Desktop");

		// Maintenance Tool Start Menu Shortcut
        component.addOperation("CreateShortcut", 
                               "@TargetDir@/atomicdex-desktop.exe", 
                               "@StartMenuDir@/AtomicDEX Maintenance Tool.lnk",
                               "workingDirectory=@TargetDir@", 
                               "iconPath=@TargetDir@/atomicdex-desktop.ico", "iconId=0",
                               "description=Start AtomicDEX Maintenance Tool");
    }
}