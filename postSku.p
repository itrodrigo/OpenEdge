/*------------------------------------------------------------------------
    File        : postSku.p
    Purpose     : Magalu Marketplace
    Syntax      :
    Description : 
    Author(s)   : Rodrigo Ferreira Reis
    Created     : Mon Jan 18 19:10:06 BRST 2021
    Notes       :
  ----------------------------------------------------------------------*/
/* ***************************  Definitions  ************************** */
using OpenEdge.Net.HTTP.*.
using OpenEdge.Net.URI.
using OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.

BLOCK-LEVEL ON ERROR UNDO, THROW.
/* ********************  Preprocessor Definitions  ******************** */
define variable objClient      AS IHttpClient        NO-UNDO.
define variable objURI         AS URI                NO-UNDO.
define variable objCredentials AS Credentials        NO-UNDO.
define variable objRequest     AS IHttpRequest       NO-UNDO.
define variable objResponse    AS IHttpResponse      NO-UNDO.
define variable JsonResp       AS JsonObject         NO-UNDO.       
DEFINE VARIABLE objJson        AS JsonObject         NO-UNDO.
DEFINE VARIABLE imgArray       AS JsonArray          NO-UNDO.
DEFINE VARIABLE attArray       AS JsonArray          NO-UNDO.
DEFINE VARIABLE objImg         AS JsonObject         NO-UNDO.
DEFINE VARIABLE objAttributes  AS JsonObject         NO-UNDO.
DEFINE VARIABLE objPrice       AS JsonObject         NO-UNDO.
DEFINE VARIABLE strJson        AS CHARACTER          NO-UNDO.
DEFINE VARIABLE IdSku          AS CHARACTER          NO-UNDO FORMAT "X(08)". 
DEFINE VARIABLE objLib         AS IHttpClientLibrary NO-UNDO.


DEFINE TEMP-TABLE Sku NO-UNDO
  FIELD Name          AS CHARACTER
  FIELD Description   AS CHARACTER
  FIELD Height        AS DECIMAL
  FIELD Width         AS DECIMAL
  FIELD Length        AS DECIMAL
  FIELD Weight        AS DECIMAL
  FIELD skuStatus     AS LOGICAL
  FIELD Variation     AS CHARACTER
  FIELD IdSku         AS CHARACTER
  FIELD IdSkuErp      AS CHARACTER
  FIELD IdProduct     AS CHARACTER
  FIELD CodeEan       AS CHARACTER
  FIELD CodeNcm       AS CHARACTER
  FIELD CodeIsbn      AS CHARACTER
  FIELD CodeNbm       AS CHARACTER
  FIELD StockQuantity AS INTEGER
  FIELD MainImageUrl  AS CHARACTER.
  
 
DEFINE TEMP-TABLE Prices
  FIELD IdSku     AS CHARACTER
  FIELD ListPrice AS DECIMAL
  FIELD SalePrice AS DECIMAL.
  
DEFINE TEMP-TABLE ImageUrl NO-UNDO 
  FIELD Id        AS CHARACTER
  FIELD UrlImages AS CHARACTER.


DEFINE TEMP-TABLE Attributes NO-UNDO 
  FIELD idSku    AS CHARACTER
  FIELD Name     AS CHARACTER
  FIELD AValue   AS CHARACTER.

/* ***************************  Main Block  *************************** */

RUN MakeJson.


