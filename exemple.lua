local _CMR = {
    UrlBase = "https://mail.cmr.dev.br",
    Identification = "recovery",
    Username = "",
    Password = "",
    AccessToken = nil
}

_CMR.UrlEncode = function(data)
    data = data:gsub("\n", "\r\n");
    data = data:gsub("([^%w ])", function(c)
         return string.format("%%%02X", string.byte(c));
    end)

    data = data:gsub(" ", "+");
    return data;
end

_CMR.ReadFile = function(filePath)
    local file = fileOpen(filePath);

    if file then
        local size = fileGetSize(file);
        local content = fileRead(file, size);

        fileClose(file);

        return content;
    end

    return nil
end

_CMR.FormatData = function(data)
    local postData = '';

    for key, value in pairs(data) do
        postData = postData..key..'='.._CMR.UrlEncode(value)..'&';
    end

    postData = postData:sub(1, -2);

    return postData;
end

_CMR.Auth = function()
    local body = {
        username = _CMR.Username,
        password = _CMR.Password
    }

    fetchRemote(_CMR.UrlBase..'/api/auth/',{
         headers = {
              ['Content-Type'] = "application/x-www-form-urlencoded",
         };
         queueName = "POST",
         postData = _CMR.FormatData(body)
    },
    function(response, error)
         local response = fromJSON(response);
         if response and error and not response['detail'] and response['access_token'] then
              _CMR.AccessToken = response['access_token'];
         end
    end)
end

_CMR.SendMail = function(name, title, email, file)
    if not _CMR.AccessToken then
        return;
    end

    local body = {
        identification = _CMR.Identification,
        emails = email,
        title = title,
        body = _CMR.ReadFile(file),
        name = name
    }

    fetchRemote(_CMR.UrlBase..'/api/mail/',{
        headers = {
            ['Content-Type'] = "application/x-www-form-urlencoded",
            ['Authorization'] = "Bearer ".._CMR.AccessToken
        };
        queueName = "POST",
        postData = _CMR.FormatData(body)
   },
   function(_, headers)
        if headers.statusCode == 204 then
            iprint("E-mail enviado!");
            return;
        end

        iprint("E-mail não foi enviado!");
   end)
end

_CMR.Auth(); -- Authenticação ela expira a cada 2 horas
setTimer(function()
    _CMR.SendMail("Exemple", "Recuperação de senha", "exemple@exemple.com", "exemple.html")
end, 1000, 1)