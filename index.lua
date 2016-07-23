--StarUpdater-UN 
--Unofficial StarUpdater branch by gnmmarechal.
--Based on StarUpdater by astronautlevel.

-- Colours
local Colors =
{
	white = Color.new(255,255,255)
	yellow = Color.new(255,205,66)
	red = Color.new(255,0,0)
	green = Color.new(55,255,0)
}

-- URLs
local urls =
{
	--Luma3DS URLs
	hourly = "http://astronautlevel2.github.io/Luma3DS/latest.zip"
	stable = "http://astronautlevel2.github.io/Luma3DS/release.zip"
	hourlyDev = "http://astronautlevel2.github.io/Luma3DSDev/latest.zip"
	stableDev = "http://astronautlevel2.github.io/Luma3DSDev/release.zip"
	--Versions String URLs
	remoteVer = "http://astronautlevel2.github.io/Luma3DS/lastVer"
	remoteCommit = "http://astronautlevel2.github.io/Luma3DS/lastCommit"
	remoteDevCommit = "http://astronautlevel2.github.io/Luma3DSDev/lastCommit"	
	--StarUpdater URLs
	latestCIA = "http://gs2012.xyz/3ds/starupdater/latest.zep" --My branch's URL
	--latestCIA = "http://www.ataber.pw/u" --Official URL
	latestHBX = "http://gs2012.xyz/3ds/starupdater/index.lua"
	--Server Latest StarUpdater Version String
	ver = "http://gs2012.xyz/3ds/starupdater/version"
}

-- Paths

local paths =
{
	--A9LH Payload Paths
	payload = "/arm9loaderhax.bin"
	--Luma3DS ZIP Path
	zip = "/Luma3DS.zip"
	--Payload Backup Path
	backup = paths.payload..".bak"
}


local curPos = 20
local isMenuhax = false
local isDev = false
local menuhaxmode, devmode = 1,2

local localVer = ""
local remoteVerNum = ""

--Controls
local pad = Controls.read()
local oldpad = pad

--CIA/3DSX
local iscia = 0
if System.checkBuild() == 2 then
	iscia = 0
else
	iscia = 1
end

--Version Info

local ver =
{
	--Current StarUpdater Version
	current = "1.5.0"
	--Latest StarUpdater version from server
	server = "???"
}

if Network.isWifiEnabled() then
	ver.server = Network.requestString(urls.ver)
end

function readConfig(fileName)
    if (isMenuhax) then
        paths.payload = "/Luma3DS.dat"
        paths.backup = paths.payload..".bak"
        return
    end
    if (System.doesFileExist(fileName)) then
        local file = io.open(fileName, FREAD)
        paths.payload = io.read(file, 0, io.size(file))
        paths.payload = string.gsub(paths.payload, "\n", "")
        paths.payload = string.gsub(paths.payload, "\r", "")
        paths.backup = paths.payload..".bak"
    elseif (not System.doesFileExist(fileName) and not isMenuhax) then
		if System.doesFileExist("/arm9loaderhax_si.bin") and (not System.doesFileExist("/arm9loaderhax.bin")) then
			paths.payload = "/arm9loaderhax_si.bin"
		else
			paths.payload = "/arm9loaderhax.bin"
		end
        paths.backup = paths.payload..".bak"
        return
    end
end

function restoreBackup()
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.waitVblankStart()
    Screen.flip()
    if System.doesFileExist(paths.backup) then
        Screen.debugPrint(5,5, "Deleting new payload...", yellow, TOP_SCREEN)
        System.deleteFile(paths.payload)
        Screen.debugPrint(5,20, "Renaming backup to "..paths.payload.."...", yellow, TOP_SCREEN)
        System.renameFile(paths.backup, paths.payload)
        Screen.debugPrint(5,35, "Press START to go back to HBL/Home menu", Colors.green, TOP_SCREEN)
        while true do
            pad = Controls.read()
                if Controls.check(pad,KEY_START) then
                    Screen.waitVblankStart()
                    Screen.flip()
                    System.exit()
            end
        end
    else
        Screen.debugPrint(5,5, "Backup path: "..paths.backup, yellow, TOP_SCREEN)
        Screen.debugPrint(5,20, "Press START to go back to HBL/Home menu", Colors.green, TOP_SCREEN)
        while true do
            pad = Controls.read()
            if Controls.check(pad,KEY_START) then
                Screen.waitVblankStart()
                Screen.flip()
                System.exit()
            end
        end
    end
