-- BME280 on DOGL128
-- http://nodemcu.readthedocs.io/en/master/en/modules/bme280/
-- DOGL128 with u8glib

-- altitude of the measurement place
--baseAlt = 320
--curAlt = 0
bme280_ok = 0
T = nil
P = nil
H = nil
D = nil

function init_display()
	local cs  = 8 -- GPIO15, pull-down 10k to GND
	local dc  = 3 -- GPIO0
	local res = 0 -- GPIO16, RES is optional YMMV
    spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
	disp = u8g.st7565_dogm128_hw_spi(cs, dc, res)

	disp:setFont(u8g.font_6x12r)
	disp:setFontRefHeightExtendedText()
	disp:setDefaultForegroundColor()
	disp:setFontPosTop()
end

function update_display()
	local x = 0
	local y = 0

	disp:drawRFrame(0, 0, 128, 64, 3)
	x = x + 3
	y = y + 1

	if (bme280_ok ~= 1) then
		disp:drawStr(x, y, "BME280 not found!")
		return
	end
	if (T == nil or P == nil or H == nil or D == nil) then
		disp:drawStr(x, y, "nil values!")
		return
	end

	if (T < 0) then
		disp:drawStr(x, y, string.format("T: -%d.%02d 'C", -T/100, -T%100))
	else
		disp:drawStr(x, y, string.format("T: %d.%02d 'C", T/100, T%100))
	end
	y = y + 12
	disp:drawStr(x, y, string.format("H: %d.%03d %%", H/1000, H%1000))
	y = y + 12

	if (D < 0) then
		disp:drawStr(x, y, string.format("D: -%d.%02d 'C", -D/100, -D%100))
	else
		disp:drawStr(x, y, string.format("D: %d.%02d 'C", D/100, D%100))
	end
	y = y + 12

	disp:drawStr(x, y, string.format("P: %d.%03d mbar", P/1000, P%1000))
	y = y + 12
--	disp:drawStr(x, y, string.format("QNH = %d.%03d", QNH/1000, QNH%1000))
--	y = y + 13

	disp:drawHLine(0, y, 128)
	y = y + 2;

--	if (curAlt > 0) then
--		disp:drawStr(x, y, string.format("altitude = %d.%02d", curAlt/100, curAlt%100))
--	else
		local u = adc.readvdd33() + 50
		disp:drawStr(x, y, string.format("Heap: %d ADC: %d.%d", node.heap(), u/1000, (u%1000)/100))
--	end
end

function draw_loop()
    -- Draws one page and schedules the next page, if there is one
    local function draw_pages()
        update_display()
        if disp:nextPage() then
			node.task.post(draw_pages)
        else
			if (bme280_ok == 1) then
			--	node.task.post(update_bme280)
				-- update readings every 3 seconds
				tmr.alarm(0, 3000, tmr.ALARM_SINGLE, update_bme280)
			end
        end
    end
    -- Restart the draw loop and start drawing pages
    disp:firstPage()
    node.task.post(draw_pages)
end

function init_bme280()
    local sda = 4 -- GPIO2
    local scl = 3 -- GPIO0
	-- default oversampling is 16x (5)
--	temp_oss = 5
--	press_oss = 5
--	humi_oss = 5
	-- default sensor mode is normal (3)
--	power_mode = 3
	-- default inactive_duration is 20ms (7)
--	inactive_duration = 7
	-- default filter coeff is 16 (4)
--	iir_filter = 4
	-- if 0 the bme280 chip is not initialised.
	-- Usefull in a battery operated setup when the ESP deep sleeps and
	-- on wakeup needs to initialise the driver (the module) but not the chip itself.
	-- The chip was kept powered (sleeping too) and is holding the latest reading
	-- that should be fetched quickly before another reading starts (bme280.startreadout()). 
--	cold_start = 1
	-- initialize bme280
	--result = bme280.init(sda,scl,temp_oss,press_oss,humi_oss,power_mode,inactive_duration,iir_filter,cold_start)
	local result = bme280.init(sda,scl)
	-- nil if not connected, 2 for bme280, 1 for bmp280
	if (result == 2) then
		print("BME280 found!")
		bme280_ok = 1
	else
		print("BME280 init failed!")
		bme280_ok = 0
	end
end

function read_bme280()
	print("read_bme280 (Heap = " .. node.heap() .. ")")

	if (bme280_ok == 1) then
		-- temperature in celsius as an integer multiplied by 100
		-- air pressure in hectopascals multiplied by 100
		-- relative humidity in percent multiplied by 1000
		-- air pressure in hectopascals multiplied by 1000 converted to sea level
		--T, P, H, QNH = bme280.read(baseAlt)	-- nil!
		H, T = bme280.humi()
		-- altimeter function - calculate altitude based on current sea level pressure (QNH) and measured pressure
		P = bme280.baro()
		-- dew point in celsius multiplied by 100
		if (H ~= nil and T ~= nil) then
			D = bme280.dewpoint(H, T)
		end
		--if (P ~= nil and QNH ~= nil) then
		--	curAlt = bme280.altitude(P, QNH)
		--end
	end
	-- start draw loop
	node.task.post(draw_loop)
end

function update_bme280()
	node.task.post(read_bme280)
end

init_display()
init_bme280()

update_bme280()
