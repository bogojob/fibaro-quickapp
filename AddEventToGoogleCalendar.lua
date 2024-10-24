-- * Author: Natale Paolo Santo Stefano
-- * Date: 24-10-2024
-- *
-- * This code is part of the Fibaro gateway environment.
-- * It represents a QuickApp that when activated, sends an email using Google's RestApi.
-- * It assumes that all parameters that are part of the OAUTH2 authentication system are in the possession of the user.
-- * ----------------------------------------------------------------------------------------------------------------



-- declare local variables
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local client_id= <YOUR CLIENT_ID>
local client_secret= <YOUR CLIENT_SECRET>
local refresh_token=<YOUR REFRESH_TOKEN>

-- Google RESTApi call
local address = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

-- prepare event elements
local summary = "Event title"
local location = "Event localtion"
local description = "Event description"
local startDate = "2024-10-30T09:00:00-07:00"
local timeZone = "Europe/Rome"
local endDate = "2024-10-30T20:00:00-07:00"
local mailCalendareUsers = {{"xxxx@acme.com}} -- list of users calendar

local requestBody = {
        summary = summary
        location = location,
        description= description
        start= {
            dateTime = startDate
            timeZone = timeZone},
            ["end"]= {
                dateTime= andDate,
                timeZone=timeZone
                },
            attendees=mailCalendarUsers
    }

function QuickApp:onInit()
    self:debug("onInit")
end

-- Action when button pressed
function QuickApp:onReleased()
      self:getToken(function(result)
              self:createEventOnCalendar(result,function(res)
                  self:debug("###",res)
              end)
        end)
end


function QuickApp:createEventOnCalendar(access_token,callback)
    net.HTTPClient({timeout=3000}):request(address,{
        options = {
                data= json.encode(requestBody),  
                method = "POST",
                headers = {
                    ["Content-Type"]= "application/json",
                    ["Authorization"]= "Bearer "..access_token
                },
            },
        success = function(response)
              self:debug("response status:", response.status) 
              self:debug("response=>:", json.encode(response.data) )
              callback(response.status)
        end,
          error = function(error)
          self:debug('error: ' .. json.encode(error))
        end    
    })
end




--  * Get access_token from google
--  * Parameters:
    -- client_id: <YOUR GOOGLE CLIENT_ID>
    -- client_secret: <YOUR GOOGLE CLIENT_SECRET>
    -- refresh_token: <YOUR GOOGLE REFRESH_TOKEN>
    -- grant_type: refresh_token
    -- callback: function to call when data received
function QuickApp:getToken(callback)
local params = 'client_id='..client_id..'&'..'client_secret='..client_secret..'&'..'refresh_token='..refresh_token..'&'..'grant_type=refresh_token'

    local address = "https://oauth2.googleapis.com/token"
    local access_token

    net.HTTPClient({timeout=3000}):request(address,{
            options = {
                data=params,
                headers = {["Content-Type"]= "application/x-www-form-urlencoded"},
                method = 'POST'
            },
        success = function(response)
                jsonData = json.decode(response.data)
                local access_token = jsonData.access_token
                self:debug("access_token =>", access_token)
                callback(access_token)
        end,
        error = function(error)
            self:debug('error: ' .. json.encode(error))
        end    
    })
end