end

function sleep(n)
  local timer = Timer.new()
  local t0 = Timer.getTime(timer)
  while Timer.getTime(timer) - t0 <= n do end
end

function getMode(mode)
    if mode == menuhaxmode then
        if (isMenuhax) then
            return "MenuHax"
        else
            return "Arm9LoaderHax"
        end
    else
        if (isDev) then
            return "Dev"
        else
            return "Regular"
        end
    end
end

function unicodify(str)
    local new_str = ""
    for i = 1, #str,1 do
        new_str = new_str..string.sub(str,i,i)..string.char(00)
    end
    return new_str
end

function getVer(path)
    if (path ~= "remote") then
      	local searchString = "Luma3DS "
      	local verString = ""
      	local isDone = false
        if (System.doesFileExist(path) == true) then
            local file = io.open(path, FREAD)
            local fileData = io.read(file, 0, io.size(file))
            io.close(file)
            local offset = string.find(fileData, searchString)
            if (offset ~= nil) then
                offset = offset + string.len(searchString)
                while(isDone == false)
                do
                    bitRead = fileData:sub(offset,offset)
                    if bitRead == " " then
                        isDone = true
                    else
                        verString = verString..bitRead
                    end
                    offset = offset + 1
                end
                return verString
            else
                return "Config error!"
            end
        else
            return "Config error!"
        end
    else
        if Network.isWifiEnabled() then
        	if (not isDev) then
            	return Network.requestString(urls.remoteVer).."-"..Network.requestString(urls.remoteCommit)
            else
            	return Network.requestString(urls.remoteVer).."-"..Network.requestString(urls.remoteDevCommit)
            end
        else
            return "No connection!"
        end
    end
end

function path_changer()
    local file = io.open(paths.payload, FREAD)
    local a9lh_data = io.read(file, 0, io.size(file))
    io.close(file)
    local offset = string.find(a9lh_data, "%"..unicodify("arm9loaderhax.bin"))
    local new_path = unicodify(string.sub(paths.payload,2,-1))
    if #new_path < 74 then
        for i = 1,74-#new_path,1 do
            new_path = new_path..string.char(00)
        end
        local file = io.open(paths.payload, FWRITE)
        io.write(file, offset-1, new_path, 74)
        io.close(file)
    end
end

function update(site)
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.waitVblankStart()
    Screen.flip()
    if Network.isWifiEnabled() then
    	Screen.debugPrint(5,5, "Downloading file...", yellow, TOP_SCREEN)
        Network.downloadFile(site, paths.zip)
        Screen.debugPrint(5,15, "File downloaded!", Colors.green, TOP_SCREEN)
        Screen.debugPrint(5,35, "Backing up payload", yellow, TOP_SCREEN)
        if (System.doesFileExist(paths.backup)) then
            System.deleteFile(paths.backup)
        end
        if (System.doesFileExist(paths.payload)) then
            System.renameFile(paths.payload, paths.backup)
        end
        if (isMenuhax == false) then
            System.extractFromZIP(paths.zip, "out/arm9loaderhax.bin", paths.payload)
            Screen.debugPrint(5,50, "Moving to payload location...", yellow, TOP_SCREEN)
            System.deleteFile(paths.zip)
            Screen.debugPrint(5,65, "Changing path for reboot patch", yellow, TOP_SCREEN)
            path_changer()
        elseif (isMenuhax == true) then
            Screen.debugPrint(5,50, "Moving to payload location...", yellow, TOP_SCREEN)
            System.extractFromZIP(paths.zip, "out/Luma3DS.dat", "/Luma3DS.dat")
            System.deleteFile(paths.zip)
        end
        Screen.debugPrint(5,80, "Done!", Colors.green, TOP_SCREEN)
        Screen.debugPrint(5,95, "Press START to go back to HBL/Home menu", Colors.green, TOP_SCREEN)
        Screen.debugPrint(5,110, "Press SELECT to reboot", Colors.green, TOP_SCREEN)
        while true do
            pad = Controls.read()
            if Controls.check(pad,KEY_START) then
                Screen.waitVblankStart()
                Screen.flip()
                System.exit()
            elseif Controls.check(pad,KEY_SELECT) then
                System.reboot()
            end
        end

    else
        Screen.debugPrint(5,5, "WiFi is off! Please turn it on and retry!", Colors.red, TOP_SCREEN)
        Screen.debugPrint(5,20, "Press START to go back to HBL/Home menu", Colors.red, TOP_SCREEN)
        while true do
            pad = Controls.read()
            if Controls.check(pad,KEY_START) then
                Screen.waitVblankStart()
                Screen.flip()
                System.exit()
            end
        end
    end
