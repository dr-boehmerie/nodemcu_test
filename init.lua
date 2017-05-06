-- init.lua

-- parameters
--ip, nm, gq = "0.0.0.0", "255.255.255.0", "10.1.1.1"

function startupWlan()
	if (abort ~= false) then
		print("Startup aborted")
		abort = nil
		return
	end

	-- load credentials
	dofile("credentials.lua")

	-- config wifi
	print("Connecting to wifi...")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, pwd)
--	wifi.sta.setip({ip = ip, netmask = nm, gateway = gw})
	wifi.sta.connect()

	-- wait for IP
	function waitWlan()
		if (abort ~= false) then
			tmr.stop(0)
			wifi.sta.disconnect()
			print("Wait aborted")
			abort = nil
			return
		end
		print(".")
		local status = wifi.sta.status()
		local ip = wifi.sta.getip()
		if ((status == 5) and (ip ~= nil) and (ip ~= "0.0.0.0")) then
			tmr.stop(0)
			print(ip)
			-- load next script
			--dofile("")
		end
	end
	tmr.alarm(0, 1000, tmr.ALARM_AUTO, waitWlan)
end
-- wait for 3 seconds after startup, cancel by setting abort to true
abort = false;
tmr.alarm(0, 3000, tmr.ALARM_SINGLE, startupWlan)
