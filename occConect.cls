/*------------------------------------------------------------------------
    File        : occConnect.cls
    Purpose     : Oracle Commerce Cloud
    Syntax      :
    Description : 
    Author(s)   : Rodrigo Ferreira Reis | Bruno Ferreira
    Created     : Thu Jul 05 14:35:16 BRST 2021
    Notes       :
  ----------------------------------------------------------------------*/
  
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.ObjectModelParser.
USING Progress.Lang.Object.
USING OpenEdge.Core.WidgetHandle.
USING OpenEdge.Core.String.
USING OpenEdge.Net.HTTP.IHttpClient.
USING OpenEdge.Net.HTTP.IHttpClientLibrary.
USING OpenEdge.Net.HTTP.ClientBuilder.
USING OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
USING OpenEdge.Net.HTTP.Credentials.
USING OpenEdge.Net.HTTP.IHttpRequest.
USING OpenEdge.Net.HTTP.IHttpResponse.
USING OpenEdge.Net.HTTP.RequestBuilder.
USING OpenEdge.Core.Collections.IStringStringMap.
USING OpenEdge.Core.Collections.StringStringMap.
USING OpenEdge.Net.HTTP.Cookie.
USING OpenEdge.Net.HTTP.CookieJarBuilder.
USING OpenEdge.Net.HTTP.ICookieJar.


