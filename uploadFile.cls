/*------------------------------------------------------------------------
File        : uploadFile.cls
Purpose     : Oracle Commerce Cloud
Syntax      :
Description : This class uploads a file to Oracle Cloud Commerce Area.
Author(s)   : Rodrigo Ferreira Reis 
Created     : Thu Mar 01 18:18:29 BRST 2022
Notes       : You need to declare all necessary usings. 
----------------------------------------------------------------------*/

CLASS COMMERCE:
  METHOD PUBLIC IHttpResponse upLoadFile(INPUT fileName AS CHARACTER):
        DEFINE VARIABLE memptrCSV       AS MEMPTR               NO-UNDO.
        DEFINE VARIABLE memptrCSVObject AS OpenEdge.Core.Memptr NO-UNDO. 
        DEFINE VARIABLE oRequestBody    AS MultipartEntity      NO-UNDO.
        DEFINE VARIABLE part            AS MessagePart          NO-UNDO.
        DEFINE VARIABLE client          AS IHttpClient          NO-UNDO.
        DEFINE VARIABLE oText           AS OpenEdge.Core.String NO-UNDO.
        DEFINE VARIABLE oEntity         AS MultipartEntity      NO-UNDO.
        DEFINE VARIABLE shortFileName   AS CHARACTER            NO-UNDO.
        
        
        
        
        shortFileName = entry(num-entries(fileName, "/"), fileName, "/").
      
        // Pass the Bearer  token here to Authorization
        
        httpUrl = 'yourcommerceUrl/files'.
        
        cToken  = 'Bearer ' + STRING(lcToken).
       
        COPY-LOB FROM FILE filename TO memptrCSV.
        memptrCSVObject = NEW OpenEdge.Core.Memptr(memptrCSV).
        
        oRequestBody = NEW MultipartEntity().

        // Create a form fileUpload with a csv file
        part = NEW MessagePart("text/csv; name=" + shortFileName, 
        memptrCSVObject).
        part:Headers:Put( HttpHeaderBuilder:Build('Content-Disposition')
        :Value('form-data; name="fileUpload"; filename="' + shortFileName 
        + '"'):Header).
        part:Headers:Put( HttpHeaderBuilder:Build('Content-Transfer-Encoding')
        :Value('binary'):Header).
        oRequestBody:AddPart(part).

        // Creates a form filename with the file name 
        oText = NEW OpenEdge.Core.String(shortFileName).
        part  = NEW MessagePart("text/plain", oText).
        
        part:Headers:Put( HttpHeaderBuilder:Build('Content-Disposition')
        :Value('form-data; name="filename"'):Header).
        oRequestBody:AddPart(part).

        // Creates a bulkImport form uploadType 
        oText = NEW OpenEdge.Core.String("bulkImport").
        part  = NEW MessagePart("text/plain", oText).
        part:Headers:Put( HttpHeaderBuilder:Build('Content-Disposition')
        :Value('form-data; name="uploadType"'):Header).
        oRequestBody:AddPart(part).
       
        oReq = RequestBuilder:Post(httpUrl)
                             :AddHeader('Authorization', cToken)
                             :AddHeader('Connection', 'Keep-Alive')
                             :ContentType('multipart/form-data')
                             :WithData(oRequestBody, 'multipart/form-data')
                             :Request.

        oResp = ClientBuilder:Build() 
                             :UsingLibrary(oLib) 
                             :SetNumRetries(3)
                             :Client 
                             :Execute(oReq).
        
        
        RETURN oResp.
       
    END METHOD.
  END CLASS.
