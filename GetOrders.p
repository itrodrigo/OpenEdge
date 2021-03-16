/*------------------------------------------------------------------------
    File        : GetOrders.p
    Purpose     : Magalu Marketplace
    Syntax      :
    Description : List new orders from Magalu Marketplace and store it into temp-table
                  Listar novos pedidos no marketplace da Magalu e armazenar em temp-table. 
    Author(s)   : Rodrigo Ferreira Reis
    Created     : Mon Jan 18 17:19:53 BRST 2021
    Notes       :
  ----------------------------------------------------------------------*/
/* ***************************  Definitions  ************************** */
USING OpenEdge.Net.HTTP.*.
USING OpenEdge.Net.URI.
USING OpenEdge.Net.HTTP.Lib.ClientLibraryBuilder.
USING Progress.Json.ObjectModel.JsonObject.
USING Progress.Json.ObjectModel.JsonArray.
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.Object.

.BLOCK-LEVEL ON ERROR UNDO, THROW.
/* ********************  Preprocessor Definitions  ******************** */
DEFINE VARIABLE objClient      AS IHttpClient        NO-UNDO.
DEFINE VARIABLE objURI         AS URI                NO-UNDO.
DEFINE VARIABLE objCredentials AS Credentials        NO-UNDO.
DEFINE VARIABLE objRequest     AS IHttpRequest       NO-UNDO.
DEFINE VARIABLE objResponse    AS IHttpResponse      NO-UNDO.
DEFINE VARIABLE strResponse    AS CHARACTER          NO-UNDO.
DEFINE VARIABLE objLib         AS IHttpClientLibrary NO-UNDO.
DEFINE VARIABLE oEntity        AS Object             NO-UNDO.
DEFINE VARIABLE objOrders      AS JsonObject         NO-UNDO.
DEFINE VARIABLE objProducts    AS JsonObject         NO-UNDO.
DEFINE VARIABLE oOrder         AS JsonObject         NO-UNDO.
DEFINE VARIABLE ordersArray    AS JsonArray          NO-UNDO.
DEFINE VARIABLE ProductsArray  AS JsonArray          NO-UNDO.

                               
DEFINE TEMP-TABLE ORDER
  FIELD IdOrder                          AS CHARACTER                      
  FIELD IdOrderMarketplace               AS CHARACTER           
  FIELD InsertedDate                     AS CHARACTER                 
  FIELD PurchasedDate                    AS CHARACTER                
  FIELD ApprovedDate                     AS CHARACTER                 
  FIELD UpdatedDate                      AS CHARACTER                  
  FIELD MarketplaceName                  AS CHARACTER              
  FIELD StoreName                        AS CHARACTER                    
  FIELD UpdatedMarketplaceStatus         AS LOGICAL
  FIELD InsertedErp                      AS LOGICAL
  FIELD EstimatedDeliveryDate            AS CHARACTER        
  FIELD CustomerPfCpf                    AS CHARACTER                
  FIELD ReceiverName                     AS CHARACTER                 
  FIELD CustomerPfName                   AS CHARACTER               
  FIELD CustomerPjCnpj                   AS CHARACTER               
  FIELD CustomerPjCorporatename          AS CHARACTER      
  FIELD DeliveryAddressStreet            AS CHARACTER        
  FIELD DeliveryAddressAdditionalInfo    AS CHARACTER
  FIELD DeliveryAddressZipcode           AS CHARACTER       
  FIELD DeliveryAddressNeighborhood      AS CHARACTER  
  FIELD DeliveryAddressCity              AS CHARACTER          
  FIELD DeliveryAddressReference         AS CHARACTER     
  FIELD DeliveryAddressState             AS CHARACTER         
  FIELD DeliveryAddressNumber            AS CHARACTER        
  FIELD TelephoneMainNumber              AS CHARACTER          
  FIELD TelephoneSecundaryNumber         AS CHARACTER     
  FIELD TelephoneBusinessNumber          AS CHARACTER      
  FIELD TotalAmount                      AS CHARACTER                  
  FIELD TotalTax                         AS CHARACTER                     
  FIELD TotalFreight                     AS CHARACTER                 
  FIELD TotalDiscount                    AS CHARACTER                
  FIELD CustomerMail                     AS CHARACTER                 
  FIELD CustomerBirthDate                AS CHARACTER            
  FIELD CustomerPjIe                     AS CHARACTER                 
  FIELD OrderStatus                      AS CHARACTER                  
  FIELD InvoicedNumber                   AS CHARACTER               
  FIELD InvoicedLine                     AS INTEGER                 
  FIELD InvoicedIssueDate                AS CHARACTER            
  FIELD InvoicedKey                      AS CHARACTER                  
  FIELD ShippedTrackingUrl               AS CHARACTER           
  FIELD ShippedTrackingProtocol          AS CHARACTER      
  FIELD ShippedEstimatedDelivery         AS CHARACTER     
  FIELD ShippedCarrierDate               AS CHARACTER           
  FIELD ShippedCarrierName               AS CHARACTER           
  FIELD ShipmentExceptionObservation     AS CHARACTER 
  FIELD ShipmentExceptionOccurrenceDate  AS CHARACTER
  FIELD DeliveredDate                    AS CHARACTER                
  FIELD ShippedCodeERP                   AS CHARACTER               
  FIELD BranchDocument                   AS CHARACTER.              

 