CLASS OCC.CONNECT:
    DEFINE VARIABLE oLib         AS IHttpClientLibrary  NO-UNDO.
    DEFINE VARIABLE oClient      AS IHttpClient         NO-UNDO.
    DEFINE VARIABLE oReq         AS IHttpRequest        NO-UNDO.
    DEFINE VARIABLE oResp        AS IHttpResponse       NO-UNDO.
    DEFINE VARIABLE objCookieJar AS ICookieJar          NO-UNDO.
    DEFINE VARIABLE oForm        AS IStringStringMap    NO-UNDO.
    DEFINE VARIABLE oJson        AS JsonObject          NO-UNDO.
    DEFINE VARIABLE lcToken      AS LONGCHAR            NO-UNDO.
    DEFINE VARIABLE cToken       AS CHARACTER           NO-UNDO.
    DEFINE VARIABLE exToken      AS INTEGER             NO-UNDO.
    DEFINE VARIABLE oRequestBody AS LONGCHAR            NO-UNDO.
    DEFINE VARIABLE httpUrl      AS CHARACTER           NO-UNDO.
    DEFINE VARIABLE strJson      AS LONGCHAR            NO-UNDO.
  

    METHOD PUBLIC CHARACTER GetToken(): 
      return cToken.
    END METHOD.

    METHOD PUBLIC VOID login():

    

      httpUrl = occurl.url + '/ccadmin/v1/login'.
      oLib = ClientLibraryBuilder
           :Build()
           // when using HTTPS
           :AddSslProtocol('TLSv1.2') 
           :Library.
    
    
      FIND FIRST occWebApi NO-LOCK 
           WHERE occWebApi.AppName = "ocx-osf-storefront" NO-ERROR.
       
      //Cookies management
      objCookieJar = CookieJarBuilder:Build():CookieJar.
      objCookieJar:ClearSessionCookies().
      oClient      = ClientBuilder:Build()
                   :KeepCookies(objCookieJar)
                   :Client.
    
      oForm = NEW StringStringMap().
      oForm:Put("grant_type","client_credentials").
      lcToken = occWebApi.appKey.
      
      cToken = 'Bearer ' + STRING(lcToken) .
      oReq = RequestBuilder:POST(httpUrl, oForm) 
           :AddHeader('Authorization', cToken) 
           :AcceptJson() 
           :ContentType('application/x-www-form-urlencoded') 
           :Request.  
            
      oResp = ClientBuilder:Build() 
                           :UsingLibrary(oLib) 
                           :Client 
                           :Execute(oReq).
    
      IF TYPE-OF(oResp:Entity, JsonObject) THEN DO:
        ASSIGN oJson = CAST(oResp:Entity, JsonObject).
        
        lcToken = oJson:GetJsonText("access_token").
         
      
      END.
    END METHOD.
             
    METHOD PUBLIC VOID GET(input endpoint as character):

      

      // Pass the Bearer  token
      cToken  = 'Bearer ' + STRING(lcToken) .

      httpUrl = occurl.url + '/ccadmin/v1/' + endpoint.

        oReq = RequestBuilder:Get(httpUrl) 
                             :AddHeader('Authorization', cToken) 
                             :AddHeader('x-ccasset-language', 'pt_BR')
                             :ContentType('application/json') 
                             :Request.  
        
        oResp = oClient:Execute(oReq).
        
        IF TYPE-OF(oResp:Entity, JsonObject) THEN DO:
            ASSIGN oJson = CAST(oResp:Entity, JsonObject).
            oJson:Write(strJson, TRUE).
          UPDATE strJson VIEW-AS editor large size 78 by 18.
        END.

    END METHOD.


    METHOD PUBLIC VOID PUT(INPUT endpoint AS CHARACTER,
                           INPUT id       AS CHARACTER,
                           INPUT jsonReq  AS JsonObject):

        

        // Pass the Bearer  token
        cToken  = 'Bearer ' + STRING(lcToken) .
        
        httpUrl = occurl.url + '/ccadmin/v1/' + endpoint + "/" + id.

        oReq = RequestBuilder:put(httpUrl, jsonReq) 
                             :AddHeader('Authorization', cToken) 
                             :AddHeader('x-ccasset-language','pt_BR')
                             :AcceptJson() 
                             :ContentType('application/json') 
                             :Request.  

        oResp = oClient:Execute(oReq).
       
        IF TYPE-OF(oResp:Entity, JsonObject) THEN DO:
            ASSIGN oJson = CAST(oResp:Entity, JsonObject).
            oJson:Write(strJson, TRUE).
            UPDATE strJson VIEW-AS editor large size 78 by 18.
        END.

    END METHOD.

    METHOD PUBLIC VOID POST(INPUT endpoint AS CHARACTER,
                           INPUT jsonReq  AS JsonObject):

        

        // Pass the Bearer  token
        cToken  = 'Bearer ' + STRING(lcToken).
        
        httpUrl = occurl.url + '/ccadmin/v1/' + endpoint.

        oReq = RequestBuilder:post(httpUrl, jsonReq) 
                             :AddHeader('Authorization', cToken)
                             :AddHeader('x-ccasset-language', 'pt_BR')
                             :AcceptJson() 
                             :ContentType('application/json') 
                             :Request.  

        oResp = oClient:Execute(oReq).
       
        IF TYPE-OF(oResp:Entity, JsonObject) THEN DO:
            ASSIGN oJson = CAST(oResp:Entity, JsonObject).
            oJson:Write(strJson, TRUE).
            UPDATE strJson VIEW-AS editor large size 78 by 18.
        END.

    END METHOD. 

    METHOD PUBLIC VOID DELETE(INPUT endpoint AS CHARACTER,
                              INPUT id       AS CHARACTER):

       

        // Pass the Bearer  token
        cToken  = 'Bearer ' + STRING(lcToken).
        
        httpUrl = occurl.url + '/ccadmin/v1/' + endpoint + "/" + id.

        oReq = RequestBuilder:delete(httpUrl) 
                             :AddHeader('Authorization', cToken)
                             :AddHeader('x-ccasset-language', 'pt_BR')
                             :AcceptJson() 
                             :ContentType('application/json') 
                             :Request.

        oResp = oClient:Execute(oReq).
       
        /*IF TYPE-OF(oResp:Entity, JsonObject) THEN DO:
            ASSIGN oJson = CAST(oResp:Entity, JsonObject).
            oJson:Write(strJson, TRUE).
            UPDATE strJson VIEW-AS editor large size 78 by 18.
        END.*/

    END METHOD. 

END CLASS.
