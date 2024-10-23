-- * Author: Natale Paolo Santo Stefano
-- * Date: 23-10-2024
-- *
-- * This code is part of the Fibaro gateway environment.
-- * It represents a QuickApp that when activated, sends an email using Google's RestApi.
-- * It assumes that all parameters that are part of the OAUTH2 authentication system are in the possession of the user.
-- * ----------------------------------------------------------------------------------------------------------------



-- declare local variables
local recipient = '<EMAIL DESTINATION ADDRESS>'
local subject = '<SUBJECT>'
local body = '<MAIL BODY>'
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local client_id= <YOUR CLIENT_ID>
local client_secret= <YOUR CLIENT_SECRET>
local refresh_token=<YOUR REFRESH_TOKEN>

-- Google RESTApi call
local address = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"

-- Create mail
function QuickApp:createEmail()
    -- creates a structure representing all parts of the mail
    local emailParts = {
        'Content-Type: text/plain; charset="UTF-8"',
        'MIME-Version: 1.0',
        'Content-Transfer-Encoding: 7bit',
        'to: ' .. recipient,               
        'subject: ' .. subject,
        '',                                -- Empty row separe headers from body
        body
    }
    -- return secure base64 mail formatted
    return self:makeUrlSafeCompact(self:enc(table.concat(emailParts, '\n')))   
end

 
-- encoding mail base64
function QuickApp:enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- make base64 secure URL
function QuickApp:makeUrlSafeCompact(str)
    return string.gsub(string.gsub(string.gsub(str, "%+", "-"), "/", "_"), "=+$", "")
end


function QuickApp:onInit()
    self:debug("onInit")
end

-- Action when button pressed
function QuickApp:onReleased()
    self:getToken(function(result)
        self:mailSend(result,function(res)
            --print return data from mailSend
            self:debug("result from mail send: ",res)
        end)
    end)
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

-- Send a mail using Google
-- * Paramters:
    -- access_token: access token received from previous call to getToken function
    -- callback: function to call when response data was received
function QuickApp:mailSend(access_token,callback)
    local encode_mail = self:createEmail()
    local encodeMsg = {raw= encode_mail }
    -- call RestAPi
    net.HTTPClient({timeout=3000}):request(address,{
            options = {
                data= json.encode(encodeMsg),  
                method = "POST",
                headers = {
                    ["Content-Type"]= "application/json",
                    ["Authorization"]= "Bearer "..access_token
                },
            },
        success = function(response)
                self:debug("response status:", response.status) 
                self:debug("headers:", response.headers["Content-Type"]) 
                self:debug("response ==>:", json.encode(response.data) )
                callback(response.status)
        end,
        error = function(error)
            self:debug('error: ' .. json.encode(error))
        end    
    })

end