DEFINE TEMP-TABLE OrderProduct
 FIELD IdSku          AS CHARACTER
 FIELD Quantity       AS INTEGER
 FIELD Price          AS CHARACTER 
 FIELD Freight        AS CHARACTER
 FIELD Discount       AS CHARACTER
 FIELD IdOrder        AS CHARACTER
 FIELD IdOrderPackage AS CHARACTER.
 
/* ***************************  Main Block  *************************** */
objLib    = ClientLibraryBuilder:Build():sslVerifyHost(NO):Library.
objClient = ClientBuilder:Build():usingLibrary(objLib):KeepCookies(CookieJarBuilder:Build():CookieJar):Client.

objURI  = NEW URI('https','api.integracommerce.com.br').

objURI:Path = '/api/Order?page=1&perPage=50&status=PROCESSING'.
                                     
objCredentials = NEW Credentials('api.integracommerce.com.br','your_user','your_password').

objRequest= RequestBuilder:Build('GET', objURI)
    :UsingBasicAuthentication(objCredentials) 
    :AcceptJson()
    :Request.
objResponse = ResponseBuilder:Build():Response.

objClient:Execute(objRequest, objResponse) NO-ERROR.


IF objResponse:StatusCode <> 200 THEN
   MESSAGE 'Request error:' + STRING(objResponse:StatusCode) 
   VIEW-AS ALERT-BOX.

oEntity = objResponse:Entity.

IF TYPE-OF(oEntity, JsonObject)
   THEN objOrders = CAST(oEntity, JsonObject).
   ELSE DO:
   MESSAGE "ERROR: Cannot understand response from service"
   VIEW-AS ALERT-BOX.
   RETURN ERROR.
END.


IF objOrders:GetInteger('Total') > 0 THEN DO:
   ordersArray = objOrders:GetJsonArray('Orders') NO-ERROR.
   RUN save_orders.
END.
ELSE DO:
   RETURN "No Order".
END.


