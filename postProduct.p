/*------------------------------------------------------------------------
    File        : postProduct.p
    Purpose     : Magalu Marketplace
    Syntax      :
    Description : This program is used to post a new products  
    Author(s)   : Rodrigo Ferreira Reis
    Created     : Mon Jan 18 17:19:53 BRST 2021
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
DEFINE VARIABLE objClient        AS IHttpClient        NO-UNDO.
DEFINE VARIABLE objURI           AS URI                NO-UNDO.
DEFINE VARIABLE objCredentials   AS Credentials        NO-UNDO.
DEFINE VARIABLE objRequest       AS IHttpRequest       NO-UNDO.
DEFINE VARIABLE objResponse      AS IHttpResponse      NO-UNDO.
DEFINE VARIABLE objJson          AS JsonObject         NO-UNDO.
DEFINE VARIABLE categoryArray    AS JsonArray          NO-UNDO.
DEFINE VARIABLE attributesArray  AS JsonArray          NO-UNDO.
DEFINE VARIABLE objCategory      AS JsonObject         NO-UNDO.
DEFINE VARIABLE objAttributes    AS JsonObject         NO-UNDO.
DEFINE VARIABLE strJson          AS CHARACTER          NO-UNDO.
DEFINE VARIABLE objLib           AS IHttpClientLibrary NO-UNDO.
DEFINE VARIABLE tabHandle        AS HANDLE             NO-UNDO.

DEFINE TEMP-TABLE Product NO-UNDO
  FIELD IdProduct    AS CHARACTER
  FIELD CatId        AS CHARACTER
  FIELD Name         AS CHARACTER
  FIELD Code         AS CHARACTER
  FIELD Brand        AS CHARACTER
  FIELD NbmOrigin    AS CHARACTER
  FIELD NbmNumber    AS CHARACTER
  FIELD WarrantyTime AS CHARACTER
  FIELD Active       AS LOGICAL.

DEFINE TEMP-TABLE Categories NO-UNDO 
  FIELD Id        AS CHARACTER
  FIELD Name      AS CHARACTER
  FIELD ParentId  AS CHARACTER.


DEFINE TEMP-TABLE Attributes NO-UNDO 
  FIELD IdProduct AS CHARACTER
  FIELD Name      AS CHARACTER
  FIELD AValue    AS CHARACTER.
 

CREATE Product.
assign Product.IdProduct    = "PRD00001"
       Product.Code         = ""
       Product.Name         = "TEST"
       Product.Brand        = "TEST" 
       Product.NbmOrigin    = ""                                             
       Product.NbmNumber    = ""
       Product.WarrantyTime = ""
       Product.Active       = true
       Product.CatId        = "".
            
CREATE Categories.
ASSIGN Categories.Id       = ""
       Categories.ParentId = ""
       Categories.Name     = "".
  
objJson = NEW JsonObject().
  
FIND FIRST Product NO-LOCK NO-ERROR.

CREATE Attributes.
ASSIGN Attributes.IdProduct = Product.IdProduct
       Attributes.Name      = ""
       Attributes.AValue    = "".
/*-------------------------------------------------------------------------------------
    Creating the json using the products collection.
--------------------------------------------------------------------------------------*/  
FOR EACH Product NO-LOCK:

     categoryArray   = NEW JsonArray().
     attributesArray = NEW JsonArray().
/*------------------------------------------------------------------------
    If your products share the same category and you don't need to use 
    productID to query them you can use the lines bellow. 
    It work just fine. 
    tabHandle = TEMP-TABLE Category:HANDLE.
    categoryArray:Read(tabHandle).
  ------------------------------------------------------------------------*/

      FOR EACH  Categories 
          WHERE Categories.Id = Product.CatId NO-LOCK 
          BREAK BY Categories.Id:
          objCategory = NEW JsonObject().
          objCategory:ADD("Id",       Categories.Id).
          objCategory:ADD("Name",     Categories.Name).
          objCategory:ADD("ParentId", Categories.ParentId).
          categoryArray:ADD(objCategory).
      END.
/*------------------------------------------------------------------------
    If your products share the same attributes and you don't need to use 
    productID  to query them you can also use the lines bellow.  
    
    tabHandle = TEMP-TABLE Attributes:HANDLE.
    attributesArray:Read(tabHandle).
  ------------------------------------------------------------------------*/ 
      
      FOR EACH  Attributes  
          WHERE Attributes.IdProduct = Product.Idproduct NO-LOCK 
          BREAK BY Attributes.Name:
          
          objAttributes = NEW JsonObject().
          objAttributes:ADD("Name",  Attributes.Name).
          objAttributes:ADD("Value", Attributes.AValue). 
          attributesArray:ADD(objAttributes). 
      END.
      
      objJson:ADD("IdProduct",    Product.Idproduct).
      objJson:ADD("Name",         Product.Name).
      objJson:ADD("Code",         Product.Code).
      objJson:ADD("Brand",        Product.Brand).
      objJson:ADD("NbmOrigin",    Product.NbmOrigin).
      objJson:ADD("NbmNumber",    Product.NbmNumber).
      objJson:ADD("WarrantyTime", Product.WarrantyTime).
      objJson:ADD("Active",       Product.Active).     
      objJson:ADD("Categories",   categoryArray).  /*Array with categories goes here*/
      objJson:ADD("Attributes",   attributesArray) /*Array with attributes goes here*/.
 
END.

objJson:Write(strJson,TRUE). 
/*-------------------------------------------------------------------------------------
    if you want to visualize the json file, uncomment the line bellow 
--------------------------------------------------------------------------------------*/  
/*update  strJson VIEW-AS editor large size 78 by 18 . */

FIND FIRST Product NO-LOCK NO-ERROR. 
if AVAILABLE Product THEN RUN SEND.

PROCEDURE SEND:

   objLib = ClientLibraryBuilder:Build():sslVerifyHost(NO):Library.
   objClient = 
   
   ClientBuilder:Build():usingLibrary(objLib):KeepCookies(CookieJarBuilder:Build():CookieJar):Client.
   
   objURI = new URI('http','api.integracommerce.com.br').
   objURI:Path = '/api/Product'.
   
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

   IF objResponse:StatusCode <> 201 THEN
      MESSAGE 'Request error:' + STRING(objResponse:StatusCode) 
      VIEW-AS ALERT-BOX.
   else cast(objResponse:Entity, JsonObject):WriteFile('response.json', true). 
   
END PROCEDURE.