PROCEDURE MakeJson:
  empty temp-table Sku.
  empty temp-table ImageUrl.
  empty temp-table Attributes.
  
  
  
  CREATE Sku.
  ASSIGN Sku.Name          = ""
         Sku.Description   = ""
         Sku.Height        = ""
         Sku.Width         = ""
         Sku.Length        = ""
         Sku.Weight        = ""
         Sku.skuStatus     = true
         Sku.Variation     = ""
         Sku.IdSku         = ""
         Sku.IdSkuErp      = ""
         Sku.IdProduct     = ""
         Sku.CodeEan       = ""
         Sku.CodeNcm       = ""
         Sku.CodeIsbn      = ""
         Sku.CodeNbm       = ""
         Sku.StockQuantity = 0
         Sku.MainImageUrl  = "http://your_image_url.com/".
        
 CREATE ImageUrl.
 objJson = NEW JsonObject().
 
 FOR FIRST Sku NO-LOCK:
     
     CREATE Attributes.
     ASSIGN Attributes.IdSku  = ""
            Attributes.Name   = "".
            Attributes.AValue = "".
          
      CREATE Prices.
      ASSIGN Prices.IdSku     = ""
             Prices.ListPrice = 1.00
             Prices.SalePrice = 1.00.
     
     imgArray = new JsonArray().
     attArray = new JsonArray().

     CREATE ImageUrl.
     ASSIGN ImageUrl.Id = Sku.IdSku
            ImageUrl.UrlImages = "http://your_image_url/".

     FOR FIRST ImageUrl 
         WHERE ImageUrl.Id = Sku.IdSku NO-LOCK 
         BREAK BY ImageUrl.Id:
         objImg = NEW JsonObject().
         objImg:ADD("UrlImages",  ImageUrl.UrlImages).
         ImgArray:ADD(objImg).
     END.
      
     
     FOR FIRST Prices NO-LOCK
         WHERE Prices.IdSku = Sku.IdSku:
          objPrice = NEW JsonObject().
          objPrice:ADD("ListPrice", Prices.ListPrice).
          objPrice:ADD("SalePrice", Prices.SalePrice).
     END.
      
     FOR EACH  Attributes  
         WHERE Attributes.IdSku = Sku.IdSku
         NO-LOCK BREAK BY Attributes.Name:
         
         objAttributes = NEW JsonObject().
         objAttributes:ADD("Name",  Attributes.Name).
         objAttributes:ADD("Value", Attributes.AValue). 
         attArray:ADD(objAttributes). 
     END.
     
      objJson:ADD("IdSku",         Sku.IdSku).
      objJson:ADD("IdSkuErp",      Sku.IdSkuErp).
      objJson:ADD("IdProduct",     Sku.IdProduct).
      objJson:ADD("Name", Sku.Name).
      objJson:ADD("Description",   Sku.Description).
      objJson:ADD("Height",        Sku.Height).
      objJson:ADD("Width",         Sku.Width).
      objJson:ADD("Length",        Sku.Length).
      objJson:ADD("Weight",        Sku.Weight).
      objJson:ADD("CodeEan",       Sku.CodeEan).
      objJson:ADD("CodeNcm",       Sku.CodeNcm).
      objJson:ADD("CodeIsbn",      Sku.CodeIsbn).
      objJson:ADD("CodeNbm",       Sku.CodeNbm).
      objJson:ADD("Variation",     Sku.Variation).     
      objJson:ADD("Status",        Sku.skuStatus).
      objJson:ADD("Price",         objPrice).
      objJson:ADD("StockQuantity", Sku.StockQuantity).
      objJson:ADD("MainImageUrl",  Sku.MainImageUrl).
      objJson:ADD("UrlImages",     objImg).
      objJson:ADD("Attributes",    objAttributes).

      
   END.

   objJson:Write(strJson,TRUE). 
   
   UPDATE  strJson VIEW-AS editor large size 78 by 18 . 
   
   RUN SendPost.
END PROCEDURE.



procedure SendPost:

   objLib = ClientLibraryBuilder:Build():sslVerifyHost(NO):Library.
   objClient = 
   
   ClientBuilder:Build():usingLibrary(objLib):KeepCookies(CookieJarBuilder:Build():CookieJar):Client.
   
   
   objURI = new URI('https','api.integracommerce.com.br').
   objURI:Path = '/api/Sku'.
   
   objCredentials = new Credentials('api.integracommerce.com.br',
               'your_user',
               'your_password').
   
   objRequest= RequestBuilder:Build('POST', objURI)
       :UsingBasicAuthentication(objCredentials) 
       :AcceptJson()
       :AddJsonData(objJson)
       :Request.
   objResponse = ResponseBuilder:Build():Response.
   
   
   objClient:Execute(objRequest, objResponse) no-error.
   
   
   if objResponse:StatusCode <> 201 then
      message 'Request error:' + string(objResponse:StatusCode) 
      view-as alert-box.
   else cast(objResponse:Entity, JsonObject):WriteFile('response.json', true). 
   
end procedure.