PROCEDURE save_orders:
   define variable o as integer.
   define variable p as integer.
   
   
   DO o  = 1 TO objOrders:GetInteger('Total'):
      
      oOrder = ordersArray:GetJsonObject(o).
   
      FIND FIRST mglOrder NO-LOCK 
           WHERE mglOrder.IdOrder = oOrder:GetCharacter("IdOrder") NO-ERROR.
           
      IF AVAIL Order THEN NEXT.
   
      CREATE Order.
      ASSIGN Order.IdOrder                         = oOrder:GetCharacter("IdOrder")                               
             Order.IdOrderMarketplace              = oOrder:GetCharacter("IdOrderMarketplace")                            
             Order.InsertedDate                    = oOrder:GetCharacter("InsertedDate")
             Order.PurchasedDate                   = oOrder:GetCharacter("PurchasedDate")
             Order.ApprovedDate                    = oOrder:GetCharacter("ApprovedDate")
             Order.UpdatedDate                     = oOrder:GetCharacter("UpdatedDate")
             Order.MarketplaceName                 = oOrder:GetCharacter("MarketplaceName")              
             Order.StoreName                       = oOrder:GetCharacter("StoreName")
             Order.UpdatedMarketplaceStatus        = oOrder:GetLogical("UpdatedMarketplaceStatus")                                   
             Order.InsertedErp = oOrder:GetLogical("InsertedErp")
             Order.EstimatedDeliveryDate           = oOrder:GetCharacter("EstimatedDeliveryDate")
             Order.CustomerPfCpf                   = oOrder:GetCharacter("CustomerPfCpf")
             Order.ReceiverName                    = oOrder:GetCharacter("ReceiverName")
             Order.CustomerPfName                  = oOrder:GetCharacter("CustomerPfName")
             Order.CustomerPjCnpj                  = oOrder:GetCharacter("CustomerPjCnpj")
             Order.CustomerPjCorporatename         = oOrder:GetCharacter("CustomerPjCorporatename")
             Order.DeliveryAddressStreet           = oOrder:GetCharacter("DeliveryAddressStreet")
             Order.DeliveryAddressAdditionalInfo   = oOrder:GetCharacter("DeliveryAddressAdditionalInfo")
             Order.DeliveryAddressZipcode          = oOrder:GetCharacter("DeliveryAddressZipcode")
             Order.DeliveryAddressNeighborhood     = oOrder:GetCharacter("DeliveryAddressNeighborhood")
             Order.DeliveryAddressCity             = oOrder:GetCharacter("DeliveryAddressCity")
             Order.DeliveryAddressReference        = oOrder:GetCharacter("DeliveryAddressReference")
             Order.DeliveryAddressState            = oOrder:GetCharacter("DeliveryAddressState")
             Order.DeliveryAddressNumber           = oOrder:GetCharacter("DeliveryAddressNumber")
             Order.TelephoneMainNumber             = oOrder:GetCharacter("TelephoneMainNumber")
             Order.TelephoneSecundaryNumber        = oOrder:GetCharacter("TelephoneSecundaryNumber")
             Order.TelephoneBusinessNumber         = oOrder:GetCharacter("TelephoneBusinessNumber")
             Order.TotalAmount                     = oOrder:GetCharacter("TotalAmount")
             Order.TotalTax                        = oOrder:GetCharacter("TotalTax")
             Order.TotalFreight                    = oOrder:GetCharacter("TotalFreight")
             Order.TotalDiscount                   = oOrder:GetCharacter("TotalDiscount")
             Order.CustomerMail                    = oOrder:GetCharacter("CustomerMail")                     
             Order.CustomerBirthDate               = oOrder:GetCharacter("CustomerBirthDate")
             Order.CustomerPjIe                    = oOrder:GetCharacter("CustomerPjIe")
             Order.OrderStatus                     = oOrder:GetCharacter("OrderStatus")
             Order.InvoicedNumber                  = oOrder:GetCharacter("InvoicedNumber")
             Order.InvoicedLine                    = oOrder:GetInteger("InvoicedLine")
             Order.InvoicedIssueDate               = oOrder:GetCharacter("InvoicedIssueDate")
             Order.InvoicedKey                     = oOrder:GetCharacter("InvoicedKey")
             Order.ShippedTrackingUrl              = oOrder:GetCharacter("ShippedTrackingUrl")
             Order.ShippedTrackingProtocol         = oOrder:GetCharacter("ShippedTrackingProtocol")
             Order.ShippedEstimatedDelivery        = oOrder:GetCharacter("ShippedEstimatedDelivery")
             Order.ShippedCarrierDate              = oOrder:GetCharacter("ShippedCarrierDate")
             Order.ShippedCarrierName              = oOrder:GetCharacter("ShippedCarrierName")
             Order.ShipmentExceptionObservation    = oOrder:GetCharacter("ShipmentExceptionObservation")
             Order.ShipmentExceptionOccurrenceDate = oOrder:GetCharacter("ShipmentExceptionOccurrenceDate")
             Order.DeliveredDate                   = oOrder:GetCharacter("DeliveredDate")
             Order.ShippedCodeERP                  = oOrder:GetCharacter("ShippedCodeERP")
             Order.BranchDocument                  = oOrder:GetCharacter("BranchDocument") .
      
      productsArray = oOrder:GetJsonArray('Products') no-error.
      
      DO p = 1 TO productsArray:length:
      
         objProducts = productsArray:GetJsonObject(p).
      
         CREATE OrderProduct.
         ASSIGN OrderProduct.IdSku          = objProducts:GetCharacter("IdSku")
                OrderProduct.Quantity       = objProducts:GetInteger("Quantity")
                OrderProduct.Price          = objProducts:GetCharacter("Price")
                OrderProduct.Freight        = objProducts:GetCharacter("Freight")
                OrderProduct.Discount       = objProducts:GetCharacter("Discount")
                OrderProduct.IdOrderPackage = objProducts:GetCharacter("IdOrderPackage")
                OrderProduct.IdOrder        = oOrder:GetCharacter("IdOrder").
   
      END.
   END.  

END PROCEDURE.


