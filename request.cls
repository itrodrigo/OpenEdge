/*------------------------------------------------------------------------
    File        : requests.cls
    Purpose     : Oracle Commerce Cloud
    Syntax      :
    Description : Send a request to Oracle Commerce Cloud
    Author(s)   : Rodrigo Ferreira Reis
    Created     : Thu Jun 30 12:49:15 BRST 2021
    Notes       :
  ----------------------------------------------------------------------*/

USING OpenEdge.Net.HTTP.*.
USING OpenEdge.Net.URI.
USING OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.*. 
USING OpenEdge.Core.String.

CLASS OCC.sendRequests:
    DEFINE VARIABLE k              AS INTEGER NO-UNDO.
    DEFINE VARIABLE objLib         AS IHttpClientLibrary NO-UNDO.
    DEFINE VARIABLE objClient      AS IHttpClient        NO-UNDO.
    DEFINE VARIABLE objURI         AS URI                NO-UNDO.
    DEFINE VARIABLE objCredentials AS Credentials        NO-UNDO.
    DEFINE VARIABLE objRequest     AS IHttpRequest       NO-UNDO.
    DEFINE VARIABLE objResponse    AS IHttpResponse      NO-UNDO.
    DEFINE VARIABLE NumCookies     AS integer            NO-UNDO.
    DEFINE VARIABLE objCookies     AS Cookie EXTENT      NO-UNDO.

    METHOD PUBLIC VOID createCredentials(INPUT apiAddress AS CHARACTER,
                                         INPUT apiUser    AS CHARACTER,
                                         INPUT apiKey     AS CHARACTER):
                                    
        objCredentials = new Credentials(apiAddress,apiUser,apiKey).
        
    END METHOD.
    
    METHOD PUBLIC VOID   createRequest(INPUT uriAddress AS CHARACTER, 
                                       INPUT apiPath    AS CHARACTER):
       
       objLib      = ClientLibraryBuilder:Build():sslVerifyHost(NO):Library.
       objClient   = ClientBuilder:Build():usingLibrary(objLib)
                   :KeepCookies(CookieJarBuilder:Build():CookieJar):Client.
       objURI      = new URI('https',uriAddress).
       objURI:Path = apiPath.
       objResponse = ResponseBuilder:Build():Response.

    END METHOD.



    METHOD  PUBLIC VOID sendRequest(INPUT jSonDocument AS JsonObject, INPUT requestType AS CHARACTER):
        objRequest = RequestBuilder:Build(requestType, objURI)
                   :UsingBasicAuthentication(objCredentials) 
                   :AcceptJson()
                   :AddJsonData(jSonDocument)
                   :Request.
           
        objClient:Execute(objRequest, objResponse) NO-ERROR.
        
        
        CASE objResponse:StatusCode:
             WHEN 200 THEN DO: //"OK"
             END.
             WHEN 201 THEN DO: //"Created"
             END.
             WHEN 202 THEN DO: //"Created - Wait for complete"
             END.
             WHEN 400 THEN DO: //"Bad Request"
             END.
             WHEN 401 THEN DO: //"Unauthorized"
             END.
             WHEN 403 THEN DO: //"Forbidden"
             END.
             WHEN 404 THEN DO: //"Not found"
             END.
             WHEN 405 THEN DO: //"Method Not Allowed"
             END.
             WHEN 406 THEN DO: //"Not Acceptable"
             END.
             WHEN 409 THEN DO: //"Conflict"
             END.
             WHEN 415 THEN DO: //"ContentType header is not correct"
             END.
             WHEN 500 THEN DO: //"Internal server error"
             END.
             WHEN 503 THEN DO: //"Service Unavailable"
             END.
                    
        END CASE.
        
        if objResponse:StatusCode <> 201 then
            MESSAGE 'Error:' + STRING(objResponse:StatusCode) 
            VIEW-AS ALERT-BOX.
            else cast(objResponse:Entity, JsonObject)
            :WriteFile('response.json', true). 


        IF ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
            DO k = 1 to ERROR-STATUS:NUM-MESSAGES:
              MESSAGE   ERROR-STATUS:GET-MESSAGE(k) VIEW-AS ALERT-BOX.
            END.
        
        END.
            
    END METHOD.


END CLASS.

