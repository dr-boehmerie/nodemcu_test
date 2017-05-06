-- http://nodemcu.readthedocs.io/en/master/en/modules/bme280/
-- BME280 Test

-- altitude of the measurement place
alt = 320
bme280_ok = 0

-- setup I2c and connect display
function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 3 -- GPIO14
    local scl = 4 -- GPIO12
    local sla = 0x3c -- SA0 GND
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
	
    disp:setFont(u8g.font_6x12r)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
end

function init_bme280()
    local sda = 3
    local scl = 4
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
	if result == 2 then
		print("BME280 found!")
		bme280_ok = 1
	else
		print("BME280 init failed!")
		bme280_ok = 0
	end
end

function print_bme280()
	-- temperature in celsius as an integer multiplied by 100
	-- air pressure in hectopascals multiplied by 100
	-- relative humidity in percent multiplied by 1000
	-- air pressure in hectopascals multiplied by 1000 converted to sea level
	T, P, H, QNH = bme280.read(alt)
	-- dew point in celsius multiplied by 100
	D = bme280.dewpoint(H, T)
	-- altimeter function - calculate altitude based on current sea level pressure (QNH) and measured pressure
	P = bme280.baro()
	curAlt = bme280.altitude(P, QNH)
	
	if T < 0 then
		print(string.format("T = -%d.%02d", -T/100, -T%100))
	else
		print(string.format("T = %d.%02d", T/100, T%100))
	end
	print(string.format("QFE = %d.%03d", P/1000, P%1000))
	print(string.format("QNH = %d.%03d", QNH/1000, QNH%1000))
	print(string.format("humidity = %d.%03d%%", H/1000, H%1000))
	if D < 0 then
		print(string.format("dew_point = -%d.%02d", -D/100, -D%100))
	else
		print(string.format("dew_point = %d.%02d", D/100, D%100))
	end
	if curAlt < 0 then
		print(string.format("altitude = -%d.%02d", -curAlt/100, -curAlt%100))
	else
		print(string.format("altitude = %d.%02d", curAlt/100, curAlt%100))
	end
end

function display_bme280()
	local x = 0
	local y = 0

	-- temperature in celsius as an integer multiplied by 100
	-- air pressure in hectopascals multiplied by 100
	-- relative humidity in percent multiplied by 1000
	-- air pressure in hectopascals multiplied by 1000 converted to sea level
	T, P, H, QNH = bme280.read(alt)
	-- dew point in celsius multiplied by 100
	D = bme280.dewpoint(H, T)
	-- altimeter function - calculate altitude based on current sea level pressure (QNH) and measured pressure
	P = bme280.baro()
	curAlt = bme280.altitude(P, QNH)
	
	-- draw loop wtf?
    disp:firstPage()
	
	repeat
		x = 0
		y = 0
		if T < 0 then
			disp:drawStr(x, y, string.format("T = -%d.%02d", -T/100, -T%100))
		else
			disp:drawStr(x, y, string.format("T = %d.%02d", T/100, T%100))
		end
		y = y + 13
		disp:drawStr(x, y, string.format("QFE = %d.%03d", P/1000, P%1000))
		y = y + 13
		disp:drawStr(x, y, string.format("QNH = %d.%03d", QNH/1000, QNH%1000))
		y = y + 13
		disp:drawStr(x, y, string.format("humidity = %d.%03d%%", H/1000, H%1000))
		y = y + 13
		if D < 0 then
			disp:drawStr(x, y, string.format("dew_point = -%d.%02d", -D/100, -D%100))
		else
			disp:drawStr(x, y, string.format("dew_point = %d.%02d", D/100, D%100))
		end
		y = y + 13
		if curAlt < 0 then
			disp:drawStr(x, y, string.format("altitude = -%d.%02d", -curAlt/100, -curAlt%100))
		else
			disp:drawStr(x, y, string.format("altitude = %d.%02d", curAlt/100, curAlt%100))
		end

	until disp:nextPage() == false
end




init_i2c_display()
print("Heap: " .. node.heap())

init_bme280()
print("Heap: " .. node.heap())

if bme280_ok == 1 then
	print_bme280()
	display_bme280()
	print("Heap: " .. node.heap())
end