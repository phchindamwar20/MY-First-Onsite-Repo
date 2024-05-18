/**
 * @description       : https://blog.lkatney.com/2017/09/13/handle-commas-in-csv-columns-apex/
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-04-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FileParserService {
    public static final String COMMA = ':c:';
    public static final String QUOTES = ':q:';

    public static String preProcessCSVLine(String csvLine) {
        //String csvLine = 'Test,Check,abc@abc.com, "19, Link road, A1SH10, India", companyName, "companyStreet, CompanyCity, CompanyCountry"';
        String prevLine = csvLine;
        Integer startIndex;
        Integer endIndex;

        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + QUOTES + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + QUOTES + csvLine.substring(endIndex+1, csvLine.length());
                }
            }
        
            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', COMMA);
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }
        csvLine.replaceAll('\r','').replaceAll('\n','');
        System.debug('~~~~ FileParserService::preProcessCSVLine: prevLine -'+prevLine);
        System.debug('~~~~ FileParserService::preProcessCSVLine: csvLine -'+csvLine);

        return csvLine;
    }

    public static String processCell(String cell) {
        String newCell = cell.replaceAll(QUOTES, '').replaceAll(COMMA, ',').replaceAll('\r', '').replaceAll('\n', '').trim();    
        newCell= String.isBlank(newCell) ? null : newCell;
        return newCell;
    }

    public static Date processDate(String cell) {
        String newCell = processCell(cell);
        return !String.isBlank(newCell) ? Date.parse(newCell) : null;
    }

    public static Boolean processBoolean(String cell) {
        String newCell = processCell(cell);
        //System.debug('~~~~ FileParserService::processBoolean: newCell - ' + newCell);
        if (newCell=='0') {
            return false;
        } else {
            return true;
        }
    }

    public static Decimal processDecimal(String cell) {
        String newCell = processCell(cell);
        System.debug('~~~~ FileParserService::processDecimal: newCell - ' + newCell);
        return !String.isBlank(newCell) ? Decimal.valueOf(newCell) : null;
    }

    public static Id processId(String cell) {
        String newCell = processCell(cell);
        System.debug('~~~~ FileParserService::processId: newCell - ' + newCell);
        return !String.isBlank(newCell) ? Id.valueOf(newCell) : null;
    }

    public static Integer processInteger(String cell) {
        String newCell = processCell(cell);
        System.debug('~~~~ FileParserService::processInteger: newCell - ' + newCell);
        return !String.isBlank(newCell) ? Integer.valueOf(newCell) : null;
    }    
}