end

function init()
	readConfig("/luma/update.cfg")
	localVer = getVer(paths.payload)
	remoteVerNum = getVer("remote")
end

function main()
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.debugPrint(5,5, "Welcome to the StarUpdater!", yellow, TOP_SCREEN)
    Screen.debugPrint(0, curPos, "->", Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,20, "Update stable Luma3DS", Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,35, "Update unstable Luma3DS", Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,50, "Restore a Luma3DS backup", Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,65, "Developer mode: "..getMode(devmode), Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,80, "Install mode: "..getMode(menuhaxmode), Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,95, "Go back to HBL/Home menu", Colors.white, TOP_SCREEN)
    Screen.debugPrint(30,110, "Update the updater", Colors.white, TOP_SCREEN)
    Screen.debugPrint(5,145, "Your Luma3DS version  : "..localVer, Colors.white, TOP_SCREEN)
    Screen.debugPrint(5,160, "Latest Luma3DS version: "..remoteVerNum, Colors.white, TOP_SCREEN)
    if (not isMenuhax) then
        Screen.debugPrint(5, 175, "Install directory: "..paths.payload, Colors.white, TOP_SCREEN)
    end
    Screen.debugPrint(5, 195, "Installed Updater: v."..ver.current, Colors.white, TOP_SCREEN)
    Screen.debugPrint(5, 210, "Latest Updater   : v."..ver.server, Colors.white, TOP_SCREEN)
    Screen.flip()
end

init()
main()
while true do
        pad = Controls.read()
        
        if Controls.check(pad,KEY_START) and not Controls.check(oldpad,KEY_START) then
        	System.exit()
        end	
            
        if Controls.check(pad,KEY_DDOWN) and not Controls.check(oldpad,KEY_DDOWN) then
            if (curPos < 110) then
                curPos = curPos + 15
                main()
            end
        elseif Controls.check(pad,KEY_DUP) and not Controls.check(oldpad,KEY_DUP) then
            if (curPos > 20) then
                curPos = curPos - 15
                main()
            end
        elseif Controls.check(pad,KEY_A) and not Controls.check(oldpad,KEY_A) then
            if (curPos == 20) then
                if (not isDev) then
                    update(urls.stable)
                else
                    update(urls.stableDev)
                end
            elseif (curPos == 35) then
                if (not isDev) then
                    update(urls.hourly)
                else
                    update(urls.hourlyDev)
                end
            elseif (curPos == 50) then
                restoreBackup()
            elseif (curPos == 65) then
                isDev = not isDev
                main()
            elseif (curPos == 80) then
                isMenuhax = not isMenuhax
                init()
                main()
            elseif (curPos == 95) then
                System.exit()
            elseif (curPos == 110) then
            	if iscia == 1 then
                	Screen.clear(TOP_SCREEN)
        		Screen.debugPrint(5, 5, "Downloading new CIA...", Colors.yellow, TOP_SCREEN)
       			Network.downloadFile(urls.latestCIA, "/Updater.CIA")
                	sleep(2000)
                	Screen.debugPrint(5, 20, "Installing CIA...", Colors.yellow, TOP_SCREEN)
                	System.installCIA("/Updater.CIA", SDMC)
                	System.deleteFile("/Updater.CIA")
                	System.exit()
                else
                	Screen.clear(TOP_SCREEN)
                	Screen.debugPrint(5, 5, "Downloading new script...", Colors.yellow, TOP_SCREEN)
					System.deleteFile("/3ds/StarUpdater/index.lua")
                	Network.downloadFile(urls.latestHBX, "/3ds/StarUpdater/index.lua")
                	System.exit()
            	end	

            end
        end
        oldpad = pad
    end


