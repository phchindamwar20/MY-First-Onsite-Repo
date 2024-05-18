/*********************************************************************************
Author:         
Company:        FirstOnSite
Description:    Class to generate the token for ICI Authentication
Class:     		GetSASToken.cls

History:
When        	Who         		What
24-June-2022	Arpit				Added code for generating the token for ICI Authentication

*************************************************************************************/
public class GetSASToken {
    public static String getSASTokenMethod(String resourceUri, String keyName, String key) {
        Long epoch = System.currentTimeMillis()/1000L;
        Integer week = 60*60*24*7;
        String expiry = (epoch + week).format();
        String sasToken = null;
        
        try {
            String stringToSign = EncodingUtil.urlEncode(resourceUri, 'UTF-8') + '\n' + expiry;
            Blob data= Blob.valueOf(key);
            Blob stringToSignBlob= Blob.valueOf(stringToSign);
            Blob signatureBlob = Crypto.generateMac('HmacSHA256', stringToSignBlob, data);
            sasToken = 'SharedAccessSignature sr=' + EncodingUtil.urlEncode(resourceUri, 'UTF-8') +'&sig=' +
                EncodingUtil.urlEncode(String.valueOf(EncodingUtil.base64Encode(signatureBlob)), 'UTF-8') + '&se=' + expiry + '&skn=' + keyName;
        } catch (Exception ex) {
            System.debug('Error: '+ex.getMessage()+'===='+ex.getStackTraceString());
        }
        return sasToken;
    }
}