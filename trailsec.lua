-- This information is used by the Wi-Fi dongle to make a wireless connection to the router in the Lab
SSID = "M112-PD"
SSID_PASSWORD = "aiv4aith2Zie4Aeg"

-- configure ESP as a station
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID,SSID_PASSWORD)
wifi.sta.autoconnect(1)

HOST = "iot-https-relay-firebase.appspot.com" 
URI = "/firebase/DatabaseService.json"

function build_post_request(host, uri, data_table)

    data = ""
    for param,value in pairs(data_table) do
        data = data .. param.."="..value.."&"
    end

    request = "POST "..uri.." HTTP/1.1\r\n"..
                "Host: "..host.."\r\n"..
                "Connection: close\r\n"..
                "Content-Type: application/x-www-form-urlencoded\r\n"..
                "Content-Length: "..string.len(data).."\r\n"..
                "\r\n"..
                data
    return request
end

-- This function registers a function to echo back any response from the server, to our DE1/NIOS system 
-- or hyper-terminal (depending on what the dongle is connected to)
function display(sck,response)
    print(response)
end

-- When using send_sms: the "from" number HAS to be your twilio number.
-- If you have a free twilio account the "to" number HAS to be your twilio verified number.
function send_to_firebase(data_table)

    json = "{\"latitude\" : "..data_table["lat"]..", "..
            "\"longitude\" : "..data_table["long"]..","..
            "\"timestamp\" : "..data_table["timestamp"]..","..
            "\"uid\" : "..data_table["uid"].."}"

    data = {
        firebaseUrl = "https://cpen391-poc.firebaseio.com/",
        path = "/Geolocation",
        method = "POST",
        data = json
    }

    socket = net.createConnection(net.TCP,0)
    socket:on("receive", function(sck, response)
        print(response)
    end)
    socket:connect(80,HOST)

    socket:on("connection", function(sck)
        post_request = build_post_request(HOST,URI,data)
        sck:send(post_request)
    end)
end

function send_coor(latitude, longitude, user_id)
    ip = wifi.sta.getip()

    if(ip==nil) then
        print("IP address not found. Please try again")
    else
        tmr.stop(0)
        json_data = {
            lat = latitude,
            long = longitude,
            timestamp = "{\".sv\" : \"timestamp\"}",
            uid = user_id
        }
        send_to_firebase(json_data)
    end
end
